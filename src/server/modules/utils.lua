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

--- @module src.server.modules.utils
--- @description Handles server side utility functions

local utils = {}

--- @section General

function utils.get_player_identifiers(source)
    local ids = {}
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:find("license2") then ids.license = id end
        if id:find("discord") then ids.discord = id end
        if id:find("ip") then ids.ip = id end
    end
    return ids
end

function utils.generate_unique_id(length, table_name, column_name, json_path)
    local charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local function create_id()
        local new_id = ""
        for i = 1, length do
            local random_index = math.random(1, #charset)
            new_id = new_id .. charset:sub(random_index, random_index)
        end
        return new_id
    end
    local function id_exists(new_id)
        local query = json_path
            and string.format("SELECT COUNT(*) as count FROM %s WHERE JSON_EXTRACT(%s, '$.%s') = ?", table_name, column_name, json_path)
            or string.format("SELECT COUNT(*) as count FROM %s WHERE %s = ?", table_name, column_name)
        local result = MySQL.query.await(query, { new_id })
        return result and result[1] and result[1].count > 0
    end
    local id
    repeat id = create_id() until not id_exists(id)
    return id
end

function utils.get_randomized_coords(center, radius)
    local angle = math.random() * 2 * math.pi
    local r = radius * math.sqrt(math.random())
    return {
        x = center.x + r * math.cos(angle),
        y = center.y + r * math.sin(angle),
        z = center.z,
        w = math.random(0.0, 360.0)
    }
end

function utils.has_permission(source, aces)
    if not aces or aces == false then return false end
    if type(aces) == "string" then aces = { aces } end
    for _, ace in ipairs(aces) do
        if IsPlayerAceAllowed(source, ace) then return true end
    end
    return false
end

--- @section Inventory

function utils.get_vehicle_config(model_name, class_name, inv_type)
    local inv_defs = require("configs.inventories")
    local config = inv_defs[model_name] or (inv_defs.vehicle_defaults and inv_defs.vehicle_defaults[class_name]) or (inv_defs.vehicle_defaults and inv_defs.vehicle_defaults.sedan)
    return config and config[inv_type] or { columns = 10, rows = 4, max_weight = 100000 }
end

function utils.try_lock_container(container_id, source)
    local is_locked, locked_by = core.containers:is_locked(container_id)
    if is_locked and locked_by ~= source then
        pluck.notify(source, { type = "error", header = "Inventory", message = locale("container.already_in_use"), duration = 3000 })
        return false
    end
    if not is_locked then
        core.containers:lock(container_id, source)
    end
    return true
end

function utils.get_nearest_container(pcoords, max_dist)
    local closest_dist = max_dist
    local closest_id = nil
    local closest_container = nil

    for id, container in pairs(core.containers.containers) do
        if container.type ~= "vehicle" and container.metadata and container.metadata.coords then
            local mc = container.metadata.coords
            local dist = #(pcoords - vector3(mc.x, mc.y, mc.z))
            if dist < closest_dist then
                closest_dist = dist
                closest_id = id
                closest_container = container
            end
        end
    end

    return closest_id, closest_container
end

function utils.build_slot_popup_data(item_defs, item_id, quantity, action)
    if not item_defs then return end
    local def = item_defs[item_id]
    if not def then return nil end
    return {
        item_id = item_id,
        image = def.image or ("/ui/assets/items/" .. item_id .. ".png"),
        quantity = quantity,
        action = action,
        rarity = def.rarity or "common"
    }
end


function utils.calculate_group_weights(items_by_group, item_defs)
    local weights = {}
    for group_id, group in pairs(items_by_group or {}) do
        local group_weight = 0
        for _, entry in pairs(group) do
            local item = item_defs[entry.id]
            if item and item.weight then
                group_weight = group_weight + (item.weight * (entry.quantity or 1))
            end
        end
        weights[group_id] = group_weight
    end
    return weights
end

function utils.calculate_total_inventory_weight(group_weights, inventory_defs)
    local current, max = 0, 0
    for group_id, def in pairs(inventory_defs or {}) do
        if def and def.is_player then
            current = current + (group_weights[group_id] or 0)
            max = max + (def.max_weight or 0)
        end
    end
    return current, max
end

function utils.calculate_group_weight(raw_items, item_defs)
    local total = 0
    for _, entry in pairs(raw_items or {}) do
        local def = item_defs[entry.id]
        if def and def.weight then
            total = total + (def.weight * (entry.quantity or 1))
        end
    end
    return total
end

return utils