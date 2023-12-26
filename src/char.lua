function init_char()
    local char={
        x=200,
        y=240,
        runspeed=1,
        spr=004,
        spri=1,
        state='stand',
        flip=false,
        facing_back=false,
        cell_x=0,
        cell_y=0,
        next_move=nil,
        is_moving=false,
        move_direction=0,
        facing=0,
        action_cell_x=0,
        action_cell_y=0,
        collision_component=nil,
        test_collider=nil,
        last_direction=0,
        health=10,
        max_health=10,
        stamina=20,
        max_stamina=20,
        exhausted=false,
        states={
            ['stand']={
                ['walk']=1,
                ['run']=1
            },
            ['walk']={
                ['stand']=1,
                ['run']=1
            },
            ['run']={
                ['stand']=1,
                ['walk']=1
            }
        },
        animations={
            ['stand']={096},
            ['stand_back']={098},
            ['walk']={096,096,097,097},
            ['walk_back']={098,098,099,099},
            ['run']={096,096,097,097},
            ['run_back']={098,098,099,099}
        },
        change_state=change_state,
        contextual_action=nil,
        get_input=get_input,
        update=update_char,
        menu=function(self)
            -- bring up pause / item menu
            new_game_state = 'menu'
        end,
        action=function(self)
            -- talk / read
            new_game_state = 'menu'
        end,

        draw=function(self)
            if self.state == 'run' then
                -- trails
                color_spr(self.spr,1,self.x+cos(self.last_direction)*4,self.y+sin(self.last_direction)*4,self.flip)
            end
            outline_sprite(self.spr,0,self.x,self.y,self.flip)

            -- stamina
            if self.stamina < self.max_stamina then
                local s_pct = (self.stamina / self.max_stamina) * 10
                local s_col = 11
                if self.exhausted then s_col = 8 end
                line(self.x - 1, self.y - 2, self.x + s_pct - 1, self.y - 2, s_col)
            end

            -- contextual action
            if self.contextual_action and game_state == 'move' then
                rectfill(self.x + 9, self.y + 9, self.x + 50, self.y + 15, 1)
                if self.pickup_text ~= nil then
                    print("\142: "..self.pickup_text, self.x + 10, self.y + 10, 7)
                else
                    print("\142: "..self.contextual_action, self.x + 10, self.y + 10, 7)
                end
            end

            -- debug collision
            -- rect((self.collision_component.x * 8), (self.collision_component.y *8), (self.collision_component.x *8)+ 8, (self.collision_component.y * 8)+8,8)
            -- if (self.test_collider ~= nil) then
            --     rect(self.test_collider.x * 8, self.test_collider.y * 8, (self.test_collider.x * 8) + 8, (self.test_collider.y * 8) + 8, 9)
            -- end

        end
    }

    char.collision_component = collision_manager:register_collider(
        'char',
        char.cell_x,
        char.cell_y,
        collision_manager.collider_types.solid
    )

    return char
end

function change_state(_char, next_state)
    if next_state ~= _char.state and _char.states[_char.state][next_state] ~= nil then
        _char.state = next_state
        _char.spri = 1
    end
end

function update_char(_char)
    if _char.pause then
        return
    end

    -- get the active cell
    _char.cell_x = flr(_char.x / 8)
    _char.cell_y = flr(_char.y / 8)

    next_move = nil

    -- stamina recovery
    if t % 32 == 0 and _char.state ~= 'run' and _char.stamina < _char.max_stamina then
        _char.stamina = min(_char.stamina + 1, _char.max_stamina)
        if _char.exhausted and _char.stamina > (_char.max_stamina / 2) then
            _char.exhausted = false
        end 
    end 

    -- get input for the given frame
    if btn(0) and not(btn(1)) and not(btn(2)) and not(btn(3)) then
        next_move = 0
        _char.last_direction = 0
    elseif btn(1) and not(btn(0)) and not(btn(2)) and not(btn(3)) then
        next_move = 0.5
        _char.last_direction = 0.5
    elseif btn(2) and not(btn(1)) and not(btn(0)) and not(btn(3)) then
        next_move = 0.75
        _char.last_direction = 0.75
    elseif btn(3) and not(btn(1)) and not(btn(2)) and not(btn(0)) then
        next_move = 0.25
        _char.last_direction = 0.25
    end

    next_state = _char.state

    -- if we're moving, we shouldn't change direction until we've landed squarely on a cell
    if _char.is_moving then
        
        -- move to cell
        _char.x -= cos(_char.move_direction) * _char.runspeed
        _char.y -= sin(_char.move_direction) * _char.runspeed

        if _char.state == 'run' then
            if t % 8 == 0 then
                add_new_dust(_char.x + 4, _char.y + 7, 0, 0, 6, 2, 0, 7)
                _char.stamina -= 2
                sfx(47)
            end


            if _char.stamina <= 0 then
                _char.runspeed = 1
                _char.exhausted = true
                _char.stamina = 0
                next_state = 'walk'
            end
        end

        -- landed on a cell
        if (_char.x % 8 <= 0.2 or _char.x % 8 >= 7.8) and (_char.y % 8 <= 0.2 or _char.y % 8 >= 7.8) then
            _char.x = round(_char.x)
            _char.y = round(_char.y)
            _char.is_moving = false

            _char.action_cell_x = (_char.x / 8) - cos(_char.last_direction)
            _char.action_cell_y = (_char.y / 8) - sin(_char.last_direction)

            _char.cell_x = flr(_char.x / 8)
            _char.cell_y = flr(_char.y / 8)

            -- check cell for exits
            local tile_key = _char.cell_x .. "-" .. _char.cell_y
            if level.exits[tile_key] ~= nil then
                local lv = levels.list[level.exits[tile_key]]
                transition_level(lv)
            end
        end
    end

    _char.contextual_action = nil
    _char.pickup_text = nil
    local action_key = (_char.action_cell_x) .. '-' .. (_char.action_cell_y)

    -- other objects (locks, trees, etc)
    local object_target = object_manager._[action_key]
    if object_target and object_target.action then
        if object_target.action['check'] then
            _char.contextual_action = 'check'
        end
    end

    -- talk / npcs
    local npc_target = npc_manager._[action_key]
    if npc_target then
        if npc_target.hostile then
            _char.contextual_action = 'fight'
        elseif npc_target.script ~= nil then
            _char.contextual_action = 'talk'
        end
    end

    -- pickup items
    local cell_item = item_map:get(_char.cell_x, _char.cell_y)
    if cell_item ~= nil then
        _char.contextual_action = 'pickup'
        _char.pickup_text = cell_item.name
    end

    -- action
    if btnp(5) then
        -- check the action cell to see if we should do something different


        if _char.contextual_action == 'check' then
            new_game_state = 'talk'
            dialog_manager.current_npc = {
                script=object_target.action['check']
            }
            dialog_manager:load()
            return
        end

        -- item pickup
        if _char.contextual_action == 'pickup' then
            local did_work = inventory:add(cell_item)
            if did_work then
                item_map:delete(_char.cell_x, _char.cell_y)
            end

            return
        end

        if _char.contextual_action == 'talk' then
            new_game_state = 'talk'
            dialog_manager.current_npc = npc_target
            dialog_manager:load()
            return
        end

        if _char.contextual_action == 'fight' then
            new_game_state = 'battle'
            battle_manager:load(npc_target)
            return
        end

        -- otherwise, just bring up the menu
        _char:menu()
    end

    -- if I'm on a cell and there's an input, read the next direction and get ready to move next frame
    if _char.is_moving == false then
        if next_move ~= nil then

            -- change facing direction
            _char.facing = next_move
            if next_move == 0 then
                _char.flip = true
                _char.facing_back = false
            elseif next_move == 0.25 then
                _char.facing_back = false
            elseif next_move == 0.5 then
                _char.flip = false
                _char.facing_back = false
            elseif next_move == 0.75 then
                _char.facing_back = true
            end

            _char.action_cell_x = _char.cell_x - cos(_char.last_direction)
            _char.action_cell_y = _char.cell_y - sin(_char.last_direction)

            -- check to see if the next cell is free
            _char.test_collider = {id='char', x=0, y=0}
            _char.test_collider.x = _char.cell_x - cos(next_move)
            _char.test_collider.y = _char.cell_y - sin(next_move)

            if collision_manager:test_intersect(_char.test_collider, collision_manager.collider_types.solid) then
                return
            end

            -- if it is...
            next_state = 'walk'

            _char.is_moving = true
            _char.move_direction = next_move
            _char.runspeed = 1

            if btn(4) then
                if _char.stamina > 0 and _char.exhausted == false then
                    _char.runspeed = 2
                    next_state = 'run'
                end
            end
        else
            next_state = 'stand'
        end
    end

    -- update state
    _char:change_state(next_state)

    _char.collision_component:update(_char.cell_x, _char.cell_y)

    -- _char.action_cell_x = _char.cell_x - cos(_char.last_direction)
    -- _char.action_cell_y = _char.cell_y - sin(_char.last_direction)

    -- animation, and update sprite
    current_anim = _char.state
    if _char.facing_back == true then
        current_anim = _char.state .. '_back'
    end
    if t % 4 == 0 then
        _char.spri = ((_char.spri + 1) % #_char.animations[current_anim]) + 1
    end

    _char.spr = _char.animations[current_anim][_char.spri]
end