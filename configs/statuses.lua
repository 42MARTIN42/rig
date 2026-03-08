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

--- @module configs.statuses
--- @description Handles all statuses related config settings

return {
    
    --- Default statuses applied to new players
    --- Also used on revive to reset
    _defaults = {
        health = 200.0,
        armour = 0.0,
        hunger = 100.0,
        thirst = 100.0,
        hygiene = 100.0,
        stress = 0.0,
        sanity = 100.0,
        temperature = 37.0,
        bleeding = 0.0,
        radiation = 0.0,
        infection = 0.0,
        poison = 0.0
    },

    tick_rate = 5000 -- Status update tick (5seconds)
}