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

local player_data = {}

--- @section API Functions

function core.get_player_data(category)
    return (category and player_data[category]) or player_data
end

exports("get_player_data", core.get_player_data)

function core.has_player_data(category)
    return core.get_player_data(category) ~= nil
end

exports("has_player_data", core.has_player_data)

function core.dump_player_data()
    log("debug", locale("registry.client.player_data_dump", json.encode(core.get_player_data())))
end

exports("dump_player_data", core.dump_player_data)

--- @section Events

RegisterNetEvent("rig:cl:player_loaded")
AddEventHandler("rig:cl:player_loaded", function(meta)
    if type(meta) ~= "table" or not meta.source then log("error", locale("registry.client.player_meta_missing")) return end
    log("info", locale("registry.client.player_loaded", meta.username, meta.source))
    TriggerServerEvent("rig:sv:get_command_suggestions")
end)

RegisterNetEvent("rig:cl:playing_state_changed")
AddEventHandler("rig:cl:playing_state_changed", function(state)
    if not state then log("error", locale("registry.client.playing_state_missing")) return end
    log("info", locale("registry.client.playing_state_changed", state and "playing" or "not playing"))
end)

RegisterNetEvent("rig:cl:sync_player_data")
AddEventHandler("rig:cl:sync_player_data", function(payload)
    if type(payload) ~= "table" then return end
    for category, data in pairs(payload) do
        if type(category) == "string" and type(data) == "table" then
            player_data[category] = data
            log("debug", locale("registry.client.player_data_synced", category, json.encode(data)))
        end
    end
end)