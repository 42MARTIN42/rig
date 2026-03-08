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

--- @script src.client.registry.objects
--- @description Client-side registry for players and placed objects.

--- @section Imports

local objects = require("src.client.modules.objects")
local interactions = require("src.client.modules.interactions")

--- @section Constants

local SPAWN_DISTANCE = 150.0
local DESPAWN_DISTANCE = 200.0

--- @section Tables

local placed = {}
--- placed[id] = { model, object_type, label, icon, keys, coords, entity }

--- @section Functions

local function stream_placed(player_coords)
    for id, obj in pairs(placed) do
        local pos = vector3(obj.coords.x, obj.coords.y, obj.coords.z)
        local dist = #(player_coords - pos)
        if dist < SPAWN_DISTANCE and not obj.entity then
            obj.entity = objects.create(obj.model, obj.coords)
            local keys = {}
            for _, k in ipairs(obj.keys or {}) do
                keys[#keys + 1] = {
                    key = k.key,
                    label = k.label,
                    on_action = function()
                        TriggerServerEvent("rig:sv:use_placed_object", id, k.key)
                    end
                }
            end
            interactions.add({ id = id, coords = obj.coords, header = obj.label, icon = obj.icon, keys = keys })
        elseif dist >= DESPAWN_DISTANCE and obj.entity then
            objects.remove(obj.entity)
            interactions.remove(id)
            obj.entity = nil
        end
    end
end

--- @section Events

RegisterNetEvent("rig:cl:load_placed_objects")
AddEventHandler("rig:cl:load_placed_objects", function(list)
    for _, obj in ipairs(list) do
        placed[obj.id] = {
            model = obj.model,
            object_type = obj.object_type,
            label = obj.label,
            icon = obj.icon,
            keys = obj.keys,
            coords = vector4(obj.x, obj.y, obj.z, obj.w or 0.0),
            entity = nil
        }
    end
end)

RegisterNetEvent("rig:cl:spawn_placed_object")
AddEventHandler("rig:cl:spawn_placed_object", function(id, model, object_type, label, icon, keys, x, y, z, w)
    placed[id] = {
        model = model,
        object_type = object_type,
        label = label,
        icon = icon,
        keys = keys,
        coords = vector4(x, y, z, w or 0.0),
        entity = nil
    }
end)

RegisterNetEvent("rig:cl:remove_placed_object")
AddEventHandler("rig:cl:remove_placed_object", function(id)
    local obj = placed[id]
    if not obj then return end
    if obj.entity then objects.remove(obj.entity) end
    interactions.remove(id)
    placed[id] = nil
end)

--- @section Threads

CreateThread(function()
    while true do
        local player_coords = GetEntityCoords(PlayerPedId())
        stream_placed(player_coords)
        Wait(500)
    end
end)

--- @section Test Commands

RegisterCommand("test_placer", function()
    objects.start_placing({
        model = "prop_skid_sleepbag_1",
        label = "PLACE SLEEPINGBAG",
        on_confirm = function(coords)
            TriggerServerEvent("rig:sv:place_object", { object_type = "sleeping_bag", coords = coords })
        end
    })
end, false)