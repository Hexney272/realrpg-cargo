--[[
    ECO Cargo - Achievement System (Server-side)
    Checks and awards achievements based on player statistics
]]

ECO = ECO or {}
ECO.Achievements = {}

--- Check and award new achievements for a player
--- Called after successful delivery or stat update
---@param identifier string Player identifier
---@param source number Player server ID
function ECO.Achievements.check(identifier, source)
    if not Config.achievements or #Config.achievements == 0 then return end

    -- Fetch current stats
    local stats = MySQL.query.await([[
        SELECT *,
        `started_mission` + `started_delivery` as `all_started`,
        `done_mission` + `done_delivery` as `all_done`,
        `stolen_mission` + `stolen_delivery` as `all_stolen`
        FROM `eco_cargo_stats`
        WHERE `identifier` = @identifier
    ]], { ['@identifier'] = identifier })

    if not stats or not stats[1] then return end

    local playerStats = stats[1]
    local currentAchievements = {}

    -- Parse existing achievements from DB
    if playerStats.achievement and playerStats.achievement ~= '' then
        local parsed = json.decode(playerStats.achievement)
        if parsed then
            currentAchievements = parsed
        end
    end

    -- Check each achievement
    local newAchievements = {}
    local hasNew = false

    for _, achievement in ipairs(Config.achievements) do
        -- Skip already earned
        if not currentAchievements[achievement.id] then
            -- Check condition
            local success, result = pcall(achievement.condition, playerStats)

            if success and result then
                -- Achievement earned!
                currentAchievements[achievement.id] = os.time()
                newAchievements[#newAchievements + 1] = achievement
                hasNew = true
            end
        end
    end

    -- Save to DB if new achievements earned
    if hasNew then
        local achievementJson = json.encode(currentAchievements)

        MySQL.update([[
            UPDATE `eco_cargo_stats`
            SET `achievement` = @achievement
            WHERE `identifier` = @identifier
        ]], {
            ['@achievement'] = achievementJson,
            ['@identifier'] = identifier
        })

        -- Notify player of each new achievement
        for _, achievement in ipairs(newAchievements) do
            TriggerClientEvent('eco_cargo:achievementUnlocked', source, {
                id = achievement.id,
                name = achievement.name,
                description = achievement.description,
                icon = achievement.icon
            })
        end

        -- Discord notification for achievements
        if #newAchievements > 0 then
            local xPlayer = ESX.GetPlayerFromId(source)
            local playerName = xPlayer and (xPlayer.getName and xPlayer.getName()) or identifier

            for _, achievement in ipairs(newAchievements) do
                ECO.Discord.send('cargoDelivered', {
                    title = 'Achievement Unlocked!',
                    description = playerName .. ' earned a new achievement.',
                    color = 16766720, -- Gold
                    fields = {
                        { name = 'Achievement', value = achievement.name, inline = true },
                        { name = 'Player', value = playerName, inline = true },
                    }
                })
            end
        end
    end
end

--- Get all achievements for a player (for display)
---@param identifier string Player identifier
---@return table {earned: table, available: table}
function ECO.Achievements.getAll(identifier)
    local stats = MySQL.query.await([[
        SELECT `achievement` FROM `eco_cargo_stats`
        WHERE `identifier` = @identifier
    ]], { ['@identifier'] = identifier })

    local earned = {}

    if stats and stats[1] and stats[1].achievement and stats[1].achievement ~= '' then
        local parsed = json.decode(stats[1].achievement)
        if parsed then earned = parsed end
    end

    local result = {}

    for _, achievement in ipairs(Config.achievements) do
        result[#result + 1] = {
            id = achievement.id,
            name = achievement.name,
            description = achievement.description,
            icon = achievement.icon,
            earned = earned[achievement.id] ~= nil,
            earnedAt = earned[achievement.id]
        }
    end

    return result
end
