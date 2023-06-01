menu = {
    cursor = {
        x=1,
        y=1,
        draw_x=1,
        draw_y=1
    },
    selected_item = nil,

    update = function(self)

        self.cursor.draw_x = cam.x + ((self.cursor.x - 1) * 8) + 93
        self.cursor.draw_y = cam.y + ((self.cursor.y - 1) * 8) + 40

        if (btnp(0)) then
            self.cursor.x = max(self.cursor.x - 1, 1)
            add_new_dust(self.cursor.draw_x + 1, self.cursor.draw_y + 4, 1, 0, 6, 2, 0, 7)
            add_new_dust(self.cursor.draw_x + 1, self.cursor.draw_y + 4, 0.5, 0, 4, 1, 0, 7)
        end

        if (btnp(1)) then
            self.cursor.x = min(self.cursor.x + 1, 4)
            add_new_dust(self.cursor.draw_x + 1, self.cursor.draw_y + 4, -1, 0, 6, 2, 0, 7)
            add_new_dust(self.cursor.draw_x + 1, self.cursor.draw_y + 4, -0.5, 0, 4, 1, 0, 7)
        end

        if (btnp(2)) then
            self.cursor.y = max(self.cursor.y - 1, 1)
            add_new_dust(self.cursor.draw_x + 4, self.cursor.draw_y + 1, 0, 1, 6, 2, 0, 7)
            add_new_dust(self.cursor.draw_x + 4, self.cursor.draw_y + 1, 0, 0.5, 4, 1, 0, 7)
        end

        if (btnp(3)) then
            self.cursor.y = min(self.cursor.y + 1, 9)
            add_new_dust(self.cursor.draw_x + 4, self.cursor.draw_y + 1, 0, -1, 6, 2, 0, 7)
            add_new_dust(self.cursor.draw_x + 4, self.cursor.draw_y + 1, 0, -0.5, 4, 1, 0, 7)
        end 


        if (btnp(4)) then
            game_state = 'move'
        end

        self.selected_item = inventory.items[self.cursor.x][self.cursor.y]
    end,

    draw = function(self)
        -- status
        draw_menu_rect(0,0,63,63,7)
        print('- status - ', cam.x + 12, cam.y + 2, 7)


        -- inventory
        draw_menu_rect(90, 32, 127, 114, 7)

        print('-items-', cam.x + 98, cam.y + 34, 7)


        for i=1,9 do
            for j=1,4 do
                local item = inventory.items[j][i]
                if (item ~= nil) then
                    spr(item.spr, cam.x + 93 + ((j-1) * 8), cam.y + 40 + ((i-1) * 8))
                end
            end
        end

        -- cursor
        draw_menu_rect(
            self.cursor.draw_x - cam.x,
            self.cursor.draw_y - cam.y,
            self.cursor.draw_x - cam.x + 8,
            self.cursor.draw_y - cam.y + 8,
            7,
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