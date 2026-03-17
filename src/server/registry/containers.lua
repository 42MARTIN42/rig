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

local Container = require("src.server.extensions.inventory.classes.container")

local Containers = {}
Containers.__index = Containers

function Containers.new()
    return setmetatable({
        containers = {},
        container_locks = {},
        vehicle_locks = {},
    }, Containers)
end

function Containers:generate_id(prefix, subtype)
    prefix = prefix or "container"
    local id
    repeat
        id = subtype and ("%s:%s:%s:%s"):format(prefix, subtype, os.time(), math.random(1000, 9999)) or ("%s:%s:%s"):format(prefix, os.time(), math.random(1000, 9999))
    until not self.containers[id]
    return id
end

function Containers:cleanup_stale_vehicles(max_age)
    max_age = max_age or 300000
    local now = GetGameTimer()
    local removed = 0
    for id, container in pairs(self.containers) do
        if container.type == "vehicle" and not container.persist then
            if not self.container_locks[id] then
                local age = now - (container.last_accessed or container.created_at or now)
                if age > max_age then
                    self:remove(id)
                    removed = removed + 1
                end
            end
        end
    end
    if removed > 0 then
        print(("^3[Containers] Cleaned up %d stale vehicle containers^7"):format(removed))
    end
end

function Containers:add(id, container)
    if not id or not container then return false end
    self.containers[id] = container
    return true
end

function Containers:create(id, data)
    if not id or type(id) ~= "string" then return nil end
    if self.containers[id] then return self.containers[id] end
    data = data or {}
    local container = Container.new(id, data)
    if not container then return nil end
    if not container:load() then return nil end
    self.containers[id] = container
    TriggerEvent("rig:sv:container_created", container)
    return container
end

function Containers:get(id)
    return self.containers[id]
end

function Containers:get_or_create_vehicle(plate, inv_type, vehicle_data)
    inv_type = inv_type or "trunk"
    local id = ("vehicle:%s:%s"):format(inv_type, plate)
    local existing = self.containers[id]
    if existing then
        existing.last_accessed = GetGameTimer()
        return existing
    end
    vehicle_data = vehicle_data or {}
    local persist = vehicle_data.is_owned or false
    return self:create(id, {
        owner = vehicle_data.owner or "unknown",
        type = "vehicle",
        subtype = inv_type,
        persist = persist,
        metadata = {
            persist = persist,
            plate = plate,
            inv_type = inv_type,
            model = vehicle_data.model,
            class = vehicle_data.class,
        }
    })
end

function Containers:make_vehicle_persistent(plate, owner, inv_type)
    inv_type = inv_type or "trunk"
    local id = ("vehicle:%s:%s"):format(inv_type, plate)
    local container = self.containers[id]
    if not container then return false end
    container.persist = true
    container.owner = owner
    container:save(true)
    return true
end

function Containers:remove(id)
    if not self.containers[id] then return false end
    self.containers[id] = nil
    self.container_locks[id] = nil
    TriggerClientEvent("rig:cl:remove_container", -1, id)
    TriggerEvent("rig:sv:container_removed", id)
    return true
end

function Containers:has(id)
    return self.containers[id] ~= nil
end

function Containers:get_items(id)
    local container = self.containers[id]
    return container and container:get_items() or {}
end

function Containers:set_items(id, items)
    local container = self.containers[id]
    if not container then return false end
    local priv_items = container:get_items()
    for k, v in pairs(items) do priv_items[k] = v end
    container:mark_dirty()
    container:save()
    return true
end

function Containers:is_locked(id)
    local lock = self.container_locks[id]
    return lock ~= nil, lock and lock.source or nil
end

function Containers:lock(id, source)
    if self.container_locks[id] then return false end
    self.container_locks[id] = { source = source, locked_at = GetGameTimer() }
    return true
end

function Containers:unlock(id, source)
    local lock = self.container_locks[id]
    if not lock then return true end
    if source and lock.source ~= source then return false end
    self.container_locks[id] = nil
    return true
end

function Containers:get_player_lock(source)
    for id, lock in pairs(self.container_locks) do
        if lock.source == source then return id end
    end
    return nil
end

function Containers:get_locked_by_player(source)
    return self:get_player_lock(source)
end

function Containers:unlock_all_for_player(source)
    for id, lock in pairs(self.container_locks) do
        if lock.source == source then
            self.container_locks[id] = nil
        end
    end
    self.vehicle_locks[source] = nil
end

function Containers:set_vehicle_access(source, vehicle_data)
    self.vehicle_locks[source] = vehicle_data
end

function Containers:clear_vehicle_access(source)
    self.vehicle_locks[source] = nil
end

function Containers:get_vehicle_access(source)
    return self.vehicle_locks[source]
end

function Containers:save(id)
    local container = self.containers[id]
    if not container then return false end
    container:save()
    return true
end

function Containers:save_all()
    for id, container in pairs(self.containers) do
        if container.persist then
            container:save()
        end
    end
end

return Containers