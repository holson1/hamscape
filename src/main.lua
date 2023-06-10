-- sword 

function _init()
    -- global vars
    t=0
    at = 0
    cam = {
        x = 0,
        y = 0
    }
    msg=''

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

    char=init_char()
    item_map:set(26, 29, items.crab)

    npc_manager:add(npc_pig)
    collision_manager:register_collider('test_box', 250, 250, 256, 283, collision_manager.collider_types.solid)
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

    cam.x = max(char.x - 64, 0)
    cam.y = max(char.y - 64, 0)

    for d in all(dust) do
        d:update()
    end

    if (new_game_state) then
        game_state = new_game_state
        new_game_state = nil
    end

end

function _draw()
    cls()


    camera(cam.x, cam.y)
    map(0,0,0,0,128,64)

    item_map:draw()
    npc_manager:draw_all()
    char:draw()


    if (game_state == 'menu') then
        menu:draw()
    end

    if (game_state == 'talk') then
        dialog_manager:draw()
    end

    for d in all(dust) do
        d:draw()
    end

    debug()
end
