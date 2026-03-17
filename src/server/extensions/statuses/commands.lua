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

--- @section Commands

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