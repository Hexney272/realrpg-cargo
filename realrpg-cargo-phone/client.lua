--[[
    RealRPG Cargo - Quasar Smartphone V3 App (Client)
    ONLY registers the custom app - NUI callbacks are in the main cargo resource
]]

local appRegistered = false
local resourceName = GetCurrentResourceName()
local baseUrl = 'https://cfx-nui-' .. resourceName .. '/ui/build/'

Citizen.CreateThread(function()
    while GetResourceState('qs-smartphone') ~= 'started' do
        Citizen.Wait(1000)
    end

    Citizen.Wait(3000)

    local ok, err = exports['qs-smartphone']:addCustomApp({
        id = 'realrpg_cargo',
        label = 'RealRPG Cargo',
        icon = baseUrl .. 'icon.svg',
        category = 'Business',
        creator = 'RealRPG',
        description = 'Fuvarozó vállalkozás kezelése, szerződések, statisztikák.',
        appStoreOnly = false,
        price = 0,
        sizeMb = 2,
        iframe = { url = baseUrl .. 'index.html' },
        custom = {
            enabled = true,
            bridge = {
                enabled = true,
                allowedOrigins = { 'https://cfx-nui-' .. resourceName },
            },
        },
    })

    if ok then
        appRegistered = true
        print('[RealRPG Cargo Phone] App registered')
    else
        print('[RealRPG Cargo Phone] Failed: ' .. tostring(err))
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == resourceName and appRegistered then
        exports['qs-smartphone']:removeCustomApp('realrpg_cargo')
    end
end)
