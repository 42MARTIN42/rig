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

--- @module configs.items
--- @description Handles all static data for items.

return {

    --- @section Food/Drinks

    water = {
        label = "Water",
        description = {
            "A refreshing bottle of clean water.",
            "Can be purchased from most stores."
        },
        image = "water.png",
        weight = 330,
        w = 1,
        h = 2,
        metadata = {
            rarity = "common",
            quality = 100,
            degrade_rate = 0.25
        },
        actions = {
            drop = {
                model = "ba_prop_club_water_bottle"
            },
            use = {
                animation = {
                    progress = { message = "Drinking Water.." },
                    dict = "mp_player_intdrink",
                    anim = "loop_bottle",
                    flags = 49,
                    duration = 5000,
                    freeze = false,
                    continuous = false,
                    props = {
                        {
                            model = "ba_prop_club_water_bottle",
                            bone = 60309,
                            coords = { x = 0.0, y = 0.0, z = -0.05 },
                            rotation = { x = 0.0, y = 0.0, z = 0.0 },
                            soft_pin = false,
                            collision = false,
                            is_ped = true,
                            rot_order = 1,
                            sync_rot = true
                        }
                    },
                    callback = function(source, data)
                        local p = core.players:get(source)
                        if not p then return end
                        local removed = p:run_method("remove_item", { col = data.col, row = data.row }, 1, data.group)
                        if not removed then return end
                        local statuses = p:run_method("get_statuses")
                        p:run_method("set_statuses", {
                            thirst = math.min(100, (statuses.thirst or 0) + 40)
                        })
                        TriggerClientEvent("rig:cl:inventory_changed", source)
                        p:sync()
                    end
                }
            }
        }
    },

    --- @section Ammo

    ammo_9mm = {
        label = "9mm Ammo",
        description = "Standard 9x19mm Parabellum ammunition",
        image = "ammo_9mm.png",
        weight = 8,
        w = 1,
        h = 1,
        stackable = 50,
        category = "ammo",
        metadata = {
            ammo_refill = 12,
        },
        actions = {
            drop = true,
            use = true
        }
    },

    --- @section Attachments

    pistol_mag_extended = {
        label = "Extended Mag: Pistol",
        description = {
            "Extended magazine for supported 9mm pistols."
        },
        image = "pistol_mag_extended.png",
        weight = 250,
        w = 1,
        h = 1,
        category = "attachments",
        metadata = {
            rarity = "rare",
        },
        actions = {
            drop = true,
            use = {
                attachments = {
                    { weapon = "weapon_pistol", component = "COMPONENT_PISTOL_CLIP_02" },
                    { weapon = "weapon_pistol_mk2", component = "COMPONENT_PISTOL_MK2_CLIP_02" },
                    { weapon = "weapon_combatpistol", component = "COMPONENT_COMBATPISTOL_CLIP_02" },
                    { weapon = "weapon_appistol", component = "COMPONENT_APPISTOL_CLIP_02" },
                    { weapon = "weapon_pistol50", component = "COMPONENT_PISTOL50_CLIP_02" },
                    { weapon = "weapon_snspistol", component = "COMPONENT_SNSPISTOL_CLIP_02" },
                    { weapon = "weapon_snspistol_mk2", component = "COMPONENT_SNSPISTOL_MK2_CLIP_02" },
                    { weapon = "weapon_heavypistol", component = "COMPONENT_HEAVYPISTOL_CLIP_02" },
                    { weapon = "weapon_vintagepistol", component = "COMPONENT_VINTAGEPISTOL_CLIP_02" },
                    { weapon = "weapon_ceramicpistol", component = "COMPONENT_CERAMICPISTOL_CLIP_02" }
                }
            }
        }
    },

    --- @section Weapons

    weapon_pistol = {
        label = "Pistol",
        description = "9mm semi-automatic pistol",
        image = "weapon_pistol.png",
        weight = 710,
        w = 1,
        h = 2,
        stackable = false,
        category = "weapon",
        metadata = {
            rarity = "common",
            serial = "",
            ammo = 0,
            ammo_types = { "ammo_9mm" },
            attachments = {},
            durability = 100
        },
        actions = {
            drop = { model = "w_pi_pistol" },
            use = true
        }
    },

    --- @section Player Inventories

    dufflebag = {
        label = "Dufflebag",
        description = "It's a duffle, it holds things.",
        image = "dufflebag.png",
        weight = 1000,
        w = 2,
        h = 2,
        stackable = false,
        category = "player_inventory",
        metadata = {
            equipped = false
        },
        actions = {
            drop = {
                model = "ch_prop_ch_duffbag_gruppe_01a"
            },
            use = {
                inventory_group = "dufflebag",
                loadout_slot = "backpack",
                clothing = {
                    component_id = 5,
                    drawable = 45,
                    texture = 0,
                    male = { drawable = 45, texture = 0 },
                    female = { drawable = 45, texture = 0 }
                },
                animation = {
                    progress = { message = "Equipping backpack..." },
                    dict = "clothingshirt",
                    anim = "try_shirt_positive_d",
                    flags = 49,
                    duration = 2000,
                    freeze = false,
                    continuous = false,
                    callback = function(source, data)
                        core.toggle_player_inventory(source, data)
                    end
                }
            }
        }
    }

}