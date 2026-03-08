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

--- @class Effects
--- @description Player effects extension for buffs, debuffs, and status effects.

--- @section Imports

local cfg_effects = require("configs.effects")

--- @section Class

local Effects = {}

--- @section Constants

local EFFECT_TYPES = cfg_effects._types

--- @section Lifecycle

function Effects:on_load()
    local player = self.player
    local unique_id = player.unique_id

    local result = MySQL.query.await("SELECT * FROM rig_player_effects WHERE unique_id = ?", { unique_id })
    local effects = {}

    if result and #result > 0 then
        for _, effect in ipairs(result) do
            effects[effect.effect_id] = {
                effect_type = effect.effect_type,
                effect_name = effect.effect_name,
                duration = effect.duration,
                stacks = effect.stacks or 1,
                applied_at = effect.applied_at,
                expires_at = effect.expires_at
            }
        end
    end

    player:add_data("effects", effects, true)

    --- Getters

    player:add_method("get_effects", function()
        return player:get_data("effects")
    end)

    player:add_method("get_effect", function(effect_id)
        return player:get_data("effects")[effect_id]
    end)

    --- Setters

    player:add_method("set_effects", function(updates)
        if not updates or type(updates) ~= "table" then return false end

        local now = os.time()
        local validated_updates = {}

        for effect_id, effect_data in pairs(updates) do
            if effect_data and type(effect_data) == "table" then
                if not EFFECT_TYPES[effect_data.effect_type] then return false end
                local duration = tonumber(effect_data.duration) or -1
                validated_updates[effect_id] = {
                    effect_type = effect_data.effect_type,
                    effect_name = effect_data.effect_name or "",
                    duration = duration,
                    stacks = tonumber(effect_data.stacks) or 1,
                    applied_at = now,
                    expires_at = duration ~= -1 and (now + duration) or nil
                }
            end
        end

        return player:set_data("effects", validated_updates, true)
    end)

    player:add_method("set_effect", function(effect_id, effect_data)
        if not effect_data or type(effect_data) ~= "table" then return false end
        if not EFFECT_TYPES[effect_data.effect_type] then return false end

        local now = os.time()
        local duration = tonumber(effect_data.duration) or -1

        local validated = {
            [effect_id] = {
                effect_type = effect_data.effect_type,
                effect_name = effect_data.effect_name or "",
                duration = duration,
                stacks = tonumber(effect_data.stacks) or 1,
                applied_at = now,
                expires_at = duration ~= -1 and (now + duration) or nil
            }
        }

        return player:set_data("effects", validated, true)
    end)

    --- Clean up

    player:add_method("clear_effect", function(effect_id)
        player:set_data("effects", { [effect_id] = nil }, true)
    end)

    player:add_method("clear_effects", function()
        player:replace_data("effects", {}, true)
    end)
end

function Effects:on_save()
    local effects = self.player:get_data("effects")
    if not effects then return end
    local queries = {}
    for effect_id, effect_data in pairs(effects) do
        if effect_data then
            queries[#queries + 1] = {
                query = "INSERT INTO rig_player_effects (unique_id, effect_id, effect_type, effect_name, duration, stacks, applied_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE effect_type = VALUES(effect_type), effect_name = VALUES(effect_name), duration = VALUES(duration), stacks = VALUES(stacks), applied_at = VALUES(applied_at), expires_at = VALUES(expires_at), metadata = VALUES(metadata)",
                values = {
                    self.player.unique_id,
                    effect_id,
                    effect_data.effect_type,
                    effect_data.effect_name or "",
                    effect_data.duration or -1,
                    effect_data.stacks or 1,
                    effect_data.applied_at,
                    effect_data.expires_at
                }
            }
        end
    end
    return queries
end

return Effects