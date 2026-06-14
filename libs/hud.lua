--[[
    ECO Cargo - HUD Module
    NUI communication, notifications, and HUD state management
]]

ECO = ECO or {}
ECO.Hud = {}

--- Update HUD state based on player/cargo context
function ECO.Hud.update()

    local presetName

    -- HUD PRESET SELECT
    if ECO.PLAYER.isApprovedDriver then

        if ECO.MONITOR.towing then
            if ECO.targetZone[1] then
                presetName = 'deliveryInformation'
            else
                presetName = 'notification'
            end
        else
            presetName = 'notification'
        end
    else
        presetName = 'hide'
    end

    -- HUD SETTINGS
    if ECO.MONITOR.hud == presetName then return end

    if presetName == 'deliveryInformation' then

        local data = {}
        local product = ECO.allProducts[tonumber(ECO.CARGO.productId)]

        data.targetZone = ECO.allZones[tonumber(ECO.CARGO.destinationZoneId)]
        data.productProperties = product.properties
        data.productName = _(product.name) or product.name
        data.speedLimit = Config.speedLimit['country']
        data.trailerHealth = 0
        data.goodsQuality = 0

        if ECO.CARGO.trailerHealth then
            data.trailerHealth = math.round(ECO.CARGO.trailerHealth * 0.1)
        end

        if ECO.CARGO.quality then
            data.goodsQuality = math.round(ECO.CARGO.quality)
        end

        SendNUIMessage({
            subject = "DELIVERY_INFO",
            deliveryData = data
        })

    elseif presetName == 'notification' then

        SendNUIMessage({ subject = "CLOSE_INFO" })
        ECO.Hud.notify("information", _('promotion_message'), 10000)

    else

        SendNUIMessage({ subject = "CLOSE_INFO" })
    end

    ECO.MONITOR.hud = presetName
end

--- Send live data update to HUD
---@param paramName string Parameter name to update
---@param value any New value
function ECO.Hud.sendLiveData(paramName, value)

    if ECO.MONITOR.towing then
        SendNUIMessage({
            subject = "UPDATE",
            paramName = paramName,
            value = value
        })
    end
end

--- Send action data to HUD (marker enter/exit)
---@param actionData table Action data
---@param operation string 'append' or 'close'
function ECO.Hud.sendActionData(actionData, operation)

    SendNUIMessage({
        subject = "ACTION_INFO",
        operation = operation,
        actionData = actionData
    })
end

--- Show a custom notification on the HUD
---@param type string Notification type (information, fail, money, warning)
---@param text string Notification text
---@param length number|nil Display duration in ms
---@param style string|nil Custom style
function ECO.Hud.notify(type, text, length, style)

    SendNUIMessage({
        type = type,
        text = text,
        length = length,
        style = style,
        subject = "NOTIFICATION"
    })
end

-- Global aliases for backward compatibility
setHud = ECO.Hud.update
sendHudLiveData = ECO.Hud.sendLiveData
sendHudActionData = ECO.Hud.sendActionData
DoCustomHudText = ECO.Hud.notify

-- ============================================================
-- EVENT HANDLERS
-- ============================================================

RegisterNetEvent('eco_cargo:showNotification', function(data)
    ECO.Hud.notify(data.type, data.text, data.length, data.style)
end)

RegisterNetEvent('eco_cargo:missionNotification', function(data)

    if ECO.PLAYER.job then

        if (data.defender and data.defender == ECO.PLAYER.job.name) or (data.owner and data.owner.identifier == ECO.PLAYER.identifier) then

            ECO.Hud.notify(data.type, data.text, data.length, data.style)

            if data.showChat then
                TriggerEvent("chat:addMessage", { args = { "^1[ECO CARGO]", data.text } })
            end

        elseif data.otherText then
            TriggerEvent("chat:addMessage", { args = { "^1[ECO CARGO]", data.otherText } })
        end
    end
end)
