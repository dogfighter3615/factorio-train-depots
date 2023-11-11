-- File handling the changes to the trainstop_table

---create a new element in the trainstop table
---@param trainstop LuaEntity
function create_new_trainstoptable_element(trainstop)
    local controlbehavior = trainstop.get_control_behavior()
    if controlbehavior then
        ---@diagnostic disable-next-line: undefined-field
        global.trainstop_table[trainstop.backer_name] = not controlbehavior.disabled
    end
end

---rename an element in the trainstop table
---@param oldname any
---@param newname any
function replace_name_trainstop_table(oldname, newname)
    
    if global.trainstop_table[oldname] == nil then 
        local trainstop = find_entites({entityname = newname,
                                        type = "trainstop"})
        if trainstop == nil then return end
        create_new_trainstoptable_element(trainstop)
        return
    end
    global.trainstop_table[newname] = global.trainstop_table[oldname]
    global.trainstop_table[oldname] = nil
end

---make a new trainstop Table, will delete the old one and make a new one, 
---should only be used on initialising or debugging, rest should be handled by adding and removing from the table
function make_TrainstopTable () 
    global.trainstop_table = {}
    for _,sur in pairs(game.surfaces) do
        local entities = sur.find_entities_filtered({type = "trainstop"})
        for _,trainstop in pairs(entities) do
            create_new_trainstoptable_element(trainstop)
        end 
    end
end

---remove the given transtop from the table
---@param trainstop string
function remove_trainstop_from_trainstoptable(trainstop)
    global.trainstop_table[trainstop] = nil
end

---update an element of the trainstop_table with the given name
---@param trainstop string
function update_trainstoptable_element(trainstop)
    local stop = game.get_train_stops{name = trainstop}
    for _,v in pairs(stop) do
        ---@diagnostic disable-next-line: undefined-field
        global.trainstop_table[v.backer_name] = not v.get_control_behavior().disabled
    end
end
