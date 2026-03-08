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

--- @section Imports

local callbacks = require("libs.graft.fivem.callbacks")
local utils = require("src.server.modules.utils")
local cfg_admin = require("configs.admin")

--- @section Statuses

callbacks.register("rig:sv:validate_revive", function(source, data, cb)
    local player = core.players:get(source)
    if not player then cb({ valid = false }) return end
    local valid = player:run_method("get_status", "pending_revive") == true
    player:run_method("set_status", "pending_revive", false)
    cb({ valid = valid })
end)

callbacks.register("rig:sv:validate_respawn", function(source, data, cb)
    local player = core.players:get(source)
    if not player then cb({ valid = false }) return end
    local valid = player:run_method("get_status", "is_dead") == true
    cb({ valid = valid })
end)

--- @section Admin

callbacks.register("rig:sv:admin_can_open_menu", function(source, data, cb)
    if not cfg_admin.permissions.open_menu then
        cb({ allowed = true })
        return
    end
    cb({ allowed = utils.has_permission(source, cfg_admin.permissions.open_menu) })
end)

--- @section Callbacks

callbacks.register("rig:sv:admin_toggle_noclip", function(source, data, cb)
    cb({ allowed = utils.has_permission(source, cfg_admin.permissions.user.noclip) })
end)

callbacks.register("rig:sv:admin_toggle_godmode", function(source, data, cb)
    cb({ allowed = utils.has_permission(source, cfg_admin.permissions.user.godmode) })
end)

callbacks.register("rig:sv:admin_toggle_invisible", function(source, data, cb)
    cb({ allowed = utils.has_permission(source, cfg_admin.permissions.user.invisible) })
end)

callbacks.register("rig:sv:admin_toggle_freeze", function(source, data, cb)
    cb({ allowed = utils.has_permission(source, cfg_admin.permissions.user.freeze) })
end)

callbacks.register("rig:sv:admin_can_teleport_waypoint", function(source, data, cb)
    cb({ allowed = utils.has_permission(source, cfg_admin.permissions.user.teleport_waypoint) })
end)

callbacks.register("rig:sv:admin_can_teleport_coords", function(source, data, cb)
    cb({ allowed = utils.has_permission(source, cfg_admin.permissions.user.teleport_coords) })
end)

callbacks.register("rig:sv:admin_revive_self", function(source, data, cb)
    if not utils.has_permission(source, cfg_admin.permissions.user.revive) then cb({ success = false, reason = "no_permission" }) return end
    local player = core.players:get(source)
    if not player then cb({ success = false, reason = "player_not_found" }) return end
    player:run_method("revive_player")
    cb({ success = true })
end)

callbacks.register("rig:sv:admin_kill_self", function(source, data, cb)
    if not utils.has_permission(source, cfg_admin.permissions.user.kill) then cb({ success = false, reason = "no_permission" }) return end
    local player = core.players:get(source)
    if not player then cb({ success = false, reason = "player_not_found" }) return end
    player:run_method("kill_player")
    cb({ success = true })
end)

callbacks.register("rig:sv:admin_revive_player", function(source, data, cb)
    if not utils.has_permission(source, cfg_admin.permissions.user.revive) then cb({ success = false, reason = "no_permission" }) return end
    local target = core.players:get(tonumber(data.target) or source)
    if not target then cb({ success = false, reason = "player_not_found" }) return end
    target:run_method("revive_player")
    cb({ success = true })
end)

callbacks.register("rig:sv:admin_kill_player", function(source, data, cb)
    if not utils.has_permission(source, cfg_admin.permissions.user.kill) then cb({ success = false, reason = "no_permission" }) return end
    local target = core.players:get(tonumber(data.target) or source)
    if not target then cb({ success = false, reason = "player_not_found" }) return end
    target:run_method("kill_player")
    cb({ success = true })
end)

callbacks.register("rig:sv:admin_can_view_bans", function(source, data, cb)
    cb({ allowed = utils.has_permission(source, cfg_admin.permissions.view_bans) })
end)

callbacks.register("rig:sv:admin_get_ban_list", function(source, data, cb)
    if not utils.has_permission(source, cfg_admin.permissions.view_bans) then
        cb({ bans = {} })
        return
    end
    local result = MySQL.query.await([[
        SELECT b.id, b.unique_id, b.banned_by, b.reason, b.expires_at, p.name
        FROM rig_player_bans b
        JOIN rig_players p ON p.unique_id = b.unique_id
        WHERE b.expired = 0
        ORDER BY b.created DESC
    ]], {})
    if result then
        for _, ban in ipairs(result) do
            ban.expires_formatted = ban.expires_at and os.date("%d/%m/%y %H:%M", ban.expires_at / 1000) or "Permanent"
        end
    end
    cb({ bans = result or {} })
end)

callbacks.register("rig:sv:admin_remove_ban", function(source, data, cb)
    if not utils.has_permission(source, cfg_admin.permissions.remove_ban) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local ok = dam.remove_ban(data.unique_id)
    cb({ success = ok })
end)

callbacks.register("rig:sv:admin_can_view_players", function(source, data, cb)
    if not cfg_admin.permissions.view_players then
        cb({ allowed = true })
        return
    end
    cb({ allowed = utils.has_permission(source, cfg_admin.permissions.view_players) })
end)

callbacks.register("rig:sv:admin_get_player_list", function(source, data, cb)
    if not cfg_admin.permissions.view_players then
        cb({ players = get_player_list() })
        return
    end
    cb({ players = utils.has_permission(source, cfg_admin.permissions.view_players) and get_player_list() or {} })
end)

callbacks.register("rig:sv:admin_teleport_to_player", function(source, data, cb)
    if not utils.has_permission(source, cfg_admin.permissions.players.teleport) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local target = tonumber(data.target)
    if not target then cb({ success = false }) return end
    local ped = GetPlayerPed(target)
    if not ped or ped == 0 then cb({ success = false }) return end
    local coords = GetEntityCoords(ped)
    cb({ success = true, coords = {x = coords.x, y = coords.y, z = coords.z} })
end)

callbacks.register("rig:sv:admin_bring_player", function(source, data, cb)
    if not utils.has_permission(source, cfg_admin.permissions.players.bring) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local target = tonumber(data.target)
    if not target then cb({ success = false }) return end
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then cb({ success = false }) return end
    local coords = GetEntityCoords(ped)
    TriggerClientEvent("rig:cl:set_coords", target, {x = coords.x, y = coords.y, z = coords.z})
    cb({ success = true })
end)

callbacks.register("rig:sv:admin_ban_player", function(source, data, cb)
    if not utils.has_permission(source, cfg_admin.permissions.players.ban) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local target = tonumber(data.target)
    if not target then cb({ success = false }) return end
    local banned_by = GetPlayerName(source) or "dam"
    local ok = dam.ban_player(target, banned_by, data.reason, data.duration)
    cb({ success = ok })
end)

callbacks.register("rig:sv:admin_kick_player", function(source, data, cb)
    if not utils.has_permission(source, cfg_admin.permissions.players.kick) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local target = tonumber(data.target)
    if not target then cb({ success = false }) return end
    DropPlayer(target, data.reason or "Kicked by admin.")
    cb({ success = true })
end)

callbacks.register("rig:sv:admin_warn_player", function(source, data, cb)
    if not utils.has_permission(source, cfg_admin.permissions.players.warn) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local target = tonumber(data.target)
    if not target then cb({ success = false }) return end
    local ids = dam.get_identifiers(target)
    if not ids.license then cb({ success = false }) return end
    local result = MySQL.query.await("SELECT unique_id FROM rig_players WHERE license = ?", { ids.license })
    if not result or not result[1] then cb({ success = false }) return end
    local warned_by = GetPlayerName(source) or "dam"
    MySQL.insert.await("INSERT INTO rig_player_warnings (unique_id, warned_by, reason) VALUES (?, ?, ?)", { result[1].unique_id, warned_by, data.reason or "No reason provided." })
    TriggerClientEvent("rig:cl:player_warned", target, data.reason or "No reason provided.")
    cb({ success = true })
end)

callbacks.register("rig:sv:admin_get_player_warnings", function(source, data, cb)
    if not utils.has_permission(source, cfg_admin.permissions.players.warn) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local target = tonumber(data.target)
    if not target then cb({ success = false }) return end
    local ids = dam.get_identifiers(target)
    if not ids.license then cb({ success = false }) return end
    local result = MySQL.query.await("SELECT unique_id FROM rig_players WHERE license = ?", { ids.license })
    if not result or not result[1] then cb({ success = false }) return end
    local warnings = MySQL.query.await("SELECT id, warned_by, reason, created FROM rig_player_warnings WHERE unique_id = ? ORDER BY created DESC", { result[1].unique_id })
    if warnings then
        for _, w in ipairs(warnings) do
            w.created = os.date("%d/%m/%y %H:%M", w.created / 1000)
        end
    end
    cb({ success = true, warnings = warnings or {} })
end)