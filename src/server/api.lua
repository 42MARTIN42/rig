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

--- @section User Accounts *(rig_players)*

function core.get_user(source)
    local p = core.players:get(source)
    if not p then return nil end
    return getmetatable(p) and p.user_data or p
end
exports("get_user", core.get_user)

function core.update_user_data(source, updates)
    local p = core.players:get(source)
    if not p then return false end
    local user = getmetatable(p) and p.user_data or p
    for key, value in pairs(updates) do
        if user[key] ~= nil then user[key] = value end
    end
    local update_keys = {}
    local update_values = {}
    for key, value in pairs(updates) do
        table.insert(update_keys, string.format("`%s` = ?", key))
        table.insert(update_values, type(value) == "table" and json.encode(value) or value)
    end
    if #update_keys == 0 then return false end
    table.insert(update_values, user.license)
    MySQL.prepare.await(string.format("UPDATE rig_players SET %s WHERE license = ?", table.concat(update_keys, ", ")), update_values)
    return true
end
exports("update_user_data", core.update_user_data)

--- @section Player State

function core.create_player(source)
    local player = core.players:create(source)
    if player then TriggerEvent("rig:sv:player_loaded", player) end
    return player
end
exports("create_player", core.create_player)

function core.get_players()
    return core.players:get_all()
end
exports("get_players", core.get_players)

function core.get_player(source)
    return core.players:get(source)
end
exports("get_player", core.get_player)

function core.save_player(source)
    local p = core.players:get(source)
    return p and p:save()
end
exports("save_player", core.save_player)

function core.is_player_loaded(source)
    local p = core.players:get(source)
    return p and p:has_loaded() or false
end
exports("is_player_loaded", core.is_player_loaded)

function core.is_player_playing(source)
    local p = core.players:get(source)
    return p and p:is_playing() or false
end
exports("is_player_playing", core.is_player_playing)

function core.set_player_playing(source, state)
    local p = core.players:get(source)
    if p then p:set_playing(state) end
end
exports("set_player_playing", core.set_player_playing)

--- @section Player Data

function core.update_user_data(source, updates)
    local p = core.players:get(source)
    return p and p:update_user_data(updates) or false
end
exports("update_user_data", core.update_user_data)

function core.get_player_data(source, category)
    local p = core.players:get(source)
    return p and p:get_data(category) or nil
end
exports("get_player_data", core.get_player_data)

function core.set_player_data(source, category, updates, sync)
    local p = core.players:get(source)
    return p and p:set_data(category, updates, sync) or false
end
exports("set_player_data", core.set_player_data)

function core.add_player_data(source, category, value, replicate)
    local p = core.players:get(source)
    return p and p:add_data(category, value, replicate) or false
end
exports("add_player_data", core.add_player_data)

function core.has_player_data(source, category)
    local p = core.players:get(source)
    return p and p:has_data(category) or false
end
exports("has_player_data", core.has_player_data)

function core.replace_player_data(source, category, data, sync)
    local p = core.players:get(source)
    return p and p:replace_data(category, data, sync)
end
exports("replace_player_data", core.replace_player_data)

function core.remove_player_data(source, category)
    local p = core.players:get(source)
    if p then return p:remove_data(category) end
end
exports("remove_player_data", core.remove_player_data)

function core.sync_player_data(source, category)
    local p = core.players:get(source)
    if p then return p:sync(category) end
end
exports("sync_player_data", core.sync_player_data)

--- @section Player Methods

function core.run_player_method(source, name, ...)
    local p = core.players:get(source)
    return p and p:run_method(name, ...)
end
exports("run_player_method", core.run_player_method)

function core.add_player_method(source, name, fn)
    local p = core.players:get(source)
    return p and p:add_method(name, fn) or false
end
exports("add_player_method", core.add_player_method)

function core.remove_player_method(source, name, fn)
    local p = core.players:get(source)
    return p and p:remove_method(name, fn) or false
end
exports("remove_player_method", core.remove_player_method)

function core.has_player_method(source, name)
    local p = core.players:get(source)
    return p and p:has_method(name) or false
end
exports("has_player_method", core.has_player_method)

function core.get_player_method(source, name)
    local p = core.players:get(source)
    return p and p:get_method(name) or false
end
exports("get_player_method", core.get_player_method)

--- @section Player Extensions

function core.add_player_extension(source, name, ext)
    local p = core.players:get(source)
    return p and p:add_extension(name, ext) or false
end
exports("add_player_extension", core.add_player_extension)

function core.remove_player_extension(source, name, ext)
    local p = core.players:get(source)
    return p and p:remove_extension(name, ext) or false
end
exports("remove_player_extension", core.remove_player_extension)

function core.get_player_extension(source, name)
    local p = core.players:get(source)
    return p and p:get_extension(name) or nil
end
exports("get_player_extension", core.get_player_extension)

function core.has_player_extension(source, name)
    local p = core.players:get(source)
    return p and p:has_extension(name) or false
end
exports("has_player_extension", core.has_player_extension)

--- @section Player Debugging

function core.dump_player_data(source)
    local p = core.players:get(source)
    if p then p:dump_data() end
end
exports("dump_player_data", core.dump_player_data)

function core.list_player_extensions(source)
    local p = core.players:get(source)
    return p and p:list_extensions() or {}
end
exports("list_player_extensions", core.list_player_extensions)

--- @section Objects

function core.place_object(source, data)
    local user = core.get_user(source)
    if not user then return end
    core.objects:place(source, data, user)
end
exports("place_object", core.place_object)

function core.remove_object(source, id)
    local user = core.get_user(source)
    if not user then return end
    core.objects:remove(source, id, user)
end
exports("remove_object", core.remove_object)

function core.use_object(source, id, key)
    core.objects:use(source, id, key)
end
exports("use_object", core.use_object)

--- @section Weather

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