

local utils = {}
--- @section Inventory

local VEHICLE_CLASSES = {
    [0] = "compact", [1] = "sedan", [2] = "suv", [3] = "coupe",
    [4] = "muscle", [5] = "sports", [6] = "super", [7] = "motorcycle",
    [8] = "offroad", [9] = "industrial", [10] = "utility", [11] = "van",
    [12] = "cycle", [13] = "boat", [14] = "helicopter", [15] = "plane",
    [16] = "service", [17] = "emergency", [18] = "military",
    [19] = "commercial", [20] = "train"
}

function utils.get_vehicle_class_name(class_id)
    return VEHICLE_CLASSES[class_id] or "sedan"
end

function utils.get_vehicle_config(vehicle)
    if not DoesEntityExist(vehicle) then return nil, nil end
    local vehicle_data = core.get_static_data("inventories")
    local model_name = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    local class_name = utils.get_vehicle_class_name(GetVehicleClass(vehicle))
    if vehicle_data[model_name] then
        return vehicle_data[model_name].trunk, vehicle_data[model_name].glovebox
    end
    if vehicle_data.vehicle_defaults and vehicle_data.vehicle_defaults[class_name] then
        return vehicle_data.vehicle_defaults[class_name].trunk, vehicle_data.vehicle_defaults[class_name].glovebox
    end
    return nil, nil
end

function utils.is_rear_engine(vehicle)
    local vehicle_data = core.get_static_data("inventories")
    if not vehicle_data or not vehicle_data.rear_engine then return false end
    local model_name = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    return vehicle_data.rear_engine[model_name] == true
end

function utils.get_nearby_vehicle(radius)
    radius = radius or 2.5
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, radius, 0, 70)
    if not DoesEntityExist(vehicle) then return nil, nil end
    local bone_index = utils.is_rear_engine(vehicle)
        and GetEntityBoneIndexByName(vehicle, "engine")
        or GetEntityBoneIndexByName(vehicle, "boot")
    if bone_index ~= -1 then
        local bone_coords = GetWorldPositionOfEntityBone(vehicle, bone_index)
        if #(coords - bone_coords) <= radius then
            return vehicle, "trunk"
        end
    end
    return nil, nil
end

function utils.get_current_vehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        return vehicle, "glovebox"
    end
    return nil, nil
end

function utils.get_accessible_vehicle_inventory()
    local vehicle, veh_type = utils.get_current_vehicle()
    if vehicle then
        local _, glovebox_config = utils.get_vehicle_config(vehicle)
        return vehicle, veh_type, glovebox_config
    end
    vehicle, veh_type = utils.get_nearby_vehicle(2.5)
    if vehicle then
        local trunk_config = utils.get_vehicle_config(vehicle)
        return vehicle, veh_type, trunk_config
    end
    return nil, nil, nil
end

function utils.set_vehicle_trunk_state(vehicle, inv_type, open)
    if not DoesEntityExist(vehicle) then return end
    if inv_type == "trunk" then
        local door = utils.is_rear_engine(vehicle) and 4 or 5
        if open then SetVehicleDoorOpen(vehicle, door, false, false)
        else SetVehicleDoorShut(vehicle, door, false) end
    end
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