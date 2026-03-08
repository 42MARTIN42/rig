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

--- @script src.client.gui.admin_menu
--- @description Handle all UI stuff for admin menu.

--- @section Imports

local callbacks = require("libs.graft.fivem.callbacks")

--- @section Module

local m = {}

--- @section State

local cached_warnings = {}

--- @section Internal Functions

local function build_player_menu(players)
    local menus = {
        players = { title = "Player List", items = {} }
    }
    for _, p in ipairs(players) do
        local key = "player_" .. p.source
        local warn_key = "warnings_" .. p.source
        menus.players.items[#menus.players.items + 1] = {
            type = "submenu",
            label = "[" .. p.source .. "] " .. p.name,
            submenu = key
        }
        local warn_items = {}
        local cached = cached_warnings[p.source]
        if cached then
            if #cached > 0 then
                for _, w in ipairs(cached) do
                    warn_items[#warn_items + 1] = { type = "action", label = "By: ".. w.warned_by .. " | For: " .. w.reason, desc = w.created, on_action = function() end }
                end
            else
                warn_items[#warn_items + 1] = { type = "action", label = "No warnings.", on_action = function() end }
            end
        else
            warn_items[#warn_items + 1] = { type = "action", label = "Loading...", on_action = function() end }
        end
        warn_items[#warn_items + 1] = { type = "separator" }
        warn_items[#warn_items + 1] = { type = "back", key = key, label = "Back", desc = "Return to player." }
        menus[warn_key] = { title = "Warnings: " .. p.name, items = warn_items }
        menus[key] = {
            title = "[" .. p.source .. "] " .. p.name,
            items = {
                { type = "action", label = "Revive", desc = "Revive player.", keep_open = true, on_action = function() revive_player(p.source) end },
                { type = "action", label = "Kill", desc = "Kill player.", keep_open = true, on_action = function() kill_player(p.source) end },
                { type = "action", label = "Teleport To", desc = "Teleport to player.", keep_open = true, on_action = function() teleport_to_player(p.source) end },
                { type = "action", label = "Bring", desc = "Bring player to you.", keep_open = true, on_action = function() bring_player(p.source) end },
                { type = "action", label = "Kick", desc = "Kick player.", keep_open = true, on_action = function() kick_player(p.source) end },
                { type = "action", label = "Warn", desc = "Warn player.", keep_open = true, on_action = function() warn_player(p.source) end },
                { type = "submenu", label = "View Warnings", desc = "View player warnings.", submenu = warn_key },
                { type = "action", label = "Ban", desc = "Ban player.", keep_open = true, on_action = function() ban_player(p.source) end },
                { type = "separator" },
                { type = "back", key = "players", label = "Back", desc = "Return to player list." },
            }
        }
    end
    menus.players.items[#menus.players.items + 1] = {type = "separator"}
    menus.players.items[#menus.players.items + 1] = {type = "close", label = "Close"}
    return menus
end

local function fetch_warnings(players)
    for _, p in ipairs(players) do
        if not cached_warnings[p.source] then
            callbacks.trigger("rig:sv:admin_get_player_warnings", {target = p.source}, function(r)
                if r and r.success then
                    cached_warnings[p.source] = r.warnings
                end
            end)
        end
    end
end

local function open_player_menu(players)
    local menus = build_player_menu(players)
    if drip.is_menu_open("admin_players") then
        drip.update_menus("admin_players", menus)
        return
    end
    drip.open_menu({
        id = "admin_players",
        root = "players",
        style = { x = 0.250, y = 0.0275, width = 0.22 },
        menus = menus
    })
end

local function start_player_poll()
    cached_warnings = {}
    CreateThread(function()
        while drip.is_menu_open("admin_players") do
            callbacks.trigger("rig:sv:admin_get_player_list", {}, function(response)
                if not response or not drip.is_menu_open("admin_players") then return end
                fetch_warnings(response.players)
                open_player_menu(response.players)
            end)
            Wait(5000)
        end
        cached_warnings = {}
    end)
end

local function start_ban_poll()
    CreateThread(function()
        while drip.is_menu_open("admin_bans") do
            callbacks.trigger("rig:sv:admin_get_ban_list", {}, function(r)
                if not r or not drip.is_menu_open("admin_bans") then return end
                m.open_ban_menu(r.bans)
            end)
            Wait(30000)
        end
    end)
end

local function build_ban_menu(bans)
    local menus = {
        bans = { title = "Ban List", items = {} }
    }
    for _, b in ipairs(bans) do
        local key = "ban_" .. b.id
        menus.bans.items[#menus.bans.items + 1] = {
            type = "submenu",
            label = b.unique_id .. " | " .. b.name .. " | " .. (b.expires_formatted or "Permanent"),
            submenu = key
        }
        menus[key] = {
            title = b.name,
            items = {
                { type = "action", label = "Remove", desc = "Remove this ban.", keep_open = true, on_action = function() remove_ban(b.unique_id) end },
                { type = "separator" },
                { type = "back", key = "bans", label = "Back", desc = "Return to ban list." },
            }
        }
    end
    if #menus.bans.items == 0 then
        menus.bans.items[#menus.bans.items + 1] = { type = "action", label = "No active bans.", on_action = function() end }
    end
    menus.bans.items[#menus.bans.items + 1] = {type = "separator"}
    menus.bans.items[#menus.bans.items + 1] = {type = "close", label = "Close"}
    return menus
end

--- @section API Functions

function m.open_ban_menu(bans)
    local menus = build_ban_menu(bans)
    if drip.is_menu_open("admin_bans") then
        drip.update_menus("admin_bans", menus)
        return
    end
    drip.open_menu({
        id = "admin_bans",
        root = "bans",
        style = { x = 0.485, y = 0.0275, width = 0.22 },
        menus = menus
    })
end

function m.build_user_menu()
    return {
        title = "Self",
        items = {
            { type = "toggle", label = "Noclip", desc = "Toggle noclip.", value = noclip_active, on_change = function() toggle_noclip() end },
            { type = "toggle", label = "God Mode", desc = "Toggle god mode.", value = godmode_active, on_change = function() toggle_godmode() end },
            { type = "toggle", label = "Invisible", desc = "Toggle invisibility.", value = invisible_active, on_change = function() toggle_invisible() end },
            { type = "toggle", label = "Freeze", desc = "Toggle freeze.", value = freeze_active, on_change = function() toggle_freeze() end },
            { type = "action", label = "Print Coords", desc = "Print v2, v3, v4 coords to console.", keep_open = true, on_action = function()
                local ped = PlayerPedId()
                local c = GetEntityCoords(ped)
                local h = GetEntityHeading(ped)
                print(("vector2(%.2f, %.2f)"):format(c.x, c.y))
                print(("vector3(%.2f, %.2f, %.2f)"):format(c.x, c.y, c.z))
                print(("vector4(%.2f, %.2f, %.2f, %.2f)"):format(c.x, c.y, c.z, h))
            end },
            { type = "action", label = "Teleport to Waypoint", desc = "Teleport to your waypoint.", keep_open = true, on_action = teleport_to_waypoint },
            { type = "action", label = "Teleport to Coords", desc = "Teleport to specific coordinates.", keep_open = true, on_action = teleport_to_coords },
            { type = "action", label = "Revive", desc = "Revive yourself.", keep_open = true, on_action = revive_self },
            { type = "action", label = "Kill", desc = "Kill yourself.", keep_open = true, on_action = kill_self },
            { type = "separator" },
            { type = "back", key = "main", label = "Back", desc = "Go back to main menu." },
        }
    }
end


function m.build_players_menu()
    return {
        title = "Player Actions",
        items = {
            {
                type = "action",
                label = "Player List",
                desc = "View and manage online players.",
                keep_open = true,
                on_action = function()
                    callbacks.trigger("rig:sv:admin_can_view_players", {}, function(response)
                        if not response or not response.allowed then
                            pluck.notify({header = locale("admin.access_denied"), type = "error", message = locale("admin.no_permission_action"), duration = 4000})
                            return
                        end
                        callbacks.trigger("rig:sv:admin_get_player_list", {}, function(r)
                            if not r then return end
                            fetch_warnings(r.players)
                            open_player_menu(r.players)
                            start_player_poll()
                        end)
                    end)
                end
            },
            {
                type = "action",
                label = "Ban List",
                desc = "View and manage active bans.",
                keep_open = true,
                on_action = function()
                    callbacks.trigger("rig:sv:admin_can_view_bans", {}, function(response)
                        if not response or not response.allowed then
                            pluck.notify({header = locale("admin.access_denied"), type = "error", message = locale("admin.no_permission_action"), duration = 4000})
                            return
                        end
                        callbacks.trigger("rig:sv:admin_get_ban_list", {}, function(r)
                            if not r then return end
                            m.open_ban_menu(r.bans)
                            start_ban_poll()
                        end)
                    end)
                end
            },
            { type = "separator" },
            { type = "back", key = "main", label = "Back", desc = "Go back to main menu." },
        }
    }
end

function m.build_vehicles_menu()
    return {
        title = "Vehicles",
        items = {
            { type = "action", label = "Spawn Vehicle", desc = "Spawn a vehicle by model name.", keep_open = true, on_action = spawn_vehicle },
            { type = "action", label = "Delete Vehicle", desc = "Delete your current vehicle.", keep_open = true, on_action = delete_vehicle },
            { type = "action", label = "Repair Vehicle", desc = "Repair your current vehicle.", keep_open = true, on_action = repair_vehicle },
            { type = "action", label = "Vehicle Info", desc = "Toggle vehicle info panel.", keep_open = true, on_action = function()
                if drip.is_panel_visible("admin_vehicle_info") then
                    drip.hide_panel("admin_vehicle_info")
                else
                    show_vehicle_panel()
                end
            end },
            { type = "separator" },
            { type = "back", key = "main", label = "Back", desc = "Go back to main menu." },
        }
    }
end

return m