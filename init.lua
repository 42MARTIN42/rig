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

--- @script init
--- @description Main initialization file

--- @section Bootstrap

core = setmetatable({}, { __index = _G })

core.resource = GetCurrentResourceName()
core.is_server = IsDuplicityVersion()
core.cache = {}
core.locales = {}
core.metadata = {
    name = GetResourceMetadata(core.resource, "name", 0) or "unknown",
    description = GetResourceMetadata(core.resource, "description", 0) or "unknown",
    version = GetResourceMetadata(core.resource, "version", 0) or "unknown",
    author = GetResourceMetadata(core.resource, "author", 0) or "Unknown"
}
core.convars = {
    debug = GetConvar("rig:debug_mode", "true") == "true",
    language = GetConvar("rig:language", "en"),
    console_splash = GetConvar("rig:console_splash", "true") == "true",
    uid_length = tonumber(GetConvar("rig:uid_length", "6")) or 6,
    username_prefix = GetConvar("rig:username_prefix", "survivor"),
    player_save_interval = GetConvar("rig:player_save_interval", "5") or 5,
    server_name = GetConvar("rig:server_name", "RIG"),
    server_tagline = GetConvar("rig:server_tagline", "Survival Framework (pre-alpha v0.0.1)"),
    server_logo = GetConvar("rig:server_logo", "/libs/pluck/ui/assets/logos/logo.png"),
}

--- @section Utility Functions

--- Gets the current time for debug logs
local function get_current_time()
    if core.is_server then return os.date("%Y-%m-%d %H:%M:%S") end
    if GetLocalTime then
        local y, m, d, h, min, s = GetLocalTime()
        return string.format("%04d-%02d-%02d %02d:%02d:%02d", y, m, d, h, min, s)
    end
    return "0000-00-00 00:00:00"
end

--- Logs a stylized print message
--- @param level string: Debug level (debug, info, success, warn, error, critical, dev)
--- @param message string: Message to print
local function log(level, message)
    if not core.convars.debug then return end
    local colours = { reset = "^7", debug = "^6", info = "^5", success = "^2", warn = "^3", error = "^8", critical = "^1", dev = "^9" }
    local clr = colours[level] or "^7"
    local time = get_current_time()
    print(("%s[%s] [%s] [%s]:^7 %s"):format(clr, time, core.metadata.name, level:upper(), message))
end

core.log = log
_G.log = log

--- Translates a string to a locale key
--- @param key string: Locale key string
--- @param ... any: Arguments for string.format
--- @return string: localed string
local function locale(key, ...)
    local str = core.locales[key]
    if not str and type(key) == "string" then
        local v = core.locales
        for p in key:gmatch("[^%.]+") do v = v and v[p] end
        str = v
    end
    if type(str) == "string" then
        local ok, res = pcall(string.format, str, ...)
        return ok and res or str
    end
    return select("#", ...) > 0 and (tostring(key) .. " | " .. table.concat({...}, ", ")) or tostring(key)
end

core.locale = locale
_G.locale = locale

--- Safe require function for loading internal modules
--- @param key string: Path key e.g. `src.server.modules.database`
local function safe_require(key)
    if not key or type(key) ~= "string" then return nil end
    local rel_path = key:gsub("%.", "/")
    if not rel_path:match("%.lua$") then rel_path = rel_path .. ".lua" end
    local cache_key = ("%s:%s"):format(core.resource, rel_path)
    if core.cache[cache_key] then return core.cache[cache_key] end
    local file = LoadResourceFile(core.resource, rel_path)
    if not file then log("warn", locale("init.mod_missing", rel_path)) return nil end
    local module_env = setmetatable({}, { __index = _G })
    local chunk, err = load(file, ("@@%s/%s"):format(core.resource, rel_path), "t", module_env)
    if not chunk then log("error", locale("init.mod_compile", rel_path, err)) return nil end
    local ok, result = pcall(chunk)
    if not ok then log("error", locale("init.mod_runtime", rel_path, result)) return nil end
    if type(result) ~= "table" then log("error", locale("init.mod_return", rel_path, type(result))) return nil end
    core.cache[cache_key] = result
    return result
end

_G.require = safe_require
exports("require", safe_require)

--- Loads a json file
local function require_json(path)
    local raw = LoadResourceFile(GetCurrentResourceName(), path)
    return json.decode(raw or "{}")
end

--- @section Locales

local loaded_locale = require("locales." .. core.convars.language)
if loaded_locale then
    core.locales = loaded_locale
end

--- @section Startup Message

if core.is_server and core.convars.console_splash then

    print("^2 ███████████   █████   █████████ ")
    print("^2▒▒███▒▒▒▒▒███ ▒▒███   ███▒▒▒▒▒███")
    print("^2 ▒███    ▒███  ▒███  ███     ▒▒▒ ")
    print("^2 ▒██████████   ▒███ ▒███         ")
    print("^2 ▒███▒▒▒▒▒███  ▒███ ▒███    █████")
    print("^2 ▒███    ▒███  ▒███ ▒▒███  ▒▒███ ")
    print("^2 █████   █████ █████ ▒▒█████████ ")
    print("^2▒▒▒▒▒   ▒▒▒▒▒ ▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒ ")
    print("^2")
    print("^2 ------------------------------------------------------------")
    print("^7  Name:        ^2" .. core.metadata.name)
    print("^7  Description: ^2" .. core.metadata.description)
    print("^7  Author:      ^2" .. core.metadata.author)
    print("^7  Version:     ^2" .. core.metadata.version)
    print("^2 ------------------------------------------------------------")
    print("^7  Settings:")

    local function log_setting(key, value)
        local function format_value(v)
            if type(v) == "boolean" then
                return v and "^2true" or "^1false"
            end
            return "^2" .. tostring(v)
        end

        if type(value) == "table" then
            print("^7    " .. key .. ":")
            for k, v in pairs(value) do
                print("^7      " .. k .. ": " .. format_value(v))
            end
        else
            print("^7    " .. key .. ": " .. format_value(value))
        end
    end

    for key, value in pairs(core.convars) do
        if key ~= "console_splash" then
            log_setting(key, value)
        end
    end

    print("^2 ------------------------------------------------------------")

end

--- @section Namespace Protection

SetTimeout(250, function()
    setmetatable(core, {
        __newindex = function(_, key)
            error(locale("init.ns_blocked", key), 2)
        end
    })
    
    log("success", locale("init.ns_ready", core.metadata.name))
end)