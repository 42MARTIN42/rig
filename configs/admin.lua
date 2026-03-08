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

--- @module configs.admin
--- @description Handles all server side configurable options for the admin menu

return {

    permissions = {
        open_menu = { "rig.dev", "rig.admin" }, -- table | string | false - { "rig.dev" } | "rig.dev" | false (no perm check)
        view_players = { "rig.dev", "rig.admin" },
        view_bans = { "rig.dev", "rig.admin" },

        remove_ban = { "rig.dev", "rig.admin" },

        user = {
            noclip = { "rig.dev", "rig.admin" },
            godmode = { "rig.dev", "rig.admin" },
            invisible = { "rig.dev", "rig.admin" },
            freeze = { "rig.dev", "rig.admin" },
            teleport_waypoint = { "rig.dev", "rig.admin" },
            teleport_coords = { "rig.dev", "rig.admin" },
            revive = { "rig.dev", "rig.admin" },
            kill = { "rig.dev", "rig.admin" },
        },

        players = {
            godmode = { "rig.dev", "rig.admin" },
            invisible = { "rig.dev", "rig.admin" },
            kick = { "rig.dev", "rig.admin" },
            warn = { "rig.dev", "rig.admin" },
            ban = { "rig.dev", "rig.admin" },
            teleport = { "rig.dev", "rig.admin" },
            bring = { "rig.dev", "rig.admin" },
            revive = { "rig.dev", "rig.admin" },
            kill = { "rig.dev", "rig.admin" },
        },

        vehicles = {
            spawn = { "rig.dev", "rig.admin" },
            delete = { "rig.dev", "rig.admin" },
            repair = { "rig.dev", "rig.admin" }
        }
    }
}