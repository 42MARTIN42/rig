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
local vehicles = require("libs.graft.fivem.vehicles")
local utils = require("src.server.modules.utils")

--- @section Public Commands

commands.register({
    name = "id",
    help = "Check your current server ID.",
    params = {},
    handler = function(source)
        pluck.notify(source, { type = "info", header = locale("commands.notify_header"), message = locale("commands.id", source), duration = 5000 })
    end
})

commands.register({
    name = "disconnect",
    help = "Disconnect from the server.",
    params = {},
    handler = function(source)
        pluck.notify(source, { type = "info", header = locale("commands.notify_header"), message = locale("commands.disconnecting"), duration = 2500 })
        Wait(2500)
        DropPlayer(source, locale("commands.disconnected"))
    end
})

--- @section Test

RegisterCommand("testplayer", function(source)
    local _src = source
    local ids = utils.get_player_identifiers(_src)
    local result = core.players:exists(ids.license)
    
    if result and result[1] then
        local user_data = result[1]
        core.players:stage(ids.license, user_data)
        
        if core.players:activate(_src, ids.license) then
            core.players:assign_personal_bucket(_src)
            local player = core.create_player(_src)
            if player then 
                player:run_method("set_status", "playing", true)
                print(("^2[Test] Successfully forced initialization for source %s^7"):format(_src))
            end
        end
    else
        print("^1[Test] Failed: No database record found for license.^7")
    end
end, false)

RegisterCommand("testbed", function(source)
    local player = core.players:get(source)
    if not player then return end
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    player:run_method("set_spawn", "test_bed_01", {
        spawn_type = "bed",
        label = "Test Bed",
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = heading
    })
    print("Test bed saved for " .. player.unique_id)
end, false)

RegisterCommand("testsleeping", function(source)
    local player = core.players:get(source)
    if not player then return end
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    player:run_method("set_spawn", "test_bag_01", {
        spawn_type = "sleepingbag",
        label = "Test Sleepingbag",
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = heading
    })
    print("Test bag saved for " .. player.unique_id)
end, false)