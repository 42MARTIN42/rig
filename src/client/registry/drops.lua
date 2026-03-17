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

--- @script src.client.registry.drops
--- @description Client-side registry for ground drops.

--- @section Imports

local objects = require("src.client.modules.objects")
local interactions = require("src.client.modules.interactions")

--- @section Constants

local SPAWN_DISTANCE   = 30.0
local DESPAWN_DISTANCE = 35.0

--- @section State

local drops = {}
core.client_drops = drops

--- @section Streaming

local function stream_drops(player_coords)
    for id, drop in pairs(drops) do
        local pos = vector3(drop.coords.x, drop.coords.y, drop.coords.z)
        local dist = #(player_coords - pos)

        if dist < SPAWN_DISTANCE and not drop.entity then
            drop.entity = objects.create(drop.model, drop.coords)
            interactions.add({
                id = id,
                coords = drop.coords,
                header = drop.label,
                icon = drop.icon,
                keys = {
                    {
                        key = "pickup",
                        label = "Pick Up",
                        on_action = function()
                            TriggerServerEvent("rig:sv:pickup_drop", id)
                        end
                    }
                }
            })

        elseif dist >= DESPAWN_DISTANCE and drop.entity then
            objects.remove(drop.entity)
            interactions.remove(id)
            drop.entity = nil
        end
    end
end

--- @section Events

RegisterNetEvent("rig:cl:init_drops")
AddEventHandler("rig:cl:init_drops", function(data)
    if type(data) ~= "table" then return end
    for id, drop in pairs(data) do
        drop.entity = nil
        drops[id] = drop
    end
end)

RegisterNetEvent("rig:cl:add_drop")
AddEventHandler("rig:cl:add_drop", function(data)
    if type(data) ~= "table" or not data.id then return end
    data.entity = nil
    drops[data.id] = data
end)

RegisterNetEvent("rig:cl:remove_drop")
AddEventHandler("rig:cl:remove_drop", function(id)
    local drop = drops[id]
    if not drop then return end
    if drop.entity then objects.remove(drop.entity) end
    interactions.remove(id)
    drops[id] = nil
end)

--- @section Threads

CreateThread(function()
    TriggerServerEvent("rig:sv:request_drops")

    while true do
        local player_coords = GetEntityCoords(PlayerPedId())
        stream_drops(player_coords)
        Wait(500)
    end
end)