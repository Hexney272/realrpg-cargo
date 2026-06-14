--[[
    RealRPG Cargo - Company System (Server-side)
    Manages trucking companies: CRUD, employees, vehicles, contracts, payments
    All monetary values in Ft (Forint)
    
    Money handling: Uses ESX xPlayer methods (compatible with both ESX Legacy and ox_inventory)
    - getMoney() / removeMoney() for cash
    - getAccount('bank') / removeAccountMoney('bank') for bank
]]

if not Config.company or not Config.company.enabled then return end

-- ============================================================
-- MONEY HELPERS (ESX compatible)
-- ============================================================

--- Get player's available money (cash + bank combined for company operations)
---@param xPlayer table ESX player object
---@return number Total available funds
local function getPlayerFunds(xPlayer)
    local cash = xPlayer.getMoney() or 0
    local bank = xPlayer.getAccount('bank')
    local bankMoney = bank and bank.money or 0
    return cash + bankMoney
end

--- Remove money from player (prefers bank, falls back to cash)
---@param xPlayer table ESX player object
---@param amount number Amount to remove
---@return boolean success
local function removePlayerMoney(xPlayer, amount)
    if not xPlayer or amount <= 0 then return false end

    local bank = xPlayer.getAccount('bank')
    local bankMoney = bank and bank.money or 0

    if bankMoney >= amount then
        xPlayer.removeAccountMoney('bank', amount)
        return true
    elseif xPlayer.getMoney() >= amount then
        xPlayer.removeMoney(amount)
        return true
    elseif (bankMoney + xPlayer.getMoney()) >= amount then
        -- Split between bank and cash
        local fromBank = bankMoney
        local fromCash = amount - fromBank
        xPlayer.removeAccountMoney('bank', fromBank)
        xPlayer.removeMoney(fromCash)
        return true
    end

    return false
end

--- Add money to player (to bank account)
---@param xPlayer table ESX player object
---@param amount number Amount to add
local function addPlayerMoney(xPlayer, amount)
    if not xPlayer or amount <= 0 then return end
    xPlayer.addAccountMoney('bank', amount)
end

-- ============================================================
-- HELPERS
-- ============================================================

local function hasPermission(role, permission)
    local roleConfig = Config.company.roles[role]
    if not roleConfig then return false end
    if roleConfig.permissions[1] == 'all' then return true end
    for _, perm in ipairs(roleConfig.permissions) do
        if perm == permission then return true end
    end
    return false
end

local function getCompanyLevel(company)
    if not company then return Config.company.levels[1] end
    local levels = Config.company.levels
    for i = #levels, 1, -1 do
        if (company.reputation or 0) >= levels[i].reputationNeeded and
           (company.total_deliveries or 0) >= levels[i].deliveriesNeeded then
            return levels[i]
        end
    end
    return levels[1]
end

local function addTransaction(companyId, txType, amount, description, relatedId)
    local success, err = pcall(function()
        local company = MySQL.query.await('SELECT `balance` FROM `realrpg_cargo_companies` WHERE `id` = ?', { companyId })
        local balanceAfter = (company and company[1]) and (company[1].balance + amount) or amount

        MySQL.update([[
            INSERT INTO `realrpg_cargo_transactions` (`company_id`, `type`, `amount`, `balance_after`, `description`, `related_identifier`)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], { companyId, txType, amount, balanceAfter, description or '', relatedId or '' })

        MySQL.update('UPDATE `realrpg_cargo_companies` SET `balance` = `balance` + ? WHERE `id` = ?', { amount, companyId })
    end)

    if not success then
        print('[RealRPG Cargo] Transaction error: ' .. tostring(err))
    end
end

-- ============================================================
-- COMPANY CRUD
-- ============================================================

--- Create a new company
lib.callback.register('realrpg_cargo:company:create', function(source, data)
    local success, result = pcall(function()
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return { success = false, message = 'Játékos nem található' } end

        local identifier = xPlayer.identifier
        local name = data and data.name or nil

        -- Validations
        if not name or #name < Config.company.nameMinLength or #name > Config.company.nameMaxLength then
            return { success = false, message = 'A cégnév hossza ' .. Config.company.nameMinLength .. '-' .. Config.company.nameMaxLength .. ' karakter között kell legyen' }
        end

        -- Check if player already owns a company
        local existing = MySQL.query.await('SELECT `id` FROM `realrpg_cargo_companies` WHERE `owner_identifier` = ?', { identifier })
        if existing and existing[1] then
            return { success = false, message = 'Már van egy vállalkozásod!' }
        end

        -- Check if player is already employed somewhere
        local employed = MySQL.query.await('SELECT `id` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
        if employed and employed[1] then
            return { success = false, message = 'Már dolgozol egy vállalkozásnál! Előbb lépj ki.' }
        end

        -- Check if name taken
        local nameTaken = MySQL.query.await('SELECT `id` FROM `realrpg_cargo_companies` WHERE `name` = ?', { name })
        if nameTaken and nameTaken[1] then
            return { success = false, message = 'Ez a cégnév már foglalt!' }
        end

        -- Check money (bank + cash combined)
        local funds = getPlayerFunds(xPlayer)
        if funds < Config.company.registrationFee then
            return { success = false, message = 'Nincs elég pénzed! Szükséges: ' .. Config.company.registrationFee .. ' Ft (neked van: ' .. funds .. ' Ft)' }
        end

        -- Deduct money and create
        local moneyRemoved = removePlayerMoney(xPlayer, Config.company.registrationFee)
        if not moneyRemoved then
            return { success = false, message = 'Pénz levonás sikertelen!' }
        end

        local insertId = MySQL.insert.await([[
            INSERT INTO `realrpg_cargo_companies` (`name`, `owner_identifier`, `description`)
            VALUES (?, ?, ?)
        ]], { name, identifier, (data and data.description) or '' })

        if not insertId then
            addPlayerMoney(xPlayer, Config.company.registrationFee)
            return { success = false, message = 'Adatbázis hiba! Pénz visszautalva.' }
        end

        -- Add owner as employee
        MySQL.insert.await([[
            INSERT INTO `realrpg_cargo_employees` (`company_id`, `identifier`, `role`, `salary`)
            VALUES (?, ?, 'owner', 0)
        ]], { insertId, identifier })

        -- Transaction record
        addTransaction(insertId, 'registration', -Config.company.registrationFee, 'Cégalapítási díj', identifier)

        return { success = true, message = 'Vállalkozás sikeresen létrehozva!', companyId = insertId }
    end)

    if not success then
        print('[RealRPG Cargo] Company create error: ' .. tostring(result))
        return { success = false, message = 'Szerver hiba! Ellenőrizd hogy a realrpg_cargo_company.sql importálva van-e.' }
    end

    return result
end)

--- Get player's company data (dashboard)
lib.callback.register('realrpg_cargo:company:get', function(source)
    local success, result = pcall(function()
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return nil end

        local identifier = xPlayer.identifier

        -- Find employee record
        local employee = MySQL.query.await([[
            SELECT e.*, c.*,
                e.id as employee_id, e.role as my_role, e.salary as my_salary,
                c.id as company_id, c.name as company_name
            FROM `realrpg_cargo_employees` e
            JOIN `realrpg_cargo_companies` c ON c.id = e.company_id
            WHERE e.identifier = ?
        ]], { identifier })

        if not employee or not employee[1] then return nil end

        local company = employee[1]
        local companyId = company.company_id
        local level = getCompanyLevel(company)

        -- Get employees
        local employees = MySQL.query.await([[
            SELECT e.*, u.firstname, u.lastname
            FROM `realrpg_cargo_employees` e
            LEFT JOIN `users` u ON u.identifier = e.identifier
            WHERE e.company_id = ?
            ORDER BY FIELD(e.role, 'owner', 'manager', 'dispatcher', 'driver')
        ]], { companyId })

        -- Get vehicles
        local vehicles = MySQL.query.await('SELECT * FROM `realrpg_cargo_vehicles` WHERE `company_id` = ?', { companyId })

        -- Get active contracts
        local contracts = MySQL.query.await([[
            SELECT * FROM `realrpg_cargo_contracts`
            WHERE `company_id` = ? AND `status` IN ('available', 'accepted', 'in_progress')
            ORDER BY `created_at` DESC
        ]], { companyId })

        -- Recent transactions
        local transactions = MySQL.query.await([[
            SELECT * FROM `realrpg_cargo_transactions`
            WHERE `company_id` = ?
            ORDER BY `created_at` DESC LIMIT 20
        ]], { companyId })

        return {
            company = {
                id = companyId,
                name = company.company_name,
                balance = company.balance,
                reputation = company.reputation,
                level = level,
                totalDeliveries = company.total_deliveries,
                totalDistance = company.total_distance,
                totalRevenue = company.total_revenue,
                taxPaid = company.tax_paid,
                description = company.description,
                foundedAt = company.founded_at,
            },
            myRole = company.my_role,
            mySalary = company.my_salary,
            employees = employees or {},
            vehicles = vehicles or {},
            contracts = contracts or {},
            transactions = transactions or {},
            config = {
                roles = Config.company.roles,
                vehiclesAvailable = Config.company.vehicles.available,
                levels = Config.company.levels,
            }
        }
    end)

    if not success then
        print('[RealRPG Cargo] Company get error: ' .. tostring(result))
        return nil
    end

    return result
end)

--- Delete / disband company
lib.callback.register('realrpg_cargo:company:disband', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { success = false } end

    local identifier = xPlayer.identifier

    local company = MySQL.query.await('SELECT `id`, `balance` FROM `realrpg_cargo_companies` WHERE `owner_identifier` = ?', { identifier })
    if not company or not company[1] then
        return { success = false, message = 'Nem vagy cégtulajdonos!' }
    end

    -- Pay out remaining balance to owner
    if company[1].balance > 0 then
        xPlayer.addMoney(company[1].balance)
    end

    -- Delete company (CASCADE deletes employees, vehicles, contracts, transactions, invites)
    MySQL.update('DELETE FROM `realrpg_cargo_companies` WHERE `id` = ?', { company[1].id })

    return { success = true, message = 'A vállalkozás megszüntetve. Egyenleg kifizetve: ' .. company[1].balance .. ' Ft' }
end)

-- ============================================================
-- EMPLOYEE MANAGEMENT
-- ============================================================

--- Invite a player to the company
lib.callback.register('realrpg_cargo:company:invite', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { success = false } end

    local identifier = xPlayer.identifier

    -- Check permission
    local emp = MySQL.query.await('SELECT `company_id`, `role` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
    if not emp or not emp[1] or not hasPermission(emp[1].role, 'hire') then
        return { success = false, message = 'Nincs jogosultságod meghívni!' }
    end

    local companyId = emp[1].company_id
    local targetId = data.targetIdentifier
    local role = data.role or 'driver'
    local salary = data.salary or Config.company.roles[role].defaultSalary

    -- Check if target already in a company
    local targetEmp = MySQL.query.await('SELECT `id` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { targetId })
    if targetEmp and targetEmp[1] then
        return { success = false, message = 'Ez a játékos már egy cégnél dolgozik!' }
    end

    -- Check max employees
    local level = getCompanyLevel(MySQL.query.await('SELECT * FROM `realrpg_cargo_companies` WHERE `id` = ?', { companyId })[1])
    local empCount = MySQL.query.await('SELECT COUNT(*) as cnt FROM `realrpg_cargo_employees` WHERE `company_id` = ?', { companyId })
    if empCount[1].cnt >= level.maxEmployees then
        return { success = false, message = 'Elérted a maximális alkalmazotti létszámot!' }
    end

    -- Create invite
    local expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (Config.company.invites.expiresInHours * 3600))

    MySQL.insert.await([[
        INSERT INTO `realrpg_cargo_invites` (`company_id`, `target_identifier`, `invited_by`, `role`, `salary`, `expires_at`)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { companyId, targetId, identifier, role, salary, expiresAt })

    -- Notify target player if online
    local targetSource = ESX.GetPlayerFromIdentifier(targetId)
    if targetSource then
        TriggerClientEvent('realrpg_cargo:companyInvite', targetSource.source, {
            companyId = companyId,
            role = role,
            salary = salary
        })
    end

    return { success = true, message = 'Meghívás elküldve!' }
end)

--- Accept an invite
lib.callback.register('realrpg_cargo:company:acceptInvite', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { success = false } end

    local identifier = xPlayer.identifier
    local inviteId = data.inviteId

    local invite = MySQL.query.await([[
        SELECT * FROM `realrpg_cargo_invites`
        WHERE `id` = ? AND `target_identifier` = ? AND `status` = 'pending'
    ]], { inviteId, identifier })

    if not invite or not invite[1] then
        return { success = false, message = 'Meghívás nem található vagy lejárt!' }
    end

    local inv = invite[1]

    -- Join company
    MySQL.insert.await([[
        INSERT INTO `realrpg_cargo_employees` (`company_id`, `identifier`, `role`, `salary`)
        VALUES (?, ?, ?, ?)
    ]], { inv.company_id, identifier, inv.role, inv.salary })

    -- Mark invite as accepted
    MySQL.update("UPDATE `realrpg_cargo_invites` SET `status` = 'accepted' WHERE `id` = ?", { inviteId })

    return { success = true, message = 'Csatlakoztál a vállalathoz!' }
end)

--- Fire an employee
lib.callback.register('realrpg_cargo:company:fire', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { success = false } end

    local identifier = xPlayer.identifier
    local targetId = data.targetIdentifier

    -- Check permission
    local emp = MySQL.query.await('SELECT `company_id`, `role` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
    if not emp or not emp[1] or not hasPermission(emp[1].role, 'fire') then
        return { success = false, message = 'Nincs jogosultságod elbocsátani!' }
    end

    -- Cannot fire owner
    local target = MySQL.query.await('SELECT `role` FROM `realrpg_cargo_employees` WHERE `company_id` = ? AND `identifier` = ?', { emp[1].company_id, targetId })
    if not target or not target[1] then
        return { success = false, message = 'A játékos nem dolgozik itt!' }
    end
    if target[1].role == 'owner' then
        return { success = false, message = 'A tulajdonost nem lehet elbocsátani!' }
    end

    MySQL.update('DELETE FROM `realrpg_cargo_employees` WHERE `company_id` = ? AND `identifier` = ?', { emp[1].company_id, targetId })

    -- Reputation penalty
    MySQL.update('UPDATE `realrpg_cargo_companies` SET `reputation` = GREATEST(0, `reputation` + ?) WHERE `id` = ?',
        { Config.company.reputation.penaltyFired, emp[1].company_id })

    return { success = true, message = 'Alkalmazott elbocsátva.' }
end)

--- Leave company (employee quits)
lib.callback.register('realrpg_cargo:company:leave', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { success = false } end

    local identifier = xPlayer.identifier

    local emp = MySQL.query.await('SELECT `company_id`, `role` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
    if not emp or not emp[1] then
        return { success = false, message = 'Nem vagy alkalmazásban!' }
    end
    if emp[1].role == 'owner' then
        return { success = false, message = 'Tulajdonosként nem léphetsz ki! Előbb oszlasd fel a céget.' }
    end

    MySQL.update('DELETE FROM `realrpg_cargo_employees` WHERE `company_id` = ? AND `identifier` = ?', { emp[1].company_id, identifier })

    return { success = true, message = 'Kiléptél a vállalatból.' }
end)

--- Update employee role/salary
lib.callback.register('realrpg_cargo:company:updateEmployee', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { success = false } end

    local identifier = xPlayer.identifier

    local emp = MySQL.query.await('SELECT `company_id`, `role` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
    if not emp or not emp[1] or not hasPermission(emp[1].role, 'hire') then
        return { success = false, message = 'Nincs jogosultságod!' }
    end

    local updates = {}
    local params = {}

    if data.role and data.role ~= 'owner' then
        updates[#updates + 1] = '`role` = ?'
        params[#params + 1] = data.role
    end
    if data.salary then
        updates[#updates + 1] = '`salary` = ?'
        params[#params + 1] = data.salary
    end

    if #updates == 0 then return { success = false, message = 'Nincs mit frissíteni' } end

    params[#params + 1] = emp[1].company_id
    params[#params + 1] = data.targetIdentifier

    MySQL.update('UPDATE `realrpg_cargo_employees` SET ' .. table.concat(updates, ', ') .. ' WHERE `company_id` = ? AND `identifier` = ?', params)

    return { success = true, message = 'Alkalmazott frissítve.' }
end)

-- ============================================================
-- VEHICLE MANAGEMENT
-- ============================================================

--- Purchase a vehicle for the company
lib.callback.register('realrpg_cargo:company:buyVehicle', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { success = false } end

    local identifier = xPlayer.identifier

    local emp = MySQL.query.await('SELECT `company_id`, `role` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
    if not emp or not emp[1] or not hasPermission(emp[1].role, 'manage_vehicles') then
        return { success = false, message = 'Nincs jogosultságod járművet vásárolni!' }
    end

    local companyId = emp[1].company_id
    local model = data.model

    -- Find vehicle in config
    local vehicleConfig = nil
    for _, v in ipairs(Config.company.vehicles.available) do
        if v.model == model then vehicleConfig = v break end
    end
    if not vehicleConfig then
        return { success = false, message = 'Ismeretlen jármű típus!' }
    end

    -- Check company balance
    local company = MySQL.query.await('SELECT `balance`, `reputation`, `total_deliveries` FROM `realrpg_cargo_companies` WHERE `id` = ?', { companyId })
    if not company or not company[1] or company[1].balance < vehicleConfig.price then
        return { success = false, message = 'Nincs elég pénz a céges kasszában! Szükséges: ' .. vehicleConfig.price .. ' Ft' }
    end

    -- Check max vehicles
    local level = getCompanyLevel(company[1])
    local vehCount = MySQL.query.await('SELECT COUNT(*) as cnt FROM `realrpg_cargo_vehicles` WHERE `company_id` = ?', { companyId })
    if vehCount[1].cnt >= level.maxVehicles then
        return { success = false, message = 'Elérted a maximális járműszámot (' .. level.maxVehicles .. ')!' }
    end

    -- Generate plate
    local plate = 'RC' .. math.random(100, 999) .. string.char(math.random(65, 90)) .. string.char(math.random(65, 90))

    -- Purchase
    MySQL.insert.await([[
        INSERT INTO `realrpg_cargo_vehicles` (`company_id`, `model`, `plate`, `display_name`, `purchase_price`)
        VALUES (?, ?, ?, ?, ?)
    ]], { companyId, model, plate, vehicleConfig.name, vehicleConfig.price })

    addTransaction(companyId, 'vehicle_purchase', -vehicleConfig.price, vehicleConfig.name .. ' vásárlás (' .. plate .. ')', identifier)

    return { success = true, message = vehicleConfig.name .. ' megvásárolva! Rendszám: ' .. plate }
end)

--- Sell a vehicle
lib.callback.register('realrpg_cargo:company:sellVehicle', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { success = false } end

    local identifier = xPlayer.identifier

    local emp = MySQL.query.await('SELECT `company_id`, `role` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
    if not emp or not emp[1] or not hasPermission(emp[1].role, 'manage_vehicles') then
        return { success = false, message = 'Nincs jogosultságod!' }
    end

    local vehicle = MySQL.query.await('SELECT * FROM `realrpg_cargo_vehicles` WHERE `id` = ? AND `company_id` = ?', { data.vehicleId, emp[1].company_id })
    if not vehicle or not vehicle[1] then
        return { success = false, message = 'Jármű nem található!' }
    end

    -- Sell at 60% of purchase price
    local sellPrice = math.floor(vehicle[1].purchase_price * 0.6)

    MySQL.update('DELETE FROM `realrpg_cargo_vehicles` WHERE `id` = ?', { data.vehicleId })
    addTransaction(emp[1].company_id, 'vehicle_purchase', sellPrice, vehicle[1].display_name .. ' eladás (' .. vehicle[1].plate .. ')', identifier)

    return { success = true, message = 'Jármű eladva! Bevétel: ' .. sellPrice .. ' Ft' }
end)

-- ============================================================
-- CONTRACT MANAGEMENT
-- ============================================================

--- Get available contracts for a company
lib.callback.register('realrpg_cargo:company:getContracts', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local identifier = xPlayer.identifier

    local emp = MySQL.query.await('SELECT `company_id` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
    if not emp or not emp[1] then return {} end

    local contracts = MySQL.query.await([[
        SELECT * FROM `realrpg_cargo_contracts`
        WHERE `company_id` = ?
        ORDER BY `status` ASC, `created_at` DESC
    ]], { emp[1].company_id })

    return contracts or {}
end)

--- Accept a contract
lib.callback.register('realrpg_cargo:company:acceptContract', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { success = false } end

    local identifier = xPlayer.identifier

    local emp = MySQL.query.await('SELECT `company_id`, `role` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
    if not emp or not emp[1] or not hasPermission(emp[1].role, 'accept_contracts') then
        return { success = false, message = 'Nincs jogosultságod szerződést elfogadni!' }
    end

    MySQL.update([[
        UPDATE `realrpg_cargo_contracts`
        SET `status` = 'accepted', `accepted_at` = NOW(), `assigned_driver` = ?
        WHERE `id` = ? AND `company_id` = ? AND `status` = 'available'
    ]], { data.driverIdentifier or identifier, data.contractId, emp[1].company_id })

    return { success = true, message = 'Szerződés elfogadva!' }
end)

-- ============================================================
-- PAYMENT INTEGRATION (Called from main cargo delivery)
-- ============================================================

--- Process company delivery payment
--- Called when a company employee delivers cargo
---@param identifier string Driver identifier
---@param deliveryData table {km, quality, freightFee, productId}
function ProcessCompanyDelivery(identifier, deliveryData)
    if not Config.company.enabled then return end

    local emp = MySQL.query.await([[
        SELECT e.company_id, e.role, e.salary, c.name as company_name
        FROM `realrpg_cargo_employees` e
        JOIN `realrpg_cargo_companies` c ON c.id = e.company_id
        WHERE e.identifier = ?
    ]], { identifier })

    if not emp or not emp[1] then return end -- Not in a company

    local companyId = emp[1].company_id
    local salary = emp[1].salary
    local fee = deliveryData.freightFee or 0

    -- Calculate company share
    local companyShare = math.floor(fee * Config.company.profit.companyShare)
    local taxAmount = math.floor(companyShare * Config.company.taxRate)
    local netCompanyIncome = companyShare - taxAmount

    -- Add to company balance
    addTransaction(companyId, 'delivery_income', netCompanyIncome, 'Szállítási bevétel (' .. (deliveryData.km or 0) .. ' km)', identifier)

    -- Tax
    if taxAmount > 0 then
        addTransaction(companyId, 'tax', -taxAmount, 'Adó (' .. math.floor(Config.company.taxRate * 100) .. '%)', identifier)
    end

    -- Salary bonus based on quality
    local qualityBonus = 0
    if (deliveryData.quality or 0) >= 95 then
        qualityBonus = math.floor(salary * (Config.company.salary.bonusMultiplier - 1))
    end

    -- Update employee stats
    MySQL.update([[
        UPDATE `realrpg_cargo_employees`
        SET `deliveries_done` = `deliveries_done` + 1,
            `distance_driven` = `distance_driven` + ?,
            `revenue_generated` = `revenue_generated` + ?,
            `bonus_earned` = `bonus_earned` + ?,
            `last_delivery` = NOW()
        WHERE `company_id` = ? AND `identifier` = ?
    ]], { deliveryData.km or 0, fee, qualityBonus, companyId, identifier })

    -- Update company stats
    MySQL.update([[
        UPDATE `realrpg_cargo_companies`
        SET `total_deliveries` = `total_deliveries` + 1,
            `total_distance` = `total_distance` + ?,
            `total_revenue` = `total_revenue` + ?,
            `tax_paid` = `tax_paid` + ?,
            `reputation` = `reputation` + ?,
            `last_activity` = NOW()
        WHERE `id` = ?
    ]], {
        deliveryData.km or 0,
        fee,
        taxAmount,
        Config.company.reputation.perDelivery,
        companyId
    })

    -- Pay salary from company balance if enough
    local totalPay = salary + qualityBonus
    if totalPay > 0 then
        local companyBalance = MySQL.query.await('SELECT `balance` FROM `realrpg_cargo_companies` WHERE `id` = ?', { companyId })
        if companyBalance and companyBalance[1] and companyBalance[1].balance >= totalPay then
            addTransaction(companyId, 'salary_payment', -totalPay, 'Fizetés: ' .. emp[1].company_name, identifier)
        end
    end

    return {
        companyShare = netCompanyIncome,
        tax = taxAmount,
        salary = salary,
        bonus = qualityBonus
    }
end

-- ============================================================
-- DEPOSIT / WITHDRAW
-- ============================================================

--- Deposit money into company
lib.callback.register('realrpg_cargo:company:deposit', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = 'Hiba' } end

    local identifier = xPlayer.identifier
    local amount = tonumber(data and data.amount) or 0

    if amount <= 0 then return { success = false, message = 'Érvénytelen összeg!' } end

    local emp = MySQL.query.await('SELECT `company_id`, `role` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
    if not emp or not emp[1] then return { success = false, message = 'Nem vagy cégnél!' } end

    local funds = getPlayerFunds(xPlayer)
    if funds < amount then
        return { success = false, message = 'Nincs elég pénzed! (Van: ' .. funds .. ' Ft)' }
    end

    local removed = removePlayerMoney(xPlayer, amount)
    if not removed then return { success = false, message = 'Pénz levonás sikertelen!' } end

    addTransaction(emp[1].company_id, 'deposit', amount, 'Befizetés', identifier)

    return { success = true, message = amount .. ' Ft befizetve a céges kasszába.' }
end)

--- Withdraw money from company
lib.callback.register('realrpg_cargo:company:withdraw', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = 'Hiba' } end

    local identifier = xPlayer.identifier
    local amount = tonumber(data and data.amount) or 0

    if amount <= 0 then return { success = false, message = 'Érvénytelen összeg!' } end

    local emp = MySQL.query.await('SELECT `company_id`, `role` FROM `realrpg_cargo_employees` WHERE `identifier` = ?', { identifier })
    if not emp or not emp[1] or not hasPermission(emp[1].role, 'view_finances') then
        return { success = false, message = 'Nincs jogosultságod!' }
    end

    local company = MySQL.query.await('SELECT `balance` FROM `realrpg_cargo_companies` WHERE `id` = ?', { emp[1].company_id })
    if not company or not company[1] or company[1].balance < amount then
        return { success = false, message = 'Nincs elég pénz a kasszában!' }
    end

    addTransaction(emp[1].company_id, 'withdrawal', -amount, 'Kivétel', identifier)
    addPlayerMoney(xPlayer, amount)

    return { success = true, message = amount .. ' Ft kivéve a kasszából.' }
end)

-- ============================================================
-- COMMANDS
-- ============================================================

RegisterCommand('company', function(source)
    TriggerClientEvent('realrpg_cargo:openCompany', source)
end, false)

RegisterCommand('ceginfo', function(source)
    TriggerClientEvent('realrpg_cargo:openCompany', source)
end, false)

-- ============================================================
-- PENDING INVITES (for players without company)
-- ============================================================

lib.callback.register('realrpg_cargo:company:getInvites', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local invites = MySQL.query.await([[
        SELECT i.*, c.name as company_name
        FROM `realrpg_cargo_invites` i
        JOIN `realrpg_cargo_companies` c ON c.id = i.company_id
        WHERE i.target_identifier = ? AND i.status = 'pending' AND i.expires_at > NOW()
    ]], { xPlayer.identifier })

    return invites or {}
end)
