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

--- @class Injuries
--- @description Player injuries extension for body-part specific damage tracking.

--- @section Imports

local cfg_injuries = require("configs.injuries")

--- @section Class

local Injuries = {}

--- @section Constants

local DEFAULT_INJURIES = cfg_injuries._defaults

--- @section Lifecycle

function Injuries:on_load()
    local player = self.player
    local unique_id = player.unique_id

    --- @section Player Data

    local result = MySQL.query.await("SELECT * FROM rig_player_injuries WHERE unique_id = ?", { unique_id })
    local injuries

    if not result or #result == 0 then
        MySQL.insert.await("INSERT INTO rig_player_injuries (unique_id) VALUES (?)", { unique_id })
        injuries = DEFAULT_INJURIES
    else
        injuries = result[1]
        injuries.unique_id = nil
    end

    player:add_data("injuries", injuries, true)

    --- @section Methods

    --- Getters

    player:add_method("get_injuries", function()
        return player:get_data("injuries")
    end)

    player:add_method("get_injury", function(body_part)
        return player:get_data("injuries")[body_part]
    end)

    --- Setters

    player:add_method("set_injuries", function(updates)
        if not updates or type(updates) ~= "table" then return false end
        local validated = {}
        for body_part, damage in pairs(updates) do
            if DEFAULT_INJURIES[body_part] ~= nil then
                validated[body_part] = math.max(0.0, math.min(100.0, tonumber(damage) or 0.0))
            end
        end
        return player:set_data("injuries", validated, true)
    end)

    player:add_method("set_injury", function(body_part, damage)
        if not DEFAULT_INJURIES[body_part] then return false end
        return player:set_data("injuries", {
            [body_part] = math.max(0.0, math.min(100.0, tonumber(damage) or 0.0))
        }, true)
    end)

    --- Clean up

    player:add_method("clear_injury", function(body_part)
        if not DEFAULT_INJURIES[body_part] then return false end
        return player:set_data("injuries", { [body_part] = 0.0 }, true)
    end)
    
    player:add_method("clear_injuries", function()
        player:replace_data("injuries", DEFAULT_INJURIES, true)
    end)
end

function Injuries:on_save()
    local injuries = self.player:get_data("injuries")
    if not injuries then return end
    return {{
        query = "INSERT INTO rig_player_injuries (unique_id, head, upper_torso, lower_torso, forearm_right, forearm_left, hand_right, hand_left, thigh_right, thigh_left, calf_right, calf_left, foot_right, foot_left) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE head = VALUES(head), upper_torso = VALUES(upper_torso), lower_torso = VALUES(lower_torso), forearm_right = VALUES(forearm_right), forearm_left = VALUES(forearm_left), hand_right = VALUES(hand_right), hand_left = VALUES(hand_left), thigh_right = VALUES(thigh_right), thigh_left = VALUES(thigh_left), calf_right = VALUES(calf_right), calf_left = VALUES(calf_left), foot_right = VALUES(foot_right), foot_left = VALUES(foot_left)",
        values = {
            self.player.unique_id,
            injuries.head or 0.0,
            injuries.upper_torso or 0.0,
            injuries.lower_torso or 0.0,
            injuries.forearm_right or 0.0,
            injuries.forearm_left or 0.0,
            injuries.hand_right or 0.0,
            injuries.hand_left or 0.0,
            injuries.thigh_right or 0.0,
            injuries.thigh_left or 0.0,
            injuries.calf_right or 0.0,
            injuries.calf_left or 0.0,
            injuries.foot_right or 0.0,
            injuries.foot_left or 0.0
        }
    }}
end

return Injuries