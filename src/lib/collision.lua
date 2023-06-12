collision_manager = {
    -- todo: quad tree to improve performance
    objects={},
    collider_count=0,
    collider_types = {
        solid='solid',
        overlap='ovelap'
    },

    -- current behavior: overwrite anything with the same id
    register_collider=function(self, id, left, top, right, bottom, type)
        local new_collider = {
            id=id,
            left=left,
            top=top,
            right=right,
            bottom=bottom,
            type=type,

            update=function(self, l, t, r, b)
                self.left = l
                self.right = r
                self.top = t
                self.bottom = b
            end,

            check_intersect=function(self, other)
                return false
            end,

            draw=function(self)
                rect(self.left, self.top, self.right, self.bottom, 8)
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
                if not(
                    obj1.left >= obj2.right or
                    obj1.right <= obj2.left or
                    obj1.top >= obj2.bottom or
                    obj1.bottom <= obj2.top
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

