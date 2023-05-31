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