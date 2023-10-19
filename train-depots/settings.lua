data:extend({
    {
        type = "string-setting",
        name = "depot_names",
        setting_type = "runtime-global",
        default_value = "Depot",
        localised_name = "Depot Names",
        localised_description = "The names of the stations trains should go to, divided by ','."
    },
    {
        type = "int-setting",
        name = "time_between_checks",
        setting_type = "runtime-global",
        default_value = 60,
        minimum_value = 30,
        localised_name = "time between checks",
        localised_description = "the time that's between checks for which trains can depart from a depot in ticks. can be extended if the mod causes the server to lag."
    }
})