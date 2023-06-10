collision_manager = {
    -- todo: quad tree to improve performance
    objects={},
    collider_types = {
        solid='solid',
        overlap='ovelap'
    },

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

        add(self.objects, new_collider)
        return new_collider
    end,

    test_intersect=function(self, obj1, type)
        for obj2 in all(self.objects) do
            if (obj1.id ~= obj2.id) then
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
        for obj in all(self.objects) do
            obj:draw()
        end
    end
}

