--[[
    ECO Cargo - Discord Webhook Integration
    Sends embed notifications to Discord for cargo events
]]

ECO = ECO or {}
ECO.Discord = {}

--- Send a Discord webhook message
---@param eventType string Event type key from Config.discord.events
---@param embed table Discord embed object
function ECO.Discord.send(eventType, embed)
    if not Config.discord.enabled then return end
    if not Config.discord.webhookUrl or Config.discord.webhookUrl == '' then return end
    if not Config.discord.events[eventType] then return end

    embed.color = embed.color or Config.discord.colors[eventType] or 3447003
    embed.timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')

    if not embed.footer then
        embed.footer = { text = 'ECO Cargo System' }
    end

    local payload = json.encode({
        username = Config.discord.botName or 'ECO Cargo',
        avatar_url = Config.discord.botAvatar or nil,
        embeds = { embed }
    })

    PerformHttpRequest(Config.discord.webhookUrl, function(statusCode, response, headers)
        if statusCode ~= 200 and statusCode ~= 204 then
            print(('[ECO CARGO] Discord webhook error: %s (status: %d)'):format(response or 'unknown', statusCode))
        end
    end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

--- Notify: Mission registered (protection requested)
---@param data table {owner, defender, missionId, productId, loadingZoneId}
function ECO.Discord.missionRegistered(data)
    ECO.Discord.send('missionRegistered', {
        title = 'Mission Registered',
        description = 'A high-value cargo mission has been registered. Protection requested.',
        fields = {
            { name = 'Owner', value = data.owner.characterName or 'Unknown', inline = true },
            { name = 'Defender Faction', value = data.defender or 'N/A', inline = true },
            { name = 'Mission ID', value = data.missionId or 'N/A', inline = true },
        }
    })
end

--- Notify: Cargo delivery started
---@param data table {owner, productId, trailerPlate, destinationZoneId, km}
function ECO.Discord.cargoStarted(data)
    local productName = 'Unknown'
    if ECO.PRODUCTS and ECO.PRODUCTS[tonumber(data.productId)] then
        productName = ECO.PRODUCTS[tonumber(data.productId)].name or 'Unknown'
    end

    ECO.Discord.send('cargoStarted', {
        title = 'Cargo Delivery Started',
        description = 'A new cargo delivery has been dispatched.',
        fields = {
            { name = 'Driver', value = data.owner.characterName or 'Unknown', inline = true },
            { name = 'Product', value = productName, inline = true },
            { name = 'Distance', value = (data.km or 0) .. ' km', inline = true },
            { name = 'Trailer Plate', value = data.trailerPlate or 'N/A', inline = true },
        }
    })
end

--- Notify: Cargo delivered successfully
---@param data table {owner, productId, trailerPlate, km, quality, payable}
function ECO.Discord.cargoDelivered(data)
    local productName = 'Unknown'
    if ECO.PRODUCTS and ECO.PRODUCTS[tonumber(data.productId)] then
        productName = ECO.PRODUCTS[tonumber(data.productId)].name or 'Unknown'
    end

    ECO.Discord.send('cargoDelivered', {
        title = 'Cargo Delivered',
        description = 'A cargo delivery has been completed successfully.',
        fields = {
            { name = 'Driver', value = data.driverName or 'Unknown', inline = true },
            { name = 'Product', value = productName, inline = true },
            { name = 'Distance', value = (data.km or 0) .. ' km', inline = true },
            { name = 'Quality', value = math.round(data.quality or 0) .. '%', inline = true },
            { name = 'Payment', value = '$' .. math.round(data.payable or 0), inline = true },
        }
    })
end

--- Notify: Cargo stolen
---@param data table {thiefName, ownerName, productId, trailerPlate}
function ECO.Discord.cargoStolen(data)
    local productName = 'Unknown'
    if ECO.PRODUCTS and ECO.PRODUCTS[tonumber(data.productId)] then
        productName = ECO.PRODUCTS[tonumber(data.productId)].name or 'Unknown'
    end

    ECO.Discord.send('cargoStolen', {
        title = 'Cargo Stolen!',
        description = 'A cargo shipment has been stolen by another player.',
        fields = {
            { name = 'Thief', value = data.thiefName or 'Unknown', inline = true },
            { name = 'Original Owner', value = data.ownerName or 'Unknown', inline = true },
            { name = 'Product', value = productName, inline = true },
            { name = 'Trailer Plate', value = data.trailerPlate or 'N/A', inline = true },
        }
    })
end

--- Notify: Cargo/trailer destroyed
---@param data table {driverName, productId, trailerPlate}
function ECO.Discord.cargoDestroyed(data)
    local productName = 'Unknown'
    if ECO.PRODUCTS and ECO.PRODUCTS[tonumber(data.productId)] then
        productName = ECO.PRODUCTS[tonumber(data.productId)].name or 'Unknown'
    end

    ECO.Discord.send('cargoDestroyed', {
        title = 'Cargo Destroyed!',
        description = 'A cargo shipment has been destroyed.',
        fields = {
            { name = 'Driver', value = data.driverName or 'Unknown', inline = true },
            { name = 'Product', value = productName, inline = true },
            { name = 'Trailer Plate', value = data.trailerPlate or 'N/A', inline = true },
        }
    })
end
