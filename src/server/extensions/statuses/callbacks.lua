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

--- @section Imports

local callbacks = require("libs.graft.fivem.callbacks")

--- @section Statuses

callbacks.register("rig:sv:validate_revive", function(source, data, cb)
    local player = core.players:get(source)
    if not player then cb({ valid = false }) return end
    local valid = player:run_method("get_status", "pending_revive") == true
    player:run_method("set_status", "pending_revive", false)
    cb({ valid = valid })
end)

callbacks.register("rig:sv:validate_respawn", function(source, data, cb)
    local player = core.players:get(source)
    if not player then cb({ valid = false }) return end
    local valid = player:run_method("get_status", "is_dead") == true
    cb({ valid = valid })
end)
