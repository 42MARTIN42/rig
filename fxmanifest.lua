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
version "0.2.0"
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
    "ui/loadscreen/**/*",
    "ui/inventory/*"
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

    "src/server/**/**/*.lua"
}

--- Deps & Provides
dependency "oxmysql"
provide "rig"