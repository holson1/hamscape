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

        turn=function(self)
            for v in all(self._) do
                v:turn()
            end
        end,
        
        draw=function(self)
            for v in all(self._) do
                spr(v.s,v.x*8,v.y*8,1,1,v.flip)
            end
        end
    }
end