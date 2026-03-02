-- ============================================================
--  nxn-fuel | server.lua
-- ============================================================

-- ── In-memory cache (plate -> float) ──────────────────────────────
local fuelCache = {}

-- ── Segéd ─────────────────────────────────────────────────────

local function ValidatePlate(plate)
    return type(plate) == 'string' and #plate > 0 and #plate <= 20
end

local function DefaultFuel()
    if Config.DefaultFuelOnSpawn == 'full' then
        return 100.0
    elseif Config.DefaultFuelOnSpawn == 'last' then
        -- 'last' esetén a DB-ből kellene, de ha nincs ott, random-ot adunk
        return NXN.Fuel.Clamp(
            Config.SpawnFuelMin + math.random() * (Config.SpawnFuelMax - Config.SpawnFuelMin),
            0.0, 100.0
        )
    else
        -- 'random' (alapértelmezett)
        return NXN.Fuel.Clamp(
            Config.SpawnFuelMin + math.random() * (Config.SpawnFuelMax - Config.SpawnFuelMin),
            0.0, 100.0
        )
    end
end

-- ── DB init ────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(res)
    if res ~= Config.ResourceName then return end
    NXN.Fuel.Info('nxn-fuel elindul...')
    CreateThread(function()
        if GetResourceState('nxn-database') ~= 'started' then
            NXN.Fuel.Warn('nxn-database nem fut – DB tábla nem hozható létre!')
            return
        end
        exports['nxn-database']:registerTable(Config.ResourceName, {
            name = 'nxn_vehicle_fuel',
            sql  = [[
                CREATE TABLE IF NOT EXISTS `nxn_vehicle_fuel` (
                    `id`         INT AUTO_INCREMENT PRIMARY KEY,
                    `plate`      VARCHAR(20)  NOT NULL UNIQUE,
                    `fuel`       FLOAT        DEFAULT 100.0,
                    `updated_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
                        ON UPDATE CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]]
        })
        NXN.Fuel.Info('nxn_vehicle_fuel tábla regisztrálva.')
    end)
end)

-- ── Szerver exportok ───────────────────────────────────────

---@param plate string
---@return float
exports('getFuel', function(plate)
    plate = NXN.Fuel.NormalizePlate(plate)
    if not ValidatePlate(plate) then return 0.0 end
    if fuelCache[plate] then return fuelCache[plate] end
    -- Szinkron lekérés cache miss esetén
    local result = 0.0
    if GetResourceState('nxn-database') == 'started' then
        local rows = MySQL.query.await(
            'SELECT fuel FROM `nxn_vehicle_fuel` WHERE plate = ? LIMIT 1',
            { plate }
        )
        if rows and rows[1] then
            result = tonumber(rows[1].fuel) or DefaultFuel()
        else
            result = DefaultFuel()
        end
    else
        result = DefaultFuel()
    end
    fuelCache[plate] = result
    return result
end)

---@param plate  string
---@param amount float
---@return boolean
exports('setFuel', function(plate, amount)
    plate = NXN.Fuel.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    local clamped = NXN.Fuel.Clamp(tonumber(amount) or 0.0, 0.0, 100.0)
    fuelCache[plate] = clamped
    if GetResourceState('nxn-database') == 'started' then
        MySQL.insert(
            'INSERT INTO `nxn_vehicle_fuel` (plate, fuel) VALUES (?, ?)'
            .. ' ON DUPLICATE KEY UPDATE fuel = VALUES(fuel)',
            { plate, clamped }
        )
    end
    NXN.Fuel.Log(('setFuel: plate=%s level=%.2f'):format(plate, clamped))
    return true
end)

---@param plate  string
---@param amount float
---@return float
exports('addFuel', function(plate, amount)
    plate = NXN.Fuel.NormalizePlate(plate)
    if not ValidatePlate(plate) then return 0.0 end
    local current = exports['nxn-fuel']:getFuel(plate)
    local newLevel = NXN.Fuel.Clamp(current + (tonumber(amount) or 0.0), 0.0, 100.0)
    exports['nxn-fuel']:setFuel(plate, newLevel)
    NXN.Fuel.Log(('addFuel: plate=%s +%.2f -> %.2f'):format(plate, amount, newLevel))
    return newLevel
end)

---@param plate  string
---@param amount float
---@return float
exports('removeFuel', function(plate, amount)
    plate = NXN.Fuel.NormalizePlate(plate)
    if not ValidatePlate(plate) then return 0.0 end
    local current = exports['nxn-fuel']:getFuel(plate)
    local newLevel = NXN.Fuel.Clamp(current - (tonumber(amount) or 0.0), 0.0, 100.0)
    exports['nxn-fuel']:setFuel(plate, newLevel)
    NXN.Fuel.Log(('removeFuel: plate=%s -%.2f -> %.2f'):format(plate, amount, newLevel))
    return newLevel
end)

---@param plate string
---@return float
exports('getTankSize', function(plate)
    plate = NXN.Fuel.NormalizePlate(plate)
    if GetResourceState('nxn-vehicles') == 'started' then
        local ok, data = pcall(function()
            return exports['nxn-vehicles']:getVehicleData(plate)
        end)
        if ok and type(data) == 'table' and data.tankSize then
            return tonumber(data.tankSize) or Config.DefaultTankSize
        end
    end
    return Config.DefaultTankSize
end)

-- ── Net eventek ────────────────────────────────────────────

-- Kliens kéri a jármű üzemanyagszintjét (járműbe szálláskor)
RegisterNetEvent('nxn-fuel:server:requestFuel', function(plate)
    local src = source
    plate = NXN.Fuel.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end

    CreateThread(function()
        local level
        if GetResourceState('nxn-database') == 'started' then
            local rows = MySQL.query.await(
                'SELECT fuel FROM `nxn_vehicle_fuel` WHERE plate = ? LIMIT 1',
                { plate }
            )
            if rows and rows[1] then
                level = tonumber(rows[1].fuel)
                if Config.DefaultFuelOnSpawn == 'last' then
                    -- megtartjuk a mentett értéket
                else
                    -- 'random' vagy 'full': ha van DB-ben, azt használjuk (egyszer már volt)
                    level = level
                end
            else
                level = DefaultFuel()
                -- Betesszük a cache-be és DB-be is
                MySQL.insert(
                    'INSERT IGNORE INTO `nxn_vehicle_fuel` (plate, fuel) VALUES (?, ?)',
                    { plate, level }
                )
            end
        else
            level = DefaultFuel()
        end

        fuelCache[plate] = level
        TriggerClientEvent('nxn-fuel:client:sync', src, { plate = plate, level = level })
        NXN.Fuel.Log(('requestFuel: src=%d plate=%s level=%.2f'):format(src, plate, level))
    end)
end)

-- Kliens menti az üzemanyagszintet (throttle-zott)
RegisterNetEvent('nxn-fuel:server:saveFuel', function(plate, level)
    local src = source
    plate = NXN.Fuel.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end
    level = NXN.Fuel.Clamp(tonumber(level) or 0.0, 0.0, 100.0)

    fuelCache[plate] = level

    if GetResourceState('nxn-database') ~= 'started' then return end
    MySQL.insert(
        'INSERT INTO `nxn_vehicle_fuel` (plate, fuel) VALUES (?, ?)'
        .. ' ON DUPLICATE KEY UPDATE fuel = VALUES(fuel)',
        { plate, level }
    )
    NXN.Fuel.Log(('saveFuel: plate=%s level=%.2f'):format(plate, level))
end)
