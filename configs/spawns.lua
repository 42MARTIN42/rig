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

--- @module config.spawns
--- @description Handles all spawns related config settings

return {
    
    --- Default spawn types matches db enum
    _types = {
        last_location = "last_location",
        bed = "bed",
        sleepingbag = "sleepingbag"
    },

    default_spawn_location = vector4(-268.47, -956.98, 31.22, 208.54), -- Default location incase nothing gets set

    --- World spawn zones
    --- Idea was to try make a simple system similar to other survival games
    --- Players pick a "world zone" and are spawned at random coords within that zone
    zones = {
        easy = { -- "easy" zones
            { 
                label = "Paleto Bay", -- UI label
                coords = vector3(247.02, 6564.15, 31.22), -- Center location
                radius = 200.0 -- Circle radius allowed to spawn
            },
            { label = "Sandy Shores", coords = vector3(1436.55, 3495.96, 35.86), radius = 200.0 },
            { label = "Grapeseed", coords = vector3(2587.76, 4870.91, 35.49), radius = 300.0 },
        },
        medium = {
            { label = "Wind Farm", coords = vector3(2230.73, 1832.12, 108.55), radius = 300.0 },
            { label = "Oil Fields", coords = vector3(1577.32, -2326.93, 88.1), radius = 300.0 },
            { label = "Terminal", coords = vector3(985.51, -3092.65, 5.9), radius = 200.0 },
        },
        hard = {
            { label = "Del Perro", coords = vector3(-1455.44, -1124.41, 3.26), radius = 100.0 },
            { label = "LS Airport", coords = vector3(-790.14, -2366.46, 14.57), radius = 150.0 }
        }
    }

}