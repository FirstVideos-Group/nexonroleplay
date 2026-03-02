-- ============================================================
--  nxn-vehicles | server.lua
-- ============================================================

-- ── Segédfüggvények ──────────────────────────────────────────

local function NotifyPlayer(src, msg, ntype)
    if GetResourceState('nxn-notify') ~= 'started' then return end
    local t = ntype or 'info'
    if     t == 'success' then TriggerClientEvent('nxn-notify:client:success', src, msg)
    elseif t == 'danger'  then TriggerClientEvent('nxn-notify:client:danger',  src, msg)
    elseif t == 'warning' then TriggerClientEvent('nxn-notify:client:warning', src, msg)
    else                       TriggerClientEvent('nxn-notify:client:info',    src, msg)
    end
end

local function GetIdentifier(src)
    if GetResourceState('nxn-database') ~= 'started' then return nil end
    return exports['nxn-database']:getIdentifier(src)
end

local function ValidatePlate(plate)
    return type(plate) == 'string' and #plate > 0 and #plate <= 8
end

--- Véletlenszerű érvekényes magyar stílusú rendszám generálása (ha nincs megadva)
local function GeneratePlate()
    local chars = 'ABCDEFGHJKLMNPRSTUVWXYZ'
    local function rc() return chars:sub(math.random(#chars), math.random(#chars)) end
    return ('%s%s%s-%s%s-%s%s'):
        format(rc(), rc(), rc(),
               tostring(math.random(0,9)), tostring(math.random(0,9)),
               rc(), rc()
        )
end

--- Egyedi rendszám (DB-ben nincs-e még)
local function UniqueGeneratedPlate()
    for _ = 1, 20 do
        local p = GeneratePlate()
        local existing = MySQL.single.await(
            'SELECT id FROM `nxn_vehicles` WHERE plate = ? LIMIT 1', { p }
        )
        if not existing then return p end
    end
    -- végső fallback: timestamp alapú
    return ('NX%06d'):format(math.random(100000, 999999))
end

-- ── DB init ───────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(res)
    if res ~= Config.ResourceName then return end
    NXN.Vehicles.Info('nxn-vehicles elindul...')
    CreateThread(function()
        if GetResourceState('nxn-database') ~= 'started' then
            NXN.Vehicles.Warn('nxn-database nem fut – táblák nem hozhatók létre')
            return
        end

        exports['nxn-database']:registerTable(Config.ResourceName, {
            name = 'nxn_vehicles',
            sql  = [[
                CREATE TABLE IF NOT EXISTS `nxn_vehicles` (
                    `id`         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
                    `identifier` VARCHAR(64)   NOT NULL,
                    `plate`      VARCHAR(16)   NOT NULL UNIQUE,
                    `model`      VARCHAR(64)   NOT NULL,
                    `label`      VARCHAR(128)  DEFAULT NULL,
                    `class`      TINYINT       DEFAULT NULL,
                    `mods`       JSON          DEFAULT NULL,
                    `garage`     VARCHAR(64)   NOT NULL DEFAULT 'main_garage',
                    `impounded`  TINYINT(1)    NOT NULL DEFAULT 0,
                    `stored`     TINYINT(1)    NOT NULL DEFAULT 1,
                    `created_at` DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (`id`),
                    INDEX `idx_identifier` (`identifier`),
                    INDEX `idx_plate`      (`plate`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]]
        })

        exports['nxn-database']:registerTable(Config.ResourceName, {
            name = 'nxn_vehicle_engine_hp',
            sql  = [[
                CREATE TABLE IF NOT EXISTS `nxn_vehicle_engine_hp` (
                    `plate`      VARCHAR(16) NOT NULL PRIMARY KEY,
                    `hp_percent` FLOAT       NOT NULL DEFAULT 100.0,
                    `updated_at` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]]
        })

        NXN.Vehicles.Info('Táblák regisztrálva.')
    end)
end)

-- ── Net eventek ──────────────────────────────────────────────

-- Járműbe lépés
RegisterNetEvent('nxn-vehicles:server:entered', function(plate, vehicleClass)
    local src = source
    plate = NXN.Vehicles.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end

    NXN.Vehicles.Log(('entered: src=%d plate=%s class=%d'):format(src, plate, vehicleClass))

    -- Jogosítvány ellenőrzés
    if Config.EnableLicenseCheck and GetResourceState('nxn-licenses') == 'started' then
        local licType = exports['nxn-vehicles']:getLicenseTypeForClass(vehicleClass)
        if licType then
            local ok = exports['nxn-licenses']:hasLicense(src, licType)
            if not ok then
                NotifyPlayer(src, 'Nincs érvényes jogosítványod ehhez a járműhöz!', 'warning')
                NXN.Vehicles.Log(('Jogosítvány hiány: src=%d type=%s'):format(src, licType))
            end
        end
    end

    -- nxn-vehicle-hud: siren modul auto-engedélyezés emergency járműnél
    if GetResourceState('nxn-vehicle-hud') == 'started' then
        local isEmergency = (vehicleClass == Config.EmergencyClass)
        TriggerClientEvent('nxn-vehicle-hud:client:setModule', src, 'siren', isEmergency)
        NXN.Vehicles.Log(('vehicle-hud siren modul: %s (class=%d)'):format(tostring(isEmergency), vehicleClass))
    end

    -- stored = false beállítása (ha a jármű korábban tárolt volt)
    local row = MySQL.single.await(
        'SELECT stored FROM `nxn_vehicles` WHERE plate = ?', { plate }
    )
    if row and row.stored == 1 then
        MySQL.update(
            'UPDATE `nxn_vehicles` SET stored = 0 WHERE plate = ?', { plate }
        )
    end

    -- Motor HP visszatöltése az nxn-engine kliensnek
    if Config.PersistEngineHP then
        local hpRow = MySQL.single.await(
            'SELECT hp_percent FROM `nxn_vehicle_engine_hp` WHERE plate = ?', { plate }
        )
        local hp = hpRow and hpRow.hp_percent or 100.0
        TriggerClientEvent('nxn-vehicles:client:engineHPSync', src, { plate = plate, hp = hp })
    end

    -- Szerver event kisugarárzása (nxn-licenses stb. figyeli)
    TriggerEvent('nxn-vehicles:server:entered', src, plate, vehicleClass)
end)

-- Járműből kilépés
RegisterNetEvent('nxn-vehicles:server:exited', function(plate)
    local src = source
    plate = NXN.Vehicles.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end
    NXN.Vehicles.Log(('exited: src=%d plate=%s'):format(src, plate))
    TriggerEvent('nxn-vehicles:server:exited', src, plate)
end)

-- Motor HP mentése (nxn-garage hívja despawn előtt)
RegisterNetEvent('nxn-vehicles:server:saveHP', function(plate, hp)
    local src = source
    plate = NXN.Vehicles.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end
    local hpVal = tonumber(hp)
    if not hpVal or hpVal < 0 or hpVal > 100 then return end
    if not Config.PersistEngineHP then return end
    exports['nxn-vehicles']:saveEngineHP(plate, hpVal)
    NXN.Vehicles.Log(('saveHP (net): src=%d plate=%s hp=%.1f'):format(src, plate, hpVal))
end)

-- nxn-impound figyelme: lefoglás esemény
AddEventHandler('nxn-impound:server:vehicleImpounded', function(src, plate)
    plate = NXN.Vehicles.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end
    exports['nxn-vehicles']:setImpounded(plate, true)
    NXN.Vehicles.Log(('Lefoglálva (impound event): plate=%s'):format(plate))
end)

-- ── Szerver exportok ─────────────────────────────────────────

--- Játékos összes járműve (shallow copy tombje)
---@param identifier string
---@return table[]
exports('getVehicles', function(identifier)
    if type(identifier) ~= 'string' or #identifier == 0 then return {} end
    local rows = MySQL.query.await(
        'SELECT * FROM `nxn_vehicles` WHERE identifier = ?', { identifier }
    )
    local result = {}
    for _, v in ipairs(rows or {}) do
        table.insert(result, {
            id         = v.id,
            identifier = v.identifier,
            plate      = v.plate,
            model      = v.model,
            label      = v.label,
            class      = v.class,
            mods       = v.mods,
            garage     = v.garage,
            impounded  = v.impounded == 1,
            stored     = v.stored    == 1,
            created_at = v.created_at,
        })
    end
    return result
end)

--- Egy jármű adatai rendszám alapján
---@param plate string
---@return table|nil
exports('getVehicle', function(plate)
    plate = NXN.Vehicles.NormalizePlate(plate)
    if not ValidatePlate(plate) then return nil end
    local row = MySQL.single.await(
        'SELECT * FROM `nxn_vehicles` WHERE plate = ?', { plate }
    )
    if not row then return nil end
    return {
        id         = row.id,
        identifier = row.identifier,
        plate      = row.plate,
        model      = row.model,
        label      = row.label,
        class      = row.class,
        mods       = row.mods,
        garage     = row.garage,
        impounded  = row.impounded == 1,
        stored     = row.stored    == 1,
        created_at = row.created_at,
    }
end)

--- Új jármű regisztrálása DB-be
---@param identifier string
---@param model       string
---@param label       string
---@param class       integer
---@param plate       string?  Ha nil, véletlenszerű egyedi rendszám generalódik
---@return string|nil  plate
exports('addVehicle', function(identifier, model, label, class, plate)
    if type(identifier) ~= 'string' or #identifier == 0 then return nil end
    if type(model)      ~= 'string' or #model      == 0 then return nil end

    local finalPlate
    if type(plate) == 'string' and #plate > 0 then
        finalPlate = NXN.Vehicles.NormalizePlate(plate)
    else
        finalPlate = UniqueGeneratedPlate()
    end

    local ok = MySQL.insert.await(
        'INSERT INTO `nxn_vehicles` (identifier, plate, model, label, class) VALUES (?, ?, ?, ?, ?)',
        { identifier, finalPlate, model, label or model, tonumber(class) or 0 }
    )
    if ok then
        NXN.Vehicles.Info(('addVehicle: ident=%s plate=%s model=%s'):format(identifier, finalPlate, model))
        return finalPlate
    end
    NXN.Vehicles.Error(('addVehicle: DB insert sikertelen ident=%s model=%s'):format(identifier, model))
    return nil
end)

--- Jármű törlése
---@param plate string
---@return boolean
exports('removeVehicle', function(plate)
    plate = NXN.Vehicles.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    local affected = MySQL.update.await(
        'DELETE FROM `nxn_vehicles` WHERE plate = ?', { plate }
    )
    -- HP sor törlése is
    MySQL.update('DELETE FROM `nxn_vehicle_engine_hp` WHERE plate = ?', { plate })
    NXN.Vehicles.Log(('removeVehicle: plate=%s affected=%d'):format(plate, affected or 0))
    return (affected or 0) > 0
end)

--- Garazs/kint állapot állítása
---@param plate  string
---@param state  boolean  true = garazsban
---@return boolean
exports('setStored', function(plate, state)
    plate = NXN.Vehicles.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    local val = state and 1 or 0
    local affected = MySQL.update.await(
        'UPDATE `nxn_vehicles` SET stored = ? WHERE plate = ?', { val, plate }
    )
    NXN.Vehicles.Log(('setStored: plate=%s stored=%s'):format(plate, tostring(state)))
    return (affected or 0) > 0
end)

--- Lefoglalás állapot beállítása
---@param plate  string
---@param state  boolean
---@return boolean
exports('setImpounded', function(plate, state)
    plate = NXN.Vehicles.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    local val = state and 1 or 0
    local affected = MySQL.update.await(
        'UPDATE `nxn_vehicles` SET impounded = ? WHERE plate = ?', { val, plate }
    )
    NXN.Vehicles.Log(('setImpounded: plate=%s impounded=%s'):format(plate, tostring(state)))
    return (affected or 0) > 0
end)

--- Motor HP % lekérése DB-ből
---@param plate string
---@return number  (0-100, alapérték 100.0)
exports('getEngineHP', function(plate)
    plate = NXN.Vehicles.NormalizePlate(plate)
    if not ValidatePlate(plate) or not Config.PersistEngineHP then return 100.0 end
    local row = MySQL.single.await(
        'SELECT hp_percent FROM `nxn_vehicle_engine_hp` WHERE plate = ?', { plate }
    )
    return row and row.hp_percent or 100.0
end)

--- Motor HP mentése DB-be
---@param plate string
---@param hp    number  (0-100)
exports('saveEngineHP', function(plate, hp)
    plate = NXN.Vehicles.NormalizePlate(plate)
    if not ValidatePlate(plate) or not Config.PersistEngineHP then return end
    local hpVal = tonumber(hp)
    if not hpVal then return end
    hpVal = math.max(0, math.min(100, hpVal))
    MySQL.query(
        'INSERT INTO `nxn_vehicle_engine_hp` (plate, hp_percent) VALUES (?, ?) ON DUPLICATE KEY UPDATE hp_percent = ?, updated_at = NOW()',
        { plate, hpVal, hpVal }
    )
    NXN.Vehicles.Log(('saveEngineHP: plate=%s hp=%.1f'):format(plate, hpVal))
end)

--- Tulajdonos-ellenőrzés
---@param src   integer
---@param plate string
---@return boolean
exports('isOwner', function(src, plate)
    plate = NXN.Vehicles.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    local identifier = GetIdentifier(src)
    if not identifier then return false end
    local row = MySQL.single.await(
        'SELECT id FROM `nxn_vehicles` WHERE plate = ? AND identifier = ? LIMIT 1',
        { plate, identifier }
    )
    return row ~= nil
end)

--- Kényelmi export: jogosítvány típus járműosztályhoz
---@param class integer
---@return string|nil
exports('getLicenseTypeForClass', function(class)
    return Config.LicenseByClass[tonumber(class)] or nil
end)

--- Garjármű garage-azonosítójának frissítése
---@param plate   string
---@param garageId string
---@return boolean
exports('setGarage', function(plate, garageId)
    plate = NXN.Vehicles.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    if type(garageId) ~= 'string' or #garageId == 0 then return false end
    local affected = MySQL.update.await(
        'UPDATE `nxn_vehicles` SET garage = ? WHERE plate = ?', { garageId, plate }
    )
    return (affected or 0) > 0
end)

--- Mods JSON frissítése
---@param plate string
---@param mods  table
---@return boolean
exports('setMods', function(plate, mods)
    plate = NXN.Vehicles.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    local ok, jsonStr = pcall(json.encode, mods)
    if not ok then return false end
    local affected = MySQL.update.await(
        'UPDATE `nxn_vehicles` SET mods = ? WHERE plate = ?', { jsonStr, plate }
    )
    return (affected or 0) > 0
end)
