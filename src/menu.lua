menu = {
    cursor = {
        x=1,
        y=1
    },
    selected_item = nil,

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

        self.selected_item = inventory.items[self.cursor.y][self.cursor.x]
    end,

    draw = function(self)
        -- status
        draw_menu_rect(0,0,63,63,7)
        print('- status - ', cam.x + 12, cam.y + 2, 7)


        -- inventory
        draw_menu_rect(96, 32, 127, 111, 7)

        print('-items-', cam.x + 98, cam.y + 34, 7)


        for i=1,9 do
            for j=1,4 do
                local item = inventory.items[i][j]
                if (item ~= nil) then
                    spr(item.spr, cam.x + 96 + ((j-1) * 8), cam.y + 40 + ((i-1) * 8))
                end
            end
        end

        -- cursor
        draw_menu_rect(
            ((self.cursor.x - 1) * 8) + 96,
            ((self.cursor.y - 1) * 8) + 40,
            ((self.cursor.x) * 8) + 96 - 1,
            ((self.cursor.y) * 8) + 40 - 1,
            8,
            true
        )


        -- bottom bar
        draw_menu_rect(16, 120, 111, 127, 7)

        if (self.selected_item ~= nil) then
            print(self.selected_item.name, cam.x + 48, cam.y + 122, 7)
        end

    end
}

function draw_menu_rect(x0, y0, x1, y1, color, transparent)
    if (not(transparent)) then
        rectfill(cam.x + x0, cam.y + y0, cam.x + x1, cam.y + y1, 0)
    end
    line(cam.x + x0 + 1, cam.y + y0, cam.x + x1 - 1, cam.y + y0, color)
    line(cam.x + x0, cam.y + y0 + 1, cam.x + x0, cam.y + y1 - 1, color)
    line(cam.x + x0 + 1, cam.y + y1, cam.x + x1 - 1, cam.y + y1, color)
    line(cam.x + x1, cam.y + y0 + 1, cam.x + x1, cam.y + y1 - 1, color)
end