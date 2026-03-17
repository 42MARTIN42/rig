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

--- @section Events

RegisterServerEvent("rig:sv:disconnect", function()
    local _src = source
    DropPlayer(_src, locale("disconnected"))
end)

AddEventHandler("rig:sv:player_loaded", function(player)
    local objects = core.objects:get_sync_payload()
    core.sync_static_data_to_client(player.source)
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