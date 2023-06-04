function init_char()
    local char={
        x=200,
        y=240,
        dx=0,
        dy=0,
        runspeed=1,
        spr=004,
        spri=1,
        state='stand',
        flip=false,
        cell_x=0,
        cell_y=0,
        action_cell_x=0,
        action_cell_y=0,
        last_direction=0,
        health=10,
        max_health=10,
        stamina=20,
        max_stamina=20,
        exhausted=false,
        states={
            ['stand']={
                ['walk']=1,
            },
            ['walk']={
                ['stand']=1,
            }
        },
        animations={
            ['stand']={004},
            ['walk']={004,004,020,020},
        },
        change_state=change_state,
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
            spr(self.spr,self.x,self.y,1,1,self.flip)
            -- stamina
            if (self.stamina < self.max_stamina) then
                local s_pct = (self.stamina / self.max_stamina) * 10
                local s_col = 11
                if (self.exhausted) then s_col = 8 end
                line(self.x - 1, self.y - 2, self.x + s_pct - 1, self.y - 2, s_col)
            end

        end
    }
    return char
end

function change_state(_char, next_state)
    if (_char.states[_char.state][next_state] ~= nil) then
        _char.state = next_state
        _char.spri = 1
    end
end

function get_input(_char)
    if (btn(0) and not(btn(1)) and not(btn(2)) and not(btn(3))) then
        local collision_cell = mget(_char.cell_x - 1, _char.cell_y)
        if (fget(collision_cell) == 1) then
            _char.dx = 0
        else
            _char.dx = -char.runspeed
        end

        _char:change_state('walk')
        _char.flip = true
        _char.last_direction = 0
    elseif (btn(1) and not(btn(0)) and not(btn(2)) and not(btn(3)) ) then
        local collision_cell = mget(_char.cell_x + 1, _char.cell_y)
        if (fget(collision_cell) == 1) then
            _char.dx = 0
        else
            _char.dx = char.runspeed
        end

        _char:change_state('walk')
        _char.flip = false
        _char.last_direction = 0.5
    elseif (btn(2) and not(btn(1)) and not(btn(0)) and not(btn(3))) then
        local collision_cell = mget(_char.cell_x, _char.cell_y - 1)
        if (fget(collision_cell) == 1) then
            _char.dy = 0
        else
            _char.dy = -char.runspeed
        end

        _char:change_state('walk')
        _char.last_direction = 0.75
    elseif (btn(3) and not(btn(1)) and not(btn(2)) and not(btn(0))) then
        local collision_cell = mget(_char.cell_x, _char.cell_y + 1)
        if (fget(collision_cell) == 1) then
            _char.dy = 0
        else
            _char.dy = char.runspeed
        end

        _char:change_state('walk')
        _char.last_direction = 0.25
    end

    if (btn(0) == btn(1)) then
        _char.dx = 0 
    end

    if (btn(2) == btn(3)) then
        _char.dy = 0 
    end 

    if (_char.dx == 0 and _char.dy == 0) then
        _char:change_state('stand')
    end

    -- action
    if (btnp(5)) then
        -- check the action cell to see if we should do something different

        -- item pickup
        local cell_item = item_map:get(_char.action_cell_x, _char.action_cell_y)
        if (cell_item ~= nil) then
            local did_work = inventory:add(cell_item)
            if (did_work) then
                item_map:delete(_char.action_cell_x, _char.action_cell_y)
            end

            return
        end
        -- otherwise, just bring up the menu
        _char:menu()
    end

    -- run
    if (btn(4) and (abs(_char.dx) > 0 or abs(_char.dy) > 0)) then
        if (_char.stamina > 0 and _char.exhausted == false) then
            _char.runspeed = 1.5

            if (t % 8 == 0) then
                add_new_dust(_char.x + 4, _char.y + 7, 0, 0, 6, 2, 0, 7)
                _char.stamina -= 1
            end

            if (_char.stamina <= 0) then
                _char.runspeed = 1
                _char.exhausted = true
                _char.stamina = 0
            end
        end
    else
        _char.runspeed = 1
        if (t % 32 == 0 and _char.stamina < _char.max_stamina) then
            _char.stamina = min(_char.stamina + 1, _char.max_stamina)
            if (_char.exhausted and _char.stamina > (_char.max_stamina / 2)) then
                _char.exhausted = false
            end 
        end
    end
end

function update_char(_char)
    if (_char.pause) then
        return
    end

    _char:get_input()

    _char.y += _char.dy
    _char.x += _char.dx

    -- closest cell
    _char.cell_x = round((_char.x + (3 * cos(_char.last_direction) - 1)) / 8)
    _char.cell_y = round((_char.y + (3 * sin(_char.last_direction) - 1)) / 8)
    _char.action_cell_x = _char.cell_x - cos(_char.last_direction)
    _char.action_cell_y = _char.cell_y - sin(_char.last_direction)

    -- animation
    if (t % 4 == 0) then
        _char.spri = ((_char.spri + 1) % #_char.animations[_char.state]) + 1
    end

    _char.spr = _char.animations[_char.state][_char.spri]
end
