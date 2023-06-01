_log={}
log_l=4
for i=1,log_l do
    add(_log,'')
end

function log(str)
    add(_log,str)
end
   
function debug()
    vars = {
        't='..t,
        "draw_x="..menu.cursor.draw_x
    }

    -- draw the log
    for i=count(_log)-log_l+1,count(_log) do
        add(vars,'> '.._log[i])
    end

    for i,v in ipairs(vars) do
        print(v,(cam.x)+8,(cam.y)+(i*8),15)
    end
end
