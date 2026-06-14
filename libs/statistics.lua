--
-- Created by IntelliJ IDEA.
-- User: ekhion
-- Date: 2020. 12. 27.
-- Time: 13:57
--

RegisterCommand('cargostat', function()

    local result = lib.callback.await('realrpg_cargo:getStatistics', false)

    SetNuiFocus(true, true)

    SendNUIMessage({
        subject = 'STATISTICS',
        operation = 'open',
        data = result[1] and result[1] or {}
    })
end)

RegisterNUICallback('myStatistics', function(data, cb)

    ExecuteCommand('cargostat')
    cb('ok')
end)


RegisterNUICallback('getAllStatistics', function(data, cb)

    local result = lib.callback.await('realrpg_cargo:getAllStatistics', false, data)

    if result[1] then

        for i = 1, #result do

            result[i].rank = statAnalysis(Config.rank, result[i])
            result[i].title = statAnalysis(Config.title, result[i])
            result[i].titleLabel = _('title' .. result[i].title)
            result[i].rankLabel = _('rank' .. result[i].rank)
        end
    end

    cb(json.encode(result))
end)


function statAnalysis(reference, stat)

    local statValue

    if type(stat) ~= 'table' or next(stat) == nil then return 1 end

    for i = 1, #reference do

        for k, v in pairs(reference[i]) do

            statValue = tonumber(stat[k])

            if not statValue or statValue < v then

                return i == 1 and i or i - 1
            end
        end
    end

    return #reference
end


RegisterNUICallback('getRanks', function(data, cb)

    local rankLabels = {}
    local titleLabels = {}

    for i = 1, #Config.rank do rankLabels[i] = _U('rank' .. i) end
    for i = 1, #Config.title do titleLabels[i] = _('title' .. i) end

    cb(json.encode({
        ranks = Config.rank,
        rankLabels = rankLabels,
        titles = Config.title,
        titleLabels = titleLabels,
    }))
end)



