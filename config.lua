Config = {}
Config.Locale = 'hu'

-- ============================================================
-- DISCORD WEBHOOK
-- ============================================================
Config.discord = {
    enabled = true,
    webhookUrl = '', -- Paste your Discord webhook URL here
    botName = 'RealRPG Cargo',
    botAvatar = '', -- Optional: bot avatar URL

    -- Which events to log
    events = {
        missionRegistered = true,   -- Mission protection requested
        cargoStarted = true,        -- Cargo delivery started
        cargoDelivered = true,      -- Cargo delivered successfully
        cargoStolen = true,         -- Cargo was stolen
        cargoDestroyed = true,      -- Cargo/trailer destroyed
    },

    -- Embed colors (decimal)
    colors = {
        missionRegistered = 16744192,   -- Orange
        cargoStarted = 3066993,         -- Green
        cargoDelivered = 3447003,       -- Dark Green
        cargoStolen = 15158332,         -- Red
        cargoDestroyed = 10038562,      -- Dark Red
    }
}

-- ============================================================
-- GENERAL SETTINGS
-- ============================================================

-- MULTI CHARACTER
-- If true then wait for 'esx:kashloaded' trigger! -- README.MD
Config.kashacters = false

-- a member of a defensive faction is prohibited from launching a mission he defends
Config.disableMissionStartForDefenders = true

-- Included teb_speed_controll: RP Friendly Cruise Control/Speed Limiter (https://github.com/hojgr/teb_speed_control)
Config.enableSpeedControl = false

Config.illegalFactions = {
    'vagos',
    'ballas',
    'crips',
    'bloods',
    'family',
    'yakuza',
    'lostmc',
    'cayoperico',
    'cardem',
    'unemployed',
    'triad',
    'notfound',
    'camorra',
    '313',
    'peaky',
    'glockboyz',
    'streetgods',
    'cosanostra',
    'lafamily',
    'calicartel',
    'alsalam',
    'bratstvo',
    'ms12',
    'rocky',
    'blackkings',
    'goonsquad',
    'carteldesinaloa',
    'crimson',
    'families',
    'doolies',
}

Config.lawEnforcementFactions = {
    'police',
    'sheriff',
    'nexa',
    'lspd',
    'sahp'
}

-- ============================================================
-- FACTION ROLES (Multiple attacker & defender groups)
-- ============================================================
-- Defenders: factions that can protect high-value shipments
-- Attackers: factions that can steal/intercept shipments
-- These lists are used by the mission system to determine:
--   1. Who gets notified when a mission is registered
--   2. Who counts as "counter" players for mission balance
-- You can add as many factions as you want to each list.

Config.defenderFactions = {
    'police',
    'sheriff',
    'nexa',
    'lspd',
    'sahp',
}

Config.attackerFactions = {
    'vagos',
    'ballas',
    'crips',
    'bloods',
    'family',
    'yakuza',
    'lostmc',
    'cayoperico',
    'cardem',
    'triad',
    'camorra',
    'cosanostra',
    'lafamily',
    'calicartel',
    'alsalam',
    'bratstvo',
    'ms12',
    'blackkings',
    'goonsquad',
    'carteldesinaloa',
    'crimson',
    'families',
}

-- TACHOGRAF
Config.speedLimit = {
    country = 90,
    city = 60
}

-- MONEY TYPE FOR STOLEN CARGO
Config.stolenCargoPaymentType = 'black_money' -- OPTIONS: 'money', 'black_money', 'bank'; DEFAULT: 'black_money',
Config.stolenMissionPaymentMultiplier = 2

-- Delay time between the start of two transports (the cp disappears)
Config.cargoRequestDelay = 1 -- DEFAULT: 1, in minute

Config.kilometerFee = 2500 -- Kilométerenkénti díj (Ft) - reális fuvarozási km díj

Config.distanceMultiplier = 0.995 -- Távolság szorzó (1 alatt enyhén csökkenti a km díjat nagy távolságon)

Config.baseFee = 15000 -- Kiállási alapdíj (Ft) - minden fuvarért jár alap

-- FONTOS: A kaució (caution_money) és az áru értéke (value) a realrpg_cargo_products
-- SQL táblában van beállítva termékenként. Ha Ft-ra váltottál, frissítsd ezeket is!
-- Példa: UPDATE realrpg_cargo_products SET caution_money = caution_money * 300, value = value * 300;

Config.countingZoneRadius = 40 -- DEFAULT: 40 -- Defenders must be within that range

-- SAFETY REGULATIONS
Config.propertyParams = {
    -- Magas értékű
    high_value = {
        rollMonitoringSpeed = 0, -- DEFAULT 50 KM/H (activating damageRoll monitor)
        overturn = 0, -- over max roll = Goods destroyed, DEFAULT 40
        damageRoll = 0, -- DEFAULT 6 -- Over value damaged the goods
        collisionSensitivity = 0, -- 0 = INSENSITIVE, DEFAULT 60 (FULL GOODS DESTROY COLLISION SPEED IN KM/H)
        priceMultiplier = 40, -- 40% -- increase basic freightFee (kilometerFee * distanceMultiplier + baseFee)
        illegalPriceMultiplier = 0 -- 0% -- increase illegalBasePrice for database(value)
    },

    -- Robbanásveszélyes
    explosive = {
        rollMonitoringSpeed = 45,
        overturn = 30,
        damageRoll = 6,
        collisionSensitivity = 40,
        priceMultiplier = 40, -- %
        illegalPriceMultiplier = 0,
        impactFlash = 50 --km/h
    },

    -- Törékeny
    fragile = {
        rollMonitoringSpeed = 45,
        overturn = 40,
        damageRoll = 6,
        collisionSensitivity = 60,
        priceMultiplier = 40,
        illegalPriceMultiplier = 0,
    },

    -- Tűzveszélyes
    flammable = {
        rollMonitoringSpeed = 0,
        overturn = 0,
        damageRoll = 0,
        collisionSensitivity = 0,
        priceMultiplier = 40,
        illegalPriceMultiplier = 0,
        impactFlash = 50 --km/h
    },

    -- Mérgező
    toxic = {
        rollMonitoringSpeed = 0,
        overturn = 0,
        damageRoll = 0,
        collisionSensitivity = 0,
        priceMultiplier = 40,
        illegalPriceMultiplier = 0
    },

    -- Maró
    corrodent = {
        rollMonitoringSpeed = 0,
        damageRoll = 0,
        collisionSensitivity = 0,
        overturn = 0,
        priceMultiplier = 40,
        illegalPriceMultiplier = 0
    },

    -- Túlsúlyos
    heavy = {
        rollMonitoringSpeed = 0,
        damageRoll = 0,
        collisionSensitivity = 0,
        overturn = 0,
        priceMultiplier = 40,
        illegalPriceMultiplier = 0,
    },

    -- Hűtött
    refrigerate = {
        rollMonitoringSpeed = 0,
        overturn = 0,
        damageRoll = 0,
        collisionSensitivity = 0,
        illegalPriceMultiplier = 0
    },

    -- Szennyező
    pollutant = {
        rollMonitoringSpeed = 0,
        overturn = 0,
        damageRoll = 0,
        collisionSensitivity = 0,
        priceMultiplier = 40, -- %
        illegalPriceMultiplier = 0
    },
    -- illegal
    illegal = {
        illegal = 1
    },
    -- trailer signal
    marked_on_the_map = {
        marked_on_the_map = 1
    },

    -- possible improving statistics
    high_sensitivity = {
        rollMonitoringSpeed = 35,
        overturn = 40,
        damageRoll = 4,
        collisionSensitivity = 40,
        extraStatDeliveryPoint = 1, -- incrase mission and normal delivery (improving statistics)
        extraStatQualityMultiplier = 2, -- cargo quality Multiplier (improving statistics)
        impactFlash = 40 --km/h
    },
}

-- RANK CONDITIONS
Config.rank = {
    { vulnerable = 0, all_done = 0, quality_rate = 0, success_rate = 0 },       -- iron
    { vulnerable = 5, all_done = 50, quality_rate = 90, success_rate = 90 },    -- bronze
    { vulnerable = 30, all_done = 150, quality_rate = 95, success_rate = 95 },  -- silver
    { vulnerable = 90, all_done = 400, quality_rate = 97, success_rate = 97 },  -- gold
    { vulnerable = 150, all_done = 800, quality_rate = 99, success_rate = 99 }, -- platinum
}

-- TITLE CONDITIONS
Config.title = {
    { distance = 0, rank = 1 },     -- Newbie,
    { distance = 300, rank = 2 },   -- Enthusiast,
    { distance = 1000, rank = 3 },  -- Skilled Worker,
    { distance = 2500, rank = 3 },  -- Professional,
    { distance = 4000, rank = 3 },  -- Master,
    { distance = 5500, rank = 3 },  -- Instructor,
    { distance = 7500, rank = 4 },  -- Elite,
    { distance = 10000, rank = 4 }, -- King of the Road,
    { distance = 12000, rank = 4 }, -- Legend,
    { distance = 14500, rank = 5 }, -- Divine Champion,
}

-- ============================================================
-- ACHIEVEMENTS
-- ============================================================
-- Each achievement has:
--   id: unique identifier (stored in DB)
--   name: locale key for display name
--   description: locale key for description
--   icon: material icon name
--   condition: function(stats) that returns true when achieved
Config.achievements = {
    {
        id = 'first_delivery',
        name = 'achievement_first_delivery',
        description = 'achievement_first_delivery_desc',
        icon = 'local_shipping',
        condition = function(stats)
            return (stats.done_delivery or 0) + (stats.done_mission or 0) >= 1
        end
    },
    {
        id = 'road_warrior',
        name = 'achievement_road_warrior',
        description = 'achievement_road_warrior_desc',
        icon = 'directions_car',
        condition = function(stats)
            return (stats.distance or 0) >= 500
        end
    },
    {
        id = 'marathon_runner',
        name = 'achievement_marathon_runner',
        description = 'achievement_marathon_runner_desc',
        icon = 'emoji_events',
        condition = function(stats)
            return (stats.distance or 0) >= 2000
        end
    },
    {
        id = 'perfectionist',
        name = 'achievement_perfectionist',
        description = 'achievement_perfectionist_desc',
        icon = 'star',
        condition = function(stats)
            local allDone = (stats.done_delivery or 0) + (stats.done_mission or 0)
            if allDone < 10 then return false end
            local qualityRate = (stats.goods_quality or 0) / allDone
            return qualityRate >= 98
        end
    },
    {
        id = 'veteran',
        name = 'achievement_veteran',
        description = 'achievement_veteran_desc',
        icon = 'military_tech',
        condition = function(stats)
            return (stats.done_delivery or 0) + (stats.done_mission or 0) >= 100
        end
    },
    {
        id = 'mission_specialist',
        name = 'achievement_mission_specialist',
        description = 'achievement_mission_specialist_desc',
        icon = 'security',
        condition = function(stats)
            return (stats.done_mission or 0) >= 20
        end
    },
    {
        id = 'guardian',
        name = 'achievement_guardian',
        description = 'achievement_guardian_desc',
        icon = 'shield',
        condition = function(stats)
            return (stats.defender or 0) >= 10
        end
    },
    {
        id = 'danger_lover',
        name = 'achievement_danger_lover',
        description = 'achievement_danger_lover_desc',
        icon = 'whatshot',
        condition = function(stats)
            return (stats.vulnerable or 0) >= 50
        end
    },
    {
        id = 'ironman',
        name = 'achievement_ironman',
        description = 'achievement_ironman_desc',
        icon = 'fitness_center',
        condition = function(stats)
            return (stats.working_time or 0) >= 36000 -- 10 hours
        end
    },
    {
        id = 'thief',
        name = 'achievement_thief',
        description = 'achievement_thief_desc',
        icon = 'visibility_off',
        condition = function(stats)
            return (stats.stolen_delivery or 0) + (stats.stolen_mission or 0) >= 5
        end
    },
    {
        id = 'legend',
        name = 'achievement_legend',
        description = 'achievement_legend_desc',
        icon = 'workspace_premium',
        condition = function(stats)
            return (stats.distance or 0) >= 10000 and
                   (stats.done_delivery or 0) + (stats.done_mission or 0) >= 500
        end
    },
}

-- ILLEGAL TARGETS
Config.illegalTargetZones = {
    {
        name = 'Cherry Pie',
        address = 'Grand Senora Desert - Baytree Canyon Rd',
        description = 'Illegális árú átvevő',
        actionpoint = vector3(-66.87, 1878.26, 197.96)
    },
    {
        name = 'Pajta',
        address = 'Great Chaparral - Route 68',
        description = 'Illegális árú átvevő',
        actionpoint = vector3(-87.88, 2805.13, 54.29)
    },
    {
        name = 'Flamingo',
        address = 'Redwood Lights Track - Senora Rd',
        description = 'Illegális árú átvevő',
        actionpoint = vector3(895.0, 2172.67, 50.29)
    },
    {
        name = 'Supermarket',
        address = 'Grand Senora Desert - Route 68',
        description = 'Illegális árú átvevő',
        actionpoint = vector3(596.1, 2801.67, 41.16)
    },
}

-- MISSION
Config.missionBlipSprite = 478 -- DEFAULT: 478 radar_contraband
Config.missionBlipColor = 5 -- DEFAULT: 5 orange
Config.missionTrailerSignalInterval = 20 -- DEFAULT: 20 in sec
Config.defenderSocietyPaymentPercent = 70 -- DEFAULT: 70 - védelmi díj jutalék = áru értékének 70 %-a

-- TRUCKS
Config.approvedVehicles = {
    "hauler",
    "phantom",
    "phantom3",
    "packer"
}

-- Hash approved vehicles for quick lookup (client-side only)
if GetHashKey then
    for i = 1, #Config.approvedVehicles do
        Config.approvedVehicles[GetHashKey(Config.approvedVehicles[i])] = Config.approvedVehicles[i]
    end
end

-- ZONE MAP: https:--imgvol.cdn.lcpdfr.com/screenshots/monthly_2015_06/LSSD_Patrol_Zones.png.a9d508cd773ddae957219efd0df43df3.png
Config.zoneData = {
    AIRP = { "city", "Los Santos Nemzetközi Repülőtér" },
    ALAMO = { "country", "Alamo Sea" },
    ALTA = { "city", "Alta" },
    ARMYB = { "country", "Fort Zancudo" },
    BANHAMC = { "country", "Banham Canyon Dr" },
    BANNING = { "city", "Banning" },
    BEACH = { "city", "Vespucci Beach" },
    BHAMCA = { "country", "Banham Canyon" },
    BRADP = { "country", "Braddock Pass" },
    BRADT = { "country", "Braddock Tunnel" },
    BURTON = { "city", "Burton" },
    CALAFB = { "country", "Calafia Bridge" },
    CANNY = { "country", "Raton Canyon" },
    CCREAK = { "country", "Cassidy Creek" },
    CHAMH = { "city", "Chamberlain Hills" },
    CHIL = { "country", "Vinewood Hills" },
    CHU = { "country", "Chumash" },
    CMSW = { "country", "Chiliad Mountain State Wilderness" },
    CYPRE = { "city", "Cypress Flats" },
    DAVIS = { "city", "Davis" },
    DELBE = { "city", "Del Perro Beach" },
    DELPE = { "city", "Del Perro" },
    DELSOL = { "city", "La Puerta" },
    DESRT = { "country", "Grand Senora Desert" },
    DOWNT = { "city", "Downtown" },
    DTVINE = { "city", "Downtown Vinewood" },
    EAST_V = { "city", "East Vinewood" },
    EBURO = { "city", "El Burro Heights" },
    ELGORL = { "country", "El Gordo Lighthouse" },
    ELYSIAN = { "city", "Elysian Island" },
    GALFISH = { "country", "Galilee" },
    GOLF = { "city", "GWC and Golfing Society" },
    GRAPES = { "country", "Grapeseed" },
    GREATC = { "country", "Great Chaparral" },
    HARMO = { "country", "Harmony" },
    HAWICK = { "city", "Hawick" },
    HORS = { "city", "Vinewood Racetrack" },
    HUMLAB = { "country", "Humane Labs and Research" },
    JAIL = { "country", "Bolingbroke Penitentiary" },
    KOREAT = { "city", "Little Seoul" },
    LACT = { "country", "Land Act Reservoir" },
    LAGO = { "country", "Lago Zancudo" },
    LDAM = { "country", "Land Act Dam" },
    LEGSQU = { "city", "Legion Square" },
    LMESA = { "city", "La Mesa" },
    LOSPUER = { "city", "La Puerta" },
    MIRR = { "city", "Mirror Park" },
    MORN = { "city", "Morningwood" },
    MOVIE = { "city", "Richards Majestic" },
    MTCHIL = { "country", "Mount Chiliad" },
    MTGORDO = { "country", "Mount Gordo" },
    MTJOSE = { "country", "Mount Josiah" },
    MURRI = { "city", "Murrieta Heights" },
    NCHU = { "country", "North Chumash" },
    NOOSE = { "city", "N.O.O.S.E" },
    OCEANA = { "city", "Pacific Ocean" },
    PALCOV = { "country", "Paleto Cove" },
    PALETO = { "country", "Paleto Bay" },
    PALFOR = { "country", "Paleto Forest" },
    PALHIGH = { "city", "Palomino Highlands" },
    PALMPOW = { "country", "Palmer-Taylor Power Station" },
    PBLUFF = { "city", "Pacific Bluffs" },
    PBOX = { "city", "Pillbox Hill" },
    PROCOB = { "country", "Procopio Beach" },
    RANCHO = { "city", "Rancho" },
    RGLEN = { "country", "Richman Glen" },
    RICHM = { "country", "Richman" },
    ROCKF = { "city", "Rockford Hills" },
    RTRAK = { "country", "Redwood Lights Track" },
    SANAND = { "city", "San Andreas" },
    SANCHIA = { "country", "San Chianski Mountain Range" },
    SANDY = { "country", "Sandy Shores" },
    SKID = { "city", "mission Row" },
    SLAB = { "country", "Stab City" },
    STAD = { "city", "Maze Bank Arena" },
    STRAW = { "city", "Strawberry" },
    TATAMO = { "country", "Tataviam Mountains" },
    TERMINA = { "city", "Terminal" },
    TEXTI = { "city", "Textile City" },
    TONGVAH = { "country", "Tongva Hills" },
    TONGVAV = { "country", "Tongva Valley" },
    VCANA = { "city", "Vespucci Canals" },
    VESP = { "city", "Vespucci" },
    VINE = { "city", "Vinewood" },
    WINDF = { "country", "Ron Alternates Wind Farm" },
    WVINE = { "city", "West Vinewood" },
    ZANCUDO = { "country", "Zancudo River" },
    ZP_ORT = { "city", "Port of South Los Santos" },
    ZQ_UAR = { "country", "Davis Quartz" },
}


-- ============================================================
-- COMPANY SYSTEM (Kamionos Vállalkozás)
-- ============================================================
-- All prices and salaries are in Ft (Forint)

Config.company = {
    enabled = true,

    -- Cégalapítás
    registrationFee = 2500000,          -- 2.500.000 Ft alapítási díj (reális: ~2.5M Ft egyéni vállalkozás)
    nameMinLength = 3,
    nameMaxLength = 30,

    -- Adózás
    taxRate = 0.15,                      -- 15% adó a céges bevételek után (reális magyar adóteher)
    taxInterval = 24,                    -- Óránként hányszor von adót (24 = naponta)

    -- Szintek és limitek
    levels = {
        { level = 1, name = 'Induló',           maxEmployees = 3,  maxVehicles = 2,  reputationNeeded = 0,    deliveriesNeeded = 0 },
        { level = 2, name = 'Fejlődő',          maxEmployees = 5,  maxVehicles = 3,  reputationNeeded = 50,   deliveriesNeeded = 30 },
        { level = 3, name = 'Haladó',           maxEmployees = 8,  maxVehicles = 5,  reputationNeeded = 200,  deliveriesNeeded = 100 },
        { level = 4, name = 'Professzionális',  maxEmployees = 12, maxVehicles = 8,  reputationNeeded = 500,  deliveriesNeeded = 300 },
        { level = 5, name = 'Nagyvállalat',     maxEmployees = 20, maxVehicles = 15, reputationNeeded = 1500, deliveriesNeeded = 750 },
    },

    -- Rangok / Szerepkörök
    roles = {
        driver = {
            label = 'Sofőr',
            permissions = { 'drive', 'view_contracts' },
            defaultSalary = 35000,      -- 35.000 Ft / szállítás (reális sofőr napi bér ~50-80k)
        },
        dispatcher = {
            label = 'Diszpécser',
            permissions = { 'drive', 'view_contracts', 'accept_contracts', 'assign_drivers' },
            defaultSalary = 55000,      -- 55.000 Ft / szállítás
        },
        manager = {
            label = 'Menedzser',
            permissions = { 'drive', 'view_contracts', 'accept_contracts', 'assign_drivers', 'hire', 'fire', 'manage_vehicles', 'view_finances' },
            defaultSalary = 85000,      -- 85.000 Ft / szállítás
        },
        owner = {
            label = 'Tulajdonos',
            permissions = { 'all' },
            defaultSalary = 0,          -- A tulajdonos a profitból él
        },
    },

    -- Fizetési rendszer
    salary = {
        paymentType = 'per_delivery',    -- 'per_delivery' = szállításonként
        bonusMultiplier = 1.3,           -- +30% bónusz ha a minőség 95%+ volt
        penaltyMultiplier = 0.5,         -- 50% büntetés ha megsemmisült a rakomány
    },

    -- Céges fuvar profit elosztás
    profit = {
        companyShare = 0.25,             -- 25% a cégnek (kasszába)
        driverShare = 0.75,              -- 75% a sofőrnek (a fuvardíjból)
    },

    -- Járműpark (reális magyar kamion árak RP arányban)
    vehicles = {
        available = {
            { model = 'hauler',     name = 'Hauler',          price = 8500000,   maintenanceCost = 150000 },
            { model = 'phantom',    name = 'Phantom',         price = 12000000,  maintenanceCost = 220000 },
            { model = 'phantom3',   name = 'Phantom Custom',  price = 18500000,  maintenanceCost = 350000 },
            { model = 'packer',     name = 'Packer',          price = 9800000,   maintenanceCost = 180000 },
        },
        maintenanceInterval = 50,        -- Szervíz szükséges ennyi szállítás után
        fuelCostPerKm = 250,             -- 250 Ft / km üzemanyag (reális dízel ár)
    },

    -- Szerződés rendszer
    contracts = {
        maxActive = 3,                   -- Max aktív szerződés egyszerre
        refreshInterval = 60,            -- Új szerződések ennyi percenként generálódnak
        baseReward = 150000,             -- 150.000 Ft alap jutalom
        distanceMultiplier = 1200,       -- +1.200 Ft / km távolság
        qualityBonus = 0.20,             -- +20% ha 95%+ minőséggel teljesíted
        deadlineDefault = 24,            -- 24 óra alapértelmezett határidő
        penaltyRate = 0.25,              -- 25% büntetés ha lejár a határidő
    },

    -- Reputáció
    reputation = {
        perDelivery = 2,                 -- +2 rep normál szállítás
        perContract = 5,                 -- +5 rep szerződés teljesítés
        perContractBonus = 3,            -- +3 rep ha bónusz minőséggel
        penaltyFailed = -10,             -- -10 rep ha megsemmisül / lejár
        penaltyFired = -3,              -- -3 rep ha elbocsátasz valakit
    },

    -- Meghívás
    invites = {
        expiresInHours = 48,             -- Meghívás 48 óra után lejár
        maxPending = 5,                  -- Max 5 függő meghívás egyszerre
    },
}
