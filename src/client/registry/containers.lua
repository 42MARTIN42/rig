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

--- @script src.client.registry.containers
--- @description Client-side registry for world containers.

--- @section Imports

local objects = require("src.client.modules.objects")
local interactions = require("src.client.modules.interactions")

--- @section Constants

local SPAWN_DISTANCE   = 40.0
local DESPAWN_DISTANCE = 45.0

--- @section State

local placed = {}
local vehicles = {}

--- @section Streaming

local function stream_containers(player_coords)
    for id, container in pairs(placed) do
        local pos = vector3(container.coords.x, container.coords.y, container.coords.z)
        local dist = #(player_coords - pos)

        if dist < SPAWN_DISTANCE and not container.entity then
            container.entity = objects.create(container.model, container.coords)
            local keys = {}
            for _, k in ipairs(container.keys or {}) do
                keys[#keys + 1] = {
                    key = k.key,
                    label = k.label,
                    on_action = function()
                        TriggerServerEvent("rig:sv:open_container", id)
                    end
                }
            end
            interactions.add({ id = id, coords = container.coords, header = container.label, icon = container.icon, keys = keys })

        elseif dist >= DESPAWN_DISTANCE and container.entity then
            objects.remove(container.entity)
            interactions.remove(id)
            container.entity = nil
        end
    end
end

--- @section API

function core.add_container(data)
    if type(data) ~= "table" or not data.id then return end
    data.entity = nil
    placed[data.id] = data
end

function core.get_container(id)
    return placed[id] or vehicles[id]
end

function core.remove_container(id)
    local container = placed[id]
    if not container then return end
    if container.entity then objects.remove(container.entity) end
    interactions.remove(id)
    placed[id] = nil
end

function core.add_vehicle_container(data)
    if type(data) ~= "table" or not data.id then return end
    vehicles[data.id] = data
end

function core.clear_vehicle_containers()
    for k in pairs(vehicles) do vehicles[k] = nil end
end

--- @section Events

RegisterNetEvent("rig:cl:add_container")
AddEventHandler("rig:cl:add_container", function(data)
    if type(data) ~= "table" or not data.id then return end
    data.entity = nil
    placed[data.id] = data
end)

RegisterNetEvent("rig:cl:remove_container")
AddEventHandler("rig:cl:remove_container", function(id)
    local container = placed[id]
    if not container then return end
    if container.entity then objects.remove(container.entity) end
    interactions.remove(id)
    placed[id] = nil
end)

--- @section Threads

CreateThread(function()
    while true do
        local player_coords = GetEntityCoords(PlayerPedId())
        stream_containers(player_coords)
        Wait(500)
    end
end)