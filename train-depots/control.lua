--control.lua

--test if the mod is alive
script.on_event(defines.events.on_console_chat, function (event)
    if event.message=="hello mod" then
        game.print("hello "..game.get_player(event.player_index).name)
        create_depot_array()
        local screen_element = game.players[event.player_index].gui.screen
        register_commands()
        close_depot_gui(game.players[event.player_index])
    end
    for key,ent in pairs(game.surfaces[1].find_entities_filtered{type='locomotive'}) do
        mesg = tableToString(ent.train.schedule)
        -- __DebugAdapter.print(mesg)
        --mesg2=tableToString(create_schedule_table(1))
        --__DebugAdapter.print("____________")
        --__DebugAdapter.print(mesg2)
    end
end)


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
            active = global.trainstop_table[station.station]
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

function check_trains (event)
    
    if global.depot_list == nil then
        global.depot_list = {}
    end
    for id,train in pairs(global.depot_list)do
        if global.train_table[id].go_to_depot then
            local activelist = 0
            if train.schedule == nil then return end
            for _,v in pairs(train.schedule.records) do
                if v.station ~= settings.global["depot_names"].value then
                    if global.trainstop_table[v.station] then
                        activelist = activelist + 1
                    end
                end
            end
            if (activelist > 1) then
                local schedule = remove_stop_from_schedule(train.schedule,train.schedule.current)
                replace_train_schedule(
                    get_train_by_id(id).train,
                    schedule)
                global.train_table[id].go_to_depot = false
                global.train_table[id].at_depot = false
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
        for _,v in pairs(locomotives) do
            global.train_list[v.backer_name] = v.train.schedule
        end
    end
end

---add the depot to the train schedule at the correct spot
---@param train LuaTrain
function send_train_to_depot(train)
    if global.train_table[train.id].go_to_depot == false then
        local current = train.schedule.current
        schedule = add_stop_in_schedule(train.schedule,create_schedule_table(current),current)
        replace_train_schedule(train,schedule)
        global.train_table[train.id].go_to_depot = true
    end
end

---updates the train list for when a train enters a station
---@param event EventData.on_train_changed_state
function train_enters_station(event)
    global.train_table[event.train.id].at_station = true
    if not event.train.manual_mode then
        if event.train.station ~= nil then
            if event.train.station.backer_name ~= global.train_table.selected_depot then
                local active_stops = 0
                for _,v in pairs(event.train.schedule.records) do
                    if global.trainstop_table[v.station] then
                        active_stops = active_stops + 1
                    end
                end
                if active_stops < 2 then
                    send_train_to_depot(event.train)
                end
            else if event.train.station.backer_name == global.train_table.selected_depot then
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
    for _,v in pairs(global.train_table) do
        if v.at_station then
            local active_stops = 0
            for _,v in pairs(v.train.schedule.records) do
                if global.trainstop_table[v.station] then
                    active_stops = active_stops + 1
                end
            end
            if active_stops < 2 then
                local depot_stops = 0
                for _,v in pairs(v.train.schedule.records) do
                    if v.station == settings.global["depot_names"].value then
                        depot_stops = depot_stops+1
                    end
                end
                if depot_stops == 0 then
                    send_train_to_depot(v.train)
                end
            end
        end
    end
end

---creates the array of possible depot station names
function create_depot_array()
    local depot_array = {}
    local depot_name = ""
    for i = 1 , #depot_name_setting, 1 do
        local sub = string.sub(depot_name_setting, i, i)
        if sub ~= "," then
            depot_name = depot_name .. sub
        else 
            depot_array[#depot_array+1] = depot_name
            depot_name = ""
        end
    end
    depot_array[#depot_array+1] = depot_name
    return depot_array
end

local function OnInit(event)
    global.depot_list = {}
    global.station_list = {}
    print_trains_entering_station = false
    if game then
        ---- initial code
    end
    
end

---do whatever needs to be done when loading a save
function OnLoad()
    script.on_event(defines.events.on_tick,function ()
        if game then
            -- this part will run exactly once at the start of the game, dont forget to not add any other on_tick events
            register_commands()
            script.on_event(defines.events.on_tick,nil)
            if global.train_table == nil then 
                create_train_table()
            end
            if global.trainstop_table == nil then 
                create_stop_list()
            end
        end
    end)
    depot_name_setting = settings.global["depot_names"].value
end

----------------------------------------train table-------------------------------------------

---should only be called when the mod initializes or when called by a command, creates a large lag spike as it has to iterate over every train
function create_train_table()
    global.train_table = {}
    for _,sur in pairs(game.surfaces) do
        for _,train in pairs(sur.find_entities_filtered{type='locomotive'}) do
            global.train_table[train.train.id] = {
                train = train.train,
                selected_depot = "",
                go_to_depot = false,
                enable_depot = true,
                at_depot = false,
                at_station = false
            }
        end
    end
end

---function for the remake command
---@param event CustomCommandData
function remake_train_table(event)
    create_train_table()
    game.players[event.player_index].print("remade train table")
end
-------------------------------------------gui-----------------------------------------------

---open the depot gui to choose a depot station to go to
---@param player LuaPlayer
function open_depot_gui(player)
    ----------------------main frame
    local screen_element = player.gui.screen
    local train_depot_gui = screen_element.add{type = 'frame', name = 'train_depot_settings_frame', caption = 'train depot settings'}
    train_depot_gui.style.size = {250,450}
    --train_depot_gui.location = {x=507,y=1630}

    ----------------------dropdown box for selecting station
    local depot_selector_drop_down = train_depot_gui.add{type = 'drop-down', 
                                                        name = 'depot_selector_drop_down',
                                                        caption='select the depot station to go to'}
    depot_selector_drop_down.items = create_depot_array()
    depot_selector_drop_down.selected_index = 1

    ----------------------checkbox to opt in or out of depots

end

---close the depot gui
---@param player LuaPlayer
function close_depot_gui(player)
    if player == nil then return end
    local screen_element = player.gui.screen
    for _,v in pairs(screen_element.children) do
        if v.name == "train_depot_settings_frame"then
            v.destroy()
        end        
    end
end

--------------------------------------event handlers-----------------------------------------

script.on_init(OnInit)
script.on_load(OnLoad)


script.on_nth_tick(360,function (event)
    check_station_trains()
end)


script.on_nth_tick(60, function (event)
    create_stop_list()
end)

--start the clock to check the trains
script.on_nth_tick(tonumber(settings.global["time_between_checks"].value), function (event)
    check_trains(event)
end)

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
        close_depot_gui(player)

    end
end)

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
    end
end)
--------------------------------------------------------debug section---------------------------

---prints out the trainlist table
---@param command CustomCommandData
function print_trainlist(command) 
    if command.player_index ~= nil and command.parameter ~= nil then
        game.get_player(command.player_index).print(tableToString(global.train_table[command.parameter]))
    else if command.player_index ~= nil then
        game.get_player(command.player_index).print("please specify a train id")
    end
end
end

---prints out the active stations
---@param command CustomCommandData
function print_trainstop_table(command)
    if command.player_index ~= nil and command.parameter ~= nil then
        game.get_player(command.player_index).print(tableToString(global.trainstop_table[command.parameter]))
    else if command.player_index ~= nil then
        game.get_player(command.player_index).print(tableToString(global.trainstop_table))
    end
end
end

function turn_on_train_debugging(command)
    if command.player_index ~= nil then
        game.get_player(command.player_index).print("prepare for the lag")
    end
    print_trains_entering_station = true
end

function register_commands()
    commands.add_command("print_trainlist",
    "prints out the trainlist table",print_trainlist)
    commands.add_command("print_trainstop_table", 
    "prints out the table of active trainstops",print_trainstop_table)
    commands.add_command("turn_on_train_debugging",
    "turns on the train debugging tool that prints out when a train visits a station, only to be used when needed",
    turn_on_train_debugging)
    commands.add_command("remake_train_table","creates a new train table, will cause a lag spike, only call when needed",
    remake_train_table)
end