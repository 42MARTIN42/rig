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

--- @module configs.zones
--- @description Handles all zones related config settings

return {
    
    --- Saltwater zones
    --- Drinking from water sources in any of these zones will trigger `saltwater_ingestion` effect on players
    --- Will also return saltwater on water collection not dirty
    saltwater = {
        OCEANA = true,   -- Pacific Ocean
        BEACH = true,    -- Vespucci Beach
        DELBE = true,    -- Del Perro Beach
        PROCOB = true,   -- Procopio Beach
        PALCOV = true,   -- Paleto Cove
        PALETO = true,   -- Paleto Bay
        NCHU = true,     -- North Chumash (coastal)
        CHU = true,      -- Chumash (coastal)
        ELGORL = true,   -- El Gordo Lighthouse (coastal)
        ELYSIAN = true,  -- Elysian Island (harbour/port)
        ZP_ORT = true,   -- Port of South Los Santos
        DELSOL = true,   -- La Puerta (coastal industrial)
        LOSPUER = true,  -- La Puerta duplicate
        TERMINA = true,  -- Terminal (port area)
        VCANA = true,    -- Vespucci Canals (tidal canals)
        LAGO = true,     -- Lago Zancudo (coastal lagoon)
        ISHeist = true,  -- Cayo Perico Island
    },

    --- Scumminess levels: https://docs.fivem.net/natives/?_0x5F7B268D15BA0739
    --- This is just a random native used by the game to calculate phone signal, returns a num 0 -> 5
    scumminess = {
        [0] = { -- Post
            water = { -- Water source effects
                statuses = { -- Status modifiers
                    thirst = 40 --Restores 40 thirst when drinking here
                },
                effects = { -- Player effects to apply
                    { 
                        id = "dysentry", -- Effect id connnects to `effects.lua`
                        chance = 10 -- Chance to apply it
                    }
                }
            }
        },
        [1] = { -- Nice
            water = {
                statuses = { thirst = 35 },
                effects = {
                    { id = "dysentry", chance = 15 }
                }
            }
        },
        [2] = { -- Above Average
            water = {
                statuses = { thirst = 30 },
                effects = {
                    { id = "dysentry", chance = 25 },
                    { id = "cholera", chance = 2 }
                }
            }
        },
        [3] = { -- Below Average
            water = {
                statuses = { thirst = 20, stress = 5 },
                effects = {
                    { id = "dysentry", chance = 40 },
                    { id = "cholera", chance = 10 }
                }
            }
        },
        [4] = { -- Crap
            water = {
                statuses = { thirst = 12, health = -2, stress = 10 },
                effects = {
                    { id = "dysentry", chance = 60 },
                    { id = "cholera", chance = 25 },
                    { id = "parasites", chance = 5 }
                }
            }
        },
        [5] = { -- Scum
            water = {
                statuses = { thirst = 5, health = -5, stress = 20 },
                effects = {
                    { id = "dysentry", chance = 85 },
                    { id = "cholera", chance = 45 },
                    { id = "parasites", chance = 20 }
                }
            }
        },
    }

}