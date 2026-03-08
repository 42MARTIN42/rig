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

--- @class Objects
--- @description Manages player placed objects

--- @section Imports

local placeables_cfg = require("configs.placeables")

--- @section Class

local Objects = {}
Objects.__index = Objects

--- @factory Constructor

function Objects.new()
    local self = setmetatable({
        placed_objects = {},
    }, Objects)
    return self
end

--- @section Functions

function Objects:get_sync_payload()
    local payload = {}
    for id, obj in pairs(self.placed_objects) do
        local def = placeables_cfg[obj.object_type]
        table.insert(payload, {
            id = id,
            model = obj.model,
            object_type = obj.object_type,
            label = def and def.label or "",
            icon = def and def.icon or "",
            keys = def and def.keys or {},
            x = obj.coords.x, y = obj.coords.y, z = obj.coords.z, w = obj.coords.w
        })
    end
    return payload
end

function Objects:load()
    local rows = MySQL.query.await("SELECT * FROM rig_placed_objects", {})
    if not rows then return end
    for _, row in ipairs(rows) do
        row.coords = vector4(row.x, row.y, row.z, row.w or 0.0)
        self.placed_objects[row.id] = row
    end
end

function Objects:save(obj)
    MySQL.insert.await("INSERT INTO rig_placed_objects (id, owner_id, model, object_type, x, y, z, w) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", { 
        obj.id, obj.owner_id, obj.model, obj.object_type, obj.coords.x, obj.coords.y, obj.coords.z, obj.coords.w 
    })
    self.placed_objects[obj.id] = obj
end

function Objects:delete(id)
    MySQL.update.await("DELETE FROM rig_placed_objects WHERE id = ?", { id })
    self.placed_objects[id] = nil
end

function Objects:count(owner_id, object_type)
    local count = 0
    for _, obj in pairs(self.placed_objects) do
        if obj.owner_id == owner_id and obj.object_type == object_type then
            count = count + 1
        end
    end
    return count
end

function Objects:generate_id(owner_id, object_type)
    return ("%s_%s_%d"):format(owner_id:sub(1, 8), object_type:sub(1, 8), GetGameTimer())
end

function Objects:place(source, data, user)
    local definition = placeable_objects[data.object_type]
    if not definition then
        log("error", ("Unknown object type '%s' from source %d"):format(data.object_type, source))
        return
    end
    if self:count(user.unique_id, data.object_type) >= (definition.limit or 1) then
        log("error", ("Too many objects placed of type: %s"):format(data.object_type))
        return
    end
    local id = self:generate_id(user.unique_id, data.object_type)
    local obj = { id = id, owner_id = user.unique_id, model = definition.model, object_type = data.object_type, coords = data.coords }
    self:save(obj)
    TriggerClientEvent("rig:cl:spawn_placed_object", -1, id, obj.model, obj.object_type, definition.label, definition.icon, definition.keys, obj.coords.x, obj.coords.y, obj.coords.z, obj.coords.w)
    log("info", ("Placed %s for %s"):format(data.object_type, user.unique_id))
end

function Objects:remove(source, id, user)
    local obj = self.placed_objects[id]
    if not obj or obj.owner_id ~= user.unique_id then
        log("error", "Player is not the owner cannot remove.")
        return
    end
    self:delete(id)
    TriggerClientEvent("rig:cl:remove_placed_object", -1, id)
    log("info", ("Removed '%s' for %s"):format(id, user.unique_id))
end

function Objects:use(source, id, key)
    local obj = self.placed_objects[id]
    if not obj then return end
    local definition = placeable_objects[obj.object_type]
    if not definition or not definition.actions then return end
    local action = definition.actions[key]
    if action then action(source, id) end
end

return Objects