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

--- @script src.server.extensions.inventory.modules.actions
--- @description Server-side inventory action handlers.

--- @section Imports

local item_defs = require("configs.items")
local inv_defs = require("configs.inventories")

--- @section Module

local actions = {}

--- @section Helpers

local function resolve_group(section)
    if not section then return nil end
    return section:gsub("^left_", ""):gsub("^right_", ""):gsub("^center_", "")
end

local function is_player_group(group_id)
    local def = inv_defs[group_id]
    return def and def.is_player == true
end

local function parse_vehicle_group(group_id)
    local inv_type, plate = group_id:match("^vehicle:([^:]+):(.+)$")
    return inv_type ~= nil, inv_type, plate
end

local function sync_and_refresh(source, p, container)
    p:sync()
    TriggerClientEvent("rig:cl:inventory_changed", source, container and {
        id = container.identifier,
        items = container:get_items()
    } or nil)
end

--- @section Weapon Handlers

local function handle_weapon_use(source, col, row, item, def, group)
    local p = core.players:get(source)
    if not p then return false end
    local ped = GetPlayerPed(source)
    if not ped or not DoesEntityExist(ped) then return false end
    local inv_meta = p:run_method("get_inventory_metadata") or {}
    local equipped = inv_meta.equipped_weapon
    if equipped and equipped.col == col and equipped.row == row and equipped.group == group and equipped.id == item.id and item.metadata and equipped.serial == item.metadata.serial then
        RemoveAllPedWeapons(ped, true)
        inv_meta.equipped_weapon = nil
        p:run_method("set_inventory_metadata", inv_meta, false)
        sync_and_refresh(source, p)
        return true
    end
    RemoveAllPedWeapons(ped, true)
    item.metadata = item.metadata or {}
    if not item.metadata.serial or item.metadata.serial == "" then
        item.metadata.serial = ("%s_%s_%s"):format(item.id, source, os.time())
        p:run_method("set_item_metadata", { col = col, row = row }, { serial = item.metadata.serial }, true, group)
    end
    local weapon_hash = GetHashKey(item.id)
    local ammo = tonumber(item.metadata.ammo) or 0
    GiveWeaponToPed(ped, weapon_hash, ammo, false, true)
    SetPedAmmo(ped, weapon_hash, ammo)
    if type(item.metadata.attachments) == "table" then
        for _, attachment_id in ipairs(item.metadata.attachments) do
            local att_def = item_defs[attachment_id]
            if att_def and att_def.actions and att_def.actions.use and att_def.actions.use.attachments then
                for _, mod in ipairs(att_def.actions.use.attachments) do
                    if mod.weapon == item.id and mod.component then
                        GiveWeaponComponentToPed(ped, weapon_hash, GetHashKey(mod.component))
                    end
                end
            end
        end
    end
    inv_meta.equipped_weapon = { col = col, row = row, group = group, id = item.id, serial = item.metadata.serial }
    p:run_method("set_inventory_metadata", inv_meta, false)
    sync_and_refresh(source, p)
    return true
end

local function handle_ammo_use(source, col, row, item, def, group)
    local p = core.players:get(source)
    if not p then return false end
    local inv_meta = p:run_method("get_inventory_metadata") or {}
    local equipped = inv_meta.equipped_weapon
    if not equipped then return false end
    local ped = GetPlayerPed(source)
    if not ped or not DoesEntityExist(ped) then return false end
    local weapon_item = p:run_method("get_item", { col = equipped.col, row = equipped.row }, 1, equipped.group)
    if not weapon_item then return false end
    local weapon_def = item_defs[weapon_item.id]
    if not weapon_def then return false end
    local allowed_ammo = weapon_def.metadata and weapon_def.metadata.ammo_types or {}
    local valid = false
    for _, ammo_id in ipairs(allowed_ammo) do
        if ammo_id == item.id then valid = true break end
    end
    if not valid then return false end
    weapon_item.metadata = weapon_item.metadata or {}
    local current_ammo = tonumber(weapon_item.metadata.ammo) or 0
    local rounds_to_add = math.min(def.metadata and def.metadata.ammo_refill or 1, item.quantity or 1)
    local new_ammo = current_ammo + rounds_to_add
    weapon_item.metadata.ammo = new_ammo
    p:run_method("set_item_metadata", { col = equipped.col, row = equipped.row }, weapon_item.metadata, false, equipped.group)
    local weapon_hash = GetHashKey(weapon_item.id)
    SetPedAmmo(ped, weapon_hash, new_ammo)
    p:run_method("remove_item", { col = col, row = row }, rounds_to_add, group)
    sync_and_refresh(source, p)
    return true
end

local function handle_attachment_use(source, col, row, item, def, group)
    local p = core.players:get(source)
    if not p then return false end
    local inv_meta = p:run_method("get_inventory_metadata") or {}
    local equipped = inv_meta.equipped_weapon
    if not equipped then return false end
    local weapon_item = p:run_method("get_item", { col = equipped.col, row = equipped.row }, 1, equipped.group)
    if not weapon_item then return false end
    local component
    for _, mod in ipairs(def.actions.use.attachments or {}) do
        if mod.weapon == weapon_item.id then
            component = mod.component
            break
        end
    end
    if not component then return false end
    weapon_item.metadata = weapon_item.metadata or {}
    weapon_item.metadata.attachments = weapon_item.metadata.attachments or {}
    local ped = GetPlayerPed(source)
    local weapon_hash = GetHashKey(weapon_item.id)
    local component_hash = GetHashKey(component)
    for i = #weapon_item.metadata.attachments, 1, -1 do
        if weapon_item.metadata.attachments[i] == item.id then
            RemoveWeaponComponentFromPed(ped, weapon_hash, component_hash)
            table.remove(weapon_item.metadata.attachments, i)
            p:run_method("add_item", item.id, 1, nil, group)
            p:run_method("set_item_metadata", { col = equipped.col, row = equipped.row }, weapon_item.metadata, false, equipped.group)
            sync_and_refresh(source, p)
            return true
        end
    end
    GiveWeaponComponentToPed(ped, weapon_hash, component_hash)
    table.insert(weapon_item.metadata.attachments, item.id)
    p:run_method("remove_item", { col = col, row = row }, 1, group)
    p:run_method("set_item_metadata", { col = equipped.col, row = equipped.row }, weapon_item.metadata, false, equipped.group)
    sync_and_refresh(source, p)
    return true
end

--- @section Actions

function actions.drop_item(source, data)
    if not data or not data.col or not data.row or not data.group then
        return log("warn", "[drop_item] missing data")
    end

    local p = core.players:get(source)
    if not p then return log("error", "[drop_item] no player") end

    local item = p:run_method("get_item", { col = data.col, row = data.row }, 1, data.group)
    if not item then return log("info", "[drop_item] no item at position") end

    local def = item_defs[item.id]
    if not def or not def.actions or not def.actions.drop then
        return log("info", "[drop_item] item not droppable: " .. item.id)
    end

    local quantity = math.min(tonumber(data.quantity) or item.quantity or 1, item.quantity or 1)
    if quantity <= 0 then return log("warn", "[drop_item] zero quantity") end

    if def.category == "player_inventory" and item.metadata and item.metadata.equipped then
        actions.toggle_player_inventory(source, { col = data.col, row = data.row, group = data.group })
        item = p:run_method("get_item", { col = data.col, row = data.row }, 1, data.group)
        if not item then return log("error", "[drop_item] item lost after unequip") end
    end

    local model = type(def.actions.drop) == "table" and def.actions.drop.model or def.model or def.prop or "prop_paper_bag_small"

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return log("error", "[drop_item] no ped") end

    local removed = p:run_method("remove_item", { col = data.col, row = data.row }, quantity, data.group)
    if not removed then return log("error", "[drop_item] remove failed") end

    local coords = GetEntityCoords(ped)
    local drop_id = core.drops:add({
        item_id = item.id,
        label = def.label,
        description = def.description,
        image = def.image or item.id,
        category = def.category,
        weight = def.weight,
        w = def.w or 1,
        h = def.h or 1,
        model = model,
        quantity = quantity,
        metadata = item.metadata,
        coords = { x = coords.x, y = coords.y, z = coords.z - 1.0 }
    })

    sync_and_refresh(source, p)
    log("success", ("[drop_item] src:%s dropped %s x%d drop_id:%d"):format(source, item.id, quantity, drop_id))
end

function actions.pickup_drop(source, drop_id)
    if not drop_id then return log("warn", "[pickup_drop] no drop_id") end

    local p = core.players:get(source)
    if not p then return log("error", "[pickup_drop] no player") end

    local drop = core.drops:get(drop_id)
    if not drop then return log("warn", "[pickup_drop] drop missing: " .. tostring(drop_id)) end

    if not core.drops:lock(drop_id) then
        return log("warn", "[pickup_drop] drop already locked: " .. tostring(drop_id))
    end

    local success = p:run_method("add_item", drop.item_id, drop.quantity, drop.metadata)
    if not success then
        core.drops:unlock(drop_id)
        return log("warn", "[pickup_drop] add_item failed for: " .. drop.item_id)
    end

    core.drops:remove(drop_id)
    sync_and_refresh(source, p)
    log("success", ("[pickup_drop] src:%s picked up %s x%d"):format(source, drop.item_id, drop.quantity))
end

function actions.move_item(source, move_data)
    if not move_data then return log("error", "[move_item] no data") end

    local from_col = tonumber(move_data.from_col)
    local from_row = tonumber(move_data.from_row)
    local to_col = tonumber(move_data.to_col)
    local to_row = tonumber(move_data.to_row)
    local from_group = resolve_group(move_data.from_section or move_data.from_group)
    local to_group = resolve_group(move_data.to_section or move_data.to_group)

    if not from_col or not from_row or not to_col or not to_row or not from_group or not to_group then
        return log("error", ("[move_item] incomplete data: %s"):format(json.encode(move_data)))
    end

    log("debug", ("[move_item] src:%s | from:%s_%s(%s) -> to:%s_%s(%s)"):format(source, from_col, from_row, from_group, to_col, to_row, to_group))

    local p = core.players:get(source)
    if not p then return log("error", "[move_item] no player") end

    local from_is_vehicle, from_inv_type, from_plate = parse_vehicle_group(from_group)
    local to_is_vehicle, to_inv_type, to_plate = parse_vehicle_group(to_group)

    if to_group == "vicinity" then
        actions.drop_item(source, { col = from_col, row = from_row, group = from_group })
        return
    end

    if from_group == "vicinity" then
        local drop_id = move_data.dataset and tonumber(move_data.dataset.drop_id)
        if drop_id then actions.pickup_drop(source, drop_id) end
        return
    end

    if from_is_vehicle or to_is_vehicle then

        if not from_is_vehicle and to_is_vehicle then
            local container = core.containers:get(("vehicle:%s:%s"):format(to_inv_type, to_plate))
            if not container then
                container = core.containers:get_or_create_vehicle(to_plate, to_inv_type)
            end
            if not container then return log("error", "[move_item] vehicle container missing: " .. to_plate) end

            local item = p:run_method("get_item", { col = from_col, row = from_row }, 1, from_group)
            if not item then return log("warn", "[move_item] player item missing") end

            local amount = item.quantity or 1
            local success, msg = container:add_item(item.id, amount, item.metadata, to_group, to_col, to_row)
            if success then
                local removed, remove_msg = p:run_method("remove_item", { col = from_col, row = from_row }, amount, from_group)
                if removed then
                    container:save()
                    sync_and_refresh(source, p, container)
                    log("success", "[move_item] player -> vehicle")
                else
                    container:remove_item({ col = to_col, row = to_row }, amount, to_group)
                    log("error", "[move_item] rollback player remove: " .. tostring(remove_msg))
                end
            else
                log("warn", "[move_item] vehicle add_item failed: " .. tostring(msg))
            end
            return
        end

        if from_is_vehicle and not to_is_vehicle then
            local container = core.containers:get(("vehicle:%s:%s"):format(from_inv_type, from_plate))
            if not container then return log("error", "[move_item] vehicle container missing: " .. from_plate) end

            local item = container:get_item({ col = from_col, row = from_row })
            if not item then return log("warn", "[move_item] vehicle item missing") end

            local amount = item.quantity or 1
            local success, msg = p:run_method("add_item", item.id, amount, item.metadata, to_group, to_col, to_row)
            if success then
                local removed, remove_msg = container:remove_item({ col = from_col, row = from_row }, amount, from_group)
                if removed then
                    container:save()
                    sync_and_refresh(source, p, container)
                    log("success", "[move_item] vehicle -> player")
                else
                    p:run_method("remove_item", { col = to_col, row = to_row }, amount, to_group)
                    log("error", "[move_item] rollback vehicle remove: " .. tostring(remove_msg))
                end
            else
                log("warn", "[move_item] player add_item failed: " .. tostring(msg))
            end
            return
        end

        if from_is_vehicle and to_is_vehicle and from_plate == to_plate then
            local container = core.containers:get(("vehicle:%s:%s"):format(from_inv_type, from_plate))
            if not container then return log("error", "[move_item] vehicle container missing") end

            local success, msg = container:move_item(
                { col = from_col, row = from_row },
                { col = to_col, row = to_row },
                from_group, to_group
            )
            if success then
                container:save()
                sync_and_refresh(source, p, container)
                log("success", "[move_item] vehicle internal move")
            else
                log("warn", "[move_item] vehicle move failed: " .. tostring(msg))
            end
            return
        end
    end

    local from_is_player = is_player_group(from_group)
    local to_is_player = is_player_group(to_group)

    if from_is_player and to_is_player then
        local success, msg = p:run_method("move_item", from_col, from_row, to_col, to_row, from_group, to_group)
        if success then
            sync_and_refresh(source, p)
            log("success", "[move_item] player -> player ok")
        else
            log("warn", "[move_item] player move failed: " .. tostring(msg))
        end
        return
    end

    local container_id = core.containers:get_locked_by_player(source)
    if not container_id then return log("error", "[move_item] no locked container for player") end

    local container = core.containers:get(container_id)
    if not container then return log("error", "[move_item] container missing: " .. container_id) end

    if from_is_player and not to_is_player then
        local item = p:run_method("get_item", { col = from_col, row = from_row }, 1, from_group)
        if not item then return log("warn", "[move_item] player item missing") end

        local amount = item.quantity or 1
        local success, msg = container:add_item(item.id, amount, item.metadata, to_group, to_col, to_row)
        if success then
            local removed, remove_msg = p:run_method("remove_item", { col = from_col, row = from_row }, amount, from_group)
            if removed then
                container:save()
                sync_and_refresh(source, p, container)
                log("success", "[move_item] player -> container: " .. container_id)
            else
                container:remove_item({ col = to_col, row = to_row }, amount, to_group)
                log("error", "[move_item] rollback player remove: " .. tostring(remove_msg))
            end
        else
            log("warn", "[move_item] container add_item failed: " .. tostring(msg))
        end
        return
    end

    if not from_is_player and to_is_player then
        local item = container:get_item({ col = from_col, row = from_row })
        if not item then return log("warn", "[move_item] container item missing") end

        local amount = item.quantity or 1
        local success, msg = p:run_method("add_item", item.id, amount, item.metadata, to_group, to_col, to_row)
        if success then
            local removed, remove_msg = container:remove_item({ col = from_col, row = from_row }, amount, from_group)
            if removed then
                container:save()
                sync_and_refresh(source, p, container)
                log("success", "[move_item] container -> player: " .. container_id)
            else
                p:run_method("remove_item", { col = to_col, row = to_row }, amount, to_group)
                log("error", "[move_item] rollback container remove: " .. tostring(remove_msg))
            end
        else
            log("warn", "[move_item] player add_item failed: " .. tostring(msg))
        end
        return
    end

    if not from_is_player and not to_is_player then
        local success, msg = container:move_item(
            { col = from_col, row = from_row },
            { col = to_col, row = to_row },
            from_group, to_group
        )
        if success then
            container:save()
            sync_and_refresh(source, p, container)
            log("success", "[move_item] container internal move")
        else
            log("warn", "[move_item] container move failed: " .. tostring(msg))
        end
        return
    end

    log("error", "[move_item] unhandled move case")
end

function actions.split_item(source, data)
    if not data or not data.col or not data.row or not data.group or not data.quantity then
        return log("error", "[split_item] missing data")
    end

    local p = core.players:get(source)
    if not p then return log("error", "[split_item] no player") end

    local inv_def = inv_defs[data.group]
    if not inv_def or (not inv_def.is_player and not inv_def.is_container) then
        return log("warn", "[split_item] bad inventory group: " .. tostring(data.group))
    end

    local item = p:run_method("get_item", { col = data.col, row = data.row }, 1, data.group)
    if not item then return log("warn", "[split_item] no item at position") end

    local current_qty = item.quantity or 1
    local split_amount = tonumber(data.quantity)

    if not split_amount or split_amount <= 0 or split_amount >= current_qty then
        return log("warn", ("[split_item] bad amount: %s / %d"):format(tostring(split_amount), current_qty))
    end

    local def = item_defs[item.id]
    if not def then return log("error", "[split_item] no item def: " .. item.id) end

    local stackable = def.stackable
    if stackable == nil then stackable = true end
    if not stackable then return log("warn", "[split_item] not stackable: " .. item.id) end

    local removed = p:run_method("remove_item", { col = data.col, row = data.row }, split_amount, data.group)
    if not removed then return log("error", "[split_item] remove failed") end

    local success = p:run_method("add_item", item.id, split_amount, item.metadata, data.group)
    if not success then
        p:run_method("add_item", item.id, split_amount, item.metadata, data.group, data.col, data.row)
        return log("error", "[split_item] add failed, rolled back")
    end

    sync_and_refresh(source, p)
    log("success", ("[split_item] src:%s split %d from %s_%s"):format(source, split_amount, data.col, data.row))
end

function actions.use_item(source, data)
    if not source or not data then return log("error", "[use_item] invalid params") end

    local p = core.players:get(source)
    if not p then return log("error", "[use_item] no player") end

    local col, row, group

    if type(data) == "table" then
        col = data.col
        row = data.row
        group = data.group
    end

    if not col or not row then return log("warn", "[use_item] col/row required") end

    local item = p:run_method("get_item", { col = col, row = row }, 1, group)
    if not item then return log("warn", "[use_item] no item at position") end

    local def = item_defs[item.id]
    if not def then return log("error", "[use_item] no definition: " .. item.id) end

    local category = def.category or "general"

    if category == "weapon" then return handle_weapon_use(source, col, row, item, def, group) end
    if category == "ammo" then return handle_ammo_use(source, col, row, item, def, group) end
    if category == "attachments" then return handle_attachment_use(source, col, row, item, def, group) end

    if category == "player_inventory" then
        local use_config = def.actions and def.actions.use
        if use_config and use_config.animation then
            TriggerClientEvent("rig:cl:use_item_animation", source, {
                animation = use_config.animation,
                col = col, row = row, group = group, item_id = item.id
            })
            return true
        end
        return false
    end

    if not core.is_usable(item.id) then return log("info", "[use_item] item not usable: " .. item.id) end

    local use_data = core.get_usable_item(item.id)
    if not use_data then return log("error", "[use_item] no use data: " .. item.id) end

    if type(use_data) == "function" then
        return use_data(source, col, row, item.id, def, group)
    end

    if type(use_data) == "table" and use_data.animation then
        TriggerClientEvent("rig:cl:use_item_animation", source, {
            animation = use_data.animation,
            col = col, row = row, group = group, item_id = item.id
        })
        return true
    end

    log("warn", "[use_item] invalid use data type: " .. item.id)
end

function actions.toggle_player_inventory(source, data)
    local p = core.players:get(source)
    if not p then return log("error", "[toggle_player_inventory] no player") end

    local item = p:run_method("get_item", { col = data.col, row = data.row }, 1, data.group)
    if not item then
        pluck.notify(source, { type = "error", header = "Inventory", message = "Item not found", duration = 3000 })
        return log("warn", "[toggle_player_inventory] no item")
    end

    local def = item_defs[item.id]
    if not def or not def.actions or not def.actions.use then
        pluck.notify(source, { type = "error", header = "Inventory", message = "This item cannot be used", duration = 3000 })
        return log("error", "[toggle_player_inventory] no definition: " .. item.id)
    end

    local use_config = def.actions.use
    local inventory_group = use_config.inventory_group
    local loadout_slot = use_config.loadout_slot

    local inv_meta = p:run_method("get_inventory_metadata") or {}
    inv_meta.equipped_inventories = inv_meta.equipped_inventories or {}
    inv_meta.loadout = inv_meta.loadout or {}

    local is_equipped = item.metadata and item.metadata.equipped == true

    if is_equipped then
        -- Remove from loadout metadata
        if loadout_slot then
            inv_meta.loadout[loadout_slot] = nil
        end

        -- Remove temporary inventory group and store contents back on item
        if inventory_group then
            local group_contents = p:run_method("remove_temporary_inventory_group", inventory_group)
            item.metadata.stored_items = group_contents
        end

        item.metadata.equipped = false

        for i, equipped_inv in ipairs(inv_meta.equipped_inventories) do
            if equipped_inv.group == (inventory_group or loadout_slot) and equipped_inv.serial == item.metadata.serial then
                table.remove(inv_meta.equipped_inventories, i)
                break
            end
        end

        -- Return item to source group
        p:run_method("add_item", item.id, 1, item.metadata, data.group)

        TriggerClientEvent("rig:cl:apply_inventory_clothing", source, { action = "remove", clothing = use_config.clothing, prop = use_config.prop })
        p:run_method("set_inventory_metadata", inv_meta, false)
        sync_and_refresh(source, p)
        pluck.notify(source, { type = "success", header = "Inventory", message = ("Unequipped %s"):format(def.label), duration = 4000 })
        log("success", ("[toggle_player_inventory] unequipped %s from slot %s"):format(item.id, loadout_slot or inventory_group))
    else
        -- Check for duplicate equipped inventory type
        for _, equipped_inv in ipairs(inv_meta.equipped_inventories) do
            local other_item = p:run_method("get_item", { col = equipped_inv.col, row = equipped_inv.row }, 1, equipped_inv.source_group)
            if other_item and other_item.metadata and other_item.metadata.serial ~= (item.metadata and item.metadata.serial or "") then
                pluck.notify(source, { type = "error", header = "Inventory", message = "You already have one equipped!", duration = 4000 })
                return log("warn", "[toggle_player_inventory] already equipped for src: " .. source)
            end
        end

        -- Check loadout slot isn't already occupied
        if loadout_slot and inv_meta.loadout[loadout_slot] then
            pluck.notify(source, { type = "error", header = "Inventory", message = "That slot is already occupied!", duration = 4000 })
            return log("warn", "[toggle_player_inventory] loadout slot occupied: " .. loadout_slot)
        end

        item.metadata = item.metadata or {}
        if not item.metadata.serial or item.metadata.serial == "" then
            item.metadata.serial = ("%s_%s_%s"):format(item.id, source, os.time())
        end

        item.metadata.equipped = true
        local stored_items = item.metadata.stored_items or {}

        -- Remove item from source inventory
        local removed = p:run_method("remove_item", { col = data.col, row = data.row }, 1, data.group)
        if not removed then
            pluck.notify(source, { type = "error", header = "Inventory", message = "Failed to equip item", duration = 3000 })
            return log("error", "[toggle_player_inventory] failed to remove item from source")
        end

        -- Add temporary inventory group if needed
        if inventory_group then
            local success, msg = p:run_method("add_temporary_inventory_group", inventory_group, stored_items)
            if not success then
                -- Rollback
                p:run_method("add_item", item.id, 1, item.metadata, data.group)
                pluck.notify(source, { type = "error", header = "Inventory", message = msg or "Failed to add inventory", duration = 3000 })
                return
            end
        end

        -- Store in loadout metadata
        if loadout_slot then
            inv_meta.loadout[loadout_slot] = {
                id = item.id,
                label = def.label,
                image = def.image,
                category = def.category,
                metadata = item.metadata,
                serial = item.metadata.serial,
                source_group = data.group,
                inventory_group = inventory_group
            }
        end

        table.insert(inv_meta.equipped_inventories, {
            group = inventory_group or loadout_slot,
            serial = item.metadata.serial,
            col = data.col,
            row = data.row,
            source_group = data.group,
            item_id = item.id
        })

        TriggerClientEvent("rig:cl:apply_inventory_clothing", source, { action = "equip", clothing = use_config.clothing, prop = use_config.prop })
        p:run_method("set_inventory_metadata", inv_meta, false)
        sync_and_refresh(source, p)
        pluck.notify(source, { type = "success", header = "Inventory", message = ("Equipped %s"):format(def.label), duration = 4000 })
        log("success", ("[toggle_player_inventory] equipped %s to slot %s"):format(item.id, loadout_slot or inventory_group))
    end
end

-- Add to actions module
function actions.unequip_loadout_item(source, data)
    if not data or not data.slot_id then return log("error", "[unequip_loadout_item] missing slot_id") end

    local p = core.players:get(source)
    if not p then return log("error", "[unequip_loadout_item] no player") end

    local inv_meta = p:run_method("get_inventory_metadata") or {}
    inv_meta.loadout = inv_meta.loadout or {}

    local slot_entry = inv_meta.loadout[data.slot_id]
    if not slot_entry then return log("warn", "[unequip_loadout_item] slot empty: " .. data.slot_id) end

    local def = item_defs[slot_entry.id]
    if not def then return log("error", "[unequip_loadout_item] no item def: " .. slot_entry.id) end

    local use_config = def.actions and def.actions.use

    -- Remove temporary inventory group and store contents back on item metadata
    if slot_entry.inventory_group then
        local group_contents = p:run_method("remove_temporary_inventory_group", slot_entry.inventory_group)
        slot_entry.metadata = slot_entry.metadata or {}
        slot_entry.metadata.stored_items = group_contents
    end

    slot_entry.metadata = slot_entry.metadata or {}
    slot_entry.metadata.equipped = false

    -- Remove from equipped_inventories
    inv_meta.equipped_inventories = inv_meta.equipped_inventories or {}
    for i, equipped_inv in ipairs(inv_meta.equipped_inventories) do
        if equipped_inv.serial == slot_entry.serial then
            table.remove(inv_meta.equipped_inventories, i)
            break
        end
    end

    -- Remove from loadout
    inv_meta.loadout[data.slot_id] = nil

    -- Return item to pockets (or source group)
    local target_group = slot_entry.source_group or "pockets"
    local success, msg = p:run_method("add_item", slot_entry.id, 1, slot_entry.metadata, target_group)
    if not success then
        log("error", "[unequip_loadout_item] failed to return item to " .. target_group .. ": " .. tostring(msg))
        return
    end

    if use_config then
        TriggerClientEvent("rig:cl:apply_inventory_clothing", source, { action = "remove", clothing = use_config.clothing, prop = use_config.prop })
    end

    p:run_method("set_inventory_metadata", inv_meta, false)
    sync_and_refresh(source, p)
    pluck.notify(source, { type = "success", header = "Inventory", message = ("Unequipped %s"):format(def.label), duration = 4000 })
    log("success", ("[unequip_loadout_item] src:%s unequipped %s from %s"):format(source, slot_entry.id, data.slot_id))
end

function actions.animation_finished(source, data)
    if not data or not data.item_id or not data.col or not data.row then
        return log("error", "[animation_finished] missing data")
    end

    local def = item_defs[data.item_id]
    if not def then return log("warn", "[animation_finished] no item def: " .. data.item_id) end

    local use_data = core.get_usable_item(data.item_id)
    if not use_data or type(use_data) ~= "table" then return end

    local anim = use_data.animation
    if anim and anim.callback and type(anim.callback) == "function" then
        anim.callback(source, data)
    end
end

return actions