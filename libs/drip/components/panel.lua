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

--- @file panel
--- @description Panel component. Data driven KVP text panel, supports multiple instances via id.

--- @section State

local _panels = {}

--- @class Panel

local Panel = {}
Panel.__index = Panel

function Panel.new(data)
    local style = data.style or {}
    local colours = {}
    for k, v in pairs(drip.style.colours) do colours[k] = v end
    if style.colours then
        for k, v in pairs(style.colours) do colours[k] = v end
    end
    return setmetatable({
        id = data.id,
        title = data.title or "Panel",
        lines = type(data.lines) == "table" and data.lines or {data.lines},
        x = drip.resolve_style(style, "x"),
        y = drip.resolve_style(style, "y"),
        width = drip.resolve_style(style, "width"),
        header_font = drip.resolve_style(style, "header_font"),
        header_scale = drip.resolve_style(style, "header_scale"),
        header_height = drip.resolve_style(style, "header_height"),
        text_font = drip.resolve_style(style, "text_font"),
        text_scale = drip.resolve_style(style, "text_scale"),
        line_h = drip.resolve_style(style, "line_h"),
        pad_x = drip.resolve_style(style, "pad_x"),
        pad_y = drip.resolve_style(style, "pad_y"),
        colours = colours,
    }, Panel)
end

function Panel:get_height()
    return self.header_height + (#self.lines * self.line_h) + (self.pad_y * 2)
end

function Panel:draw()
    local x = self.x
    local y = self.y
    local w = self.width
    local cx = x + w / 2
    local box_h = self:get_height()
    local c = self.colours

    DrawRect(cx, y + box_h / 2, w, box_h, drip.colour(c, "bg"))
    DrawRect(cx, y + box_h / 2, w - 0.001, box_h - 0.001, drip.colour(c, "bg_inner"))

    local hcy = y + self.header_height / 2
    DrawRect(cx, hcy, w, self.header_height, drip.colour(c, "header"))
    DrawRect(cx, hcy - (self.header_height / 2) + 0.001, w, 0.002, drip.colour(c, "key"))
    local hr, hg, hb, ha = drip.colour(c, "header_text")
    drip.draw_text(self.title, cx, hcy - 0.0125, self.header_font, self.header_scale, hr, hg, hb, ha, true)
    for i, line in ipairs(self.lines) do
        local ly = y + self.header_height + self.pad_y + ((i - 1) * self.line_h)
        if type(line) == "table" then
            local kc = line.key_colour or c.key
            local vc = line.value_colour or c.value
            local val = type(line.value) == "function" and tostring(line.value()) or tostring(line.value or "")
            drip.draw_text(line.key or "", x + self.pad_x, ly, self.text_font, self.text_scale, kc[1], kc[2], kc[3], kc[4], false)
            drip.draw_text(val, x + self.pad_x + (w * 0.45), ly, self.text_font, self.text_scale, vc[1], vc[2], vc[3], vc[4], false)
        else
            drip.draw_text(line, x + self.pad_x, ly, self.text_font, self.text_scale, drip.colour(c, "value"))
        end
    end
end

--- @section Threads

CreateThread(function()
    while true do
        Wait(0)
        for _, panel in pairs(_panels) do
            panel:draw()
        end
    end
end)

--- @section API

function drip.show_panel(data)
    if not data.id then return end
    _panels[data.id] = Panel.new(data)
end

function drip.hide_panel(id)
    _panels[id] = nil
end

function drip.update_panel(data)
    if not data.id or not _panels[data.id] then return end
    _panels[data.id] = Panel.new(data)
end

function drip.is_panel_visible(id)
    return _panels[id] ~= nil
end