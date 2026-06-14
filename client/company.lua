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
    local result = lib.callback.await('realrpg_cargo:company:get', false)
    if result then
        cb(json.encode(result))
    else
        cb(json.encode(json.null))
    end
end)

--- Create company
RegisterNUICallback('company_create', function(data, cb)
    local result = lib.callback.await('realrpg_cargo:company:create', false, data)
    cb(json.encode(result or { success = false, message = 'Szerver hiba' }))
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
