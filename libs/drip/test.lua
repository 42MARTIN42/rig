RegisterCommand("drip:test", function()
    if drip.is_menu_open() then drip.close_menu() return end

    drip.open_menu({
        id = "drip_master_test",
        root = "main",
        style = {x = 0.015, y = 0.0275, width = 0.22},
        menus = {
            main = {
                title = "DRIP MASTER TEST",
                items = {
                    {type = "submenu", label = "Notifications", desc = "Test alert types.", submenu = "notif_test"},
                    {type = "submenu", label = "Input Fields", desc = "Test selectors and numbers.", submenu = "input_test"},
                    {
                        type = "action", 
                        label = "Keyboard Input",
                        desc = "Open the on-screen grid keyboard.",
                        keep_open = true,
                        on_action = function()
                            drip.open_keyboard({
                                title = "TEST KEYBOARD",
                                default = "DRIP",
                                keep_open = true,
                                on_confirm = function(val)
                                    drip.notify({header = "Keyboard", type = "success", message = "Value: " .. val, duration = 3000, style = { x = 0.785, y = 0.0275, width = 0.20 } })
                                end
                            })
                        end
                    },
                    {
                        type = "action", 
                        label = "Toggle Info Panels", 
                        desc = "Display UI panels for camera/status.",
                        keep_open = true,
                        on_action = function()
                            if drip.is_panel_visible("controls") then
                                drip.hide_panel("controls")
                                drip.hide_panel("status")
                            else
                                drip.show_panel({
                                    id = "controls",
                                    title = "Free Camera",
                                    style = {x = 0.015, y = 0.35, width = 0.14},
                                    lines = {
                                        {key = "[W/A/S/D]", value = "Move"},
                                        {key = "[Q/E]", value = "Up / Down"},
                                        {key = "[SHIFT]", value = "Fast"},
                                        {key = "[BACKSPACE]", value = "Exit"},
                                    }
                                })
                                drip.show_panel({
                                    id = "status",
                                    title = "Server Status",
                                    style = {x = 0.015, y = 0.60, width = 0.14},
                                    lines = {
                                        {key = "Time", value = function() return string.format("%02d:%02d", GetClockHours(), GetClockMinutes()) end},
                                        {key = "Zone", value = function() return GetLabelText(GetNameOfZone(table.unpack(GetEntityCoords(PlayerPedId())))) end},
                                    }
                                })
                            end
                        end
                    },
                    {type = "separator"},
                    {type = "close", label = "Close Menu", desc = "Exit the test suite."}
                }
            },
            notif_test = {
                title = "Notifications",
                items = {
                    {type = "action", label = "Info Notify", keep_open = true, on_action = function() drip.notify({header = "Info", type = "info", message = "This is a info notification.", duration = 3000, style = { x = 0.785, y = 0.0275, width = 0.20 }}) end},
                    {type = "action", label = "Success Notify", keep_open = true, on_action = function() drip.notify({header = "Success", type = "success", message = "This is a success notification.", duration = 3000, style = { x = 0.785, y = 0.0275, width = 0.20 }}) end},
                    {type = "action", label = "Error Notify", keep_open = true, on_action = function() drip.notify({header = "Error", type = "error", message = "This is a error notification.", duration = 3000, style = { x = 0.785, y = 0.0275, width = 0.20 }}) end},
                    {type = "action", label = "Warning Notify", keep_open = true, on_action = function() drip.notify({header = "Warning", type = "warning", message = "This is a warning notification.", duration = 3000, style = { x = 0.785, y = 0.0275, width = 0.20 }}) end},
                    {type = "separator"},
                    {type = "back", key = "main", label = "Back"}
                }
            },
            input_test = {
                title = "Input Suite",
                items = {
                    {
                        type = "action", 
                        label = "Open Multi-Input",
                        keep_open = true, 
                        on_action = function()
                            drip.open_input({
                                title = "User Settings",
                                keep_open = true,
                                inputs = {
                                    {id = "char_name", type = "select", label = "Character", options = {"Case", "Boii", "Dev"}},
                                    {id = "spawn_lvl", type = "number", label = "Level", min = 1, max = 10, step = 1, default = 5},
                                },
                                on_confirm = function(values)
                                    drip.notify({header = "Input Result", type = "info", message = "Selected: " .. values.char_name .. " Level: " .. values.spawn_lvl, duration = 3000, style = { x = 0.785, y = 0.0275, width = 0.20 }})
                                end
                            })
                        end
                    },
                    {type = "separator"},
                    {type = "back", key = "main", label = "Back"}
                }
            }
        }
    })
end, false)