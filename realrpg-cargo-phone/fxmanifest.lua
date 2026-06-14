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

-- Invisible NUI page (required for RegisterNUICallback to work)
-- The actual visible UI runs inside Quasar Smartphone's iframe via cfx-nui URL
ui_page 'ui/nui.html'

files {
    'ui/nui.html',
    'ui/build/**/*',
}

dependencies {
    'qs-smartphone',
    'realrpg-cargo',
}
