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

--- @class Player
--- @description The main player class for RIG.
--- **DO NOT TOUCH THIS FILE UNLESS YOU KNOW WHAT YOU ARE DOING... YOU WILL BREAK THE ENTIRE PLAYER CORE**
--- **THIS FILE SHOULD NEVER NEED TOUCHING UNLESS MAJOR ARCHITECTURE CHANGES OCCUR**
--- **PLAYERS CAN BE EXTENDED ENTIRELY THROUGH THE EXTENSION SYSTEM. USE IT.**

--- @section Class

local Player = {}
Player.__index = Player
Player.__metatable = false
local Private = setmetatable({}, { __mode = "k" })

--- @section Helpers

local function init_private(self, user)
    Private[self] = {
        user = user,
        data = {
            user = {
                unique_id = user.unique_id,
                username = user.username,
                vip = user.vip,
                priority = user.priority,
                banned = user.banned,
                muted = user.muted
            },
            flags = {
                loaded = false,
                playing = false
            }
        },
        replicated = {},
        extensions = {},
        methods = {}
    }
end

--- @section Constructor

function Player.new(source)
    if not source then log("error", locale("source_missing")) return nil end
    local user = core.get_user(source)
    if not user then log("error", locale("user_missing", source)) return nil end
    local self = setmetatable({
        source = source,
        unique_id = user.unique_id or "undefined",
        username = user.username or ("default_" .. user.unique_id),
        vip = user.vip,
        priority = user.priority
    }, Player)
    init_private(self, user)
    return self
end

--- @section Methods

function Player:load()
    local priv = Private[self]
    if not priv then return false end
    for _, ext in pairs(priv.extensions) do 
        if ext.on_load then 
            ext:on_load() 
        end 
    end
    self:sync()
    self:set_data("flags", { loaded = true })
    TriggerEvent("rig:sv:player_loaded", self)
    log("success", locale("player_loaded", self.unique_id))
    return true
end

function Player:unload()
    local priv = Private[self]
    if not priv then return false end
    for _, ext in pairs(priv.extensions) do 
        if ext.on_unload then 
            ext:on_unload() 
        end 
    end
    TriggerEvent("rig:sv:player_unload", self)
    Private[self] = nil
    return true
end

function Player:save()
    local priv = Private[self]
    if not priv then return false end
    if not self:is_playing() then return false end
    local queries = {}
    for _, ext in pairs(priv.extensions) do
        if ext.on_save then
            local result = ext:on_save()
            if result then
                for _, q in ipairs(result) do
                    queries[#queries + 1] = q
                end
            end
        end
    end
    if #queries > 0 then MySQL.transaction.await(queries) end
    TriggerEvent("rig:sv:player_save", self)
    return true
end

function Player:has_loaded()
    return Private[self].data.flags.loaded == true
end

function Player:is_playing()
    return Private[self].data.flags.playing == true
end

function Player:set_playing(state)
    Private[self].data.flags.playing = state
    TriggerEvent("rig:sv:playing_state_changed", self.source, state)
    TriggerClientEvent("rig:cl:playing_state_changed", self.source, state)
end

function Player:add_data(category, value, replicate)
    if type(category) ~= "string" then return false end
    local priv = Private[self]
    priv.data[category] = value
    if replicate then 
        priv.replicated[category] = true 
    end
    return true
end

function Player:get_data(category)
    local data = Private[self].data
    return category and data[category] or data
end

function Player:has_data(category)
    return Private[self].data[category] ~= nil
end

function Player:set_data(category, updates, sync)
    local priv = Private[self]
    local target = priv.data[category]
    if type(target) ~= "table" or type(updates) ~= "table" then return false end
    for k, v in pairs(updates) do 
        target[k] = v 
    end
    if sync then 
        self:sync(category) 
    end
    return true
end

function Player:replace_data(category, data, sync)
    local priv = Private[self]
    if priv.data[category] == nil then return false end
    priv.data[category] = type(data) == "table" and data or {}
    if sync then self:sync(category) end
    return true
end

function Player:remove_data(category)
    local priv = Private[self]
    if priv.data[category] ~= nil then
        priv.data[category] = nil
        self:sync(category)
        return true
    end
    return false
end

function Player:sync(category)
    local priv = Private[self]
    local payload = {}
    if category then
        if not priv.replicated[category] or type(priv.data[category]) ~= "table" then return end
        payload[category] = priv.data[category]
    else
        for k in pairs(priv.replicated) do
            payload[k] = priv.data[k]
        end
    end
    TriggerClientEvent("rig:cl:sync_player_data", self.source, payload)
end

function Player:update_user_data(updates)
    local priv = Private[self]
    if not priv.data.user or type(updates) ~= "table" then return false end
    for k, v in pairs(updates) do
        if priv.data.user[k] ~= nil then
            priv.data.user[k] = v
        end
    end
    core.update_user_data(self.source, updates)
    return true
end

function Player:add_method(name, fn)
    if type(name) == "string" and type(fn) == "function" then
        Private[self].methods[name] = fn
        return true
    end
    return false
end

function Player:remove_method(name)
    local methods = Private[self].methods
    if methods[name] then
        methods[name] = nil
        return true
    end
    return false
end

function Player:run_method(name, ...)
    local fn = Private[self].methods[name]
    return fn and fn(...) or nil
end

function Player:has_method(name)
    return Private[self].methods[name] ~= nil
end

function Player:get_method(name)
    return Private[self].methods[name]
end

function Player:add_extension(name, ext)
    if type(name) == "string" and type(ext) == "table" then
        Private[self].extensions[name] = ext
        return true
    end
    return false
end

function Player:remove_extension(name)
    local extensions = Private[self].extensions
    if extensions[name] then
        extensions[name] = nil
        return true
    end
    return false
end

function Player:get_extension(name)
    return Private[self].extensions[name]
end

function Player:has_extension(name)
    return Private[self].extensions[name] ~= nil
end

function Player:list_extensions()
    local keys = {}
    for k in pairs(Private[self].extensions) do 
        keys[#keys + 1] = k 
    end
    return keys
end

function Player:dump_data()
    log("debug", locale("player_data_dump", json.encode(Private[self].data)))
end

return Player