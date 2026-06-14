--[[
    RealRPG - Cargo Delivery System
    Server-side logic
    Modernized: ox_lib callbacks, oxmysql, secure payment
]]

ECO = ECO or {}
ECO.CARGO = {}
ECO.PLAYERS = {}
ECO.MISSION = {}
ECO.PRODUCTS = {}
ECO.loadingZonesIds = {}

-- ============================================================
-- CALLBACKS (using lib.callback from ox_lib)
-- ============================================================

lib.callback.register('realrpg_cargo:getMission', function(source)
    return ECO.MISSION
end)

lib.callback.register('realrpg_cargo:getPlayers', function(source)

    -- PLAYER MONITORING
    if next(ECO.PLAYERS) == nil then

        local xPlayer
        local getPlayers = ESX.GetPlayers()

        for i = 1, #getPlayers do

            xPlayer = ESX.GetPlayerFromId(getPlayers[i])

            if xPlayer ~= nil then
                ECO.PLAYERS[xPlayer.source] = xPlayer.job.name
            end
        end
    end

    return ECO.PLAYERS
end)

lib.callback.register('realrpg_cargo:getPlayer', function(source)

    local xPlayer = ESX.GetPlayerFromId(source)

    local userData = {
        serverId = source,
        characterName = 'John Doe',
        dateOfBirth = '-',
        group = 'player',
        permissionLevel = 0,
        job = {},
        identifier = '',
    }

    if xPlayer ~= nil then

        userData.job = xPlayer.job
        userData.identifier = xPlayer.identifier

        local user = MySQL.query.await('SELECT * FROM users WHERE identifier = @identifier', {
            ['@identifier'] = userData.identifier
        })

        if user and user[1] then

            local firstname = user[1].firstname or ''
            local lastname = user[1].lastname or ''

            userData.characterName = firstname .. " " .. lastname
            userData.dateOfBirth = user[1].dateofbirth or '-'
            userData.group = user[1].group or 'player'
            userData.permissionLevel = user[1].permission_level or 0
        end
    end

    return userData
end)

lib.callback.register('realrpg_cargo:getZones', function(source)

    local zones = MySQL.query.await('SELECT * FROM realrpg_cargo_zones', {})
    return zones
end)

lib.callback.register('realrpg_cargo:getProducts', function(source)

    if next(ECO.PRODUCTS) == nil then

        local sql = 'SELECT * FROM `realrpg_cargo_products` WHERE `loading` NOT IN("[]", "") AND `destination` NOT IN("[]", "")'
        local result = MySQL.query.await(sql, {})

        if result and result[1] then

            ECO.loadingZonesIds = {}

            local row, loading

            for i = 1, #result do

                row = result[i]
                loading = {}

                row.loading = json.decode(row.loading)

                if row.loading then

                    for j = 1, #row.loading do

                        loading[row.loading[j]] = 0
                        ECO.loadingZonesIds[row.loading[j]] = true
                    end
                end

                ECO.PRODUCTS[row.id] = row
                ECO.PRODUCTS[row.id].loading = loading
            end
        end
    end

    return ECO.PRODUCTS, ECO.loadingZonesIds
end)

lib.callback.register('realrpg_cargo:getAllProducts', function(source)

    local result = MySQL.query.await('SELECT * FROM `realrpg_cargo_products`', {})
    return result
end)

lib.callback.register('realrpg_cargo:getDistances', function(source)

    local distances = MySQL.query.await('SELECT * FROM `realrpg_cargo_distances`', {})
    return distances
end)

lib.callback.register('realrpg_cargo:cargoLoader', function(source, plate, existsCheck)

    if existsCheck then
        -- Reserved for future use (trailer respawning logic)
        return nil
    else
        return ECO.CARGO[plate]
    end
end)

lib.callback.register('realrpg_cargo:getDataByPlate', function(source, plate)

    plate = safePlate(plate)
    return ECO.CARGO[plate]
end)

lib.callback.register('realrpg_cargo:getAllStatistics', function(source, data)

    -- SECURITY: Whitelist allowed orderBy columns to prevent SQL injection
    local allowedOrderBy = {
        all_started = true,
        all_done = true,
        distance = true,
        quality_rate = true,
        success_rate = true,
        vulnerable = true,
        working_time = true,
        last_activity = true
    }

    local allowedDir = {
        ASC = true,
        DESC = true
    }

    if not data.orderBy or not allowedOrderBy[data.orderBy] then data.orderBy = 'all_started' end
    if not data.dir or not allowedDir[data.dir] then data.dir = 'DESC' end

    local sql = [[
        SELECT `realrpg_cargo_stats`.*,
        `realrpg_cargo_stats`.`started_mission` + `realrpg_cargo_stats`.`started_delivery` as `all_started`,
        `realrpg_cargo_stats`.`done_mission` + `realrpg_cargo_stats`.`done_delivery` as `all_done`,
        `realrpg_cargo_stats`.`stolen_mission` + `realrpg_cargo_stats`.`stolen_delivery` as `all_stolen`,
        `realrpg_cargo_stats`.`goods_quality` / (`realrpg_cargo_stats`.`started_mission` + `realrpg_cargo_stats`.`started_delivery`) as `quality_rate`,
        (`realrpg_cargo_stats`.`done_mission` + `realrpg_cargo_stats`.`done_delivery`) / (`realrpg_cargo_stats`.`started_mission` + `realrpg_cargo_stats`.`started_delivery`) * 100 as `success_rate`,
        `users`.`firstname`,
        `users`.`lastname`
        FROM `realrpg_cargo_stats`
        LEFT JOIN `users`
        USING (`identifier`)
        ORDER BY `]] .. data.orderBy .. [[` ]] .. data.dir .. [[
        LIMIT 50
    ]]

    local result = MySQL.query.await(sql, {})
    return result
end)

lib.callback.register('realrpg_cargo:getAchievements', function(source)

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return {} end

    return ECO.Achievements.getAll(xPlayer.identifier)
end)

lib.callback.register('realrpg_cargo:getStatistics', function(source)

    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier

    local sql = [[
        SELECT `realrpg_cargo_stats`.*,
        `realrpg_cargo_stats`.`started_mission` + `realrpg_cargo_stats`.`started_delivery` as `all_started`,
        `realrpg_cargo_stats`.`done_mission` + `realrpg_cargo_stats`.`done_delivery` as `all_done`,
        `realrpg_cargo_stats`.`stolen_mission` + `realrpg_cargo_stats`.`stolen_delivery` as `all_stolen`,
        `realrpg_cargo_stats`.`goods_quality` / (`realrpg_cargo_stats`.`started_mission` + `realrpg_cargo_stats`.`started_delivery`) as `quality_rate`,
        (`realrpg_cargo_stats`.`done_mission` + `realrpg_cargo_stats`.`done_delivery`) / (`realrpg_cargo_stats`.`started_mission` + `realrpg_cargo_stats`.`started_delivery`) * 100 as `success_rate`,
        `users`.`firstname`,
        `users`.`lastname`
        FROM `realrpg_cargo_stats`
        LEFT JOIN `users`
        USING (`identifier`)
        WHERE `realrpg_cargo_stats`.`identifier` = @identifier
    ]]

    local result = MySQL.query.await(sql, { ['@identifier'] = identifier })
    return result
end)

lib.callback.register('realrpg_cargo:getServerTime', function(source)
    return os.time()
end)

lib.callback.register('realrpg_cargo:getRemainingTime', function(source, data)

    local product = ECO.PRODUCTS[data.productId]
    local lastStartTime = product.loading[data.loadingZoneId]

    return remainingTime(lastStartTime, product.reproduction_time, os.time())
end)

-- ============================================================
-- PLAYER MONITORING
-- ============================================================

AddEventHandler('esx:setJob', function(playerId, job)
    ECO.PLAYERS[playerId] = job.name
    TriggerClientEvent('realrpg_cargo:updatePlayers', -1, ECO.PLAYERS)
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    ECO.PLAYERS[playerId] = xPlayer.job.name
    TriggerClientEvent('realrpg_cargo:updatePlayers', -1, ECO.PLAYERS)
end)

AddEventHandler('esx:playerDropped', function(playerId)
    ECO.PLAYERS[playerId] = nil
    TriggerClientEvent('realrpg_cargo:updatePlayers', -1, ECO.PLAYERS)
end)

-- ============================================================
-- CARGO EVENTS
-- ============================================================

RegisterNetEvent('realrpg_cargo:cargoRegister', function(ecoCargo)

    local _source = source
    local plate = safePlate(ecoCargo.trailerPlate)
    local isMission, isVulnerable
    local osTime = os.time()

    if not ECO.CARGO[plate] then ECO.CARGO[plate] = {} end

    -- SECURITY: Validate caution money from server-side product data
    local product = ECO.PRODUCTS[tonumber(ecoCargo.productId)]
    if product then
        ecoCargo.cautionMoney = product.caution_money or 0
        ecoCargo.goodsValue = product.value or 0
    end

    --LAST START TIME REGISTER
    ECO.PRODUCTS[ecoCargo.productId].loading[ecoCargo.loadingZoneId] = osTime

    ecoCargo.startDelivery = osTime

    table.refresh(ECO.CARGO[plate], ecoCargo)

    -- PAY CAUTION (using server-validated amount)
    local cautionMoney = tonumber(ecoCargo.cautionMoney)

    if type(cautionMoney) == 'number' and cautionMoney > 0 then
        removeMoney(_source, cautionMoney)
    end

    -- ADD PLATE MISSION DATA
    local missionId = concatId(ecoCargo.loadingZoneId, ecoCargo.productId, '_')

    if ECO.MISSION[missionId] and ECO.MISSION[missionId].owner.identifier == ecoCargo.owner.identifier then

        isMission = true

        ECO.MISSION[missionId].trailerPlate = plate
        ECO.MISSION[missionId].destinationZoneId = ecoCargo.destinationZoneId

        TriggerClientEvent('realrpg_cargo:missionUpdate', -1, ECO.MISSION)
        TriggerClientEvent('realrpg_cargo:missionNotification', -1, { otherText = _('mission_start_alert') })
    end

    if ecoCargo.params.damageRoll < 10 or ecoCargo.params.collisionSensitivity < 100 then
        isVulnerable = true
    end

    -- STAT RECORD
    local sql = [[
    INSERT INTO `realrpg_cargo_stats`
    (
        `identifier`,
        `started_delivery`,
        `started_mission`,
        `vulnerable`,
        `last_activity`
    ) VALUES (
        @identifier,
        @started_delivery,
        @started_mission,
        @vulnerable,
        current_timestamp()
    )
    ON DUPLICATE KEY UPDATE
        `started_delivery` = `started_delivery` + @started_delivery,
        `started_mission` = `started_mission` + @started_mission,
        `vulnerable` = `vulnerable` + @vulnerable,
        `last_activity` = current_timestamp()
    ]]

    MySQL.update(sql, {
        ['@identifier'] = ecoCargo.owner.identifier,
        ['@started_delivery'] = isMission and 0 or 1,
        ['@started_mission'] = isMission and 1 or 0,
        ['@vulnerable'] = isVulnerable and 1 or 0,
    })

    TriggerClientEvent('realrpg_cargo:productUpdate', -1, {
        productId = ecoCargo.productId,
        loadingZoneId = ecoCargo.loadingZoneId,
        time = osTime
    })

    -- DISCORD: Cargo started notification
    ECO.Discord.cargoStarted({
        owner = ecoCargo.owner,
        productId = ecoCargo.productId,
        trailerPlate = plate,
        destinationZoneId = ecoCargo.destinationZoneId,
        km = ecoCargo.km
    })
end)

RegisterNetEvent('realrpg_cargo:cargoUpdate', function(ecoCargo)

    local plate = safePlate(ecoCargo.trailerPlate)

    if not ECO.CARGO[plate] then ECO.CARGO[plate] = {} end

    table.refresh(ECO.CARGO[plate], ecoCargo)
end)

RegisterNetEvent('realrpg_cargo:deleteCargo', function(plate, state)

    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local identifier = xPlayer.identifier

    if not ECO.CARGO[plate] then return end

    local isMission
    local increaseDoneDelivery, increaseDoneMission = 1, 1
    local quality = 0
    local defenders = {}
    local ecoCargo = ECO.CARGO[plate]
    local stolen = not (ecoCargo.owner.identifier == identifier)

    TriggerClientEvent('realrpg_cargo:trailerSignal', -1, {}, plate, false)

    -- DELETE MISSION DATA
    local missionId = concatId(ecoCargo.loadingZoneId, ecoCargo.productId, '_')

    if ECO.MISSION[missionId] and ECO.MISSION[missionId].trailerPlate == plate then

        isMission = true
        defenders = ECO.MISSION[missionId].joined
        TriggerEvent('realrpg_cargo:missionUpdate', { missionId = missionId }, 'delete')
    end

    local params = ecoCargo.params

    if params.extraStatDeliveryPoint and type(params.extraStatDeliveryPoint) == 'number' then
        increaseDoneDelivery = increaseDoneDelivery + params.extraStatDeliveryPoint
    end

    if params.extraStatQualityMultiplier and type(params.extraStatQualityMultiplier) == 'number' then
        quality = ecoCargo.quality * params.extraStatQualityMultiplier
    end

    if isMission then
        quality = ecoCargo.quality * 2
        increaseDoneMission = 2
    end

    local sql = [[
        INSERT INTO `realrpg_cargo_stats`
        (
            `identifier`,
            `distance`,
            `goods_quality`,
            `done_delivery`,
            `done_mission`,
            `stolen_delivery`,
            `stolen_mission`,
            `destroyed_trailer`,
            `working_time`,
            `last_activity`
        ) VALUES (
            @identifier,
            @distance,
            @goods_quality,
            @done_delivery,
            @done_mission,
            @stolen_delivery,
            @stolen_mission,
            @destroyed_trailer,
            @working_time,
            current_timestamp()
        )
        ON DUPLICATE KEY UPDATE
            `distance` = `distance` + @distance,
            `done_delivery` = IF(`started_delivery` >= `done_delivery` + @done_delivery, `done_delivery` + @done_delivery, `started_delivery`),
            `done_mission` = IF(`started_mission` >= `done_mission` + @done_mission, `done_mission` + @done_mission, `started_mission`),
            `goods_quality` = IF(`goods_quality` + @goods_quality > (`done_delivery` + `done_mission`) * 100,
            (`done_delivery` + `done_mission`) * 100, `goods_quality` + @goods_quality),
            `stolen_delivery` = `stolen_delivery` + @stolen_delivery,
            `stolen_mission` = `stolen_mission` + @stolen_mission,
            `destroyed_trailer` = `destroyed_trailer` + @destroyed_trailer,
            `working_time` = `working_time` + @working_time,
            `last_activity` = current_timestamp()
    ]]

    MySQL.update(sql, {
        ['@identifier'] = identifier,
        ['@distance'] = (not stolen and state ~= 'DESTROYED') and ecoCargo.km or 0,
        ['@goods_quality'] = (not stolen and state ~= 'DESTROYED') and quality or 0,
        ['@done_delivery'] = (not isMission and not stolen and state ~= 'DESTROYED') and increaseDoneDelivery or 0,
        ['@done_mission'] = (isMission and not stolen and state ~= 'DESTROYED') and increaseDoneMission or 0,
        ['@stolen_delivery'] = (not isMission and stolen and state ~= 'DESTROYED') and 1 or 0,
        ['@stolen_mission'] = (isMission and stolen and state ~= 'DESTROYED') and 1 or 0,
        ['@destroyed_trailer'] = state == 'DESTROYED' and 1 or 0,
        ['@working_time'] = not stolen and (os.time() - ecoCargo.startDelivery) or 0,
    })

    -- Update defender stats
    if next(defenders) ~= nil and not stolen and state ~= 'DESTROYED' then

        local defenderSql = [[
            INSERT INTO `realrpg_cargo_stats`
            (`identifier`, `defender`, `last_activity`)
            VALUES (@identifier, @defender, current_timestamp())
            ON DUPLICATE KEY UPDATE
                `defender` = `defender` + @defender,
                `last_activity` = current_timestamp()
        ]]

        for i = 1, #defenders do
            MySQL.update(defenderSql, {
                ['@identifier'] = defenders[i],
                ['@defender'] = 1,
            })
        end
    end

    ECO.CARGO[plate] = nil

    -- DISCORD: Notify based on cargo state
    if state == 'DESTROYED' then
        ECO.Discord.cargoDestroyed({
            driverName = xPlayer.getName and xPlayer.getName() or identifier,
            productId = ecoCargo.productId,
            trailerPlate = plate
        })
    elseif stolen then
        ECO.Discord.cargoStolen({
            thiefName = xPlayer.getName and xPlayer.getName() or identifier,
            ownerName = ecoCargo.owner.characterName or 'Unknown',
            productId = ecoCargo.productId,
            trailerPlate = plate
        })
    end
end)

RegisterNetEvent('realrpg_cargo:changeMonitorOwner', function(oldOwner, plate)

    local _source = source

    if ECO.CARGO[plate] then
        ECO.CARGO[plate].monitorOwner = _source
        TriggerClientEvent('realrpg_cargo:changeMonitorOwner', oldOwner, plate, _source)
    end
end)

-- ============================================================
-- SECURE PAYMENT (server-side calculation)
-- ============================================================

RegisterNetEvent('realrpg_cargo:deliverCargo', function(plate)

    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then return end

    plate = safePlate(plate)

    if not ECO.CARGO[plate] then return end

    local ecoCargo = ECO.CARGO[plate]
    local identifier = xPlayer.identifier
    local stolen = not (ecoCargo.owner.identifier == identifier)

    -- Server-side payment calculation
    local propertyNames = {}
    local product = ECO.PRODUCTS[tonumber(ecoCargo.productId)]

    if product and product.properties and product.properties ~= '' then
        propertyNames = json.decode(product.properties) or {}
    end

    local priceData = calculatePrice(propertyNames, ecoCargo.km, product)

    local paymentData = payData({
        freightFee = priceData.freightFee,
        illegalPrice = priceData.illegalPrice,
        trailerHealth = ecoCargo.trailerHealth or 1000,
        quality = ecoCargo.quality or 100,
        stolen = stolen,
        cautionMoney = ecoCargo.cautionMoney or 0,
        product = product
    })

    local amount = tonumber(paymentData.payable) or 0
    local societyAmount = tonumber(paymentData.defenderSocietyPayable) or 0
    local moneyType = stolen and Config.stolenCargoPaymentType or 'money'

    -- Pay the player
    if amount > 0 then
        if moneyType == 'black_money' or moneyType == 'bank' then
            xPlayer.addAccountMoney(moneyType, amount)
        else
            xPlayer.addMoney(amount)
        end

        TriggerClientEvent('realrpg_cargo:showNotification', _source, {
            type = 'money',
            text = _('add_money', amount, _(moneyType))
        })
    end

    -- Pay society
    if societyAmount > 0 and product.defender and product.defender ~= '' then
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. product.defender, function(account)
            if account then
                account.addMoney(societyAmount)
            end
        end)

        TriggerClientEvent('realrpg_cargo:missionNotification', -1, {
            defender = product.defender,
            type = 'money',
            text = _('add_society_money', _(product.defender), societyAmount)
        })
    end

    -- Return payment data to client for report display
    TriggerClientEvent('realrpg_cargo:paymentProcessed', _source, paymentData)

    -- DISCORD: Successful delivery notification
    ECO.Discord.cargoDelivered({
        driverName = xPlayer.getName and xPlayer.getName() or identifier,
        productId = ecoCargo.productId,
        trailerPlate = plate,
        km = ecoCargo.km,
        quality = ecoCargo.quality,
        payable = paymentData.payable
    })

    -- ACHIEVEMENTS: Check after successful delivery
    ECO.Achievements.check(identifier, _source)

    -- COMPANY: Process company delivery payment
    if ProcessCompanyDelivery then
        ProcessCompanyDelivery(identifier, {
            km = ecoCargo.km,
            quality = ecoCargo.quality,
            freightFee = priceData.freightFee,
            productId = ecoCargo.productId
        })
    end
end)

-- DEPRECATED: Legacy event handlers (kept for backward compatibility warnings)
RegisterNetEvent('realrpg_cargo:addMoney', function()
    print('[ECO CARGO WARNING] realrpg_cargo:addMoney called directly - this is deprecated and insecure!')
end)

RegisterNetEvent('realrpg_cargo:societyAddMoney', function()
    print('[ECO CARGO WARNING] realrpg_cargo:societyAddMoney called directly - this is deprecated!')
end)

RegisterNetEvent('realrpg_cargo:removeMoney', function(amount)
    local _source = source
    removeMoney(_source, amount)
end)

-- ============================================================
-- MISSION EVENTS
-- ============================================================

RegisterNetEvent('realrpg_cargo:missionUpdate', function(data, subject)

    local currentMission = ECO.MISSION[data.missionId]

    if not currentMission then return end

    if subject == 'leave' then

        for i = 1, #currentMission.joined do
            if currentMission.joined[i] == data.player.identifier then
                table.remove(currentMission.joined, i)
                break
            end
        end

        data.type = 'warning'
        data.text = _('defender_left', data.player.characterName, data.player.job.grade_label)
        TriggerClientEvent('realrpg_cargo:missionNotification', -1, data)

    elseif subject == 'join' then

        table.insert(currentMission.joined, data.player.identifier)

        data.type = 'information'
        data.text = _('defender_joined', data.player.characterName, data.player.job.grade_label)
        TriggerClientEvent('realrpg_cargo:missionNotification', -1, data)

    elseif subject == 'delete' then

        data.owner = currentMission.owner
        data.defender = currentMission.defender
        data.type = 'warning'
        data.text = _('mission_is_over')

        TriggerClientEvent('realrpg_cargo:missionNotification', -1, data)
        TriggerClientEvent('realrpg_cargo:trailerSignal', -1, {}, currentMission.plate, false)

        ECO.MISSION[data.missionId] = nil
    end

    TriggerClientEvent('realrpg_cargo:missionUpdate', -1, ECO.MISSION)
end)

RegisterNetEvent('realrpg_cargo:missionRegister', function(data)

    local missionId = data.missionId

    -- REGISTER MISSION
    if not ECO.MISSION[missionId] then

        ECO.MISSION[missionId] = {
            owner = data.owner,
            joined = {},
            defender = data.defender
        }

        TriggerClientEvent('realrpg_cargo:missionUpdate', -1, ECO.MISSION)
    end

    -- BROADCAST
    data.showChat = true
    data.type = "information"
    data.text = _('request_protection', data.owner.characterName)
    data.otherText = _('mission_alert')

    TriggerClientEvent('realrpg_cargo:missionNotification', -1, data)

    -- DISCORD: Mission registered notification
    ECO.Discord.missionRegistered({
        owner = data.owner,
        defender = data.defender,
        missionId = missionId,
        productId = data.productId,
        loadingZoneId = data.loadingZoneId
    })
end)

RegisterNetEvent('realrpg_cargo:showCountingZone', function(coord)
    TriggerClientEvent('realrpg_cargo:showCountingZone', -1, coord)
end)

RegisterNetEvent('realrpg_cargo:trailerSignal', function(coord, plate, state)
    TriggerClientEvent('realrpg_cargo:trailerSignal', -1, coord, plate, state)
end)

-- ============================================================
-- DISTANCE MANAGEMENT
-- ============================================================

RegisterNetEvent('realrpg_cargo:updateDistance', function(data)

    for k, v in pairs(data) do
        MySQL.update(
            "INSERT INTO `realrpg_cargo_distances` (`id`, `air`, `route`) VALUES (@id, @air, @route) ON DUPLICATE KEY UPDATE `air` = @air, `route` = @route",
            { ['@id'] = k, ['@air'] = v.air, ['@route'] = v.route }
        )
    end
end)

RegisterNetEvent('realrpg_cargo:deleteDistance', function(data)

    if type(data) == 'table' and next(data) then
        MySQL.update("DELETE FROM `realrpg_cargo_distances` WHERE `id` IN (" .. table.concat(data, ', ') .. ")", {})
    end
end)

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

function removeMoney(_source, amount)

    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then return end

    xPlayer.removeMoney(amount)

    TriggerClientEvent('realrpg_cargo:showNotification', _source, {
        type = 'money',
        text = _('remove_money', amount)
    })
end

-- ============================================================
-- ADMIN COMMANDS
-- ============================================================

RegisterCommand("cargodiag", function(source)

    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    local group = xPlayer.getGroup()

    if group == 'admin' or group == 'superadmin' then
        TriggerClientEvent('realrpg_cargo:cargoDiagnostics', source)
        TriggerClientEvent('esx:showNotification', source, '~r~ECO CARGO:~s~ Diagnosztika')
    else
        TriggerClientEvent('chat:addMessage', source, { args = { "^1SYSTEM", "Ehhez nincs jogosultságod!" } })
    end
end)
