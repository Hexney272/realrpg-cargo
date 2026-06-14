--[[
    ECO Cargo - Monitor Module
    Real-time monitoring: speed limits, roll, overturning, collisions
]]

ECO = ECO or {}
ECO.MonitorFn = {}

--- Monitor speed limit violations and update HUD
---@param speed number Current speed in km/h
function ECO.MonitorFn.speedLimit(speed)

    if speed > Config.speedLimit[ECO.MONITOR.area] + 5 then

        if not ECO.MONITOR.overSpeed then
            sendHudLiveData('overSpeed', 1)
            ECO.MONITOR.overSpeed = true
        end
    else

        if ECO.MONITOR.overSpeed then
            sendHudLiveData('overSpeed', 0)
            ECO.MONITOR.overSpeed = false
        end
    end
end

--- Update HUD speed limit display when zone changes
---@param speedLimit number Speed limit for current zone
function ECO.MonitorFn.setHudSpeedLimit(speedLimit)

    if ECO.MONITOR.hudSpeedLimit ~= speedLimit then
        sendHudLiveData('speedLimit', speedLimit)
        ECO.MONITOR.hudSpeedLimit = speedLimit
    end
end

--- Monitor trailer roll angle and apply quality damage
---@param speed number Current speed in km/h
---@param roll number Current roll angle (absolute)
---@param frameTime number Frame time from GetFrameTime()
function ECO.MonitorFn.roll(speed, roll, frameTime)

    if speed > ECO.CARGO.params.rollMonitoringSpeed then

        local rollLimit = ECO.CARGO.params.damageRoll - (((speed - ECO.CARGO.params.rollMonitoringSpeed) * 0.20) ^ 2) / 100
        if rollLimit < 4 then rollLimit = 4 end

        if roll > rollLimit then

            ECO.CARGO.quality = ECO.CARGO.quality - frameTime * 4
            ECO.MONITOR.ServerSaveRequest = true

            if not ECO.MONITOR.rollNotify then
                sendHudLiveData('roll')
                ECO.MONITOR.rollNotify = true
            end
        else
            ECO.MONITOR.rollNotify = false
        end

        if not IsVehicleOnAllWheels(ECO.CARGO.trailer) then

            ECO.CARGO.quality = ECO.CARGO.quality - frameTime * 4
            ECO.MONITOR.ServerSaveRequest = true

            if not ECO.MONITOR.wheelNotify then
                sendHudLiveData('wheel')
                ECO.MONITOR.wheelNotify = true
            end
        else
            ECO.MONITOR.wheelNotify = false
        end
    end
end

--- Monitor trailer overturning - destroys cargo if threshold exceeded
---@param roll number Current roll angle (absolute)
function ECO.MonitorFn.overturning(roll)

    if roll > ECO.CARGO.params.overturn then

        ECO.CARGO.quality = 0
        ECO.MONITOR.ServerSaveRequest = true

        DoCustomHudText('fail', _('delivery_failed'))
        finishCargo('DESTROYED')
    end
end

--- Monitor collisions and apply impact damage
---@param speed number Current speed in km/h
---@param prevSpeed number Previous frame speed in km/h
function ECO.MonitorFn.collision(speed, prevSpeed)

    if ECO.CARGO.params.collisionSensitivity < 1000 then

        local diff = math.abs(speed - prevSpeed)

        if diff > 5 and (GetLastMaterialHitByEntity(ECO.CARGO.trailer) ~= 0 or
                GetLastMaterialHitByEntity(ECO.CARGO.attachedTo) ~= 0) then

            if not ECO.MONITOR.ImpactFlash and ECO.CARGO.params.impactFlash < diff then
                AddExplosion(GetEntityCoords(ECO.CARGO.trailer), 7, 0.6, true, false, 5.0)
                ECO.MONITOR.ImpactFlash = true
            end

            ECO.CARGO.quality = ECO.CARGO.quality - ((diff / ECO.CARGO.params.collisionSensitivity) ^ 2) * 100
        end
    end
end

-- Global aliases for backward compatibility
speedLimitMonitor = ECO.MonitorFn.speedLimit
SetHudSpeedLimit = ECO.MonitorFn.setHudSpeedLimit
rollMonitor = ECO.MonitorFn.roll
overturningMonitor = ECO.MonitorFn.overturning
collisionMonitor = ECO.MonitorFn.collision
