-- Handles the interactions with the train GUI

---
---@param event EventData.on_gui_checked_state_changed
function oncheckboxchanged(event)
    if event.element.name == "depot_checkbox" then
        local trainid
        local player = game.get_player(event.player_index)
        if player ~= nil then
            if player.opened ~= nil then
                trainid = player.opened.train.id
                if event.element.state then
                    global.train_table[trainid].enable_depot = true
                else
                    global.train_table[trainid].enable_depot = false
                end
            end
        end
    end
end

---@param event EventData.on_gui_selection_state_changed
function onselectionchanged(event)
    if event.element.name == "depot_selector_drop_down" then
        local trainid
        local player = game.get_player(event.player_index)
        if player ~= nil then
            if player.opened ~= nil then
                trainid = player.opened.train.id
                global.train_table[trainid].selected_depot = event.element.items[event.element.selected_index]
            end
        end
    end
end