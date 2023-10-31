--File with all event handlers in it

script.on_init(function ()
    OnInit()
end)

script.on_load(OnLoad)

script.on_configuration_changed(function (event)
    local mod_changes = event.mod_changes["train-depots"]
    if mod_changes ~= nil then
        if mod_changes.old_version ~= nil then
            create_train_table()
        end
    end
end)

script.on_nth_tick(60, function (event)
    if global.train_table == nil then
        global.train_table = {}
    end
    if global.depot_array == nil then
        global.depot_array = {}
    end
    create_stop_list()
end)

--start the clock to check the trains
script.on_nth_tick(tonumber(settings.global["time_between_checks"].value), function (event)
    if global.train_table == nil then
        global.train_table = {}
    end
    if global.depot_array == nil then
        global.depot_array = {}
    end
    check_station_trains()

end)

script.on_nth_tick(1,function (event)
    if global.train_table == nil then
        global.train_table = {}
    end
    if global.depot_array == nil then
        global.depot_array = {}
    end
    on_tick(event)
end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
    oncheckboxchanged(event)
end)

script.on_event(defines.events.on_gui_selection_state_changed, function (event)
    onselectionchanged(event)
end)

script.on_event(defines.events.on_runtime_mod_setting_changed,function (event)
    global.depot_array = create_depot_array(settings.global["depot_names"].value)
end)

script.on_event(defines.events.on_built_entity, function (event)
    if event.created_entity.type == 'locomotive' then 
        --game.print("hi"..event.created_entity.train.id)
        create_train_table_element(event.created_entity.train)
    end
end)

script.on_event(defines.events.on_robot_built_entity,function (event)
    if event.created_entity.type == 'locomotive' then 
        --game.print("hi"..event.created_entity.train.id)
        create_train_table_element(event.created_entity.train)
    end
end)

script.on_event(defines.events.on_entity_died, function (event)
    if event.entity.type == 'locomotive' then
        --game.print("removed train from table")
        global.train_table[event.entity.train.id] = nil
    end
end)

script.on_event(defines.events.on_player_mined_entity,function (event)
    if event.entity.type == 'locomotive'then
        --game.print("removed train from table")
        global.train_table[event.entity.train.id] = nil
    end
end)

script.on_event(defines.events.on_robot_mined_entity,function (event)
    if event.entity.type == 'locomotive'then
        --game.print("removed train from table")
        global.train_table[event.entity.train.id] = nil
    end
end)

script.on_event(defines.events.on_train_schedule_changed, function (event)
    if event.player_index ~= nil or event.mod_name ~= "train-depots" then
        if global.train_table[event.train.id] == nil then 
            create_train_table_element(event.train)
        end
        if global.train_table[event.train.id].go_to_depot then
            if event.train.schedule ~= nil then 
                local hasdepot
                for _,v in pairs(event.train.schedule.records) do
                    if v.station == global.train_table[event.train.id].selected_depot then
                        hasdepot = true 
                    end
                end
                if not hasdepot then 
                    global.train_table[event.train.id].go_to_depot = false
                end
            end
        end
    end
    update_train_table_train(event.train)
end)

--[
-- commented out because its not yet ready for use

--open the depot gui when you look at a train
script.on_event(defines.events.on_gui_opened, function (event)
    if event.entity == nil then return end
    if event.entity.type == 'locomotive' then
        local player = game.players[event.player_index]
        open_depot_gui(player)
    end
end)

--close the depot gui when the train gui is closed
script.on_event(defines.events.on_gui_closed,function (event)
    if event.entity == nil then return end
    if event.entity.type == 'locomotive' then
        local player = game.players[event.player_index]
        local screen_element = player.gui.relative
        for _,v in pairs(screen_element.children) do
            if v.name == "train_depot_settings_frame"then
                for _,k in pairs(v.children) do
                    if k.name == "depot_selector_drop_down" then
                        if global.train_table[event.entity.train.id] == nil then
                            create_train_table_element(event.entity.train)
                        else
                            global.train_table[event.entity.train.id].selected_depot = k.items[k.selected_index]
                        end
                    end 
                end
            end
        end
        close_depot_gui(player)

    end
end)
--]]
script.on_event(defines.events.on_train_changed_state, function (event)
    if global.station_list == nil then
        global.station_list = {}
    end
    if event.old_state==6 then
        train_enters_station(event)
        if print_trains_entering_station then
            game.print("train entered"..event.train.station.backer_name)
        end
    end
    if event.old_state == 7 then
        global.station_list[event.train.id] = nil
        update_train_table_train(event.train)
    end
end)