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

--- @class Spawns
--- @description Player spawns extension for managing spawn locations.

--- @section Imports

local cfg_spawns = require("configs.spawns")

--- @section Class

local Spawns = {}

--- @section Constants

local SPAWN_TYPES = cfg_spawns._types

--- @section Lifecycle

function Spawns:on_load()
    local player = self.player
    local unique_id = player.unique_id
    
    --- @section Player Data
    
    local result = MySQL.query.await("SELECT * FROM rig_player_spawns WHERE unique_id = ?", { unique_id })
    local spawns = {}
    
    if result and #result > 0 then
        for _, spawn in ipairs(result) do
            spawns[spawn.spawn_id] = {
                spawn_type = spawn.spawn_type,
                label = spawn.label,
                x = spawn.x,
                y = spawn.y,
                z = spawn.z,
                w = spawn.w,
                updated_at = spawn.updated_at
            }
        end
    end
    
    player:add_data("spawns", spawns, true)
    
    --- @section Methods
    
    --- Getters

    player:add_method("get_spawns", function()
        return player:get_data("spawns")
    end)
    
    player:add_method("get_spawn", function(spawn_id)
        return player:get_data("spawns")[spawn_id]
    end)
    
    --- Setters

    player:add_method("set_spawns", function(updates)
        if not updates or type(updates) ~= "table" then return false end
        local validated_updates = {}
        for spawn_id, spawn_data in pairs(updates) do
            if spawn_data and type(spawn_data) == "table" then
                if not SPAWN_TYPES[spawn_data.spawn_type] then return false end
                validated_updates[spawn_id] = {
                    spawn_type = spawn_data.spawn_type,
                    label = spawn_data.label or nil,
                    x = tonumber(spawn_data.x) or 0,
                    y = tonumber(spawn_data.y) or 0,
                    z = tonumber(spawn_data.z) or 0,
                    w = tonumber(spawn_data.w) or 0,
                    updated_at = os.date("%Y-%m-%d %H:%M:%S")
                }
            end
        end
        return player:set_data("spawns", validated_updates, true)
    end)

    player:add_method("set_spawn", function(spawn_id, spawn_data)
        if not spawn_data or type(spawn_data) ~= "table" then return false end
        if not SPAWN_TYPES[spawn_data.spawn_type] then return false end
        local validated = {
            [spawn_id] = {
                spawn_type = spawn_data.spawn_type,
                label = spawn_data.label or nil,
                x = tonumber(spawn_data.x) or 0,
                y = tonumber(spawn_data.y) or 0,
                z = tonumber(spawn_data.z) or 0,
                w = tonumber(spawn_data.w) or 0,
                updated_at = os.date("%Y-%m-%d %H:%M:%S")
            }
        }
        return player:set_data("spawns", validated, true)
    end)

    --- Actions

    player:add_method("spawn_player", function(coords)
        local ped = GetPlayerPed(player.source)
        if player:run_method("get_status", "is_dead") then
            player:run_method("set_status", "is_dead", false)
            player:run_method("reset_statuses")
            player:run_method("clear_effects")
            player:run_method("clear_injuries")
        end
        FreezeEntityPosition(ped, true)
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, coords.w or 0.0)
        core.players:set_bucket(player.source, "main")
        player:set_playing(true)
        TriggerClientEvent("rig:cl:find_ground_and_spawn", player.source)
    end)
    
    --- Clean up

    player:add_method("clear_spawns", function()
        local spawns = player:get_data("spawns")
        local last_location = spawns.last_location

        return player:set_data("spawns", { last_location = last_location }, true)
    end)
    
    player:add_method("clear_spawn", function(spawn_id)
        if spawn_id == "last_location" then return false end
        return player:set_data("spawns", { [spawn_id] = nil }, true)
    end)

    --- Save

    player:add_method("save_last_location", function()
        if not player or not player.source then return false end
        local ped = GetPlayerPed(player.source)
        if not DoesEntityExist(ped) then return false end
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local last_location = { spawn_type = "last_location", label = "Last Location", x = coords.x, y = coords.y, z = coords.z, w = heading }
        return player:run_method("set_spawn", "last_location", last_location)
    end)

end

function Spawns:on_save()
    if not self.player:is_playing() then print("player not playing spawns skipped save") return end
    self.player:run_method("save_last_location")
    local spawns = self.player:get_data("spawns")
    if not spawns then return end
    local queries = {}
    for spawn_id, spawn_data in pairs(spawns) do
        if spawn_data then
            queries[#queries + 1] = {
                query = "INSERT INTO rig_player_spawns (unique_id, spawn_id, spawn_type, label, x, y, z, w) VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE spawn_type = VALUES(spawn_type), label = VALUES(label), x = VALUES(x), y = VALUES(y), z = VALUES(z), w = VALUES(w)",
                values = { self.player.unique_id, spawn_id, spawn_data.spawn_type, spawn_data.label or nil, spawn_data.x, spawn_data.y, spawn_data.z, spawn_data.w }
            }
        end
    end
    return queries
end

return Spawns