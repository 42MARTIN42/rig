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

--- @class Drops
--- @description Manages ground drops.

--- @section Class

local Drops = {}
Drops.__index = Drops

--- @factory Constructor

function Drops.new()
    return setmetatable({
        drops = {},
        pickup_locks = {},
        drop_index = 0,
    }, Drops)
end

--- @section Internal Helpers

--- Offsets coords slightly to avoid stacking drops
--- @param base table: {x, y, z}
--- @return table: Adjusted coords
function Drops:resolve_coords(base)
    for _, drop in pairs(self.drops) do
        local dx = base.x - drop.coords.x
        local dy = base.y - drop.coords.y
        if math.sqrt(dx * dx + dy * dy) < 0.6 then
            base = {
                x = base.x + math.random(-30, 30) / 100,
                y = base.y + math.random(-30, 30) / 100,
                z = base.z
            }
        end
    end
    return base
end

--- @section CRUD

--- Adds a drop to the world
--- @param data table: { item_id, label, image, category, quantity, metadata, coords }
--- @return number: Drop id
function Drops:add(data)
    self.drop_index = self.drop_index + 1
    data.id = self.drop_index
    data.coords = self:resolve_coords(data.coords)
    self.drops[self.drop_index] = data
    TriggerClientEvent("rig:cl:add_drop", -1, data)
    return self.drop_index
end

--- Removes a drop from the world
--- @param drop_id number
--- @return boolean
function Drops:remove(drop_id)
    if not self.drops[drop_id] then return false end
    self.drops[drop_id] = nil
    self.pickup_locks[drop_id] = nil
    TriggerClientEvent("rig:cl:remove_drop", -1, drop_id)
    return true
end

--- Gets a drop by id
--- @param drop_id number
--- @return table|nil
function Drops:get(drop_id)
    return self.drops[drop_id]
end

--- Gets all drops
--- @return table
function Drops:get_all()
    return self.drops
end

--- Gets nearby drops for a player
--- @param source number
--- @param radius number|nil: Default 2.5
--- @return table: Array of drop ids
function Drops:get_nearby(source, radius)
    radius = radius or 2.5
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return {} end

    local pcoords = GetEntityCoords(ped)
    local nearby = {}

    for drop_id, drop in pairs(self.drops) do
        local dcoords = vector3(drop.coords.x, drop.coords.y, drop.coords.z)
        if #(pcoords - dcoords) <= radius then
            nearby[#nearby + 1] = drop_id
        end
    end

    return nearby
end

--- @section Locks

--- Checks if a drop is locked
--- @param drop_id number
--- @return boolean
function Drops:is_locked(drop_id)
    return self.pickup_locks[drop_id] ~= nil
end

--- Locks a drop for pickup
--- @param drop_id number
--- @return boolean
function Drops:lock(drop_id)
    if self.pickup_locks[drop_id] then return false end
    self.pickup_locks[drop_id] = true
    return true
end

--- Unlocks a drop
--- @param drop_id number
function Drops:unlock(drop_id)
    self.pickup_locks[drop_id] = nil
end

--- @section Sync

--- Syncs all drops to a specific client
--- @param source number
function Drops:sync_to(source)
    TriggerClientEvent("rig:cl:init_drops", source, self.drops)
end

return Drops