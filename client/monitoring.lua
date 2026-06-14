--[[
    ECO Cargo - Client Monitoring
    Optimized threads for cargo state tracking and real-time monitoring
]]

-- ROUTER: Slow monitoring loop (every 2 seconds)
Citizen.CreateThread(function()

    while not ECO.LOADED.player do Citizen.Wait(1000) end

    while true do

        _PlayerPedId = PlayerPedId()

        Citizen.Wait(2000)

        ----------------- DATA COLLECTION -----------------

        ECO.MONITOR.gameTimer = GetGameTimer()
        ECO.PLAYER.coords = GetEntityCoords(_PlayerPedId)

        -- CHECK VEHICLE
        ECO.Vehicle = GetVehiclePedIsIn(_PlayerPedId, false)

        -- TRUCK AND DRIVER INSPECTION
        isApprovedDriver()

        -- TRAILER INSPECTION
        getTrailer()

        -- TRAILER SLOW MONITORING
        getLiveData()

        ------------------ CARGO SETTINGS -----------------

        -- DELIVERY INTERRUPTION
        deliveryInterruption()

        -- TRAILER TOWING
        initCargo()

        -- INIT ZONES
        setZones()

        -- SHOW ACTIONS, NOTIFICATION, DELIVERY INFORMATION
        setHud()
    end
end)

-- FAST LIVEDATA: Real-time cargo monitoring (collision, roll, speed)
-- OPTIMIZED: Uses dynamic wait time based on cargo state and speed
Citizen.CreateThread(function()

    while not ECO.CARGO or not ECO.CARGO.trailer do Citizen.Wait(1000) end

    local speed = 0
    local _GetFrameTime, prevSpeed, roll
    local abs = math.abs
    local waitTime

    while true do

        if ECO.CARGO.trailer then

            prevSpeed = speed
            speed = GetEntitySpeed(ECO.CARGO.trailer) * 3.6
            roll = abs(GetEntityRoll(ECO.CARGO.trailer))

            _GetFrameTime = GetFrameTime()

            -- HitByEntity
            collisionMonitor(speed, prevSpeed)

            -- OVERTURNING MONITOR
            overturningMonitor(roll)

            -- ROLL AND WHEELS MONITOR
            rollMonitor(speed, roll, _GetFrameTime)

            -- SPEEDLIMIT ALERT
            speedLimitMonitor(speed)

            -- DYNAMIC WAIT: Higher speed or dangerous cargo = more frequent checks
            -- Stationary or slow: check less frequently to save FPS
            if speed < 5 then
                waitTime = 100  -- Barely moving: 10 fps check rate
            elseif speed < 30 then
                waitTime = 50   -- Slow: 20 fps check rate
            elseif speed < 60 then
                waitTime = 16   -- Medium: ~60 fps check rate
            else
                waitTime = 0    -- Fast: every frame (critical for collision detection)
            end

            Citizen.Wait(waitTime)
        else
            Citizen.Wait(2000)
        end
    end
end)

-- SEND DATA TO SERVER: Periodic server sync
Citizen.CreateThread(function()

    while true do

        Citizen.Wait(20000)

        if ECO.MONITOR.ServerSaveRequest and ECO.CARGO.trailer then
            TriggerServerEvent('eco_cargo:cargoUpdate', ECO.CARGO)
            ECO.MONITOR.ServerSaveRequest = false
        end
    end
end)

-- TRAILER MARKER: Show marker above detached trailer
-- OPTIMIZED: Only runs the Wait(0) loop when conditions are met
Citizen.CreateThread(function()

    while true do

        -- Check conditions at low frequency first
        if ECO.PLAYER.isApprovedDriver and
                ECO.CARGO.trailer and
                ECO.CARGO.attachedTo == 0 and
                ECO.PLAYER.coords and ECO.CARGO.coords and
                #(ECO.PLAYER.coords - ECO.CARGO.coords) < 100 then

            -- Only draw marker every frame when actually needed
            DrawMarker(22,
                ECO.CARGO.coords.x,
                ECO.CARGO.coords.y,
                ECO.CARGO.coords.z + 5,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                2.0, 2.0, -6.0,
                255, 255, 0, 255,
                true, -- bobUpAndDown
                true, 2, false, false, false, false)

            Citizen.Wait(0)
        else
            Citizen.Wait(1000)
        end
    end
end)

-- SEND TRAILER SIGNAL: Periodic GPS signal for marked cargo
Citizen.CreateThread(function()

    while true do

        Citizen.Wait(Config.missionTrailerSignalInterval * 1000)

        if ECO.MONITOR.towing and ECO.CARGO.params and ECO.CARGO.params.marked_on_the_map == 1 then
            TriggerServerEvent('eco_cargo:trailerSignal', ECO.CARGO.coords, ECO.MONITOR.trailerPlate, true)
        end
    end
end)

-- ============================================================
-- EVENT HANDLERS
-- ============================================================

-- PLAYER MONITORING
RegisterNetEvent('eco_cargo:updatePlayers', function(players)
    ECO.PLAYERS = players
end)

-- MISSION MONITORING
RegisterNetEvent('eco_cargo:missionUpdate', function(mission)
    ECO.MISSION = mission
end)

-- PRODUCT COOLDOWN MONITORING
RegisterNetEvent('eco_cargo:productUpdate', function(data)
    if ECO.allProducts[data.productId] then
        ECO.allProducts[data.productId].loading[data.loadingZoneId] = data.time
    end
end)
