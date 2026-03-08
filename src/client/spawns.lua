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

--- @script src.client.spawns
--- @description Handles client side function for RIG spawn system

--- @section Variables

local spawn_camera = nil
local spawn_ui_active = false

--- @section Functions

local function create_spawn_camera(coords)
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, coords.x, coords.y, coords.z + 500.0)
    PointCamAtCoord(cam, coords.x, coords.y, coords.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
    local start_z = coords.z + 500.0
    local end_z = coords.z + 100.0
    local start_time = GetGameTimer()
    while GetGameTimer() - start_time < 2000 do
        local progress = (GetGameTimer() - start_time) / 2000
        SetCamCoord(cam, coords.x, coords.y, start_z + (end_z - start_z) * progress)
        Wait(0)
    end
    return cam
end

local function build_footer_keys()
    return {
        {
            key = "ESCAPE",
            label = "Disconnect",
            on_action = function()
                TriggerServerEvent("rig:sv:disconnect")
            end
        }
    }
end

local function get_ui_layout()
    return {
        header = {
            layout = { left = { justify = "flex-start" }, center = { justify = "center" }, right = { justify = "flex-end" } },
            elements = {
                left = {
                    {
                        type = "group",
                        items = {
                            { type = "logo", image = core.convars.server_logo },
                            { type = "text", title = core.convars.server_name, subtitle = core.convars.server_tagline }
                        }
                    }
                },
                center = { { type = "tabs" } },
                right = {
                    { type = "text", title = "You can pick a new spawn when you die.", subtitle = "Place a sleeping bag or bed down to spawn there." }
                }
            }
        },
        footer = {
            layout = { left = { justify = "flex-start", gap = "1vw" }, center = { justify = "center" }, right = { justify = "flex-end", gap = "1vw" } },
            elements = {
                left = { { type = "audioplayer", autoplay = true, randomize = true } },
                center = {},
                right = { { type = "actions", actions = build_footer_keys() } }
            }
        },
        content = { pages = {} }
    }
end

local function build_safezone_cards(world_zones)
    local cards = {}
    for _, zone in ipairs(world_zones) do
        cards[#cards + 1] = {
            image = zone.image,
            title = zone.label,
            description = "Difficulty: " .. zone.difficulty,
            layout = "column",
            buttons = {
                {
                    id = "btn_view_" .. zone.id,
                    label = "View",
                    class = "secondary",
                    on_action = function()
                        if spawn_camera then DeleteEntity(spawn_camera) end
                        spawn_camera = create_spawn_camera(zone.coords)
                        SetEntityCoords(PlayerPedId(), zone.coords.x, zone.coords.y, zone.coords.z, false, false, false, false)
                    end
                },
                {
                    id = "btn_spawn_" .. zone.id,
                    label = "Spawn",
                    class = "primary",
                    should_close = true,
                    on_action = function()
                        TriggerServerEvent("rig:sv:select_spawn", zone.id)
                    end
                }
            }
        }
    end
    return cards
end
local function build_bed_cards(personal)
    local descriptions = { last_location = "Last Location", sleepingbag = "Sleeping Bag" }
    local cards = {}

    table.sort(personal, function(a, b)
        if a.spawn_type == "last_location" then return true end
        if b.spawn_type == "last_location" then return false end
        return false
    end)

    for _, bed in ipairs(personal) do
        cards[#cards + 1] = {
            title = bed.label,
            description = descriptions[bed.spawn_type] or "Bed",
            layout = "column",
            buttons = {
                {
                    id = "btn_view_" .. bed.id,
                    label = "View",
                    class = "secondary",
                    on_action = function()
                        if spawn_camera then DeleteEntity(spawn_camera) end
                        spawn_camera = create_spawn_camera(bed.coords)
                        SetEntityCoords(PlayerPedId(), bed.coords.x, bed.coords.y, bed.coords.z, false, false, false, false)
                    end
                },
                {
                    id = "btn_spawn_" .. bed.id,
                    label = "Spawn",
                    class = "primary",
                    should_close = true,
                    on_action = function()
                        TriggerServerEvent("rig:sv:select_spawn", bed.id)
                    end
                }
            }
        }
    end
    return cards
end

local function setup_spawn_scene(payload)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(50) end
    Wait(200)
    local first = payload.world_zones and payload.world_zones[1]
    local coords = first and first.coords or { x = -268.47, y = -956.98, z = 31.22, w = 0 }
    spawn_camera = create_spawn_camera(coords)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityVisible(PlayerPedId(), false)
    SetWeatherTypeNowPersist("HALLOWEEN")
    NetworkOverrideClockTime(23, 0, 0)
    spawn_ui_active = true
    CreateThread(function()
        while spawn_ui_active do
            NetworkOverrideClockTime(23, 0, 0)
            Wait(100)
        end
    end)
    if IsScreenFadedOut() then DoScreenFadeIn(500) end
end

--- @section Events

RegisterNetEvent("rig:cl:handle_spawn_ui", function(payload)
    setup_spawn_scene(payload)
    local ui = get_ui_layout()

    local has_zones = payload.world_zones and #payload.world_zones > 0
    local has_personal = payload.personal and #payload.personal > 0

    if payload.is_downed then spawn_ui_downed = true end

    local zones_section = has_zones and {
        type = "cards",
        layout = { columns = 2, flex = "column", scroll_x = "none" },
        title = "World Zones",
        cards = build_safezone_cards(payload.world_zones)
    }

    local personal_section = has_personal and {
        type = "cards",
        layout = { columns = 2, flex = "column", scroll_x = "none" },
        title = "Personal Spawns",
        cards = build_bed_cards(payload.personal)
    }

    ui.content.pages = {
        spawn = {
            index = 1,
            title = "Spawn Locations",
            layout = { left = 4, center = 4, right = 4 },
            left = zones_section or personal_section,
            right = has_zones and has_personal and personal_section
        }
    }

    pluck.build_ui(ui)
end)

RegisterNetEvent("rig:cl:cleanup_spawn_camera", function()
    spawn_ui_active = false
    if spawn_camera then
        DeleteEntity(spawn_camera)
        spawn_camera = nil
    end
    RenderScriptCams(false, false, 0, true, true)
    FreezeEntityPosition(PlayerPedId(), false)
    SetEntityVisible(PlayerPedId(), true)
    if IsScreenFadedOut() then DoScreenFadeIn(1000) end
end)

RegisterNetEvent("rig:cl:find_ground_and_spawn", function()
    Wait(100)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    local attempts = 0
    repeat
        Wait(100)
        attempts = attempts + 1
    until HasCollisionLoadedAroundEntity(ped) or attempts >= 30
    local found, ground_z
    attempts = 0
    repeat
        found, ground_z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
        attempts = attempts + 1
        Wait(100)
    until found or attempts >= 20
    if found then
        local x, y = coords.x, coords.y
        SetEntityCoords(ped, x, y, ground_z + 0.5, false, false, false, false)
    end
    FreezeEntityPosition(ped, false)
    TriggerEvent("rig:cl:cleanup_spawn_camera")
end)

--- @section Test

RegisterCommand("test_spawn_ui", function()
    TriggerServerEvent("rig:sv:fetch_spawns")
end)