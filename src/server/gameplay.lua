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

local cfg_statuses = require("configs.statuses")
local cfg_weather = require("configs.weather")

--- @section Constants

local TICK_RATE = cfg_statuses.tick_rate or 5000
local DELTA = TICK_RATE / 1000
local PLAYER_SAVE = core.convars.player_save_interval * 60 * 1000 or (5 * 60 * 100)
local WEATHER_SYNC = cfg_weather.update_interval * 60 * 1000 or (7 * 60 * 100)
local WEATHER_SAVE = cfg_weather.save_interval * 60 * 1000 or (30 * 60 * 100)

--- @section Statuses

CreateThread(function()
    while true do
        for source, player in pairs(core.players:get_all()) do
            if type(player.is_playing) == "function" and player:is_playing() then
                local ext = player:get_extension("statuses")
                if ext and ext.on_tick then 
                    ext:on_tick(DELTA) 
                end
            end
        end
        Wait(TICK_RATE)
    end
end)

--- @section Save

CreateThread(function()
    while true do
        Wait(PLAYER_SAVE)
        core.players:save_all()
    end
end)

--- @section Weather

CreateThread(function()
    local last_tick = GetGameTimer()
    local last_save = GetGameTimer()
    while true do
        local now = GetGameTimer()
        local delta_ms = now - last_tick
        last_tick = now
        for bucket_id, env in pairs(core.bucket_environments) do
            if env.dynamic_time then
                core.advance_bucket_time(bucket_id, delta_ms)
            end
            if now % WEATHER_SYNC < delta_ms then
                if env.dynamic_weather and not env.freeze_weather then
                    if math.random(100) <= (cfg_weather.weather_change_probability or 5) then
                        local season_list = cfg_weather.seasons[env.season]
                        local new_weather = season_list[math.random(#season_list)]
                        if new_weather ~= env.weather then
                            env.weather = new_weather
                            core.update_weather_effects(env, new_weather)
                        end
                    end
                end
                core.sync_bucket_environment(bucket_id)
            end
            if now - last_save >= WEATHER_SAVE then
                core.save_bucket_weather(bucket_id)
            end
        end
        if now - last_save >= WEATHER_SAVE then last_save = now end
        Wait(1000) 
    end
end)