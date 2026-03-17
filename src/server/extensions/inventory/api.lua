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

--- @file src.server.api
--- @description Handles all server side API registration.
--- Required due to cross resource usage, class functions do not like exports to keep it simple.
--- You have two options: 
--- `local rig = exports.rig:api()` then call functions `rig.save_player(source)`
--- or `exports.rig:save_player(source)` to use exports directly 

--- @section Imports

local inv_api = require("src.server.extensions.inventory.modules.actions")

function core.toggle_player_inventory(source, data)
    inv_api.toggle_player_inventory(source, data)
end
exports("toggle_player_inventory", core.toggle_player_inventory)