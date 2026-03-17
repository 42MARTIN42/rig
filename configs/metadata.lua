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

--- @module configs.metadata
--- @description Metadata labels and display values for items

return {

    --- @section Items

    rarity = { -- Metadata type: item rarity classification
        display = true, -- Whether this metadata is shown in the UI
        label = "Rarity", -- UI label text
        values = { -- Allowed values and their display labels
            common = { label = "Common" }, -- Lowest tier
            uncommon = { label = "Uncommon" },
            rare = { label = "Rare" },
            epic = { label = "Epic" },
            legendary = { label = "Legendary" } -- Highest tier
        }
    },

    quality = { -- Degradable item value (used for consumables, food, etc.)
        display = true, -- Show in UI
        label = "Quality", -- UI label
        suffix = "%" -- Appended to value when displayed
    },

    durability = { -- Condition value (typically for weapons / tools)
        display = true,
        label = "Durability",
        suffix = "%"
    },

    degrade_rate = { -- Rate at which quality/durability decays
        display = true,
        label = "Degrade Rate",
        suffix = "%"
    },

    ammo = { -- Current ammo loaded into a weapon
        display = true,
        label = "Ammo"
    },

    ammo_types = { -- Supported ammo items for a weapon
        display = true,
        label = "Ammo Type",
        values = { -- Maps ammo item IDs to display names
            ammo_9mm = { label = "9mm" },
            ammo_rifle = { label = "5.56mm" },
            ammo_shotgun = { label = "12 Gauge" },
            ammo_sniper = { label = "7.62mm" }
        }
    },

    ammo_refill = {
        display = true,
        label = "Rounds Per Use"
    },

    serial = { -- Weapon serial number (identification / tracking)
        display = false,
        label = "Serial"
    },

    attachments = { -- Attached weapon components (internal use)
        display = false, -- Hidden from UI by default
        label = "Attachments"
    }

}