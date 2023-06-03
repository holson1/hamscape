-- sword 

function _init()
    -- global vars
    t=0
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
end

function _update()
    --pal()
    t=(t+1)%128

    if (game_state == 'move') then
        char:update()
    end

    if (game_state == 'menu') then
        menu:update()
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

    map(0,0,0,0,128,64)

    camera(cam.x, cam.y)
    char:draw()

    if (game_state == 'menu') then
        menu:draw()
    end

    for d in all(dust) do
        d:draw()
    end

    --debug()
end
