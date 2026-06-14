--[[
    RealRPG Cargo - Quasar Smartphone V3 App (Client)
    Registers the app AND handles NUI callbacks from the phone iframe
]]

local appRegistered = false
local resourceName = GetCurrentResourceName()
local baseUrl = 'https://cfx-nui-' .. resourceName .. '/ui/build/'

-- ============================================================
-- APP REGISTRATION
-- ============================================================

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

-- ============================================================
-- NUI CALLBACKS (called from phone iframe via XHR)
-- ============================================================

RegisterNUICallback('phone:getCompany', function(data, cb)
    TriggerServerEvent('realrpg_cargo_phone:getCompany')
    cb(json.encode({ ok = true }))
end)

RegisterNUICallback('phone:getStats', function(data, cb)
    TriggerServerEvent('realrpg_cargo_phone:getStats')
    cb(json.encode({ ok = true }))
end)

RegisterNUICallback('phone:getContracts', function(data, cb)
    TriggerServerEvent('realrpg_cargo:contracts:getAvailable')
    cb(json.encode({ ok = true }))
end)

RegisterNUICallback('phone:acceptContract', function(data, cb)
    TriggerServerEvent('realrpg_cargo:contracts:accept', data.contractId)
    cb(json.encode({ ok = true }))
end)

RegisterNUICallback('phone:deposit', function(data, cb)
    TriggerServerEvent('realrpg_cargo_phone:deposit', tonumber(data.amount) or 0)
    cb(json.encode({ ok = true }))
end)

RegisterNUICallback('phone:withdraw', function(data, cb)
    TriggerServerEvent('realrpg_cargo_phone:withdraw', tonumber(data.amount) or 0)
    cb(json.encode({ ok = true }))
end)

-- ============================================================
-- SERVER RESPONSES → Forward to phone iframe NUI
-- ============================================================

RegisterNetEvent('realrpg_cargo_phone:statsResult', function(data)
    SendNUIMessage({ type = 'STATS_DATA', data = data })
end)

RegisterNetEvent('realrpg_cargo_phone:companyResult', function(data)
    SendNUIMessage({ type = 'COMPANY_DATA', data = data })
end)

RegisterNetEvent('realrpg_cargo:contracts:availableResult', function(contracts)
    SendNUIMessage({ type = 'CONTRACTS_DATA', data = contracts })
end)

RegisterNetEvent('realrpg_cargo_phone:actionResult', function(data)
    SendNUIMessage({ type = 'ACTION_RESULT', data = data })
end)

-- ============================================================
-- CLEANUP
-- ============================================================

AddEventHandler('onResourceStop', function(resource)
    if resource == resourceName and appRegistered then
        exports['qs-smartphone']:removeCustomApp('realrpg_cargo')
    end
end)
