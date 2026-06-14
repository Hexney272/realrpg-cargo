--[[
    RealRPG Cargo - Quasar Smartphone V3 App (Server)
    Handles data requests from the phone app and sends push notifications
]]

-- ============================================================
-- DATA REQUESTS FROM PHONE
-- ============================================================

RegisterNetEvent('realrpg_cargo_phone:getStats', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier

    local ok, stats = pcall(MySQL.query.await, [[
        SELECT *,
        `started_mission` + `started_delivery` as `all_started`,
        `done_mission` + `done_delivery` as `all_done`
        FROM `realrpg_cargo_stats`
        WHERE `identifier` = ?
    ]], { identifier })

    if ok and stats and stats[1] then
        TriggerClientEvent('realrpg_cargo_phone:statsResult', _source, stats[1])
    else
        TriggerClientEvent('realrpg_cargo_phone:statsResult', _source, nil)
    end
end)

RegisterNetEvent('realrpg_cargo_phone:getCompany', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier

    local ok, employee = pcall(MySQL.query.await, [[
        SELECT e.role as my_role, e.salary as my_salary, e.deliveries_done,
               c.id as company_id, c.name as company_name, c.balance, c.reputation,
               c.total_deliveries, c.total_distance
        FROM `realrpg_cargo_employees` e
        JOIN `realrpg_cargo_companies` c ON c.id = e.company_id
        WHERE e.identifier = ?
    ]], { identifier })

    if ok and employee and employee[1] then
        -- Get employee count
        local empCount = MySQL.query.await('SELECT COUNT(*) as cnt FROM `realrpg_cargo_employees` WHERE `company_id` = ?', { employee[1].company_id })

        employee[1].employee_count = empCount and empCount[1] and empCount[1].cnt or 0
        TriggerClientEvent('realrpg_cargo_phone:companyResult', _source, employee[1])
    else
        TriggerClientEvent('realrpg_cargo_phone:companyResult', _source, nil)
    end
end)

RegisterNetEvent('realrpg_cargo_phone:getContracts', function()
    local _source = source

    local ok, contracts = pcall(MySQL.query.await, [[
        SELECT c.id, c.reward, c.bonus_reward, c.required_quality, c.deadline_hours,
               p.name as product_name, p.defender as product_defender,
               z1.name as zone_from_name, z2.name as zone_to_name
        FROM `realrpg_cargo_contracts` c
        LEFT JOIN `realrpg_cargo_products` p ON p.id = c.product_id
        LEFT JOIN `realrpg_cargo_zones` z1 ON z1.id = c.zone_from
        LEFT JOIN `realrpg_cargo_zones` z2 ON z2.id = c.zone_to
        WHERE c.`status` = 'available' AND c.`company_id` IS NULL
        ORDER BY c.`reward` DESC
        LIMIT 10
    ]], {})

    TriggerClientEvent('realrpg_cargo_phone:contractsResult', _source, ok and contracts or {})
end)

RegisterNetEvent('realrpg_cargo_phone:deposit', function(amount)
    local _source = source
    -- Forward to main cargo resource
    TriggerEvent('realrpg_cargo:company:deposit', _source, amount)
    TriggerClientEvent('realrpg_cargo_phone:actionResult', _source, { success = true, message = 'Befizetés feldolgozva' })
end)

RegisterNetEvent('realrpg_cargo_phone:withdraw', function(amount)
    local _source = source
    TriggerEvent('realrpg_cargo:company:withdraw', _source, amount)
    TriggerClientEvent('realrpg_cargo_phone:actionResult', _source, { success = true, message = 'Kivétel feldolgozva' })
end)

-- ============================================================
-- PUSH NOTIFICATIONS (sent from main cargo resource)
-- ============================================================

-- Listen for cargo events and send phone notifications
AddEventHandler('realrpg_cargo:phone:notify', function(targetSource, title, text)
    local ok, _ = pcall(function()
        exports['qs-smartphone']:sendPhoneNotification(targetSource, {
            appId = 'realrpg_cargo',
            title = title,
            text = text,
        })
    end)
end)

-- Contract accepted notification (broadcast to all)
RegisterNetEvent('realrpg_cargo:contracts:taken', function(data)
    -- This is already handled client-side, but we can also push to phones
end)

print('[RealRPG Cargo Phone] Server loaded')
