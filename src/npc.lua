npc_blueprint = {
    id=nil,
    cell_x=nil,
    cell_y=nil,
    x=nil,
    y=nil,
    flip=false,
    spr=nil,
    script=nil,
    move_direction=nil,
    wander=true,
    update = function(self)
        if self.wander then
            if self.move_direction == nil then
                -- pick a random direction to move in
                if (t % 64 == 0) then
                    local dirs = {0,0.25,0.5,0.75}

                    self.move_direction = rnd(dirs)

                    if (self.move_direction ~= nil) then

                        if (self.move_direction == 0) then
                            self.flip = false
                        elseif (self.move_direction == 0.5) then
                            self.flip = true
                        end

                        -- check to see if the next cell is free
                        local test_collider = {id=self.id, x=0, y=0}
                        test_collider.x = self.cell_x - cos(self.move_direction)
                        test_collider.y = self.cell_y - sin(self.move_direction)

                        if (
                            collision_manager:test_intersect(test_collider, collision_manager.collider_types.solid) or
                            abs(test_collider.x - self.origin_x) > 3 or
                            abs(test_collider.y - self.origin_y) > 3
                        ) then
                            self.move_direction = nil
                        else
                            -- move the collider
                            self.collision_component:update(test_collider.x, test_collider.y)

                            local key = self.cell_x .. '-' .. self.cell_y
                            npc_manager._[test_collider.x .. '-' .. test_collider.y] = self
                            npc_manager._[key] = nil
                        end
                    end

                end
            else
                self.x -= cos(self.move_direction)
                self.y -= sin(self.move_direction)
                if (self.x % 8 == 0 and self.y % 8 == 0) then
                    self.cell_x = self.x / 8
                    self.cell_y = self.y / 8
                    self.move_direction = nil
                end
            end
        else
            if (t % 16 == 0) then
                self.flip = not(self.flip)
            end
        end
    end
}

npc_manager = {
    _ = {},
    add=function(self,p)
        for k,v in pairs(npc_blueprint) do
            if v!=nil and p[k] == nil then
                p[k]=v
            end
        end

        p.collision_component = collision_manager:register_collider(
            p.id,
            p.cell_x,
            p.cell_y,
            collision_manager.collider_types.solid
        )

        p.x = p.cell_x * 8
        p.y = p.cell_y * 8
        p.origin_x = p.cell_x
        p.origin_y = p.cell_y

        local key = p.cell_x .. '-' .. p.cell_y
        self._[key] = p
    end,

    delete=function(self,key)
        local target_npc = self._[key]
        if (target_npc ~= nil) then
            collision_manager:delete_collider(target_npc.id)
        end
        self._[key] = nil
    end,

    flush=function(self)
        for k in pairs(self._) do
            self:delete(k)
        end
    end,
    
    -- TODO: only update the npcs that are on screen
    update_all=function(self)
        for k,v in pairs(self._) do
            v:update()
        end
    end,
    
    -- TODO: only draw the npcs that are on screen
    draw_all=function(self)
        for k,v in pairs(self._) do
            if v.s then
                spr(v.s,v.x,v.y,1,1,v.flip)
                if t % 16 > 8 then
                    rectfill(v.x,v.y,v.x+7,v.y+3,0)
                    spr(v.s,v.x,v.y+1,1,0.75,v.flip)
                end
                if v.hurt then
                    color_spr(v.s,8,v.x,v.y,v.flip)
                    v.hurt = false
                end
            end
        end
    end
}


npc_pig = {
    id='farm_pig',
    cell_x = 26,
    cell_y = 26,
    s = 084,
    script = function(self)
        return {'oink!'}
    end
}


npc_wizard = {
    id='wizard',
    cell_x = 29,
    cell_y = 37,
    s = 100,
    script = function(self)
        local dialog = {
            'blast, my journey was\ncut short by a bear!'
        }
        if (npc_cat.talked and not(npc_cat.fed)) then
            dialog = {
                'oh, my cat is hungry?',
                'let me summon him a\nnice tuna fish.',
                '...!',
                'there, that should make\nhim happy for a\nlittle while.'
            }
            npc_cat.fed = true
        end
        return dialog
    end
}

npc_cat = {
    id='cat',
    cell_x=19,
    cell_y=22,
    s = 101,
    wander=false,
    talked=false,
    fed = false,
    script = function(self)
        if (self.fed) then
            return {
                'thank you! *munch*\n(i must remember to bury\nthe leftovers...)'
            }
        else
            self.talked=true
            return {
                "that's right, i'm a cat.\njust like you~",
                "i'm also quite hungry.",
                "can you tell my owner\nto summon me some food?",
                "he's a \fcwizard\n\f7...so he can do that."
            }
        end
    end
}

npc_farmer = {
    id='farmer',
    cell_x=8,
    cell_y=9,
    s = 102,
    wander=false,
    script = function(self)
        return {'now where could i have\nleft that shed key?'}
    end
}

enemy_gob = {
    id='gob',
    cell_x=14,
    cell_y=30,
    s=080,
    hostile=true,
    health=5
}

enemy_spawner = {
    id='spawner',
    cell_x=14,
    cell_y=28,
    count=0,
    update=function(self)
        if t == 1 and self.count < 3 then
            -- TODO: make this better
            local eid = rndi(1,99)
            npc_manager:add({
                id='gob'..eid,
                cell_x=rndi(9,16),
                cell_y=rndi(24,38),
                s=080,
                hostile=true,
                health=5
            })
            self.count += 1
        end
    end
}


dialog_manager = {
    current_npc=nil,
    char_counter=1,
    button_held=false,
    dialog_counter=1,
    dialog=nil,
    load=function(self)
        if (self.current_npc.script == nil) then
            self.current_npc = nil
            new_game_state = 'move'
            return
        end
        self.dialog_counter=1
        self.char_counter=1
        self.dialog=self.current_npc:script()
    end,
    update = function(self)
        local line = self.dialog[self.dialog_counter]

        if (btnp(4)) then
            self.current_npc = nil
            new_game_state = 'move'
            return
        end

        if (btn(5)) then
            if (self.button_held == false) then
                self.button_held = true

                -- move to end of text
                if (self.char_counter < #line) then
                    self.char_counter = #line
                    return
                end

                -- advance to next block
                self.dialog_counter +=1
                self.char_counter=1
                if (self.dialog_counter > #self.dialog) then
                    self.current_npc = nil
                    new_game_state = 'move'
                    return
                end
            end
        else
            self.button_held = false
        end

        if (self.char_counter < #line) then
            self.char_counter += 1
            sfx(rnd({47,47,48,47}))
        end
    end,
    draw = function(self)
        if (self.current_npc) then
            draw_menu_rect(
                8,
                103,
                119,
                127,
                7
            )
            local line = self.dialog[self.dialog_counter]
            local substring = sub(line, 1, self.char_counter)
            print(substring, cam.x + 18, cam.y + 105, 7)

            if (self.char_counter >= #line and t%32 > 16) then
                print("\142", cam.x + 110, cam.y + 120, 7)
            end
        end
    end
}