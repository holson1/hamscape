items = {}

items.crab = {
    spr = 006,
    name = 'crab'
}

items.log = {
    spr = 019,
    name = 'log'
}

items.shed_key = {
    spr = 045,
    name = 'shed key'
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