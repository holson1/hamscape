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
