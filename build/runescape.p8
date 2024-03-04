pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--src/levels.lua
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
-->8
--src/items.lua
items = {}

items.crab = {
    spr = 006,
    name = 'crab'
}

items.log = {
    spr = 019,
    name = 'log'
}

-- potential token save:
-- items.shed_key = "045,shed key"
-- sprite,name,eatable,equip_slot,sfx
items.shed_key = {
    spr = 045,
    name = 'shed key'
}

item_map = {
    _={},
    get = function(self, x, y)
        if self._[y] ~= nil then
            return self._[y][x]
        end
    end,
    set = function(self, x, y, item)
        if self._[y] == nil then
            self._[y] = {}
        end

        self._[y][x] = item
    end,
    delete = function(self, x, y)
        self:set(x, y, nil)
    end,
    draw = function(self)
        for i=1,64 do
            if self._[i] ~= nil then
                for j=1,64 do
                    if self._[i][j] ~= nil then
                        spr(self._[i][j].spr, j * 8, i * 8)
                    end
                end
            end
        end
    end
}
-->8
--src/main.lua
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

    char=init_char()
    level:load()
end

function _update()
    --pal()
    t=(t+1)%128
    
    if t%4 == 0 then
        at = (at+1)%16
    end

    if game_state == 'move' then
        char:update()
        npc_manager:update_all()
    end

    if game_state == 'menu' then
        menu:update()
    end

    if game_state == 'talk' then
        dialog_manager:update()
    end

    if game_state == 'battle' then
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

    if new_game_state then
        game_state = new_game_state
        new_game_state = nil
    end

    level:update()

    if level == levels.overworld then
        if cam.cell_x ~= old_cell_x or cam.cell_y ~= old_cell_y then
            for i=cam.cell_x,cam.cell_x+17 do
                for j=cam.cell_y,cam.cell_y+17 do
                    local new_cell = mget(i,j)
                    if fget(new_cell) == 1 then
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

    if game_state == 'menu' then
        menu:draw()
    end

    if game_state == 'talk' then
        dialog_manager:draw()
    end

    if game_state == 'battle' then
        battle_manager:draw()
    end

    for d in all(dust) do
        d:draw()
    end

    --debug()
end
-->8
--src/inventory.lua
inventory = {
    rows=4,
    cols=5,
    items = {
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {}
    },
    add = function(self, item)
        -- add to the first free space
        for i=1,self.rows do
            for j=1,self.cols do
                if self.items[i][j] == nil then
                   self.items[i][j] = item
                   return true 
                end
            end
        end
        return false
    end,
    has_item= function(self,name)
        for i=1,self.rows do
            for j=1,self.cols do
                local item = self.items[i][j]
                if item and item.name == name then
                    return true
                end
            end
        end
        return false
    end,
    drop = function(self, x, y)
    end,
    remove = function(self, x, y)
    end
}
-->8
--src/object.lua
object_manager = {
    _ = {},
    add=function(self,x,y,s,options)
        collision_manager:register_collider(
            'obj'..x..'-'..y,
            x,
            y,
            collision_manager.collider_types.solid
        )

        local key = x .. '-' .. y

        local obj = {
            id='obj'..x..'-'..y,
            x=x,
            y=y,
            s=s
        }
        for k,v in pairs(options) do
            obj[k] = v
        end

        self._[key] = obj
    end,

    delete=function(self,key)
        local target_obj = self._[key]
        if target_obj ~= nil then
            collision_manager:delete_collider(target_obj.id)
        end
        self._[key] = nil
    end,

    flush=function(self)
        for k in pairs(self._) do
            self:delete(k)
        end
    end,
    
    -- TODO: only draw the objects that are on screen
    draw_all=function(self)
        for k,v in pairs(self._) do
            spr(v.s,v.x*8,v.y*8,1,1)
        end
    end
}
-->8
--src/stats.lua
stats = {
    xp=0,
    hp=10,
    attack=1,
    accuracy=0.75,
    defense=1,
    speed=1,
    evasion=0.05,
    woodcutting=1,
    fishing=1,
    mining=1
}
-->8
--src/menu.lua
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
-->8
--src/npc.lua
npc_blueprint = {
    id=nil,
    cell_x=nil,
    cell_y=nil,
    x=nil,
    y=nil,
    flip=false,
    spr=nil,
    script=nil,
    move_direction=nil,
    wander=true,
    update = function(self)
        if self.wander then
            if self.move_direction == nil then
                -- pick a random direction to move in
                if (t % 64 == 0) then
                    local dirs = {0,0.25,0.5,0.75}

                    self.move_direction = rnd(dirs)

                    if (self.move_direction ~= nil) then

                        if (self.move_direction == 0) then
                            self.flip = false
                        elseif (self.move_direction == 0.5) then
                            self.flip = true
                        end

                        -- check to see if the next cell is free
                        local test_collider = {id=self.id, x=0, y=0}
                        test_collider.x = self.cell_x - cos(self.move_direction)
                        test_collider.y = self.cell_y - sin(self.move_direction)

                        if (
                            collision_manager:test_intersect(test_collider, collision_manager.collider_types.solid) or
                            abs(test_collider.x - self.origin_x) > 3 or
                            abs(test_collider.y - self.origin_y) > 3
                        ) then
                            self.move_direction = nil
                        else
                            -- move the collider
                            self.collision_component:update(test_collider.x, test_collider.y)

                            local key = self.cell_x .. '-' .. self.cell_y
                            npc_manager._[test_collider.x .. '-' .. test_collider.y] = self
                            npc_manager._[key] = nil
                        end
                    end

                end
            else
                self.x -= cos(self.move_direction)
                self.y -= sin(self.move_direction)
                if self.x % 8 == 0 and self.y % 8 == 0 then
                    self.cell_x = self.x / 8
                    self.cell_y = self.y / 8
                    self.move_direction = nil
                end
            end
        else
            if t%16 == 0 then
                self.flip = not(self.flip)
            end
        end
    end
}

npc_manager = {
    _ = {},
    add=function(self,p)
        for k,v in pairs(npc_blueprint) do
            if v!=nil and p[k] == nil then
                p[k]=v
            end
        end

        p.collision_component = collision_manager:register_collider(
            p.id,
            p.cell_x,
            p.cell_y,
            collision_manager.collider_types.solid
        )

        p.x = p.cell_x * 8
        p.y = p.cell_y * 8
        p.origin_x = p.cell_x
        p.origin_y = p.cell_y

        local key = p.cell_x .. '-' .. p.cell_y
        self._[key] = p
    end,

    delete=function(self,key)
        local target_npc = self._[key]
        if target_npc ~= nil then
            collision_manager:delete_collider(target_npc.id)
        end
        self._[key] = nil
    end,

    flush=function(self)
        for k in pairs(self._) do
            self:delete(k)
        end
    end,
    
    -- TODO: only update the npcs that are on screen
    update_all=function(self)
        for k,v in pairs(self._) do
            v:update()
        end
    end,
    
    -- TODO: only draw the npcs that are on screen
    draw_all=function(self)
        for k,v in pairs(self._) do
            if v.s then
                spr(v.s,v.x,v.y,1,1,v.flip)
                if t % 16 > 8 then
                    rectfill(v.x,v.y,v.x+7,v.y+3,0)
                    spr(v.s,v.x,v.y+1,1,0.75,v.flip)
                end
                if v.hurt then
                    color_spr(v.s,8,v.x,v.y,v.flip)
                    v.hurt = false
                end
            end
        end
    end
}


npc_pig = {
    id='farm_pig',
    cell_x = 26,
    cell_y = 26,
    s = 084,
    script = function(self)
        return {'oink!'}
    end
}


npc_wizard = {
    id='wizard',
    cell_x = 29,
    cell_y = 37,
    s = 100,
    script = function(self)
        local dialog = {
            'blast, my journey was\ncut short by a bear!'
        }
        if npc_cat.talked and not(npc_cat.fed) then
            dialog = {
                'oh, my cat is hungry?',
                'let me summon him a\nnice tuna fish.',
                '...!',
                'there, that should make\nhim happy for a\nlittle while.'
            }
            npc_cat.fed = true
        end
        return dialog
    end
}

npc_cat = {
    id='cat',
    cell_x=19,
    cell_y=22,
    s = 101,
    wander=false,
    talked=false,
    fed = false,
    script = function(self)
        if self.fed then
            return {
                'thank you! *munch*\n(i must remember to bury\nthe leftovers...)'
            }
        else
            self.talked=true
            return {
                "that's right, i'm a cat.\njust like you~",
                "i'm also quite hungry.",
                "can you tell my owner\nto summon me some food?",
                "he's a \fcwizard\n\f7...so he can do that."
            }
        end
    end
}

npc_farmer = {
    id='farmer',
    cell_x=8,
    cell_y=9,
    s = 102,
    wander=false,
    script = function(self)
        return {'now where could i have\nleft that shed key?'}
    end
}

enemy_gob = {
    id='gob',
    cell_x=14,
    cell_y=30,
    s=080,
    hostile=true,
    hp=5,
    attack=2,
    speed=1,
    defense=1,
    accuracy=0.75,
    evasion=0.1
}

enemy_spawner = {
    id='spawner',
    cell_x=14,
    cell_y=28,
    count=0,
    update=function(self)
        if t == 1 and self.count < 3 then
            -- TODO: make this better
            local eid = rndi(1,99)
            local gob_copy = {}
            for k,v in pairs(enemy_gob) do
                gob_copy[k]=v
            end
            gob_copy.id = 'gob'..eid
            gob_copy.cell_x=rndi(9,16)
            gob_copy.cell_y=rndi(24,38)
            npc_manager:add(gob_copy)
            self.count += 1
        end
    end
}


dialog_manager = {
    current_npc=nil,
    char_counter=1,
    button_held=false,
    dialog_counter=1,
    dialog=nil,
    load=function(self)
        if self.current_npc.script == nil then
            self.current_npc = nil
            new_game_state = 'move'
            return
        end
        self.dialog_counter=1
        self.char_counter=1
        self.dialog=self.current_npc:script()
    end,
    update = function(self)
        local line = self.dialog[self.dialog_counter]

        if btnp(4) then
            self.current_npc = nil
            new_game_state = 'move'
            return
        end

        if btn(5) then
            if self.button_held == false then
                self.button_held = true

                -- move to end of text
                if self.char_counter < #line then
                    self.char_counter = #line
                    return
                end

                -- advance to next block
                self.dialog_counter +=1
                self.char_counter=1
                if self.dialog_counter > #self.dialog then
                    self.current_npc = nil
                    new_game_state = 'move'
                    return
                end
            end
        else
            self.button_held = false
        end

        if self.char_counter < #line then
            self.char_counter += 1
            sfx(rnd({47,47,48,47}))
        end
    end,
    draw = function(self)
        if self.current_npc then
            draw_menu_rect(
                8,
                103,
                119,
                127,
                7
            )
            local line = self.dialog[self.dialog_counter]
            local substring = sub(line, 1, self.char_counter)
            print(substring, cam.x + 18, cam.y + 105, 7)

            if self.char_counter >= #line and t%32 > 16 then
                print("\142", cam.x + 110, cam.y + 120, 7)
            end
        end
    end
}
-->8
--src/lib/group.lua
function new_group(bp)
    return {
        _={},
        bp=bp,
        
        new=function(self,p)
            for k,v in pairs(bp) do
                if v!=nil then
                    p[k]=v
                end
            end
            p.alive=true
            add(self._,p)
        end,
           
        update=function(self)
            for i,v in ipairs(self._) do
                v:update()
                if v.alive==false then
                del(self._,self._[i])
                end
            end
        end,
        
        draw=function(self)
            for v in all(self._) do
                spr(v.s,v.x,v.y,1,1,v.flip)
            end
        end
    }
end
-->8
--src/lib/collision.lua
collision_manager = {
    -- todo: quad tree to improve performance
    objects={},
    collider_count=0,
    collider_types = {
        solid='solid',
        overlap='overlap'
    },

    -- current behavior: overwrite anything with the same id
    register_collider=function(self, id, x, y, type)
        local new_collider = {
            id=id,
            x=x,
            y=y,
            type=type,

            update=function(self, x, y)
                self.x = x
                self.y = y
            end,

            check_intersect=function(self, other)
                return false
            end,

            draw=function(self)
                rect(self.x * 8, self.y * 8, (self.x * 8) + 8, (self.y * 8) + 8, 8)
            end
        }

        if (self.objects[id] == nil) then
            self.collider_count += 1
        end

        self.objects[id] = new_collider
        return new_collider
    end,

    delete_collider=function(self,id)
        self.objects[id] = nil
        self.collider_count -= 1
    end,
    
    flush=function(self)
        for k in pairs(self.objects) do
            self.objects[k] = nil
        end
        self.collider_count = 0
    end,

    test_intersect=function(self, obj1, type)
        for id,obj2 in pairs(self.objects) do
            if obj1.id ~= id then
                if obj1.x == obj2.x and obj1.y == obj2.y then
                    return true
                end
            end
        end
        return false
    end,

    draw_colliders=function(self)
        for id,obj in pairs(self.objects) do
            obj:draw()
        end
    end
}

-->8
--src/lib/dust.lua
-- TODO: refactor this, rn it can use up to 18 tokens per call
function add_new_dust(_x,_y,_dx,_dy,_l,_s,_g,_f)
    add(dust, {
    fade=_f,x=_x,y=_y,dx=_dx,dy=_dy,life=_l,orig_life=_l,rad=_s,col=1,grav=_g,draw=function(self)
    circfill(self.x,self.y,self.rad,self.col)
    end,update=function(self)
    self.x+=self.dx self.y+=self.dy
    self.dy+=self.grav self.rad*=0.9 self.life-=1
    if type(self.fade)=="table"then self.col=self.fade[flr(#self.fade*(self.life/self.orig_life))+1]else self.col=self.fade end
    if self.life<0then del(dust,self)end end})
end
-->8
--src/lib/util.lua
function rndi(min,max)
    return flr(rnd(max - min)) + min
end

function round(x)
    if (x - flr(x)) >= 0.5 then
        return ceil(x)
    else
        return flr(x)
    end
end

function print_centered(s, x1, x2, y, col)
    local str_w = #s * 2
    local center_point = ceil((x2 - x1) / 2) + x1
    print(s, cam.x + (center_point - str_w), cam.y + y, col)
end

function outline(s,x,y,c,o) -- 34 tokens, 5.7 seconds
    color(o)
    ?'\-f'..s..'\^g\-h'..s..'\^g\|f'..s..'\^g\|h'..s,x,y
    ?s,x,y,c
end

function outline_sprite(s,col_outline,x,y,flip)
    -- reset palette to col_outline
    for c=1,15 do
      pal(c,col_outline)
    end
    -- draw outline
    spr(s,x+1,y,1,1,flip)
    spr(s,x-1,y,1,1,flip)
    spr(s,x,y+1,1,1,flip)
    spr(s,x,y-1,1,1,flip)
  
    -- reset palette
    pal()
    -- draw final sprite
    spr(s,x,y,1,1,flip)  
end

function color_spr(s,col,x,y,flip)
    for c=1,15 do
      pal(c,col)
    end
    spr(s,x,y,1,1,flip)  
    pal()
end
-->8
--src/log.lua
_log={}
log_l=4
for i=1,log_l do
    add(_log,'')
end

function log(str)
    add(_log,str)
end
   
function debug()
    local current_item = item_map:get(char.action_cell_x, char.action_cell_y)
    local item_s = ''
    if current_item ~= nil then
        item_s = current_item.name
    end


    vars = {
        't='..t,
        "at="..at,
        "colliders="..collision_manager.collider_count
    }

    collision_manager:draw_colliders()

    -- draw the log
    for i=count(_log)-log_l+1,count(_log) do
        add(vars,'> '.._log[i])
    end

    for i,v in ipairs(vars) do
        print(v,(cam.x)+8,(cam.y)+(i*8),15)
    end

end
-->8
--src/char.lua
function init_char()
    local char={
        x=200,
        y=240,
        runspeed=1,
        spr=004,
        spri=1,
        state='stand',
        flip=false,
        facing_back=false,
        cell_x=0,
        cell_y=0,
        next_move=nil,
        is_moving=false,
        move_direction=0,
        facing=0,
        action_cell_x=0,
        action_cell_y=0,
        collision_component=nil,
        test_collider=nil,
        last_direction=0,
        health=10,
        max_health=10,
        stamina=20,
        max_stamina=20,
        exhausted=false,
        states={
            ['stand']={
                ['walk']=1,
                ['run']=1
            },
            ['walk']={
                ['stand']=1,
                ['run']=1
            },
            ['run']={
                ['stand']=1,
                ['walk']=1
            }
        },
        animations={
            ['stand']={096},
            ['stand_back']={098},
            ['walk']={096,096,097,097},
            ['walk_back']={098,098,099,099},
            ['run']={096,096,097,097},
            ['run_back']={098,098,099,099}
        },
        change_state=change_state,
        contextual_action=nil,
        get_input=get_input,
        update=update_char,
        menu=function(self)
            -- bring up pause / item menu
            new_game_state = 'menu'
        end,
        action=function(self)
            -- talk / read
            new_game_state = 'menu'
        end,

        draw=function(self)
            if self.state == 'run' then
                -- trails
                color_spr(self.spr,1,self.x+cos(self.last_direction)*4,self.y+sin(self.last_direction)*4,self.flip)
            end
            outline_sprite(self.spr,0,self.x,self.y,self.flip)

            -- stamina
            if self.stamina < self.max_stamina then
                local s_pct = (self.stamina / self.max_stamina) * 10
                local s_col = 11
                if self.exhausted then s_col = 8 end
                line(self.x - 1, self.y - 2, self.x + s_pct - 1, self.y - 2, s_col)
            end

            -- contextual action
            if self.contextual_action and game_state == 'move' then
                rectfill(self.x + 9, self.y + 9, self.x + 50, self.y + 15, 1)
                if self.pickup_text ~= nil then
                    print("\142: "..self.pickup_text, self.x + 10, self.y + 10, 7)
                else
                    print("\142: "..self.contextual_action, self.x + 10, self.y + 10, 7)
                end
            end

            -- debug collision
            -- rect((self.collision_component.x * 8), (self.collision_component.y *8), (self.collision_component.x *8)+ 8, (self.collision_component.y * 8)+8,8)
            -- if (self.test_collider ~= nil) then
            --     rect(self.test_collider.x * 8, self.test_collider.y * 8, (self.test_collider.x * 8) + 8, (self.test_collider.y * 8) + 8, 9)
            -- end

        end
    }

    char.collision_component = collision_manager:register_collider(
        'char',
        char.cell_x,
        char.cell_y,
        collision_manager.collider_types.solid
    )

    return char
end

function change_state(_char, next_state)
    if next_state ~= _char.state and _char.states[_char.state][next_state] ~= nil then
        _char.state = next_state
        _char.spri = 1
    end
end

function update_char(_char)
    if _char.pause then
        return
    end

    -- get the active cell
    _char.cell_x = flr(_char.x / 8)
    _char.cell_y = flr(_char.y / 8)

    next_move = nil

    -- stamina recovery
    if t % 32 == 0 and _char.state ~= 'run' and _char.stamina < _char.max_stamina then
        _char.stamina = min(_char.stamina + 1, _char.max_stamina)
        if _char.exhausted and _char.stamina > (_char.max_stamina / 2) then
            _char.exhausted = false
        end 
    end 

    -- get input for the given frame
    if btn(0) and not(btn(1)) and not(btn(2)) and not(btn(3)) then
        next_move = 0
        _char.last_direction = 0
    elseif btn(1) and not(btn(0)) and not(btn(2)) and not(btn(3)) then
        next_move = 0.5
        _char.last_direction = 0.5
    elseif btn(2) and not(btn(1)) and not(btn(0)) and not(btn(3)) then
        next_move = 0.75
        _char.last_direction = 0.75
    elseif btn(3) and not(btn(1)) and not(btn(2)) and not(btn(0)) then
        next_move = 0.25
        _char.last_direction = 0.25
    end

    next_state = _char.state

    -- if we're moving, we shouldn't change direction until we've landed squarely on a cell
    if _char.is_moving then
        
        -- move to cell
        _char.x -= cos(_char.move_direction) * _char.runspeed
        _char.y -= sin(_char.move_direction) * _char.runspeed

        if _char.state == 'run' then
            if t % 8 == 0 then
                add_new_dust(_char.x + 4, _char.y + 7, 0, 0, 6, 2, 0, 7)
                _char.stamina -= 2
                sfx(47)
            end


            if _char.stamina <= 0 then
                _char.runspeed = 1
                _char.exhausted = true
                _char.stamina = 0
                next_state = 'walk'
            end
        end

        -- landed on a cell
        if (_char.x % 8 <= 0.2 or _char.x % 8 >= 7.8) and (_char.y % 8 <= 0.2 or _char.y % 8 >= 7.8) then
            _char.x = round(_char.x)
            _char.y = round(_char.y)
            _char.is_moving = false

            _char.action_cell_x = (_char.x / 8) - cos(_char.last_direction)
            _char.action_cell_y = (_char.y / 8) - sin(_char.last_direction)

            _char.cell_x = flr(_char.x / 8)
            _char.cell_y = flr(_char.y / 8)

            -- check cell for exits
            local tile_key = _char.cell_x .. "-" .. _char.cell_y
            if level.exits[tile_key] ~= nil then
                local lv = levels.list[level.exits[tile_key]]
                transition_level(lv)
            end
        end
    end

    _char.contextual_action = nil
    _char.pickup_text = nil
    local action_key = (_char.action_cell_x) .. '-' .. (_char.action_cell_y)

    -- other objects (locks, trees, etc)
    local object_target = object_manager._[action_key]
    if object_target and object_target.action then
        if object_target.action['check'] then
            _char.contextual_action = 'check'
        end
    end

    -- talk / npcs
    local npc_target = npc_manager._[action_key]
    if npc_target then
        if npc_target.hostile then
            _char.contextual_action = 'fight'
        elseif npc_target.script ~= nil then
            _char.contextual_action = 'talk'
        end
    end

    -- pickup items
    local cell_item = item_map:get(_char.cell_x, _char.cell_y)
    if cell_item ~= nil then
        _char.contextual_action = 'pickup'
        _char.pickup_text = cell_item.name
    end

    -- action
    if btnp(5) then
        -- check the action cell to see if we should do something different


        if _char.contextual_action == 'check' then
            new_game_state = 'talk'
            dialog_manager.current_npc = {
                script=object_target.action['check']
            }
            dialog_manager:load()
            return
        end

        -- item pickup
        if _char.contextual_action == 'pickup' then
            local did_work = inventory:add(cell_item)
            if did_work then
                item_map:delete(_char.cell_x, _char.cell_y)
            end

            return
        end

        if _char.contextual_action == 'talk' then
            new_game_state = 'talk'
            dialog_manager.current_npc = npc_target
            dialog_manager:load()
            return
        end

        if _char.contextual_action == 'fight' then
            new_game_state = 'battle'
            battle_manager:load(npc_target)
            return
        end

        -- otherwise, just bring up the menu
        _char:menu()
    end

    -- if I'm on a cell and there's an input, read the next direction and get ready to move next frame
    if _char.is_moving == false then
        if next_move ~= nil then

            -- change facing direction
            _char.facing = next_move
            if next_move == 0 then
                _char.flip = true
                _char.facing_back = false
            elseif next_move == 0.25 then
                _char.facing_back = false
            elseif next_move == 0.5 then
                _char.flip = false
                _char.facing_back = false
            elseif next_move == 0.75 then
                _char.facing_back = true
            end

            _char.action_cell_x = _char.cell_x - cos(_char.last_direction)
            _char.action_cell_y = _char.cell_y - sin(_char.last_direction)

            -- check to see if the next cell is free
            _char.test_collider = {id='char', x=0, y=0}
            _char.test_collider.x = _char.cell_x - cos(next_move)
            _char.test_collider.y = _char.cell_y - sin(next_move)

            if collision_manager:test_intersect(_char.test_collider, collision_manager.collider_types.solid) then
                return
            end

            -- if it is...
            next_state = 'walk'

            _char.is_moving = true
            _char.move_direction = next_move
            _char.runspeed = 1

            if btn(4) then
                if _char.stamina > 0 and _char.exhausted == false then
                    _char.runspeed = 2
                    next_state = 'run'
                end
            end
        else
            next_state = 'stand'
        end
    end

    -- update state
    _char:change_state(next_state)

    _char.collision_component:update(_char.cell_x, _char.cell_y)

    -- _char.action_cell_x = _char.cell_x - cos(_char.last_direction)
    -- _char.action_cell_y = _char.cell_y - sin(_char.last_direction)

    -- animation, and update sprite
    current_anim = _char.state
    if _char.facing_back == true then
        current_anim = _char.state .. '_back'
    end
    if t % 4 == 0 then
        _char.spri = ((_char.spri + 1) % #_char.animations[current_anim]) + 1
    end

    _char.spr = _char.animations[current_anim][_char.spri]
end
-->8
--src/battle.lua
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
-->8
__gfx__
00000000000330000000000000000900000000000000000008000080000000000000000000000000000000000000000005000050000000000000000000000000
000000000003300000000000000099900000900000000cc08000000800004000004400000005000000000aa07777700005000050050000500000000000000000
00700700003033000003300000009790000090000000c0c0808888080004400000440000000000500000aaaa78888700005555000500005000000000000a9000
0007700000333300033333300000290000099900000cccc00808808000044400000004400500000000a0aaaa788788700555555005555550000000000a999a90
000770000330333033003333000200000099099000cccc000888888000444400044404440005000000000aa0078878700505505005000050000000009aa44999
00700700030333303033333300200000099009900cccc000888888880044444004440444000005000aa0000007887870050550500555555000000000a9499989
0000000033000333333333300200000009900990ccc00000088888800444444004440000005000000aa00a0000788870050000500550055000000000999a9a98
00000000303333333333300300000000009999000c000000808008080444444000000000000000000000000000077700000000000555555000000000a99998a4
000000003003333303333330000004400000900000eeee000080080000000077047770000000700000004000066666600666666000000004000000000a9a8440
00000000033333300000000000404444000999000eeeeee00808080800000777040007000047770000777770611111166cccccc6000000e40ddddd0000044000
0000000000000000000440000004044400090900eeeeeeee8088808000007770040000700004770007004007611111166cccccc60000044e006666d000044000
0000000000044000004440000040440400990990e0ee00ee088888080607770004000007000400000000400066666666666666660000540e0066600000444000
00000000000444000004400004444040009009900ee0e0ee008888800667700000400007000040000000400066666666666666660004400e0066600000044000
0000000000044000000440004004040009900990e0e000ee880888800066000000400070000040000000400006666660066666600054000e0006000000044000
000000000004400000044000400440000990999000000ee000808888060660000040670000000400000040000666666006666660454000000000600000044000
00000000000440000004400004440000009999000000ee0008080088600000000040000000000400000040000066660000666600040000000000000000044000
000000b00000003000bb3b00000000a000000a00000000000000044400000000000000000000300000000000000000000000000000000aa00000000000000000
00000b33000099300b3b33b000000a0000000af00000000000004f4400bb00300b00300000000300000000000000000004a000f00000700a0000000000000000
0000b33000099993b3b333b3000a0fa0000a0aaa00000000000444f40b00b030000000b0000088800000000008000080004a00a00000a0090000000000000000
000b330000999990b3b333b300aa0f00000aa00000000000004f44400b00b00003000000000088800444444000088000000a000000009a900000000000000000
00b3300000999900b3b333b300a04f000a04aa0000fffff00444f4000b0000b0000030000008880049399994008888000a000400000a00000000000000000000
0bbb000009999000b3b333b304f04f040a4000000fffffff4f4440000b030b0000b000000088800044999344008888000a000a0000a000000000000000000000
7bb00000999900000b3b33b004f04f0404aa00000fffffff44f400000b030b0003000b000880000004444440000880000a0f00a00a9000000000000000000000
770000009900000000bb3b0004f04f04400000000000000004400000000000000000000000000000004444000000000000000000a90900000000000000000000
00000001111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000015151515155100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001555155551555551000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00155155551555155515510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01555155551555155515551000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04777777777777774ffffff44444444455555555000000000cc0000011111111333333336666666655555555ffffffff77777777222222220000000077777740
0477777477777777fff4ffff4777777456655555040004000ddccc7044144444333333336666666655555555ffffffff77777777200000026606600647777740
0477774777777777f4f4ffff47aaaa74555555550000004000c0000044144144333333336666666655555555ffffffff77777777200000020000666074777740
0477747777777777f4f4ff5f47aaaa745555566500400000000dddc044144144333333336666666655555555ffffffff77777777200000026600000077477740
0477477777777777f4f4ffff47aaaa7455555555000004007000000744144144333333336666666655555555ffffffff77777777200000020066606677747740
0474777777777777f4f4ffff47aaaa7456655555000400000dd07c0044144144333333336666666655555555ffffffff77777777200000020000000077774740
0447777777777777ffffffff47777774555555550400000400cd0dd044144144333333336666666655555555ffffffff77777777200000026606666077777440
0444444444444444ffffffff444444445555556600000400cc0000cc11111111333333336666666655555555ffffffff77777777222222220000000044444440
0bb0033000000000000000000000000000eeee00007000070000000000000000444444444f4f4444000000000000000000000000000000000000000000000000
033bb1700000000000050555555555000eeeeee0007000070077770000000710ffff44ff4f4f4fff000000000000000000000000000000000000000000000000
01733170000000000055555555555500e77e77ee00017110077171700000076044ffffff4f4f4444000000000000000000000000000000000000000000000000
0b3133b0000000000055555555555550e71e17ee000171100771717000007600ffffffff4f4f4fff000000000000000000000000000000000000000000000000
bb7e79bb000000000055555555555550eeeeeeee0077777007777770000760004444444444444444000000000000000000000000000000000000000000000000
b099990b0000000000000555555555500e1e1ee0077777600077777007760000ffffff44fff4f4f4000000000000000000000000000000000000000000000000
00b33b0000000000000005555555550000eeee10007171000007170001600000ff44ffff4444f4f4000000000000000000000000000000000000000000000000
0bb00bb000000000000555500005550000e00e000000000000000000000000004ffffffffff4f4f4000000000000000000000000000000000000000000000000
000000000010000000000000000000000000d0000161161000044000000000000000000000000000000000000000000000000000000000000000000000000000
10700400017004004010010004100100040dd0000166661000444400000000000000000000000000000000000000000000000000000000000000000000000000
0177740001777400041111000411110040dddd001616616144444444000000000000000000000000000000000000000000000000000000000000000000000000
071741400717414001441110014411104dddddd01616616100f1f106000000000000000000000000000000000000000000000000000000000000000000000000
07174140071741400475411004754110404f47001566665100ffff06000000000000000000000000000000000000000000000000000000000000000000000000
017444100174441004777110047771104d7777d00155a5150f6116ff000000000000000000000000000000000000000000000000000000000000000000000000
0141110001111400040071000400710040d77d00156666550f111106000000000000000000000000000000000000000000000000000000000000000000000000
0100140001410000040001000000700040ddddd01565565100550556000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000a10054540000f07200310082646421640000008200000054001110101010100000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a090700054003232f10313133100646464820000000000708000000021101011116464000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000700054000072000434143431646464820000720070707000900000212100006472000082000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000080007070707000b10414240431006464008210007090900090000000008200726400000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000008000a0700070000000000000006464000021706590900090700054000000646400826464000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000064645400700090005500700054545482640000006464000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000064640000008070549080700000005400646472000072000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000646400000080707070000070000064646464008200000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000647064540000000000540000006482826464220000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000646464647000000000000000006472826400000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000006464646464647000000000820064647282000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000064646464646464648200720000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000064646470706464720064640000640000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000646464800082002264648200728200000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000646400000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000646490005400000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000646400000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000006464900000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000064640000540000000000000000000000000000000000000000000000000000000000000000
__gff__
0001010000000001000000000000000100010101000000000000000001000001000000000000008000000000800000000101010000000000000000000000000001010000000001000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4848484848484848484848484848484848484848484848484848484848484646464a4a4a4a4a4a4a4a4a4a4a4a4a4a000000000000000000000000000000000000484848484848484848484848484a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a
484848484848484848484848484848484848484848480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a4a4a4a4a4a00000000000000000000000000000000000000000000004a4a
4848484848484848484848484848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a4a
4848484848484848484848480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a4a
484848484848484848480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848484848484800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
4848484848480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a4a
4848484848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a4a
484848484800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000004646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000004646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000000046460000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000000046460000000227020001010000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000000046460000000202020130320201010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000000046460000001201011240421201010100010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000000046460000000001011313003031320101111101130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
4848480000000000000000000000464600280000011113000040424f01111327010000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4848480000000000000000000000004600000000111913090909090911010013010101120101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
484848000000000000000000000000464600280000000000092c232323010000011201280101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048
484800000000000000000000000000464646000000000100092c2c2c23010000012811130101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048
484800000000000000000f2845000f00464627002800111c002c2c2c2c114500010128010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048
484800000000000000231f0045231f2300464600000000002800000028004500010101110101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4848000000000000232323004500000028464646270000000000000000004500010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4848000000000013232300004545454545474747474545454545454545454500011201010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046
4848000000090000000045454528000000004646270228000000000000004500010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004800000000000000464646
__sfx__
010100001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01110000100500000000000000000000000000000000000010050000000000000000000000000000000000001005000000000000000000000000000000000000100500000000000000000e050000000000000000
491100003361200000336153361533615336153361533605336120000033615000003361533605000000000033612000003361533615336153361533615336131c61500000386120000033615000003360500000
3f11000021050000002805528055280552800028050000002a050000002b0002b050260502605026055000001e05000000260500000026050000001e050000001f050000001e050000001a0501a0501a05500000
3f11000021050000002805528055280552800028050000002a050000002b0002b050260502605026055000002f0500000028050000002d0502b0502a0500000026050000002a0500000028050280502805500000
3111000024524285242b5242f52424524285242b5242f52424524285242b5242f52424524285242b5242f5242b5242f52432524365242b5242f52432524365242b5242f52432524365242b5242f5243252436524
011100000c0500c0500c0550c000000000000000000000000c0500c0500c055000000000000000000000000013050130501305500000000000000000000000001305013050130550000015050150501000000000
011100001100000000000000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0112000018050000001f050000001f050000002700000000000000000000000000000000000000170502700018050000001f050000001f0500000027000000000000000000000000000000000000001700000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000076500965011650116500a6500b65008650316502a650244502045016450104500b650096500865005650016500065003650046500365003650016500065000000000000000000000000000000000000
0002000022150201501f2501b150181501515011150101500e1500b15008130041400215001600016000160000600006000060000600000000000000000000000000000000000000000000000000000000000000
0001000005650076500b6500b6501165015650196501d650246501b650106500c6500865007650036500365000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000111501115016150181501b1501c150201502115024150251502615026150241501f1501b150190501415014150141501215014150141500f150131501315013150131501215014150161501b1501d150
00060000216501e65023650176500e63007620046500865008650076200362002620016200562005620076200a61004610096100961000000046000f600036000000000000000000000000000000000000000000
00060000280502d050000002d040000002d030000002d020000002d01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c0000075500b5500f55014550175501b5501d55022550255500d5501155015550175501c5502055024550285502a550225502a550255402a540225202a520255002a5102f5002a510000002a5100000000000
000100002662026620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002c0202c020186201762015620146000460001600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000155501e550076500765005650106500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000009530085200a5200c5100e5100d5500955007550075500755005550055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01424344
00 01024344
00 01020344
00 01020444
00 01020344
00 01020444
00 06020544
00 06020544
00 06420541
02 06424544

