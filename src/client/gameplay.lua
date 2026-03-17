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

--- @script src.client.gameplay
--- @description Handles client side gameplay loop

--- @section Config

local hud_components = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 13, 19, 20, 21, 22 }
local disable_controls = {
    37, 157, 158, 160, 161, 256, 257
}

--- @section Setup

for i = 1, 15 do EnableDispatchService(i, false) end
SetAudioFlag("PoliceScannerDisabled", true)
SetGarbageTrucks(false)
SetCreateRandomCops(false)
SetCreateRandomCopsNotOnScenarios(false)
SetCreateRandomCopsOnScenarios(false)
SetWeaponsNoAutoreload(true)
SetWeaponsNoAutoswap(true)

--- @section Threads

local player_id = PlayerId()

CreateThread(function()
    while true do
        for i = 1, #hud_components do HideHudComponentThisFrame(hud_components[i]) end
        for i = 1, #disable_controls do DisableControlAction(0, disable_controls[i], true) end
        DisplayAmmoThisFrame(false)
        InvalidateIdleCam()
        InvalidateVehicleIdleCam()
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        ClearPlayerWantedLevel(player_id)
        SetArtificialLightsState(true)
        SetArtificialLightsStateAffectsVehicles(true)
        Wait(100)
    end
end)