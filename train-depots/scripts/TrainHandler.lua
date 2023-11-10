--Functions to send trains somewhere or check of the train table needs to update

---replace the current schedule of a train with a new one
---@param train LuaTrain
---@param schedule table
function replace_train_schedule(train, schedule)
    if schedule == nil then return end
    train.schedule = schedule
end

---adds a stop to a schedule in the specified spot
---@param schedule table
---@param added_stop table
---@param place int
function add_stop_in_schedule(schedule,added_stop,place) 
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
---@param schedule TrainSchedule
---@param place int
---@param stopname string
---@return table
function remove_stop_from_schedule(schedule, place, stopname)
    if schedule == nil then return {} end
    if schedule.records[place] == nil or place == nil then return schedule end
    if stopname ~= schedule.records[place].station then 
        --game.print("trying to delete the wrong station, tried to delete "..schedule.record[place]) 
        return schedule 
    end
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

---add the depot to the train schedule at the correct spot
---@param train LuaTrain
function send_train_to_depot(train)
    if global.train_table[train.id].go_to_depot == false then
        local current = train.schedule.current
        schedule = add_stop_in_schedule(train.schedule, create_schedule_table(current,train.id),current)
        replace_train_schedule(train,schedule)
        global.train_table[train.id].go_to_depot = true
    end
end

---update the train_table.train variable if something changed
---@param train LuaTrain
function update_train_table_train(train)
    if global.train_table[train.id]==nil then
        create_train_table_element(train)
    end
    global.train_table[train.id].train = train
end

---checks the amount of active stations a train has
---@param train LuaTrain
---@return int | nil
function check_stations(train)
    local active_station = 0
    if train.schedule.records == nil then return end
    for _,v in pairs(train.schedule.records) do
        if global.trainstop_table[v.station] then
            active_station = active_station + 1
        end
    end
    return active_station
end 

---checks for any active depot stations in the schedule and returns their places.
---{station place : station name}
---@param train LuaTrain
---@return table | nil
function find_depot_stations(train)
    local depot_table
    if train.schedule.records == nil then return end
    for k,v in pairs(train.schedule.records) do
        if v.station == global.train_table[train.id].selected_depot then
            depot_table[k] = v.station
        end
    end
    return depot_table
end

---removes all depot stations in the trains schedule
---@param train LuaTrain
function remove_depots_from_trains(train)
    depots = find_depot_stations(train)
    if depots == nil then return end
    local schedule = train.schedule
    if schedule == nil then return end
    for id,name in pairs(depots) do
        local new_schedule = remove_stop_from_schedule(schedule,id,name)
        if not new_schedule == nil then 
            schedule = new_schedule
        end
    end
    replace_train_schedule(train,schedule)
end