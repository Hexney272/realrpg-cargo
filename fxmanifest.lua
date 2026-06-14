fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Tutya & Ekhion'
description 'RealRPG - Cargo Delivery System'
version '2.0.0'

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
    'server/main.lua',
}

-- NUI (HTML interface)
ui_page 'html/ui.html'

files {
    'locales/en.json',
    'locales/hu.json',
    'html/ui.html',
    'html/styles.css',
    'html/js/*.js',
    'html/img/*.*',
}

-- Required dependencies
dependencies {
    'ox_lib',
    'es_extended',
    'oxmysql',
}
