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
            spr(v.s,v.x*8,v.y*8,1,1)
        end
    end
}