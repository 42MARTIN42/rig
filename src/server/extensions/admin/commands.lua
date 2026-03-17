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

--- @script src.server.commands
--- @description Handles all core commands for the framework.

--- @section Imports

local commands = require("libs.graft.fivem.commands")
local vehicles = require("libs.graft.fivem.vehicles")

--- @section Commands

commands.register({
    ace = "rig.dev",
    name = "rig:vehicle",
    help = "Spawn a vehicle at your location.",
    params = {
        { name = "model", help = "Vehicle model name." },
        { name = "enter", help = "Enter vehicle on spawn (true/false)." }
    },
    handler = function(source, args)
        local model = args[1]
        local should_enter = args[2] and (args[2]:lower() == "true" or args[2] == "1") or false
        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)
        local net_id = vehicles.spawn(model, { coords = vector4(coords.x + 5, coords.y, coords.z, GetEntityHeading(ped)), vehicle_type = "automobile", z_mod = 0 })
        if not net_id then
            pluck.notify(source, { type = "error", header = locale("commands.notify_header"), message = locale("commands.vehicle_spawn_failed"), duration = 2500 })
            return
        end
        if should_enter then
            Wait(50)
            local vehicle = NetworkGetEntityFromNetworkId(net_id)
            if vehicle and DoesEntityExist(vehicle) then TaskWarpPedIntoVehicle(ped, vehicle, -1) end
        end
        pluck.notify(source, { type = "success", header = locale("commands.notify_header"), message = locale("commands.vehicle_spawned"), duration = 2500 })
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:dv",
    help = "Delete the vehicle you are currently in.",
    handler = function(source, args)
        local ped = GetPlayerPed(source)
        local vehicle = GetVehiclePedIsIn(ped, false)
        if not vehicle or vehicle == 0 then
            pluck.notify(source, { type = "error", header = locale("commands.notify_header"), message = locale("commands.no_vehicle"), duration = 5000 })
            return
        end
        local net_id = NetworkGetNetworkIdFromEntity(vehicle)
        vehicles.delete(net_id)
        pluck.notify(source, { type = "success", header = locale("commands.notify_header"), message = locale("commands.vehicle_deleted"), duration = 5000 })
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:cv",
    help = "Delete all spawned vehicles.",
    params = {},
    handler = function(source)
        vehicles.clear()
        pluck.notify(source, { type = "success", header = locale("commands.notify_header"), message = locale("commands.vehicles_cleared"), duration = 5000 })
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:ban",
    help = "Ban a player.",
    params = {
        { name = "id", help = "Player server ID." },
        { name = "duration", help = "Duration in seconds (0 for permanent)." },
        { name = "reason", help = "Ban reason." }
    },
    handler = function(source, args)
        local target = tonumber(args[1])
        local duration = tonumber(args[2])
        local reason = args[3] or locale("commands.no_reason")
        if not target then
            pluck.notify(source, { type = "error", header = locale("commands.notify_header"), message = locale("commands.invalid_player_id"), duration = 5000 })
            return
        end
        core.ban(target, GetPlayerName(source), reason, duration == 0 and nil or duration)
        pluck.notify(source, { type = "success", header = locale("commands.notify_header"), message = locale("commands.player_banned", target), duration = 5000 })
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:unban",
    help = "Unban a player by unique ID.",
    params = {
        { name = "unique_id", help = "Player unique ID." }
    },
    handler = function(source, args)
        local unique_id = args[1]
        if not unique_id then
            pluck.notify(source, { type = "error", header = locale("commands.notify_header"), message = locale("commands.unique_id_required"), duration = 5000 })
            return
        end
        local success = core.unban(unique_id)
        pluck.notify(source, { type = success and "success" or "error", header = locale("commands.notify_header"), message = locale(success and "commands.player_unbanned" or "commands.unban_failed", unique_id), duration = 5000 })
    end
})