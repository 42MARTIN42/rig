--[[
--------------------------------------------------

This file is part of DRIP.
You are free to use these files within your own resources.
Please retain the original credit and attached MIT license.
Support honest development.

Author: Case @ BOII Development
License: MIT (https://github.com/boiidevelopment/drip/blob/main/LICENSE)
GitHub: https://github.com/boiidevelopment/drip

--------------------------------------------------
]]

--- @script init
--- @description Main initialization file

--- @section Bootstrap

drip = {setmetatable({}, { __index = _G })}

--- @section Keys

drip.keycodes = {
    ["enter"] = 191,
    ["escape"] = 322,
    ["backspace"] = 177,
    ["tab"] = 37,
    ["arrowleft"] = 174,
    ["arrowright"] = 175,
    ["arrowup"] = 172,
    ["arrowdown"] = 173,
    ["space"] = 22,
    ["delete"] = 178,
    ["insert"] = 121,
    ["home"] = 213,
    ["end"] = 214,
    ["pageup"] = 10,
    ["pagedown"] = 11,
    ["leftcontrol"] = 36,
    ["leftshift"] = 21,
    ["leftalt"] = 19,
    ["rightcontrol"] = 70,
    ["rightshift"] = 70,
    ["rightalt"] = 70,
    ["numpad0"] = 108,
    ["numpad1"] = 117,
    ["numpad2"] = 118,
    ["numpad3"] = 60,
    ["numpad4"] = 107,
    ["numpad5"] = 110,
    ["numpad6"] = 109,
    ["numpad7"] = 117,
    ["numpad8"] = 111,
    ["numpad9"] = 112,
    ["numpad+"] = 96,
    ["numpad-"] = 97,
    ["numpadenter"] = 191,
    ["numpad."] = 108,
    ["f1"] = 288,
    ["f2"] = 289,
    ["f3"] = 170,
    ["f4"] = 168,
    ["f5"] = 166,
    ["f6"] = 167,
    ["f7"] = 168,
    ["f8"] = 169,
    ["f9"] = 56,
    ["f10"] = 57,
    ["a"] = 34,
    ["b"] = 29,
    ["c"] = 26,
    ["d"] = 30,
    ["e"] = 46,
    ["f"] = 49,
    ["g"] = 47,
    ["h"] = 74,
    ["i"] = 27,
    ["j"] = 36,
    ["k"] = 311,
    ["l"] = 182,
    ["m"] = 244,
    ["n"] = 249,
    ["o"] = 39,
    ["p"] = 199,
    ["q"] = 44,
    ["r"] = 45,
    ["s"] = 33,
    ["t"] = 245,
    ["u"] = 303,
    ["v"] = 0,
    ["w"] = 32,
    ["x"] = 73,
    ["y"] = 246,
    ["z"] = 20,
    ["mouse1"] = 24,
    ["mouse2"] = 25
}

drip.keys = {
    input = {
        up = "arrowup",
        down = "arrowdown",
        left = "arrowleft",
        right = "arrowright",
        confirm = "enter",
        close = "escape"
    },
    menu = {
        up = "arrowup",
        down = "arrowdown",
        left = "arrowleft",
        right = "arrowright",
        confirm = "enter",
        back = "backspace",
        switch_menu = "tab"
    },
    keyboard = {
        up = "arrowup",
        down = "arrowdown",
        left = "arrowleft",
        right = "arrowright",
        confirm = "enter",
        back = "backspace",
    }
}

--- @section Style

drip.style = {
    x = 0.015,
    y = 0.0275,
    width = 0.22,
    gap = 0.006,
    max_vis = 10,
    wrap = 50,
    header_font = 4,
    header_scale = 0.34,
    header_height = 0.030,
    text_font = 0,
    text_scale = 0.30,
    line_h = 0.024,
    pad_x = 0.008,
    pad_y = 0.006,
    val_w = 0.07,
    colours = {
        bg = {0, 0, 0, 180},
        bg_inner = {255, 255, 255, 15},
        header = {20, 20, 20, 255},
        header_text = {255, 255, 255, 255},
        text = {220, 220, 220, 220},
        text_sel = {255, 255, 255, 255},
        text_dim = {160, 160, 160, 200},
        highlight = {255, 255, 255, 30},
        accent = {228, 173, 41, 255},
        separator = {255, 255, 255, 30},
        toggle_on = {80, 200, 120, 255},
        toggle_off = {200, 80, 80, 255},
        slider_bg = {60, 60, 60, 200},
        val_bg = {60, 60, 60, 200},
        val_fill = {228, 173, 41, 180},
        success = {80, 200, 120, 255},
        error = {200, 80, 80, 255},
        info = {80, 160, 255, 255},
        warning = {228, 173, 41, 255},
        key = {228, 173, 41, 255},
        value = {220, 220, 220, 220},
    }
}

--- @section Utility Functions

function drip.resolve_style(style, key)
    if style and style[key] ~= nil then return style[key] end
    return drip.style[key]
end

function drip.colour(colours, key, alpha_override)
    local c = colours[key] or {255, 255, 255, 255}
    return c[1], c[2], c[3], alpha_override or c[4]
end
drip.color = drip.colour

function drip.draw_text(str, x, y, font, scale, r, g, b, a, centre, shadow)
    SetTextFont(font or drip.style.text_font)
    SetTextScale(scale or drip.style.text_scale, scale or drip.style.text_scale)
    SetTextColour(r or 255, g or 255, b or 255, a or 255)
    SetTextCentre(centre and 1 or 0)
    if shadow then SetTextDropShadow() end
    SetTextEntry("STRING")
    AddTextComponentString(str)
    DrawText(x, y)
end

function drip.wrap_text(str, limit)
    local lines = {}
    local current = ""
    for word in str:gmatch("%S+") do
        if #current + #word + 1 > limit then
            lines[#lines + 1] = current
            current = word
        else
            current = current == "" and word or current .. " " .. word
        end
    end
    if current ~= "" then lines[#lines + 1] = current end
    return lines
end

--- @section API Export

--exports("api", drip)

--- @section Namespace Protection

SetTimeout(250, function()
    setmetatable(drip, {
        __newindex = function(_, key)
            error("Attempted to modify locked namespace", 2)
        end
    })
    
    print("[drip] namespace locked and ready")
end)