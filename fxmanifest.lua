--[[
 ███████████   █████   █████████ 
▒▒███▒▒▒▒▒███ ▒▒███   ███▒▒▒▒▒███
 ▒███    ▒███  ▒███  ███     ▒▒▒ 
 ▒██████████   ▒███ ▒███         
 ▒███▒▒▒▒▒███  ▒███ ▒███    █████
 ▒███    ▒███  ▒███ ▒▒███  ▒▒███ 
 █████   █████ █████ ▒▒█████████ 
▒▒▒▒▒   ▒▒▒▒▒ ▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒                                                                                                     
]]

fx_version "cerulean"
games { "gta5" }

--- Metadata
name "rig"
version "0.1.0"
description "A drop in ready survival framework."
author "Case"
lua54 "yes"

--- Loading Screen
--- If you dont want to use the default load screen remove or replace here
loadscreen "ui/loadscreen/loadscreen.html"
loadscreen_manual_shutdown "yes"

--- UI
ui_page "libs/pluck/ui/index.html"
nui_callback_strict_mode "true"
files { 
    "configs/appearance.lua",
    "configs/tattoos.lua",

    "libs/pluck/ui/**/*",
    "ui/loadscreen/**/*"
}

--- Scripts
shared_scripts {
    "locales/*.lua",
    "init.lua",

    "libs/graft/**/*.lua",
    "libs/pluck/**/*.lua",
}
client_scripts {
    "libs/drip/init.lua",
    "libs/drip/components/*.lua",
    "src/client/**/*.lua",
}
server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "configs/*.lua",

    "src/server/init.lua",
    "src/server/events.lua",
    "src/server/api.lua",
    "src/server/commands.lua",
    "src/server/callbacks.lua",
    "src/server/gameplay.lua"
}

--- Deps & Provides
dependency "oxmysql"
provide "rig"