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

--- @class Appearance
--- @description Player appearance extension for character customization.

--- @section Imports

local tables = require("libs.graft.standalone.tables")
local cfg_appearance = require("configs.appearance")

--- @section Class

local Appearance = {}

--- @section Data Defaults

local DEFAULT_STYLES = tables.copy(cfg_appearance._defaults)

--- @section Lifecycle

function Appearance:on_load()
    local player = self.player
    local unique_id = player.unique_id
    
    --- @section Player Data
    
    local result = MySQL.query.await("SELECT * FROM rig_player_appearances WHERE unique_id = ?", { unique_id })
    local appearance

    if not result or #result == 0 then
        MySQL.insert.await("INSERT INTO rig_player_appearances (unique_id, sex, genetics, barber, clothing, tattoos, has_customised) VALUES (?, ?, ?, ?, ?, ?, ?)", {
                unique_id,
                "m",
                json.encode(DEFAULT_STYLES.m.genetics),
                json.encode(DEFAULT_STYLES.m.barber),
                json.encode(DEFAULT_STYLES.m.clothing),
                json.encode(DEFAULT_STYLES.m.tattoos),
                0
            }
        )
        appearance = {
            sex = "m",
            genetics = DEFAULT_STYLES.m.genetics,
            barber = DEFAULT_STYLES.m.barber,
            clothing = DEFAULT_STYLES.m.clothing,
            tattoos = DEFAULT_STYLES.m.tattoos,
            has_customised = false
        }
    else
        local row = result[1]
        local sex = row.sex or "m"
        appearance = {
            sex = sex,
            genetics = json.decode(row.genetics) or DEFAULT_STYLES[sex].genetics,
            barber = json.decode(row.barber) or DEFAULT_STYLES[sex].barber,
            clothing = json.decode(row.clothing) or DEFAULT_STYLES[sex].clothing,
            tattoos = json.decode(row.tattoos) or DEFAULT_STYLES[sex].tattoos,
            has_customised = row.has_customised
        }
    end

    player:add_data("appearance", appearance, true)
    
    --- @section Methods
    
    --- Getters

    player:add_method("get_appearance", function()
        return player:get_data("appearance")
    end)

    player:add_method("get_sex", function()
        return player:get_data("appearance").sex
    end)

    player:add_method("get_genetics", function()
        return player:get_data("appearance").genetics
    end)

    player:add_method("get_barber", function()
        return player:get_data("appearance").barber
    end)

    player:add_method("get_clothing", function()
        return player:get_data("appearance").clothing
    end)

    player:add_method("get_tattoos", function()
        return player:get_data("appearance").tattoos
    end)

    --- Setters

    player:add_method("set_sex", function(sex)
        if sex ~= "m" and sex ~= "f" then return false end
        return player:set_data("appearance", {
            sex = sex,
            genetics = DEFAULT_STYLES[sex].genetics,
            barber = DEFAULT_STYLES[sex].barber,
            clothing = DEFAULT_STYLES[sex].clothing,
            tattoos = DEFAULT_STYLES[sex].tattoos,
            has_customised = true
        }, true)
    end)

    player:add_method("set_genetics", function(genetics)
        if not genetics or type(genetics) ~= "table" then return false end
        return player:set_data("appearance", {
            genetics = genetics,
            has_customised = true
        }, true)
    end)

    player:add_method("set_barber", function(barber)
        if not barber or type(barber) ~= "table" then return false end
        return player:set_data("appearance", {
            barber = barber,
            has_customised = true
        }, true)
    end)

    player:add_method("set_clothing", function(clothing)
        if not clothing or type(clothing) ~= "table" then return false end
        return player:set_data("appearance", {
            clothing = clothing,
            has_customised = true
        }, true)
    end)

    player:add_method("set_tattoos", function(tattoos)
        if not tattoos or type(tattoos) ~= "table" then return false end
        return player:set_data("appearance", {
            tattoos = tattoos,
            has_customised = true
        }, true)
    end)

    --- Validation

    player:add_method("has_customised_appearance", function()
        return player:get_data("appearance").has_customised
    end)

    --- Saving

    player:add_method("save_appearance", function(sex, style)
        if not sex or (sex ~= "m" and sex ~= "f") or not style or type(style) ~= "table" then 
            return false 
        end
        return player:set_data("appearance", {
            sex = sex,
            genetics = style.genetics,
            barber = style.barber,
            clothing = style.clothing,
            tattoos = style.tattoos,
            has_customised = true
        }, true)
    end)
end

function Appearance:on_save()
    local appearance = self.player:get_data("appearance")
    if not appearance then return end
    return {{
        query = "INSERT INTO rig_player_appearances (unique_id, sex, genetics, barber, clothing, tattoos, has_customised) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE sex = VALUES(sex), genetics = VALUES(genetics), barber = VALUES(barber), clothing = VALUES(clothing), tattoos = VALUES(tattoos), has_customised = VALUES(has_customised)",
        values = { self.player.unique_id, appearance.sex, json.encode(appearance.genetics), json.encode(appearance.barber), json.encode(appearance.clothing), json.encode(appearance.tattoos), appearance.has_customised and 1 or 0 }
    }}
end

return Appearance