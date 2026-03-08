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

--- @module src.server.modules.ui
--- @description Handles building UI payloads for client

--- @section Imports

local cfg_spawns = require("configs.spawns")

local ui = {}

function ui.build_spawn_payload(spawns, statuses)
    if not cfg_spawns or not cfg_spawns.zones then
        log("error", "UI Module: cfg_spawns.zones is NIL or MISSING!")
        return { world_zones = {}, personal = {} }
    end

    local is_dead = statuses and statuses.is_dead
    local is_downed = statuses and statuses.is_downed
    local world_zones = {}
    local personal = {}

    for spawn_id, spawn_data in pairs(spawns) do
        local spawn_type = spawn_data.spawn_type
        if not (is_dead and spawn_type == "last_location") then
            if spawn_type == "last_location" or spawn_type == "bed" or spawn_type == "sleepingbag" then
                table.insert(personal, {
                    id = spawn_id,
                    label = spawn_data.label,
                    spawn_type = spawn_type,
                    coords = { x = spawn_data.x, y = spawn_data.y, z = spawn_data.z, w = spawn_data.w }
                })
            end
        end
    end

    local has_personal = #personal > 0
    local first_join = not has_personal and not spawns.last_location
    local show_zones = is_dead or first_join
    local show_personal = has_personal

    if show_zones then
        for difficulty, zones in pairs(cfg_spawns.zones) do
            for index, zone_data in ipairs(zones) do
                table.insert(world_zones, {
                    id = string.format("%s_%d", difficulty, index),
                    difficulty = difficulty,
                    label = zone_data.label,
                    coords = { x = zone_data.coords.x, y = zone_data.coords.y, z = zone_data.coords.z }
                })
            end
        end
    end

    return {
        world_zones = show_zones and world_zones or {},
        personal = show_personal and personal or {},
        is_downed = is_downed
    }
end

return ui