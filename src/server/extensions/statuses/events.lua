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

local cfg_zones = require("configs.zones")
local cfg_effects = require("configs.effects")

--- @section Events

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