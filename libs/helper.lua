--[[
    ECO Cargo - Helper/Utility Module (Shared)
    Common utility functions used on both client and server
]]

ECO = ECO or {}
ECO.Utils = {}

-- ============================================================
-- TABLE UTILITIES
-- ============================================================

--- Count entries in an associative table
---@param tbl table
---@return number
function ECO.Utils.assocCount(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

--- Get keys of a table as an indexed array
---@param tbl table
---@return table
function ECO.Utils.arrayKeys(tbl)
    local keyset = {}
    local n = 0
    for k, _ in pairs(tbl) do
        n = n + 1
        keyset[n] = k
    end
    return keyset
end

--- Get elements in 'a' that are not in 'b'
---@param a table
---@param b table
---@return table
function ECO.Utils.arrayDiff(a, b)
    local ai = {}
    local diff = {}
    for _, v in pairs(a) do ai[v] = true end
    for _, v in pairs(b) do
        if ai[v] == nil then table.insert(diff, v) end
    end
    return diff
end

--- Check if element exists in table
---@param e any Element to search for
---@param t table Table to search in
---@return boolean
function ECO.Utils.inTable(e, t)
    for _, v in pairs(t) do
        if (v == e) then return true end
    end
    return false
end

--- Split string by separator
---@param str string
---@param sep string
---@return table
function ECO.Utils.explode(str, sep)
    local t = {}
    for k in str:gmatch("([^" .. sep .. "]+)") do t[#t + 1] = k end
    return t
end

--- Shallow copy of a table
---@param original table
---@return table
function ECO.Utils.shallowCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end
    return copy
end

--- Deep copy of a table (recursive)
--- Uses local self-reference to avoid dependency on ECO.Utils being defined
---@param orig any
---@return any
local function _deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[_deepCopy(orig_key)] = _deepCopy(orig_value)
        end
        setmetatable(copy, _deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end
ECO.Utils.deepCopy = _deepCopy

--- Get value from table with fallback
---@param tbl table|nil
---@param key any
---@param noValue any Fallback value
---@return any
function ECO.Utils.getValue(tbl, key, noValue)
    return tbl and tbl[key] or noValue
end

-- ============================================================
-- MATH UTILITIES
-- ============================================================

--- Round a number to specified decimal places
---@param num number
---@param numDecimalPlaces number|nil
---@return number
function math.round(num, numDecimalPlaces)
    if type(tonumber(num)) ~= 'number' then return 0 end
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

--- Calculate percentage value
---@param amount number Base amount
---@param percent number Percentage
---@return number
function ECO.Utils.percentageValue(amount, percent)
    local p = tonumber(percent)
    local a = tonumber(amount)
    if type(p) ~= 'number' or p < 1 then return 0 end
    if type(a) ~= 'number' or a < 1 then return 0 end
    return (p / 100) * a
end

--- Get max of two values (nil-safe)
function ECO.Utils.max(a, b)
    a = tonumber(a)
    b = tonumber(b)
    if not a then return b end
    if not b then return a end
    return (math.max(a, b))
end

--- Get min of two values (nil-safe)
function ECO.Utils.min(a, b)
    a = tonumber(a)
    b = tonumber(b)
    if not a then return 0 end
    if not b then return 0 end
    return (math.min(a, b))
end

-- ============================================================
-- CONVERSION UTILITIES
-- ============================================================

--- Convert m/s speed to km/h
---@param speed number Speed in m/s
---@return number Speed in km/h
function ECO.Utils.transformToKm(speed)
    return math.floor(speed * 3.6 + 0.5)
end

--- Convert km/h to m/s
function ECO.Utils.kmhToMps(kmh)
    return kmh * (1/3.6)
end

--- Convert m/s to km/h
function ECO.Utils.mpsToKmh(mps)
    return mps * 3.6
end

--- Convert m/s to mph
function ECO.Utils.mpsToMph(mps)
    return ECO.Utils.mpsToKmh(mps) * (1/1.609)
end

-- ============================================================
-- STRING/ID UTILITIES
-- ============================================================

--- Safe plate text (remove non-alphanumeric characters)
---@param plate string|nil
---@return string
function ECO.Utils.safePlate(plate)
    if type(plate) == 'string' and plate ~= "" then
        return plate:gsub('[^A-z%d]', '')
    end
    return ''
end

--- Concatenate two IDs with optional separator
---@param id1 number
---@param id2 number
---@param separator string|nil
---@param short boolean|nil If true, always put smaller ID first
---@return string
function ECO.Utils.concatId(id1, id2, separator, short)
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

--- Convert SQL timestamp to formatted date
---@param sqlTime number|string
---@param format string|nil
---@return string
function ECO.Utils.sqlTime2date(sqlTime, format)
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

--- Calculate remaining time for product availability
---@param lastStartTime number|nil
---@param reproductionTime number|nil
---@param serverTimeStamp number
---@return number Remaining seconds (0 if available)
function ECO.Utils.remainingTime(lastStartTime, reproductionTime, serverTimeStamp)
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

--- Format elapsed time for display
---@param elapsedTime number Time in seconds
---@return number, string Value and unit label key
function ECO.Utils.displayTime(elapsedTime)
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

--- Set a property value using min/max comparison
---@param property table Source property table
---@param params table Target params table
---@param key string Property key
---@param minMax string 'min' or 'max'
function ECO.Utils.setProperty(property, params, key, minMax)
    if type(property[key]) == 'number' and property[key] > 0 then
        if minMax == 'min' then
            params[key] = ECO.Utils.min(property[key], params[key])
        else
            params[key] = ECO.Utils.max(property[key], params[key])
        end
    end
end

-- ============================================================
-- TABLE EXTENSIONS
-- ============================================================

--- Refresh table t1 with values from t2
table.refresh = function(t1, t2)
    if type(t1) ~= 'table' or type(t2) ~= 'table' or next(t2) == nil then
        return
    end
    for k, v in pairs(t2) do
        t1[k] = v
    end
end

-- ============================================================
-- CLIENT-ONLY UTILITIES (guarded by native existence check)
-- ============================================================

--- Get vehicle entity from plate text
---@param plate string
---@return table|nil {coords, vehicle} or nil
function ECO.Utils.getVehicleFromPlate(plate)

    if not ESX or not ESX.Game or not ESX.Game.GetVehicles then return nil end

    local allVehicles = ESX.Game.GetVehicles()
    local vPlate

    plate = ECO.Utils.safePlate(plate)

    if type(allVehicles) == 'table' and next(allVehicles) then
        for i = 1, #allVehicles do
            vPlate = ECO.Utils.safePlate(GetVehicleNumberPlateText(allVehicles[i]))
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

--- Create a blip on the map
---@param coords vector3
---@param sprite number
---@param color number
---@param blipname string
---@return number Blip handle
function ECO.Utils.createBlip(coords, sprite, color, blipname)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipname)
    EndTextCommandSetBlipName(blip)
    return blip
end

--- Count players with a specific job (client-only)
---@param job string Job name
---@return number
function ECO.Utils.countPlayers(job)
    if next(ECO.PLAYERS) == nil then return 0 end

    local count = 0
    for serverId, playerJob in pairs(ECO.PLAYERS) do
        if playerJob == job and serverId ~= ECO.PLAYER.serverId then
            count = count + 1
        end
    end
    return count
end

--- Get product IDs available at a zone
---@param zoneId number
---@return table
function ECO.Utils.getZoneProductsIds(zoneId)
    local productIds = {}
    for k, v in pairs(ECO.allProducts) do
        if v.loading[zoneId] then
            productIds[k] = true
        end
    end
    return productIds
end

--- Display subtitle message
function ECO.Utils.msginf(msg, duree)
    duree = duree or 500
    ClearPrints()
    SetTextEntry_2("STRING")
    AddTextComponentString(msg)
    DrawSubtitleTimed(duree, 1)
end

-- ============================================================
-- GLOBAL ALIASES (backward compatibility)
-- ============================================================

assocCount = ECO.Utils.assocCount
array_keys = ECO.Utils.arrayKeys
array_diff = ECO.Utils.arrayDiff
in_table = ECO.Utils.inTable
explode = ECO.Utils.explode
shallowCopy = ECO.Utils.shallowCopy
deepCopy = ECO.Utils.deepCopy
getValue = ECO.Utils.getValue
percentageValue = ECO.Utils.percentageValue
max = ECO.Utils.max
min = ECO.Utils.min
transformToKm = ECO.Utils.transformToKm
KmhToMps = ECO.Utils.kmhToMps
MpsToKmh = ECO.Utils.mpsToKmh
MpsToMph = ECO.Utils.mpsToMph
safePlate = ECO.Utils.safePlate
concatId = ECO.Utils.concatId
sqlTime2date = ECO.Utils.sqlTime2date
remainingTime = ECO.Utils.remainingTime
displayTime = ECO.Utils.displayTime
setProperty = ECO.Utils.setProperty
getVehicleFromPlate = ECO.Utils.getVehicleFromPlate
createBlip = ECO.Utils.createBlip
countPlayers = ECO.Utils.countPlayers
getZoneProductsIds = ECO.Utils.getZoneProductsIds
msginf = ECO.Utils.msginf
