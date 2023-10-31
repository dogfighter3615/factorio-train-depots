--control.lua1

require "scripts/TrainTable.lua"
require "scripts/EventHandlers.lua"
require "scripts.Commands"
require "scripts/Gui.lua"
require "scripts.Utils"

--test if the mod is alive
script.on_event(defines.events.on_console_chat, function (event)
    if event.message=="hello mod" then
        game.print("hello "..game.get_player(event.player_index).name)
        local player = game.players[event.player_index]
        local player = game.players[event.player_index]
    end
end)

---checks stationed trains if they have to go to a depot or leave from there
function check_trains ()
    if global.depot_list == nil then
        global.depot_list = {}
    end
    for id,v in pairs(global.train_table)do
        local train = game.get_train_by_id(id)
        if train == nil then return end
        if train.valid ~= false and train.schedule ~= nil then
            if global.train_table[id].go_to_depot then
                local activelist = 0
                if train.schedule == nil then return end
                for _,v in pairs(train.schedule.records) do
                    if v.station ~= global.train_table[id].selected_depot then
                        if global.trainstop_table[v.station] then
                            activelist = activelist + 1
                        end
                    end
                end
                if (activelist > 1) then
                    local schedule = Utils.remove_stop_from_schedule(train.schedule,train.schedule.current,global.train_table[id].selected_depot)
                    local train = game.get_train_by_id(id)
                    if train == nil then return end
                    replace_train_schedule(
                        train,
                        schedule)
                    global.train_table[id].go_to_depot = false
                    global.train_table[id].at_depot = false
                end
            end
        end
    end
end



---create a list of all stops that are on the map, only stores name and active state
---stores the list as a table that is globally accessible and returns it
function create_stop_list()
    global.trainstop_table = {}
    local stops = game.get_train_stops()
    for _,v in pairs(stops) do
        local controlbehavior = v.get_control_behavior()
        if controlbehavior then
            if not global.trainstop_table[v.backer_name] then
                global.trainstop_table[v.backer_name] = not controlbehavior.disabled
            end
        else
            global.trainstop_table[v.backer_name] = true
        end
    end
    return table
end

---creates a train list, should only be used once per initiation. the list should be updated based on events instead
function create_train_list()
    global.train_list = {}
    global.depot_list = {}
    for _,sur in pairs(game.surfaces) do
        locomotives = sur.find_entities_filtered{type="locomotive"}
        for id,v in pairs(locomotives) do
            local train = game.get_train_by_id(id)
            if train == nil then return end
            global.train_list[v.backer_name] = train.schedule
        end
    end
end

---add the depot to the train schedule at the correct spot
---@param train LuaTrain
function send_train_to_depot(train)
    if global.train_table[train.id].go_to_depot == false then
        local current = train.schedule.current
        schedule = Utils.add_stop_in_schedule(train.schedule,Utils.create_schedule_table(current,train.id),current)
        replace_train_schedule(train,schedule)
        global.train_table[train.id].go_to_depot = true
    end
end

---updates the train list for when a train enters a station
---@param event EventData.on_train_changed_state
function train_enters_station(event)
    if global.train_table[event.train.id] == nil then
        create_train_table_element(event.train)
    end
    global.train_table[event.train.id].at_station = true
    if not event.train.manual_mode then
        if event.train.station ~= nil then
            if event.train.station.backer_name ~= global.train_table[event.train.id].selected_depot then
                local active_stops = 0
                for _,v in pairs(event.train.schedule.records) do
                    if global.trainstop_table == nil then
                        global.trainstop_table = {}
                    end
                    if global.trainstop_table[v.station] then
                        active_stops = active_stops + 1
                    end
                end
                if active_stops < 2 then
                    if global.train_table[event.train.id].enable_depot then
                        send_train_to_depot(event.train)
                    end
                end
            else if event.train.station.backer_name == global.train_table[event.train.id].selected_depot then
                global.train_table[event.train.id].at_depot = true
                for k,v in pairs(global.depot_list) do
                    if not v.valid == nil then
                        global.depot_list[k] = nil
                    end
                end
            end
        end
    end
end
end


function check_station_trains()
    for key,v in pairs(global.train_table) do
        local train = game.get_train_by_id(key)
        if train == nil then return end
        if train.valid == false then
            global.train_table[key] = nil
            return
        else
            if train.schedule == nil then break end
            if train.schedule.records[train.schedule.current].station == v.selected_depot then
                if not v.enable_depot then
                    local depotplace
                    for place,k in pairs(train.schedule.records) do
                        if k.station == v.selected_depot then
                            depotplace = place
                            break
                        end
                    end
                    local table = Utils.remove_stop_from_schedule(train.schedule,depotplace,v.selected_depot)
                    Utils.replace_train_schedule(train,table)
                end
            end
            if v.at_station and train.valid ~= false and v.enable_depot then
                if train.schedule ~= nil then
                    local active_stops = 0
                    local depotplace
                    for place,k in pairs(train.schedule.records) do
                        if global.trainstop_table[k.station] then
                            active_stops = active_stops + 1
                        end
                        if k.station == v.selected_depot then
                            depotplace = place
                        end
                    end
                    if active_stops > 2 and v.at_depot then
                        local table = Utils.remove_stop_from_schedule(train.schedule,depotplace,v.selected_depot)
                        replace_train_schedule(train,table)
                    else if active_stops < 2 then
                        local depot_stops = 0
                        for _,k in pairs(train.schedule.records) do
                            if k.station == v.selected_depot then
                                depot_stops = depot_stops+1
                            end
                        end
                        if depot_stops == 0 then
                            if v.enable_depot then
                                send_train_to_depot(train)
                            end
                        end
                    end
                end
                end
            end
        end
    end
end

---creates the array of possible depot station names
function create_depot_array(setting)
    global.depot_array = {}
    local depot_name = ""
    for i = 1 , #setting, 1 do
        local sub = string.sub(setting, i, i)
        if sub ~= "," then
            depot_name = depot_name .. sub
        else 
            global.depot_array[#global.depot_array+1] = depot_name
            depot_name = ""
        end
    end
    global.depot_array[#global.depot_array+1] = depot_name
    return global.depot_array
end


function on_tick(event)
    if PostLoad then
        PostLoad = false
        game.print("loaded")
        
        if global.depot_array == nil then
            create_depot_array(settings.global["depot_names"].value)
        end
        if global.train_table == nil then 
            create_train_table()
        end
        if global.trainstop_table == nil then 
            create_stop_list()
        end
    end
end

---do whatever needs to be done when loading a save
-- remember you dont have global table or game class idiot
function OnLoad()
    --PostLoad = true   
    register_commands()
end

---update the train_table.train variable if something changed
---@param train LuaTrain
function update_train_table_train(train)
    if global.train_table[train.id]==nil then
        create_train_table_element(train)
    end
    global.train_table[train.id].train = train
end