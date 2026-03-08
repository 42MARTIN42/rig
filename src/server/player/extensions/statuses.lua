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

--- @class Statuses
--- @description Player statuses extension for health, hunger, thirst, etc.

--- @section Imports

local tables = require("libs.graft.standalone.tables")
local cfg_statuses = require("configs.statuses")

--- @section Class

local Statuses = {}

--- @section Constants

local DEFAULT_STATUSES = tables.copy(cfg_statuses._defaults)

--- @section State

local pending_revives = {}

--- @section Lifecycle

function Statuses:on_load()
    local player = self.player
    local unique_id = player.unique_id

    --- @section Player Data

    local result = MySQL.query.await("SELECT * FROM rig_player_statuses WHERE unique_id = ?", { unique_id })
    local statuses = result and result[1] or DEFAULT_STATUSES

    if not result or #result == 0 then
        MySQL.insert.await("INSERT INTO rig_player_statuses (unique_id) VALUES (?)", { unique_id })
    end

    statuses.pending_revive = false
    statuses.is_downed = statuses.health > 0 and statuses.health <= 20
    statuses.is_dead = statuses.health <= 0
    
    player:add_data("statuses", statuses, true)

    --- @section Methods

    --- Getters

    player:add_method("get_statuses", function()
        return player:get_data("statuses")
    end)

    player:add_method("get_status", function(key)
        return player:get_data("statuses")[key]
    end)

    --- Setters

    player:add_method("set_statuses", function(updates)
        player:set_data("statuses", updates, true)
    end)

    player:add_method("set_status", function(key, value)
        player:set_data("statuses", { [key] = value }, true)
    end)

    player:add_method("reset_statuses", function()
        return player:set_data("statuses", DEFAULT_STATUSES, true)
    end)

    --- Validation

    player:add_method("is_dead", function()
        local statuses = player:get_data("statuses")
        return statuses and statuses.is_dead
    end)

    player:add_method("is_downed", function()
        local statuses = player:get_data("statuses")
        return statuses and statuses.is_downed
    end)

    --- Actions

    player:add_method("revive_player", function()
        player:run_method("set_status", "pending_revive", true)
        player:run_method("set_status", "is_downed", false)
        player:run_method("reset_statuses")
        player:run_method("clear_effects")
        player:run_method("clear_injuries")
        TriggerClientEvent("rig:cl:revive_player", player.source)
        log("success", locale("log_player_revived", player.username))
    end)

    player:add_method("respawn_player", function()
        player:run_method("set_status", "is_dead", true)
        player:run_method("set_status", "is_downed", false)
        player:run_method("reset_statuses")
        player:run_method("clear_effects")
        player:run_method("clear_injuries")
        core.players:assign_personal_bucket(player.source)
        TriggerClientEvent("rig:cl:respawn_player", player.source)
        log("success", locale("log_player_respawned", player.username))
    end)

    player:add_method("down_player", function()
        local statuses = player:get_data("statuses")
        if not statuses or statuses.health <= 0 then return end
        local total_time = 20000
        local steps = 12
        local interval = total_time / steps
        local drain_per_step = (statuses.health - 1) / steps
        local step = 0
        player:run_method("set_status", "is_downed", true)
        TriggerClientEvent("rig:cl:player_downed", player.source, { duration = total_time })
        log("info", locale("statuses.log_player_downed", player.username))
        local function bleed_out()
            step = step + 1
            local current = player:get_data("statuses")
            if not current then return end
            if current.health > 20 then return end
            local new_health = math.max(0, current.health - drain_per_step)
            player:run_method("set_status", "health", new_health)
            if new_health <= 0 or step >= steps then
                player:run_method("kill_player")
                return
            end
            SetTimeout(interval, bleed_out)
        end
        SetTimeout(interval, bleed_out)
    end)

    player:add_method("kill_player", function()
        player:run_method("reset_statuses")
        player:run_method("clear_effects")
        player:run_method("clear_injuries")
        player:run_method("set_status", "health", 0)
        player:run_method("set_status", "is_dead", true)
        local ped = GetPlayerPed(player.source)
        SetEntityHealth(ped, 0)
        SetPedArmour(ped, 0)
        TriggerClientEvent("rig:cl:player_died", player.source)
        log("info", locale("log_player_died", player.username))
    end)

    player:add_method("pickup_player", function()
        local statuses = player:get_data("statuses")
        if not statuses or statuses.health > 30 then return false end
        player:run_method("set_status", "health", 35)
        player:run_method("set_status", "pending_revive", true)
        TriggerClientEvent("rig:cl:player_picked_up", player.source)
        log("success", locale("log_player_picked_up", player.username))
        return true
    end)
end

function Statuses:on_tick(dt)
    local player = self.player
    if not player:is_playing() then return end
    local statuses = player:get_data("statuses")
    if not statuses or statuses.health <= 5 then return end
    local updates = {}
    local health = statuses.health
    updates.hunger = math.max(0, statuses.hunger - (0.1 * dt))
    updates.thirst = math.max(0, statuses.thirst - (0.15 * dt))
    updates.hygiene = math.max(0, statuses.hygiene - (0.02 * dt))
    updates.sanity = math.max(0, statuses.sanity - (0.01 * dt))
    if updates.hunger <= 0 then health = math.max(0, health - (0.5 * dt)) end
    if updates.thirst <= 0 then health = math.max(0, health - (1.0 * dt)) end
    local effects = player:get_data("effects")
    if effects then
        local now = os.time()
        for effect_id, effect in pairs(effects) do
            if effect.expires_at and now >= effect.expires_at then
                player:run_method("clear_effect", effect_id)
            else
                local md = effect.modifiers
                if md then
                    local stacks = effect.stacks or 1
                    if md.health_drain then health = math.max(0, health - (md.health_drain * stacks * dt)) end
                    if md.infection_drain then updates.infection = math.min(100, (statuses.infection or 0) + (md.infection_drain * stacks * dt)) end
                    if md.poison_drain then updates.poison = math.min(100, (statuses.poison or 0) + (md.poison_drain * stacks * dt)) end
                    if md.stress_drain then updates.stress = math.min(100, (statuses.stress or 0) + (md.stress_drain * stacks * dt)) end
                    if md.sanity_drain then updates.sanity = math.max(0, (updates.sanity or statuses.sanity) - (md.sanity_drain * stacks * dt)) end
                    if md.thirst_drain then updates.thirst = math.max(0, (updates.thirst or statuses.thirst) - (md.thirst_drain * stacks * dt)) end
                end
            end
        end
    end
    local prev_health = statuses.health
    updates.health = health
    if health <= 20 and prev_health > 20 then
        player:run_method("down_player")
    end
    player:set_data("statuses", updates, true)
end

function Statuses:on_save()
    local statuses = self.player:get_data("statuses")
    if not statuses then return end
    return {{
        query = "INSERT INTO rig_player_statuses (unique_id, health, armour, hunger, thirst, hygiene, stress, sanity, temperature, bleeding, radiation, infection, poison) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE health = VALUES(health), armour = VALUES(armour), hunger = VALUES(hunger), thirst = VALUES(thirst), hygiene = VALUES(hygiene), stress = VALUES(stress), sanity = VALUES(sanity), temperature = VALUES(temperature), bleeding = VALUES(bleeding), radiation = VALUES(radiation), infection = VALUES(infection), poison = VALUES(poison)",
        values = {
            self.player.unique_id,
            statuses.health or DEFAULT_STATUSES.health,
            statuses.armour or DEFAULT_STATUSES.armour,
            statuses.hunger or DEFAULT_STATUSES.hunger,
            statuses.thirst or DEFAULT_STATUSES.thirst,
            statuses.hygiene or DEFAULT_STATUSES.hygiene,
            statuses.stress or DEFAULT_STATUSES.stress,
            statuses.sanity or DEFAULT_STATUSES.sanity,
            statuses.temperature or DEFAULT_STATUSES.temperature,
            statuses.bleeding or DEFAULT_STATUSES.bleeding,
            statuses.radiation or DEFAULT_STATUSES.radiation,
            statuses.infection or DEFAULT_STATUSES.infection,
            statuses.poison or DEFAULT_STATUSES.poison
        }
    }}
end

return Statuses