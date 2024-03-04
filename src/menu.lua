menu = {
    cursor = {
        x=1,
        y=1,
        draw_x=1,
        draw_y=1
    },
    positions = {
        inventory = {
            left = 80,
            top = 32,
            padding = {
                left = 3,
                right = 3,
                top = 9,
                bottom = 3
            },
            grid = {
                left = 0,
                top = 0
            }
        },
        bottom_bar = {
            left = 16,
            top = 119,
            right = 111,
            bottom = 127
        }
    },

    selected_item = nil,

    init = function(self)
        self.positions.inventory.grid.left = self.positions.inventory.left + self.positions.inventory.padding.left
        self.positions.inventory.grid.top = self.positions.inventory.top + self.positions.inventory.padding.top
    end,

    update = function(self)
        self.cursor.draw_x = cam.x + ((self.cursor.x - 1) * 8) + self.positions.inventory.grid.left
        self.cursor.draw_y = cam.y + ((self.cursor.y - 1) * 8) + self.positions.inventory.grid.top


        -- todo: refactor into input fn
        if btnp(0) then
            self.cursor.x = max(self.cursor.x - 1, 1)
        end

        if btnp(1) then
            self.cursor.x = min(self.cursor.x + 1, inventory.cols)
        end

        if btnp(2) then
            self.cursor.y = max(self.cursor.y - 1, 1)
        end

        if btnp(3) then
            self.cursor.y = min(self.cursor.y + 1, inventory.rows)
        end 


        if btnp(5) then
            -- drop item
            if self.selected_item then
                item_map:set(char.cell_x, char.cell_y, inventory.items[self.cursor.x][self.cursor.y])
                inventory.items[self.cursor.x][self.cursor.y] = nil
            end
        end

        if btnp(4) then
            new_game_state = 'move'
        end

        self.selected_item = inventory.items[self.cursor.x][self.cursor.y]
    end,

    draw = function(self)
        -- status
        draw_menu_rect(0,0,63,63,7)
        print('- status - ', cam.x + 12, cam.y + 2, 7)


        local inv_right = self.positions.inventory.grid.left + (inventory.cols * 8) + self.positions.inventory.padding.right

        -- inventory
        draw_menu_rect(
            self.positions.inventory.left,
            self.positions.inventory.top,
            inv_right,
            self.positions.inventory.grid.top + (inventory.rows * 8) + self.positions.inventory.padding.bottom,
            7
        )

        --print('-items-', cam.x + self., cam.y + 34, 7)
        print_centered('-items-', self.positions.inventory.left, inv_right, self.positions.inventory.top + 2, 7)

        for i=1,inventory.rows do
            for j=1,inventory.cols do
                local item = inventory.items[j][i]
                if item then
                    spr(item.spr, cam.x + self.positions.inventory.grid.left + ((j-1) * 8), cam.y + self.positions.inventory.grid.top + ((i-1) * 8))
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
        draw_menu_rect(
            self.positions.bottom_bar.left,
            self.positions.bottom_bar.top,
            self.positions.bottom_bar.right,
            self.positions.bottom_bar.bottom,
            7
        )

        if self.selected_item ~= nil then
            print_centered(self.selected_item.name, self.positions.bottom_bar.left, self.positions.bottom_bar.right, self.positions.bottom_bar.top + 2, 7)
        end

    end
}

function draw_menu_rect(x0, y0, x1, y1, color, transparent)
    if not(transparent) then
        rectfill(cam.x + x0, cam.y + y0, cam.x + x1, cam.y + y1, 0)
    end
    line(cam.x + x0 + 1, cam.y + y0, cam.x + x1 - 1, cam.y + y0, color)
    line(cam.x + x0, cam.y + y0 + 1, cam.x + x0, cam.y + y1 - 1, color)
    line(cam.x + x0 + 1, cam.y + y1, cam.x + x1 - 1, cam.y + y1, color)
    line(cam.x + x1, cam.y + y0 + 1, cam.x + x1, cam.y + y1 - 1, color)
end