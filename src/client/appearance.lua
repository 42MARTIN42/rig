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

--- @script src.client.appearance
--- @description Handles client side function for RIG appearance system

--- @section Imports

local tables = require("libs.graft.standalone.tables")
local cfg_appearance = require("configs.appearance")
local cfg_tattoos = require("configs.tattoos")

--- @section Constants

local FACIAL_FEATURES = {
    { index = 0, value = "nose_width" }, 
    { index = 1, value = "nose_peak_height" }, 
    { index = 2, value = "nose_peak_length" },
    { index = 3, value = "nose_bone_height" }, 
    { index = 4, value = "nose_peak_lower" }, 
    { index = 5, value = "nose_twist" },
    { index = 6, value = "eyebrow_height" }, 
    { index = 7, value = "eyebrow_depth" }, 
    { index = 8, value = "cheek_bone" },
    { index = 9, value = "cheek_sideways_bone" }, 
    { index = 10, value = "cheek_bone_width" },
    { index = 11, value = "eye_opening" }, 
    { index = 12, value = "lip_thickness" }, 
    { index = 13, value = "jaw_bone_width" },
    { index = 14, value = "jaw_bone_shape" }, 
    { index = 15, value = "chin_bone" }, 
    { index = 16, value = "chin_bone_length" },
    { index = 17, value = "chin_bone_shape" }, 
    { index = 18, value = "chin_hole" }, 
    { index = 19, value = "neck_thickness" }
}
local OVERLAYS = {
    { index = 2, style = "eyebrow", opacity = "eyebrow_opacity", colour = "eyebrow_colour" },
    { index = 1, style = "facial_hair", opacity = "facial_hair_opacity", colour = "facial_hair_colour" },
    { index = 10, style = "chest_hair", opacity = "chest_hair_opacity", colour = "chest_hair_colour" },
    { index = 4, style = "make_up", opacity = "make_up_opacity", colour = "make_up_colour" },
    { index = 5, style = "blush", opacity = "blush_opacity", colour = "blush_colour" },
    { index = 8, style = "lipstick", opacity = "lipstick_opacity", colour = "lipstick_colour" },
    { index = 0, style = "blemish", opacity = "blemish_opacity" },
    { index = 11, style = "moles", opacity = "moles_opacity" },
    { index = 3, style = "ageing", opacity = "ageing_opacity" },
    { index = 6, style = "complexion", opacity = "complexion_opacity" },
    { index = 7, style = "sun_damage", opacity = "sun_damage_opacity" },
    { index = 9, style = "body_blemish", opacity = "body_blemish_opacity" }
}
local CLOTHING = {
    { index = 1, style = "mask_style", texture = "mask_texture" },
    { index = 11, style = "jacket_style", texture = "jacket_texture" },
    { index = 8, style = "shirt_style", texture = "shirt_texture" },
    { index = 9, style = "vest_style", texture = "vest_texture" },
    { index = 4, style = "legs_style", texture = "legs_texture" },
    { index = 6, style = "shoes_style", texture = "shoes_texture" },
    { index = 3, style = "hands_style", texture = "hands_texture" },
    { index = 5, style = "bag_style", texture = "bag_texture" },
    { index = 10, style = "decals_style", texture = "decals_texture" },
    { index = 7, style = "neck_style", texture = "neck_texture" },
    { index = 0, style = "hats_style", texture = "hats_texture", is_prop = true },
    { index = 1, style = "glasses_style", texture = "glasses_texture", is_prop = true },
    { index = 2, style = "earwear_style", texture = "earwear_texture", is_prop = true },
    { index = 6, style = "watches_style", texture = "watches_texture", is_prop = true },
    { index = 7, style = "bracelets_style", texture = "bracelets_texture", is_prop = true }
}

local GENETICS_CONFIG = {
    {
        header = "appearance.client.genetics.heritage",
        inputs = {
            { id = "mother", label = "appearance.client.genetics.mother" },
            { id = "father", label = "appearance.client.genetics.father" },
            { id = "resemblance", label = "appearance.client.genetics.resemblance" },
            { id = "skin", label = "appearance.client.genetics.skin" }
        }
    },
    {
        header = "appearance.client.genetics.eyes",
        inputs = {
            { id = "eye_colour", label = "appearance.client.genetics.eye_colour" },
            { id = "eye_opening", label = "appearance.client.genetics.eye_opening" },
            { id = "eyebrow_height", label = "appearance.client.genetics.eyebrow_height" },
            { id = "eyebrow_depth", label = "appearance.client.genetics.eyebrow_depth" }
        }
    },
    {
        header = "appearance.client.genetics.nose",
        inputs = {
            { id = "nose_width", label = "appearance.client.genetics.nose_width" },
            { id = "nose_peak_height", label = "appearance.client.genetics.nose_peak_height" },
            { id = "nose_peak_length", label = "appearance.client.genetics.nose_peak_length" },
            { id = "nose_bone_height", label = "appearance.client.genetics.nose_bone_height" },
            { id = "nose_peak_lower", label = "appearance.client.genetics.nose_peak_lower" },
            { id = "nose_twist", label = "appearance.client.genetics.nose_twist" }
        }
    },
    {
        header = "appearance.client.genetics.cheeks_lips",
        inputs = {
            { id = "cheek_bone", label = "appearance.client.genetics.cheek_bone" },
            { id = "cheek_bone_sideways", label = "appearance.client.genetics.cheek_bone_sideways" },
            { id = "cheek_bone_width", label = "appearance.client.genetics.cheek_bone_width" },
            { id = "lip_thickness", label = "appearance.client.genetics.lip_thickness" }
        }
    },
    {
        header = "appearance.client.genetics.jaw_chin",
        inputs = {
            { id = "jaw_bone_width", label = "appearance.client.genetics.jaw_bone_width" },
            { id = "jaw_bone_shape", label = "appearance.client.genetics.jaw_bone_shape" },
            { id = "chin_bone", label = "appearance.client.genetics.chin_bone" },
            { id = "chin_bone_length", label = "appearance.client.genetics.chin_bone_length" },
            { id = "chin_bone_shape", label = "appearance.client.genetics.chin_bone_shape" },
            { id = "chin_hole", label = "appearance.client.genetics.chin_hole" },
            { id = "neck_thickness", label = "appearance.client.genetics.neck_thickness" }
        }
    }
}
local BARBER_CONFIG = {
    {
        header = "appearance.client.barber.hair",
        inputs = {
            { id = "hair", label = "appearance.client.barber.hair" },
            { id = "hair_colour", label = "appearance.client.barber.hair_colour" },
            { id = "fade", label = "appearance.client.barber.fade" },
            { id = "fade_colour", label = "appearance.client.barber.fade_colour" }
        }
    },
    {
        header = "appearance.client.barber.eyebrows",
        inputs = {
            { id = "eyebrow", label = "appearance.client.barber.eyebrow" },
            { id = "eyebrow_opacity", label = "appearance.client.barber.eyebrow_opacity" },
            { id = "eyebrow_colour", label = "appearance.client.barber.eyebrow_colour" }
        }
    },
    {
        header = "appearance.client.barber.facial_hair",
        inputs = {
            { id = "facial_hair", label = "appearance.client.barber.facial_hair" },
            { id = "facial_hair_opacity", label = "appearance.client.barber.facial_hair_opacity" },
            { id = "facial_hair_colour", label = "appearance.client.barber.facial_hair_colour" }
        }
    },
    {
        header = "appearance.client.barber.chest_hair",
        inputs = {
            { id = "chest_hair", label = "appearance.client.barber.chest_hair" },
            { id = "chest_hair_opacity", label = "appearance.client.barber.chest_hair_opacity" },
            { id = "chest_hair_colour", label = "appearance.client.barber.chest_hair_colour" }
        }
    },
    {
        header = "appearance.client.barber.makeup",
        inputs = {
            { id = "make_up", label = "appearance.client.barber.make_up" },
            { id = "make_up_opacity", label = "appearance.client.barber.make_up_opacity" },
            { id = "make_up_colour", label = "appearance.client.barber.make_up_colour" },
            { id = "blush", label = "appearance.client.barber.blush" },
            { id = "blush_opacity", label = "appearance.client.barber.blush_opacity" },
            { id = "blush_colour", label = "appearance.client.barber.blush_colour" },
            { id = "lipstick", label = "appearance.client.barber.lipstick" },
            { id = "lipstick_opacity", label = "appearance.client.barber.lipstick_opacity" },
            { id = "lipstick_colour", label = "appearance.client.barber.lipstick_colour" }
        }
    },
    {
        header = "appearance.client.barber.skin",
        inputs = {
            { id = "blemish", label = "appearance.client.barber.blemish" },
            { id = "blemish_opacity", label = "appearance.client.barber.blemish_opacity" },
            { id = "body_blemish", label = "appearance.client.barber.body_blemish" },
            { id = "body_blemish_opacity", label = "appearance.client.barber.body_blemish_opacity" },
            { id = "ageing", label = "appearance.client.barber.ageing" },
            { id = "ageing_opacity", label = "appearance.client.barber.ageing_opacity" },
            { id = "complexion", label = "appearance.client.barber.complexion" },
            { id = "complexion_opacity", label = "appearance.client.barber.complexion_opacity" },
            { id = "sun_damage", label = "appearance.client.barber.sun_damage" },
            { id = "sun_damage_opacity", label = "appearance.client.barber.sun_damage_opacity" },
            { id = "moles", label = "appearance.client.barber.moles" },
            { id = "moles_opacity", label = "appearance.client.barber.moles_opacity" }
        }
    }
}

--- @section Variables

local active_cam = nil
local current_sex = "m"
local appearance_ranges = nil
local ped_styles = tables.copy(cfg_appearance._defaults)

--- @section Functions

local function setup_camera(z_location, position_key)
    local cam_config = cfg_appearance.camera_positions[position_key]
    if not cam_config then return end
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end
    local offset_x, offset_y, offset_z = cam_config.offset.x, cam_config.offset.y, cam_config.offset.z
    local height_adjustment = cam_config.height_adjustment or 0
    local x, y, z = table.unpack(GetOffsetFromEntityInWorldCoords(ped, offset_x, offset_y, offset_z + height_adjustment))
    if not x or not y or not z then return end
    if DoesCamExist(active_cam) then DestroyCam(active_cam, false) end

    active_cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamActive(active_cam, true)
    SetCamCoord(active_cam, x, y, z)
    SetCamRot(active_cam, -5.0, 0.0, z_location + 180.0)
    RenderScriptCams(true, false, 0, true, true)
end

local function destroy_active_camera()
    if DoesCamExist(active_cam) then
        DestroyCam(active_cam, false)
        RenderScriptCams(false, false, 0, true, true)
        active_cam = nil
    end
end

local function get_style(sex)
    if not sex then return false end
    return ped_styles[sex]
end

local function apply_overlay(player, overlay, barber_data)
    local style = tonumber(barber_data[overlay.style]) or 0
    local opacity = (tonumber(barber_data[overlay.opacity]) or 0) / 100
    SetPedHeadOverlay(player, overlay.index, style, opacity)

    if overlay.colour then
        local colour = tonumber(barber_data[overlay.colour])
        if colour then
            SetPedHeadOverlayColor(player, overlay.index, 1, colour, colour)
        else
            log("error", "Invalid overlay colour for " .. overlay.style)
        end
    end
end

local function apply_clothing(player, item, clothing_data)
    local style = tonumber(clothing_data[item.style]) or -1
    local texture = tonumber(clothing_data[item.texture]) or 0

    if style >= 0 then
        if item.is_prop then
            SetPedPropIndex(player, item.index, style, texture, true)
        else
            SetPedComponentVariation(player, item.index, style, texture, 0)
        end
    end
end

local function apply_tattoos(player, tattoos, sex)
    if not tattoos then return end

    for zone, zone_tattoos in pairs(tattoos) do
        if type(zone_tattoos) == "table" then
            for _, tattoo_info in ipairs(zone_tattoos) do
                if tattoo_info and tattoo_info.name and tattoo_info.name ~= "none" then
                    local hash_field = (sex == "m") and tattoo_info.hash_m or tattoo_info.hash_f
                    if not hash_field or hash_field == "" then
                        print("[DEBUG] Skipping invalid hash for tattoo:", tattoo_info.name)
                    else
                        local hash = GetHashKey(hash_field)
                        local collection_hash = GetHashKey(tattoo_info.collection)
                        if hash and collection_hash then
                            SetPedDecoration(player, collection_hash, hash)
                        else
                            print("[ERROR] Invalid hash or collection for tattoo:", json.encode(tattoo_info))
                        end
                    end
                end
            end
        end
    end
end

local function set_ped_appearance(player, data)
    if not player or not data then log("error", "Function: set_ped_appearance failed | Reason: Missing required parameters (player or data).") return end
    
    local genetics = data.genetics
    SetPedHeadBlendData(player, genetics.mother, genetics.father, nil, genetics.mother, genetics.father, nil, genetics.resemblence, genetics.skin, nil, true)
    SetPedEyeColor(player, genetics.eye_colour)
    
    local barber = data.barber
    SetPedComponentVariation(player, 2, barber.hair, 0, 0)
    SetPedHairColor(player, barber.hair_colour, barber.highlight_colour)
    
    for _, feature in ipairs(FACIAL_FEATURES) do
        SetPedFaceFeature(player, feature.index, tonumber(genetics[feature.value]) or 0)
    end
    
    for _, overlay in ipairs(OVERLAYS) do
        apply_overlay(player, overlay, barber)
    end
    
    for _, item in ipairs(CLOTHING) do
        apply_clothing(player, item, data.clothing)
    end
    
    ClearPedDecorations(player)
    apply_tattoos(player, data.tattoos, current_sex)
    log("info", "Ped appearance successfully updated.")
end

local function set_player_model(player_id, player_ped, sex, style)
    if sex and sex ~= current_sex then
        current_sex = sex
    end
    
    local model = (current_sex == "m") and "mp_m_freemode_01" or "mp_f_freemode_01"
    local m = GetHashKey(tostring(model))
    if not HasModelLoaded(m) then
        RequestModel(m)
        while not HasModelLoaded(m) do
            Wait(0)
        end
    end
    
    local valid = IsModelValid(m)
    if not valid then
        return false, "Model is not valid."
    end
    SetPlayerModel(player_id, m)
    
    Wait(200)
    
    player_ped = GetPlayerPed(player_id)
    SetModelAsNoLongerNeeded(m)
    SetPedComponentVariation(player_ped, 0, 0, 0, 1)
    local p_style = style or ped_styles[current_sex]
    set_ped_appearance(player_ped, p_style)
    return true, "Model set successfully."
end

local function rotate_ped(direction)
    if not direction then return log("err", "Function: appearance_rotate_ped failed. | Reason: Direction parameter is missing.") end
    
    local player_ped = PlayerPedId()
    local current_heading = GetEntityHeading(player_ped)
    original_heading = original_heading or current_heading
    local rotations = {
        right = current_heading + 45,
        left = current_heading - 45,
        flip = current_heading + 180,
        reset = original_heading
    }
    
    local new_heading = rotations[direction]
    if not new_heading then log("err", "Function: appearance_rotate_ped failed. | Reason: Invalid direction parameter - Use right, left, flip, reset.") return end
    
    if direction == "reset" then
        original_heading = nil
    end
    
    SetEntityHeading(player_ped, new_heading)
end

local function get_appearance_ranges()
    local ped = PlayerPedId()
    local data = ped_styles[current_sex]
    return {
        -- Genetics
        mother = { min = -1, max = 21 },
        father = { min = -1, max = 21 },
        resemblance = { min = -1, max = 100 },
        skin = { min = -1, max = 100 },
        eye_colour = { min = -1, max = 31 },
        eye_opening = { min = -1, max = 20 },
        eyebrow_height = { min = -1, max = 20 },
        eyebrow_depth = { min = -1, max = 20 },
        nose_width = { min = -1, max = 20 },
        nose_peak_height = { min = -1, max = 20 },
        nose_peak_length = { min = -1, max = 20 },
        nose_bone_height = { min = -1, max = 20 },
        nose_peak_lower = { min = -1, max = 20 },
        nose_twist = { min = -1, max = 20 },
        cheek_bone = { min = -1, max = 20 },
        cheek_bone_sideways = { min = -1, max = 20 },
        cheek_bone_width = { min = -1, max = 20 },
        lip_thickness = { min = -1, max = 20 },
        jaw_bone_width = { min = -1, max = 20 },
        jaw_bone_shape = { min = -1, max = 20 },
        chin_bone = { min = -1, max = 20 },
        chin_bone_length = { min = -1, max = 20 },
        chin_bone_shape = { min = -1, max = 20 },
        chin_hole = { min = -1, max = 20 },
        neck_thickness = { min = -1, max = 20 },
        -- Barber
        hair = { min = -1, max = GetNumberOfPedDrawableVariations(ped, 2) - 1 },
        hair_colour = { min = -1, max = 63 },
        fade = { min = -1, max = GetNumberOfPedTextureVariations(ped, 2, tonumber(data.barber.hair)) - 1 },
        fade_colour = { min = -1, max = 63 },
        eyebrow = { min = -1, max = GetPedHeadOverlayNum(2) - 1 },
        eyebrow_opacity = { min = -1, max = 100 },
        eyebrow_colour = { min = -1, max = 63 },
        facial_hair = { min = -1, max = GetPedHeadOverlayNum(1) - 1 },
        facial_hair_opacity = { min = -1, max = 100 },
        facial_hair_colour = { min = -1, max = 63 },
        chest_hair = { min = -1, max = GetPedHeadOverlayNum(10) - 1 },
        chest_hair_opacity = { min = -1, max = 100 },
        chest_hair_colour = { min = -1, max = 63 },
        make_up = { min = -1, max = GetPedHeadOverlayNum(4) - 1 },
        make_up_opacity = { min = -1, max = 100 },
        make_up_colour = { min = -1, max = 63 },
        blush = { min = -1, max = GetPedHeadOverlayNum(5) - 1 },
        blush_opacity = { min = -1, max = 100 },
        blush_colour = { min = -1, max = 63 },
        lipstick = { min = -1, max = GetPedHeadOverlayNum(8) - 1 },
        lipstick_opacity = { min = -1, max = 100 },
        lipstick_colour = { min = -1, max = 63 },
        blemish = { min = -1, max = GetPedHeadOverlayNum(0) - 1 },
        blemish_opacity = { min = -1, max = 100 },
        body_blemish = { min = -1, max = GetPedHeadOverlayNum(11) - 1 },
        body_blemish_opacity = { min = -1, max = 100 },
        ageing = { min = -1, max = GetPedHeadOverlayNum(3) - 1 },
        ageing_opacity = { min = -1, max = 100 },
        complexion = { min = -1, max = GetPedHeadOverlayNum(6) - 1 },
        complexion_opacity = { min = -1, max = 100 },
        sun_damage = { min = -1, max = GetPedHeadOverlayNum(7) - 1 },
        sun_damage_opacity = { min = -1, max = 100 },
        moles = { min = -1, max = GetPedHeadOverlayNum(11) - 1 },
        moles_opacity = { min = -1, max = 100 }
    }
end

local function update_ped_appearance(category, id, value)
    if not category or value == nil then log("err", "Function: update_ped_appearance failed | Reason: Missing required parameters.") return end
    
    if category == "tattoos" and id and type(value) == "table" then
        if not ped_styles[current_sex].tattoos[id] then log("err", "Function: update_ped_appearance failed | Reason: Invalid tattoo zone: " .. tostring(id)) return end
        ped_styles[current_sex].tattoos[id] = value
        set_ped_appearance(PlayerPedId(), ped_styles[current_sex])
        return
    end

    if id == "resemblance" or id == "skin" then
        if value ~= -1 then
            value = value / 100
        end
    end

    if id and type(ped_styles[current_sex][category][id]) == "table" then
        for k, _ in pairs(ped_styles[current_sex][category][id]) do
            ped_styles[current_sex][category][id][k] = value[k]
        end
    elseif id then
        ped_styles[current_sex][category][id] = value
    else
        ped_styles[current_sex][category] = value
    end

    set_ped_appearance(PlayerPedId(), ped_styles[current_sex])
end

local function build_footer_keys()
    return {
        {
            key = "P",
            label = "Change Ped",
            on_action = function()
                local new_sex = (current_sex == "m") and "f" or "m"
                local success, message = set_player_model(PlayerId(), PlayerPedId(), new_sex)
                if not success then log("error", message) return end
                appearance_ranges = get_appearance_ranges()
            end
        },
        {
            key = "Z",
            label = "Body",
            on_action = function()
                setup_camera(cfg_appearance.location.w, "body")
            end
        },
        {
            key = "X",
            label = "Face",
            on_action = function()
                setup_camera(cfg_appearance.location.w, "face")
            end
        },
        {
            key = "C",
            label = "Legs",
            on_action = function()
                setup_camera(cfg_appearance.location.w, "legs")
            end
        },
        {
            key = "A",
            label = "Rotate Left",
            on_action = function()
                rotate_ped("left")
            end
        },
        {
            key = "D",
            label = "Rotate Right",
            on_action = function()
                rotate_ped("right")
            end
        },
        {
            key = "ENTER",
            label = "Save Appearance",
            should_close = true,
            on_action = function()
                local style = get_style(current_sex)
                Wait(10)
                TriggerServerEvent("rig:sv:save_appearance", current_sex, style)
            end
        }
    }
end

local function get_ui_layout()
    local footer_keys = build_footer_keys()
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
                    { type = "text", title = "Appearance can be changed in game.", subtitle = "Visit any safezone for more information." }
                }
            }
        },
        footer = {
            layout = { left = { justify = "flex-start", gap = "1vw" }, center = { justify = "center" }, right = { justify = "flex-end", gap = "1vw" } },
            elements = {
                left = {
                    { type = "audioplayer", autoplay = true, randomize = true }
                },
                center = {},
                right = {
                    {
                        type = "actions",
                        actions = footer_keys
                    }
                }
            }
        },
        content = { pages = {} }
    }
end

local function build_input_group_page(opts)
    return {
        index = opts.index,
        title = opts.title,
        layout = { left = 3 },
        left = {
            type = "input_groups",
            title = opts.title,
            id = opts.id,
            layout = { columns = 1, scroll_x = "none" },
            groups = opts.groups
        }
    }
end

local function on_increment(data)
    local category = data.dataset.category
    local target = data.dataset.target
    local value = tonumber(data.dataset.value) or 0
    local range = appearance_ranges[target]
    if not range then log("error", "No range found for: " .. tostring(target)) return end

    local new_value = value + 1
    if new_value > range.max then new_value = range.max end
    update_ped_appearance(category, target, new_value)
end

local function on_decrement(data)
    local category = data.dataset.category
    local target = data.dataset.target
    local value = tonumber(data.dataset.value) or 0
    local range = appearance_ranges[target]
    if not range then log("error", "No range found for: " .. tostring(target)) return end

    local new_value = value - 1
    if new_value < range.min then new_value = range.min end
    update_ped_appearance(category, target, new_value)
end

local function build_genetics_groups()
    local groups = {}
    for _, group_config in ipairs(GENETICS_CONFIG) do
        local inputs = {}
        for _, cfg_appearance in ipairs(group_config.inputs) do
            local range = appearance_ranges[cfg_appearance.id] or { min = -1, max = 100 }
            inputs[#inputs + 1] = {
                id = cfg_appearance.id,
                type = "number",
                label = locale(cfg_appearance.label),
                category = "genetics",
                min = range.min,
                max = range.max,
                value = ped_styles[current_sex]["genetics"][cfg_appearance.id],
                on_increment = on_increment,
                on_decrement = on_decrement
            }
        end
        groups[#groups + 1] = {
            header = locale(group_config.header),
            expandable = true,
            inputs = inputs
        }
    end
    return groups
end

local function build_barber_groups()
    local groups = {}
    for _, group_config in ipairs(BARBER_CONFIG) do
        local inputs = {}
        for _, cfg_appearance in ipairs(group_config.inputs) do
            local range = appearance_ranges[cfg_appearance.id] or { min = -1, max = 100 }
            inputs[#inputs + 1] = {
                id = cfg_appearance.id,
                type = "number",
                label = locale(cfg_appearance.label),
                category = "barber",
                min = range.min,
                max = range.max,
                value = ped_styles[current_sex]["barber"][cfg_appearance.id],
                on_increment = on_increment,
                on_decrement = on_decrement
            }
        end
        groups[#groups + 1] = {
            header = locale(group_config.header),
            expandable = true,
            inputs = inputs
        }
    end
    return groups
end

local function build_tattoos_groups()
    local tattoo_data = cfg_tattoos
    local groups = {}
    local sex = current_sex
    for zone, tattoos in pairs(tattoo_data) do
        local inputs = {}
        local stored_zone = ped_styles[sex].tattoos[zone] or {}
        local options = {}

        for _, t in ipairs(tattoos) do
            local hash = sex == "m" and t.hash_m or t.hash_f
            if hash and hash ~= "" then
                options[#options + 1] = { value = t.name, label = t.label }
            end
        end

        table.insert(options, 1, { value = "", label = "none" })
        
        local num_inputs = math.max(#stored_zone, 1)
        for i = 1, num_inputs do
            local stored = stored_zone[i] and stored_zone[i].name or ""
            inputs[#inputs + 1] = {
                id = string.format("%s_%d", zone, i),
                type = "select",
                label = locale("appearance.client.tattoos." .. zone) .. " #" .. i,
                category = "tattoos",
                copyable = true,
                value = stored,
                options = options,
                on_select = function(selected)
                    if not selected or not selected.dataset then return end
                    local tattoo_name = selected.dataset.value
                    local raw_zone = selected.dataset.target
                    local base_zone = raw_zone:match("^(.-)_?%d*$") or raw_zone
                    local slot = tonumber(raw_zone:match("%d+$")) or 1

                    if tattoo_name == "" then
                        if ped_styles[sex].tattoos[base_zone][slot] then
                            table.remove(ped_styles[sex].tattoos[base_zone], slot)
                            set_ped_appearance(PlayerPedId(), ped_styles[sex])
                        else
                            log("info", "No tattoo to remove at", base_zone, "slot", slot)
                        end
                        return
                    end

                    local tattoo_info = nil
                    for _, t in ipairs(tattoos) do
                        if t.name == tattoo_name then
                            local hash = sex == "m" and t.hash_m or t.hash_f
                            if hash and hash ~= "" then
                                tattoo_info = t
                                break
                            end
                        end
                    end
                    if not tattoo_info then log("error", "Tattoo not found for:", tattoo_name) return end

                    ped_styles[sex].tattoos[base_zone][slot] = tattoo_info
                    set_ped_appearance(PlayerPedId(), ped_styles[sex])
                end
            }
        end
        groups[#groups + 1] = {
            header = locale("appearance.client.tattoos." .. zone),
            expandable = true,
            inputs = inputs
        }
    end
    return groups
end

--- @section Events

RegisterNetEvent("rig:cl:create_first_appearance", function()
    local player_id = PlayerId()
    local player_ped = PlayerPedId()
    local success, message = set_player_model(player_id, player_ped, current_sex)
    if not success then log("error", message) return end

    Wait(1500)

    player_ped = PlayerPedId()
    SetEntityCoords(player_ped, cfg_appearance.location.x, cfg_appearance.location.y, cfg_appearance.location.z, false, false, false, true)
    SetEntityHeading(player_ped, cfg_appearance.location.w)
    
    Wait(500)
    
    appearance_ranges = get_appearance_ranges()
    setup_camera(cfg_appearance.location.w, "body")
    SetNuiFocus(true, true)
    DisplayRadar(false)
    if IsScreenFadedOut() then DoScreenFadeIn(500) end
    
    local appearance_ui = get_ui_layout()

    appearance_ui.content.pages.genetics = build_input_group_page({
        page_key = "genetics",
        index = 1,
        title = "Genetics",
        id = "genetics_inputs",
        groups = build_genetics_groups()
    })
    appearance_ui.content.pages.barber = build_input_group_page({
        page_key = "barber",
        index = 2,
        title = "Barber",
        id = "barber_inputs",
        groups = build_barber_groups()
    })
    appearance_ui.content.pages.tattoos = build_input_group_page({
        page_key = "tattoos",
        index = 3,
        title = "Tattoos",
        id = "tattoos_inputs",
        groups = build_tattoos_groups()
    })
    pluck.build_ui(appearance_ui)
end)

RegisterNetEvent("rig:cl:load_appearance", function(data)
    if not data then log("error", locale("appearance.client.appearance_data_missing")) return end
    
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(50) end
    
    local player_id = PlayerId()
    local player_ped = PlayerPedId()
    local success, message = set_player_model(player_id, player_ped, data.sex, data)
    if not success then log("error", message) return end
    
    Wait(500)
    
    DisplayRadar(false)
    TriggerServerEvent("rig:sv:fetch_spawns")
end)

--- @section Test

RegisterCommand("test_char_custom", function()
    TriggerEvent("rig:cl:create_first_appearance")
end)