--[[
    RealRPG Cargo - Contract Generator (Server-side)
    Generates SHARED contracts visible to ALL companies.
    First company to accept gets the contract - competitive system.
    
    Contracts are NOT tied to a specific company until accepted.
    company_id = 0 means "available to all"
]]

if not Config.company or not Config.company.enabled then return end

print('[RealRPG Cargo] contracts.lua loaded')

-- ============================================================
-- CONTRACT GENERATOR
-- ============================================================

--- Generate new shared contracts from existing products and zones
local function generateContracts()
    -- Count existing available contracts
    local ok, existing = pcall(MySQL.query.await, [[
        SELECT COUNT(*) as cnt FROM `realrpg_cargo_contracts` 
        WHERE `status` = 'available' AND `company_id` IS NULL
    ]], {})

    if not ok then
        print('[RealRPG Cargo] Contract generator DB error: ' .. tostring(existing))
        return
    end

    local currentCount = (existing and existing[1]) and existing[1].cnt or 0
    local maxContracts = Config.company.contracts.maxAvailable or 8

    if currentCount >= maxContracts then return end

    -- Get products with valid routes
    local ok2, products = pcall(MySQL.query.await, [[
        SELECT `id`, `name`, `value`, `loading`, `destination`, `properties`, `defender`
        FROM `realrpg_cargo_products`
        WHERE `loading` NOT IN('[]', '') AND `destination` NOT IN('[]', '')
        ORDER BY RAND()
        LIMIT 5
    ]], {})

    if not ok2 or not products or not products[1] then return end

    -- Get zones for distance lookup
    local ok3, distances = pcall(MySQL.query.await, 'SELECT `id`, `route` FROM `realrpg_cargo_distances`', {})
    if not ok3 then return end

    local distMap = {}
    if distances then
        for _, d in ipairs(distances) do
            distMap[d.id] = math.round(d.route * 0.001, 1)
        end
    end

    local contractsToCreate = maxContracts - currentCount
    local created = 0

    for _, product in ipairs(products) do
        if created >= contractsToCreate then break end

        local loading = json.decode(product.loading)
        local destination = json.decode(product.destination)

        if loading and loading[1] and destination and destination[1] then
            -- Pick random from/to
            local zoneFrom = loading[math.random(#loading)]
            local zoneTo = destination[math.random(#destination)]

            -- Calculate distance
            local distId = tonumber(concatId(zoneFrom, zoneTo, '', true))
            local km = distMap[distId] or math.random(5, 25)

            -- Calculate reward based on distance + config
            local baseReward = Config.company.contracts.baseReward
            local distBonus = km * Config.company.contracts.distanceMultiplier
            local reward = math.round(baseReward + distBonus)

            -- Defender products pay more
            if product.defender and product.defender ~= '' then
                reward = math.round(reward * 3)
            end

            -- Bonus reward for high quality delivery
            local bonusReward = math.round(reward * Config.company.contracts.qualityBonus)

            -- Penalty for failure
            local penalty = math.round(reward * Config.company.contracts.penaltyRate)

            -- Required quality (harder contracts = more reward)
            local requiredQuality = math.random(70, 95)
            if requiredQuality >= 90 then
                reward = math.round(reward * 1.3)
            end

            -- Deadline (hours)
            local deadline = Config.company.contracts.deadlineDefault

            -- Expiry (when the contract disappears if not accepted)
            local expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (Config.company.contracts.refreshInterval * 60))

            -- Insert contract (company_id = 0 = shared/available to all)
            local ok4, insertId = pcall(MySQL.insert.await, [[
                INSERT INTO `realrpg_cargo_contracts`
                (`company_id`, `product_id`, `zone_from`, `zone_to`, `reward`, `bonus_reward`, 
                 `penalty`, `required_quality`, `deadline_hours`, `status`, `expires_at`)
                VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, 'available', ?)
            ]], { product.id, zoneFrom, zoneTo, reward, bonusReward, penalty, requiredQuality, deadline, expiresAt })

            if ok4 and insertId then
                created = created + 1
            end
        end
    end

    if created > 0 then
        print('[RealRPG Cargo] Generated ' .. created .. ' new contracts')
    end
end

-- ============================================================
-- AUTO-GENERATION LOOP
-- ============================================================

Citizen.CreateThread(function()
    -- Wait for server to be ready
    Citizen.Wait(10000)

    -- Generate initial contracts
    generateContracts()

    -- Then generate periodically
    while true do
        Citizen.Wait(Config.company.contracts.refreshInterval * 60 * 1000)
        generateContracts()

        -- Also expire old contracts
        pcall(MySQL.update, [[
            UPDATE `realrpg_cargo_contracts` 
            SET `status` = 'expired' 
            WHERE `status` = 'available' AND `expires_at` < NOW()
        ]], {})
    end
end)

-- ============================================================
-- CONTRACT CALLBACKS (shared contracts - competitive)
-- ============================================================

--- Get ALL available contracts (shared between companies)
RegisterNetEvent('realrpg_cargo:contracts:getAvailable', function()
    local _source = source
    local ok, contracts = pcall(MySQL.query.await, [[
        SELECT c.*, p.name as product_name, p.properties as product_properties,
               p.trailer as product_trailer, p.defender as product_defender,
               z1.name as zone_from_name, z1.address as zone_from_address,
               z2.name as zone_to_name, z2.address as zone_to_address
        FROM `realrpg_cargo_contracts` c
        LEFT JOIN `realrpg_cargo_products` p ON p.id = c.product_id
        LEFT JOIN `realrpg_cargo_zones` z1 ON z1.id = c.zone_from
        LEFT JOIN `realrpg_cargo_zones` z2 ON z2.id = c.zone_to
        WHERE c.`status` = 'available' AND c.`company_id` IS NULL
        ORDER BY c.`reward` DESC
    ]], {})

    if not ok then
        print('[RealRPG Cargo] Get contracts error: ' .. tostring(contracts))
        TriggerClientEvent('realrpg_cargo:contracts:availableResult', _source, {})
        return
    end

    TriggerClientEvent('realrpg_cargo:contracts:availableResult', _source, contracts or {})
end)

--- Accept a shared contract (competitive - first come first served)
RegisterNetEvent('realrpg_cargo:contracts:accept', function(contractId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier

    -- Get player's company
    local ok, emp = pcall(MySQL.query.await, 'SELECT `company_id`, `role` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
    if not ok or not emp or not emp[1] then
        TriggerClientEvent('realrpg_cargo:contracts:acceptResult', _source, { success = false, message = 'Nem vagy cégnél!' })
        return
    end

    local companyId = emp[1].company_id

    -- Check permission
    if not hasPermission(emp[1].role, 'accept_contracts') then
        TriggerClientEvent('realrpg_cargo:contracts:acceptResult', _source, { success = false, message = 'Nincs jogosultságod szerződést elfogadni!' })
        return
    end

    -- Try to claim the contract (atomic - prevents race condition)
    local ok2, affected = pcall(MySQL.update.await, [[
        UPDATE `realrpg_cargo_contracts` 
        SET `company_id` = ?, `status` = 'accepted', `accepted_at` = NOW(), `assigned_driver` = ?
        WHERE `id` = ? AND `status` = 'available' AND `company_id` IS NULL
    ]], { companyId, identifier, contractId })

    if not ok2 then
        print('[RealRPG Cargo] Accept contract error: ' .. tostring(affected))
        TriggerClientEvent('realrpg_cargo:contracts:acceptResult', _source, { success = false, message = 'Adatbázis hiba!' })
        return
    end

    if affected and affected > 0 then
        -- Get company name for notification
        local companyData = MySQL.query.await('SELECT `name` FROM `realrpg_cargo_companies` WHERE `id` = ?', { companyId })
        local companyName = (companyData and companyData[1]) and companyData[1].name or 'Ismeretlen'

        -- Notify ALL players that this contract was taken
        TriggerClientEvent('realrpg_cargo:contracts:taken', -1, {
            contractId = contractId,
            companyName = companyName
        })

        TriggerClientEvent('realrpg_cargo:contracts:acceptResult', _source, { success = true, message = 'Szerződés elfogadva! Határidő: ' .. Config.company.contracts.deadlineDefault .. ' óra' })
    else
        TriggerClientEvent('realrpg_cargo:contracts:acceptResult', _source, { success = false, message = 'Ezt a szerződést már más elfogadta!' })
    end
end)

-- ============================================================
-- ADMIN: Force generate contracts
-- ============================================================

RegisterCommand('gencontracts', function(source)
    if source == 0 then
        generateContracts()
        print('[RealRPG Cargo] Contracts generated by console')
    else
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and (xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin') then
            generateContracts()
            TriggerClientEvent('realrpg_cargo:showNotification', source, { type = 'success', text = 'Szerződések generálva!' })
        end
    end
end, false)
