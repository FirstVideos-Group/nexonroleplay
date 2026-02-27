-- ============================================================
--  nxn-cityhall | server.lua
-- ============================================================

-- ── Csekk cache ──────────────────────────────────────────────
--- { [src] = { {id, reason, amount, issued_at, paid} } }
local finesCache = {}

-- ── Segédfüggvények ─────────────────────────────────────────

local function GetIdentifier(src)
    if GetResourceState('nxn-database') ~= 'started' then return nil end
    return exports['nxn-database']:getIdentifier(src)
end

local function Notify(src, msg, ntype)
    if GetResourceState('nxn-notify') == 'started' then
        TriggerClientEvent('nxn-notify:client:show', src, msg, ntype or 'info')
    end
end

-- ── DB init ──────────────────────────────────────────────

AddEventHandler('onResourceStart', function(res)
    if res ~= Config.ResourceName then return end
    NXN.CityHall.Info('nxn-cityhall elindul...')
    CreateThread(function()
        if GetResourceState('nxn-database') ~= 'started' then
            NXN.CityHall.Warn('nxn-database nem fut, csekk tábla nem létrehozható')
            return
        end
        exports['nxn-database']:registerTable(Config.ResourceName, {
            name = 'nxn_fines',
            sql  = [[
                CREATE TABLE IF NOT EXISTS `nxn_fines` (
                    `id`          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
                    `identifier`  VARCHAR(60)    NOT NULL,
                    `reason`      VARCHAR(200)   NOT NULL DEFAULT '',
                    `amount`      INT UNSIGNED   NOT NULL DEFAULT 0,
                    `issued_by`   VARCHAR(60)    DEFAULT NULL COMMENT 'rendőr/NPC/server azonosító',
                    `issued_at`   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    `paid`        TINYINT(1)     NOT NULL DEFAULT 0,
                    `paid_at`     DATETIME       DEFAULT NULL,
                    PRIMARY KEY (`id`),
                    INDEX `idx_fines_ident` (`identifier`),
                    INDEX `idx_fines_paid`  (`paid`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]]
        })
        NXN.CityHall.Info('nxn_fines tábla OK.')
    end)
end)

-- ── Játékos kilép ───────────────────────────────────────────

AddEventHandler('playerDropped', function()
    finesCache[source] = nil
end)

-- ── Net events ────────────────────────────────────────────

-- Csekk lista kérés
RegisterNetEvent('nxn-cityhall:server:getFines', function()
    local src        = source
    local identifier = GetIdentifier(src)
    if not identifier then return end

    NXN.CityHall.Log(('getFines: src=%d'):format(src))

    local rows = MySQL.query.await(
        'SELECT * FROM `nxn_fines` WHERE identifier = ? AND paid = 0 ORDER BY issued_at DESC',
        { identifier }
    ) or {}

    finesCache[src] = rows
    TriggerClientEvent('nxn-cityhall:client:openFines', src, rows)
end)

-- Csekk fizetése
RegisterNetEvent('nxn-cityhall:server:payFine', function(fineId)
    local src        = source
    local identifier = GetIdentifier(src)
    if not identifier then return end

    NXN.CityHall.Log(('payFine: src=%d id=%s'):format(src, tostring(fineId)))

    -- Ellenőrzés: valami van-e
    local fine = MySQL.single.await(
        'SELECT * FROM `nxn_fines` WHERE id = ? AND identifier = ? AND paid = 0',
        { fineId, identifier }
    )

    if not fine then
        Notify(src, 'Nem található bírság.', 'warning')
        return
    end

    -- Jövőbeli pénzrendszer integráció helye:
    -- local balance = exports['nxn-bank']:getBalance(src)
    -- if balance < fine.amount then Notify(src,'Nincs elég pénzed.','danger'); return end
    -- exports['nxn-bank']:removeBalance(src, fine.amount)

    MySQL.update.await(
        'UPDATE `nxn_fines` SET paid = 1, paid_at = NOW() WHERE id = ?',
        { fineId }
    )

    Notify(src, ('✅ Bírság befizetve: $%d – %s'):format(fine.amount, fine.reason), 'success')
    TriggerClientEvent('nxn-cityhall:client:finesPaid', src, fineId)
    TriggerEvent('nxn-cityhall:server:finePaid', src, fine)
    NXN.CityHall.Info(('Fine fizetve: src=%d id=%d amount=%d'):format(src, fineId, fine.amount))
end)

-- ── Exportok (szerver) ──────────────────────────────────────

--- Bírság kiadása (például rendőrségi script által)
---@param src      integer   cél játékos
---@param reason   string    ok / leírás
---@param amount   integer   összeg ($)
---@param issuedBy string?   kiadó azonosító (nil = szerver)
---@return integer|nil   Az új fine ID
exports('issueFine', function(src, reason, amount, issuedBy)
    local identifier = GetIdentifier(src)
    if not identifier then
        NXN.CityHall.Warn('issueFine: nincs identifier')
        return nil
    end

    local id = MySQL.insert.await(
        'INSERT INTO `nxn_fines` (identifier, reason, amount, issued_by) VALUES (?, ?, ?, ?)',
        { identifier, reason or '', amount or 0, issuedBy or 'server' }
    )

    Notify(src, ('⚠️ Bírságot kaptad: $%d – %s'):format(amount, reason), 'warning')
    TriggerEvent('nxn-cityhall:server:fineIssued', src, id, reason, amount)
    NXN.CityHall.Info(('issueFine: src=%d reason=%s amount=%d id=%d'):format(
        src, reason, amount, id
    ))
    return id
end)

--- Bírság változásai – listázás
---@param src integer
---@return table
exports('getFines', function(src)
    return finesCache[src] or {}
end)

--- Bírság visszavonása
---@param fineId integer
---@return boolean
exports('revokeFine', function(fineId)
    local affected = MySQL.update.await(
        'UPDATE `nxn_fines` SET paid = 1, paid_at = NOW() WHERE id = ?',
        { fineId }
    )
    NXN.CityHall.Log(('revokeFine: id=%d affected=%d'):format(fineId, affected or 0))
    return (affected or 0) > 0
end)

--- Osszes fizetetlen bírság összege
---@param src integer
---@return integer
exports('getTotalFines', function(src)
    local identifier = GetIdentifier(src)
    if not identifier then return 0 end
    local row = MySQL.single.await(
        'SELECT COALESCE(SUM(amount),0) as total FROM `nxn_fines` WHERE identifier=? AND paid=0',
        { identifier }
    )
    return (row and row.total) or 0
end)

--- Van-e ki nem fizetett bírság
---@param src integer
---@return boolean
exports('hasUnpaidFines', function(src)
    local identifier = GetIdentifier(src)
    if not identifier then return false end
    local row = MySQL.single.await(
        'SELECT COUNT(*) as cnt FROM `nxn_fines` WHERE identifier=? AND paid=0',
        { identifier }
    )
    return (row and row.cnt or 0) > 0
end)
