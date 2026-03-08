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

--- @module interactions
--- @description Generic DUI interaction zone management.

if rawget(_G, "__interactions_module") then
    return _G.__interactions_module
end

local interactions = {}
_G.__interactions_module = interactions

--- @section API

--- Adds a DUI interaction zone
--- @param options table: { id, coords, header, image, icon, keys, additional }
function interactions.add(options)
    if not options or not options.id or not options.coords then
        print("[interactions] Missing id or coords")
        return
    end
    pluck.add_dui_zone({
        id = options.id,
        coords = vector3(options.coords.x, options.coords.y, options.coords.z),
        header = options.header or "",
        image = options.image or nil,
        icon = options.icon or nil,
        keys = options.keys or {},
        additional = options.additional or {}
    })
end

--- Removes a DUI interaction zone
--- @param id string: Zone ID to remove
function interactions.remove(id)
    if not id then return end
    pluck.remove_dui_zone(id)
end

return interactions