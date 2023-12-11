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
        collision_manager:delete_collider(target_npc.id)
        -- TODO: double check that this actually cleans up the npc
        del(self._, target_npc)
        self._[key] = nil
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
            spr(v.s,v.x,v.y,1,1,v.flip)
        end
    end
}


npc_pig = {
    id='farm_pig',
    cell_x = 26,
    cell_y = 26,
    s = 084,
    script = function(self)
        return {{'oink!'}}
    end
}


npc_wizard = {
    id='wizard',
    cell_x = 29,
    cell_y = 37,
    s = 100,
    script = function(self)
        local dialog = {
            {
                'blast, my journey was',
                'cut short by a bear!'
            }
        }
        if (npc_cat.talked and not(npc_cat.fed)) then
            dialog = {
                {
                    'oh, my cat is hungry?'
                },
                {
                    'let me summon him a',
                    'nice tuna fish.'
                },
                {
                    '...'
                },
                {
                    'there, that should make',
                    'him happy for a',
                    'little while.'
                }
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
                {
                    'thank you! *munch*',
                    '(i must remember to bury',
                    'the leftovers)...'
                }
            }
        else
            self.talked=true
            return {
                {
                    "that's right, i'm a cat.",
                    "just like you~"
                },
                {
                    "i'm also quite hungry."
                },
                {
                    "can you tell my owner",
                    "to summon me some food?"
                },
                {
                    "he's a wizard",
                    "...so he can do that."
                }
            }
        end
    end
}

enemy_gob = {
    id='gob',
    cell_x=14,
    cell_y=30,
    s=080,
    hostile=true,
    health=2
}


dialog_manager = {
    current_npc=nil,
    dialog_counter=1,
    dialog=nil,
    load=function(self)
        if (self.current_npc.script == nil) then
            self.current_npc = nil
            new_game_state = 'move'
            return
        end
        self.dialog_counter=1
        self.dialog=self.current_npc:script()
    end,
    update = function(self)
        if (btnp(4)) then
            self.current_npc = nil
            new_game_state = 'move'
        end

        if (btnp(5)) then
            self.dialog_counter +=1
            if (self.dialog_counter > #self.dialog) then
                self.current_npc = nil
                new_game_state = 'move'
            end
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
            for i,v in ipairs(self.dialog[self.dialog_counter]) do
                print(v, cam.x + 18, cam.y + 105 + (8 * (i - 1)), 7)
            end
        end
    end
}