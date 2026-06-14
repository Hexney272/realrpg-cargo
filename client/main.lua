print('[RealRPG Cargo] main.lua loaded')
--ESX = nil
ECO = ECO or {}
ECO.blips = ECO.blips or {}
ECO.zones = ECO.zones or {}
ECO.allZones = ECO.allZones or {}
ECO.distances = ECO.distances or {}
ECO.loadingZones = ECO.loadingZones or {}
ECO.targetZone = ECO.targetZone or {}
ECO.closestZones = ECO.closestZones or {}
ECO.allProducts = ECO.allProducts or {}
ECO.CARGO = { interruption = true }
ECO.MONITOR = { queryStatus = {}, hasAlreadyNotify = {}, area = 'country' }
ECO.LOADED = ECO.LOADED or {}
ECO.PLAYER = ECO.PLAYER or {}
ECO.PLAYERS = ECO.PLAYERS or {}
ECO.MISSION = ECO.MISSION or {}
ECO.DIAGNOSTICS = ECO.DIAGNOSTICS or {}

local selectCharacters

_PlayerPedId = nil

local playerLoaded
local hasAlreadyEnteredMarker, currentActionData = false, {}
local currentAction, currentActionMsg, lastZone

Citizen.CreateThread(function()

    -- Wait for ESX player to be loaded
    while not ESX.PlayerLoaded do Citizen.Wait(1000) end

    -- LOADING PLAYER LIST
    ECO.PLAYERS = lib.callback.await('realrpg_cargo:getPlayers', false)
    ECO.LOADED.players = true

    if Config.kashacters then

        local serverId = GetPlayerServerId(PlayerId())

        if not ECO.PLAYERS[serverId] then
            while not selectCharacters do Citizen.Wait(2000) end
        end
    end

    -- LOADING PLAYER DATA
    local player = lib.callback.await('realrpg_cargo:getPlayer', false)
    ECO.PLAYER = player
    ECO.PLAYER.cargoRequestTime = 0
    ECO.LOADED.player = true

    -- LOADING MISSION DATA
    ECO.MISSION = lib.callback.await('realrpg_cargo:getMission', false)
    ECO.LOADED.mission = true

    -- LOADING DATABASE: ZONE DATA
    local zones = lib.callback.await('realrpg_cargo:getZones', false)

    if zones and next(zones) ~= nil then

        for _, v in pairs(zones) do

            ECO.allZones[v.id] = v
            ECO.allZones[v.id].actionpoint = coordsPharser(v.actionpoint)
            ECO.allZones[v.id].spawnpoint = coordsPharser(v.spawnpoint)
        end
    end

    zones = nil
    ECO.LOADED.allZones = true

    -- LOADING DATABASE: DISTANCE DATA
    local distances = lib.callback.await('realrpg_cargo:getDistances', false)

    if distances and next(distances) ~= nil then

        for _, v in pairs(distances) do

            ECO.distances[v.id] = ESX.Math.Round(v.route * 0.001, 1)
        end
    end

    distances = nil
    ECO.LOADED.distances = true

    -- LOADING DATABASE: PRODUCT DATA
    local products, loadingZonesIds = lib.callback.await('realrpg_cargo:getProducts', false)

    if products and next(products) ~= nil then

        ECO.allProducts = products

        for k, _ in pairs(loadingZonesIds) do

            ECO.loadingZones[#ECO.loadingZones + 1] = ECO.allZones[k]
        end
    end

    products = nil
    ECO.LOADED.loadingZones = true
    ECO.LOADED.allProducts = true

    _PlayerPedId = PlayerPedId()
end)


RegisterNetEvent('esx:setJob', function(job)
    ECO.PLAYER.job = job
end)

RegisterNetEvent('playerSpawned', function()
    ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:kashloaded', function()
    selectCharacters = true
end)


-- CHECKPOINT HANDLE - Enter / Exit marker events
-- OPTIMIZED: Squared distance comparison (no sqrt), early exit when not driving
Citizen.CreateThread(function()

    while not ECO.LOADED.allZones do Citizen.Wait(1000) end

    local closestZones, coords, distSq, currentZone, isInMarker, zones
    local MARKER_DIST_SQ = 36      -- 6^2 meters
    local RENDER_DIST_SQ = 22500   -- 150^2 meters

    while true do

        Citizen.Wait(1000)

        zones = ECO.zones

        if ECO.PLAYER.isApprovedDriver and _PlayerPedId then

            coords = GetEntityCoords(_PlayerPedId)
            isInMarker = false
            currentZone = nil
            closestZones = {}

            for k, v in pairs(zones) do

                local zoneCoord = v['actionpoint'][1][1]
                local dx = coords.x - zoneCoord.x
                local dy = coords.y - zoneCoord.y
                local dz = coords.z - zoneCoord.z
                distSq = dx*dx + dy*dy + dz*dz

                if distSq < RENDER_DIST_SQ then
                    closestZones[#closestZones + 1] = k
                end
                if distSq < MARKER_DIST_SQ then
                    isInMarker = true
                    currentZone = k
                end
            end

            ECO.closestZones = closestZones

            if (isInMarker and not hasAlreadyEnteredMarker) or (isInMarker and lastZone ~= currentZone) then
                hasAlreadyEnteredMarker = true
                lastZone = currentZone
                TriggerEvent('realrpg_cargo:hasEnteredMarker', currentZone)
            end

            if not isInMarker and hasAlreadyEnteredMarker then
                hasAlreadyEnteredMarker = false
                TriggerEvent('realrpg_cargo:hasExitedMarker', lastZone)
            end
        end
    end
end)

AddEventHandler('realrpg_cargo:hasEnteredMarker', function(itemIndex)

    currentActionData = ECO.zones[itemIndex]

    if not ECO.CARGO.interruption then

        currentAction = 'delivery_of_goods'
        currentActionData.message = _('delivery_of_goods')
    else

        currentAction = 'open_freight_list'
        currentActionData.message = _('open_freight_list')
    end

    sendHudActionData(currentActionData, 'append')
end)

AddEventHandler('realrpg_cargo:hasExitedMarker', function(itemIndex)

    currentAction = nil
    sendHudActionData({}, 'close')
end)

-- Display Action points markers + Key input handler
-- OPTIMIZED: Separated marker rendering from game logic
--   - DrawMarker: Wait(0) only when zones are nearby
--   - Key input: only checked when there's an active action
Citizen.CreateThread(function()

    while not ECO.LOADED.allZones do Citizen.Wait(1000) end

    local index, item, zones

    while true do

        index = ECO.closestZones
        zones = ECO.zones

        if index[1] and ECO.PLAYER.isApprovedDriver then

            -- Key controls (only when in marker)
            if currentAction then

                if IsControlJustReleased(0, 38) then

                    -- MESSAGE CLOSE
                    SendNUIMessage({
                        subject = "CLOSE_PAGE"
                    })

                    if currentAction == 'delivery_of_goods' then

                        ECO.CARGO.showPayData = true

                        -- SECURE: Server handles payment calculation
                        TriggerServerEvent('realrpg_cargo:deliverCargo', ECO.CARGO.trailerPlate)

                        DetachVehicleFromTrailer(ECO.Vehicle)
                        Citizen.Wait(300)

                        ESX.Game.DeleteVehicle(ECO.CARGO.trailer)
                        finishCargo('DELIVERED')

                    elseif currentAction == 'open_freight_list' then

                        local serverTimeStamp = lib.callback.await('realrpg_cargo:getServerTime', false)

                        local loadingPositionId = currentActionData['id']
                        local zoneProductsIds = getZoneProductsIds(loadingPositionId)
                        local products = {}
                        local destinationZones, destinationIds, distance, km, cId, propertyNames

                        if next(zoneProductsIds) then

                            for productId, v in pairs(zoneProductsIds) do

                                local product = deepCopy(ECO.allProducts[productId])
                                local lastStartTime = product.loading[loadingPositionId]

                                product.remainingTime = remainingTime(lastStartTime, product.reproduction_time, serverTimeStamp)
                                product.remainingTimeDisplay = ''

                                if product.remainingTime ~= 0 then

                                    local timeValue, timeUnit = displayTime(product.remainingTime)
                                    product.remainingTimeDisplay = string.format("%s %s", timeValue, _(timeUnit))
                                end

                                product.label = _(product.name)
                                product.defenderLabel = product.defender == '' and '' or _(product.defender)

                                destinationIds = json.decode(product.destination)
                                propertyNames = json.decode(product.properties)
                                product.params = calculateParams(propertyNames)

                                product.destinationZones = {}

                                for j = 1, #destinationIds do

                                    cId = tonumber(concatId(loadingPositionId, destinationIds[j], '', true))
                                    distance = getValue(ECO.distances, cId, 0)

                                    product.destinationZones[j] = deepCopy(ECO.allZones[destinationIds[j]])
                                    product.destinationZones[j].distance = distance
                                    product.destinationZones[j].priceData = calculatePrice(propertyNames, distance, product)
                                end

                                table.insert(products, product)
                            end
                        end

                        openNUI(products, "CARGO_SELECT")
                    end

                    currentAction = nil
                end
            end

            -- DrawMarker
            for i = 1, #index do

                item = zones[index[i]]

                if item then
                    DrawMarker(23, item['actionpoint'][1][1], 0.0, 0.0, 0.0, 0, 0.0, 0.0, 6.0, 6.0, 0.5, 255, 0, 0, 255, false, false, 2, false, false, false, false)
                end
            end

            Citizen.Wait(0)
        else
            Citizen.Wait(1000)
        end
    end
end)

RegisterNetEvent('realrpg_cargo:changeMonitorOwner', function(trailerPlate, newOwner)

    -- changeMonitorOwner
    if ECO.CARGO.trailerPlate == trailerPlate then

        ECO.CARGO.trailer = false
        ECO.CARGO.monitorOwner = newOwner
    end
end)


function openNUI(data, subject)

    SetNuiFocus(true, true)

    SendNUIMessage({
        data = data,
        subject = subject,
        currentZone = currentActionData or {},
        player = ECO.PLAYER,
        mission = ECO.MISSION,
        disableMissionStartForDefenders = Config.disableMissionStartForDefenders
    })
end


RegisterNUICallback('registerCargo', function(data, cb)

    SetNuiFocus(false, false)

    local startPermission = true
    local permissionMsg = ''

    if data.defender ~= '' then

        if next(ECO.MISSION) ~= nil then

            for _, v in pairs(ECO.MISSION) do

                if v.trailerPlate then startPermission = false end
            end

            permissionMsg = _('a_mission_is_already_in_progress')
        end


        if Config.disableMissionStartForDefenders then

            if data.defender == ECO.PLAYER.job.name then

                startPermission = false
                permissionMsg = _('disable_mission_start_for_defenders')
            end
        end
    end


    if startPermission then

        local remainingTime = lib.callback.await('realrpg_cargo:getRemainingTime', false, data)

        if remainingTime == 0 then

            local trailer = trailerSpawn(currentActionData['spawnpoint'], data.productId)

            if trailer then

                ECO.PLAYER.cargoRequestTime = GetGameTimer()

                ECO.CARGO = {
                    -- TRAILER
                    trailer = trailer,
                    trailerHealth = 1000,
                    trailerModel = data.trailerModel,
                    trailerPlate = safePlate(GetVehicleNumberPlateText(trailer)),
                    stolen = false,

                    -- PRODUCT
                    productId = data.productId,

                    -- MONITOR
                    monitorOwner = ECO.PLAYER.serverId,
                    quality = 100,
                    params = json.decode(data.params),

                    -- MONEY
                    freightFee = data.freightFee,
                    illegalPrice = data.illegalPrice,
                    goodsValue = data.goodsValue,
                    cautionMoney = data.cautionMoney,

                    -- ZONE
                    km = data.km,
                    destinationZoneId = data.destinationId,
                    loadingZoneId = data.loadingZoneId,

                    -- OWNER
                    owner = ECO.PLAYER
                }

                TriggerServerEvent('realrpg_cargo:cargoRegister', ECO.CARGO)
            end
        else

            local timeValue, timeUnit = displayTime(remainingTime)
            DoCustomHudText('fail', _('cargo_not_available', timeValue, _(timeUnit)))
        end
    else

        DoCustomHudText('fail', permissionMsg)
    end

    cb('ok')
end)


RegisterNUICallback('exit', function(data, cb)

    SetNuiFocus(false, false)
    cb('ok')
end)

-- SECURE: Receive payment data from server after delivery
RegisterNetEvent('realrpg_cargo:paymentProcessed', function(paymentData)

    -- Show the cargo report with server-calculated payment
    local report = createCargoReport(ECO.CARGO)
    report.payData = paymentData
    report.showPayData = true

    openNUI(report, "CARGO_REPORT")
end)


RegisterCommand('inspect', function()

    local coords = GetEntityCoords(PlayerPedId())
    local vehicle, distance = ESX.Game.GetClosestVehicle(coords)

    if not IsPedOnFoot(PlayerPedId()) then

        DoCustomHudText('information', _('that_way_you_cant_scan_anything'))
        return false
    end

    if vehicle == 0 or distance > 10 then

        DoCustomHudText('information', _('there_are_no_vehicles_nearby'))
        return false
    end

    if GetVehicleClass(vehicle) ~= 11 then

        DoCustomHudText('information', _('you_can_only_scan_a_trailer'))
        return false
    end

    local data = lib.callback.await('realrpg_cargo:getDataByPlate', false, GetVehicleNumberPlateText(vehicle))

    if data then
        openNUI(createCargoReport(data), "CARGO_REPORT")
    else
        DoCustomHudText('fail', _('no_information'))
    end
end)


RegisterCommand('closenui', function()

    SetNuiFocus(false, false)

    SendNUIMessage({
        subject = 'CLOSE_PAGE'
    })
end)

