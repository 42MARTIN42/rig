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

--- @class Players
--- @description Handles registering and moving players.

--- @section Imports

local Player = require("src.server.players.classes.player")
local utils = require("src.server.modules.utils")
local bucket_cfg = require("configs.buckets")

--- @section Class

local Players = {}
Players.__index = Players

function Players.new()
    return setmetatable({
        temp = {},
        players = {},
        extensions = {},
        bucket_players = {},
        buckets = bucket_cfg
    }, Players)
end

--- @section Internal Bucket Helpers

function Players:_get_bucket_player_count(bucket_name)
    local bucket = self.bucket_players[bucket_name]
    if not bucket then return 0 end
    local count = 0
    for _ in pairs(bucket) do count = count + 1 end
    return count
end

--- @section Registry Logic

function Players:request_connection(source, name, deferrals)
    local ids = utils.get_player_identifiers(source)
    if not ids.license then return deferrals.done("No valid license found.") end
    deferrals.defer()
    deferrals.update("Checking your identifiers...")
    local result = self:exists(ids.license)
    local user_data = result and result[1]
    if not user_data then
        deferrals.update("Creating new user...")
        local uid = utils.generate_unique_id(core.convars.uid_length, "rig_players", "unique_id")
        local default_username = ("%s_%s"):format(core.convars.username_prefix, uid:lower())
        self:persist(name, uid, default_username, ids.license, ids.discord, GetPlayerTokens(source), ids.ip)
        user_data = { name = name, unique_id = uid, username = default_username, license = ids.license, discord = ids.discord, ip = ids.ip, banned = false }
    end
    local ban = MySQL.query.await("SELECT id, reason, expires_at FROM rig_player_bans WHERE unique_id = ? AND expired = 0 ORDER BY created DESC LIMIT 1", { user_data.unique_id })
    local active_ban = ban and ban[1]
    if active_ban then
        if active_ban.expires_at and os.time() > (active_ban.expires_at / 1000) then
            MySQL.prepare.await("UPDATE rig_player_bans SET expired = 1 WHERE id = ?", { active_ban.id })
            MySQL.prepare.await("UPDATE rig_players SET banned = 0 WHERE unique_id = ?", { user_data.unique_id })
        else
            local msg = active_ban.expires_at and ("Banned until " .. os.date("%Y-%m-%d %H:%M:%S", active_ban.expires_at / 1000)) or "Permanently banned."
            return deferrals.done(("%s\nReason: %s"):format(msg, active_ban.reason))
        end
    end
    self:stage(ids.license, user_data)
    deferrals.done()
end

function Players:exists(license)
    return MySQL.query.await("SELECT * FROM rig_players WHERE license = ?", { license })
end

function Players:persist(name, unique_id, default_username, license, discord, tokens, ip)
    return MySQL.insert.await("INSERT INTO rig_players (unique_id, name, username, license, discord, tokens, ip) VALUES (?, ?, ?, ?, ?, ?, ?)",
        { unique_id, name, default_username, license, discord, json.encode(tokens), ip }
    )
end

function Players:stage(license, data)
    self.temp[license] = data
end

function Players:activate(source, license)
    local data = self.temp[license]
    if data then
        self.players[source] = data
        self.temp[license] = nil
        return true
    end
    return false
end

--- @section Bucket Management

function Players:set_bucket(source, bucket_name)
    bucket_name = bucket_name or "main"
    local config = self.buckets[bucket_name]
    if not config then return false, "invalid_bucket" end
    if config.staff_only and not IsPlayerAceAllowed(source, "rig.admin") then
        return false, "staff_only"
    end
    if config.player_cap and self:_get_bucket_player_count(bucket_name) >= config.player_cap then
        return false, "bucket_full"
    end
    for _, players in pairs(self.bucket_players) do players[source] = nil end
    self.bucket_players[bucket_name] = self.bucket_players[bucket_name] or {}
    self.bucket_players[bucket_name][source] = true
    SetPlayerRoutingBucket(source, config.bucket)
    TriggerEvent("rig:sv:player_assigned_bucket", source, config.bucket, config)
    return true
end

function Players:assign_personal_bucket(source)
    local bucket_count = 0
    for _ in pairs(self.buckets) do bucket_count = bucket_count + 1 end
    local assigned_bucket = bucket_count + source
    for _, players in pairs(self.bucket_players) do players[source] = nil end
    self.bucket_players["personal"] = self.bucket_players["personal"] or {}
    self.bucket_players["personal"][source] = assigned_bucket
    SetPlayerRoutingBucket(source, assigned_bucket)
    SetRoutingBucketPopulationEnabled(assigned_bucket, false)
    SetRoutingBucketEntityLockdownMode(assigned_bucket, "strict")
    return assigned_bucket
end

--- @section Lifecycle

function Players:register_extension(name, fn, priority)
    table.insert(self.extensions, { name = name, fn = fn, priority = priority or 100 })
    table.sort(self.extensions, function(a, b) return a.priority < b.priority end)
end

function Players:create(source)
    local data = self.players[source]
    if not data or getmetatable(data) then return data end
    local player = Player.new(source, data)
    if not player then return nil end
    for _, ext in ipairs(self.extensions) do
        local ok, err = pcall(ext.fn, player)
        if not ok then
            print(("^1[Players] Extension %s failed: %s^7"):format(ext.name, err))
        end
    end
    player:load()
    self.players[source] = player
    return player
end

function Players:get_all()
    return self.players
end

function Players:get(source)
    return self.players[source]
end

function Players:remove(source)
    local p = self.players[source]
    if p then p:unload() end
    for _, players in pairs(self.bucket_players) do players[source] = nil end
    self.players[source] = nil
end

function Players:save_all()
    for _, player in pairs(self.players) do
        if getmetatable(player) then player:save() end
    end
end

return Players