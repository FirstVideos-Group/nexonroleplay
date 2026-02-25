-- ============================================================
--  nxn-database | server.lua
--  FIX: race condition – playerDropped hamarabb fut mint LoadPlayer
--       befejez – pendingLoad flag + SavePlayer DB fallback
-- ============================================================

-- ── Belso cache ─────────────────────────────────────────────
--- Memoraban tarolt jatekosadatok { [src] = playerData }
local playerCache  = {}
local joinTimes    = {}
--- pendingLoad: igaz amig a LoadPlayer DB-lekerdezese folyamatban van
--- Ha playerDropped erkezik kozben, megvarja a betoltest majd ment.
local pendingLoad  = {}

-- ── Segdfüggvenyek ──────────────────────────────────────────

---@param src number
---@return string|nil
local function GetIdent(src)
    local identType = Config.IdentifierType
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:find(identType .. ':') then
            NXN.DB.Log(('Identifier found: src=%d id=%s'):format(src, id))
            return id
        end
    end
    NXN.DB.Warn(('No identifier "%s" for src=%d'):format(identType, src))
    return nil
end

---@return string
local function NowTimestamp()
    return os.date('!%Y-%m-%d %H:%M:%S')
end

-- ── Auto-migrate ─────────────────────────────────────────────

local function RunMigrations()
    if not Config.AutoMigrate then
        NXN.DB.Log('AutoMigrate letiltva, kihagyva.')
        return
    end
    NXN.DB.Info('Migraciok futtatasa...')
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `nxn_players` (
            `id`             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `identifier`     VARCHAR(60)   NOT NULL UNIQUE,
            `name`           VARCHAR(60)   NOT NULL DEFAULT 'Unknown',
            `first_joined`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `last_online`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `total_playtime` INT UNSIGNED  NOT NULL DEFAULT 0,
            `metadata`       LONGTEXT      DEFAULT NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
    NXN.DB.Info(('Tabla OK: %s'):format(Config.PlayersTable))
end

-- ── Jatekos betoltese / letrehozasa ────────────────────────────

---@param src number
---@param identifier string
---@param playerName string
local function LoadPlayer(src, identifier, playerName)
    NXN.DB.Log(('LoadPlayer: src=%d ident=%s name=%s'):format(src, identifier, playerName))
    pendingLoad[src] = true   -- jelzi hogy DB muvelet folyamatban

    local row = MySQL.single.await(
        'SELECT * FROM `' .. Config.PlayersTable .. '` WHERE identifier = ?',
        { identifier }
    )
    local now = NowTimestamp()

    if row then
        MySQL.update.await(
            'UPDATE `' .. Config.PlayersTable .. '` SET `name` = ?, `last_online` = ? WHERE `identifier` = ?',
            { playerName, now, identifier }
        )
        row.name        = playerName
        row.last_online = now
        playerCache[src] = row
        NXN.DB.Log(('Betoltve DB-bol: %s'):format(identifier))
    else
        local insertId = MySQL.insert.await(
            'INSERT INTO `' .. Config.PlayersTable .. '` (`identifier`, `name`, `first_joined`, `last_online`) VALUES (?, ?, ?, ?)',
            { identifier, playerName, now, now }
        )
        playerCache[src] = {
            id             = insertId,
            identifier     = identifier,
            name           = playerName,
            first_joined   = now,
            last_online    = now,
            total_playtime = 0,
            metadata       = nil,
        }
        NXN.DB.Info(('Uj jatekos: %s (DB id=%d)'):format(identifier, insertId))
    end

    pendingLoad[src] = false   -- DB muvelet kesz
    TriggerEvent('nxn-database:server:playerLoaded', src, playerCache[src])
end

-- ── Jatekos mentese disconnect-kor ────────────────────────────
-- FIX: Race condition - ha LoadPlayer meg fut (pendingLoad=true),
-- megvarjuk amig befejezi, azutan mentunk.
-- Ha valami miatt a cache meg mindig nil (pl. DB hiba a betoltesnel),
-- DB fallback: csak last_online-t frissitjuk identifier alapjan.

---@param src number
---@param joinTime number
local function SavePlayer(src, joinTime)
    -- Varakozas ha a betoltes meg folyamatban van (max 10 masodperc)
    local waited = 0
    while pendingLoad[src] == true and waited < 10000 do
        Wait(100)
        waited = waited + 100
    end
    if waited > 0 then
        NXN.DB.Log(('SavePlayer: %dms varakozas a betoltesre (src=%d)'):format(waited, src))
    end

    local data = playerCache[src]
    local now  = NowTimestamp()

    if data then
        -- Normalis ut: cache-bol mentunk
        local sessionSeconds = os.time() - (joinTime or os.time())
        MySQL.update.await(
            'UPDATE `' .. Config.PlayersTable .. '` SET `last_online` = ?, `total_playtime` = `total_playtime` + ? WHERE `identifier` = ?',
            { now, sessionSeconds, data.identifier }
        )
        NXN.DB.Log(('Elmentve: %s | session=%ds'):format(data.identifier, sessionSeconds))
    else
        -- Fallback: cache nincs (pl. DB hiba betoltesnel vagy 10mp timeout)
        -- Legalabb last_online-t frissitjuk identifier alapjan ha van
        local identifier = GetIdent(src)
        if identifier then
            MySQL.update.await(
                'UPDATE `' .. Config.PlayersTable .. '` SET `last_online` = ? WHERE `identifier` = ?',
                { now, identifier }
            )
            NXN.DB.Warn(('SavePlayer fallback (nincs cache): last_online frissitve, identifier=%s'):format(identifier))
        else
            NXN.DB.Warn(('SavePlayer: nincs cache ES nincs identifier, src=%d, kihagyva'):format(src))
        end
    end

    playerCache[src] = nil
    pendingLoad[src] = nil
end

-- ── Esemenykezelok ─────────────────────────────────────────────

AddEventHandler('playerConnecting', function(name, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    local identifier = GetIdent(src)
    if not identifier then
        deferrals.done('[nxn-database] Nem sikerult azonositani. Probald ujra.')
        return
    end
    deferrals.done()
end)

AddEventHandler('playerActivated', function()
    local src        = source
    local identifier = GetIdent(src)
    if not identifier then
        NXN.DB.Warn(('playerActivated: nincs identifier, src=%d'):format(src))
        return
    end
    local playerName = GetPlayerName(src) or 'Unknown'
    joinTimes[src]   = os.time()
    CreateThread(function()
        LoadPlayer(src, identifier, playerName)
    end)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    NXN.DB.Log(('playerDropped: src=%d reason=%s'):format(src, tostring(reason)))
    local jt = joinTimes[src]
    joinTimes[src] = nil
    CreateThread(function()
        SavePlayer(src, jt)
    end)
end)

-- ── Heartbeat ─────────────────────────────────────────────────

if Config.HeartbeatInterval and Config.HeartbeatInterval > 0 then
    CreateThread(function()
        while true do
            Wait(Config.HeartbeatInterval * 1000)
            local now = NowTimestamp()
            for src, data in pairs(playerCache) do
                MySQL.update(
                    'UPDATE `' .. Config.PlayersTable .. '` SET `last_online` = ? WHERE `identifier` = ?',
                    { now, data.identifier }
                )
                NXN.DB.Log(('Heartbeat: %s'):format(data.identifier))
            end
        end
    end)
end

-- ── Resource start ─────────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= Config.ResourceName then return end
    NXN.DB.Info('nxn-database elindul, migraciok...')
    CreateThread(function()
        RunMigrations()
        NXN.DB.Info('nxn-database kesz.')
    end)
end)

-- ── Exportok ─────────────────────────────────────────────────

exports('getPlayer', function(src)
    local data = playerCache[src]
    NXN.DB.Log(('getPlayer: src=%d found=%s'):format(src, tostring(data ~= nil)))
    return data
end)

exports('getIdentifier', function(src)
    local data = playerCache[src]
    return data and data.identifier or nil
end)

exports('getAllPlayers', function()
    return playerCache
end)

exports('getPlayerByIdentifier', function(identifier, cb)
    NXN.DB.Log(('getPlayerByIdentifier: %s'):format(identifier))
    MySQL.single(
        'SELECT * FROM `' .. Config.PlayersTable .. '` WHERE identifier = ?',
        { identifier },
        function(row) cb(row) end
    )
end)

exports('getMeta', function(src, key)
    local data = playerCache[src]
    if not data or not data.metadata then return nil end
    local ok, decoded = pcall(json.decode, data.metadata)
    if not ok then
        NXN.DB.Warn(('getMeta: JSON decode hiba src=%d'):format(src))
        return nil
    end
    return decoded[key]
end)

exports('setMeta', function(src, key, value)
    local data = playerCache[src]
    if not data then
        NXN.DB.Warn(('setMeta: nincs cache src=%d'):format(src))
        return false
    end
    local decoded = {}
    if data.metadata then
        local ok, d = pcall(json.decode, data.metadata)
        if ok then decoded = d end
    end
    decoded[key] = value
    local encoded = json.encode(decoded)
    data.metadata    = encoded
    playerCache[src] = data
    MySQL.update(
        'UPDATE `' .. Config.PlayersTable .. '` SET `metadata` = ? WHERE `identifier` = ?',
        { encoded, data.identifier }
    )
    NXN.DB.Log(('setMeta: src=%d key=%s'):format(src, key))
    return true
end)

exports('queryAllPlayers', function(cb)
    MySQL.query(
        'SELECT `id`, `identifier`, `name`, `first_joined`, `last_online`, `total_playtime` FROM `'
        .. Config.PlayersTable .. '` ORDER BY `last_online` DESC',
        {},
        function(rows) cb(rows or {}) end
    )
end)

exports('registerTable', function(resourceName, tableInfo)
    if not tableInfo or not tableInfo.sql then
        NXN.DB.Warn(('registerTable: hianyos tableInfo a "%s" resource-tol'):format(resourceName))
        return false
    end
    NXN.DB.Info(('Tabla regisztralva: %s (forras: %s)'):format(tableInfo.name or '?', resourceName))
    MySQL.query.await(tableInfo.sql)
    return true
end)
