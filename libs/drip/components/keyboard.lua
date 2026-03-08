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

if IsDuplicityVersion() then return end

--- @file keyboard
--- @description On-screen grid keyboard using dedicated keyboard key mapping.

--- @section Constants

local KEY_UP = drip.keycodes[drip.keys.keyboard.up] or 172
local KEY_DOWN = drip.keycodes[drip.keys.keyboard.down] or 173
local KEY_LEFT = drip.keycodes[drip.keys.keyboard.left] or 174
local KEY_RIGHT = drip.keycodes[drip.keys.keyboard.right] or 175
local KEY_ENTER = drip.keycodes[drip.keys.keyboard.confirm] or 191
local KEY_BACK = drip.keycodes[drip.keys.keyboard.back] or 177

local LAYOUT = {
    {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"},
    {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"},
    {"A", "S", "D", "F", "G", "H", "J", "K", "L", "!"},
    {"Z", "X", "C", "V", "B", "N", "M", ",", ".", "?"},
    {"BACKSPACE", "SPACE", "DONE"}
}

--- @section State

local _active_kb = nil
local _kb_visible = false

--- @class Keyboard

local Keyboard = {}
Keyboard.__index = Keyboard

function Keyboard.new(data)
    local style = data.style or {}
    return setmetatable({
        title = (data.title or "ENTER TEXT"):upper(),
        current_text = data.default or "",
        row = 1,
        col = 1,
        keep_open = data.keep_open or false,
        on_confirm = data.on_confirm,
        on_cancel = data.on_cancel,
        width = style.width or 0.35,
        x = nil,
        y = nil,
        key_h = 0.032,
        colours = drip.style.colours
    }, Keyboard)
end

function Keyboard:get_height()
    return (#LAYOUT * self.key_h) + 0.11
end

function Keyboard:nav(dr, dc)
    local new_row = math.max(1, math.min(#LAYOUT, self.row + dr))
    local new_col = math.max(1, math.min(#LAYOUT[new_row], self.col + dc))
    self.row, self.col = new_row, new_col
end

function Keyboard:press()
    local key = LAYOUT[self.row][self.col]
    if key == "DONE" then
        local val = self.current_text
        if not self.keep_open then
            drip.close_keyboard()
            Wait(10)
        end
        if self.on_confirm then self.on_confirm(val) end
    elseif key == "BACKSPACE" then
        self.current_text = self.current_text:sub(1, -2)
    elseif key == "SPACE" then
        self.current_text = self.current_text .. " "
    else
        self.current_text = self.current_text .. key
    end
end

function Keyboard:draw()
    local c = self.colours
    local w = self.width
    local box_h = self:get_height()
    local x = self.x or (0.5 - w / 2)
    local y = self.y or (0.45 - box_h / 2)
    local cx, cy = x + w / 2, y + box_h / 2
    DrawRect(cx, cy, w, box_h, drip.colour(c, "bg"))
    DrawRect(cx, cy, w - 0.001, box_h - 0.001, drip.colour(c, "bg_inner"))
    local hcy = y + (drip.style.header_height / 2)
    DrawRect(cx, hcy, w, drip.style.header_height, drip.colour(c, "header"))
    DrawRect(cx, y + 0.0005, w, 0.0015, drip.colour(c, "accent"))
    local hr, hg, hb, ha = drip.colour(c, "header_text")
    drip.draw_text(self.title, cx, hcy - 0.012, drip.style.header_font, drip.style.header_scale, hr, hg, hb, ha, true)
    local d_y = y + 0.06
    DrawRect(cx, d_y, w - 0.02, 0.035, drip.colour(c, "bg_inner", 100))
    drip.draw_text(self.current_text .. "_", cx, d_y - 0.012, drip.style.text_font, 0.35, 255, 255, 255, 255, true)
    local start_y = d_y + 0.03
    for r, row in ipairs(LAYOUT) do
        local key_w = (w - 0.02) / #row
        for col_idx, char in ipairs(row) do
            local is_sel = (self.row == r and self.col == col_idx)
            local kx = (x + 0.01) + (col_idx * key_w) - (key_w / 2)
            local ky = start_y + (r * self.key_h)
            if is_sel then
                DrawRect(kx, ky, key_w - 0.002, self.key_h - 0.002, drip.colour(c, "highlight"))
                DrawRect(kx, ky + (self.key_h/2) - 0.001, key_w - 0.002, 0.0015, drip.colour(c, "accent"))
            end
            local tr, tg, tb, ta = drip.colour(c, is_sel and "text_sel" or "text")
            drip.draw_text(char, kx, ky - 0.011, drip.style.text_font, 0.26, tr, tg, tb, ta, true)
        end
    end
end

--- @section API

function drip.is_keyboard_open()
    return _kb_visible
end

function drip.close_keyboard()
    _kb_visible = false
    _active_kb = nil
end

function drip.open_keyboard(data)
    _active_kb = Keyboard.new(data)
    _kb_visible = true
end

--- @section Threads
CreateThread(function()
    while true do
        Wait(0)
        if _kb_visible and _active_kb then
            _active_kb:draw()
            
            DisableControlAction(0, KEY_UP, true)
            DisableControlAction(0, KEY_DOWN, true)
            DisableControlAction(0, KEY_LEFT, true)
            DisableControlAction(0, KEY_RIGHT, true)
            DisableControlAction(0, KEY_ENTER, true)
            DisableControlAction(0, KEY_BACK, true)
            
            if IsDisabledControlJustPressed(0, KEY_UP) then
                _active_kb:nav(-1, 0)
            elseif IsDisabledControlJustPressed(0, KEY_DOWN) then
                _active_kb:nav(1, 0)
            elseif IsDisabledControlJustPressed(0, KEY_LEFT) then
                _active_kb:nav(0, -1)
            elseif IsDisabledControlJustPressed(0, KEY_RIGHT) then
                _active_kb:nav(0, 1)
            elseif IsDisabledControlJustPressed(0, KEY_ENTER) then
                _active_kb:press()
            elseif IsDisabledControlJustPressed(0, KEY_BACK) then 
                local inst = _active_kb
                drip.close_keyboard()
                if inst and inst.on_cancel then inst.on_cancel() end
            end
        end
    end
end)