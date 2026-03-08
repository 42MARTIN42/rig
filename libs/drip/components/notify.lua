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

--- @file client.notify
--- @description Handles notifcation component; types: "success", "error", "info", "warning"

--- @section State

local _queue = {}

--- @class Notify

local Notify = {}
Notify.__index = Notify

function Notify.new(data)
    local style = data.style or {}
    local colours = {}
    for k, v in pairs(drip.style.colours) do colours[k] = v end
    if style.colours then
        for k, v in pairs(style.colours) do colours[k] = v end
    end
    
    local wrap = drip.resolve_style(style, "wrap")
    local lines = drip.wrap_text(data.message or "", wrap)
    
    return setmetatable({
        header = data.header or "Notice",
        type = data.type or "info",
        lines = lines,
        duration = data.duration or 3000,
        expires = GetGameTimer() + (data.duration or 3000),
        x = style.x or drip.style.x, 
        y = style.y or drip.style.y,
        width = style.width or drip.style.width,
        header_font = drip.resolve_style(style, "header_font"),
        header_scale = drip.resolve_style(style, "header_scale"),
        header_height = drip.resolve_style(style, "header_height"),
        text_font = drip.resolve_style(style, "text_font"),
        text_scale = drip.resolve_style(style, "text_scale"),
        line_h = drip.resolve_style(style, "line_h"),
        pad_x = drip.resolve_style(style, "pad_x"),
        pad_y = drip.resolve_style(style, "pad_y"),
        colours = colours,
    }, Notify)
end

function Notify:is_expired()
    return GetGameTimer() > self.expires
end

function Notify:get_height()
    return self.header_height + (#self.lines * self.line_h) + (self.pad_y * 2)
end

function Notify:draw(draw_y)
    local cx = self.x + self.width / 2
    local header_h = self.header_height
    local body_h = (#self.lines * self.line_h) + (self.pad_y * 2)
    local box_h = header_h + body_h
    local c = self.colours
    DrawRect(cx, draw_y + box_h / 2, self.width, box_h, drip.colour(c, "bg"))
    DrawRect(cx, draw_y + box_h / 2, self.width - 0.001, box_h - 0.001, drip.colour(c, "bg_inner"))
    local hcy = draw_y + header_h / 2
    DrawRect(cx, hcy, self.width, header_h, drip.colour(c, "header"))
    DrawRect(cx, hcy - (header_h / 2) + 0.001, self.width, 0.002, drip.colour(c, self.type))
    local tr, tg, tb, ta = drip.colour(c, self.type)
    drip.draw_text(self.header, cx, hcy - 0.013, self.header_font, self.header_scale, tr, tg, tb, ta, true)
    for i, line in ipairs(self.lines) do
        local ly = draw_y + header_h + self.pad_y + ((i - 1) * self.line_h)
        drip.draw_text(line, self.x + self.pad_x, ly, self.text_font, self.text_scale, drip.colour(c, "text"))
    end
end

--- @section API

function drip.notify(data)
    _queue[#_queue + 1] = Notify.new(data)
end

RegisterNetEvent("drip:cl:notify", function(data)
    if not data then return end
    drip.notify(data)
end)

--- @section Threads

CreateThread(function()
    while true do
        Wait(0)
        if #_queue == 0 then 
            Wait(500) 
        else
            local stacks = {}
            local i = 1
            while i <= #_queue do
                local n = _queue[i]
                if n:is_expired() then
                    table.remove(_queue, i)
                else
                    local stack_key = tostring(n.x) .. tostring(n.y)
                    stacks[stack_key] = stacks[stack_key] or n.y
                    n:draw(stacks[stack_key])
                    stacks[stack_key] = stacks[stack_key] + n:get_height() + (drip.style.gap or 0.006)
                    i = i + 1
                end
            end
        end
    end
end)