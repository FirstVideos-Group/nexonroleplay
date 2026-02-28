-- ============================================================
--  nxn-licenses | server.lua
-- ============================================================

-- ── Cache ──────────────────────────────────────────────
--- { [src] = { [licenseId] = rowTable, ... } }
local licenseCache = {}
--- { [src] = { [licenseId] = rowTable, ... } }
local pendingCache = {}

-- ── Segédfüggvények ───────────────────────────────────────

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

local function SyncClient(src)
    local data = licenseCache[src] or {}
    local pend = pendingCache[src] or {}
    TriggerClientEvent('nxn-licenses:client:sync', src, data, pend)
    NXN.Licenses.Log(('SyncClient: src=%d'):format(src))
end

local function GenerateIdNumber(licenseType)
    local ts  = tostring(os.time()):sub(-6)
    local rnd = math.random(100, 999)
    return ('%s-%s-%s-%d'):format(Config.IdPrefix, licenseType:upper():sub(1,3), ts, rnd)
end

local function countMap(t)
    local c = 0
    for _ in pairs(t) do c = c + 1 end
    return c
end

--- Ellenőrzi, hogy az igazolvány fizikailag megvan-e az inventoryban.
--- Ha az nxn-inventory nem fut vagy Config.InventoryCheck = false, true-val tér vissza.
---@param src integer
---@param licenseType string
---@return boolean
local function HasItemInInventory(src, licenseType)
    if not Config.InventoryCheck then return true end
    if GetResourceState('nxn-inventory') ~= 'started' then
        NXN.Licenses.Warn('nxn-inventory nem fut, inventory ellenőrzés átugorva')
        return true
    end
    local def = NXN.Licenses.GetTypeDef(licenseType)
    if not def or not def.inventoryItem then
        NXN.Licenses.Warn(('HasItemInInventory: nincs inventoryItem defìniálva: %s'):format(licenseType))
        return false
    end
    local has = exports['nxn-inventory']:hasItem(src, def.inventoryItem, 1)
    NXN.Licenses.Log(('HasItemInInventory: src=%d type=%s item=%s -> %s'):format(
        src, licenseType, def.inventoryItem, tostring(has)
    ))
    return has
end

--- Item adása inventory-ba kiadáskor (ha az nxn-inventory fut).
---@param src integer
---@param licenseType string
local function GiveItemToInventory(src, licenseType)
    if not Config.InventoryCheck then return end
    if GetResourceState('nxn-inventory') ~= 'started' then return end
    local def = NXN.Licenses.GetTypeDef(licenseType)
    if not def or not def.inventoryItem then return end
    -- Ha már bent van (pl. másodlagos grantLicense), ne duplikálja
    if exports['nxn-inventory']:hasItem(src, def.inventoryItem, 1) then
        NXN.Licenses.Log(('GiveItemToInventory: már bent van: src=%d item=%s'):format(
            src, def.inventoryItem
        ))
        return
    end
    local ok, err = exports['nxn-inventory']:addItem(src, def.inventoryItem, 1)
    if ok then
        NXN.Licenses.Log(('GiveItemToInventory: OK src=%d item=%s'):format(src, def.inventoryItem))
    else
        NXN.Licenses.Warn(('GiveItemToInventory FAIL: src=%d item=%s err=%s'):format(
            src, def.inventoryItem, tostring(err)
        ))
    end
end

--- Item eltávolítása visszavonásnál
---@param src integer
---@param licenseType string
local function RemoveItemFromInventory(src, licenseType)
    if not Config.InventoryCheck then return end
    if GetResourceState('nxn-inventory') ~= 'started' then return end
    local def = NXN.Licenses.GetTypeDef(licenseType)
    if not def or not def.inventoryItem then return end
    if exports['nxn-inventory']:hasItem(src, def.inventoryItem, 1) then
        exports['nxn-inventory']:removeItem(src, def.inventoryItem, 1)
        NXN.Licenses.Log(('RemoveItemFromInventory: src=%d item=%s'):format(src, def.inventoryItem))
    end
end

-- ── Adatbázis ──────────────────────────────────────────────

local function RegisterTables()
    NXN.Licenses.Info('Adatbázis táblák regisztrálása...')
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

-- ── Betöltés ──────────────────────────────────────────────

local function LoadPlayerLicenses(src, identifier)
    NXN.Licenses.Log(('LoadPlayerLicenses: src=%d ident=%s'):format(src, identifier))

    local rows = MySQL.query.await(
        'SELECT * FROM `nxn_licenses` WHERE identifier = ? AND revoked = 0',
        { identifier }
    )
    licenseCache[src] = {}
    for _, row in ipairs(rows or {}) do
        licenseCache[src][row.license_type] = row
    end

    local preqs = MySQL.query.await(
        'SELECT * FROM `nxn_license_requests` WHERE identifier = ? AND processed = 0',
        { identifier }
    )
    pendingCache[src] = {}
    for _, row in ipairs(preqs or {}) do
        pendingCache[src][row.license_type] = row
    end

    NXN.Licenses.Log(('Betöltve: src=%d licenses=%d pending=%d'):format(
        src, countMap(licenseCache[src]), countMap(pendingCache[src])
    ))

    SyncClient(src)
    TriggerEvent('nxn-licenses:server:loaded', src)
end

-- ── Player events ─────────────────────────────────────────

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

-- ── Feldolgozó tick ─────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(Config.ProcessInterval * 1000)
        NXN.Licenses.Log('Igazolvány feldolgozó fut...')

        local now   = NXN.Licenses.NowStr()
        local ready = MySQL.query.await(
            'SELECT * FROM `nxn_license_requests` WHERE processed = 0 AND ready_at <= ?',
            { now }
        )

        for _, req in ipairs(ready or {}) do
            local def = NXN.Licenses.GetTypeDef(req.license_type)
            if def then
                local idNum  = GenerateIdNumber(req.license_type)
                local expStr = NXN.Licenses.ExpiresStr(def.validDays)

                MySQL.query.await([[
                    INSERT INTO `nxn_licenses` (identifier, license_type, id_number, issued_at, expires_at)
                    VALUES (?, ?, ?, NOW(), ?)
                    ON DUPLICATE KEY UPDATE id_number=VALUES(id_number), issued_at=NOW(), expires_at=VALUES(expires_at), revoked=0
                ]], { req.identifier, req.license_type, idNum, expStr })

                MySQL.update.await(
                    'UPDATE `nxn_license_requests` SET processed = 1 WHERE id = ?',
                    { req.id }
                )

                NXN.Licenses.Info(('Kiadva: ident=%s type=%s id=%s'):format(
                    req.identifier, req.license_type, idNum
                ))

                -- Online játékos frissítése
                for _, rawSrc in ipairs(GetPlayers()) do
                    local s     = tonumber(rawSrc)
                    local ident = exports['nxn-database']:getIdentifier(s)
                    if ident == req.identifier then

                        local newRow = MySQL.single.await(
                            'SELECT * FROM `nxn_licenses` WHERE identifier=? AND license_type=?',
                            { req.identifier, req.license_type }
                        )
                        if not newRow then
                            Wait(300)
                            newRow = MySQL.single.await(
                                'SELECT * FROM `nxn_licenses` WHERE identifier=? AND license_type=?',
                                { req.identifier, req.license_type }
                            )
                        end

                        if not licenseCache[s] then licenseCache[s] = {} end
                        licenseCache[s][req.license_type] = newRow or {
                            identifier   = req.identifier,
                            license_type = req.license_type,
                            id_number    = idNum,
                            issued_at    = os.date('!%Y-%m-%d %H:%M:%S'),
                            expires_at   = expStr,
                            revoked      = 0,
                        }

                        if pendingCache[s] then
                            pendingCache[s][req.license_type] = nil
                        end

                        -- ★ Fizikai item adása az inventory-ba
                        GiveItemToInventory(s, req.license_type)

                        SyncClient(s)

                        local def2  = NXN.Licenses.GetTypeDef(req.license_type)
                        local label = (def2 and def2.label) or req.license_type
                        NotifyPlayer(s, ('✅ Megkaptad: %s – az inventoryédba került!'):format(label), 'success')

                        NXN.Licenses.Log(('Online játékosnak küldve + item: src=%d'):format(s))
                        break
                    end
                end
            end
        end
    end
end)

-- ── Net events ─────────────────────────────────────────────

-- Igenylés
RegisterNetEvent('nxn-licenses:server:apply', function(licenseType)
    local src        = source
    local identifier = GetIdentifier(src)
    if not identifier then return end

    local def = NXN.Licenses.GetTypeDef(licenseType)
    if not def then
        NotifyPlayer(src, 'Ismeretlen igazolvány típus.', 'danger')
        return
    end

    if licenseCache[src] and licenseCache[src][licenseType] then
        if not NXN.Licenses.IsExpired(licenseCache[src][licenseType]) then
            NotifyPlayer(src, ('Érvényes %s már nálad van.'):format(def.label), 'warning')
            return
        end
    end

    if pendingCache[src] and pendingCache[src][licenseType] then
        NotifyPlayer(src, ('%s igenylésed már feldolgozás alatt.'):format(def.label), 'warning')
        return
    end

    if def.requiredAge and def.requiredAge > 0 then
        local age = GetAge(src)
        if age < def.requiredAge then
            NotifyPlayer(src, ('Minimum %d éves kor szükséges.'):format(def.requiredAge), 'danger')
            return
        end
    end

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

    local mins = math.ceil(def.processSec / 60)
    NotifyPlayer(src,
        ('Igenylés beadásra került. Kb. %d perc múlva kerül az inventory-dba.'):format(mins),
        'info'
    )
    NXN.Licenses.Info(('Igenylés: src=%d type=%s readyAt=%s'):format(src, licenseType, readyAt))
end)

-- Felmutatás
RegisterNetEvent('nxn-licenses:server:showTo', function(licenseType, targetSrc)
    local src        = source
    local identifier = GetIdentifier(src)
    if not identifier then return end

    local lic = licenseCache[src] and licenseCache[src][licenseType]
    if not lic or NXN.Licenses.IsExpired(lic) then
        NotifyPlayer(src, 'Nincs érvényes igazolványod ehhez.', 'warning')
        return
    end

    -- ★ Inventory ellenőrzés: fizikailag nálad van-e?
    if not HasItemInInventory(src, licenseType) then
        NotifyPlayer(src, 'Az igazolvány nincs nálad (inventory)!', 'warning')
        return
    end

    local identity = GetIdentity(src)
    local def      = NXN.Licenses.GetTypeDef(licenseType)

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

    TriggerClientEvent('nxn-licenses:client:viewShown', targetSrc, payload)
    NotifyPlayer(src, 'Felmutatva.', 'success')
    NXN.Licenses.Log(('showTo: src=%d -> target=%d type=%s'):format(src, targetSrc, licenseType))
end)

-- Szinkron kérés
RegisterNetEvent('nxn-licenses:server:requestSync', function()
    SyncClient(source)
end)

-- ── Resource start ──────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= Config.ResourceName then return end
    NXN.Licenses.Info('nxn-licenses elindul...')
    CreateThread(function()
        RegisterTables()
        NXN.Licenses.Info('nxn-licenses kész.')
    end)
end)

-- ── Exportok ────────────────────────────────────────────

--- Van-e érvényes igazolvány ÉS fizikailag az inventory-jában is megvan-e?
--- (Ha Config.InventoryCheck = false, csak DB-t ellenőriz)
---@param src integer
---@param licenseType string
---@return boolean
exports('hasLicense', function(src, licenseType)
    local lic = licenseCache[src] and licenseCache[src][licenseType]
    if not lic then return false end
    if NXN.Licenses.IsExpired(lic) then return false end
    -- Inventory ellenőrzés
    return HasItemInInventory(src, licenseType)
end)

--- Igazolvány DB sor visszaadása (inventory check nélkül)
---@param src integer
---@param licenseType string
---@return table|nil
exports('getLicense', function(src, licenseType)
    return licenseCache[src] and licenseCache[src][licenseType] or nil
end)

--- Összes igazolvány
---@param src integer
---@return table
exports('getAllLicenses', function(src)
    return licenseCache[src] or {}
end)

--- Visszavonás – DB + cache + inventory tárgy eltávolítása
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

    if licenseCache[src] then licenseCache[src][licenseType] = nil end

    -- ★ Fizikai item eltávolítása
    RemoveItemFromInventory(src, licenseType)

    SyncClient(src)
    NotifyPlayer(src, ('%s visszavonva.'):format(
        (NXN.Licenses.GetTypeDef(licenseType) or {}).label or licenseType
    ), 'danger')
    NXN.Licenses.Log(('revokeLicense: src=%d type=%s'):format(src, licenseType))
    return true
end)

--- Közvetlen kiadás (admin/script) – inventory itemet is ad
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

    -- ★ Fizikai item adása
    GiveItemToInventory(src, licenseType)

    SyncClient(src)
    NXN.Licenses.Log(('grantLicense: src=%d type=%s'):format(src, licenseType))
    return true
end)

--- Lejárat idő
---@param src integer
---@param licenseType string
---@return string|nil
exports('getExpiry', function(src, licenseType)
    local lic = licenseCache[src] and licenseCache[src][licenseType]
    return lic and lic.expires_at or nil
end)

--- Függő igenylés van-e
---@param src integer
---@param licenseType string
---@return boolean
exports('hasPending', function(src, licenseType)
    return pendingCache[src] and pendingCache[src][licenseType] ~= nil
end)

--- Fizikailag nála van-e az igazolvány tárgy (csak inventory check, DB nélkül)
---@param src integer
---@param licenseType string
---@return boolean
exports('hasLicenseItem', function(src, licenseType)
    return HasItemInInventory(src, licenseType)
end)
