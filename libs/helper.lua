--[[
    RealRPG Cargo - Helper/Utility Module (Shared)
    SIMPLE GLOBAL FUNCTIONS - compatible with all FiveM environments
]]

-- ============================================================
-- TABLE UTILITIES
-- ============================================================

function assocCount(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

function array_keys(tbl)
    local keyset = {}
    local n = 0
    for k, _ in pairs(tbl) do
        n = n + 1
        keyset[n] = k
    end
    return keyset
end

function array_diff(a, b)
    local ai = {}
    local diff = {}
    for _, v in pairs(a) do ai[v] = true end
    for _, v in pairs(b) do
        if ai[v] == nil then table.insert(diff, v) end
    end
    return diff
end

function in_table(e, t)
    for _, v in pairs(t) do
        if (v == e) then return true end
    end
    return false
end

function explode(str, sep)
    local t = {}
    for k in str:gmatch("([^" .. sep .. "]+)") do t[#t + 1] = k end
    return t
end

-- ============================================================
-- COPY UTILITIES
-- ============================================================

function shallowCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end
    return copy
end

function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function getValue(tbl, key, noValue)
    return tbl and tbl[key] or noValue
end

-- ============================================================
-- MATH UTILITIES
-- ============================================================

function math.round(num, numDecimalPlaces)
    if type(tonumber(num)) ~= 'number' then return 0 end
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function percentageValue(amount, percent)
    local p = tonumber(percent)
    local a = tonumber(amount)
    if type(p) ~= 'number' or p < 1 then return 0 end
    if type(a) ~= 'number' or a < 1 then return 0 end
    return (p / 100) * a
end

function max(a, b)
    a = tonumber(a)
    b = tonumber(b)
    if not a then return b end
    if not b then return a end
    return (math.max(a, b))
end

function min(a, b)
    a = tonumber(a)
    b = tonumber(b)
    if not a then return 0 end
    if not b then return 0 end
    return (math.min(a, b))
end

-- ============================================================
-- CONVERSION UTILITIES
-- ============================================================

function transformToKm(speed)
    return math.floor(speed * 3.6 + 0.5)
end

function KmhToMps(kmh)
    return kmh * (1/3.6)
end

function MpsToKmh(mps)
    return mps * 3.6
end

function MpsToMph(mps)
    return MpsToKmh(mps) * (1/1.609)
end

-- ============================================================
-- STRING/ID UTILITIES
-- ============================================================

function safePlate(plate)
    if type(plate) == 'string' and plate ~= "" then
        return plate:gsub('[^A-z%d]', '')
    end
    return ''
end

function concatId(id1, id2, separator, short)
    id1 = tonumber(id1)
    id2 = tonumber(id2)
    separator = separator or ''
    if short then
        if id1 > id2 then
            return id2 .. separator .. id1
        end
    end
    return id1 .. separator .. id2
end

function sqlTime2date(sqlTime, format)
    if not format or format == '' then
        format = '%Y-%m-%d'
    end
    sqlTime = tonumber(sqlTime) and tonumber(sqlTime) or 0
    local unixTimeStamp = sqlTime * 0.001
    return os.date(format, unixTimeStamp)
end

-- ============================================================
-- TIME UTILITIES
-- ============================================================

function remainingTime(lastStartTime, reproductionTime, serverTimeStamp)
    if (type(lastStartTime) == 'number' and lastStartTime ~= 0) and
            (type(reproductionTime) == 'number' and reproductionTime ~= 0) then
        local startTime = lastStartTime + reproductionTime * 60
        if startTime > serverTimeStamp then
            return startTime - serverTimeStamp
        else
            return 0
        end
    else
        return 0
    end
end

function displayTime(elapsedTime)
    if elapsedTime < 60 then return elapsedTime, 'sec' end

    local hours = math.floor(elapsedTime / 3600)
    local minutes = math.floor((math.fmod(elapsedTime, 3600) / 3600) * 10) / 10

    if hours < 1 then
        minutes = math.floor(math.fmod(elapsedTime, 3600) / 60)
        return minutes, 'minute'
    end

    return hours + minutes, 'hour'
end

-- ============================================================
-- PROPERTY UTILITIES
-- ============================================================

function setProperty(property, params, key, minMax)
    if type(property[key]) == 'number' and property[key] > 0 then
        if minMax == 'min' then
            params[key] = min(property[key], params[key])
        else
            params[key] = max(property[key], params[key])
        end
    end
end

-- ============================================================
-- TABLE EXTENSIONS
-- ============================================================

table.refresh = function(t1, t2)
    if type(t1) ~= 'table' or type(t2) ~= 'table' or next(t2) == nil then
        return
    end
    for k, v in pairs(t2) do
        t1[k] = v
    end
end

-- ============================================================
-- CLIENT-ONLY UTILITIES
-- ============================================================

function getVehicleFromPlate(plate)
    if not ESX or not ESX.Game or not ESX.Game.GetVehicles then return nil end

    local allVehicles = ESX.Game.GetVehicles()
    local vPlate

    plate = safePlate(plate)

    if type(allVehicles) == 'table' and next(allVehicles) then
        for i = 1, #allVehicles do
            vPlate = safePlate(GetVehicleNumberPlateText(allVehicles[i]))
            if vPlate == plate then
                return {
                    coords = GetEntityCoords(allVehicles[i]),
                    vehicle = allVehicles[i]
                }
            end
        end
    end

    return nil
end

function createBlip(coords, sprite, color, blipname)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipname)
    EndTextCommandSetBlipName(blip)
    return blip
end

function countPlayers(job)
    if next(ECO.PLAYERS) == nil then return 0 end
    local count = 0
    for serverId, playerJob in pairs(ECO.PLAYERS) do
        if playerJob == job and serverId ~= ECO.PLAYER.serverId then
            count = count + 1
        end
    end
    return count
end

function getZoneProductsIds(zoneId)
    local productIds = {}
    for k, v in pairs(ECO.allProducts) do
        if v.loading[zoneId] then
            productIds[k] = true
        end
    end
    return productIds
end

function msginf(msg, duree)
    duree = duree or 500
    ClearPrints()
    SetTextEntry_2("STRING")
    AddTextComponentString(msg)
    DrawSubtitleTimed(duree, 1)
end
