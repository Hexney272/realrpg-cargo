--[[
    RealRPG Cargo - Calculator Module
    Price calculation, payment logic, and parameter computation
    SIMPLE GLOBAL FUNCTIONS
]]

function calculatePrice(propertyNames, km, product)
    local defender = product.defender
    local value = product.value

    -- Defaults
    km = km or 1
    local kilometerFee = Config.kilometerFee or 2500
    local distanceMultiplier = Config.distanceMultiplier or 0.995
    local baseFee = Config.baseFee or 15000

    local freightFee = km * kilometerFee * (distanceMultiplier ^ km) + baseFee
    local maxPrice = freightFee * 2
    local illegalPrice = value

    -- Defender missions: HIGHEST PAY (4x multiplier on distance-based fee)
    if defender ~= '' then
        freightFee = freightFee * 4
        illegalPrice = value
    end

    if propertyNames and next(propertyNames) ~= nil then
        for i = 1, #propertyNames do
            local propertyName = propertyNames[i]
            if Config.propertyParams[propertyName] then
                local propertyParams = Config.propertyParams[propertyName]
                freightFee = freightFee + percentageValue((maxPrice - freightFee), propertyParams['priceMultiplier'])
                illegalPrice = illegalPrice + percentageValue(value, propertyParams['illegalPriceMultiplier'])
            end
        end
    end

    freightFee = math.round(freightFee)
    illegalPrice = math.round(illegalPrice)

    return {
        freightFee = freightFee,
        illegalPrice = illegalPrice,
    }
end

function payData(data)
    local result = {
        priceDeduction = 0,
        pricePayment = 0,
        cautionDeduction = 0,
        cautionPayment = 0,
        payable = 0,
        defenderSocietyPayable = 0,
        freightFee = data.freightFee
    }

    local tDamage = ((1000 - data.trailerHealth) * 0.001) ^ 2
    local gDamage = data.quality * 0.01

    if data.stolen then
        if data.product.defender ~= '' then
            data.illegalPrice = data.illegalPrice * Config.stolenMissionPaymentMultiplier
        end

        result.pricePayment = math.round(data.illegalPrice * gDamage)
        result.priceDeduction = data.illegalPrice - result.pricePayment
        result.payable = result.pricePayment
    else
        result.cautionPayment = math.round(data.cautionMoney * (1 - tDamage))
        result.cautionDeduction = data.cautionMoney - result.cautionPayment

        result.pricePayment = math.round(data.freightFee * gDamage)
        result.priceDeduction = data.freightFee - result.pricePayment

        if data.product.defender ~= '' then
            result.defenderSocietyPayable = math.round(result.pricePayment * (Config.defenderSocietyPaymentPercent * 0.01))
        end

        result.payable = result.pricePayment - result.defenderSocietyPayable + result.cautionPayment
    end

    return result
end

function calculateParams(propertyNames)
    local params = {
        rollMonitoringSpeed = 1000,
        overturn = 80,
        damageRoll = 80,
        collisionSensitivity = 1000,
        impactFlash = 1000,
        illegal = 0,
        marked_on_the_map = 0,
        extraStatDeliveryPoint = 0,
        extraStatQualityMultiplier = 1
    }

    if propertyNames and next(propertyNames) ~= nil then
        for i = 1, #propertyNames do
            local propertyName = propertyNames[i]
            if Config.propertyParams[propertyName] then
                local property = Config.propertyParams[propertyName]
                setProperty(property, params, 'rollMonitoringSpeed', 'min')
                setProperty(property, params, 'damageRoll', 'min')
                setProperty(property, params, 'overturn', 'min')
                setProperty(property, params, 'collisionSensitivity', 'min')
                setProperty(property, params, 'impactFlash', 'min')
                setProperty(property, params, 'illegal', 'max')
                setProperty(property, params, 'marked_on_the_map', 'max')
                setProperty(property, params, 'extraStatDeliveryPoint', 'max')
                setProperty(property, params, 'extraStatQualityMultiplier', 'max')
            end
        end
    end

    return json.encode(params)
end
