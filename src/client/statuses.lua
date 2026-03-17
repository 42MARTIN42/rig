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

--- @script src.client.statuses
--- @description Main client file for the statuses extension.

--- @section Imports

local environment = require("libs.graft.fivem.environment")
local keys = require("libs.graft.fivem.keys")
local animations = require("libs.graft.fivem.animations")
local callbacks = require("libs.graft.fivem.callbacks")

--- @section Variables

local hud_active = false
local is_downed = false

--- @section Functions

local function build_hud_payload()
    local player_data = core.get_player_data()
    local statuses = player_data.statuses or {}
    return {
        health = statuses.health or 200,
        armour = statuses.armour or 0,
        hunger = statuses.hunger or 100,
        thirst = statuses.thirst or 100,
        hygiene = statuses.hygiene or 100,
        stress = statuses.stress or 0,
        sanity = statuses.sanity or 100,
        temperature = statuses.temperature or 37,
        bleeding = statuses.bleeding or 0,
        radiation = statuses.radiation or 0,
        infection = statuses.infection or 0,
        poison = statuses.poison or 0,
        stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId()),
        oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
    }
end

local function play_idle_crawl(ped)
    local dict = "combat@damage@writhe"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    TaskPlayAnim(ped, dict, "writhe_loop", 8.0, -8.0, -1, 1, 0, false, false, false)
end

local function downed_crawl_loop(ped)
    local is_crawling = false
    local is_moving = false
    while is_downed do
        DisableAllControlActions(0)
        EnableControlAction(0, 32, true)
        EnableControlAction(0, 33, true)
        EnableControlAction(0, 34, true)
        EnableControlAction(0, 35, true)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, 25, true)

        local forward = IsControlPressed(0, 32)
        local backward = IsControlPressed(0, 33)
        local left = IsControlPressed(0, 34)
        local right = IsControlPressed(0, 35)
        local any_movement = forward or backward or left or right

        if left then
            SetEntityHeading(ped, GetEntityHeading(ped) + 2.0)
        elseif right then
            SetEntityHeading(ped, GetEntityHeading(ped) - 2.0)
        end

        if not is_crawling then
            if forward then
                is_moving = true
                is_crawling = true
                TaskPlayAnim(ped, "move_crawl", "onfront_fwd", 8.0, -8.0, -1, 2, 0.0, false, false, false)
                SetTimeout(820, function() is_crawling = false end)
            elseif backward then
                is_moving = true
                is_crawling = true
                TaskPlayAnim(ped, "move_crawl", "onfront_bwd", 8.0, -8.0, -1, 2, 0.0, false, false, false)
                SetTimeout(990, function() is_crawling = false end)
            elseif not any_movement and is_moving then
                is_moving = false
                play_idle_crawl(ped)
            end
        end

        Wait(0)
    end
end

--- @section Events

AddEventHandler("rig:cl:playing_state_changed", function(state)
    if state then
        hud_active = true
        pluck.show_status_hud()
        pluck.send_headshot()
        pluck.update_status_hud(build_hud_payload())
    else
        hud_active = false
        pluck.hide_status_hud()
    end
end)

RegisterNetEvent("rig:cl:player_died", function()
    is_downed = false
    hud_active = false
    pluck.hide_status_hud()
    EnableAllControlActions(0)
    ClearTimecycleModifier()

    local ped = PlayerPedId()
    SetEntityHealth(ped, 0)
    SetPedArmour(ped, 0)
    ClearPedTasks(ped)

    pluck.update_interaction_hint({
        label = "Dead",
        status_text = "You are dead...",
        action_text = "Press H to Respawn"
    })

    SetTimecycleModifierStrength(1.0)

    local dict = "dead"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    local dead_anim_letters = { "a", "b", "c", "d", "e", "f", "g", "h" }
    TaskPlayAnim(ped, dict, "dead_" .. dead_anim_letters[math.random(#dead_anim_letters)], 8.0, -8.0, -1, 1, 0, false, false, false)

    CreateThread(function()
        while true do
            if IsControlJustPressed(0, 74) then
                TriggerServerEvent("rig:sv:player_respawn")
                break
            end
            Wait(0)
        end
    end)
end)

RegisterNetEvent("rig:cl:player_downed", function(data)
    local ped = PlayerPedId()
    is_downed = true
    local remaining = data.duration / 1000

    pluck.hide_status_hud()
    pluck.update_interaction_hint({
        label = "Downed",
        status_text = remaining .. "s remaining",
        action_text = "Press H to Give Up"
    })

    SetTimecycleModifier("damage")
    SetTimecycleModifierStrength(0.3)

    CreateThread(function()
        while is_downed and remaining > 0 do
            Wait(1000)
            remaining = remaining - 1
            pluck.update_hint_status(remaining .. "s remaining")
            local strength = math.min(1.0, 0.3 + (1.0 - (remaining / (data.duration / 1000))) * 0.7)
            SetTimecycleModifierStrength(strength)
        end
        if not is_downed then return end
        is_downed = false
        pluck.update_interaction_hint({
            label = "Dead",
            status_text = "You are dead...",
            action_text = "Press H to Respawn"
        })
        SetTimecycleModifierStrength(1.0)
        EnableAllControlActions(0)
        ClearPedTasks(ped)
        local dict = "dead"
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(0) end
        local dead_anim_letters = { "a", "b", "c", "d", "e", "f", "g", "h" }
        TaskPlayAnim(ped, dict, "dead_" .. dead_anim_letters[math.random(#dead_anim_letters)], 8.0, -8.0, -1, 1, 0, false, false, false)
    end)

    CreateThread(function()
        while is_downed do
            if IsControlJustPressed(0, 74) then
                TriggerServerEvent("rig:sv:player_give_up")
                break
            end
            Wait(0)
        end
    end)

    RequestAnimDict("combat@damage@writhe")
    while not HasAnimDictLoaded("combat@damage@writhe") do Wait(0) end
    RequestAnimDict("move_crawl")
    while not HasAnimDictLoaded("move_crawl") do Wait(0) end

    TaskPlayAnim(ped, "combat@damage@writhe", "writhe_enter", 8.0, -8.0, -1, 1, 0, false, false, false)
    Wait(1500)
    TaskPlayAnim(ped, "combat@damage@writhe", "writhe_loop", 8.0, -8.0, -1, 1, 0, false, false, false)

    CreateThread(function() downed_crawl_loop(ped) end)
end)

RegisterNetEvent("rig:cl:player_picked_up", function()
    callbacks.trigger("rig:sv:validate_revive", {}, function(response)
        if not response or not response.valid then
            log("info", "[pickup] validate failed - response: " .. tostring(response and response.valid))
            return
        end
        local ped = PlayerPedId()
        NetworkResurrectLocalPlayer(GetEntityCoords(ped), GetEntityHeading(ped), true, true)
        SetEntityHealth(ped, 41)
        SetPedArmour(ped, 0)
    end)
    is_downed = false
    ClearPedTasks(PlayerPedId())
    EnableAllControlActions(0)
    ClearTimecycleModifier()
    RemoveAnimDict("move_crawl")
    RemoveAnimDict("combat@damage@writhe")
    hud_active = true
    pluck.show_status_hud()
    pluck.destroy_interaction_hint()
end)

RegisterNetEvent("rig:cl:respawn_player", function()
    callbacks.trigger("rig:sv:validate_respawn", {}, function(response)
        if not response or not response.valid then
            log("info", "[respawn] validate failed - response: " .. tostring(response and response.valid))
            return
        end
        local ped = PlayerPedId()
        NetworkResurrectLocalPlayer(GetEntityCoords(ped), GetEntityHeading(ped), true, true)
        TriggerServerEvent("rig:sv:fetch_spawns")
    end)
end)

RegisterNetEvent("rig:cl:revive_player", function()
    callbacks.trigger("rig:sv:validate_revive", {}, function(response)
        if not response or not response.valid then
            log("info", "[revive] validate failed - response: " .. tostring(response and response.valid))
            return
        end
        local ped = PlayerPedId()
        NetworkResurrectLocalPlayer(GetEntityCoords(ped), GetEntityHeading(ped), true, true)
        SetEntityHealth(ped, 200)
        SetPedArmour(ped, 100)
    end)
    is_downed = false
    ClearPedTasks(PlayerPedId())
    EnableAllControlActions(0)
    ClearTimecycleModifier()
    RemoveAnimDict("move_crawl")
    RemoveAnimDict("combat@damage@writhe")
    hud_active = true
    pluck.show_status_hud()
    pluck.destroy_interaction_hint()
end)

--- @section Threads

CreateThread(function()
    while not core.get_player_data() or next(core.get_player_data()) == nil do
        Wait(100)
    end
    while true do
        if hud_active then
            pluck.update_status_hud(build_hud_payload())
        end
        Wait(500)
    end
end)

CreateThread(function()
    while not core.get_player_data() or next(core.get_player_data()) == nil do
        Wait(100)
    end
    local key_list = keys.get_keys()
    local in_water = false
    local is_drinking = false

    while true do
        local ped = PlayerPedId()

        if environment.is_in_water(ped) then
            if not in_water then
                in_water = true
                pluck.update_interaction_hint({
                    label = "Water Source",
                    action_text = "Press E to drink"
                })
            end

            if not is_drinking and IsControlJustReleased(0, key_list["e"]) then
                is_drinking = true
                pluck.destroy_interaction_hint()

                animations.play(ped, {
                    dict = "amb@world_human_bum_wash@male@high@idle_a",
                    anim = "idle_b",
                    duration = 6500,
                    flags = 1,
                    freeze = false
                }, function()
                    local coords = GetEntityCoords(ped)
                    local zone = GetZoneAtCoords(coords.x, coords.y, coords.z)
                    local scumminess = zone and GetZoneScumminess(zone) or -1

                    TriggerServerEvent("rig:sv:player_drink_water_source", { zone = zone, scumminess = scumminess })
                    is_drinking = false
                    if environment.is_in_water(ped) then
                        pluck.update_interaction_hint({
                            label = "Water Source",
                            action_text = "Press E to drink"
                        })
                    end
                end)
            end

            Wait(0)
        else
            if in_water then
                in_water = false
                pluck.destroy_interaction_hint()
            end
            Wait(500)
        end
    end
end)

CreateThread(function()
    local last_health = 200
    local last_armour = 0
    while true do
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        local armour = GetPedArmour(ped)
        if health ~= last_health or armour ~= last_armour then
            last_health = health
            last_armour = armour
            TriggerServerEvent("rig:sv:update_health_armour", { health = health, armour = armour })
        end
        Wait(50)
    end
end)

--- @section Commands

RegisterCommand("statusdemo", function()
    pluck.show_status_hud()
    pluck.send_headshot()
    CreateThread(function()
        local fake = {
            health = 200, armour = 70, hunger = 100, thirst = 100,
            hygiene = 100, stress = 100, sanity = 100, temperature = 37,
            bleeding = 20, radiation = 10, infection = 0, poison = 40,
            stamina = 100, oxygen = 100
        }
        for _ = 1, 4 do
            fake.temperature = fake.temperature - 4
            fake.hunger = fake.hunger - 3
            fake.stress = fake.stress + 3
            fake.stamina = fake.stamina - 5
            pluck.update_status_hud(fake)
            Wait(4000)
        end
        fake.temperature = 32
        fake.thirst = fake.thirst - 15
        fake.stress = fake.stress + 5
        pluck.update_status_hud(fake)
    end)
end)