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

--- @section Events

RegisterServerEvent("rig:sv:fetch_appearance", function()
    local _src = source
    local player = core.create_player(_src)
    if not player then log("error", locale("player_creation_failed", _src)) return end
    local appearance = player:run_method("get_appearance")
    if not appearance or not appearance.has_customised then
        TriggerClientEvent("rig:cl:create_first_appearance", _src)
        return
    end
    TriggerClientEvent("rig:cl:load_appearance", _src, appearance)
end)

RegisterServerEvent("rig:sv:save_appearance", function(sex, style)
    local _src = source
    local player = core.players:get(_src)
    if not player then log("error", locale("player_missing", _src)) return end
    if not sex or not style then log("error", "Appearance data missing, cant save.") return end
    local result = player:run_method("save_appearance", sex, style)
    if result then
        player:save()
        log("info", "Appearance saved for player: " .. player.unique_id)
        TriggerClientEvent("rig:cl:load_appearance", _src, style)
    else
        log("error", "Failed to save appearance for player: " .. player.unique_id)
    end
end)