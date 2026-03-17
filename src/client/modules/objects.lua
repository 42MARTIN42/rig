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

--- @module objects
--- @description Handles creating, removing and placing world objects.

if rawget(_G, "__objects_module") then
    return _G.__objects_module
end

local objects = {}
_G.__objects_module = objects

--- @section Dependencies

local requests = require("libs.graft.fivem.requests")
local keys = require("libs.graft.fivem.keys")

--- @section Constants

local PLACEMENT_CONTROLS = {
    { key = "G", action = "Rotate Left" },
    { key = "H", action = "Rotate Right" },
    { key = "Enter", action = "Confirm" },
    { key = "Backspace", action = "Cancel" }
}

local OFFSET_DISTANCE = 1.5
local ROTATE_SPEED = 1.5
local PLACE_ANIM_DICT = "amb@world_human_hammering@male@base"
local PLACE_ANIM_NAME = "base"
local PLACE_ANIM_DURATION = 3500

--- @section State

local created_entities = {}
local is_placing = false

--- @section Internal Functions

local function get_ground_z(x, y, z)
    local found, ground_z = GetGroundZFor_3dCoord(x, y, z, false)
    return found and ground_z or z
end

local function play_confirm_anim(ped)
    requests.anim(PLACE_ANIM_DICT)
    TaskPlayAnim(ped, PLACE_ANIM_DICT, PLACE_ANIM_NAME, 8.0, -8.0, PLACE_ANIM_DURATION, 1, 0, false, false, false)
    pluck.show_progressbar({
        header = "Placing...",
        duration = PLACE_ANIM_DURATION
    })
    Wait(PLACE_ANIM_DURATION)
end

--- @section API

function objects.create(model, coords)
    local model_hash = GetHashKey(model)
    if not requests.model(model_hash) then
        print(("[objects] Failed to load model: %s"):format(model))
        return nil
    end
    local entity = CreateObject(model_hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(entity, coords.w or 0.0)
    PlaceObjectOnGroundProperly(entity)
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, true, true)
    SetModelAsNoLongerNeeded(model_hash)
    created_entities[entity] = true
    return entity
end

function objects.remove(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
        created_entities[entity] = nil
    end
end

function objects.track_entity(entity)
    if entity then created_entities[entity] = true end
end

function objects.start_placing(config)
    if is_placing then return end
    if not config or not config.model then return print("[objects] Missing model") end
    is_placing = true
    local model_hash = GetHashKey(config.model)
    if not requests.model(model_hash) then
        print(("[objects] Failed to load model: %s"):format(config.model))
        is_placing = false
        return
    end
    local ped = PlayerPedId()
    local offset = GetOffsetFromEntityInWorldCoords(ped, 0.0, OFFSET_DISTANCE, 0.0)
    local preview = CreateObject(model_hash, offset.x, offset.y, offset.z, false, true, true)
    SetEntityAlpha(preview, 150)
    SetEntityCollision(preview, false, false)
    local key_list = keys.get_keys()
    pluck.set_controls(config.label or "PLACE OBJECT", PLACEMENT_CONTROLS)
    pluck.show_controls()
    while true do
        Wait(0)
        local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, OFFSET_DISTANCE, 0.0)
        local gz = get_ground_z(pos.x, pos.y, pos.z + 2.0)
        SetEntityCoords(preview, pos.x, pos.y, gz, false, false, false, true)
        if IsControlPressed(0, key_list["g"]) then
            SetEntityHeading(preview, GetEntityHeading(preview) - ROTATE_SPEED)
        end
        if IsControlPressed(0, key_list["h"]) then
            SetEntityHeading(preview, GetEntityHeading(preview) + ROTATE_SPEED)
        end
        if IsControlJustReleased(0, key_list["enter"]) then
            pluck.hide_controls()
            play_confirm_anim(ped)

            local final_coords = GetEntityCoords(preview)
            local final_heading = GetEntityHeading(preview)
            DeleteObject(preview)
            SetModelAsNoLongerNeeded(model_hash)
            if config.on_confirm then
                config.on_confirm(vector4(final_coords.x, final_coords.y, final_coords.z, final_heading))
            end
            break
        end
        if IsControlJustReleased(0, key_list["backspace"]) then
            DeleteObject(preview)
            SetModelAsNoLongerNeeded(model_hash)
            pluck.hide_controls()
            if config.on_cancel then config.on_cancel() end
            break
        end
    end
    is_placing = false
end

function objects.is_placing()
    return is_placing
end

function objects.cleanup_all()
    for entity in pairs(created_entities) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
    created_entities = {}
end

AddEventHandler("onResourceStop", function(resource)
    if GetCurrentResourceName() == resource then
        objects.cleanup_all()
    end
end)

return objects