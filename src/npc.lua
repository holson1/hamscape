npc_blueprint = {
    id=nil,
    x=nil,
    y=nil,
    dx=0,
    dy=0,
    spr=nil,
    dialog=nil,
    update = function(self)
        -- walk randomly
        if (t % 64 == 0) then
            if (rnd() > 0.7) then
                local dir = rnd({0, 0.25, 0.5, 0.75})
                self.dx = cos(dir) * 0.25
                self.dy = sin(dir) * 0.25
            else
                self.dx = 0
                self.dy = 0
            end
        end

        self.x += self.dx
        self.y += self.dy

        self.collision_component:update(self.x, self.y, self.x + 8, self.y + 8)
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
            p.x + 8,
            p.y + 8,
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
            spr(v.s,v.x,v.y,1,1,v.flip)
        end
    end
}


npc_pig = {
    id='farm_pig',
    x = 208,
    y = 208,
    s = 084,
    dialog = {'oink!'}
}

npc_wizard = {
    id='wizard',
    x = 232,
    y = 296,
    s = 100,
    dialog = {
        'blast, my journey was',
        'cut short by a bear!'
    }
}

dialog_manager = {
    current_npc=nil,
    update = function(self)
        if (btnp(4) or btnp(5)) then
            self.current_npc = nil
            new_game_state = 'move'
        end
    end,
    draw = function(self)
        if (self.current_npc) then
            draw_menu_rect(
                16,
                111,
                111,
                127,
                7
            )
            for i,v in ipairs(self.current_npc.dialog) do
                print(v, cam.x + 18, cam.y + 113 + (8 * (i - 1)), 7)
            end
        end
    end
}