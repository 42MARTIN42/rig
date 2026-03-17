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

local vehicles = require("libs.graft.fivem.vehicles")
local utils = require("src.server.modules.utils")
local inventory = require("src.server.extensions.inventory.modules.actions")

--- @section Events

RegisterServerEvent("rig:sv:move_item")
AddEventHandler("rig:sv:move_item", function(data)
    local _src = source
    inventory.move_item(_src, data)
end)

RegisterServerEvent("rig:sv:use_item")
AddEventHandler("rig:sv:use_item", function(data)
    local _src = source
    inventory.use_item(_src, data)
end)

RegisterServerEvent("rig:sv:unequip_loadout_item")
AddEventHandler("rig:sv:unequip_loadout_item", function(data)
    local _src = source
    inventory.unequip_loadout_item(_src, data)
end)

RegisterServerEvent("rig:sv:pickup_drop")
AddEventHandler("rig:sv:pickup_drop", function(drop_id)
    local _src = source
    inventory.pickup_drop(_src, drop_id)
end)

RegisterServerEvent("rig:sv:split_item")
AddEventHandler("rig:sv:split_item", function(data)
    local _src = source
    inventory.split_item(_src, data)
end)

RegisterServerEvent("rig:sv:remove_item")
AddEventHandler("rig:sv:remove_item", function(data)
    local _src = source
    core.remove_item(_src, data)
end)

RegisterServerEvent("rig:sv:animation_finished")
AddEventHandler("rig:sv:animation_finished", function(data)
    local _src = source
    inventory.animation_finished(_src, data)
end)

RegisterServerEvent("rig:sv:close_inventory")
AddEventHandler("rig:sv:close_inventory", function()
    local _src = source
    core.containers:unlock_all_for_player(_src)
    TriggerClientEvent("rig:cl:close_inventory", _src)
end)

RegisterServerEvent("rig:sv:open_inventory")
AddEventHandler("rig:sv:open_inventory", function()
    local _src = source
    local player = core.players:get(_src)
    if not player then return end
    local ped = GetPlayerPed(_src)
    if not ped or ped == 0 then return end
    local pcoords = GetEntityCoords(ped)
    local inv = player:get_data("inventory")
    local payload = {
        player_data = {
            unique_id = player.unique_id,
            name = GetPlayerName(_src),
            items = inv and inv.items or {},
            metadata = inv and inv.metadata or {}
        },
        secondary = nil,
        is_vehicle = false
    }
    local info = vehicles.get_info(nil, { source = _src, coords = pcoords, radius = 4.0 })
    if info and info.plate then
        local inv_type = info.is_inside and "glovebox" or "trunk"
        local container = core.containers:get_or_create_vehicle(info.plate, inv_type, info)
        if container and utils.try_lock_container(container.identifier, _src) then
            local cfg = utils.get_vehicle_config(info.model, info.class, inv_type)
            payload.secondary = {
                id = container.identifier,
                type = inv_type,
                items = container:get_items(),
                plate = info.plate,
                vehicle = info.entity,
                config = cfg,
                is_vehicle = true
            }
            payload.is_vehicle = true
        end
    end
    if not payload.secondary then
        local container_id, container = utils.get_nearest_container(pcoords, 2.5)
        if container_id and container and utils.try_lock_container(container_id, _src) then
            payload.secondary = {
                id = container_id,
                type = container.subtype or container.type,
                items = container:get_items(),
                metadata = container.metadata
            }
        end
    end
    TriggerClientEvent("rig:cl:open_inventory", _src, payload)
end)