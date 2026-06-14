--[[
    RealRPG Cargo - Quasar Smartphone V3 App (Server)
    Data queries for the phone app + push notifications
]]

-- ============================================================
-- DATA REQUESTS FROM PHONE
-- ============================================================

RegisterNetEvent('realrpg_cargo_phone:getStats', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    local ok, stats = pcall(MySQL.query.await, [[
        SELECT *,
        `started_mission` + `started_delivery` as `all_started`,
        `done_mission` + `done_delivery` as `all_done`
        FROM `realrpg_cargo_stats`
        WHERE `identifier` = ?
    ]], { xPlayer.identifier })

    TriggerClientEvent('realrpg_cargo_phone:statsResult', _source, ok and stats and stats[1] or nil)
end)

RegisterNetEvent('realrpg_cargo_phone:getCompany', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    local ok, employee = pcall(MySQL.query.await, [[
        SELECT e.role as my_role, e.salary as my_salary, e.deliveries_done,
               c.id as company_id, c.name as company_name, c.balance, c.reputation,
               c.total_deliveries, c.total_distance
        FROM `realrpg_cargo_employees` e
        JOIN `realrpg_cargo_companies` c ON c.id = e.company_id
        WHERE e.identifier = ?
    ]], { xPlayer.identifier })

    if ok and employee and employee[1] then
        local empCount = MySQL.query.await('SELECT COUNT(*) as cnt FROM `realrpg_cargo_employees` WHERE `company_id` = ?', { employee[1].company_id })
        employee[1].employee_count = empCount and empCount[1] and empCount[1].cnt or 0
        TriggerClientEvent('realrpg_cargo_phone:companyResult', _source, employee[1])
    else
        TriggerClientEvent('realrpg_cargo_phone:companyResult', _source, nil)
    end
end)

RegisterNetEvent('realrpg_cargo_phone:deposit', function(amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    amount = tonumber(amount) or 0
    if amount <= 0 then return end

    local emp = MySQL.query.await('SELECT `company_id` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
    if not emp or not emp[1] then return end

    local bank = xPlayer.getAccount('bank')
    local bankMoney = bank and bank.money or 0

    if bankMoney >= amount then
        xPlayer.removeAccountMoney('bank', amount)
    elseif xPlayer.getMoney() >= amount then
        xPlayer.removeMoney(amount)
    else
        TriggerClientEvent('realrpg_cargo_phone:actionResult', _source, { success = false, message = 'Nincs elég pénzed!' })
        return
    end

    MySQL.update('UPDATE `realrpg_cargo_companies` SET `balance` = `balance` + ? WHERE `id` = ?', { amount, emp[1].company_id })
    TriggerClientEvent('realrpg_cargo_phone:actionResult', _source, { success = true, message = amount .. ' Ft befizetve!' })
end)

RegisterNetEvent('realrpg_cargo_phone:withdraw', function(amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    amount = tonumber(amount) or 0
    if amount <= 0 then return end

    local emp = MySQL.query.await('SELECT `company_id` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
    if not emp or not emp[1] then return end

    local company = MySQL.query.await('SELECT `balance` FROM `realrpg_cargo_companies` WHERE `id` = ?', { emp[1].company_id })
    if not company or not company[1] or company[1].balance < amount then
        TriggerClientEvent('realrpg_cargo_phone:actionResult', _source, { success = false, message = 'Nincs elég pénz a kasszában!' })
        return
    end

    MySQL.update('UPDATE `realrpg_cargo_companies` SET `balance` = `balance` - ? WHERE `id` = ?', { amount, emp[1].company_id })
    xPlayer.addAccountMoney('bank', amount)
    TriggerClientEvent('realrpg_cargo_phone:actionResult', _source, { success = true, message = amount .. ' Ft kivéve!' })
end)

print('[RealRPG Cargo Phone] Server loaded')
