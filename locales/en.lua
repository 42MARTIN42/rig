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

--- @module locales.en
--- @description English language; you can replace these or add a new language file.

local locales = {}

locales.init = {
    mod_missing = "Module not found: %s",
    mod_compile = "Module compile error in %s: %s",
    mod_runtime = "Module runtime error in %s: %s",
    mod_return = "Module %s did not return a table (got %s)",
    ns_blocked = "Attempted to modify locked namespace: core.%s",
    ns_ready = "%s namespace locked and ready",
}

locales.admin = {
    access_denied = "Access Denied",
    no_permission = "You do not have permission to access the admin menu...",
    no_permission_action = "You do not have permission to do this...",
}

locales.registry = {
    client = {
        player_meta_missing = "Player meta missing or invalid on load.",
        player_loaded = "Player %s (%d) loaded on client.",
        player_data_synced = "Synced category '%s': %s",
        player_data_dump = "Player data dump: %s",
    },
    server = {
        duplicate_extension_name = "Duplicate extension name registered: %s",
        extension_failed = "Extension '%s' failed: %s",
        player_missing = "Player not found for source: %d",
        player_creation_failed = "Failed to create player for source: %d",
        player_loaded = "Player %d loaded",
        player_dropped = "Player %d disconnected",
        disconnected = "You have been disconnected.",
        no_license = "No valid license found.",
        no_temp_data = "No temp data found for license: %s",
        ban_auto_expired = "Auto-expired ban for %s",
        personal_bucket_assigned = "Player %d assigned to bucket %d",
    }
}

locales.weather = {
    server = {
        notify_header = "WEATHER SYSTEM",
        environment_data_missing = "Environment data missing for bucket %d",
        bucket_initialized = "Bucket '%s' (ID: %d) initialized with %s weather",
        weather_changed = "Weather changed to %s in bucket '%s'",
        no_permission = "You don't have permission to use this command",
        bucket_not_found = "Bucket not found",
        weather_usage = "Usage: /pit_weather:setweather <type> [bucket_id]",
        weather_set = "Weather set to %s for bucket %d",
        admin_weather_changed = "%s changed weather to %s in bucket %d",
        time_usage = "Usage: /pit_weather:settime <hour> <minute> [bucket_id] (hour: 0-23, minute: 0-59)",
        time_set = "Time set to %02d:%02d for bucket %d",
        admin_time_changed = "%s changed time to %02d:%02d in bucket %d",
        season_usage = "Usage: /pit_weather:setseason <WINTER|SPRING|SUMMER|AUTUMN> [bucket_id]",
        season_set = "Season set to %s for bucket %d",
        admin_season_changed = "%s changed season to %s in bucket %d",
        weather_frozen = "Weather %s for bucket %d",
        admin_freeze_toggled = "%s toggled weather freeze (%s) in bucket %d",
        dynamic_usage = "Usage: /pit_weather:dynamic <weather|time> <on|off> [bucket_id]",
        dynamic_toggled = "Dynamic %s turned %s for bucket %d",
        admin_dynamic_toggled = "%s toggled dynamic %s (%s) in bucket %d",
    }
}

locales.appearance = {
    client = {
        appearance_data_missing = "Data is missing cant load appearance.",
        genetics = {
            header = "Genetics",
            heritage = "Heritage",
            mother = "Mother",
            father = "Father",
            resemblance = "Resemblance",
            skin = "Skin Tone",
            eyes = "Eyes",
            eye_colour = "Eye Colour",
            eye_opening = "Eye Opening",
            eyebrow_height = "Eyebrow Height",
            eyebrow_depth = "Eyebrow Depth",
            nose = "Nose",
            nose_width = "Nose Width",
            nose_peak_height = "Nose Peak Height",
            nose_peak_length = "Nose Peak Length",
            nose_bone_height = "Nose Bone Height",
            nose_peak_lower = "Nose Peak Lower",
            nose_twist = "Nose Twist",
            cheeks_lips = "Cheeks & Lips",
            cheek_bone = "Cheek Bone",
            cheek_bone_sideways = "Sideways Bone Size",
            cheek_bone_width = "Cheek Bone Width",
            lip_thickness = "Lip Thickness",
            jaw_chin = "Jaw & Chin",
            jaw_bone_width = "Jaw Bone Width",
            jaw_bone_shape = "Jaw Bone Shape",
            chin_bone = "Chin Bone",
            chin_bone_length = "Chin Bone Length",
            chin_bone_shape = "Chin Bone Shape",
            chin_hole = "Chin Hole",
            neck = "Neck",
            neck_thickness = "Neck Thickness"
        },
        barber = {
            header = "Barber",
            hair = "Hair",
            hair_colour = "Hair Colour",
            fade = "Fade",
            fade_colour = "Fade Colour",
            eyebrows = "Eyebrows",
            eyebrow = "Eyebrow",
            eyebrow_opacity = "Eyebrow Opacity",
            eyebrow_colour = "Eyebrow Colour",
            facial_hair = "Facial Hair",
            facial_hair_opacity = "Facial Hair Opacity",
            facial_hair_colour = "Facial Hair Colour",
            chest_hair = "Chest Hair",
            chest_hair_opacity = "Chest Hair Opacity",
            chest_hair_colour = "Chest Hair Colour",
            makeup = "Make Up",
            make_up = "Make Up",
            make_up_opacity = "Make Up Opacity",
            make_up_colour = "Make Up Colour",
            blush = "Blush",
            blush_opacity = "Blush Opacity",
            blush_colour = "Blush Colour",
            lipstick = "Lipstick",
            lipstick_opacity = "Lipstick Opacity",
            lipstick_colour = "Lipstick Colour",
            skin = "Skin",
            blemish = "Blemish",
            blemish_opacity = "Blemish Opacity",
            body_blemish = "Body Blemish",
            body_blemish_opacity = "Body Blemish Opacity",
            ageing = "Ageing",
            ageing_opacity = "Ageing Opacity",
            complexion = "Complexion",
            complexion_opacity = "Complexion Opacity",
            sun_damage = "Sun Damage",
            sun_damage_opacity = "Sun Damage Opacity",
            moles = "Moles",
            moles_opacity = "Moles Opacity"
        },
        tattoos = {
            header = "Tattoos",
            ZONE_HEAD = "Head",
            ZONE_HAIR = "Hair",
            ZONE_TORSO = "Torso",
            ZONE_LEFT_ARM = "Left Arm",
            ZONE_RIGHT_ARM = "Right Arm",
            ZONE_LEFT_LEG = "Left Leg",
            ZONE_RIGHT_LEG = "Right Leg"
        }
    }
}

locales.statuses = {
    commands = {
        notify_header = "ADMIN",
        player_not_found = "Player not found.",
        player_revived = "Player %d has been revived.",
        player_killed = "Player %d has been killed.",
        player_downed = "Player %d has been downed.",
    },
    log_player_revived = "Player %s was revived.",
    log_player_died = "Player %s died.",
    log_player_downed = "Player %s was downed.",
    log_player_picked_up = "Player %s was picked up.",
}

locales.inventory = {
    client = {
        ui = {
            open = "OPEN",
            closed = "CLOSED",
            unknown = "unknown",
            vehicle_missing = "[Vehicle Container] Vehicle does not exist",
            vehicle_toggle = "[Vehicle Container] Setting %s to %s",
            glovebox_no_anim = "[Vehicle Container] Glovebox access (no animation)",
            server_id = "Server ID: %d",
            equipment = "Equipment",
            inventory = "Inventory",
            vicinity = "Vicinity",
            ground = "Ground",
            glovebox = "Glovebox",
            trunk = "Trunk",
            unequip = "Unequip",
            head_view = "Head View",
            body_view = "Body View",
            guide = "Guide",
            close = "Close",
            opening_guide = "Opening inventory guide...",
            pick_up = "Pick Up",
            use = "Use",
            split_stack = "Split Stack",
            quantity = "Quantity",
            confirm = "Confirm",
            cancel = "Cancel",
            modal_data = "modal data: %s",
            no_actions = "no actions %s",
            item_def_missing = "Item definition missing: %s",
            anim_data_missing = "Animation data missing",
            clothing = {
                hat = "Hat",
                mask = "Mask",
                glasses = "Glasses",
                earrings = "Earrings",
                necklace = "Necklace",
                shirt = "Shirt",
                gloves = "Gloves",
                bracelet = "Bracelet",
                watch = "Watch",
                pants = "Pants",
                bag = "Bag",
                top = "Top",
                hair = "Hair",
                reset = "Reset",
                visor = "Visor",
                shoes = "Shoes",
                reset_title = "Reset Clothing",
                reset_desc = "Reset all clothing to default",
                reset_all = "Reset All",
                toggle = "Toggle",
                toggle_desc = "Toggle your %s on/off"
            },

            slot = {
                helmet = "Helmet",
                mask = "Mask",
                shirt = "Shirt",
                vest = "Vest",
                backpack = "Backpack",
                pants = "Pants",
                shoes = "Shoes",
                primary = "Primary",
                secondary = "Secondary",
                melee = "Melee"
            },

            vehicle = {
                already_open = "This vehicle is already being accessed by another player",
                lock_failed = "Failed to lock vehicle container",
                opened = "Vehicle container opened",
                closed = "Vehicle container closed"
            }
        },
    }
}

return locales