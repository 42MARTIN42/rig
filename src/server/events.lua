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
local ui = require("src.server.modules.ui")
local cfg_zones = require("configs.zones")
local cfg_effects = require("configs.effects")
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
--- @section Objects

RegisterServerEvent("rig:sv:place_object", function(data)
    core.place_object(source, data)
end)

RegisterServerEvent("rig:sv:remove_placed_object", function(id)
    core.remove_object(source, id)
end)

RegisterServerEvent("rig:sv:use_placed_object", function(id, key)
    core.use_object(source, id, key)
end)

--- @section Statuses

RegisterServerEvent("rig:sv:player_drink_water_source", function(data)
    local source = source
    local player = core.players:get(source)
    if not player or not player:has_loaded() then return end
    if not data or not data.zone or data.scumminess == nil then return end
    local modifier = cfg_zones.scumminess[data.scumminess] and cfg_zones.scumminess[data.scumminess].water or cfg_zones.scumminess[0].water
    local is_saltwater = cfg_zones.saltwater[data.zone] ~= nil
    local applied_effects = {}

    for status_id, amount in pairs(modifier.statuses) do
        local current = player:run_method("get_status", status_id) or 0
        local max = (status_id == "health") and 200.0 or 100.0
        player:run_method("set_status", status_id, math.min(max, math.max(0, current + amount)))
    end

    if is_saltwater then
        local salt_def = cfg_effects.saltwater_ingestion
        if salt_def then
            player:run_method("set_effect", "saltwater_ingestion", salt_def)
            applied_effects[#applied_effects + 1] = salt_def.label or "Saltwater Ingestion"
        end
    end

    for _, effect in ipairs(modifier.effects) do
        if math.random(100) <= effect.chance then
            local def = cfg_effects[effect.id]
            if def then
                player:run_method("set_effect", effect.id, def)
                applied_effects[#applied_effects + 1] = def.label or def.effect_name
            end
        end
    end

    if #applied_effects > 0 then
        pluck.notify(source, {
            type = "error",
            header = "You feel sick...",
            message = table.concat(applied_effects, ", "),
            duration = 6000
        })
    else
        pluck.notify(source, {
            type = is_saltwater and "warning" or "info",
            header = "Thirst Quenched",
            message = is_saltwater and "The water tasted salty." or "You drank from the water source.",
            duration = 4000
        })
    end
end)

RegisterServerEvent("rig:sv:update_health_armour", function(data)
    local _src = source
    local player = core.players:get(_src)
    if not player or not player:has_loaded() then
        print(("[rig:sv:update_health_armour] Player %s not found or not loaded"):format(_src))
        return
    end
    local ped = GetPlayerPed(_src)
    local real_health = GetEntityHealth(ped)
    local real_armour = GetPedArmour(ped)
    print(("[rig:sv:update_health_armour] src: %s | data.health: %s | real_health: %s | real_armour: %s"):format(_src, tostring(data.health), real_health, real_armour))
    player:run_method("set_statuses", { health = real_health, armour = real_armour })
end)

RegisterServerEvent("rig:sv:player_respawn", function()
    local _src = source
    local player = core.players:get(_src)
    if not player then return end
    if not player:run_method("get_status", "is_dead") then
        log("info", ("[respawn] rejected - no pending respawn for: %s"):format(_src))
        return
    end
    player:run_method("respawn_player")
end)

RegisterServerEvent("rig:sv:player_give_up", function()
    local _src = source
    local player = core.players:get(_src)
    if not player then return end
    player:run_method("kill_player")
end)

--- @section Appearance

RegisterServerEvent("rig:sv:fetch_appearance", function()
    local _src = source
    local player = core.create_player(_src)
    if not player then log("error", locale("player_creation_failed", _src)) return end
    local appearance = player:run_method("get_appearance")
    if not appearance or not appearance.has_customised then
        TriggerClientEvent("rig:cl:create_first_appearance", _src)
        return
    end
    TriggerClientEvent("rig:cl:load_appearance", _src, appearance)
end)

RegisterServerEvent("rig:sv:save_appearance", function(sex, style)
    local _src = source
    local player = core.players:get(_src)
    if not player then log("error", locale("player_missing", _src)) return end
    if not sex or not style then log("error", "Appearance data missing, cant save.") return end
    local result = player:run_method("save_appearance", sex, style)
    if result then
        player:save()
        log("info", "Appearance saved for player: " .. player.unique_id)
        TriggerClientEvent("rig:cl:load_appearance", _src, style)
    else
        log("error", "Failed to save appearance for player: " .. player.unique_id)
    end
end)

--- @section Player

RegisterServerEvent("rig:sv:disconnect", function()
    local _src = source
    DropPlayer(_src, locale("disconnected"))
end)

AddEventHandler("rig:sv:player_loaded", function(player)
    local objects = core.objects:get_sync_payload()
    TriggerClientEvent("rig:cl:load_placed_objects", player.source, objects)
    TriggerClientEvent("rig:cl:player_loaded", player.source, {
        source = player.source,
        unique_id = player.unique_id,
        username = player.username,
        vip = player.vip,
        priority = player.priority
    })
end)

AddEventHandler("rig:sv:player_assigned_bucket", function(source, bucket_id, config)
    log("info", ("[Weather] Player %d assigned to bucket %d"):format(tonumber(source), tonumber(bucket_id)))
    core.sync_player_weather(source, bucket_id)
end)

AddEventHandler("playerConnecting", function(name, kick, deferrals)
    core.players:request_connection(source, name, deferrals)
end)

AddEventHandler("playerJoining", function()
    local _src = source
    local ids = utils.get_player_identifiers(_src)
    if ids.license and core.players:activate(_src, ids.license) then
        core.players:assign_personal_bucket(_src)
    end
end)

AddEventHandler("playerDropped", function()
    local _src = source
    local player = core.players:get(_src)
    if player then
        player:save()
    end
    core.players:remove(_src)
end)

--- @section Resource 

AddEventHandler("onResourceStart", function(res)
    if res ~= GetCurrentResourceName() then return end
    core.objects:load()
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    core.players:save_all()
end)