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

--- @file src.client.loadscreen
--- @description Handles load screen stuff, nothing important.

--- @section Variables

local has_clicked_play = false

--- @section NUI Callbacks

--- Handles the play button click, fading out the screen and triggering the server to fetch appearance data.
RegisterNUICallback("loadscreen:play", function(data, cb)
    if has_clicked_play then return end
    log("info", locale("connected"))
    has_clicked_play = true
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(50) end
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    Wait(350)
    TriggerServerEvent("rig:sv:fetch_appearance")
    cb(true)
end)

--- Handles the disconnect action
RegisterNUICallback("loadscreen:disconnect", function(data, cb)
    TriggerServerEvent("rig:sv:disconnect")
    cb(true)
end)

--- @section Threads

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do 
        Wait(250) 
    end
    Wait(1000)
    print("connecting sending loadscreen message")
    SendLoadingScreenMessage(json.encode({ action = "load_complete" }))
end)