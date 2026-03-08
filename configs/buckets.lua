--[[
--------------------------------------------------

This file is part of RIG.
Please retain this header in all files.
Support honest open source development.

Author: Case @ BOII Development
Website: https://boii.dev
GitHub: https://github.com/rig-framework/rig
License: LGPL-3.0

--------------------------------------------------
]]

--- @module configs.buckets
--- @description Handles all routing bucket settings

return {
    main = {
        label = "Main World", -- Display name for the bucket
        bucket = 0, -- GTA routing bucket ID (0 = main world)
        mode = "strict", -- Entity lockdown mode "strict" | "relaxed" | "inactive" - view: https://docs.fivem.net/natives/?_0xA0F2201F
        population_enabled = false, -- Enable population on bucket
        staff_only = false, -- Enable staff only entry: false | { "admin", "owner", ... }
        player_cap = false, -- Cap the amount of players in a bucket: false | number
        vip_only = false, -- Enable vip entry only any vip ranks above value can enter: false | number
        dynamic_weather = true, -- Enable automatic weather cycling
        weather = "CLEAR", -- Static weather type (used if dynamic_weather = false)
        dynamic_time = true, -- Enable automatic time progression
        hour = 12, -- Static hour (0-23, used if dynamic_time = false)
        minute = 0, -- Static minute (0-59, used if dynamic_time = false)
        day = 1, -- Starting day (1-30, randomised on init if dynamic_time = true)
        month = 0, -- Starting month
        year = 2026, -- Staring year
        season = "WINTER", -- Current season (WINTER, SPRING, SUMMER, AUTUMN)
        freeze_weather = false -- Freeze weather/wind changes when true
    }
}