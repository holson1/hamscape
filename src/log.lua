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
        "colliders="..collision_manager.collider_count
    }

    --collision_manager:draw_colliders()

    -- draw the log
    for i=count(_log)-log_l+1,count(_log) do
        add(vars,'> '.._log[i])
    end

    for i,v in ipairs(vars) do
        print(v,(cam.x)+8,(cam.y)+(i*8),15)
    end

end
