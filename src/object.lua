object_manager = {
    _ = {},
    add=function(self,x,y,s,options)
        collision_manager:register_collider(
            'obj'..x..'-'..y,
            x,
            y,
            collision_manager.collider_types.solid
        )

        local key = x .. '-' .. y

        local obj = {
            id='obj'..x..'-'..y,
            x=x,
            y=y,
            s=s
        }
        for k,v in pairs(options) do
            obj[k] = v
        end

        self._[key] = obj
    end,

    add2=function(self,x,y,in_obj)
        collision_manager:register_collider(
            'obj'..x..'-'..y,
            x,
            y,
            collision_manager.collider_types.solid
        )

        local key = x .. '-' .. y

        local obj = {
            id='obj'..x..'-'..y,
            x=x,
            y=y,
        }
        for k,v in pairs(in_obj) do
            obj[k] = v
        end

        self._[key] = obj
    end,

    update_all=function(self)
        for k,v in pairs(self._) do
            if v.update ~= nil then
                v:update()
            end
        end 
    end,

    delete=function(self,key)
        local target_obj = self._[key]
        if target_obj ~= nil then
            collision_manager:delete_collider(target_obj.id)
        end
        self._[key] = nil
    end,

    flush=function(self)
        for k in pairs(self._) do
            self:delete(k)
        end
    end,
    
    -- TODO: only draw the objects that are on screen
    draw_all=function(self)
        for k,v in pairs(self._) do
            if v.draw ~= nil then
                v:draw()
            else
                spr(v.s,v.x*8,v.y*8,1,1)
            end
        end
    end
}

objects = {}
objects.tree = {
    s=018,
    timer=1,
    hp=3,
    update=function(self)
        if self.timer > 0 then
            self.timer -= 1
        else
            if self.action == nil then
                self.action = self._action
                self.hp=3
            end
        end
    end,
    draw=function(self)
        local xc = self.x * 8
        local yc = self.y * 8

        if self.timer > 0 then
            spr(045,xc,yc,1,1)
        else
            spr(018,xc,yc,1,1)
            rectfill(xc,yc-7,xc+6,yc-2,0)
            spr(001,xc,yc-8,1,1)
        end
    end,
    action=nil,
    _action={
        ['chop']=function(self)
            if char.exhausted then
                sfx(50)
                return
            end

            char.stamina -= 4

            if self.hp > 0 then
                sfx(47)
                add_new_dust((self.x * 8) + 4, (self.y * 8) + 4, rnd(2) - 1, -rnd(1), 15, 2, 0.1, 7)
                self.hp -= 1
            else
                sfx(42)
                self.timer = 200
                self.action=nil
                --item_map:set(22, 28, items.log)
            end
        end
    }
}