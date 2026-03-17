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

--- @file src.server.api
--- @description Handles all server side API registration.
--- Required due to cross resource usage, class functions do not like exports to keep it simple.
--- You have two options: 
--- `local rig = exports.rig:api()` then call functions `rig.save_player(source)`
--- or `exports.rig:save_player(source)` to use exports directly 

--- @section Imports

local cfg_weather = require("configs.weather")

--- @section API

function core.get_weather_config()
    return cfg_weather
end
exports("get_weather_config", core.get_weather_config)

function core.get_bucket_environment(bucket_id)
    return core.bucket_environments[bucket_id]
end
exports("get_bucket_environment", core.get_bucket_environment)

function core.save_bucket_weather(bucket_id)
    local env_data = core.bucket_environments[bucket_id]
    if not env_data then return end
    local file_content = "return {\n"
    file_content = file_content .. string.format("    weather = %q,\n", env_data.weather)
    file_content = file_content .. string.format("    hour = %d,\n", env_data.hour)
    file_content = file_content .. string.format("    minute = %d,\n", env_data.minute)
    file_content = file_content .. string.format("    day = %d,\n", env_data.day)
    file_content = file_content .. string.format("    month = %d,\n", env_data.month)
    file_content = file_content .. string.format("    year = %d,\n", env_data.year)
    file_content = file_content .. string.format("    season = %q,\n", env_data.season)
    file_content = file_content .. "}\n"
    SaveResourceFile(GetCurrentResourceName(), "src/_database/weather/bucket_" .. bucket_id .. ".lua", file_content, -1)
end
exports("save_bucket_weather", core.save_bucket_weather)

function core.load_bucket_weather(bucket_id, bucket_config)
    local file_path = "src/_database/weather/bucket_" .. bucket_id .. ".lua"
    local file_content = LoadResourceFile(GetCurrentResourceName(), file_path)
    if not file_content then core.save_bucket_weather(bucket_id) return end
    local ok, data = pcall(function() return load(file_content, "@@" .. file_path, "t", {})() end)
    if not ok or not data then core.save_bucket_weather(bucket_id) return end
    local env = core.bucket_environments[bucket_id]
    env.weather = data.weather or bucket_config.weather
    env.hour = data.hour or bucket_config.hour
    env.minute = data.minute or bucket_config.minute
    env.day = data.day or 1
    env.month = data.month or 1
    env.year = data.year or 2026
    env.season = data.season or bucket_config.season
    log("info", ("Loaded bucket %d state from disk"):format(bucket_id))
end
exports("load_bucket_weather", core.load_bucket_weather)

function core.resolve_weather_bucket_id(bucket_identifier)
    if type(bucket_identifier) == "number" then
        return core.bucket_environments[bucket_identifier] and bucket_identifier or nil
    end
    for bucket_name, bucket_config in pairs(cfg_buckets) do
        if bucket_name == bucket_identifier or bucket_config.label == bucket_identifier then
            return bucket_config.bucket
        end
    end
    return nil
end
exports("resolve_weather_bucket_id", core.resolve_weather_bucket_id)

function core.get_current_season(month)
    local seasons = {
        [0] = "WINTER", [1] = "WINTER", [2] = "WINTER",
        [3] = "SPRING", [4] = "SPRING", [5] = "SPRING",
        [6] = "SUMMER", [7] = "SUMMER", [8] = "SUMMER",
        [9] = "AUTUMN", [10] = "AUTUMN", [11] = "AUTUMN"
    }
    return seasons[month] or "WINTER"
end
exports("get_current_season", core.get_current_season)

function core.get_sunrise_sunset(weather)
    local cfg = cfg_weather.types[weather]
    return cfg and cfg.sun or { rise = 6, set = 18 }
end
exports("get_sunrise_sunset", core.get_sunrise_sunset)

function core.is_daytime(hour)
    local r = cfg_weather.time_ranges.daytime
    return hour >= r.start and hour < r.stop
end
exports("is_daytime", core.is_daytime)

function core.is_nighttime(hour)
    local r = cfg_weather.time_ranges.nighttime
    return hour >= r.start or hour < r.stop
end
exports("is_nighttime", core.is_nighttime)

function core.is_midday(hour)
    local r = cfg_weather.time_ranges.midday
    return hour >= r.start and hour <= r.stop
end
exports("is_midday", core.is_midday)

function core.calculate_temperature(hour, weather, season)
    local cfg = cfg_weather
    local type_cfg = cfg.types[weather] or cfg.types.CLEAR
    local base = type_cfg.temp.base + (cfg.seasonal_temp_offset[season] or 0)
    local mult = (hour >= 6 and hour < 12) and (0.7 + (hour - 6) / 6 * 0.3) or (hour >= 12 and hour < 18) and 1.0 or (hour >= 18 and hour < 21) and (1.0 - (hour - 18) / 3 * 0.35) or type_cfg.temp.night_mult
    return math.floor(base * mult * 10) / 10
end
exports("calculate_temperature", core.calculate_temperature)

function core.update_weather_effects(env_data, weather)
    local cfg = cfg_weather.types[weather] or cfg_weather.types.CLEAR
    local fx = cfg.effects
    local function get_val(val)
        return type(val) == "table" and (math.random(val[1], val[2]) / 100) or val
    end
    env_data.rain_level = get_val(fx.rain)
    env_data.snow_level = get_val(fx.snow)
    env_data.wind_speed = get_val(fx.wind)
end
exports("update_weather_effects", core.update_weather_effects)

function core.advance_bucket_time(bucket_id, ms_passed)
    local env = core.bucket_environments[bucket_id]
    if not env.dynamic_time then return end
    env.minute = env.minute + (ms_passed / 1000) * (24 * 60) / (cfg_weather.real_minutes_per_gta_day * 60)
    while env.minute >= 60 do
        env.minute = env.minute - 60
        env.hour = env.hour + 1
        if env.hour >= 24 then
            env.hour = 0
            env.day = env.day + 1
            if env.day > 30 then
                env.day = 1
                env.month = (env.month + 1) % 12
            end
        end
    end
end
exports("advance_bucket_time", core.advance_bucket_time)

function core.build_environment_data(bucket_id)
    local env = core.bucket_environments[bucket_id]
    local ss = core.get_sunrise_sunset(env.weather)
    return {
        weather = env.weather,
        hour = env.hour,
        minute = env.minute,
        day = env.day,
        month = env.month,
        year = env.year,
        season = env.season,
        rain_level = env.rain_level,
        snow_level = env.snow_level,
        wind_speed = env.wind_speed,
        wind_direction = env.wind_direction,
        sunrise = ss.sunrise,
        sunset = ss.sunset,
        temperature = core.calculate_temperature(env.hour, env.weather, env.season),
        transition_time = cfg_weather.transition_time,
        is_daytime = core.is_daytime(env.hour),
        is_nighttime = core.is_nighttime(env.hour),
        is_midday = core.is_midday(env.hour)
    }
end
exports("build_environment_data", core.build_environment_data)

function core.sync_bucket_environment(bucket_id)
    local env_data = core.build_environment_data(bucket_id)
    for _, player in ipairs(GetPlayers()) do
        if GetPlayerRoutingBucket(player) == bucket_id then
            TriggerClientEvent("rig:cl:set_environment", player, env_data)
        end
    end
end
exports("sync_bucket_environment", core.sync_bucket_environment)

function core.sync_player_weather(source, bucket_id)
    local env_data = core.build_environment_data(bucket_id)
    if not env_data then log("error", locale("weather.server.environment_data_missing", bucket_id)) return end
    TriggerClientEvent("rig:cl:set_environment", source, env_data)
end
exports("sync_player_weather", core.sync_player_weather)