battle_manager = {
    turn=0,
    enemy=nil,
    action_cd=0,
    selection=1,
    enemy_dmg=0,
    player_dmg=0,
    enemy_dmg_timer=0,
    player_dmg_timer=0,
    animation_timer=0,
    moves={
        {
            name='claw',
            cd=40,
            current_cd=0,
            use=function()
                sfx(42)
                battle_manager.animation_timer=10
                battle_manager:damage_enemy(1)
            end
        },
        {
            name='bite',
            cd=80,
            current_cd=0,
            use=function()
                sfx(40)
                battle_manager:damage_enemy(2)
            end
        },
        {
            name='run',
            cd=60,
            current_cd=0,
            use=function()
                if rnd(1) > 0.5 then
                    battle_manager.enemy = nil
                    new_game_state = 'move'
                end
            end
        }
    },
    load=function(self, enemy)
        self.enemy = enemy
        self.turn=0
    end,
    update = function(self)
        self.player_dmg_timer = max(0, self.player_dmg_timer - 1)
        self.enemy_dmg_timer = max(0, self.enemy_dmg_timer - 1)
        self.animation_timer = max(0, self.animation_timer - 1)

        if (self.animation_timer > 0) then
            if (abs(char.x - self.enemy.x) > 2 or abs(char.y - self.enemy.y) > 2) then
                char.x -= (char.x - self.enemy.x) / 2
                char.y -= (char.y - self.enemy.y) / 2
            end
        else
            char.x = (char.cell_x * 8)
            char.y = (char.cell_y * 8)
        end

        -- health check step
        if (self.enemy.health <= 0) then
            sfx(44)
            add_new_dust(self.enemy.x + 4, self.enemy.y + 4, rnd(2) - 1, -rnd(3), 25, 4, 0.2, 7)
            add_new_dust(self.enemy.x + 4, self.enemy.y + 4, rnd(2) - 1, -rnd(3), 25, 3, 0.2, 7)
            add_new_dust(self.enemy.x + 4, self.enemy.y + 4, rnd(2) - 1, -rnd(4), 25, 2, 0.2, 7)
            add_new_dust(self.enemy.x + 4, self.enemy.y + 4, rnd(2) - 1, -rnd(3), 25, 4, 0.2, 7)
            add_new_dust(self.enemy.x + 4, self.enemy.y + 4, rnd(2) - 1, -rnd(4), 25, 4, 0.1, 9)
            add_new_dust(self.enemy.x + 4, self.enemy.y + 4, rnd(2) - 1, -rnd(3), 25, 3, 0.1, 8)
            add_new_dust(self.enemy.x + 4, self.enemy.y + 4, rnd(2) - 1, -rnd(3), 25, 2, 0.1, 9)
            add_new_dust(self.enemy.x + 4, self.enemy.y + 4, rnd(2) - 1, -rnd(3), 25, 4, 0.1, 8)
            -- destroy the reference to the enemy
            local key = self.enemy.cell_x .. '-' .. self.enemy.cell_y
            npc_manager:delete(key)
            self.enemy = nil

            new_game_state = 'move'
            return
        end

        -- cooldown step
        for move in all(self.moves) do
            if (move.current_cd > 0) then
                move.current_cd -= 1
            end
        end

        if (self.action_cd > 0) then
            self.action_cd -= 1
            return
        end

        if (btnp(2)) then
            self.selection = max(self.selection - 1, 1)
        elseif (btnp(3)) then
            self.selection = min(self.selection + 1, #self.moves)
        end

        if (btnp(5)) then
            local move = self.moves[self.selection]
            if (move.current_cd == 0) then
                self.action_cd = 10
                move.current_cd = move.cd
                move.use(self.enemy)
            end
        end
    end,

    damage_enemy = function(self, dmg)
        self.enemy.health -= dmg
        self.enemy_dmg = dmg
        self.enemy_dmg_timer = 10
    end,

    draw = function(self)
        print('health: ' .. char.health, cam.x, cam.y, 8)
        print('enemy: ' .. self.enemy.health, cam.x, cam.y + 8, 8)

        draw_menu_rect(
            40,
            80,
            88,
            108,
            7
        )

        for i,move in ipairs(self.moves) do
            local move_color = 7
            if (move.current_cd ~= 0) then
                move_color = 6

                -- 86
                local cd_pct = (move.current_cd / move.cd)
                local bar = ((86 - 48) * cd_pct) + 48

                rectfill(cam.x + 48, cam.y + 76 + (i*6), cam.x + bar, cam.y + 80 + (i*6), 1)
            end

            print(move.name, cam.x + 48, cam.y + 76 + (i*6), move_color)
        end

        if (self.action_cd == 0) then
            print('>', cam.x + 42, cam.y + 76 + (self.selection * 6), 7)
        end

        if (self.enemy_dmg_timer > 0) then
            circfill(self.enemy.x + 4, self.enemy.y - 4, 3, 8)
            print(self.enemy_dmg, self.enemy.x + 3, self.enemy.y - 6, 7)
        end
        if (self.player_dmg_timer > 0) then
            circfill(char.x + 4, char.y - 4, 3, 8)
            print(self.player_dmg, char.x + 3, char.y - 6, 7)
        end
    end
}