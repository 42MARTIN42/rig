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

local item_defs = require("configs.items")
local inv_defs = require("configs.inventories")

local Container = {}
Container.__index = Container
Container.__metatable = false

local Private = setmetatable({}, { __mode = "k" })

local function has_required_amount(item, req)
    return (item.quantity or 1) >= req
end

local function resolve_groups(items, group_id)
    if group_id and items[group_id] then
        return { [group_id] = items[group_id] }
    end
    return items
end

local function metadata_equal(a, b)
    if a == b then return true end
    if not a or not b then return false end
    for k, v in pairs(a) do if b[k] ~= v then return false end end
    for k, v in pairs(b) do if a[k] ~= v then return false end end
    return true
end

local function get_vehicle_group_config(group_id, container)
    local inv_type, plate = group_id:match("^vehicle:([^:]+):(.+)$")
    if not inv_type or not plate then return false, nil end
    local class_name = "sedan"
    if container and container.vehicle_class then
        local class_map = {
            [0]="compact",[1]="sedan",[2]="suv",[3]="coupe",[4]="muscle",
            [5]="sports",[6]="super",[7]="motorcycle",[8]="offroad",
            [9]="industrial",[10]="utility",[11]="van",[12]="van",
            [13]="offroad",[14]="service",[15]="emergency",[16]="emergency",
            [17]="emergency",[18]="emergency",[19]="utility",
            [20]="commercial",[21]="motorcycle"
        }
        class_name = class_map[container.vehicle_class] or "sedan"
    end
    local class_config = inv_defs.vehicle_defaults[class_name] or inv_defs.vehicle_defaults.sedan
    local inv_config = class_config[inv_type]
    if not inv_config then return false, nil end
    return true, {
        is_container = true,
        columns = inv_config.columns or 10,
        rows = inv_config.rows or 4,
        max_weight = inv_config.weight or 200000
    }
end

local function find_item_by_slot(groups, col, row, req)
    local key = col .. "_" .. row
    for gid, group_items in pairs(groups) do
        local item = group_items and group_items[key]
        if item and has_required_amount(item, req) then
            return item, key, gid
        end
    end
end

local function find_item_by_id(groups, item_id, req)
    for gid, group_items in pairs(groups) do
        if type(group_items) == "table" then
            for key, item in pairs(group_items) do
                if item and item.id == item_id and has_required_amount(item, req) then
                    return item, key, gid
                end
            end
        end
    end
end

local function find_item_by_metadata(groups, lookup, req)
    local lookup_id = lookup.id
    for gid, group_items in pairs(groups) do
        if type(group_items) == "table" then
            for key, item in pairs(group_items) do
                if item then
                    local match = (not lookup_id or item.id == lookup_id)
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
                        return item, key, gid
                    end
                end
            end
        end
    end
end

local function find_free_slot(group_items, group_def, w, h)
    local cols = group_def.columns or 10
    local rows = group_def.rows or 4
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

function Container.new(identifier, data)
    local self = setmetatable({}, Container)
    data = data or {}
    self.identifier = identifier
    self.owner = data.owner or "unknown"
    self.type = data.type or "container"
    self.subtype = data.subtype
    self.metadata = data.metadata or {}
    self.persist = data.persist or (self.metadata.persist ~= false and self.metadata.persist ~= nil)
    Private[self] = { inventory = {}, loaded = false, dirty = false }
    return self
end

function Container:load()
    local priv = Private[self]
    if not priv then return false end

    if not self.persist then
        priv.inventory = { items = {}, metadata = self.metadata or {} }
        priv.loaded = true
        priv.dirty = false
        return true
    end

    local result = MySQL.single.await("SELECT * FROM rig_inventories WHERE identifier = ?", { self.identifier })
    if not result then
        local insert_id = MySQL.insert.await("INSERT INTO rig_inventories (identifier, owner, type, subtype, items, metadata) VALUES (?, ?, ?, ?, ?, ?)", {
            self.identifier, self.owner, self.type, self.subtype,
            json.encode({}), json.encode({})
        })
        if not insert_id then return false end
        priv.inventory = { items = {}, metadata = {} }
    else
        priv.inventory = {
            items = json.decode(result.items) or {},
            metadata = json.decode(result.metadata) or {}
        }
    end

    priv.loaded = true
    priv.dirty = false
    return true
end

function Container:has_loaded()
    local priv = Private[self]
    return priv and priv.loaded or false
end

function Container:mark_dirty()
    local priv = Private[self]
    if priv then priv.dirty = true end
end

function Container:save(force)
    local priv = Private[self]
    if not priv or not priv.loaded then return false end
    if not self.persist then return true end
    if not priv.dirty and not force then return true end
    local items = json.encode(priv.inventory.items)
    local metadata = json.encode(priv.inventory.metadata)
    local affected = MySQL.update.await("UPDATE rig_inventories SET items = ?, metadata = ? WHERE identifier = ?", {
        items, metadata, self.identifier
    })
    if (not affected or affected == 0) and force then
        MySQL.insert.await("INSERT INTO rig_inventories (identifier, owner, type, subtype, items, metadata) VALUES (?, ?, ?, ?, ?, ?)", {
            self.identifier, self.owner, self.type, self.subtype, items, metadata
        })
    end
    priv.dirty = false
    return true
end

function Container:sync(target)
    local priv = Private[self]
    if not priv or not priv.loaded then return end
    local coords = (priv.inventory.metadata or {}).coords
    if not coords then return end
    local lookup_key = self.subtype or self.type
    local inv_def = inv_defs[lookup_key] or inv_defs.drops
    if not inv_def then return end
    TriggerClientEvent("rig:cl:add_container", target or -1, {
        id = self.identifier,
        type = self.subtype or self.type,
        coords = coords,
        prop = inv_def.prop,
    })
end

function Container:unload()
    self:save(true)
    return true
end

function Container:get_data(category)
    local priv = Private[self]
    if not priv then return {} end
    return category and priv.inventory[category] or priv.inventory
end

function Container:get_items()
    local priv = Private[self]
    if not priv then return {} end
    return priv.inventory.items
end

function Container:get_item(lookup, quantity, group_id)
    local priv = Private[self]
    if not priv then return nil, nil, nil end
    local items = priv.inventory.items or {}
    group_id = group_id or self.subtype
    local groups = resolve_groups(items, group_id)
    local req = quantity or 1
    local t = type(lookup)
    if t == "table" and lookup.col and lookup.row then
        return find_item_by_slot(groups, lookup.col, lookup.row, req)
    end
    if t == "string" then
        local col, row = lookup:match("^(%d+)_(%d+)$")
        if col and row then
            return find_item_by_slot(groups, tonumber(col), tonumber(row), req)
        end
        return find_item_by_id(groups, lookup, req)
    end
    if t == "table" then
        return find_item_by_metadata(groups, lookup, req)
    end
    return nil, nil, nil
end

function Container:get_total_item_quantity(id, group_id)
    local priv = Private[self]
    if not priv or not priv.inventory or not priv.inventory.items then return 0 end
    local total = 0
    local groups = group_id and { [group_id] = priv.inventory.items[group_id] } or priv.inventory.items
    for _, group_items in pairs(groups) do
        if type(group_items) == "table" then
            for _, item in pairs(group_items) do
                if type(item) == "table" and item.id == id then
                    total = total + (item.quantity or 1)
                end
            end
        end
    end
    return total
end

function Container:has_item(lookup, quantity, group_id)
    return self:get_item(lookup, quantity, group_id) ~= nil
end

function Container:add_item(id, quantity, metadata, group_id, col, row)
    local priv = Private[self]
    if not priv then return false, "container_private_missing" end
    quantity = quantity or 1
    metadata = metadata or {}
    group_id = group_id or self.subtype

    local is_vehicle, vehicle_config = get_vehicle_group_config(group_id, self)
    local group_def = is_vehicle and vehicle_config or inv_defs[group_id]
    if not group_def or (not is_vehicle and not group_def.is_container) then
        return false, "invalid_group"
    end

    local item_def = item_defs[id]
    if not item_def then
        return false, "invalid_item_id"
    end

    priv.inventory.items = priv.inventory.items or {}
    priv.inventory.items[group_id] = priv.inventory.items[group_id] or {}
    local group_items = priv.inventory.items[group_id]
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
        for _, item in pairs(group_items) do
            if item.id == id and metadata_equal(item.metadata or {}, final_metadata) then
                local can_add = max_stack - (item.quantity or 1)
                if can_add > 0 then
                    local add = math.min(can_add, remaining)
                    item.quantity = (item.quantity or 1) + add
                    remaining = remaining - add
                    if remaining <= 0 then
                        self:mark_dirty()
                        return true, "item_added_success"
                    end
                end
            end
        end
    end
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
    if remaining < quantity then
        self:mark_dirty()
        return true, "item_added_success"
    end
    return false, "no_free_slot"
end

function Container:remove_item(lookup, quantity, group_id)
    local priv = Private[self]
    if not priv then return false, "container_private_missing" end
    quantity = quantity or 1
    if type(quantity) ~= "number" or quantity <= 0 then return false, "item_invalid_amount" end
    local item, key, found_group = self:get_item(lookup, quantity, group_id)
    if not item then return false, "item_not_found" end
    local group_items = priv.inventory.items[found_group]
    local current = item.quantity or 1
    if current > quantity then
        item.quantity = current - quantity
    else
        group_items[key] = nil
    end
    self:mark_dirty()
    return true, "item_removed_success"
end

function Container:move_item(from_col, from_row, to_col, to_row, from_group, to_group)
    local priv = Private[self]
    if not priv then return false, "container_private_missing" end
    from_group = from_group or self.subtype
    to_group = to_group or from_group
    local from_key = from_col .. "_" .. from_row
    local to_key = to_col .. "_" .. to_row
    if from_key == to_key and from_group == to_group then return false, "item_move_same_slot" end
    local items = priv.inventory.items
    local from_items = items[from_group]
    local to_items = items[to_group] or {}
    if not from_items or not from_items[from_key] then return false, "item_move_source_empty" end
    local source = from_items[from_key]
    local dest = to_items[to_key]
    if not dest then
        to_items[to_key] = { id = source.id, quantity = source.quantity, metadata = source.metadata, col = to_col, row = to_row, w = source.w, h = source.h }
        from_items[from_key] = nil
    elseif dest.id == source.id and metadata_equal(source.metadata or {}, dest.metadata or {}) then
        dest.quantity = (dest.quantity or 1) + (source.quantity or 1)
        from_items[from_key] = nil
    else
        from_items[from_key] = { id = dest.id, quantity = dest.quantity, metadata = dest.metadata, col = from_col, row = from_row, w = dest.w, h = dest.h }
        to_items[to_key] = { id = source.id, quantity = source.quantity, metadata = source.metadata, col = to_col, row = to_row, w = source.w, h = source.h }
    end
    items[to_group] = to_items
    self:mark_dirty()
    return true, "item_moved_success"
end

return Container