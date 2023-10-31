--File responsible for registring and handling all commands
local Utils = require("Utils")
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

function delete_depots_from_schedule (command) 
    for trainid,v in pairs(global.train_table) do
        for key,k in pairs(v.train.schedule.records) do
            if k.station == v.selected_depot then
                schedule = Utils.remove_stop_from_schedule(v.train.schedule,key,global.train_table[trainid].selected_depot)
                replace_train_schedule(game.get_train_by_id(trainid).train,schedule)
                v.go_to_depot = false
            end
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


--------------Registering Commands------------------------

--registers the commands, has to be called every time the game loads
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
    commands.add_command("remove_depots_from_trains","removes all depot stops from train schedules if needed",
    delete_depots_from_schedule)
end