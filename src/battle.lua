battle_manager = {
    turn=0,
    enemy=nil,
    battle_won=false,
    action_cd=0,
    enemy_cd=0,
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
                battle_manager.animation_timer=10
                battle_manager:attack_enemy(1)
            end
        },
        {
            name='bite',
            cd=80,
            current_cd=0,
            use=function()
                sfx(40)
                battle_manager:attack_enemy(2)
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
        self.enemy_cd = 30
        self.turn=0
        self.battle_won = false
    end,
    update = function(self)
        -- cooldown step
        self.player_dmg_timer = max(0, self.player_dmg_timer - 1)
        self.enemy_dmg_timer = max(0, self.enemy_dmg_timer - 1)
        self.animation_timer = max(0, self.animation_timer - 1)
        self.enemy_cd = max(0, self.enemy_cd - 1)
        self.action_cd = max(0, self.action_cd -1)
        for move in all(self.moves) do
            if move.current_cd > 0 then
                move.current_cd -= 1
            end
        end

        -- selection UI
        if btnp(2) then
            self.selection = max(self.selection - 1, 1)
        elseif btnp(3) then
            self.selection = min(self.selection + 1, #self.moves)
        end

        -- health check step
        if self.enemy.hp <= 0 and not(self.battle_won) then
            sfx(44)
            -- TODO: genericize / reduce token usage, this is almost 200 tokens right here!!
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
            self.battle_won = true
            npc_manager:delete(key)
            enemy_spawner.count -= 1
        end

        if self.turn == 0 and not(self.battle_won) then
            -- enemy action
            if self.enemy_cd == 0 then
                self:attack_player()
                self.enemy_cd=60+rndi(1,20)
                self.animation_timer=10
                self.turn = 2
            end

            -- player action
            if btnp(5) then
                local move = self.moves[self.selection]
                if move.current_cd == 0 then
                    self.action_cd = 10
                    move.current_cd = move.cd
                    move.use(self.enemy)
                    self.turn = 1
                end
            end
        else
            if self.animation_timer > 0 then
                if self.turn == 1 then
                    -- move char to attack
                    if (abs(char.x - self.enemy.x) > 2 or abs(char.y - self.enemy.y) > 2) then
                        char.x -= (char.x - self.enemy.x) / 2
                        char.y -= (char.y - self.enemy.y) / 2
                    end
                elseif self.turn == 2 then
                    -- if (abs(self.enemy.x - char.x) > 2 or abs(self.enemy.y - char.y) > 2) then
                    --     self.enemy.x -= (self.enemy.x - char.x) / 4
                    --     self.enemy.y -= (self.enemy.y - char.y) / 4
                    -- end
                end
            else
                self.turn = 0
                char.x = (char.cell_x * 8)
                char.y = (char.cell_y * 8)

                if self.battle_won and self.enemy_dmg_timer == 0 then
                    -- temp win battle + xp TODO move this
                    stats.attack += 1
                    stats.accuracy += 0.05
                    stats.evasion += 0.05
                    stats.defense += 0.2
                    
                    sfx(45)
                    new_game_state = 'move'
                    self.enemy = nil
                    return
                end
            end
        end
    end,

    attack_enemy = function(self, raw_dmg)
        local did_hit = rnd(1) < (stats.accuracy - self.enemy.evasion)
        if did_hit then
            local dmg = round(raw_dmg + (stats.attack / 5) + rnd(0.5) - self.enemy.defense)
            if dmg > 0 then
                sfx(42)
                self.enemy.hp -= dmg
                self.enemy_dmg = dmg
                self.enemy_dmg_timer = 20
                add_new_dust(self.enemy.x + 4, self.enemy.y + 4, rnd(2) - 1, -rnd(1), 15, 2, 0.1, 8)
                add_new_dust(self.enemy.x + 4, self.enemy.y + 4, rnd(2) - 1, -rnd(1), 15, 3, 0.1, 8)
                self.enemy.hurt = true
                return
            end
        end
        sfx(50)
        self.enemy_dmg = 0
        self.enemy_dmg_timer = 20
    end,

    attack_player = function(self)
        local did_hit = rnd(1) < (self.enemy.accuracy - stats.evasion)
        if did_hit then
            local dmg = flr(self.enemy.attack - stats.defense)
            if dmg > 0 then
                sfx(41)
                stats.hp -= dmg
                self.player_dmg = dmg
                self.player_dmg_timer = 20
                add_new_dust(char.x + 4, char.y + 4, rnd(2) - 1, -rnd(1), 15, 2, 0.1, 8)
                add_new_dust(char.x + 4, char.y + 4, rnd(2) - 1, -rnd(1), 15, 3, 0.1, 8)
                return
            end
        end
        sfx(50)
        self.player_dmg = 0
        self.player_dmg_timer = 20
    end,

    draw = function(self)
        print('health: ' .. stats.hp, cam.x, cam.y, 8)
        print('enemy: ' .. self.enemy.hp, cam.x, cam.y + 8, 8)

        draw_menu_rect(
            40,
            80,
            88,
            108,
            7
        )

        for i,move in ipairs(self.moves) do
            local move_color = 7
            if move.current_cd ~= 0 then
                move_color = 6

                -- 86
                local cd_pct = (move.current_cd / move.cd)
                local bar = ((86 - 48) * cd_pct) + 48

                rectfill(cam.x + 48, cam.y + 76 + (i*6), cam.x + bar, cam.y + 80 + (i*6), 1)
            end

            print(move.name, cam.x + 48, cam.y + 76 + (i*6), move_color)
        end

        if self.action_cd == 0 then
            print('>', cam.x + 42, cam.y + 76 + (self.selection * 6), 7)
        end

        if self.enemy_dmg_timer > 0 then
            local pct = 1 - (self.enemy_dmg_timer / 15)
            local number_color = self.enemy_dmg > 0 and 8 or 1
            outline(self.enemy_dmg, self.enemy.x + 2, self.enemy.y - 4 - (4 * pct), 7, number_color)
        end
        if self.player_dmg_timer > 0 then
            local pct = 1 - (self.player_dmg_timer / 15)
            local number_color = self.player_dmg > 0 and 8 or 1
            outline(self.player_dmg, char.x + 2, char.y - 4 - (4 * pct), 7, number_color)
        end
    end
}