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

--- @section Events

RegisterNetEvent("rig:cl:set_environment", function(data)
    SetWeatherTypeOvertimePersist(data.weather, data.transition_time)
    NetworkOverrideClockTime(data.hour, data.minute, 0)
    SetRainLevel(data.rain_level)
    SetSnowLevel(data.snow_level)
    SetWindSpeed(data.wind_speed)
end)