-- ============================================================
--  nxn-keys | server.lua
-- ============================================================

-- ── Segédfüggvények ──────────────────────────────────────────

local function Notify(src, msg, ntype)
    if GetResourceState('nxn-notify') ~= 'started' then return end
    exports['nxn-notify']:notify(src, msg, ntype or 'info')
end

local function GetIdentifier(src)
    if GetResourceState('nxn-database') ~= 'started' then return nil end
    -- nxn-identity előnyben, fallback: nxn-database
    if GetResourceState('nxn-identity') == 'started' then
        return exports['nxn-identity']:getIdentifier(src)
    end
    return exports['nxn-database']:getIdentifier(src)
end

local function ValidatePlate(plate)
    return type(plate) == 'string' and #plate > 0 and #plate <= 20
end

-- ── DB init ──────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(res)
    if res ~= Config.ResourceName then return end
    NXN.Keys.Info('nxn-keys elindul...')
    CreateThread(function()
        if GetResourceState('nxn-database') ~= 'started' then
            NXN.Keys.Warn('nxn-database nem fut – táblák nem hozhatók létre')
            return
        end
        exports['nxn-database']:registerTable(Config.ResourceName, {
            name = 'nxn_vehicle_keys',
            sql  = [[
                CREATE TABLE IF NOT EXISTS `nxn_vehicle_keys` (
                    `id`          INT AUTO_INCREMENT PRIMARY KEY,
                    `plate`       VARCHAR(20)  NOT NULL,
                    `identifier`  VARCHAR(100) NOT NULL,
                    `is_owner`    TINYINT(1)   DEFAULT 0,
                    `created_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE KEY `uq_plate_ident` (`plate`, `identifier`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]]
        })
        NXN.Keys.Info('nxn_vehicle_keys tábla regisztrálva.')
    end)
end)

-- ── Szerver exportok ─────────────────────────────────────────

--- Kulcs adása játékosnak (DB insert + kliens cache frissítés)
---@param src   integer  játékos server source
---@param plate string
---@param isOwner boolean?
---@return boolean
exports('giveKey', function(src, plate, isOwner)
    plate = NXN.Keys.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    local identifier = GetIdentifier(src)
    if not identifier then
        NXN.Keys.Warn(('giveKey: azonosító nem található src=%d'):format(src))
        return false
    end
    local ownerVal = (isOwner == true) and 1 or 0
    local ok = MySQL.insert.await(
        'INSERT IGNORE INTO `nxn_vehicle_keys` (plate, identifier, is_owner) VALUES (?, ?, ?)',
        { plate, identifier, ownerVal }
    )
    if ok then
        NXN.Keys.Log(('giveKey: src=%d plate=%s owner=%s'):format(src, plate, tostring(isOwner)))
        -- Cache frissítés a kliensnek
        local keys = exports['nxn-keys']:getKeys(src)
        TriggerClientEvent('nxn-keys:client:syncKeys', src, keys)
        return true
    end
    return false
end)

--- Kulcs megvonása
---@param src   integer
---@param plate string
---@return boolean
exports('removeKey', function(src, plate)
    plate = NXN.Keys.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    local identifier = GetIdentifier(src)
    if not identifier then return false end
    local affected = MySQL.update.await(
        'DELETE FROM `nxn_vehicle_keys` WHERE plate = ? AND identifier = ? AND is_owner = 0',
        { plate, identifier }
    )
    if (affected or 0) > 0 then
        NXN.Keys.Log(('removeKey: src=%d plate=%s'):format(src, plate))
        local keys = exports['nxn-keys']:getKeys(src)
        TriggerClientEvent('nxn-keys:client:syncKeys', src, keys)
        TriggerClientEvent('nxn-keys:client:keyRevoked', src, { plate = plate })
        TriggerEvent('nxn-keys:server:keyRevoked', plate, identifier)
        return true
    end
    return false
end)

--- Van-e kulcsa a játékosnak?
---@param src   integer
---@param plate string
---@return boolean
exports('hasKey', function(src, plate)
    plate = NXN.Keys.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    local identifier = GetIdentifier(src)
    if not identifier then return false end
    local row = MySQL.single.await(
        'SELECT id FROM `nxn_vehicle_keys` WHERE plate = ? AND identifier = ? LIMIT 1',
        { plate, identifier }
    )
    return row ~= nil
end)

--- Játékos összes kulcsa (jármű adatokkal bővítve ha nxn-vehicles férhethető)
---@param src integer
---@return table[]
exports('getKeys', function(src)
    local identifier = GetIdentifier(src)
    if not identifier then return {} end
    local rows = MySQL.query.await(
        'SELECT plate, is_owner FROM `nxn_vehicle_keys` WHERE identifier = ?',
        { identifier }
    )
    local result = {}
    for _, row in ipairs(rows or {}) do
        local entry = {
            plate    = row.plate,
            is_owner = row.is_owner == 1,
            label    = nil,
            model    = nil,
        }
        -- Jármű adatok hozzáadva ha nxn-vehicles fut
        if GetResourceState('nxn-vehicles') == 'started' then
            local veh = exports['nxn-vehicles']:getVehicle(row.plate)
            if veh then
                entry.label = veh.label
                entry.model = veh.model
            end
        end
        table.insert(result, entry)
    end
    return result
end)

--- Az összes kulcs törlése egy járműhöz (pl. eladásnál)
---@param plate string
---@return boolean
exports('revokeAllKeys', function(plate)
    plate = NXN.Keys.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    -- Kulcstulajdonosok értesítése mielőtt törlünk
    local holders = exports['nxn-keys']:getKeyHolders(plate)
    MySQL.update.await(
        'DELETE FROM `nxn_vehicle_keys` WHERE plate = ?', { plate }
    )
    -- Online játékosok cache frissítése
    for _, h in ipairs(holders) do
        for _, pid in ipairs(GetPlayers()) do
            local id = GetIdentifier(tonumber(pid))
            if id == h.identifier then
                TriggerClientEvent('nxn-keys:client:keyRevoked', tonumber(pid), { plate = plate })
                local keys = exports['nxn-keys']:getKeys(tonumber(pid))
                TriggerClientEvent('nxn-keys:client:syncKeys', tonumber(pid), keys)
            end
        end
    end
    NXN.Keys.Info(('revokeAllKeys: plate=%s'):format(plate))
    TriggerEvent('nxn-keys:server:keyRevoked', plate, 'all')
    return true
end)

--- Kik rendelkeznek kulccsal az adott járműhöz
---@param plate string
---@return table[]
exports('getKeyHolders', function(plate)
    plate = NXN.Keys.NormalizePlate(plate)
    if not ValidatePlate(plate) then return {} end
    local rows = MySQL.query.await(
        'SELECT identifier, is_owner FROM `nxn_vehicle_keys` WHERE plate = ?', { plate }
    )
    local result = {}
    for _, row in ipairs(rows or {}) do
        table.insert(result, {
            identifier = row.identifier,
            is_owner   = row.is_owner == 1,
        })
    end
    return result
end)

-- ── Net eventek (szerver) ────────────────────────────────────

-- Kulcslista kérés
RegisterNetEvent('nxn-keys:server:getKeys', function()
    local src  = source
    local keys = exports['nxn-keys']:getKeys(src)
    TriggerClientEvent('nxn-keys:client:syncKeys', src, keys)
end)

-- Zárolás
RegisterNetEvent('nxn-keys:server:lock', function(plate)
    local src = source
    plate = NXN.Keys.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end

    if not exports['nxn-keys']:hasKey(src, plate) then
        Notify(src, 'Nincs kulcsod ehhez a járműhöz!', 'danger')
        TriggerClientEvent('nxn-keys:client:lockResult', src, { ok = false, plate = plate, locked = nil, message = 'no_key' })
        return
    end

    -- nxn-engine setLocked – a kliens oldali engine a lock állapotot kezeli
    -- Szerver oldalon broadcastolunk minden kulcstulajdonosnak
    TriggerClientEvent('nxn-keys:client:lockResult', src, { ok = true, plate = plate, locked = true })

    -- Értesítés minden kulcstulajdonosnak
    local holders = exports['nxn-keys']:getKeyHolders(plate)
    for _, h in ipairs(holders) do
        for _, pid in ipairs(GetPlayers()) do
            local id = GetIdentifier(tonumber(pid))
            if id == h.identifier and tonumber(pid) ~= src then
                TriggerClientEvent('nxn-keys:client:lockResult', tonumber(pid), { ok = true, plate = plate, locked = true })
            end
        end
    end

    TriggerEvent('nxn-keys:server:locked', src, plate)
    NXN.Keys.Log(('lock: src=%d plate=%s'):format(src, plate))
end)

-- Nyitás
RegisterNetEvent('nxn-keys:server:unlock', function(plate)
    local src = source
    plate = NXN.Keys.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end

    if not exports['nxn-keys']:hasKey(src, plate) then
        Notify(src, 'Nincs kulcsod ehhez a járműhöz!', 'danger')
        TriggerClientEvent('nxn-keys:client:lockResult', src, { ok = false, plate = plate, locked = nil, message = 'no_key' })
        return
    end

    TriggerClientEvent('nxn-keys:client:lockResult', src, { ok = true, plate = plate, locked = false })

    local holders = exports['nxn-keys']:getKeyHolders(plate)
    for _, h in ipairs(holders) do
        for _, pid in ipairs(GetPlayers()) do
            local id = GetIdentifier(tonumber(pid))
            if id == h.identifier and tonumber(pid) ~= src then
                TriggerClientEvent('nxn-keys:client:lockResult', tonumber(pid), { ok = true, plate = plate, locked = false })
            end
        end
    end

    TriggerEvent('nxn-keys:server:unlocked', src, plate)
    NXN.Keys.Log(('unlock: src=%d plate=%s'):format(src, plate))
end)

-- Kulcsátadás
RegisterNetEvent('nxn-keys:server:giveKey', function(targetSrc, plate)
    local src = source
    plate = NXN.Keys.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end
    targetSrc = tonumber(targetSrc)
    if not targetSrc or targetSrc == src then return end

    -- Biztonság: küldőnek legyen kulcsa
    if not exports['nxn-keys']:hasKey(src, plate) then
        Notify(src, 'Nincs kulcsod ehhez a járműhöz!', 'danger')
        return
    end

    -- Csak tulajdonos oszthat (ha config engedélyezve)
    if Config.OnlyOwnerCanShare then
        if GetResourceState('nxn-vehicles') == 'started' then
            if not exports['nxn-vehicles']:isOwner(src, plate) then
                Notify(src, 'Csak a jármű tulajdonosa adhat kulcsot!', 'danger')
                return
            end
        end
    end

    -- Célpont már rendelkezik kulccsal?
    if exports['nxn-keys']:hasKey(targetSrc, plate) then
        Notify(src, 'Ennek a játékosnak már van kulcsa ehhez a járműhöz!', 'warning')
        return
    end

    -- Közelség ellenőrzés szerveroldalon
    local srcPed    = GetPlayerPed(src)
    local tgtPed    = GetPlayerPed(targetSrc)
    local sx, sy, sz = GetEntityCoords(srcPed)
    local tx, ty, tz = GetEntityCoords(tgtPed)
    local dist = #(vector3(sx, sy, sz) - vector3(tx, ty, tz))
    if dist > (Config.GiveKeyDistance * 2 + 2.0) then   -- 2m tolerancia
        Notify(src, 'Túl messze vagy a célpont játékostól!', 'warning')
        return
    end

    local giverName = GetPlayerName(src) or 'Ismeretlen'
    local ok = exports['nxn-keys']:giveKey(targetSrc, plate, false)
    if not ok then
        Notify(src, 'Kulcsátadás sikertelen!', 'danger')
        return
    end

    Notify(src, ('Kulcs átadva: %s'):format(plate), 'success')
    TriggerClientEvent('nxn-keys:client:keyReceived', targetSrc, { plate = plate, giverName = giverName })
    TriggerEvent('nxn-keys:server:keyGiven', src, targetSrc, plate)
    NXN.Keys.Info(('giveKey: src=%d -> target=%d plate=%s'):format(src, targetSrc, plate))
end)

-- Kulcsmegvonás (tulajdonos által)
RegisterNetEvent('nxn-keys:server:removeKey', function(targetSrc, plate)
    local src = source
    plate = NXN.Keys.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end
    targetSrc = tonumber(targetSrc)
    if not targetSrc then return end

    -- Csak tulajdonos vonhat meg
    if GetResourceState('nxn-vehicles') == 'started' then
        if not exports['nxn-vehicles']:isOwner(src, plate) then
            Notify(src, 'Csak a jármű tulajdonosa vonhat meg kulcsot!', 'danger')
            return
        end
    end

    -- Tulajdonos kulcsa védett
    if GetResourceState('nxn-vehicles') == 'started' then
        if exports['nxn-vehicles']:isOwner(targetSrc, plate) then
            Notify(src, 'A tulajdonos kulcsát nem lehet megvonni!', 'danger')
            return
        end
    end

    local removed = exports['nxn-keys']:removeKey(targetSrc, plate)
    if removed then
        Notify(src, ('Kulcs megvonva: %s'):format(plate), 'success')
        NXN.Keys.Info(('removeKey: src=%d -> target=%d plate=%s'):format(src, targetSrc, plate))
    else
        Notify(src, 'Kulcsmegvonás sikertelen (nincs ilyen kulcs?)', 'warning')
    end
end)

-- Kulcsértesítés fogadásakor kliens oldali cache kérés
RegisterNetEvent('nxn-keys:server:requestSync', function()
    local src  = source
    local keys = exports['nxn-keys']:getKeys(src)
    TriggerClientEvent('nxn-keys:client:syncKeys', src, keys)
end)
