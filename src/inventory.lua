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
                if (self.items[i][j] == nil) then
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
