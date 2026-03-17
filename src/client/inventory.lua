--- @script src.client.inventory.actions
--- @description Handles client-side inventory actions and commands.

--- @section Imports

local animations = require("libs.graft.fivem.animations")
local utils = require("src.client.modules.utils")

--- @section State

local original_ped_coords = nil
local original_ped_heading = nil
local active_cam = nil

--- @section Camera

local camera_positions = {
    body = {
        offset = vector3(0.0, 1.65, 0.15),
        offset_behind = vector3(0.0, -1.65, 0.15),
        rotation = vector3(-5.0, 0.0, 180.0),
        rotation_behind = vector3(-5.0, 0.0, 0.0),
        fov = 70.0,
        near_dof = 0.7,
        far_dof = 1.9,
        dof_strength = 1.2
    },
    vehicle = {
        offset = vector3(0.0, -2.5, 0.5),
        rotation = vector3(-10.0, 0.0, 0.0),
        fov = 80.0,
        near_dof = 1.5,
        far_dof = 4.0,
        dof_strength = 1.0
    }
}

local function set_inventory_camera(position_key, cam_behind)
    local cam_config = camera_positions[position_key]
    if not cam_config then return end
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end
    local in_vehicle = IsPedInAnyVehicle(ped, false)
    local target_entity = in_vehicle and GetVehiclePedIsIn(ped, false) or ped
    if in_vehicle then cam_config = camera_positions.vehicle end
    local offset = cam_behind and (cam_config.offset_behind or cam_config.offset) or cam_config.offset
    local base_rotation = cam_behind and (cam_config.rotation_behind or cam_config.rotation) or cam_config.rotation
    local heading = GetEntityHeading(target_entity)
    local coords = GetOffsetFromEntityInWorldCoords(target_entity, offset.x, offset.y, offset.z)
    local rot = vector3(base_rotation.x, base_rotation.y, heading + base_rotation.z)
    local new_cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, cam_config.fov or 70.0, false, 0)
    if DoesCamExist(active_cam) then
        SetCamActiveWithInterp(new_cam, active_cam, 800, true, true)
        DestroyCam(active_cam, false)
    else
        SetCamActive(new_cam, true)
        RenderScriptCams(true, true, 800, true, true)
    end
    active_cam = new_cam
    SetCamUseShallowDofMode(active_cam, true)
    SetCamNearDof(active_cam, cam_config.near_dof or 0.5)
    SetCamFarDof(active_cam, cam_config.far_dof or 2.0)
    SetCamDofStrength(active_cam, cam_config.dof_strength or 1.0)
    CreateThread(function()
        while DoesCamExist(active_cam) do
            SetUseHiDof()
            Wait(0)
        end
    end)
end

local function destroy_inventory_camera()
    if DoesCamExist(active_cam) then
        DestroyCam(active_cam, false)
        RenderScriptCams(false, true, 800, true, true)
        active_cam = nil
    end
end

local function build_item_actions(def, col, row, entry, group)
    if not def or not def.actions then return nil end
    local inv_defs = core.get_static_data("inventories") or {}
    local group_def = inv_defs[group]
    if not group_def or not group_def.is_player then return nil end

    local quantity = tonumber(entry and entry.quantity) or 1
    local actions = {}

    if def.actions.use then
        actions[#actions + 1] = {
            id = "use",
            key = "G",
            label = locale("inventory.client.ui.use"),
            should_close = true,
            on_action = function(data)
                TriggerServerEvent("rig:sv:use_item", { col = data.dataset.col, row = data.dataset.row, group = data.dataset.group_id })
                TriggerServerEvent("rig:sv:close_inventory")
                inventory_open = false
            end
        }
    end

    local stackable = def.stackable
    if stackable == nil then stackable = true end

    if stackable ~= false and quantity > 1 then
        actions[#actions + 1] = {
            id = "split",
            key = "S",
            label = locale("inventory.client.ui.split_stack"),
            modal = {
                title = locale("inventory.client.ui.split_stack"),
                options = {
                    {
                        id = "quantity",
                        label = locale("inventory.client.ui.quantity"),
                        type = "number",
                        default = 1,
                        min = 1,
                        max = quantity - 1,
                        dataset = { col = col, row = row, group_id = group }
                    }
                },
                buttons = {
                    {
                        label = locale("inventory.client.ui.confirm"),
                        on_action = function(data)
                            local amt = tonumber(data.dataset.quantity)
                            local c = tonumber(data.dataset.col)
                            local r = tonumber(data.dataset.row)
                            local group_id = data.dataset.group_id
                            if amt and c and r and group_id then
                                TriggerServerEvent("rig:sv:split_item", { col = c, row = r, group = group_id, quantity = amt })
                            end
                        end
                    },
                    { label = locale("inventory.client.ui.cancel"), action = "close_modal" }
                }
            }
        }
    end
    return (#actions > 0) and actions or nil
end

local function build_header()
    local player_source = GetPlayerServerId(PlayerId())
    return {
        layout = {
            left = { justify = "flex-start" },
            center = { justify = "center" },
            right = { justify = "flex-end" }
        },
        elements = {
            left = {},
            center = { { type = "tabs" } },
            right = {
                {
                    type = "group",
                    items = {
                        { type = "text", subtitle = locale("inventory.client.ui.server_id", player_source) }
                    }
                }
            }
        }
    }
end

local function build_vicinity_items(drops, radius)
    local items = {}
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local col, row = 1, 1
    for _, drop in pairs(drops or {}) do
        local dcoords = vector3(drop.coords.x, drop.coords.y, drop.coords.z)
        if #(pcoords - dcoords) <= radius then
            local description = type(drop.description) == "string" and { drop.description } or drop.description
            local w = drop.w or 1
            local h = drop.h or 1
            items[#items + 1] = {
                id = drop.item_id,
                image = core.convars.image_path .. (drop.image or "default.png"),
                label = drop.label or drop.item_id,
                col = col,
                row = row,
                w = w,
                h = h,
                quantity = drop.quantity,
                category = drop.category,
                dataset = { drop_id = drop.id },
                on_hover = {
                    title = drop.label or drop.item_id,
                    description = description or {}
                }
            }
            col = col + w
            if col > 10 then col = 1 row = row + 1 end
        end
    end

    return items
end

local function build_vehicle_panel(plate, inv_type, config)
    if not plate or not config then return nil end
    local vehicle_group_id = ("vehicle:%s:%s"):format(inv_type, plate)
    local container = core.get_container(vehicle_group_id)
    local items = {}
    if container and container.items and container.items[vehicle_group_id] then
        items = core.build_items_for_grid(container.items[vehicle_group_id])
    end
    return {
        type = "grid",
        section_key = vehicle_group_id,
        title = {
            text = inv_type == "glovebox" and locale("inventory.client.ui.glovebox") or locale("inventory.client.ui.trunk"),
            span = ('<i class="fa-solid fa-car"></i> %s'):format(plate)
        },
        layout = { scroll_x = "none", scroll_y = "scroll", columns = config.columns or 10, rows = config.rows or 4, cell_size = "3vw" },
        items = items
    }
end

local function build_container_panel(container_id)
    local container = core.get_container(container_id)
    if not container then return nil end
    local inv_defs = core.get_static_data("inventories") or {}
    local subtype = container.subtype or container.type or "storage"
    local config = inv_defs[subtype] or {}
    local items = {}
    if container.items and container.items[subtype] then
        items = core.build_items_for_grid(container.items[subtype])
    end
    return {
        type = "grid",
        section_key = container_id,
        title = {
            text = config.label or subtype:gsub("^%l", string.upper),
            span = ('<i class="fa-solid fa-weight-hanging"></i> %d / %d g'):format(0, config.max_weight or 0)
        },
        layout = { scroll_x = "none", scroll_y = "scroll" },
        groups = {
            {
                id = subtype,
                layout = { columns = config.columns or 10, rows = config.rows or 6, cell_size = "3vw" },
                collapsible = false,
                items = items
            }
        }
    }
end

local function build_right()
    if core.vars.current_vehicle_data then
        local d = core.vars.current_vehicle_data
        return build_vehicle_panel(d.plate, d.type, d.config)
    end
    if core.vars.current_container then
        return build_container_panel(core.vars.current_container)
    end
    local vicinity_items = build_vicinity_items(core.client_drops, 2.5)
    return {
        type = "grid",
        section_key = "vicinity",
        title = {
            text = locale("inventory.client.ui.vicinity"),
            span = '<i class="fa-solid fa-location-dot"></i> ' .. locale("inventory.client.ui.ground")
        },
        layout = { scroll_x = "none", scroll_y = "scroll", columns = 10, rows = 20, cell_size = "3vw" },
        items = vicinity_items
    }
end

local function build_loadout_items(loadout)
    local item_defs = core.get_static_data("items") or {}
    local items = {}
    for slot_id, entry in pairs(loadout or {}) do
        local def = item_defs[entry.id]
        items[slot_id] = {
            id = entry.id,
            image = core.convars.image_path .. (entry.image or (def and def.image) or "default.png"),
            label = entry.label or (def and def.label) or entry.id,
            category = entry.category or (def and def.category),
            dataset = { slot_id = slot_id, serial = entry.serial },
            on_hover = {
                title = entry.label or (def and def.label) or entry.id,
                rarity = (entry.metadata and entry.metadata.rarity) or "common",
                actions = {
                    {
                        id = "unequip",
                        key = "G",
                        label = locale("inventory.client.ui.unequip"),
                        should_close = false,
                        on_action = function(data)
                            TriggerServerEvent("rig:sv:unequip_loadout_item", { slot_id = data.dataset.slot_id, serial = data.dataset.serial })
                        end
                    }
                }
            }
        }
    end
    return items
end

local function build_center(player_data)
    local loadout = player_data and player_data.metadata and player_data.metadata.loadout or {}
    local items = build_loadout_items(loadout)
    return {
        type = "slots",
        layout = { scroll_y = "none" },
        allow_cross_group_swap = true,
        groups = {
            {
                id = "loadout",
                layout_type = "positioned",
                collapsible = false,
                slots = {
                    { id = "helmet", label = locale("inventory.client.ui.slot.helmet"), position = { top = "2%", left = "20%" }, size = "80px" },
                    { id = "mask", label = locale("inventory.client.ui.slot.mask"), position = { top = "2%", right = "20%" }, size = "80px" },
                    { id = "backpack", label = locale("inventory.client.ui.slot.backpack"), position = { top = "22%", left = "5%" }, size = "80px" },
                    { id = "primary", label = locale("inventory.client.ui.slot.primary"), position = { top = "22%", right = "5%" }, size = "80px" },
                    { id = "vest", label = locale("inventory.client.ui.slot.vest"), position = { top = "42%", left = "5%" }, size = "80px" },
                    { id = "secondary", label = locale("inventory.client.ui.slot.secondary"), position = { top = "42%", right = "5%" }, size = "80px" },
                    { id = "shirt", label = locale("inventory.client.ui.slot.shirt"), position = { top = "62%", left = "5%" }, size = "80px" },
                    { id = "melee", label = locale("inventory.client.ui.slot.melee"), position = { top = "62%", right = "5%" }, size = "80px" },
                    { id = "pants", label = locale("inventory.client.ui.slot.pants"), position = { top = "82%", left = "20%" }, size = "80px" },
                    { id = "shoes", label = locale("inventory.client.ui.slot.shoes"), position = { top = "82%", right = "20%" }, size = "80px" },
                },
                items = items
            }
        }
    }
end

local function build_footer_buttons()
    local ped = PlayerPedId()
    local buttons = {}

    buttons[#buttons + 1] = {
        key = "ESCAPE",
        label = locale("inventory.client.ui.close"),
        should_close = true,
        on_action = function()
            if core.vars.current_vehicle and DoesEntityExist(core.vars.current_vehicle) then
                core.set_vehicle_trunk_state(core.vars.current_vehicle, core.vars.current_inv_type, false)
                core.vars.current_vehicle = nil
                core.vars.current_inv_type = nil
            end

            if not IsPedInAnyVehicle(ped, false) then
                FreezeEntityPosition(ped, false)
            end

            TriggerServerEvent("rig:sv:close_inventory")
            inventory_open = false
        end
    }

    return buttons
end

local function build_footer()
    return {
        layout = {
            left = { justify = "flex-start" },
            center = { justify = "center" },
            right = { justify = "flex-end" }
        },
        elements = {
            right = { { type = "actions", actions = build_footer_buttons() } }
        }
    }
end

local function build_player_groups(player_data)
    local inv_defs = core.get_static_data("inventories") or {}
    local item_defs = core.get_static_data("items") or {}
    local groups = {}
    for group_id, raw_items in pairs(player_data.items or {}) do
        local def = inv_defs[group_id]
        if def and def.is_player then
            local weight = utils.calculate_group_weight(raw_items, item_defs)
            groups[#groups + 1] = {
                id = group_id,
                title = def.label,
                span = def.icon and ('<i class="%s"></i>'):format(def.icon) or nil,
                layout = { columns = def.columns or 10, rows = def.rows or 4, cell_size = "3vw" },
                collapsible = def.collapsible or false,
                collapsed = def.collapsed or false,
                items = core.build_items_for_grid(raw_items, item_defs, group_id)
            }
        end
    end
    return groups
end

local function resolve_meta_value(meta_def, meta_value)
    if not meta_def.display then return nil end
    if type(meta_value) == "table" and not meta_def.values then return nil end

    if meta_def.values then
        if type(meta_value) == "table" then
            local labels = {}
            for _, v in ipairs(meta_value) do
                local mapped = meta_def.values[tostring(v)]
                labels[#labels + 1] = mapped and mapped.label or tostring(v)
            end
            return #labels > 0 and table.concat(labels, ", ") or nil
        end
        local mapped = meta_def.values[tostring(meta_value)]
        return mapped and mapped.label or tostring(meta_value)
    end

    return tostring(meta_value) .. (meta_def.suffix or "")
end

--- @section API

function core.build_items_for_grid(raw_items, item_defs, group_id)
    item_defs = item_defs or core.get_static_data("items") or {}
    local metadata_defs = core.get_static_data("metadata") or {}
    local items = {}

    for _, entry in pairs(raw_items or {}) do
        local def = item_defs[entry.id]
        if def then
            local values = {}
            local progress = nil

            for meta_key, meta_value in pairs(entry.metadata or {}) do
                local meta_def = metadata_defs[meta_key]
                if meta_def then
                    if meta_key == "durability" then progress = { value = meta_value } end
                    local display = resolve_meta_value(meta_def, meta_value)
                    if display then values[#values + 1] = { key = meta_def.label, value = display } end
                end
            end

            local description = type(def.description) == "string" and { def.description } or def.description

            items[#items + 1] = {
                id = entry.id,
                image = core.convars.image_path .. (def.image or "default.png"),
                label = def.label,
                col = entry.col,
                row = entry.row,
                w = entry.w or def.w or 1,
                h = entry.h or def.h or 1,
                quantity = entry.quantity or 1,
                category = def.category,
                progress = progress,
                dataset = { col = entry.col, row = entry.row, group_id = group_id },
                on_hover = {
                    title = def.label or entry.id,
                    description = description or {},
                    values = (#values > 0) and values or nil,
                    rarity = (entry.metadata and entry.metadata.rarity) or (def.metadata and def.metadata.rarity) or "common",
                    actions = build_item_actions(def, entry.col, entry.row, entry, group_id)
                }
            }
        end
    end

    return items
end

function core.build_inventory(player_data)
    local inv_defs = core.get_static_data("inventories") or {}
    local groups = build_player_groups(player_data)
    local header = build_header()

    header.elements.left = {
        {
            type = "group",
            items = {
                { type = "logo", image = pluck.get_player_headshot() },
                { type = "text", title = player_data.name, subtitle = player_data.unique_id }
            }
        }
    }

    pluck.build_ui({
        header = header,
        footer = build_footer(),
        content = {
            pages = {
                inventory_page = {
                    index = 1,
                    title = "Inventory",
                    layout = { left = 4, center = 4, right = 4 },
                    left = {
                        type = "grid",
                        title = { text = locale("inventory.client.ui.equipment") },
                        layout = { scroll_x = "none", scroll_y = "scroll" },
                        groups = groups
                    },
                    center = build_center(player_data),
                    right = build_right()
                }
            }
        }
    })
end

local inventory_open = false

function core.is_inventory_open()
    return inventory_open
end

--- @section Events

RegisterNetEvent("rig:cl:use_item_animation")
AddEventHandler("rig:cl:use_item_animation", function(data)
    if not data or not data.animation then
        log("error", locale("inventory.anim_missing"))
        return
    end
    local ped = PlayerPedId()
    local anim = data.animation
    if anim.progress then
        pluck.show_progressbar({
            header = anim.progress.message or "Using item...",
            duration = (anim.duration or 5000)
        })
    end
    animations.play(ped, anim, function()
        TriggerServerEvent("rig:sv:animation_finished", {
            item_id = data.item_id,
            col = data.col,
            row = data.row,
            group = data.group
        })
    end)
end)

RegisterNetEvent("rig:cl:open_inventory")
AddEventHandler("rig:cl:open_inventory", function(payload)
    if type(payload) ~= "table" then return end
    inventory_open = true

    if payload.secondary then
        core.vars.current_container = payload.secondary.id
        core.vars.current_inv_type = payload.secondary.type

        if payload.is_vehicle then
            core.vars.current_vehicle = payload.secondary.vehicle
            core.vars.current_vehicle_data = {
                plate = payload.secondary.plate,
                type = payload.secondary.type,
                config = payload.secondary.config
            }
            core.add_vehicle_container(payload.secondary)
            utils.set_vehicle_trunk_state(payload.secondary.vehicle, payload.secondary.type, true)
        else
            core.vars.current_vehicle = nil
            core.vars.current_vehicle_data = nil
            core.add_container(payload.secondary)
        end
    end

    set_inventory_camera("body", payload.secondary ~= nil)
    core.build_inventory(payload.player_data)
end)

RegisterNetEvent("rig:cl:apply_inventory_clothing")
AddEventHandler("rig:cl:apply_inventory_clothing", function(data)
    local ped = PlayerPedId()
    if data.action == "equip" then
        if data.clothing then
            local model = GetEntityModel(ped)
            local is_male = model == GetHashKey("mp_m_freemode_01")
            local clothing = data.clothing
            local drawable = is_male and clothing.male and clothing.male.drawable or clothing.drawable
            local texture = is_male and clothing.male and clothing.male.texture or clothing.texture
            SetPedComponentVariation(ped, clothing.component_id, drawable, texture, 0)
        end
        if data.prop then
            SetPedPropIndex(ped, data.prop.component_id, data.prop.drawable, data.prop.texture, true)
        end

    elseif data.action == "remove" then
        if data.clothing then
            SetPedComponentVariation(ped, data.clothing.component_id, 0, 0, 0)
        end
        if data.prop then
            ClearPedProp(ped, data.prop.component_id)
        end
    end
end)

RegisterNetEvent("rig:cl:close_inventory")
AddEventHandler("rig:cl:close_inventory", function()
    core.vars.current_container = nil
    core.vars.current_inv_type = nil
    core.vars.current_vehicle = nil
    core.vars.current_vehicle_data = nil
    destroy_inventory_camera()
    pluck.close_ui()
    FreezeEntityPosition(PlayerPedId(), false)
end)

RegisterNetEvent("rig:cl:inventory_changed")
AddEventHandler("rig:cl:inventory_changed", function(container_data)
    if not core.is_inventory_open() then  return  end
    local player_data = core.get_player_data("inventory")
    if not player_data or not player_data.items then return end
    local item_defs = core.get_static_data("items") or {}
    for group_id, raw_items in pairs(player_data.items) do
        local built = core.build_items_for_grid(raw_items, item_defs, group_id)
        pluck.update_grid(built, "left_" .. group_id)
    end

    local loadout = player_data.metadata and player_data.metadata.loadout or {}
    pluck.update_slots({ loadout = build_loadout_items(loadout) }, "center")

    if container_data and container_data.id and container_data.items then
        local subtype = core.vars.current_inv_type or "trunk"
        local raw = container_data.items[container_data.id] or container_data.items[subtype] or {}
        local built = core.build_items_for_grid(raw, item_defs, subtype)
        local section_key = core.vars.current_vehicle_data and ("vehicle:%s:%s"):format(subtype, core.vars.current_vehicle_data.plate) or container_data.id
        pluck.update_grid(built, section_key)
    else
        local vicinity_items = build_vicinity_items(core.client_drops, 2.5)
        pluck.update_grid(vicinity_items, "vicinity")
    end
end)

--- @section Commands

RegisterCommand("inv:open", function()
    if IsNuiFocused() or IsPauseMenuActive() then return end
    local player_data = core.get_player_data("inventory")
    if not player_data or not player_data.items then
        pluck.notify({ 
            type = "warning", 
            header = "Inventory", 
            message = "Missing player data, contact an admin.", 
            duration = 5000 
        })
        return
    end
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        if IsPedWalking(ped) or IsPedRunning(ped) or IsPedSprinting(ped) then
            ClearPedTasksImmediately(ped)
        end
        FreezeEntityPosition(ped, true)
    end
    local coords = GetEntityCoords(ped)
    original_ped_coords = { x = coords.x, y = coords.y, z = coords.z }
    original_ped_heading = GetEntityHeading(ped)
    TriggerServerEvent("rig:sv:open_inventory")
end, false)

RegisterKeyMapping("inv:open", "Open Inventory", "keyboard", core.convars.inventory_open_key)

--[[
-- @todo some sort of setup for hot keys? maybe modal to asign to a key?
for i = 1, 6 do
    RegisterCommand("inv:hotkey_" .. i, function()
        if IsNuiFocused() or IsPauseMenuActive() then return end
        TriggerServerEvent("rig:sv:use_hotkey", i)
    end, false)
    RegisterKeyMapping("inv:hotkey_" .. i, "Hotkey Slot " .. i, "keyboard", tostring(i))
end
]]

--- @section Cleanup

AddEventHandler("onResourceStop", function(resource)
    if GetCurrentResourceName() ~= resource then return end
    if core.vars.current_vehicle and DoesEntityExist(core.vars.current_vehicle) then
        core.set_vehicle_trunk_state(core.vars.current_vehicle, core.vars.current_inv_type, false)
    end
end)