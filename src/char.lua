function init_char()
    local char={
        x=72,
        y=192,
        dx=0,
        dy=0,
        runspeed=1,
        spr=004,
        spri=1,
        state='stand',
        flip=false,
        states={
            ['stand']={
                ['walk']=1,
            },
            ['walk']={
                ['stand']=1,
            }
        },
        animations={
            ['stand']={004},
            ['walk']={004,004,020,020},
        },
        change_state=change_state,
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
    if (btn(0) and not(btn(1)) and not(btn(2)) and not(btn(3))) then
        _char.dx = -char.runspeed
        _char:change_state('walk')
        _char.flip = true
    elseif (btn(1) and not(btn(0)) and not(btn(2)) and not(btn(3)) ) then
        _char.dx = char.runspeed
        _char:change_state('walk')
        _char.flip = false
    elseif (btn(2) and not(btn(1)) and not(btn(0)) and not(btn(3))) then
        _char.dy = -char.runspeed
        _char:change_state('walk')
    elseif (btn(3) and not(btn(1)) and not(btn(2)) and not(btn(0))) then
        _char.dy = char.runspeed
        _char:change_state('walk')
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

    if (btnp(5)) then
        _char:menu()
    end

    if (btnp(4)) then
        _char:action()
    end
end

function update_char(_char)
    if (_char.pause) then
        return
    end

    _char:get_input()

    _char.y += _char.dy
    _char.x += _char.dx

    -- animation
    if (t % 4 == 0) then
        _char.spri = ((_char.spri + 1) % #_char.animations[_char.state]) + 1
    end

    _char.spr = _char.animations[_char.state][_char.spri]
end
