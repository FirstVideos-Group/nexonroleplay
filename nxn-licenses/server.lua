-- ============================================================
--  nxn-licenses | server.lua
-- ============================================================

-- ── Cache ──────────────────────────────────────────────────
--- { [src] = { [licenseId] = rowTable, ... } }
local licenseCache  = {}
--- { [src] = { [licenseId] = rowTable, ... } }
local pendingCache  = {}

-- ── Segédfüggvények ─────────────────────────────────────────

local function GetIdentifier(src)
    return exports['nxn-database']:getIdentifier(src)
end

local function GetIdentity(src)
    if GetResourceState('nxn-identity') == 'started' then
        return exports['nxn-identity']:getIdentity(src)
    end
    return nil
end

local function GetAge(src)
    if GetResourceState('nxn-identity') == 'started' then
        return exports['nxn-identity']:getAge(src) or 0
    end
    return 0
end

local function NotifyPlayer(src, msg, ntype)
    if GetResourceState('nxn-notify') == 'started' then
        TriggerClientEvent('nxn-notify:client:show', src, msg, ntype or 'info')
    end
end

--- Ügyfél adatok a kliensnek (teljes lista)
local function SyncClient(src)
    local data = licenseCache[src]  or {}
    local pend = pendingCache[src]  or {}
    TriggerClientEvent('nxn-licenses:client:sync', src, data, pend)
    NXN.Licenses.Log(('SyncClient: src=%d'):format(src))
end

--- Egyedi igazolvány ID szám generlása
local function GenerateIdNumber(licenseType)
    local ts  = tostring(os.time()):sub(-6)
    local rnd = math.random(100, 999)
    return ('%s-%s-%s-%d'):format(Config.IdPrefix, licenseType:upper():sub(1,3), ts, rnd)
end

--- Táblázat bejegyzéseinek számlálása (pairs alapon, mert string kulcsú map)
local function countMap(t)
    local c = 0
    for _ in pairs(t) do c = c + 1 end
    return c
end

-- ── Adatbázis ─────────────────────────────────────────────

local function RegisterTables()
    NXN.Licenses.Info('Adatbázis táblák regisztrálása...')

    -- Kiadott igazolványok
    exports['nxn-database']:registerTable(Config.ResourceName, {
        name = 'nxn_licenses',
        sql  = [[
            CREATE TABLE IF NOT EXISTS `nxn_licenses` (
                `id`           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
                `identifier`   VARCHAR(60)   NOT NULL,
                `license_type` VARCHAR(40)   NOT NULL,
                `id_number`    VARCHAR(40)   NOT NULL,
                `issued_at`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `expires_at`   DATETIME      DEFAULT NULL,
                `revoked`      TINYINT(1)    NOT NULL DEFAULT 0,
                PRIMARY KEY (`id`),
                UNIQUE KEY `uk_ident_type` (`identifier`, `license_type`),
                INDEX `idx_lic_ident` (`identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]]
    })

    -- Függő igénylések
    exports['nxn-database']:registerTable(Config.ResourceName, {
        name = 'nxn_license_requests',
        sql  = [[
            CREATE TABLE IF NOT EXISTS `nxn_license_requests` (
                `id`           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
                `identifier`   VARCHAR(60)   NOT NULL,
                `license_type` VARCHAR(40)   NOT NULL,
                `ready_at`     DATETIME      NOT NULL,
                `processed`    TINYINT(1)    NOT NULL DEFAULT 0,
                `created_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                INDEX `idx_req_ident`  (`identifier`),
                INDEX `idx_req_ready`  (`ready_at`),
                INDEX `idx_req_proc`   (`processed`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]]
    })

    NXN.Licenses.Info('Táblák OK.')
end

-- ── Betöltés ───────────────────────────────────────────────

local function LoadPlayerLicenses(src, identifier)
    NXN.Licenses.Log(('LoadPlayerLicenses: src=%d ident=%s'):format(src, identifier))

    -- Kiadott igazolványok
    local rows = MySQL.query.await(
        'SELECT * FROM `nxn_licenses` WHERE identifier = ? AND revoked = 0',
        { identifier }
    )
    licenseCache[src] = {}
    for _, row in ipairs(rows or {}) do
        licenseCache[src][row.license_type] = row
    end

    -- Függő igénylések
    local preqs = MySQL.query.await(
        'SELECT * FROM `nxn_license_requests` WHERE identifier = ? AND processed = 0',
        { identifier }
    )
    pendingCache[src] = {}
    for _, row in ipairs(preqs or {}) do
        pendingCache[src][row.license_type] = row
    end

    -- countMap használata: a cache string-kulcsú map, a # operátor számon nem működik
    NXN.Licenses.Log(('Betöltve: src=%d licenses=%d pending=%d'):format(
        src,
        countMap(licenseCache[src]),
        countMap(pendingCache[src])
    ))

    SyncClient(src)
    TriggerEvent('nxn-licenses:server:loaded', src)
end

-- ── nxn-database: playerLoaded ──────────────────────────────

AddEventHandler('nxn-database:server:playerLoaded', function(src, playerData)
    NXN.Licenses.Log(('playerLoaded: src=%d'):format(src))
    CreateThread(function()
        LoadPlayerLicenses(src, playerData.identifier)
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    licenseCache[src] = nil
    pendingCache[src] = nil
    NXN.Licenses.Log(('playerDropped cleanup: src=%d'):format(src))
end)

-- ── Igénylés feldolgozó tick ─────────────────────────────────
-- Minden processInterval másodpercben megnézi, hogy valamelyik igénylés
-- ready_at elérte-e az aktuális időt – ha igen, kiadja az igazolványt.

CreateThread(function()
    while true do
        Wait(Config.ProcessInterval * 1000)
        NXN.Licenses.Log('Igénylés feldolgozó fut...')

        local now = NXN.Licenses.NowStr()

        -- DB-ből lekérdezük az összes érett igénylést
        local ready = MySQL.query.await(
            'SELECT * FROM `nxn_license_requests` WHERE processed = 0 AND ready_at <= ?',
            { now }
        )

        for _, req in ipairs(ready or {}) do
            local def = NXN.Licenses.GetTypeDef(req.license_type)
            if def then
                local idNum  = GenerateIdNumber(req.license_type)
                local expStr = NXN.Licenses.ExpiresStr(def.validDays)

                -- INSERT OR UPDATE (UPSERT)
                MySQL.query.await([[
                    INSERT INTO `nxn_licenses` (identifier, license_type, id_number, issued_at, expires_at)
                    VALUES (?, ?, ?, NOW(), ?)
                    ON DUPLICATE KEY UPDATE id_number=VALUES(id_number), issued_at=NOW(), expires_at=VALUES(expires_at), revoked=0
                ]], { req.identifier, req.license_type, idNum, expStr })

                -- Igénylés lezárása
                MySQL.update.await(
                    'UPDATE `nxn_license_requests` SET processed = 1 WHERE id = ?',
                    { req.id }
                )

                NXN.Licenses.Info(('Igazolvány kiadva: ident=%s type=%s idNum=%s'):format(
                    req.identifier, req.license_type, idNum
                ))

                -- Online-e a játékos?
                for _, src in ipairs(GetPlayers()) do
                    local src = tonumber(src)
                    local ident = exports['nxn-database']:getIdentifier(src)
                    if ident == req.identifier then

                        -- Cache frissítés – nil guard: INSERT és SELECT között race condition lehetséges
                        local newRow = MySQL.single.await(
                            'SELECT * FROM `nxn_licenses` WHERE identifier=? AND license_type=?',
                            { req.identifier, req.license_type }
                        )

                        -- Ha az INSERT még nem commitált, 300ms után újra próbáljuk
                        if not newRow then
                            Wait(300)
                            newRow = MySQL.single.await(
                                'SELECT * FROM `nxn_licenses` WHERE identifier=? AND license_type=?',
                                { req.identifier, req.license_type }
                            )
                        end

                        if not licenseCache[src] then licenseCache[src] = {} end

                        if newRow then
                            -- Normál eset: DB sor megvan
                            licenseCache[src][req.license_type] = newRow
                        else
                            -- Fallback: minimális in-memory sor, hogy a cache ne maradjon nil-es
                            licenseCache[src][req.license_type] = {
                                identifier   = req.identifier,
                                license_type = req.license_type,
                                id_number    = idNum,
                                issued_at    = os.date('!%Y-%m-%d %H:%M:%S'),
                                expires_at   = expStr,
                                revoked      = 0,
                            }
                            NXN.Licenses.Warn(('newRow nil volt, fallback cache: src=%d type=%s'):format(
                                src, req.license_type
                            ))
                        end

                        if pendingCache[src] then
                            pendingCache[src][req.license_type] = nil
                        end

                        SyncClient(src)

                        -- def2 nil guard: GetTypeDef edge case-re
                        local def2  = NXN.Licenses.GetTypeDef(req.license_type)
                        local label = (def2 and def2.label) or req.license_type
                        NotifyPlayer(src, ('✅ Megkaptad: %s'):format(label), 'success')

                        NXN.Licenses.Log(('Online játékosnak küldve: src=%d'):format(src))
                        break
                    end
                end
            end
        end
    end
end)

-- ── Net events ─────────────────────────────────────────────

-- Igénylés beadása (kliens)
RegisterNetEvent('nxn-licenses:server:apply', function(licenseType)
    local src        = source
    local identifier = GetIdentifier(src)
    if not identifier then return end

    local def = NXN.Licenses.GetTypeDef(licenseType)
    if not def then
        NotifyPlayer(src, 'Ismeretlen igazolvány típus.', 'danger')
        return
    end

    -- Korlét: van-e már ilyen?
    if licenseCache[src] and licenseCache[src][licenseType] then
        local existing = licenseCache[src][licenseType]
        if not NXN.Licenses.IsExpired(existing) then
            NotifyPlayer(src, ('Érvényes %s már nálad van.'):format(def.label), 'warning')
            return
        end
    end

    -- Függőben van-e már?
    if pendingCache[src] and pendingCache[src][licenseType] then
        NotifyPlayer(src, ('%s igénylésed már feldolgozás alatt.'):format(def.label), 'warning')
        return
    end

    -- Kor ellenőrzés
    if def.requiredAge and def.requiredAge > 0 then
        local age = GetAge(src)
        if age < def.requiredAge then
            NotifyPlayer(src, ('Minimum %d éves kor szükséges.'):format(def.requiredAge), 'danger')
            return
        end
    end

    -- Igénylés beadása
    local readyAt = os.date('!%Y-%m-%d %H:%M:%S', os.time() + def.processSec)

    local insertId = MySQL.insert.await(
        'INSERT INTO `nxn_license_requests` (identifier, license_type, ready_at) VALUES (?, ?, ?)',
        { identifier, licenseType, readyAt }
    )

    if not pendingCache[src] then pendingCache[src] = {} end
    pendingCache[src][licenseType] = {
        id           = insertId,
        identifier   = identifier,
        license_type = licenseType,
        ready_at     = readyAt,
        processed    = 0,
    }

    SyncClient(src)
    NXN.Licenses.Info(('Igénylés beadása: src=%d type=%s readyAt=%s'):format(src, licenseType, readyAt))

    local mins = math.ceil(def.processSec / 60)
    NotifyPlayer(src,
        ('Igénylés beadásra került. Kb. %d perc múlva érhető el.'):format(mins),
        'info'
    )
end)

-- Igazolvány felmutatása (megmutatom másnak)
RegisterNetEvent('nxn-licenses:server:showTo', function(licenseType, targetSrc)
    local src        = source
    local identifier = GetIdentifier(src)
    if not identifier then return end

    -- Van-e ilyen érvényes igazolvány?
    local lic = licenseCache[src] and licenseCache[src][licenseType]
    if not lic or NXN.Licenses.IsExpired(lic) then
        NotifyPlayer(src, 'Nincs érvényes igazolványod ehhez.', 'warning')
        return
    end

    -- Identity adatok lekérése az nxn-identity-ből
    local identity = GetIdentity(src)
    local def      = NXN.Licenses.GetTypeDef(licenseType)

    -- Adatcsomag a céljátékos számára
    local payload = {
        licenseType = licenseType,
        def         = def,
        license     = lic,
        ownerName   = identity and ((identity.firstname or '') .. ' ' .. (identity.lastname or '')) or 'Ismeretlen',
        birthdate   = identity and ('%04d.%02d.%02d'):format(
            identity.birth_year or 0, identity.birth_month or 0, identity.birth_day or 0
        ) or '?',
        gender      = identity and (identity.gender == 0 and 'Férfi' or 'Nő') or '?',
        showedBy    = src,
    }

    -- Elküldi a céljátékosnak
    TriggerClientEvent('nxn-licenses:client:viewShown', targetSrc, payload)
    NotifyPlayer(src, 'Felmutatva.', 'success')
    NXN.Licenses.Log(('showTo: src=%d -> target=%d type=%s'):format(src, targetSrc, licenseType))
end)

-- Szinkronizáció kérés
RegisterNetEvent('nxn-licenses:server:requestSync', function()
    SyncClient(source)
end)

-- ── Resource start ───────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= Config.ResourceName then return end
    NXN.Licenses.Info('nxn-licenses elindul...')
    CreateThread(function()
        RegisterTables()
        NXN.Licenses.Info('nxn-licenses kész.')
    end)
end)

-- ── Exportok ──────────────────────────────────────────────

--- Van-e érvényes adott típusú igazolvány
---@param src integer
---@param licenseType string
---@return boolean
exports('hasLicense', function(src, licenseType)
    local lic = licenseCache[src] and licenseCache[src][licenseType]
    if not lic then return false end
    return not NXN.Licenses.IsExpired(lic)
end)

--- Igazolvány adat visszaadása
---@param src integer
---@param licenseType string
---@return table|nil
exports('getLicense', function(src, licenseType)
    return licenseCache[src] and licenseCache[src][licenseType] or nil
end)

--- Összes igazolvány visszaadása
---@param src integer
---@return table
exports('getAllLicenses', function(src)
    return licenseCache[src] or {}
end)

--- Visszavonás (pl. rendőrségi script)
---@param src integer
---@param licenseType string
---@return boolean
exports('revokeLicense', function(src, licenseType)
    local identifier = GetIdentifier(src)
    if not identifier then return false end

    MySQL.update(
        'UPDATE `nxn_licenses` SET revoked=1 WHERE identifier=? AND license_type=?',
        { identifier, licenseType }
    )

    if licenseCache[src] then
        licenseCache[src][licenseType] = nil
    end
    SyncClient(src)
    NotifyPlayer(src, ('%s visszavonva.'):format(
        (NXN.Licenses.GetTypeDef(licenseType) or {}).label or licenseType
    ), 'danger')
    NXN.Licenses.Log(('revokeLicense: src=%d type=%s'):format(src, licenseType))
    return true
end)

--- Közvetlen igazolvány kiadás (admin/script által)
---@param src integer
---@param licenseType string
---@return boolean
exports('grantLicense', function(src, licenseType)
    local identifier = GetIdentifier(src)
    if not identifier then return false end
    local def = NXN.Licenses.GetTypeDef(licenseType)
    if not def then return false end

    local idNum  = GenerateIdNumber(licenseType)
    local expStr = NXN.Licenses.ExpiresStr(def.validDays)

    MySQL.query.await([[
        INSERT INTO `nxn_licenses` (identifier, license_type, id_number, issued_at, expires_at)
        VALUES (?, ?, ?, NOW(), ?)
        ON DUPLICATE KEY UPDATE id_number=VALUES(id_number), issued_at=NOW(), expires_at=VALUES(expires_at), revoked=0
    ]], { identifier, licenseType, idNum, expStr })

    local newRow = MySQL.single.await(
        'SELECT * FROM `nxn_licenses` WHERE identifier=? AND license_type=?',
        { identifier, licenseType }
    )
    if not licenseCache[src] then licenseCache[src] = {} end
    licenseCache[src][licenseType] = newRow
    SyncClient(src)
    NXN.Licenses.Log(('grantLicense: src=%d type=%s'):format(src, licenseType))
    return true
end)

--- Lejarat idő visszaadása
---@param src integer
---@param licenseType string
---@return string|nil
exports('getExpiry', function(src, licenseType)
    local lic = licenseCache[src] and licenseCache[src][licenseType]
    return lic and lic.expires_at or nil
end)

--- Függő igénylés van-e
---@param src integer
---@param licenseType string
---@return boolean
exports('hasPending', function(src, licenseType)
    return pendingCache[src] and pendingCache[src][licenseType] ~= nil
end)
