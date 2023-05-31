menu = {
    cursor = {
        x=1,
        y=1
    },

    update = function(self)

        if (btnp(0)) then
            self.cursor.x = max(self.cursor.x - 1, 1)
        end

        if (btnp(1)) then
            self.cursor.x = min(self.cursor.x + 1, 4)
        end

        if (btnp(2)) then
            self.cursor.y = max(self.cursor.y - 1, 1)
        end

        if (btnp(3)) then
            self.cursor.y = min(self.cursor.y + 1, 9)
        end 


        if (btnp(4)) then
            game_state = 'move'
        end
    end,

    draw = function(self)
        -- status
        draw_menu_rect(0,0,63,63,7)
        print('- status - ', cam.x + 12, cam.y + 2, 7)


        -- inventory
        draw_menu_rect(96, 32, 127, 111, 7)

        print('-items-', cam.x + 98, cam.y + 34, 7)

        -- cursor
        draw_menu_rect(
            ((self.cursor.x - 1) * 8) + 96,
            ((self.cursor.y - 1) * 8) + 40,
            ((self.cursor.x) * 8) + 96 - 1,
            ((self.cursor.y) * 8) + 40 - 1,
            8
        )

        -- bottom bar
        draw_menu_rect(16, 120, 111, 127, 7)

    end
}

function draw_menu_rect(x0, y0, x1, y1, color)
    rectfill(cam.x + x0, cam.y + y0, cam.x + x1, cam.y + y1, 0)
    line(cam.x + x0 + 1, cam.y + y0, cam.x + x1 - 1, cam.y + y0, color)
    line(cam.x + x0, cam.y + y0 + 1, cam.x + x0, cam.y + y1 - 1, color)
    line(cam.x + x0 + 1, cam.y + y1, cam.x + x1 - 1, cam.y + y1, color)
    line(cam.x + x1, cam.y + y0 + 1, cam.x + x1, cam.y + y1 - 1, color)
end