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

local utils = require("src.server.modules.utils")
local ui = require("src.server.extensions.spawns.modules.ui")
local cfg_spawns = require("configs.spawns")

--- @section Spawns

RegisterServerEvent("rig:sv:fetch_spawns", function()
    local _src = source
    local player = core.players:get(_src)
    if not player then 
        log("error", ("Fetch Spawns: Player object missing for source %s"):format(_src)) 
        return 
    end
    local spawns = player:run_method("get_spawns") or {}
    local statuses = {
        is_dead = player:run_method("is_dead"),
        is_downed = player:run_method("is_downed")
    }
    local payload = ui.build_spawn_payload(spawns, statuses)
    TriggerClientEvent("rig:cl:handle_spawn_ui", _src, payload)
end)

RegisterServerEvent("rig:sv:select_spawn", function(spawn_id)
    local _src = source
    local player = core.players:get(_src)
    if not player then log("error", locale("player_missing", _src)) return end
    local spawns = player:run_method("get_spawns")
    local difficulty, index = spawn_id:match("([^_]+)_(%d+)")
    if difficulty and index then
        local zone = cfg_spawns.zones[difficulty][tonumber(index)]
        if zone then
            local final_coords = utils.get_randomized_coords(zone.coords, zone.radius)
            return player:run_method("spawn_player", final_coords)
        end
    end
    if spawns and spawns[spawn_id] then
        return player:run_method("spawn_player", spawns[spawn_id])
    end
    log("error", "Invalid spawn ID: " .. tostring(spawn_id))
end)