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

--- @file src.server.init
--- @description Handles server side initilization for the core

--- @section Players

local Players = require("src.server.registry.players")

core.players = Players.new()

--- If you add a custom internal extensions to the player core load them here.
core.player_extensions = {
    { name = "appearance", class = require("src.server.player.extensions.appearance"), priority = 100 },
    { name = "spawns", class = require("src.server.player.extensions.spawns"), priority = 99 },
    { name = "statuses", class = require("src.server.player.extensions.statuses"), priority = 98 },
    { name = "injuries", class = require("src.server.player.extensions.injuries"), priority = 97 },
    { name = "effects", class = require("src.server.player.extensions.effects"), priority = 96 },
}

function core.register_player_extension(name, fn, priority)
    core.players:register_extension(name, fn, priority)
end

exports("register_player_extension", core.register_player_extension)

for _, ext in ipairs(core.player_extensions) do
    core.register_player_extension(ext.name, function(player)
        local instance = setmetatable({ player = player }, { __index = ext.class })
        player:add_extension(ext.name, instance)
    end, ext.priority)
end

--- @section Objects

local Objects = require("src.server.registry.objects")

core.objects = Objects.new()

--- @section Weather + Buckets

local cfg_buckets = require("configs.buckets")
local cfg_weather = require("configs.weather")

core.bucket_environments = {}

SetTimeout(150, function()
    for bucket_name, bucket_config in pairs(cfg_buckets) do
        local bucket_id = bucket_config.bucket
        if bucket_config.mode then
            SetRoutingBucketEntityLockdownMode(bucket_id, bucket_config.mode)
        end
        if bucket_config.population_enabled ~= nil then
            SetRoutingBucketPopulationEnabled(bucket_id, bucket_config.population_enabled)
        end

        local init_season = bucket_config.season
        local init_weather = bucket_config.dynamic_weather and cfg_weather.seasons[init_season][math.random(1, #cfg_weather.seasons[init_season])] or bucket_config.weather
        local weather_type = cfg_weather.types[init_weather]
        local effects = weather_type and weather_type.effects

        local function resolve_effect(val)
            if type(val) == "table" then return math.random(val.min or val[1], val.max or val[2]) / 100 end
            return val or 0.0
        end

        core.bucket_environments[bucket_id] = {
            season = init_season,
            weather = init_weather,
            hour = bucket_config.dynamic_time and math.random(0, 23) or bucket_config.hour,
            minute = bucket_config.dynamic_time and math.random(0, 59) or bucket_config.minute,
            day = bucket_config.dynamic_time and math.random(1, 30) or bucket_config.day,
            month = bucket_config.month,
            year = bucket_config.year,
            rain_level = effects and resolve_effect(effects.rain) or 0.0,
            snow_level = effects and resolve_effect(effects.snow) or 0.0,
            wind_speed = effects and resolve_effect(effects.wind) or 0.5,
            wind_direction = math.random(0, 360),
            dynamic_weather = bucket_config.dynamic_weather,
            dynamic_time = bucket_config.dynamic_time,
            freeze_weather = bucket_config.freeze_weather
        }

        core.update_weather_effects(core.bucket_environments[bucket_id], init_weather)
        core.load_bucket_weather(bucket_id, bucket_config)
    end
end)