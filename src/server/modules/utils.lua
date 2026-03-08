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

--- @section API Functions

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
        local query = json_path and string.format("SELECT COUNT(*) as count FROM %s WHERE JSON_EXTRACT(%s, '$.%s') = ?", table_name, column_name, json_path) or string.format("SELECT COUNT(*) as count FROM %s WHERE %s = ?", table_name, column_name)
        local result = MySQL.query.await(query, { new_id })
        return result and result[1] and result[1].count > 0
    end
    local id
    repeat
        id = create_id()
    until not id_exists(id)
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
        local allowed = IsPlayerAceAllowed(source, ace)
        if allowed then return true end
    end
    return false
end

return utils