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
    inventory_open_key = GetConvar("rig:inventory_open_key", "I"),
    inventory_center = GetConvar("rig:inventory_center", "loadout"),
    inventory_table = GetConvar("rig:inventory_table", "rig_inventories"),
    image_path = GetConvar("rig:image_path", "nui://rig/ui/inventory/"),
}
core.vars = not core.is_server and {
    current_vehicle_data = nil,
    current_vehicle = nil,
    current_inv_type = nil,
    current_container = nil,
    client_drops = {}
} or {}

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

--- locales a string to a locale key
--- @param key string: Locale key string
--- @param ... any: Arguments for string.format
--- @return string: Localized string
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

--- @section Server

if core.is_server then

    --- @section Players

    local Players = require("src.server.registry.players")

    core.players = Players.new()

    core.player_extensions = {
        { name = "appearance", class = require("src.server.players.classes.extensions.appearance"), priority = 100 },
        { name = "spawns", class = require("src.server.players.classes.extensions.spawns"), priority = 99 },
        { name = "statuses", class = require("src.server.players.classes.extensions.statuses"), priority = 98 },
        { name = "injuries", class = require("src.server.players.classes.extensions.injuries"), priority = 97 },
        { name = "effects", class = require("src.server.players.classes.extensions.effects"), priority = 96 },
        { name = "inventory", class = require("src.server.players.classes.extensions.inventory"), priority = 95 },
    }

    function core.register_player_extension(name, fn, priority)
        core.players:register_extension(name, fn, priority)
    end

    exports("register_player_extension", core.register_player_extension)

    for _, ext in ipairs(core.player_extensions) do
        core.register_player_extension(ext.name, function(player)
            local instance = setmetatable({ player = player }, { __index = ext.class })
            player:add_extension(ext.name, instance)
        end, ext.priority)
    end

    --- @section Objects

    local Objects = require("src.server.registry.objects")

    core.objects = Objects.new()

    --- @section Weather + Buckets

    local cfg_buckets = require("configs.buckets")
    local cfg_weather = require("configs.weather")

    core.bucket_environments = {}

    SetTimeout(150, function()
        for _, bucket_config in pairs(cfg_buckets) do
            local bucket_id = bucket_config.bucket
            if bucket_config.mode then
                SetRoutingBucketEntityLockdownMode(bucket_id, bucket_config.mode)
            end
            if bucket_config.population_enabled ~= nil then
                SetRoutingBucketPopulationEnabled(bucket_id, bucket_config.population_enabled)
            end

            local init_season = bucket_config.season
            local init_weather = bucket_config.dynamic_weather and cfg_weather.seasons[init_season][math.random(1, #cfg_weather.seasons[init_season])] or bucket_config.weather
            local weather_type = cfg_weather.types[init_weather]
            local effects = weather_type and weather_type.effects

            local function resolve_effect(val)
                if type(val) == "table" then return math.random(val.min or val[1], val.max or val[2]) / 100 end
                return val or 0.0
            end

            core.bucket_environments[bucket_id] = {
                season = init_season,
                weather = init_weather,
                hour = bucket_config.dynamic_time and math.random(0, 23) or bucket_config.hour,
                minute = bucket_config.dynamic_time and math.random(0, 59) or bucket_config.minute,
                day = bucket_config.dynamic_time and math.random(1, 30) or bucket_config.day,
                month = bucket_config.month,
                year = bucket_config.year,
                rain_level = effects and resolve_effect(effects.rain) or 0.0,
                snow_level = effects and resolve_effect(effects.snow) or 0.0,
                wind_speed = effects and resolve_effect(effects.wind) or 0.5,
                wind_direction = math.random(0, 360),
                dynamic_weather = bucket_config.dynamic_weather,
                dynamic_time = bucket_config.dynamic_time,
                freeze_weather = bucket_config.freeze_weather
            }

            core.update_weather_effects(core.bucket_environments[bucket_id], init_weather)
            core.load_bucket_weather(bucket_id, bucket_config)
        end
    end)

    --- @section Inventory

    local Containers = require("src.server.registry.containers")
    local Drops = require("src.server.registry.drops")

    core.containers = Containers.new()
    core.drops = Drops.new()

    local inventory_data_modules = {
        items = "configs.items",
        inventories = "configs.inventories",
        metadata = "configs.metadata",
    }

    function core.sanitize_table(tbl)
        if type(tbl) ~= "table" then return tbl end
        local copy = {}
        for k, v in pairs(tbl) do
            if k ~= "can_access" and type(v) ~= "function" then
                copy[k] = type(v) == "table" and core.sanitize_table(v) or v
            end
        end
        return copy
    end

    local function get_sanitized_inventory_data()
        local out = {}
        for key, module_path in pairs(inventory_data_modules) do
            local ok, raw = pcall(require, module_path)
            if ok and type(raw) == "table" then
                out[key] = core.sanitize_table(raw)
            else
                log("error", locale("init.data_load", module_path))
            end
        end
        return out
    end

    function core.sync_static_data_to_client(source)
        TriggerClientEvent("rig:cl:sync_static_data", source, get_sanitized_inventory_data())
    end

    --- @section Database

    CreateThread(function()
        Wait(500)
        local table_name = core.convars.inventory_table
        MySQL.Async.execute(([[
            CREATE TABLE IF NOT EXISTS `%s` (
                `id` BIGINT NOT NULL AUTO_INCREMENT,
                `identifier` VARCHAR(255) NOT NULL,
                `owner` VARCHAR(255) NOT NULL,
                `type` ENUM('player', 'vehicle', 'container', 'drop') NOT NULL DEFAULT 'player',
                `subtype` VARCHAR(50) DEFAULT NULL,
                `items` JSON NOT NULL DEFAULT (JSON_OBJECT()),
                `metadata` JSON DEFAULT (JSON_OBJECT()),
                `last_update` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                UNIQUE KEY `identifier_unique` (`identifier`),
                KEY `owner_idx` (`owner`),
                KEY `type_subtype_idx` (`type`, `subtype`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]]):format(table_name), {}, function(result)
            if result then
                log("success", locale("init.db_table_ready", table_name))
            else
                log("error", locale("init.db_table_failed", table_name))
            end
        end)
    end)

    --- @section Item Registration

    local usable_items = {}

    --- Registers all usable items from static item definitions
    --- @return number: Total number of items successfully registered
    local function register_usable_items()
        local item_defs = require("configs.items")
        local count = 0
        
        for id, def in pairs(item_defs) do
            if def.actions and def.actions.use then
                usable_items[id] = def.actions.use
                log("success", locale("registry.item_registered", id))
                count = count + 1
            end
        end
        
        log("success", locale("registry.usable_registered", count))
        return count
    end

    SetTimeout(500, function()
        register_usable_items()
    end)

    --- Registers an item as usable
    --- @param id string: The unique identifier for the item
    --- @param use_data function|table: Function or action table executed when item is used
    --- @return boolean: Whether the item was registered successfully
    function core.register_usable_item(id, use_data)
        if not id or type(id) ~= "string" then
            log("error", locale("registry.bad_item_id", tostring(id)))
            return false
        end
        
        if type(use_data) ~= "function" and type(use_data) ~= "table" then
            log("error", locale("registry.bad_item_use", id))
            return false
        end
        
        if usable_items[id] then
            log("warn", locale("registry.item_exists", id))
            return false
        end
        
        usable_items[id] = use_data
        log("success", locale("registry.item_registered", id))
        return true
    end

    --- Gets a usable item handler
    --- @param item_id string: Item identifier
    --- @return function|table|nil: Item use handler or nil if not registered
    function core.get_usable_item(item_id)
        return usable_items[item_id]
    end

    --- Checks whether an item is usable
    --- @param item_id string: Item identifier
    --- @return boolean: True if the item is registered as usable
    function core.is_usable(item_id)
        return usable_items[item_id] ~= nil
    end

end

--- @section Client

if not core.is_server then

    --- Stores sanitized static data sent from server on player load
    --- Never require configs directly on client - data comes through this only
    core.static_data = {}

    --- Receives and stores sanitized static data from server
    RegisterNetEvent("rig:cl:sync_static_data", function(data)
        if type(data) ~= "table" then
            log("error", locale("init.data_sync_fail"))
            return
        end
        core.static_data = data
        log("success", locale("init.data_sync_ok"))
    end)

    --- Gets a specific static data set by key
    --- @param key string: Data key e.g. "items", "inventories", "metadata"
    --- @return table|nil
    function core.get_static_data(key)
        return core.static_data[key]
    end

    --- Register pluck grid slot move handler
    SetTimeout(150, function()
        pluck.set_grid_move_handler(function(data)
            TriggerServerEvent("rig:sv:move_item", data)
        end)
    end)

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
            if type(v) == "boolean" then return v and "^2true" or "^1false" end
            return "^2" .. tostring(v)
        end
        if type(value) == "table" then
            print("^7    " .. key .. ":")
            for k, v in pairs(value) do print("^7      " .. k .. ": " .. format_value(v)) end
        else
            print("^7    " .. key .. ": " .. format_value(value))
        end
    end

    for key, value in pairs(core.convars) do
        if key ~= "console_splash" then log_setting(key, value) end
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