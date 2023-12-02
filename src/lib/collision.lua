collision_manager = {
    -- todo: quad tree to improve performance
    objects={},
    collider_count=0,
    collider_types = {
        solid='solid',
        overlap='overlap'
    },

    -- current behavior: overwrite anything with the same id
    register_collider=function(self, id, x, y, type)
        local new_collider = {
            id=id,
            x=x,
            y=y,
            type=type,

            update=function(self, x, y)
                self.x = x
                self.y = y
            end,

            check_intersect=function(self, other)
                return false
            end,

            draw=function(self)
                rect(self.x * 8, self.y * 8, (self.x * 8) + 8, (self.y * 8) + 8, 8)
            end
        }

        if (self.objects[id] == nil) then
            self.collider_count += 1
        end

        self.objects[id] = new_collider
        return new_collider
    end,

    test_intersect=function(self, obj1, type)
        for id,obj2 in pairs(self.objects) do
            if (obj1.id ~= id) then
                if (
                    obj1.x == obj2.x and
                    obj1.y == obj2.y
                ) then return true end
            end
        end
        return false
    end,

    draw_colliders=function(self)
        for id,obj in pairs(self.objects) do
            obj:draw()
        end
    end
}

