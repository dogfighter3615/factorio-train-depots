-- File handling all guis

-----------------------Depot GUI---------------------------------------------------

---open the depot gui to choose a depot station to go to
---@param player LuaPlayer
function open_depot_gui(player)
    if player.opened.type ~= "locomotive" or player.opened.train == nil then return end
    local train = player.opened.train
    ----------------------main frame
    local screen_element = player.gui.relative
    for _,child in pairs(screen_element.children) do
        if child.name == 'train_depot_settings_frame' then
            child.destroy()
            break
        end
    end
    local train_depot_gui = screen_element.add{type = 'frame', name = 'train_depot_settings_frame', caption = 'train depot settings', anchor = {gui = defines.relative_gui_type.train_gui, position = defines.relative_gui_position.bottom}}
    train_depot_gui.style.size = {250,80}

    ----------------------dropdown box for selecting station
    local depot_selector_drop_down = train_depot_gui.add{type = 'drop-down', 
                                                        name = 'depot_selector_drop_down',
                                                        tooltip='select the depot station to go to'}
    depot_selector_drop_down.items = global.depot_array
    local selectedindex = 1
    for index,name in pairs(global.depot_array) do
        if train ~= nil then
            if global.train_table[train.id] == nil then 
                if type(train) == "LuaTrain" then
                    create_train_table_element(train)
                end
            else
                if name == global.train_table[train.id].selected_depot then 
                    selectedindex = index
                end
            end
        end
    end
    depot_selector_drop_down.selected_index = selectedindex

    ----------------------checkbox to opt in or out of depots
    if train ~= nil then
        if global.train_table[train.id] == nil then 
            if type(train) == "LuaTrain" then
                create_train_table_element(train)
            end
        else
            local depot_checkbox = train_depot_gui.add{type = "checkbox",name = "depot_checkbox",caption = "enable depots", 
                                                    state = global.train_table[train.id].enable_depot , tooltip ="select if trains should go to a depot"}
            depot_checkbox.location = {x = 0,y = 50}
        end
    end


end

---close the depot gui
---@param player LuaPlayer
function close_depot_gui(player)
    if player == nil then return end
    local screen_element = player.gui.relative
    for _,v in pairs(screen_element.children) do
        if v.name == "train_depot_settings_frame"then
            v.destroy()
        end        
    end
end
