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
local utils = require("src.server.modules.utils")

--- @section Public Commands

commands.register({
    name = "id",
    help = "Check your current server ID.",
    params = {},
    handler = function(source)
        pluck.notify(source, { type = "info", header = locale("commands.notify_header"), message = locale("commands.id", source), duration = 5000 })
    end
})

commands.register({
    name = "disconnect",
    help = "Disconnect from the server.",
    params = {},
    handler = function(source)
        pluck.notify(source, { type = "info", header = locale("commands.notify_header"), message = locale("commands.disconnecting"), duration = 2500 })
        Wait(2500)
        DropPlayer(source, locale("commands.disconnected"))
    end
})

--- @section Staff Commands

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

commands.register({
    ace = "rig.dev",
    name = "rig:revive",
    help = "Revive yourself or a player.",
    params = {
        { name = "id", help = "Players server ID (optional)" }
    },
    handler = function(source, args)
        local target = tonumber(args[1]) or source
        local player = core.players:get(target)
        if not player then
            pluck.notify(source, { type = "error", header = locale("statuses.commands.notify_header"), message = locale("statuses.commands.player_not_found"), duration = 5000 })
            return
        end
        player:run_method("revive_player")
        pluck.notify(source, { type = "success", header = locale("statuses.commands.notify_header"), message = locale("statuses.commands.player_revived", target), duration = 5000 })
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:kill",
    help = "Kill yourself or a player.",
    params = {
        { name = "id", help = "Player server ID (optional)" }
    },
    handler = function(source, args)
        local target = tonumber(args[1]) or source
        local player = core.players:get(target)
        if not player then
            pluck.notify(source, { type = "error", header = locale("statuses.notify_header"), message = locale("statuses.commands.player_not_found"), duration = 5000 })
            return
        end
        rig:run_method("kill_player")
        pluck.notify(source, { type = "success", header = locale("statuses.commands.notify_header"), message = locale("statuses.commands.player_killed", target), duration = 5000 })
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:down",
    help = "Down yourself or a player.",
    params = {
        { name = "id", help = "Player server ID (optional)" }
    },
    handler = function(source, args)
        local target = tonumber(args[1]) or source
        local player = core.players:get(target)
        if not player then
            pluck.notify(source, { type = "error", header = locale("statuses.commands.notify_header"), message = locale("statuses.commands.player_not_found"), duration = 5000 })
            return
        end
        rig:run_method("down_player")
        pluck.notify(source, { type = "success", header = locale("statuses.commands.notify_header"), message = locale("statuses.commands.player_downed", target), duration = 5000 })
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:setweather",
    help = "Set weather for a bucket.",
    params = {
        { name = "type", help = "Weather type." },
        { name = "bucket", help = "Bucket ID or name (optional)." }
    },
    handler = function(source, args)
        local weather_type = args[1]
        if not weather_type then
            pluck.notify(source, { type = "error", header = locale("weather.server.notify_header"), message = locale("weather.server.weather_usage"), duration = 5000 })
            return
        end
        local env, bucket_id = get_env_or_notify(source, args[2] or 0)
        if not env then return end
        weather_type = weather_type:upper()
        env.weather = weather_type
        core.update_weather_effects(env, weather_type)
        core.sync_bucket_environment(bucket_id)
        pluck.notify(source, { type = "success", header = locale("weather.server.notify_header"), message = locale("weather.server.weather_set", weather_type, bucket_id), duration = 5000 })
        log("info", locale("weather.server.admin_weather_changed", GetPlayerName(source), weather_type, bucket_id))
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:settime",
    help = "Set time for a bucket.",
    params = {
        { name = "hour", help = "Hour (0-23)." },
        { name = "minute", help = "Minute (0-59)." },
        { name = "bucket", help = "Bucket ID or name (optional)." }
    },
    handler = function(source, args)
        local hour = tonumber(args[1])
        local minute = tonumber(args[2])
        if not hour or not minute or hour < 0 or hour > 23 or minute < 0 or minute > 59 then
            pluck.notify(source, { type = "error", header = locale("weather.server.notify_header"), message = locale("weather.server.time_usage"), duration = 5000 })
            return
        end
        local env, bucket_id = get_env_or_notify(source, args[3] or 0)
        if not env then return end
        env.hour = hour
        env.minute = minute
        core.sync_bucket_environment(bucket_id)
        pluck.notify(source, { type = "success", header = locale("weather.server.notify_header"), message = locale("weather.server.time_set", hour, minute, bucket_id), duration = 5000 })
        log("info", locale("weather.server.admin_time_changed", GetPlayerName(source), hour, minute, bucket_id))
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:setseason",
    help = "Set season for a bucket.",
    params = {
        { name = "season", help = "Season name." },
        { name = "bucket", help = "Bucket ID or name (optional)." }
    },
    handler = function(source, args)
        local season = args[1]
        if not season then
            pluck.notify(source, { type = "error", header = locale("weather.server.notify_header"), message = locale("weather.server.season_usage"), duration = 5000 })
            return
        end
        local env, bucket_id = get_env_or_notify(source, args[2] or 0)
        if not env then return end
        env.season = season:upper()
        pluck.notify(source, { type = "success", header = locale("weather.server.notify_header"), message = locale("weather.server.season_set", season, bucket_id), duration = 5000 })
        log("info", locale("weather.server.admin_season_changed", GetPlayerName(source), season, bucket_id))
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:freezeweather",
    help = "Toggle weather freeze for a bucket.",
    params = {
        { name = "bucket", help = "Bucket ID or name (optional)." }
    },
    handler = function(source, args)
        local env, bucket_id = get_env_or_notify(source, args[1] or 0)
        if not env then return end
        env.freeze_weather = not env.freeze_weather
        local state = env.freeze_weather and "frozen" or "unfrozen"
        pluck.notify(source, { type = "success", header = locale("weather.server.notify_header"), message = locale("weather.server.weather_frozen", state, bucket_id), duration = 5000 })
        log("info", locale("weather.server.admin_freeze_toggled", GetPlayerName(source), state, bucket_id))
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:dynamicweather",
    help = "Toggle dynamic weather or time for a bucket.",
    params = {
        { name = "mode", help = "Mode: weather or time." },
        { name = "state", help = "State: on or off." },
        { name = "bucket", help = "Bucket ID or name (optional)." }
    },
    handler = function(source, args)
        local mode = args[1]
        local state = args[2]
        if not mode or not state or (mode ~= "weather" and mode ~= "time") or (state ~= "on" and state ~= "off") then
            pluck.notify(source, { type = "error", header = locale("weather.server.notify_header"), message = locale("weather.server.dynamic_usage"), duration = 5000 })
            return
        end
        local env, bucket_id = get_env_or_notify(source, args[3] or 0)
        if not env then return end
        local enabled = state == "on"
        if mode == "weather" then env.dynamic_weather = enabled else env.dynamic_time = enabled end
        pluck.notify(source, { type = "success", header = locale("weather.server.notify_header"), message = locale("weather.server.dynamic_toggled", mode, state, bucket_id), duration = 5000 })
        log("info", locale("weather.server.admin_dynamic_toggled", GetPlayerName(source), mode, state, bucket_id))
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:setrain",
    help = "Set rain level for a bucket.",
    params = {
        { name = "level", help = "Rain level (0.0-1.0)." },
        { name = "bucket", help = "Bucket ID or name (optional)." }
    },
    handler = function(source, args)
        local level = tonumber(args[1])
        if not level or level < 0 or level > 1 then
            pluck.notify(source, { type = "error", header = locale("weather.server.notify_header"), message = "Usage: /rig:setrain <0.0-1.0> [bucket]", duration = 5000 })
            return
        end
        local env, bucket_id = get_env_or_notify(source, args[2] or 0)
        if not env then return end
        env.rain_level = level
        core.sync_bucket_environment(bucket_id)
        pluck.notify(source, { type = "success", header = locale("weather.server.notify_header"), message = ("Rain set to %.2f for bucket %d."):format(level, bucket_id), duration = 5000 })
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:setsnow",
    help = "Set snow level for a bucket.",
    params = {
        { name = "level", help = "Snow level (0.0-1.0)." },
        { name = "bucket", help = "Bucket ID or name (optional)." }
    },
    handler = function(source, args)
        local level = tonumber(args[1])
        if not level or level < 0 or level > 1 then
            pluck.notify(source, { type = "error", header = locale("weather.server.notify_header"), message = "Usage: /rig:setsnow <0.0-1.0> [bucket]", duration = 5000 })
            return
        end
        local env, bucket_id = get_env_or_notify(source, args[2] or 0)
        if not env then return end
        env.snow_level = level
        core.sync_bucket_environment(bucket_id)
        pluck.notify(source, { type = "success", header = locale("weather.server.notify_header"), message = ("Snow set to %.2f for bucket %d."):format(level, bucket_id), duration = 5000 })
    end
})

commands.register({
    ace = "rig.dev",
    name = "rig:setwind",
    help = "Set wind speed for a bucket.",
    params = {
        { name = "speed", help = "Wind speed." },
        { name = "bucket", help = "Bucket ID or name (optional)." }
    },
    handler = function(source, args)
        local speed = tonumber(args[1])
        if not speed or speed < 0 then
            pluck.notify(source, { type = "error", header = locale("weather.server.notify_header"), message = "Usage: /rig:setwind <speed> [bucket]", duration = 5000 })
            return
        end
        local env, bucket_id = get_env_or_notify(source, args[2] or 0)
        if not env then return end
        env.wind_speed = speed
        core.sync_bucket_environment(bucket_id)
        pluck.notify(source, { type = "success", header = locale("weather.server.notify_header"), message = ("Wind speed set to %.2f for bucket %d."):format(speed, bucket_id), duration = 5000 })
    end
})

--- @section Test

RegisterCommand("testplayer", function(source)
    local _src = source
    local ids = utils.get_player_identifiers(_src)
    local result = core.players:exists(ids.license)
    
    if result and result[1] then
        local user_data = result[1]
        core.players:stage(ids.license, user_data)
        
        if core.players:activate(_src, ids.license) then
            core.players:assign_personal_bucket(_src)
            local player = core.create_player(_src)
            if player then 
                player:run_method("set_status", "playing", true)
                print(("^2[Test] Successfully forced initialization for source %s^7"):format(_src))
            end
        end
    else
        print("^1[Test] Failed: No database record found for license.^7")
    end
end, false)

RegisterCommand("weatherdemo", function(source)
    local bucket_id = 0
    local env = core.bucket_environments[bucket_id]
    if not env then return end

    CreateThread(function()
        env.season = "WINTER"
        local winter_sequence = {
            "SNOWLIGHT",
            "SNOW",
            "XMAS"
        }
        for i = 1, #winter_sequence do
            local w = winter_sequence[i]
            env.weather = w
            core.update_weather_effects(env, w)
            core.sync_environment(bucket_id)
            Wait(4000)
        end

        core.sync_environment(bucket_id)
    end)
end)

RegisterCommand("weather", function(source, args)
    local bucket_id = 0
    local env = core.bucket_environments[bucket_id]
    if not env then return end

    if not args[1] then
        print("Usage: /weather <type> [hour]")
        return
    end

    local weather_type = string.upper(args[1])
    local hour = tonumber(args[2])
    if hour then
        hour = math.max(0, math.min(23, hour))
        env.hour = hour
    end
    env.weather = weather_type
    core.update_weather_effects(env, weather_type)
    core.sync_environment(bucket_id)
    print(("Weather set to %s at %02d:00"):format(weather_type, env.hour))
end)

--- @section Test

RegisterCommand("testbed", function(source)
    local player = core.players:get(source)
    if not player then return end
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    player:run_method("set_spawn", "test_bed_01", {
        spawn_type = "bed",
        label = "Test Bed",
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = heading
    })
    print("Test bed saved for " .. player.unique_id)
end, false)

RegisterCommand("testsleeping", function(source)
    local player = core.players:get(source)
    if not player then return end
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    player:run_method("set_spawn", "test_bag_01", {
        spawn_type = "sleepingbag",
        label = "Test Sleepingbag",
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = heading
    })
    print("Test bag saved for " .. player.unique_id)
end, false)