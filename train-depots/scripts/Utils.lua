--Random bullshit go brrrr file

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
---@param trainid int
function create_schedule_table (current, trainid)
    local table = {}
    table = {
        [current+1]={
            station = global.train_table[trainid].selected_depot,
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
function create_reverse_key_array (table)
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


function OnInit()
    register_commands()
    global.depot_list = {}
    global.station_list = {}
    global.train_table = {}
    create_stop_list()
    create_depot_array(settings.global["depot_names"].value)
    create_train_table()
    print_trains_entering_station = false
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

---find the entity on a given surface or the entire game
--[[{
    entityname = name of the entity youre looking for (string), 
    enttype = type of the entity to look for (string), 
    surface = surface to look on, if nil look on all surfaces
    }
]]
---@param arguments table 
---@return LuaEntity | nil
function find_entites(arguments)
    local entityname = arguments.entityname
    local enttype = arguments.type
    local surface = arguments.surface
    if entityname == nil or enttype == nil then return nil end
    if type(entityname) ~= string or type(enttype) ~= string then return nil end
    if surface then
        local entities = surface.find_entities_filtered{type=enttype}
        if entities[entityname] ~= nil then
            return entities[entityname]
        end
    else
        for _,sur in pairs(game.surfaces) do
            local entities = sur.find_entities_filtered{type=enttype}
            if entities[entityname] ~= nil then
                return entities[entityname]
            end
        end
    end
    return nil
end
