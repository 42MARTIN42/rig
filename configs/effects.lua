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

--- @module configs.effects
--- @description Handles all effects related config settings

return {
    
    --- Static types; matches the db tables enums
    --- For now this does not need changing the 3 should cover most things
    _types = {
        buff = "buff",
        debuff = "debuff",
        status = "status"
    },

    dysentry = { -- Unique id for effect
        type = "debuff", -- the _type
        label = "Dysentery", -- UI label
        duration = 1800, -- Duration of effect in seconds
        modifiers = { -- What the effect can modify
            thirst = -2.0, -- lowers thirst by -2.0 per tick when affected
            on_tick = { -- @todo implement a on_tick check for effects
                { action = "animation", type = "stomach_ache", chance = 0.1 } -- idea is to trigger animations, throwing up etc random chance stuff
            }
        }
    },

    cholera = {
        type = "debuff",
        label = "Cholera",
        duration = 1800,
        modifiers = {
            health = -1.0,
            thirst = -5.0,
            hunger = -2.0, 
        }
    },

    parasites = {
        type = "debuff",
        label = "Parasites",
        duration = -1,
        modifiers = {
            health = -3.0,
            thirst = -5.0,
            hunger = -8.0, 
        }
    }

}