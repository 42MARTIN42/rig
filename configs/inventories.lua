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

--- @module configs.inventories
--- @description Handles all static data for different inventory types.

return {

    --- @section Player

    pockets = {
        label = "Pockets",
        icon = "fa-solid fa-hand",
        is_player = true,
        columns = 10,
        rows = 2,
        max_weight = 20000,
        collapsible = true,
        collapsed = false,
    },

    dufflebag = {
        label = "Dufflebag",
        icon = "fa-solid fa-bag-shopping",
        is_player = true,
        columns = 10,
        rows = 5,
        max_weight = 60000,
        collapsible = true,
        collapsed = false,
    },

    --- @section Containers

    storage_crate = {
        prop = "prop_drop_crate_01",
        columns = 10,
        rows = 10,
        max_weight = 1000000,
        is_container = true,
        can_access = function(source, metadata)
            return true
        end
    },

    fridge = {
        prop = "prop_fridge_03",
        columns = 10,
        rows = 4,
        max_weight = 500000,
        is_container = true,
        effects = {
            allowed_categories = { "food", "drink", "medical" },
            quality_preservation = 4.0
        }
    },

    --- @section Vehicles

    rear_engine = {
        adder = true, ardent = true, autarch = true, bullet = true,
        cheetah = true, cheetah2 = true, comet2 = true, comet3 = true,
        entityxf = true, fmj = true, gp1 = true, infernus = true,
        italigtb = true, italirsx = true, jester = true, jester2 = true,
        monroe = true, nero = true, nero2 = true, ninef = true,
        ninef2 = true, osiris = true, penetrator = true, pfister811 = true,
        prototipo = true, re7b = true, reaper = true, stingergt = true,
        surfer = true, surfer2 = true, t20 = true, tempesta = true,
        turismo2 = true, turismor = true, tyrant = true, tyrus = true,
        vacca = true, vagner = true, zentorno = true
    },

    vehicle_defaults = {
        compact = { trunk = { columns = 10, rows = 6,  max_weight = 180000 }, glovebox = { columns = 2, rows = 2, max_weight = 20000 }},
        sedan = { trunk = { columns = 10, rows = 7,  max_weight = 220000 }, glovebox = { columns = 3, rows = 2, max_weight = 25000 }},
        suv = { trunk = { columns = 10, rows = 8,  max_weight = 300000 }, glovebox = { columns = 3, rows = 2, max_weight = 30000 }},
        coupe = { trunk = { columns = 10, rows = 6,  max_weight = 200000 }, glovebox = { columns = 2, rows = 2, max_weight = 20000 }},
        muscle = { trunk = { columns = 10, rows = 7,  max_weight = 240000 }, glovebox = { columns = 3, rows = 2, max_weight = 25000 }},
        sports = { trunk = { columns = 10, rows = 5,  max_weight = 160000 }, glovebox = { columns = 3, rows = 2, max_weight = 25000 }},
        super = { trunk = { columns = 10, rows = 4,  max_weight = 120000 }, glovebox = { columns = 2, rows = 2, max_weight = 20000 }},
        motorcycle = { trunk = { columns = 4,  rows = 4,  max_weight = 60000  }, glovebox = { columns = 2, rows = 1, max_weight = 10000 }},
        offroad = { trunk = { columns = 10, rows = 9,  max_weight = 400000 }, glovebox = { columns = 3, rows = 2, max_weight = 30000 }},
        industrial = { trunk = { columns = 10, rows = 12, max_weight = 900000 }, glovebox = { columns = 3, rows = 2, max_weight = 40000 }},
        utility = { trunk = { columns = 10, rows = 10, max_weight = 700000 }, glovebox = { columns = 3, rows = 2, max_weight = 35000 }},
        van = { trunk = { columns = 10, rows = 11, max_weight = 800000 }, glovebox = { columns = 3, rows = 2, max_weight = 35000 }},
        service = { trunk = { columns = 10, rows = 9,  max_weight = 600000 }, glovebox = { columns = 3, rows = 2, max_weight = 35000 }},
        emergency = { trunk = { columns = 10, rows = 10, max_weight = 650000 }, glovebox = { columns = 4, rows = 2, max_weight = 40000 }},
        military = { trunk = { columns = 10, rows = 13, max_weight = 1500000 }, glovebox = { columns = 5, rows = 2, max_weight = 60000 }},
        commercial = { trunk = { columns = 10, rows = 12, max_weight = 1200000 }, glovebox = { columns = 4, rows = 2, max_weight = 50000 }},
    },

    --- @section Vehicle Overrides

    adder = {
        trunk    = { columns = 5, rows = 7, max_weight = 100000 },
        glovebox = { columns = 5, rows = 2, max_weight = 30000  }
    },

}