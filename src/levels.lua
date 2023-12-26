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
        ['26-23']="farm_house",
        ['24-21']="farm_shed"
    },
    load=function(self)
        item_map:set(26, 29, items.crab)

        npc_manager:add(npc_pig)
        npc_manager:add(npc_wizard)
        npc_manager:add(npc_cat)
        --npc_manager:add(enemy_gob)

        -- TODO: genericize this for many enemy types
        npc_manager:add(enemy_spawner)

        -- locked door (TODO: make a function for this)
        object_manager:add(24,21,066,{
            action={
                ['check']=function(self)
                    if inventory:has_item('shed key') then
                        object_manager:delete("24-21")
                        sfx(42)
                        return {"unlocked the door."}
                    else
                        return {"it's locked."}
                    end
                end
            }
        })

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

        item_map:set(10,10, items.shed_key)

        for i=4,12 do
            collision_manager:register_collider('map-'..i..'-8',i,8,collision_manager.collider_types.solid)
        end

        npc_manager:add(npc_farmer)
    end,
    update=function(self)
    end,
    draw=function(self)
        rect(32,64,104,104,4)
        rect(28,60,108,108,4)
        rectfill(64,104,72,112,0)
    end
}

levels.farm_shed = {
    char_x = 48,
    char_y = 56,
    exits={
        ['6-8']="overworld",
        ['7-4']="passage"
    },
    load=function(self)
        levels.overworld.char_x = 192
        levels.overworld.char_y = 168

        object_manager:add(7,4,088,{
            action={
                ['check']=function(self)
                    object_manager:delete("7-4")
                    sfx(42)
                    return {"removing the panel\nreveals a secret\npassage!"}
                end
            }
        })
    end,
    update=function(self)
    end,
    draw=function(self)
        rect(32,32,64,64,4)
        rect(28,28,68,68,4)
        rectfill(48,64,56,72,0)
    end
}

levels.passage = {
    char_x = 24,
    char_y = 16,
    exits={
        ['2-2']="farm_shed",
        ['11-2']="farm_house"
    },
    load=function(self)
        levels.farm_shed.char_x = 64
        levels.farm_shed.char_y = 32
        levels.farm_house.char_x = 32
        levels.farm_house.char_y = 48
    end,
    update=function(self)
    end,
    draw=function(self)
        rect(16,16,96,24,5)
        rect(12,12,100,28,5)
    end
}

levels.list = {
    ["overworld"]=levels.overworld,
    ["farm_house"]=levels.farm_house,
    ["farm_shed"]=levels.farm_shed,
    ["passage"]=levels.passage
}