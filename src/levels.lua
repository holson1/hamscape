levels={}

function transition_level(new_level)
    music(-1)
    npc_manager:flush()
    collision_manager:flush()
    level=new_level
    new_level:load()
    char.x = level.char_x
    char.y = level.char_y
    sfx(42)
end

levels.overworld = {
    char_x=200,
    char_y=240,
    exits={
        ['26-23']="farm_house"
    },
    load=function(self)
        item_map:set(26, 29, items.crab)

        npc_manager:add(npc_pig)
        npc_manager:add(npc_wizard)
        npc_manager:add(npc_cat)
        npc_manager:add(enemy_gob)

        --music(0, 3000)
    end,
    update=function(self)
    end,
    draw=function(self)
        map(cam.cell_x,cam.cell_y,cam.cell_x * 8, cam.cell_y* 8,17,17)
    end
}

levels.farm_house = {
    char_x = 64,
    char_y = 96,
    exits={
        ['8-13']="overworld"
    },
    load=function(self)
        levels.overworld.char_x = 208
        levels.overworld.char_y = 192
    end,
    update=function(self)
    end,
    draw=function(self)
        for i=4,12 do
            for j=8,12 do
                spr(088, i*8, j*8)
            end
        end

        rect(32,64,104,104,4)
        rect(28,60,108,108,4)
        rectfill(64,104,72,112,0)
    end
}

levels.list = {
    ["overworld"]=levels.overworld,
    ["farm_house"]=levels.farm_house
}