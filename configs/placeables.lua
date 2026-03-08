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

--- @module config.placeables
--- @description Handles all static definitions for placeable objects.

return {
    sleeping_bag = { -- Unique placeable type
        label = "Sleeping Bag", -- UI label
        model = "prop_skid_sleepbag_1", -- Prop model to spawn
        limit = 1, -- Amount player is allowed to place
        keys = { -- Actions for UI
            { key = "z", label = "Destroy" }
        },
        actions = { -- Action functions to connect to keys
            z = function(source, id)
                core.remove_object(source, id)
            end
        }
    }
}