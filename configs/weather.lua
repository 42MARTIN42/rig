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

--- @module configs.weather
--- @description Handles all weather related config settings

return {
    
    real_minutes_per_gta_day = 42, -- Amount of real life mins should make up a day
    update_interval = 7, -- How often weather updates in mins
    save_interval = 30, -- How often weather saves in mins
    transition_time = 10, -- Weather transition time in seconds
    weather_change_probability = 5, -- Probability of weather changing each update interval (5%)
    wind_direction_change = { min = -15, max = 15 }, -- Wind variance min & max

    --- Seasonal weather types
    --- The system will only change between these weathers in the right season
    seasons = {
        WINTER = { "SNOW", "SNOWLIGHT", "BLIZZARD", "XMAS", "CLOUDS", "OVERCAST", "SNOW_HALLOWEEN" },
        SPRING = { "CLEAR", "EXTRASUNNY", "CLOUDS", "RAIN", "OVERCAST", "CLEARING", "NEUTRAL" },
        SUMMER = { "CLEAR", "EXTRASUNNY", "CLOUDS", "RAIN", "THUNDER", "NEUTRAL" },
        AUTUMN = { "CLEAR", "EXTRASUNNY", "CLOUDS", "OVERCAST", "RAIN", "CLEARING", "FOGGY", "SMOG", "HALLOWEEN", "RAIN_HALLOWEEN" }
    },

    --- Temperature offsets
    --- Offsets the current temperature based on the weather types  `temp.base` value `temp = { base = 14, night_mult = 0.75 },`
    seasonal_temp_offset = {
        WINTER = -8,
        SPRING = 2,
        SUMMER = 10,
        AUTUMN = -2
    },

    --- Time ranges
    --- Nothing important mainly just night time for temp modifiers
    time_ranges = {
        daytime = { start = 6, stop = 18 },
        nighttime = { start = 20, stop = 6 },
        midday = { start = 11, stop = 13 }
    },

    --- Weather types
    types = {
        CLEAR = { -- Unique weather type
            sun = { rise = 6, set = 18 }, -- The sunrise (sun.rise) and sunset (sun.set) time
            temp = { base = 18, night_mult = 0.6 }, -- The base temperature (temp.base) and night multiplier (temp.night_multi); night would be 10degrees
            effects = { -- Weather effects; number | { min, max }
                rain = 0.0, -- Rain level
                snow = 0.0, -- Snow level
                wind = { 5, 10 } -- Wind level { min, max }
            }
        },
        EXTRASUNNY = { 
            sun = { rise = 6, set = 18 },
            temp = { base = 22, night_mult = 0.65 },
            effects = { rain = 0.0, snow = 0.0, wind = { 3, 8 } }
        },
        CLOUDS = { 
            sun = { rise = 6.25, set = 17.75 },
            temp = { base = 16, night_mult = 0.7 },
            effects = { rain = 0.0, snow = 0.0, wind = { 5, 12 } }
        },
        OVERCAST = { 
            sun = { rise = 6.5, set = 17.5 },
            temp = { base = 14, night_mult = 0.75 },
            effects = { rain = 0.0, snow = 0.0, wind = { 8, 15 } }
        },
        RAIN = { 
            sun = { rise = 7, set = 17 },
            temp = { base = 12, night_mult = 0.8 },
            effects = { rain = { 30, 80 }, snow = 0.0, wind = { 10, 18 } }
        },
        THUNDER = { 
            sun = { rise = 7, set = 17 },
            temp = { base = 10, night_mult = 0.85 },
            effects = { rain = { 60, 100 }, snow = 0.0, wind = { 15, 25 } }
        },
        CLEARING = { 
            sun = { rise = 6.5, set = 17.5 },
            temp = { base = 13, night_mult = 0.75 },
            effects = { rain = { 5, 20 }, snow = 0.0, wind = { 8, 14 } }
        },
        FOGGY = { 
            sun = { rise = 7, set = 16.75 },
            temp = { base = 11, night_mult = 0.8 },
            effects = { rain = 0.0, snow = 0.0, wind = { 3, 10 } }
        },
        SMOG = { 
            sun = { rise = 7, set = 16.75 },
            temp = { base = 15, night_mult = 0.78 },
            effects = { rain = 0.0, snow = 0.0, wind = { 2, 8 } }
        },
        SNOW = { 
            sun = { rise = 8, set = 16 },
            temp = { base = -5, night_mult = 0.9 },
            effects = { rain = 0.0, snow = { 40, 80 }, wind = { 8, 16 } }
        },
        SNOWLIGHT = { 
            sun = { rise = 8, set = 16 },
            temp = { base = -2, night_mult = 0.88 },
            effects = { rain = 0.0, snow = { 20, 50 }, wind = { 5, 12 } }
        },
        BLIZZARD = { 
            sun = { rise = 9, set = 15 },
            temp = { base = -10, night_mult = 0.95 },
            effects = { rain = 0.0, snow = { 80, 100 }, wind = { 18, 30 } }
        },
        XMAS = { 
            sun = { rise = 8, set = 16 },
            temp = { base = -3, night_mult = 0.92 },
            effects = { rain = 0.0, snow = { 30, 60 }, wind = { 5, 12 } }
        },
        HALLOWEEN = { 
            sun = { rise = 7, set = 17 },
            temp = { base = 14, night_mult = 0.8 },
            effects = { rain = 0.0, snow = 0.0, wind = { 8, 16 } }
        },
        NEUTRAL = { 
            sun = { rise = 6, set = 18 },
            temp = { base = 16, night_mult = 0.7 },
            effects = { rain = 0.0, snow = 0.0, wind = { 4, 10 } }
        },
        RAIN_HALLOWEEN = { 
            sun = { rise = 7, set = 17 },
            temp = { base = 12, night_mult = 0.85 },
            effects = { rain = { 40, 90 }, snow = 0.0, wind = { 12, 20 } }
        },
        SNOW_HALLOWEEN = { 
            sun = { rise = 8, set = 16 },
            temp = { base = -4, night_mult = 0.92 },
            effects = { rain = 0.0, snow = { 50, 85 }, wind = { 10, 18 } }
        }
    }

}