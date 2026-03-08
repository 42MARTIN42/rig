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

--- @script client.user
--- @description Handles user actions; noclip, godmode, invisible etc.

--- @section Imports

local callbacks = require("libs.graft.fivem.callbacks")
local vehicles = require("libs.graft.fivem.vehicles")
local keys = require("libs.graft.fivem.keys")
local key_list = keys.get_keys()
local admin_menu = require("src.client.gui.admin_menu")

--- @section Constants

local BASE_SPEED = 0.8
local SLOW_SPEED = 0.03
local FAST_MULT = 4.0
local BASE_ACCEL = 0.04
local FRICTION = 0.85
local SCROLL_STEP = 0.5
local SCROLL_MIN = 0.5
local SCROLL_MAX = 6.0

--- @section State

local noclip_active = false
local noclip_cam = nil
local noclip_vel = vector3(0.0, 0.0, 0.0)
local noclip_speed_mult = 1.0
local godmode_active = false
local invisible_active = false
local freeze_active = false

--- @section Local Functions

local function is_pressed(group, control)
    return IsControlPressed(group, control) or IsDisabledControlPressed(group, control)
end

local function find_ground(x, y, z)
    for i = 0, 500 do
        local found, ground_z = GetGroundZFor_3dCoord(x, y, z - i * 0.1, false)
        if found then return ground_z end
    end
    return z
end

local function start_noclip()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    noclip_cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(noclip_cam, pos.x, pos.y, pos.z + 2.0)
    SetCamRot(noclip_cam, 0.0, 0.0, GetEntityHeading(ped), 2)
    SetCamFov(noclip_cam, 70.0)
    RenderScriptCams(true, false, 0, true, true)
    FreezeEntityPosition(ped, true)
    SetEntityAlpha(ped, 0, false)
    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)
    noclip_vel = vector3(0.0, 0.0, 0.0)
    noclip_speed_mult = 1.0
    noclip_active = true
end

local function stop_noclip()
    noclip_active = false
    local cam_pos = GetCamCoord(noclip_cam)
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(noclip_cam, false)
    noclip_cam = nil
    local ped = PlayerPedId()
    local ground_z = find_ground(cam_pos.x, cam_pos.y, cam_pos.z)
    SetEntityCoords(ped, cam_pos.x, cam_pos.y, ground_z + 0.5, false, false, false, false)
    FreezeEntityPosition(ped, false)
    SetEntityAlpha(ped, 255, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
end

--- @section Player Functions

function revive_player(target)
    callbacks.trigger("rig:sv:admin_revive_player", {target = target}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "no_hook" and "No revive hook configured." or locale("admin.no_permission_action")
            pluck.notify({header = "Revive", type = "error", message = msg, duration = 4000})
            return
        end
        pluck.notify({header = "Revive", type = "success", message = "Player revived.", duration = 3000})
    end)
end

function kill_player(target)
    callbacks.trigger("rig:sv:admin_kill_player", {target = target}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "no_hook" and "No kill hook configured." or locale("admin.no_permission_action")
            pluck.notify({header = "Kill", type = "error", message = msg, duration = 4000})
            return
        end
        pluck.notify({header = "Kill", type = "success", message = "Player killed.", duration = 3000})
    end)
end

function teleport_to_player(target)
    callbacks.trigger("rig:sv:admin_teleport_to_player", {target = target}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "no_permission" and locale("admin.no_permission_action") or "Failed to teleport."
            pluck.notify({header = "Teleport", type = "error", message = msg, duration = 4000})
            return
        end
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local entity = vehicle > 0 and vehicle or ped
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
        SetPedCoordsKeepVehicle(ped, r.coords.x, r.coords.y, r.coords.z)
        DoScreenFadeIn(500)
        pluck.notify({header = "Teleport", type = "success", message = "Teleported to player.", duration = 3000})
    end)
end

function bring_player(target)
    callbacks.trigger("rig:sv:admin_bring_player", {target = target}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "no_permission" and locale("admin.no_permission_action") or "Failed to bring player."
            pluck.notify({header = "Bring", type = "error", message = msg, duration = 4000})
            return
        end
        pluck.notify({header = "Bring", type = "success", message = "Player brought to you.", duration = 3000})
    end)
end

function ban_player(target)
    drip.close_menu("admin_players")
    CreateThread(function()
        local reason = get_keyboard_input("Enter ban reason", 100)
        if not reason or reason == "" then reason = "No reason provided." end
        local duration_input = get_keyboard_input("Enter duration in minutes (0 = permanent)", 10)
        local duration = tonumber(duration_input)
        if duration and duration > 0 then duration = duration * 60 else duration = nil end
        callbacks.trigger("rig:sv:admin_ban_player", {target = target, reason = reason, duration = duration}, function(r)
            if not r or not r.success then
                local msg = r and r.reason == "no_permission" and locale("admin.no_permission_action") or "Failed to ban player."
                pluck.notify({header = "Ban", type = "error", message = msg, duration = 4000})
                return
            end
            pluck.notify({header = "Ban", type = "success", message = "Player banned.", duration = 3000})
        end)
    end)
end

function kick_player(target)
    drip.close_menu("admin_players")
    CreateThread(function()
        local reason = get_keyboard_input("Enter kick reason", 100)
        if not reason or reason == "" then reason = "No reason provided." end
        callbacks.trigger("rig:sv:admin_kick_player", {target = target, reason = reason}, function(r)
            if not r or not r.success then
                local msg = r and r.reason == "no_permission" and locale("admin.no_permission_action") or "Failed to kick player."
                pluck.notify({header = "Kick", type = "error", message = msg, duration = 4000})
                return
            end
            pluck.notify({header = "Kick", type = "success", message = "Player kicked.", duration = 3000})
        end)
    end)
end

function warn_player(target)
    drip.close_menu("admin_players")
    CreateThread(function()
        local reason = get_keyboard_input("Enter warn reason", 100)
        if not reason or reason == "" then reason = "No reason provided." end
        callbacks.trigger("rig:sv:admin_warn_player", {target = target, reason = reason}, function(r)
            if not r or not r.success then
                local msg = r and r.reason == "no_permission" and locale("admin.no_permission_action") or "Failed to warn player."
                pluck.notify({header = "Warn", type = "error", message = msg, duration = 4000})
                return
            end
            pluck.notify({header = "Warn", type = "success", message = "Player warned.", duration = 3000})
        end)
    end)
end

--- @section Self Actions

function toggle_noclip()
    callbacks.trigger("rig:sv:admin_toggle_noclip", {}, function(response)
        if not response or not response.allowed then
            pluck.notify({
                header = locale("admin.access_denied"),
                type = "error",
                message = locale("admin.no_permission_action"),
                duration = 4000
            })
            return
        end
        if noclip_active then stop_noclip() else start_noclip() end
    end)
end

function toggle_godmode()
    callbacks.trigger("rig:sv:admin_toggle_godmode", {}, function(response)
        if not response or not response.allowed then
            pluck.notify({
                header = locale("admin.access_denied"),
                type = "error",
                message = locale("admin.no_permission_action"),
                duration = 4000
            })
            return
        end
        godmode_active = not godmode_active
        SetEntityInvincible(PlayerPedId(), godmode_active)
        SetPlayerInvincible(PlayerId(), godmode_active)
        pluck.notify({
            header = "God Mode",
            type = godmode_active and "success" or "info",
            message = godmode_active and "God mode enabled." or "God mode disabled.",
            duration = 3000
        })
    end)
end

function toggle_invisible()
    callbacks.trigger("rig:sv:admin_toggle_invisible", {}, function(response)
        if not response or not response.allowed then
            pluck.notify({
                header = locale("admin.access_denied"),
                type = "error",
                message = locale("admin.no_permission_action"),
                duration = 4000
            })
            return
        end
        invisible_active = not invisible_active
        SetEntityVisible(PlayerPedId(), not invisible_active, false)
        SetEntityAlpha(PlayerPedId(), invisible_active and 0 or 255, false)
        pluck.notify({
            header = "Invisible",
            type = invisible_active and "success" or "info",
            message = invisible_active and "Invisibility enabled." or "Invisibility disabled.",
            duration = 3000
        })
    end)
end

function toggle_freeze()
    callbacks.trigger("rig:sv:admin_toggle_freeze", {}, function(response)
        if not response or not response.allowed then
            pluck.notify({header = locale("admin.access_denied"), type = "error", message = locale("admin.no_permission_action"), duration = 4000})
            return
        end
        freeze_active = not freeze_active
        FreezeEntityPosition(PlayerPedId(), freeze_active)
        pluck.notify({
            header = "Freeze",
            type = freeze_active and "success" or "info",
            message = freeze_active and "Frozen." or "Unfrozen.",
            duration = 3000
        })
    end)
end

function teleport_to_waypoint()
    callbacks.trigger("rig:sv:admin_can_teleport_waypoint", {}, function(response)
        if not response or not response.allowed then
            pluck.notify({
                header = locale("admin.access_denied"),
                type = "error",
                message = locale("admin.no_permission_action"),
                duration = 4000
            })
            return
        end
        local blip = GetFirstBlipInfoId(8)
        if not DoesBlipExist(blip) then
            pluck.notify({
                header = "Teleport",
                type = "error",
                message = "No waypoint set.",
                duration = 3000
            })
            return
        end
        local ped = PlayerPedId()
        local coords = GetBlipInfoIdCoord(blip)
        local vehicle = GetVehiclePedIsIn(ped, false)
        local entity = vehicle > 0 and vehicle or ped
        local old_coords = GetEntityCoords(ped)
        local x, y = coords.x, coords.y
        local ground_z = 850.0
        local found = false
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
        FreezeEntityPosition(entity, true)
        for i = 950.0, 0, -25.0 do
            local z = (i % 2) ~= 0 and (950.0 - i) or i
            NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
            local t = GetGameTimer()
            while IsNetworkLoadingScene() do
                if GetGameTimer() - t > 1000 then break end
                Wait(0)
            end
            NewLoadSceneStop()
            SetPedCoordsKeepVehicle(ped, x, y, z)
            local t2 = GetGameTimer()
            while not HasCollisionLoadedAroundEntity(ped) do
                RequestCollisionAtCoord(x, y, z)
                if GetGameTimer() - t2 > 1000 then break end
                Wait(0)
            end
            found, ground_z = GetGroundZFor_3dCoord(x, y, z, false)
            if found then
                SetPedCoordsKeepVehicle(ped, x, y, ground_z)
                break
            end
            Wait(0)
        end
        FreezeEntityPosition(entity, false)
        DoScreenFadeIn(500)
        if not found then
            SetPedCoordsKeepVehicle(ped, old_coords.x, old_coords.y, old_coords.z)
            pluck.notify({header = "Teleport", type = "error", message = "Could not find ground, returned to original position.", duration = 3000})
            return
        end
        pluck.notify({header = "Teleport", type = "success", message = "Teleported to waypoint.", duration = 3000})
    end)
end

function teleport_to_coords()
    callbacks.trigger("rig:sv:admin_can_teleport_coords", {}, function(response)
        if not response or not response.allowed then
            pluck.notify({header = locale("admin.access_denied"), type = "error", message = locale("admin.no_permission_action"), duration = 4000})
            return
        end
        drip.close_menu("admin")
        CreateThread(function()
            local input = get_keyboard_input("Enter coords: x, y, z")
            if not input then open_admin_menu() return end
            local x, y, z = input:match("([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+)")
            x, y, z = tonumber(x), tonumber(y), tonumber(z)
            if not x or not y or not z then
                pluck.notify({header = "Teleport", type = "error", message = "Invalid format. Use: x, y, z", duration = 3000})
                open_admin_menu()
                return
            end
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            local entity = vehicle > 0 and vehicle or ped
            local old_coords = GetEntityCoords(ped)
            local found = false
            local ground_z = 850.0
            DoScreenFadeOut(500)
            while not IsScreenFadedOut() do Wait(0) end
            FreezeEntityPosition(entity, true)
            for i = 950.0, 0, -25.0 do
                local zi = (i % 2) ~= 0 and (950.0 - i) or i
                NewLoadSceneStart(x, y, zi, x, y, zi, 50.0, 0)
                local t = GetGameTimer()
                while IsNetworkLoadingScene() do
                    if GetGameTimer() - t > 1000 then break end
                    Wait(0)
                end
                NewLoadSceneStop()
                SetPedCoordsKeepVehicle(ped, x, y, zi)
                local t2 = GetGameTimer()
                while not HasCollisionLoadedAroundEntity(ped) do
                    RequestCollisionAtCoord(x, y, zi)
                    if GetGameTimer() - t2 > 1000 then break end
                    Wait(0)
                end
                found, ground_z = GetGroundZFor_3dCoord(x, y, zi, false)
                if found then
                    SetPedCoordsKeepVehicle(ped, x, y, ground_z)
                    break
                end
                Wait(0)
            end
            FreezeEntityPosition(entity, false)
            DoScreenFadeIn(500)
            if not found then
                SetPedCoordsKeepVehicle(ped, old_coords.x, old_coords.y, old_coords.z)
                pluck.notify({header = "Teleport", type = "error", message = "Could not find ground, returned to original position.", duration = 3000})
                open_admin_menu()
                return
            end
            pluck.notify({header = "Teleport", type = "success", message = ("Teleported to %.1f, %.1f, %.1f"):format(x, y, ground_z), duration = 3000})
            open_admin_menu()
        end)
    end)
end

function revive_self()
    callbacks.trigger("rig:sv:admin_revive_self", {}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "no_hook" and "No revive hook configured." or locale("admin.no_permission_action")
            pluck.notify({header = "Revive", type = "error", message = msg, duration = 4000})
            return
        end
        pluck.notify({header = "Revive", type = "success", message = "You revived yourself.", duration = 3000})
    end)
end

function kill_self()
    callbacks.trigger("rig:sv:admin_kill_self", {}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "no_hook" and "No kill hook configured." or locale("admin.no_permission_action")
            pluck.notify({header = "Kill", type = "error", message = msg, duration = 4000})
            return
        end
        pluck.notify({header = "Kill", type = "success", message = "You killed yourself.", duration = 3000})
    end)
end

--- @section Vehicle Actions 

function spawn_vehicle()
    drip.close_menu("admin")
    CreateThread(function()
        local input = get_keyboard_input("Enter vehicle model name")
        if not input or input == "" then open_admin_menu() return end
        callbacks.trigger("rig:sv:admin_spawn_vehicle", {model = input:lower()}, function(r)
            if not r or not r.success then
                local msg = r and r.reason == "no_permission" and locale("admin.no_permission_action") or "Failed to spawn vehicle. Check model name."
                pluck.notify({header = "Spawn Vehicle", type = "error", message = msg, duration = 3000})
                open_admin_menu()
                return
            end
            local timeout = GetGameTimer() + 5000
            repeat Wait(100) until NetworkDoesEntityExistWithNetworkId(r.net_id) or GetGameTimer() > timeout
            local vehicle = NetToVeh(r.net_id)
            if vehicle and vehicle ~= 0 then
                local ped = PlayerPedId()
                local current = GetVehiclePedIsIn(ped, false)
                if current ~= 0 then DeleteVehicle(current) end
                SetPedIntoVehicle(ped, vehicle, -1)
                pluck.notify({header = "Spawn Vehicle", type = "success", message = ("Spawned: %s"):format(input:lower()), duration = 3000})
            else
                pluck.notify({header = "Spawn Vehicle", type = "error", message = "Vehicle spawned but could not be found.", duration = 3000})
            end
            open_admin_menu()
        end)
    end)
end

function delete_vehicle()
    callbacks.trigger("rig:sv:admin_delete_vehicle", {}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "not_in_vehicle" and "You are not in a vehicle." or locale("admin.no_permission_action")
            pluck.notify({header = "Delete Vehicle", type = "error", message = msg, duration = 3000})
            return
        end
        pluck.notify({header = "Delete Vehicle", type = "success", message = "Vehicle deleted.", duration = 3000})
    end)
end

function repair_vehicle()
    callbacks.trigger("rig:sv:admin_repair_vehicle", {}, function(r)
        if not r or not r.success then
            pluck.notify({header = "Repair", type = "error", message = locale("admin.no_permission_action"), duration = 3000})
            return
        end
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if not vehicle or vehicle == 0 then
            pluck.notify({header = "Repair", type = "error", message = "You are not in a vehicle.", duration = 3000})
            return
        end
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        SetVehicleFuelLevel(vehicle, 100.0)
        pluck.notify({header = "Repair", type = "success", message = "Vehicle repaired.", duration = 3000})
    end)
end

function show_vehicle_panel()
    drip.show_panel({
        id = "dam_vehicle_info",
        title = "Vehicle Info",
        style = {x = 0.015, y = 0.35, width = 0.16},
        lines = {
            {key = "Model", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return vehicles.get_model(veh)
            end},
            {key = "Class", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return vehicles.get_class(veh)
            end},
            {key = "Plate", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return vehicles.get_plate(veh)
            end},
            {key = "Body", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.0f%%", (GetVehicleBodyHealth(veh) / 1000) * 100)
            end},
            {key = "Engine", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.0f%%", (GetVehicleEngineHealth(veh) / 1000) * 100)
            end},
            {key = "Tank", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.0f%%", (GetVehiclePetrolTankHealth(veh) / 1000) * 100)
            end},
            {key = "Fuel", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.0f%%", GetVehicleFuelLevel(veh))
            end},
            {key = "Oil", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.0f%%", (GetVehicleOilLevel(veh) / 1000) * 100)
            end},
            {key = "Dirt", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.1f", GetVehicleDirtLevel(veh))
            end},
            {key = "Eng. Temp", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.1f°", GetVehicleEngineTemperature(veh))
            end},
            {key = "Turbo", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.2f", GetVehicleTurboPressure(veh))
            end},
            {key = "Max Speed", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.1f", vehicles.get_class_stats(veh).max_speed)
            end},
            {key = "Acceleration", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.2f", vehicles.get_class_stats(veh).max_acceleration)
            end},
            {key = "Agility", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.2f", vehicles.get_class_stats(veh).max_agility)
            end},
            {key = "Braking", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.2f", vehicles.get_class_stats(veh).max_braking)
            end},
            {key = "Traction", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.2f", vehicles.get_class_stats(veh).max_traction)
            end},
        }
    })
end

--- @section Global Functions

function remove_ban(unique_id)
    callbacks.trigger("rig:sv:admin_remove_ban", {unique_id = unique_id}, function(r)
        if not r or not r.success then
            pluck.notify({header = "Unban", type = "error", message = locale("admin.no_permission_action"), duration = 4000})
            return
        end
        pluck.notify({header = "Unban", type = "success", message = "Player unbanned.", duration = 3000})
        callbacks.trigger("rig:sv:admin_get_ban_list", {}, function(res)
            if not res then return end
            drip.close_menu("admin_bans")
            players_menu.open_ban_menu(res.bans)
        end)
    end)
end

function get_keyboard_input(title, max_length)
    AddTextEntry("FMMC_KEY_TIP1", title)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", "", "", "", "", max_length or 20)
    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end
    if UpdateOnscreenKeyboard() == 1 then
        return GetOnscreenKeyboardResult()
    end
    return nil
end

function open_admin_menu()
    if drip.is_menu_open("admin") then
        drip.close_menu("admin")
        drip.close_menu("admin_players")
        drip.close_menu("admin_bans")
        return
    end
    drip.open_menu({
        id = "admin",
        root = "main",
        menus = {
            main = {
                title = "Admin Menu",
                items = {
                    { type = "submenu", label = "Self", desc = "Perform actions on yourself.", submenu = "user" },
                    { type = "submenu", label = "Players", desc = "Perform actions and check bans.", submenu = "players" },
                    { type = "submenu", label = "Vehicles", desc = "Perform vehicle actions.", submenu = "vehicles" },
                    { type = "separator" },
                    { type = "close", label = "Close", desc = "Close the menu." },
                },
            },
            user = admin_menu.build_user_menu(),
            players = admin_menu.build_players_menu(),
            vehicles = admin_menu.build_vehicles_menu()
        }
    })
end

--- @section Events

RegisterNetEvent("rig:cl:player_warned", function(reason)
    pluck.notify({header = "Warning", type = "error", message = "You have been warned: " .. reason, duration = 6000})
end)

--- @section Commands

RegisterKeyMapping("admin", "Open Admin Menu", "keyboard", "F9")
RegisterCommand("admin", function()
    callbacks.trigger("rig:sv:admin_can_open_menu", {}, function(response)
        if not response or not response.allowed then
            pluck.notify({header = locale("admin.access_denied"), type = "error", message = locale("admin.no_permission"), duration = 4000})
            return
        end
        open_admin_menu()
    end)
end, false)

--- @section Threads

CreateThread(function()
    local key_list = keys.get_keys()
    while true do
        Wait(0)
        if noclip_active and noclip_cam then
            local mx = GetDisabledControlNormal(0, 1)
            local my = GetDisabledControlNormal(0, 2)
            local rot = GetCamRot(noclip_cam, 2)
            local new_z = rot.z - mx * 5.0
            local new_x = math.max(-89.0, math.min(89.0, rot.x - my * 5.0))
            SetCamRot(noclip_cam, new_x, 0.0, new_z, 2)
            local rad_z = math.rad(new_z)
            local rad_x = math.rad(new_x)
            local fx = -math.sin(rad_z) * math.cos(rad_x)
            local fy =  math.cos(rad_z) * math.cos(rad_x)
            local fz =  math.sin(rad_x)
            local rx = -math.sin(math.rad(new_z - 90.0))
            local ry =  math.cos(math.rad(new_z - 90.0))
            if is_pressed(2, 15) then
                noclip_speed_mult = math.min(SCROLL_MAX, noclip_speed_mult + SCROLL_STEP)
            elseif is_pressed(2, 14) then
                noclip_speed_mult = math.max(SCROLL_MIN, noclip_speed_mult - SCROLL_STEP)
            end
            local top_speed = BASE_SPEED * noclip_speed_mult
            local accel = BASE_ACCEL * noclip_speed_mult
            if is_pressed(0, key_list["leftcontrol"]) then
                top_speed = SLOW_SPEED
                accel = BASE_ACCEL * 0.5
            elseif is_pressed(0, key_list["leftshift"]) then
                top_speed = BASE_SPEED * FAST_MULT * noclip_speed_mult
                accel = BASE_ACCEL * 4.0
            end
            local input = vector3(0.0, 0.0, 0.0)
            if is_pressed(0, key_list["w"]) then input = input + vector3(fx, fy, fz) end
            if is_pressed(0, key_list["s"]) then input = input - vector3(fx, fy, fz) end
            if is_pressed(0, key_list["a"]) then input = input - vector3(rx, ry, 0.0) end
            if is_pressed(0, key_list["d"]) then input = input + vector3(rx, ry, 0.0) end
            if is_pressed(0, key_list["q"]) then input = input + vector3(0.0, 0.0, 1.0) end
            if is_pressed(0, key_list["z"]) then input = input - vector3(0.0, 0.0, 1.0) end
            noclip_vel = noclip_vel + input * accel
            local spd = math.sqrt(noclip_vel.x^2 + noclip_vel.y^2 + noclip_vel.z^2)
            if spd > top_speed then
                noclip_vel = noclip_vel * (top_speed / spd)
            end
            noclip_vel = noclip_vel * FRICTION
            local pos = GetCamCoord(noclip_cam)
            local new_pos = vector3(pos.x + noclip_vel.x, pos.y + noclip_vel.y, pos.z + noclip_vel.z)
            SetCamCoord(noclip_cam, new_pos.x, new_pos.y, new_pos.z)
            SetEntityCoordsNoOffset(PlayerPedId(), new_pos.x, new_pos.y, new_pos.z, false, false, false)
            DisableAllControlActions(0)
        end
    end
end)