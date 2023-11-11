-- File handling the train table

---create and add an element for/to the train table 
---@param train LuaTrain
function create_train_table_element(train)
    --game.print("train added")
    global.train_table[train.id] = {
        selected_depot = global.depot_array[1],
        go_to_depot = false,
        enable_depot = true,
        at_depot = false,
        at_station = false
    }
end

---should only be called when the mod initializes or when called by a command, creates a large lag spike as it has to iterate over every train
function create_train_table()
    global.train_table = {}
    for _,sur in pairs(game.surfaces) do
        for _,ent in pairs(sur.find_entities_filtered{type='locomotive'}) do
            create_train_table_element(ent.train)
        end
    end
end

---function for the remake command
---@param event CustomCommandData
function remake_train_table(event)
    create_train_table()
    game.players[event.player_index].print("remade train table")
end

---remove the train with the given id from the traintable
---@param train_id int
function remove_from_traintable(train_id)
    global.train_table[train_id] = nil
end

---updates the train table after an event that places/removes a train was fired
---@param train LuaTrain
function update_train_table(train)
    if global.train_table[train] == nil then 
        create_train_table_element(train)
    else
        remove_from_traintable(train.id)
    end
end