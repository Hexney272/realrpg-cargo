fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'RealRPG'
description 'RealRPG Cargo - Quasar Smartphone V3 App'
version '1.0.0'

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

ui_page 'ui/build/index.html'

files {
    'ui/build/**/*',
}

dependencies {
    'qs-smartphone',
    'realrpg-cargo',
}
