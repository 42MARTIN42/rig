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

--- @file src.server.api
--- @description Handles all server side API registration.
--- Required due to cross resource usage, class functions do not like exports to keep it simple.
--- You have two options: 
--- `local rig = exports.rig:api()` then call functions `rig.save_player(source)`
--- or `exports.rig:save_player(source)` to use exports directly 

--- @section API

function core.get_user(source)
    local p = core.players:get(source)
    if not p then return nil end
    return getmetatable(p) and p.user_data or p
end
exports("get_user", core.get_user)

function core.update_user_data(source, updates)
    local p = core.players:get(source)
    if not p then return false end
    local user = getmetatable(p) and p.user_data or p
    for key, value in pairs(updates) do
        if user[key] ~= nil then user[key] = value end
    end
    local update_keys = {}
    local update_values = {}
    for key, value in pairs(updates) do
        table.insert(update_keys, string.format("`%s` = ?", key))
        table.insert(update_values, type(value) == "table" and json.encode(value) or value)
    end
    if #update_keys == 0 then return false end
    table.insert(update_values, user.license)
    MySQL.prepare.await(string.format("UPDATE rig_players SET %s WHERE license = ?", table.concat(update_keys, ", ")), update_values)
    return true
end
exports("update_user_data", core.update_user_data)

function core.create_player(source)
    local player = core.players:create(source)
    if player then TriggerEvent("rig:sv:player_loaded", player) end
    return player
end
exports("create_player", core.create_player)

function core.get_players()
    return core.players:get_all()
end
exports("get_players", core.get_players)

function core.get_player(source)
    return core.players:get(source)
end
exports("get_player", core.get_player)

function core.save_player(source)
    local p = core.players:get(source)
    return p and p:save()
end
exports("save_player", core.save_player)

function core.is_player_loaded(source)
    local p = core.players:get(source)
    return p and p:has_loaded() or false
end
exports("is_player_loaded", core.is_player_loaded)

function core.is_player_playing(source)
    local p = core.players:get(source)
    return p and p:is_playing() or false
end
exports("is_player_playing", core.is_player_playing)

function core.set_player_playing(source, state)
    local p = core.players:get(source)
    if p then p:set_playing(state) end
end
exports("set_player_playing", core.set_player_playing)

function core.get_player_data(source, category)
    local p = core.players:get(source)
    return p and p:get_data(category) or nil
end
exports("get_player_data", core.get_player_data)

function core.set_player_data(source, category, updates, sync)
    local p = core.players:get(source)
    return p and p:set_data(category, updates, sync) or false
end
exports("set_player_data", core.set_player_data)

function core.add_player_data(source, category, value, replicate)
    local p = core.players:get(source)
    return p and p:add_data(category, value, replicate) or false
end
exports("add_player_data", core.add_player_data)

function core.has_player_data(source, category)
    local p = core.players:get(source)
    return p and p:has_data(category) or false
end
exports("has_player_data", core.has_player_data)

function core.replace_player_data(source, category, data, sync)
    local p = core.players:get(source)
    return p and p:replace_data(category, data, sync)
end
exports("replace_player_data", core.replace_player_data)

function core.remove_player_data(source, category)
    local p = core.players:get(source)
    if p then return p:remove_data(category) end
end
exports("remove_player_data", core.remove_player_data)

function core.sync_player_data(source, category)
    local p = core.players:get(source)
    if p then return p:sync(category) end
end
exports("sync_player_data", core.sync_player_data)

function core.run_player_method(source, name, ...)
    local p = core.players:get(source)
    return p and p:run_method(name, ...)
end
exports("run_player_method", core.run_player_method)

function core.add_player_method(source, name, fn)
    local p = core.players:get(source)
    return p and p:add_method(name, fn) or false
end
exports("add_player_method", core.add_player_method)

function core.remove_player_method(source, name, fn)
    local p = core.players:get(source)
    return p and p:remove_method(name, fn) or false
end
exports("remove_player_method", core.remove_player_method)

function core.has_player_method(source, name)
    local p = core.players:get(source)
    return p and p:has_method(name) or false
end
exports("has_player_method", core.has_player_method)

function core.get_player_method(source, name)
    local p = core.players:get(source)
    return p and p:get_method(name) or false
end
exports("get_player_method", core.get_player_method)

function core.add_player_extension(source, name, ext)
    local p = core.players:get(source)
    return p and p:add_extension(name, ext) or false
end
exports("add_player_extension", core.add_player_extension)

function core.remove_player_extension(source, name, ext)
    local p = core.players:get(source)
    return p and p:remove_extension(name, ext) or false
end
exports("remove_player_extension", core.remove_player_extension)

function core.get_player_extension(source, name)
    local p = core.players:get(source)
    return p and p:get_extension(name) or nil
end
exports("get_player_extension", core.get_player_extension)

function core.has_player_extension(source, name)
    local p = core.players:get(source)
    return p and p:has_extension(name) or false
end
exports("has_player_extension", core.has_player_extension)

function core.dump_player_data(source)
    local p = core.players:get(source)
    if p then p:dump_data() end
end
exports("dump_player_data", core.dump_player_data)

function core.list_player_extensions(source)
    local p = core.players:get(source)
    return p and p:list_extensions() or {}
end
exports("list_player_extensions", core.list_player_extensions)

--- @section Objects

function core.place_object(source, data)
    local user = core.get_user(source)
    if not user then return end
    core.objects:place(source, data, user)
end
exports("place_object", core.place_object)

function core.remove_object(source, id)
    local user = core.get_user(source)
    if not user then return end
    core.objects:remove(source, id, user)
end
exports("remove_object", core.remove_object)

function core.use_object(source, id, key)
    core.objects:use(source, id, key)
end
exports("use_object", core.use_object)