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