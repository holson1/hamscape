-- sword 

function _init()
    -- global vars
    t=0
    at = 0
    cam = {
        x = 0,
        y = 0,
        cell_x = 0,
        cell_y = 0
    }
    msg=''
    level=levels.overworld

    -- states: move, menu, talk, etc.
    -- game states change control delegates
    game_state = 'move'
    new_game_state = nil

    -- thanks doc_robs!
    dust={}

    inventory.items[2][3] = items.log
    inventory.items[1][2] = items.crab
    inventory.items[3][6] = items.crab

    menu:init()
    map_manager:init()

    char=init_char()
    level:load()
end

function _update()
    --pal()
    t=(t+1)%128
    
    if ((t % 4) == 0) then
        at = (at+1)%16
    end

    if (game_state == 'move') then
        char:update()
        npc_manager:update_all()
    end

    if (game_state == 'menu') then
        menu:update()
    end

    if (game_state == 'talk') then
        dialog_manager:update()
    end

    if (game_state == 'battle') then
        battle_manager:update()
    end

    cam.x = max(char.x - 64, 0)
    cam.y = max(char.y - 64, 0)

    local old_cell_x = cam.cell_x
    local old_cell_y = cam.cell_y

    cam.cell_x = flr(cam.x / 8)
    cam.cell_y = flr(cam.y / 8)

    for d in all(dust) do
        d:update()
    end

    if (new_game_state) then
        game_state = new_game_state
        new_game_state = nil
    end

    level:update()

    if (level == levels.overworld) then
        if (cam.cell_x ~= old_cell_x or cam.cell_y ~= old_cell_y) then
            for i=cam.cell_x,cam.cell_x+17 do
                for j=cam.cell_y,cam.cell_y+17 do
                    local new_cell = mget(i,j)
                    if (fget(new_cell) == 1) then
                        collision_manager:register_collider(
                            'map-'..i..'-'..j,
                            i,
                            j,
                            collision_manager.collider_types.solid
                        )
                    end
                end 
            end
        end
    end

end

function _draw()
    cls()

    camera(cam.x, cam.y)
    level:draw()

    item_map:draw()
    npc_manager:draw_all()
    object_manager:draw_all()
    char:draw()

    -- foreground
    for i=char.cell_x-1,char.cell_x+1 do
        for j=char.cell_y-1,char.cell_y+1 do
            local sp = mget(i, j)
            if sp == 044 or sp == 035 or sp == 039 then
                local sx, sy = (sp % 16) * 8, flr(sp \ 16) * 8
                sspr(sx, sy+4, 8, 4, i*8, (j*8) + 4)
            end
        end
    end
    -- map(char.cell_x-1,char.cell_y-1,(char.cell_x-1) * 8, (char.cell_y-1) * 8,3,3,0x80)

    if (game_state == 'menu') then
        menu:draw()
    end

    if (game_state == 'talk') then
        dialog_manager:draw()
    end

    if (game_state == 'battle') then
        battle_manager:draw()
    end

    for d in all(dust) do
        d:draw()
    end

    --debug()
end
