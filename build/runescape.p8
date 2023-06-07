pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--src/char.lua
function init_char()
    local char={
        x=200,
        y=240,
        dx=0,
        dy=0,
        runspeed=1,
        spr=004,
        spri=1,
        state='stand',
        flip=false,
        cell_x=0,
        cell_y=0,
        action_cell_x=0,
        action_cell_y=0,
        last_direction=0,
        health=10,
        max_health=10,
        stamina=20,
        max_stamina=20,
        exhausted=false,
        states={
            ['stand']={
                ['walk']=1,
            },
            ['walk']={
                ['stand']=1,
            }
        },
        animations={
            ['stand']={080},
            ['walk']={080,080},
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
            spr(self.spr,self.x,self.y,1,1,self.flip)

            -- stamina
            if (self.stamina < self.max_stamina) then
                local s_pct = (self.stamina / self.max_stamina) * 10
                local s_col = 11
                if (self.exhausted) then s_col = 8 end
                line(self.x - 1, self.y - 2, self.x + s_pct - 1, self.y - 2, s_col)
            end

            -- contextual action
            if (self.contextual_action and game_state == 'move') then
                print("\142: "..self.contextual_action, self.x + 10, self.y + 10, 7)
            end

        end
    }
    return char
end

function change_state(_char, next_state)
    if (_char.states[_char.state][next_state] ~= nil) then
        _char.state = next_state
        _char.spri = 1
    end
end

function get_input(_char)
    local action_key = (_char.action_cell_x * 8) .. '-' .. (_char.action_cell_y * 8)

    if (btn(0) and not(btn(1)) and not(btn(2)) and not(btn(3))) then
        local collision_cell = mget(_char.cell_x - 1, _char.cell_y)
        if (fget(collision_cell) == 1 or npc_manager._[action_key]) then
            _char.dx = 0
        else
            _char.dx = -char.runspeed
        end

        _char:change_state('walk')
        _char.flip = true
        _char.last_direction = 0
    elseif (btn(1) and not(btn(0)) and not(btn(2)) and not(btn(3)) ) then
        local collision_cell = mget(_char.cell_x + 1, _char.cell_y)
        if (fget(collision_cell) == 1 or npc_manager._[action_key]) then
            _char.dx = 0
        else
            _char.dx = char.runspeed
        end

        _char:change_state('walk')
        _char.flip = false
        _char.last_direction = 0.5
    elseif (btn(2) and not(btn(1)) and not(btn(0)) and not(btn(3))) then
        local collision_cell = mget(_char.cell_x, _char.cell_y - 1)
        if (fget(collision_cell) == 1 or npc_manager._[action_key]) then
            _char.dy = 0
        else
            _char.dy = -char.runspeed
        end

        _char:change_state('walk')
        _char.last_direction = 0.75
    elseif (btn(3) and not(btn(1)) and not(btn(2)) and not(btn(0))) then
        local collision_cell = mget(_char.cell_x, _char.cell_y + 1)
        if (fget(collision_cell) == 1 or npc_manager._[action_key]) then
            _char.dy = 0
        else
            _char.dy = char.runspeed
        end

        _char:change_state('walk')
        _char.last_direction = 0.25
    end

    if (btn(0) == btn(1)) then
        _char.dx = 0 
    end

    if (btn(2) == btn(3)) then
        _char.dy = 0 
    end 

    if (_char.dx == 0 and _char.dy == 0) then
        _char:change_state('stand')
    end

    -- determine contextual action
    _char.contextual_action = nil
    local action_key = (_char.action_cell_x * 8) .. '-' .. (_char.action_cell_y * 8)

    -- talk / npcs
    local npc_target = npc_manager._[action_key]
    if (npc_target) then
        _char.contextual_action = 'talk'
    end

    -- pickup items
    local cell_item = item_map:get(_char.cell_x, _char.cell_y)
    if (cell_item ~= nil) then
        _char.contextual_action = 'pickup'
    end

    -- action
    if (btnp(5)) then
        -- check the action cell to see if we should do something different

        -- item pickup
        if (_char.contextual_action == 'pickup') then
            local did_work = inventory:add(cell_item)
            if (did_work) then
                item_map:delete(_char.cell_x, _char.cell_y)
            end

            return
        end

        if (_char.contextual_action == 'talk') then
            new_game_state = 'talk'
            dialog_manager.current_npc = npc_target
            return
        end

        -- otherwise, just bring up the menu
        _char:menu()
    end

    -- run
    if (btn(4) and (abs(_char.dx) > 0 or abs(_char.dy) > 0)) then
        if (_char.stamina > 0 and _char.exhausted == false) then
            _char.runspeed = 1.5

            if (t % 8 == 0) then
                add_new_dust(_char.x + 4, _char.y + 7, 0, 0, 6, 2, 0, 7)
                _char.stamina -= 1
            end

            if (_char.stamina <= 0) then
                _char.runspeed = 1
                _char.exhausted = true
                _char.stamina = 0
            end
        end
    else
        _char.runspeed = 1
        if (t % 32 == 0 and _char.stamina < _char.max_stamina) then
            _char.stamina = min(_char.stamina + 1, _char.max_stamina)
            if (_char.exhausted and _char.stamina > (_char.max_stamina / 2)) then
                _char.exhausted = false
            end 
        end
    end
end

function update_char(_char)
    if (_char.pause) then
        return
    end

    _char:get_input()

    _char.y += _char.dy
    _char.x += _char.dx

    -- closest cell
    _char.cell_x = round((_char.x + (3 * cos(_char.last_direction) - 1)) / 8)
    _char.cell_y = round((_char.y + (3 * sin(_char.last_direction) - 1)) / 8)
    _char.action_cell_x = _char.cell_x - cos(_char.last_direction)
    _char.action_cell_y = _char.cell_y - sin(_char.last_direction)

    -- animation
    if (t % 4 == 0) then
        _char.spri = ((_char.spri + 1) % #_char.animations[_char.state]) + 1
    end

    _char.spr = _char.animations[_char.state][_char.spri]
end
-->8
--src/inventory.lua
inventory = {
    rows=5,
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
                if (self.items[i][j] == nil) then
                   self.items[i][j] = item
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


item_map = {
    _={},
    get = function(self, x, y)
        if (self._[y] ~= nil) then
            return self._[y][x]
        end
    end,
    set = function(self, x, y, item)
        if (self._[y] == nil) then
            self._[y] = {}
        end

        self._[y][x] = item
    end,
    delete = function(self, x, y)
        self:set(x, y, nil)
    end,
    draw = function(self)
        for i=1,64 do
            if (self._[i] ~= nil) then
                for j=1,64 do
                    if (self._[i][j] ~= nil) then
                        spr(self._[i][j].spr, j * 8, i * 8)
                    end
                end
            end
        end
    end
}
-->8
--src/lib/dust.lua
function add_new_dust(_x,_y,_dx,_dy,_l,_s,_g,_f)
    add(dust, {
    fade=_f,x=_x,y=_y,dx=_dx,dy=_dy,life=_l,orig_life=_l,rad=_s,col=8,grav=_g,draw=function(self)
    circfill(self.x,self.y,self.rad,self.col)
    end,update=function(self)
    self.x+=self.dx self.y+=self.dy
    self.dy+=self.grav self.rad*=0.9 self.life-=1
    if type(self.fade)=="table"then self.col=self.fade[flr(#self.fade*(self.life/self.orig_life))+1]else self.col=self.fade end
    if self.life<0then del(dust,self)end end})
end
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
--src/lib/util.lua
function rndi(min,max)
    return flr(rnd(max - min)) + min
end

function coord_match(a,b)
    return a[1] == b[1] and a[2] == b[2]
end

function in_bounds(a,b)
    return a > 0 and a < MAP_SIZE + 1 and b > 0 and b < MAP_SIZE + 1
end

function round(x)
    if ((x - flr(x)) >= 0.5) then
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
    if (current_item ~= nil) then
        item_s = current_item.name
    end


    vars = {
        't='..t,
        "at="..at,
        "acx="..char.action_cell_x,
        "acy="..char.action_cell_y,
        "item="..item_s
    }

    -- draw the log
    for i=count(_log)-log_l+1,count(_log) do
        add(vars,'> '.._log[i])
    end

    for i,v in ipairs(vars) do
        print(v,(cam.x)+8,(cam.y)+(i*8),15)
    end

    -- char action cells
    rect(char.cell_x * 8, char.cell_y * 8, (char.cell_x * 8) + 8, (char.cell_y * 8) + 8, 8)
    rect(char.action_cell_x * 8, char.action_cell_y * 8, (char.action_cell_x * 8) + 8, (char.action_cell_y * 8) + 8, 9)
end
-->8
--src/main.lua
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

    map(0,0,0,0,128,64)

    camera(cam.x, cam.y)

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
        if (btnp(0)) then
            self.cursor.x = max(self.cursor.x - 1, 1)
            add_new_dust(self.cursor.draw_x + 1, self.cursor.draw_y + 4, 1, 0, 6, 2, 0, 7)
            add_new_dust(self.cursor.draw_x + 1, self.cursor.draw_y + 4, 0.5, 0, 4, 1, 0, 7)
        end

        if (btnp(1)) then
            self.cursor.x = min(self.cursor.x + 1, inventory.cols)
            add_new_dust(self.cursor.draw_x + 1, self.cursor.draw_y + 4, -1, 0, 6, 2, 0, 7)
            add_new_dust(self.cursor.draw_x + 1, self.cursor.draw_y + 4, -0.5, 0, 4, 1, 0, 7)
        end

        if (btnp(2)) then
            self.cursor.y = max(self.cursor.y - 1, 1)
            add_new_dust(self.cursor.draw_x + 4, self.cursor.draw_y + 1, 0, 1, 6, 2, 0, 7)
            add_new_dust(self.cursor.draw_x + 4, self.cursor.draw_y + 1, 0, 0.5, 4, 1, 0, 7)
        end

        if (btnp(3)) then
            self.cursor.y = min(self.cursor.y + 1, inventory.rows)
            add_new_dust(self.cursor.draw_x + 4, self.cursor.draw_y + 1, 0, -1, 6, 2, 0, 7)
            add_new_dust(self.cursor.draw_x + 4, self.cursor.draw_y + 1, 0, -0.5, 4, 1, 0, 7)
        end 


        if (btnp(5)) then
            -- drop item
            if (self.selected_item) then
                item_map:set(char.cell_x, char.cell_y, inventory.items[self.cursor.x][self.cursor.y])
                inventory.items[self.cursor.x][self.cursor.y] = nil
            end
        end

        if (btnp(4)) then
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
                if (item ~= nil) then
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

        if (self.selected_item ~= nil) then
            print_centered(self.selected_item.name, self.positions.bottom_bar.left, self.positions.bottom_bar.right, self.positions.bottom_bar.top + 2, 7)
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
-->8
--src/npc.lua
npc_blueprint = {
    x=nil,
    y=nil,
    dx=0,
    dy=0,
    spr=nil,
    dialog=nil,
    update = function(self)
        -- -- walk randomly
        -- if (t % 64 == 0) then
        --     local dir = rnd({0, 0.25, 0.5, 0.75})
        --     self.dx = cos(dir) * 0.25
        --     self.dy = sin(dir) * 0.25
        -- end

        -- self.x += self.dx
        -- self.y += self.dy 
    end,
}

npc_manager = {
    _ = {},
    add=function(self,p)
        for k,v in pairs(npc_blueprint) do
            if v!=nil then
                p[k]=v
            end
        end
        local key = p.x .. '-' .. p.y
        self._[key] = p
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
            spr(v.s,v.x,v.y,1,1,v.flip)
        end
    end
}


npc_pig = {
    x = 208,
    y = 208,
    s = 084,
    dialog = 'oink!'
}

dialog_manager = {
    current_npc=nil,
    update = function(self)
        if (btnp(4) or btnp(5)) then
            self.current_npc = nil
            new_game_state = 'move'
        end
    end,
    draw = function(self)
        if (self.current_npc) then
            draw_menu_rect(
                16,
                111,
                111,
                127,
                7
            )
            print(self.current_npc.dialog, cam.x + 18, cam.y + 113, 7)
        end
    end
}
-->8
__gfx__
00000000000330000000000000000900000000000000000008000080000000000000000000000000000000000000000005000050000000000000000000000000
000000000003300000000000000099900000900000000cc08000000800004000004400000005000000000aa07777700005000050050000500000000000000000
00700700003033000003300000009790000090000000c0c0808888080004400000440000000000500000aaaa7888870000555500050000500000000000000000
0007700000333300033333300000290000099900000cccc00808808000044400000004400500000000a0aaaa7887887005555550055555500000000000000000
000770000330333033003333000200000099099000cccc000888888000444400044404440005000000000aa00788787005055050050000500000000000000000
00700700030333303033333300200000099009900cccc000888888880044444004440444000005000aa000000788787005055050055555500000000000000000
0000000033000333333333300200000009900990ccc00000088888800444444004440000005000000aa00a000078887005000050055005500000000000000000
00000000303333333333300300000000009999000c00000080800808044444400000000000000000000000000007770000000000055555500000000000000000
000000003003333303333330000004400000900000eeee0000800800000000770477700000007000000040000666666006666660000000040000000000000000
00000000033333300000000000404444000999000eeeeee00808080800000777040007000047770000777770611111166cccccc6000000e40ddddd0000000000
0000000000000000000440000004044400090900eeeeeeee8088808000007770040000700004770007004007611111166cccccc60000044e006666d000000000
0000000000044000004440000040440400990990e0ee00ee088888080607770004000007000400000000400066666666666666660000540e0066600000000000
00000000000444000004400004444040009009900ee0e0ee008888800667700000400007000040000000400066666666666666660004400e0066600000000000
0000000000044000000440004004040009900990e0e000ee880888800066000000400070000040000000400006666660066666600054000e0006000000000000
000000000004400000044000400440000990999000000ee000808888060660000040670000000400000040000666666006666660454000000000600000000000
00000000000440000004400004440000009999000000ee0008080088600000000040000000000400000040000066660000666600040000000000000000000000
000000b00000003000bb3b00000000a000000a000000000000000444000000000000000000003000000000000000000000000000000000000000000000000000
00000b33000099300b3b33b000000a0000000af00000000000004f4400bb00300b00300000000300000000000000000004a000f0000000000000000000000000
0000b33000099993b3b333b3000a0fa0000a0aaa00000000000444f40b00b030000000b0000088800000000008000080004a00a0000000000000000000000000
000b330000999990b3b333b300aa0f00000aa00000000000004f44400b00b00003000000000088800444444000088000000a0000000000000000000000000000
00b3300000999900b3b333b300a04f000a04aa0000fffff00444f4000b0000b0000030000008880049399994008888000a000400000000000000000000000000
0bbb000009999000b3b333b304f04f040a4000000fffffff4f4440000b030b0000b000000088800044999344008888000a000a00000000000000000000000000
7bb00000999900000b3b33b004f04f0404aa00000fffffff44f400000b030b0003000b000880000004444440000880000a0f00a0000000000000000000000000
770000009900000000bb3b0004f04f04400000000000000004400000000000000000000000000000004444000000000000000000000000000000000000000000
00000001111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000015151515150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001555155551550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00155155551555150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01555155551555150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04777777777777774ffffff44444444455555555000000000cc0000011111111333333336666666655555555ffffffff77777777222222220000000000000000
0477777477777777fff4ffff4777777456655555040004000ddccc7044144444333333336666666655555555ffffffff77777777200000026606600600000000
0477774777777777f4f4ffff47aaaa74555555550000004000c0000044144144333333336666666655555555ffffffff77777777200000020000666000000000
0477747777777777f4f4ff5f47aaaa745555566500400000000dddc044144144333333336666666655555555ffffffff77777777200000026600000000000000
0477477777777777f4f4ffff47aaaa7455555555000004007000000744144144333333336666666655555555ffffffff77777777200000020066606600000000
0474777777777777f4f4ffff47aaaa7456655555000400000dd07c0044144144333333336666666655555555ffffffff77777777200000020000000000000000
0447777777777777ffffffff47777774555555550400000400cd0dd044144144333333336666666655555555ffffffff77777777200000026606666000000000
0444444444444444ffffffff444444445555556600000400cc0000cc11111111333333336666666655555555ffffffff77777777222222220000000000000000
0bb00bb000000000000000000000000000eeee000070000700000000000000000000000000000000000000000000000000000000000000000000000000000000
0b1bb1b00000000000050555555555000eeeeee00070000700777700000000000000000000000000000000000000000000000000000000000000000000000000
0b1771b0000000000055555555555500ee77e77e0001711007717170000000000000000000000000000000000000000000000000000000000000000000000000
0bb11bb0000000000055555555555550ee71e17e0001711007717170000000000000000000000000000000000000000000000000000000000000000000000000
bb9999bb000000000055555555555550eeeeeeee0077777007777770000000000000000000000000000000000000000000000000000000000000000000000000
b099990b0000000000000555555555500ee1e1e00777776000777770000000000000000000000000000000000000000000000000000000000000000000000000
00bbbb0000000000000005555555550001eeee000071710000071700000000000000000000000000000000000000000000000000000000000000000000000000
0bb00bb000000000000555500005550000e00e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000646421640000008200000054001110101010100000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000646464820000000000708000000021101011116464000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000006464820000720070707000900000212100006472000082000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000008210007090900090000000008200726400000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000021706590900090700054000000646400826464000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005400700090005500700054545482640000006464000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000008070549080700000005400646472000072000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000009000000080707070000070000064646464008200000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000540000000000540000006464646464000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000900000000000000000006464646400000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000007000000000000072640082000000000000000000000000000000000000000000000000
__gff__
0001010000000001000000000000000000010101000000000000000001000000000000000000000000000000000000000000000000000000000000000000000001010000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
484848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000000000000000000227020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000000000000000000202020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000000000000000001201011201000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
484848000000000000000000000000000000000001010012003031310101111101130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a
4848480000000000000000000000000000280000011113000040414201111327010000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4848480000000000000000000000000000000000111913090909090911010013010101120101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
484848000000000000000000000000000000280000000000092c2c2c2c010000011201280101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048
484800000000000000000000000000000000000000000100092c2c2c2c010000012811130101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048
48480000000000000000000000000000464627002800111c002c2c2c2c114500010128010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048
4848000000000000000000000000000000464600000000002800000028004500010101110101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4848000000000000000000000000000000464646270000000000000000004500010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4848000000000000000000004545454545474747474545454545454545454500011201010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046
4848000000000000000000454500000000004646270228000000000000004500010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004800000000000000464646
