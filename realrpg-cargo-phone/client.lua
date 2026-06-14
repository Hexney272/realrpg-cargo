--[[
    RealRPG Cargo - Quasar Smartphone V3 App (Client)
    Registers the custom app and handles bridge communication
]]

local appRegistered = false
local resourceName = GetCurrentResourceName()
local baseUrl = 'https://cfx-nui-' .. resourceName .. '/ui/build/'

-- Wait for qs-smartphone to be ready
Citizen.CreateThread(function()
    while GetResourceState('qs-smartphone') ~= 'started' do
        Citizen.Wait(1000)
    end

    Citizen.Wait(2000) -- Extra wait for phone to initialize

    local ok, err = exports['qs-smartphone']:addCustomApp({
        id = 'realrpg_cargo',
        label = 'RealRPG Cargo',
        icon = baseUrl .. 'icon.svg',
        category = 'Business',
        creator = 'RealRPG',
        description = 'Fuvarozó vállalkozás kezelése, szerződések, statisztikák.',
        appStoreOnly = false, -- Pre-installed
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
        print('[RealRPG Cargo Phone] App registered successfully')
    else
        print('[RealRPG Cargo Phone] App registration failed: ' .. tostring(err))
    end
end)

-- ============================================================
-- NUI CALLBACKS (bridge communication from phone iframe)
-- ============================================================

-- Get player cargo stats
RegisterNUICallback('phone:getStats', function(data, cb)
    TriggerServerEvent('realrpg_cargo_phone:getStats')
    cb(json.encode({ ok = true }))
end)

-- Get company data
RegisterNUICallback('phone:getCompany', function(data, cb)
    TriggerServerEvent('realrpg_cargo_phone:getCompany')
    cb(json.encode({ ok = true }))
end)

-- Get available contracts
RegisterNUICallback('phone:getContracts', function(data, cb)
    TriggerServerEvent('realrpg_cargo_phone:getContracts')
    cb(json.encode({ ok = true }))
end)

-- Accept contract from phone
RegisterNUICallback('phone:acceptContract', function(data, cb)
    TriggerServerEvent('realrpg_cargo:contracts:accept', data.contractId)
    cb(json.encode({ ok = true }))
end)

-- Deposit to company
RegisterNUICallback('phone:deposit', function(data, cb)
    TriggerServerEvent('realrpg_cargo_phone:deposit', data.amount)
    cb(json.encode({ ok = true }))
end)

-- Withdraw from company
RegisterNUICallback('phone:withdraw', function(data, cb)
    TriggerServerEvent('realrpg_cargo_phone:withdraw', data.amount)
    cb(json.encode({ ok = true }))
end)

-- ============================================================
-- SERVER RESPONSES → Forward to NUI (phone iframe)
-- ============================================================

RegisterNetEvent('realrpg_cargo_phone:statsResult', function(data)
    SendNUIMessage({ type = 'STATS_DATA', data = data })
end)

RegisterNetEvent('realrpg_cargo_phone:companyResult', function(data)
    SendNUIMessage({ type = 'COMPANY_DATA', data = data })
end)

RegisterNetEvent('realrpg_cargo_phone:contractsResult', function(data)
    SendNUIMessage({ type = 'CONTRACTS_DATA', data = data })
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
