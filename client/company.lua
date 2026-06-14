print('[RealRPG Cargo] company.lua loaded')
--[[
    RealRPG Cargo - Company System (Client-side)
    NUI Callbacks that bridge Vue frontend → Server lib.callbacks
]]

if not Config.company or not Config.company.enabled then return end

-- ============================================================
-- OPEN COMPANY PANEL
-- ============================================================

RegisterNetEvent('realrpg_cargo:openCompany', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ subject = 'COMPANY', data = {} })
end)

RegisterCommand('company', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ subject = 'COMPANY', data = {} })
end, false)

RegisterCommand('ceginfo', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ subject = 'COMPANY', data = {} })
end, false)

-- ============================================================
-- NUI CALLBACKS → SERVER CALLBACKS
-- ============================================================

--- Get company data (dashboard)
RegisterNUICallback('company_getData', function(data, cb)
    cb(json.encode({ loading = true }))
    TriggerServerEvent('realrpg_cargo:company:requestData')
end)

-- Response from server with company data
RegisterNetEvent('realrpg_cargo:company:dataResult', function(result)
    SendNUIMessage({
        subject = 'COMPANY_DATA',
        data = result
    })
end)

--- Create company
RegisterNUICallback('company_create', function(data, cb)
    -- Use server event instead of lib.callback to avoid freeze on error
    TriggerServerEvent('realrpg_cargo:company:tryCreate', data)
    cb(json.encode({ success = true, message = 'Feldolgozás...' }))
end)

-- Response from server
RegisterNetEvent('realrpg_cargo:company:createResult', function(result)
    if result and result.success then
        DoCustomHudText('success', result.message or 'Cég létrehozva!', 5000)
        -- Reopen company panel to show dashboard
        SetNuiFocus(true, true)
        SendNUIMessage({ subject = 'COMPANY', data = {} })
    else
        DoCustomHudText('fail', result and result.message or 'Hiba történt a cégalapításnál!', 8000)
    end
end)

--- Disband company
RegisterNUICallback('company_disband', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:disband', false)
    cb(json.encode(result or { success = false, message = 'Szerver hiba' }))
end)

--- Invite player
RegisterNUICallback('company_invite', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:invite', false, data)
    cb(json.encode(result or { success = false, message = 'Szerver hiba' }))
end)

--- Accept invite
RegisterNUICallback('company_acceptInvite', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:acceptInvite', false, data)
    cb(json.encode(result or { success = false, message = 'Szerver hiba' }))
end)

--- Fire employee
RegisterNUICallback('company_fire', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:fire', false, data)
    cb(json.encode(result or { success = false, message = 'Szerver hiba' }))
end)

--- Leave company
RegisterNUICallback('company_leave', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:leave', false)
    cb(json.encode(result or { success = false, message = 'Szerver hiba' }))
end)

--- Update employee (role/salary)
RegisterNUICallback('company_updateEmployee', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:updateEmployee', false, data)
    cb(json.encode(result or { success = false, message = 'Szerver hiba' }))
end)

--- Buy vehicle
RegisterNUICallback('company_buyVehicle', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:buyVehicle', false, data)
    cb(json.encode(result or { success = false, message = 'Szerver hiba' }))
end)

--- Sell vehicle
RegisterNUICallback('company_sellVehicle', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:sellVehicle', false, data)
    cb(json.encode(result or { success = false, message = 'Szerver hiba' }))
end)

--- Get contracts
RegisterNUICallback('company_getContracts', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:getContracts', false)
    cb(json.encode(result or {}))
end)

--- Accept contract
RegisterNUICallback('company_acceptContract', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:acceptContract', false, data)
    cb(json.encode(result or { success = false, message = 'Szerver hiba' }))
end)

--- Deposit money
RegisterNUICallback('company_deposit', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:deposit', false, data)
    cb(json.encode(result or { success = false, message = 'Szerver hiba' }))
end)

--- Withdraw money
RegisterNUICallback('company_withdraw', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:withdraw', false, data)
    cb(json.encode(result or { success = false, message = 'Szerver hiba' }))
end)

--- Get pending invites (for players without company)
RegisterNUICallback('company_getInvites', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:getInvites', false)
    cb(json.encode(result or {}))
end)

-- ============================================================
-- INVITE NOTIFICATION (from server)
-- ============================================================

RegisterNetEvent('realrpg_cargo:companyInvite', function(data)
    DoCustomHudText('information', 'Meghívást kaptál egy fuvarozó vállalkozásba! Használd a /company parancsot.', 10000)
end)
