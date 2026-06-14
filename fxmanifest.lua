fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Tutya & Ekhion'
description 'RealRPG - Cargo Delivery System'
version '2.2.0'

-- Shared resources (loaded on both client and server)
shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    '@es_extended/locale.lua',
    'locales/*.lua',
    'config.lua',
    'libs/helper.lua',
}

-- Client-side scripts
client_scripts {
    'libs/calculator.lua',
    'libs/cargo.lua',
    'libs/coords.lua',
    'libs/distance.lua',
    'libs/hud.lua',
    'libs/maintenance.lua',
    'libs/mission.lua',
    'libs/monitor.lua',
    'libs/statistics.lua',
    'client/main.lua',
    'client/monitoring.lua',
    'client/cruise_control.lua',
}

-- Server-side scripts
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'libs/calculator.lua',
    'server/discord.lua',
    'server/achievements.lua',
    'server/main.lua',
}

-- NUI (Vue 3 + Vite built output)
ui_page 'html/dist/index.html'

files {
    'locales/en.json',
    'locales/hu.json',
    'html/dist/index.html',
    'html/dist/js/*.js',
    'html/dist/css/*.css',
    'html/dist/img/*.*',
}

-- Required dependencies
dependencies {
    'ox_lib',
    'es_extended',
    'oxmysql',
}
