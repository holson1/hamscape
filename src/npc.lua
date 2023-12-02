npc_blueprint = {
    id=nil,
    x=nil,
    y=nil,
    spr=nil,
    dialog=nil,
    update = function(self)
    end,
}

npc_manager = {
    _ = {},
    add=function(self,p)
        for k,v in pairs(npc_blueprint) do
            if v!=nil then
                p[k]=v
            end
        end

        p.collision_component = collision_manager:register_collider(
            p.id,
            p.x,
            p.y,
            collision_manager.collider_types.solid
        )

        local key = p.x .. '-' .. p.y
        self._[key] = p
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
            spr(v.s,v.x*8,v.y*8,1,1,v.flip)
        end
    end
}


npc_pig = {
    id='farm_pig',
    x = 26,
    y = 26,
    s = 084,
    dialog = {'oink!'}
}

npc_wizard = {
    id='wizard',
    x = 29,
    y = 37,
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
                    'him happy for a little while.'
                }
            }
            npc_cat.fed = true
        end
        return dialog
    end
}

npc_cat = {
    id='cat',
    x=19,
    y=22,
    s = 101,
    talked=false,
    fed = false,
    script = function(self)
        if (self.fed) then
            return {
                {
                    'thank you! *munch*',
                    '(i must remember to bury the leftovers)'
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

dialog_manager = {
    current_npc=nil,
    dialog_counter=1,
    dialog=nil,
    load=function(self)
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
                print(v, cam.x + 18, cam.y + 113 + (8 * (i - 1)), 7)
            end
        end
    end
}