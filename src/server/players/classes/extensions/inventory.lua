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

--- @class Inventory
--- @description Player inventory extension for grid-based inventory management.

--- @section Imports

local item_defs = require("configs.items")
local inv_defs = require("configs.inventories")

--- @section Helpers

local function resolve_groups(items, group_id)
    if group_id and items[group_id] then
        return { [group_id] = items[group_id] }
    end
    return items
end

local function resolve_mutation_groups(items, group_id)
    if group_id then
        return items[group_id] and { [group_id] = items[group_id] } or {}
    end
    local groups = {}
    for gid, group_items in pairs(items) do
        local def = inv_defs[gid]
        if def and def.is_player then
            groups[gid] = group_items
        end
    end
    return groups
end

local function has_required_amount(item, req)
    return (item.quantity or 1) >= req
end

local function find_item_by_slot(groups, col, row, req)
    local key = col .. "_" .. row
    for group_id, group_items in pairs(groups) do
        local item = group_items[key]
        if item and has_required_amount(item, req) then
            return item, key, group_id
        end
    end
end

local function find_item_by_id(groups, item_id, req)
    for group_id, group_items in pairs(groups) do
        for key, item in pairs(group_items) do
            if item.id == item_id and has_required_amount(item, req) then
                return item, key, group_id
            end
        end
    end
end

local function find_item_by_metadata(groups, lookup, req)
    local lookup_id = lookup.id
    for group_id, group_items in pairs(groups) do
        for key, item in pairs(group_items) do
            local match = true
            if lookup_id and item.id ~= lookup_id then match = false end
            if match then
                for k, v in pairs(lookup) do
                    if k ~= "id" then
                        if not item.metadata or item.metadata[k] ~= v then
                            match = false
                            break
                        end
                    end
                end
            end
            if match and has_required_amount(item, req) then
                return item, key, group_id
            end
        end
    end
end

local function metadata_equal(a, b)
    if a == b then return true end
    if not a or not b then return false end
    for k, v in pairs(a) do if b[k] ~= v then return false end end
    for k, v in pairs(b) do if a[k] ~= v then return false end end
    return true
end

local function find_free_slot(group_items, group_def, w, h)
    local cols = group_def.columns or 10
    local rows = group_def.rows or 6

    local occupied = {}
    for key, item in pairs(group_items) do
        local ic, ir = key:match("^(%d+)_(%d+)$")
        ic, ir = tonumber(ic), tonumber(ir)
        if ic and ir then
            for dc = 0, (item.w or 1) - 1 do
                for dr = 0, (item.h or 1) - 1 do
                    occupied[(ic + dc) .. "_" .. (ir + dr)] = true
                end
            end
        end
    end

    for r = 1, rows - (h - 1) do
        for c = 1, cols - (w - 1) do
            local fits = true
            for dc = 0, w - 1 do
                for dr = 0, h - 1 do
                    if occupied[(c + dc) .. "_" .. (r + dr)] then
                        fits = false
                        break
                    end
                end
                if not fits then break end
            end
            if fits then return c, r end
        end
    end

    return nil, nil
end

--- @section Class

local Inventory = {}

--- @section Lifecycle

function Inventory:on_load()
    local player = self.player
    local unique_id = player.unique_id

    local result = MySQL.single.await("SELECT * FROM rig_inventories WHERE identifier = ? AND type = 'player'", { unique_id })

    local items, metadata = {}, {}

    if result then
        items = json.decode(result.items) or {}
        metadata = json.decode(result.metadata) or {}
    else
        MySQL.insert.await("INSERT INTO rig_inventories (identifier, owner, type, items, metadata) VALUES (?, ?, 'player', ?, ?)", {
            unique_id, unique_id, json.encode(items), json.encode(metadata)
        })
    end

    player:add_data("inventory", { items = items, metadata = metadata }, true)

    --- @section Methods

    player:add_method("get_items", function(group_id)
        local inv = player:get_data("inventory")
        if not inv or not inv.items then return {} end
        if group_id then return inv.items[group_id] or {} end
        return inv.items
    end)

    player:add_method("get_item", function(lookup, quantity, group_id)
        local inv = player:get_data("inventory")
        if not inv or not inv.items then return nil, nil, nil end
        local groups = resolve_groups(inv.items, group_id)
        local req = quantity or 1
        local lookup_type = type(lookup)
        if lookup_type == "table" and lookup.col and lookup.row then
            return find_item_by_slot(groups, lookup.col, lookup.row, req)
        end
        if lookup_type == "string" then
            local col, row = lookup:match("^(%d+)_(%d+)$")
            if col and row then
                return find_item_by_slot(groups, tonumber(col), tonumber(row), req)
            end
            return find_item_by_id(groups, lookup, req)
        end
        if lookup_type == "table" then
            return find_item_by_metadata(groups, lookup, req)
        end
        return nil, nil, nil
    end)

    player:add_method("get_total_item_quantity", function(item_id, group_id)
        local inv = player:get_data("inventory")
        if not inv or not inv.items then return 0 end
        local total = 0
        local groups = group_id and { [group_id] = inv.items[group_id] } or inv.items
        for _, group_items in pairs(groups) do
            if type(group_items) == "table" then
                for _, item in pairs(group_items) do
                    if type(item) == "table" and item.id == item_id then
                        total = total + (item.quantity or 1)
                    end
                end
            end
        end
        return total
    end)

    player:add_method("get_inventory_metadata", function()
        local inv = player:get_data("inventory")
        return inv and inv.metadata or {}
    end)

    player:add_method("has_item", function(lookup, quantity, group_id)
        local item = player:run_method("get_item", lookup, quantity, group_id)
        return item ~= nil
    end)

    player:add_method("has_inventory_group", function(group_id)
        local inv = player:get_data("inventory")
        return inv and inv.items and inv.items[group_id] ~= nil
    end)

    player:add_method("set_inventory_metadata", function(metadata, merge)
        local inv = player:get_data("inventory")
        if not inv or type(metadata) ~= "table" then return false end
        if merge then
            inv.metadata = inv.metadata or {}
            for k, v in pairs(metadata) do inv.metadata[k] = v end
        else
            inv.metadata = metadata
        end
        return player:set_data("inventory", inv, true)
    end)

    player:add_method("set_item_metadata", function(lookup, metadata, merge, group_id)
        local inv = player:get_data("inventory")
        if not inv or type(metadata) ~= "table" then return false end
        local item = player:run_method("get_item", lookup, 1, group_id)
        if not item then return false end
        if merge then
            item.metadata = item.metadata or {}
            for k, v in pairs(metadata) do item.metadata[k] = v end
        else
            item.metadata = metadata
        end
        return player:set_data("inventory", inv, true)
    end)

    player:add_method("add_item", function(id, quantity, metadata, group_id, col, row)
        local inv = player:get_data("inventory")
        if not inv then return false, "inventory_missing" end
        if type(id) ~= "string" then return false, "item_id_missing" end
        quantity = quantity or 1
        if type(quantity) ~= "number" or quantity <= 0 then return false, "item_invalid_amount" end
        metadata = metadata or {}
        local item_def = item_defs[id]
        if not item_def then return false, "invalid_item_id" end
        inv.items = inv.items or {}
        local groups = resolve_mutation_groups(inv.items, group_id)
        if not next(groups) then return false, "invalid_group" end

        if item_def.unique then
            for _, group_items in pairs(inv.items) do
                for _, item in pairs(group_items) do
                    if item.id == id then return false, "item_unique_already_owned" end
                end
            end
        end

        local final_metadata = {}
        if type(item_def.metadata) == "table" then
            for k, v in pairs(item_def.metadata) do final_metadata[k] = v end
        end
        for k, v in pairs(metadata) do final_metadata[k] = v end

        local w = item_def.w or 1
        local h = item_def.h or 1
        local stackable = item_def.stackable
        if stackable == nil then stackable = true end
        local max_stack = type(stackable) == "number" and stackable or math.huge
        local remaining = quantity
        if stackable ~= false and not col then
            for gid, group_items in pairs(groups) do
                for _, item in pairs(group_items) do
                    if item.id == id and metadata_equal(item.metadata or {}, final_metadata) then
                        local can_add = max_stack - (item.quantity or 1)
                        if can_add > 0 then
                            local add = math.min(can_add, remaining)
                            item.quantity = (item.quantity or 1) + add
                            remaining = remaining - add
                            if remaining <= 0 then
                                player:set_data("inventory", inv, true)
                                return true, "item_added_success"
                            end
                        end
                    end
                end
            end
        end

        for gid, group_items in pairs(groups) do
            local group_def = inv_defs[gid]
            while remaining > 0 do
                local tc, tr = col, row
                if not tc or not tr then
                    tc, tr = find_free_slot(group_items, group_def, w, h)
                end
                if not tc or not tr then break end
                local add = remaining
                if stackable ~= false and type(stackable) == "number" then
                    add = math.min(stackable, remaining)
                end
                local key = tc .. "_" .. tr
                group_items[key] = { id = id, quantity = add, metadata = next(final_metadata) and final_metadata or nil, col = tc, row = tr, w = w, h = h }
                remaining = remaining - add
                col, row = nil, nil
            end
            if remaining <= 0 then
                player:set_data("inventory", inv, true)
                return true, "item_added_success"
            end
        end

        if remaining < quantity then
            player:set_data("inventory", inv, true)
            return true, "item_added_partial"
        end

        return false, "no_free_slot"
    end)

    player:add_method("remove_item", function(lookup, quantity, group_id)
        local inv = player:get_data("inventory")
        if not inv then return false, "inventory_missing" end
        quantity = quantity or 1
        if type(quantity) ~= "number" or quantity <= 0 then return false, "item_invalid_amount" end
        local item, key, found_group = player:run_method("get_item", lookup, 1, group_id)
        if not item then return false, "item_not_found" end
        local resolved_group = found_group or group_id
        if not resolved_group then return false, "item_group_unresolvable" end
        local resolved_key = key
        if not resolved_key and item.col and item.row then
            resolved_key = item.col .. "_" .. item.row
        end
        if not resolved_key then return false, "item_key_unresolvable" end
        local group_items = inv.items[resolved_group]
        if not group_items then return false, "group_items_missing" end
        local current = item.quantity or 1
        if current > quantity then
            group_items[resolved_key].quantity = current - quantity
        else
            group_items[resolved_key] = nil
        end
        player:set_data("inventory", inv, true)
        return true, "item_removed_success"
    end)

    player:add_method("move_item", function(from_col, from_row, to_col, to_row, from_group, to_group)
        local inv = player:get_data("inventory")
        if not inv then return false, "inventory_missing" end
        from_group = from_group or "pockets"
        to_group = to_group or from_group
        local from_key = from_col .. "_" .. from_row
        local to_key = to_col .. "_" .. to_row
        if from_key == to_key and from_group == to_group then return false, "item_move_same_slot" end
        inv.items[from_group] = inv.items[from_group] or {}
        inv.items[to_group] = inv.items[to_group] or {}
        local from_items = inv.items[from_group]
        local to_items = inv.items[to_group]
        local source_item = from_items[from_key]
        if not source_item then return false, "item_move_source_empty" end
        local dest_item = to_items[to_key]
        local to_def = inv_defs[to_group]
        local src_w = source_item.w or item_defs[source_item.id] and item_defs[source_item.id].w or 1
        local src_h = source_item.h or item_defs[source_item.id] and item_defs[source_item.id].h or 1

        local function build_occupied(items, exclude_keys)
            local occupied = {}
            for key, item in pairs(items) do
                if not exclude_keys[key] then
                    local ic, ir = key:match("^(%d+)_(%d+)$")
                    ic, ir = tonumber(ic), tonumber(ir)
                    if ic and ir then
                        local iw = item.w or item_defs[item.id] and item_defs[item.id].w or 1
                        local ih = item.h or item_defs[item.id] and item_defs[item.id].h or 1
                        for dc = 0, iw - 1 do
                            for dr = 0, ih - 1 do
                                occupied[(ic + dc) .. "_" .. (ir + dr)] = true
                            end
                        end
                    end
                end
            end
            return occupied
        end

        local function fits_at(items, col, row, w, h, exclude_keys)
            if not to_def then return false end
            local cols = to_def.columns or 10
            local rows = to_def.rows or 6
            if col + w - 1 > cols or row + h - 1 > rows then return false end
            local occupied = build_occupied(items, exclude_keys)
            for dc = 0, w - 1 do
                for dr = 0, h - 1 do
                    if occupied[(col + dc) .. "_" .. (row + dr)] then return false end
                end
            end
            return true
        end

        if not dest_item then
            local exclude = { [from_key] = true }
            if not fits_at(to_items, to_col, to_row, src_w, src_h, exclude) then
                return false, "item_move_no_space"
            end
            to_items[to_key] = { id = source_item.id, quantity = source_item.quantity, metadata = source_item.metadata, col = to_col, row = to_row }
            from_items[from_key] = nil
        elseif dest_item.id == source_item.id and metadata_equal(source_item.metadata or {}, dest_item.metadata or {}) then
            dest_item.quantity = (dest_item.quantity or 1) + (source_item.quantity or 1)
            from_items[from_key] = nil
        else
            local dest_w = dest_item.w or item_defs[dest_item.id] and item_defs[dest_item.id].w or 1
            local dest_h = dest_item.h or item_defs[dest_item.id] and item_defs[dest_item.id].h or 1
            local exclude_both = { [from_key] = true, [to_key] = true }
            if not fits_at(from_items, from_col, from_row, dest_w, dest_h, exclude_both) then
                return false, "item_move_no_space"
            end
            if not fits_at(to_items, to_col, to_row, src_w, src_h, exclude_both) then
                return false, "item_move_no_space"
            end
            from_items[from_key] = { id = dest_item.id, quantity = dest_item.quantity, metadata = dest_item.metadata, col = from_col, row = from_row }
            to_items[to_key] = { id = source_item.id, quantity = source_item.quantity, metadata = source_item.metadata, col = to_col, row = to_row }
        end

        player:set_data("inventory", inv, true)
        return true, "item_moved_success"
    end)

    player:add_method("clear_inventory", function(group_id)
        local inv = player:get_data("inventory")
        if not inv or not inv.items then return false end
        if group_id then
            inv.items[group_id] = {}
        else
            for gid in pairs(inv.items) do
                local def = inv_defs[gid]
                if def and def.is_player then
                    inv.items[gid] = {}
                end
            end
        end
        player:set_data("inventory", inv, true)
        return true
    end)

    player:add_method("add_temporary_inventory_group", function(group_id, initial_items)
        local inv = player:get_data("inventory")
        if not inv then return false end
        local inv_def = inv_defs[group_id]
        if not inv_def or not inv_def.is_player then return false end
        inv.items[group_id] = initial_items or {}
        player:set_data("inventory", inv, true)
        return true
    end)

    player:add_method("remove_temporary_inventory_group", function(group_id)
        local inv = player:get_data("inventory")
        if not inv then return nil end
        local group_items = inv.items[group_id]
        inv.items[group_id] = nil
        player:set_data("inventory", inv, true)
        return group_items or {}
    end)

end

--- @section Save

function Inventory:on_save()
    local inv = self.player:get_data("inventory")
    if not inv then return end

    return {
        {
            query = "UPDATE rig_inventories SET items = ?, metadata = ? WHERE identifier = ? AND type = 'player'",
            values = { json.encode(inv.items), json.encode(inv.metadata), self.player.unique_id }
        }
    }
end

return Inventory