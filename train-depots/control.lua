--control.lua


---convert a table into a string
---@param tbl table
---@return string
function tableToString(tbl, indent)
    if not indent then
        indent = 0
    end

    local result = "{\n"
    local first = true

    for k, v in pairs(tbl) do
        if not first then
            result = result .. ",\n"
        end

        if type(k) == "number" then
            result = result .. string.rep(" ", indent + 2) .. k .. " = "
            if type(v) == "table" then
                result = result .. tableToString(v, indent + 2)
            else
                result = result .. tostring(v)
            end
        elseif type(k) == "string" then
            result = result .. string.rep(" ", indent + 2) .. k .. " = "
            if type(v) == "table" then
                result = result .. tableToString(v, indent + 2)
            else
                result = result .. tostring(v)
            end
        end

        first = false
    end

    result = result .. "\n" .. string.rep(" ", indent) .. "}"
    return result
end

---create a schedule for the specified depot name
---currently just takes value from settings, will break if theres more than one value in there! 
---@param current int
local function create_schedule_table (current)
    local table = {}
    table = {
        [current+1]={
            station = settings.global["depot_names"].value,
            wait_conditions = {
            [1]={
                    compare_type = "or",
                    type = "full",
                    
                },
            [2] ={
                    compare_type = "and",
                    type = "empty"
            },
            [3] = {
                compare_type = "and",
                type = "item_count",
                condition = {
                    first_signal = {
                        type = "item",
                        name = "copper-plate"
                    },
                    constant = "0",
                    comparator = ">"
                }
            }
        }
        }
    }
    return table
end

--test if the mod is alive
script.on_event(defines.events.on_console_chat, function (event)
    if event.message=="hello mod" then
        game.print("hello "..game.get_player(event.player_index).name)
    end
    for key,ent in pairs(game.surfaces[1].find_entities_filtered{type='locomotive'}) do
        mesg = tableToString(ent.train.schedule)
        -- __DebugAdapter.print(mesg)
        mesg2=tableToString(create_schedule_table(1))
        --__DebugAdapter.print("____________")
        --__DebugAdapter.print(mesg2)
    end
end)


---create an array with the keys of the given table in reverse order
---@param table table
local function create_reverse_key_array (table)
    local reversedlist = {}
    local table_len = #table
    local i = table_len
    local a = 1
    while i > 0 do
        reversedlist[a] = i
        i = i-1
        a = a+1
    end
    return reversedlist
end

---replace the current schedule of a train with a new one
---@param train LuaTrain
---@param schedule table
function replace_train_schedule(train, schedule)
    train.schedule = schedule
end

---comment
---@param schedule table
---@param added_stop table
---@param place int
local function add_stop_in_schedule (schedule,added_stop,place) 
    local reversedkeylist = create_reverse_key_array(schedule.records)
    for _,k in pairs(reversedkeylist) do
        if (k >= place) then
            schedule.records[k+1] = schedule.records[k]
        end
    end
    schedule.records[place+1] = added_stop[place+1]
    return schedule
end


---remove the stop at the given place from the schedule
---@param schedule table
---@param place int
local function remove_stop_from_schedule(schedule, place)
    for key, v in pairs(schedule.records) do
        if (key >= place) then
            schedule.records[key] = schedule.records[key+1]
        end
    end
    if schedule.current > #schedule.records then
        local i = 1
        for _,station in pairs(schedule.records) do
            active = trainstop_table[station.station]
            if active == true then
                schedule.current = i
                return schedule
            else
                i = i+1
            end
        end
    end
    return schedule
end

---returns the LuaEntity with a certain train id
---@param id int
---@return LuaEntity | nil
function get_train_by_id(id) 
    for _,sur in pairs(game.surfaces) do
        locomotives = sur.find_entities_filtered{type="locomotive"}
        for _,v in pairs(locomotives) do
            if v.train.id == id then
                return v
            end
        end
    end
    return nil
end

--start the clock to check the trains
script.on_nth_tick(tonumber(settings.global["time_between_checks"].value), function (event)
    for id,train in pairs(depot_list)do
        if depot_list[id] ~= nil then
            local activelist = 0
            for _,v in pairs(train.schedule.records) do
                if v.station ~= settings.global["depot_names"].value then
                    if trainstop_table[v.station] then
                        activelist = activelist + 1
                    end
                end
            end
            if (activelist > 1) then
                local schedule = remove_stop_from_schedule(train.schedule,train.schedule.current)
                replace_train_schedule(
                    get_train_by_id(id).train,
                    schedule)
                depot_list[id] = nil
            end
        end
    end
end)


---create a list of all stops that are on the map, only stores name and active state
---stores the list as a table that is globally accessible and returns it
function create_stop_list()
    trainstop_table = {}
    local stops = game.get_train_stops()
    for _,v in pairs(stops) do
        local controlbehavior = v.get_control_behavior()
        if controlbehavior then
            if not trainstop_table[v.backer_name] then
                trainstop_table[v.backer_name] = not controlbehavior.disabled
            end
        else
            trainstop_table[v.backer_name] = true
        end
    end
    return table
end

---creates a train list, should only be used once per initiation. the list should be updated based on events instead
function create_train_list()
    train_list = {}
    depot_list = {}
    for _,sur in pairs(game.surfaces) do
        locomotives = sur.find_entities_filtered{type="locomotive"}
        for _,v in pairs(locomotives) do
            train_list[v.backer_name] = v.train.schedule
        end
    end
end

---add the depot to the train schedule at the correct spot
---@param train LuaTrain
function send_train_to_depot(train)
    local current = train.schedule.current
    schedule = add_stop_in_schedule(train.schedule,create_schedule_table(current),current)
    replace_train_schedule(train,schedule)
end

---updates the train list for when a train enters a station
---@param event EventData.on_train_changed_state
function train_enters_station(event)
    station_list[event.train.id] = event.train
    if not event.train.manual_mode then
        if event.train.station ~= nil then
            if event.train.station.backer_name ~= settings.global["depot_names"].value then
                local active_stops = 0
                for _,v in pairs(event.train.schedule.records) do
                    if trainstop_table[v.station] then
                        active_stops = active_stops + 1
                    end
                end
                if active_stops < 2 then
                    send_train_to_depot(event.train)
                end
            else if event.train.station.backer_name == settings.global["depot_names"].value then
                depot_list[event.train.id] = event.train
                for k,v in pairs(depot_list) do
                    if not v.valid == nil then
                        depot_list[k] = nil
                    end
                end
            end
        end
    end
end
end


function check_station_trains()
    for _,train in pairs(station_list) do
        local active_stops = 0
        for _,v in pairs(train.schedule.records) do
            if trainstop_table[v.station] then
                active_stops = active_stops + 1
            end
        end
        if active_stops < 2 then
            local depot_stops = 0
            for _,v in pairs(train.schedule.records) do
                if v.station == settings.global["depot_names"].value then
                    depot_stops = depot_stops+1
                end
            end
            if depot_stops == 0 then
                send_train_to_depot(train)
            end
        end
    end
end

script.on_nth_tick(360,function (event)
    check_station_trains()
end)


script.on_nth_tick(60, function (event)
    create_stop_list()
end)

script.on_event(defines.events.on_train_changed_state, function (event)
    --game.print(event.name.."name----"..event.old_state.."old state-----"..event.train.state.."new state")
    if event.old_state==6 then
        train_enters_station(event)
    end
    if event.old_state == 7 then
        station_list[event.train.id] = nil
    end
end)


local function onLoad(event)
    depot_list = {}
    station_list = {}
    script.on_event(defines.events.on_tick, function(event)
        
        if game then
            
            game.print("Saved game loaded.")
            create_stop_list()
            
            script.on_event(defines.events.on_tick, nil)
        end
    end)
end


script.on_load(onLoad)