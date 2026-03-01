-- ============================================================
--  nxn-finance | server.lua
-- ============================================================

-- ── Cache ───────────────────────────────────────────────────
--- { [src] = { cash = N, bank = N } }
local balanceCache = {}

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

local function PushUpdate(src)
    local b = balanceCache[src]
    if not b then return end
    TriggerClientEvent('nxn-finance:client:updated', src, { cash = b.cash, bank = b.bank })
end

local function ValidType(t)
    return t and Config.MoneyTypes[t] ~= nil
end

local function ResolveType(t)
    if ValidType(t) then return t end
    return Config.DefaultType
end

-- ── DB init ─────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(res)
    if res ~= Config.ResourceName then return end
    NXN.Finance.Info('nxn-finance elindul...')

    CreateThread(function()
        Wait(500)
        if GetResourceState('nxn-database') ~= 'started' then
            NXN.Finance.Warn('nxn-database nem fut, táblák nem hozhatók létre')
            return
        end

        exports['nxn-database']:registerTable(Config.ResourceName, {
            name = 'nxn_finance',
            sql  = [[
                CREATE TABLE IF NOT EXISTS `nxn_finance` (
                    `id`          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
                    `identifier`  VARCHAR(60)    NOT NULL,
                    `cash`        INT UNSIGNED   NOT NULL DEFAULT 500,
                    `bank`        INT UNSIGNED   NOT NULL DEFAULT 2500,
                    `updated_at`  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    PRIMARY KEY (`id`),
                    UNIQUE KEY `ux_finance_ident` (`identifier`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]]
        })

        exports['nxn-database']:registerTable(Config.ResourceName, {
            name = 'nxn_finance_log',
            sql  = [[
                CREATE TABLE IF NOT EXISTS `nxn_finance_log` (
                    `id`          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
                    `identifier`  VARCHAR(60)    NOT NULL,
                    `type`        ENUM('cash','bank') NOT NULL DEFAULT 'cash',
                    `action`      ENUM('add','remove','set','transfer') NOT NULL,
                    `amount`      INT            NOT NULL,
                    `reason`      VARCHAR(200)   DEFAULT NULL,
                    `issued_by`   VARCHAR(60)    DEFAULT NULL,
                    `created_at`  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (`id`),
                    INDEX `idx_log_ident`   (`identifier`),
                    INDEX `idx_log_created` (`created_at`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]]
        })

        NXN.Finance.Info('DB táblák OK.')
    end)
end)

-- ── Játékos csatlakozás / betöltés ──────────────────────────

AddEventHandler('playerSpawned', function()
    local src = source
    if balanceCache[src] then return end  -- már betöltve
    local identifier = GetIdentifier(src)
    if not identifier then return end

    local row = MySQL.single.await(
        'SELECT cash, bank FROM `nxn_finance` WHERE identifier = ?',
        { identifier }
    )

    if row then
        balanceCache[src] = { cash = row.cash, bank = row.bank }
    else
        local defaults = {}
        for k, v in pairs(Config.MoneyTypes) do defaults[k] = v.default end
        MySQL.insert.await(
            'INSERT INTO `nxn_finance` (identifier, cash, bank) VALUES (?, ?, ?)',
            { identifier, defaults.cash or 500, defaults.bank or 2500 }
        )
        balanceCache[src] = { cash = defaults.cash or 500, bank = defaults.bank or 2500 }
    end

    PushUpdate(src)
    NXN.Finance.Log(('Egyenleg betöltve: src=%d cash=%d bank=%d'):format(
        src, balanceCache[src].cash, balanceCache[src].bank
    ))
end)

-- ── Játékos kilép ───────────────────────────────────────────

AddEventHandler('playerDropped', function()
    local src        = source
    local identifier = GetIdentifier(src)
    local b          = balanceCache[src]
    if identifier and b then
        MySQL.update.await(
            'UPDATE `nxn_finance` SET cash = ?, bank = ? WHERE identifier = ?',
            { b.cash, b.bank, identifier }
        )
    end
    balanceCache[src] = nil
end)

-- ── Periodikus mentés ───────────────────────────────────────

CreateThread(function()
    while true do
        Wait(Config.SaveInterval)
        for src, b in pairs(balanceCache) do
            local identifier = GetIdentifier(src)
            if identifier then
                MySQL.update(
                    'UPDATE `nxn_finance` SET cash = ?, bank = ? WHERE identifier = ?',
                    { b.cash, b.bank, identifier }
                )
            end
        end
        NXN.Finance.Log('Periodikus mentés kész.')
    end
end)

-- ── Belső napló ─────────────────────────────────────────────

local function WriteLog(identifier, moneyType, action, amount, reason, issuedBy)
    MySQL.insert(
        'INSERT INTO `nxn_finance_log` (identifier, type, action, amount, reason, issued_by) VALUES (?,?,?,?,?,?)',
        { identifier, moneyType, action, amount, reason or '', issuedBy or 'server' }
    )
end

-- ── Net events (ATM / Bank műveletek) ───────────────────────

RegisterNetEvent('nxn-finance:server:deposit', function(amount)
    local src = source
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end

    local b = balanceCache[src]
    if not b then return end
    if b.cash < amount then
        Notify(src, ('Nincs elég készpénzed! (Szükséges: $%d)'):format(amount), 'danger')
        return
    end

    b.cash = b.cash - amount
    b.bank = b.bank + amount
    PushUpdate(src)

    local ident = GetIdentifier(src)
    WriteLog(ident, 'cash', 'remove', amount, 'Bankbetét', 'player')
    WriteLog(ident, 'bank', 'add',    amount, 'Bankbetét', 'player')

    Notify(src, ('Befizetted: $%d – Bankegyenleg: $%d'):format(amount, b.bank), 'success')
    TriggerEvent('nxn-finance:server:moneyChanged', src, 'bank', 'add', amount, b.bank)
end)

RegisterNetEvent('nxn-finance:server:withdraw', function(amount)
    local src = source
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end

    local b = balanceCache[src]
    if not b then return end
    if b.bank < amount then
        Notify(src, ('Nincs elég pénz a bankban! (Szükséges: $%d)'):format(amount), 'danger')
        return
    end

    b.bank = b.bank - amount
    b.cash = b.cash + amount
    PushUpdate(src)

    local ident = GetIdentifier(src)
    WriteLog(ident, 'bank', 'remove', amount, 'Bankfelvét', 'player')
    WriteLog(ident, 'cash', 'add',    amount, 'Bankfelvét', 'player')

    Notify(src, ('Felvetted: $%d – Készpénz: $%d'):format(amount, b.cash), 'success')
    TriggerEvent('nxn-finance:server:moneyChanged', src, 'cash', 'add', amount, b.cash)
end)

RegisterNetEvent('nxn-finance:server:transfer', function(targetId, amount, reason)
    local src    = source
    amount       = math.floor(tonumber(amount) or 0)
    targetId     = tonumber(targetId)

    if not targetId or targetId == src or amount < Config.MinTransferAmount then return end

    local bFrom = balanceCache[src]
    local bTo   = balanceCache[targetId]
    if not bFrom then return end
    if not bTo then
        Notify(src, 'A célszemély nem érhető el.', 'danger')
        return
    end
    if bFrom.bank < amount then
        Notify(src, ('Nincs elég pénz a bankban! (Szükséges: $%d)'):format(amount), 'danger')
        return
    end

    bFrom.bank = bFrom.bank - amount
    bTo.bank   = bTo.bank   + amount
    PushUpdate(src)
    PushUpdate(targetId)

    local identFrom = GetIdentifier(src)
    local identTo   = GetIdentifier(targetId)
    local desc      = reason or 'Átutalás'
    WriteLog(identFrom, 'bank', 'transfer', -amount, desc, identTo)
    WriteLog(identTo,   'bank', 'transfer',  amount, desc, identFrom)

    local senderName = GetPlayerName(src)
    Notify(src,      ('Átutalás sikeres: -$%d → %s'):format(amount, GetPlayerName(targetId)), 'success')
    Notify(targetId, ('Átutalás érkezett: +$%d – %s'):format(amount, senderName), 'success')
    TriggerEvent('nxn-finance:server:moneyChanged', src, 'bank', 'transfer', amount, bFrom.bank)
end)

-- ── Exportok (szerver) ──────────────────────────────────────

--- Egyenleg lekérése
exports('getMoney', function(src, moneyType)
    local b = balanceCache[src]
    if not b then return 0 end
    local t = ResolveType(moneyType)
    return b[t] or 0
end)

--- Összes egyenleg
exports('getBalances', function(src)
    local b = balanceCache[src]
    if not b then return { cash = 0, bank = 0 } end
    return { cash = b.cash, bank = b.bank }
end)

--- Van-e elegendő pénze
exports('hasMoney', function(src, amount, moneyType)
    local b = balanceCache[src]
    if not b then return false end
    local t = ResolveType(moneyType)
    return (b[t] or 0) >= (tonumber(amount) or 0)
end)

--- Pénz hozzáadása
exports('addMoney', function(src, amount, moneyType, reason, issuedBy)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local b = balanceCache[src]
    if not b then return false end
    local t = ResolveType(moneyType)
    b[t] = b[t] + amount
    PushUpdate(src)
    local ident = GetIdentifier(src)
    if ident then WriteLog(ident, t, 'add', amount, reason, issuedBy) end
    TriggerEvent('nxn-finance:server:moneyChanged', src, t, 'add', amount, b[t])
    return true
end)

--- Pénz levonása – false ha nincs elég
exports('removeMoney', function(src, amount, moneyType, reason, issuedBy)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local b = balanceCache[src]
    if not b then return false end
    local t = ResolveType(moneyType)
    if (b[t] or 0) < amount then return false end
    b[t] = b[t] - amount
    PushUpdate(src)
    local ident = GetIdentifier(src)
    if ident then WriteLog(ident, t, 'remove', amount, reason, issuedBy) end
    TriggerEvent('nxn-finance:server:moneyChanged', src, t, 'remove', amount, b[t])
    return true
end)

--- Pénz közvetlen beállítása
exports('setMoney', function(src, amount, moneyType, reason, issuedBy)
    amount = math.floor(tonumber(amount) or 0)
    if amount < 0 then return false end
    local b = balanceCache[src]
    if not b then return false end
    local t = ResolveType(moneyType)
    b[t] = amount
    PushUpdate(src)
    local ident = GetIdentifier(src)
    if ident then WriteLog(ident, t, 'set', amount, reason, issuedBy) end
    TriggerEvent('nxn-finance:server:moneyChanged', src, t, 'set', amount, b[t])
    return true
end)

--- Játékos→Játékos átutalás
exports('transferMoney', function(fromSrc, toSrc, amount, moneyType, reason)
    amount = math.floor(tonumber(amount) or 0)
    local t = ResolveType(moneyType)
    local bFrom = balanceCache[fromSrc]
    local bTo   = balanceCache[toSrc]
    if not bFrom or not bTo then return false end
    if (bFrom[t] or 0) < amount then return false end
    bFrom[t] = bFrom[t] - amount
    bTo[t]   = bTo[t]   + amount
    PushUpdate(fromSrc)
    PushUpdate(toSrc)
    local identFrom = GetIdentifier(fromSrc)
    local identTo   = GetIdentifier(toSrc)
    if identFrom then WriteLog(identFrom, t, 'transfer', -amount, reason, identTo) end
    if identTo   then WriteLog(identTo,   t, 'transfer',  amount, reason, identFrom) end
    TriggerEvent('nxn-finance:server:moneyChanged', fromSrc, t, 'transfer', amount, bFrom[t])
    return true
end)

--- Tranzakció napló lekérése
exports('getTransactionLog', function(src, limit)
    local identifier = GetIdentifier(src)
    if not identifier then return {} end
    limit = math.min(tonumber(limit) or 50, 200)
    local rows = MySQL.query.await(
        'SELECT * FROM `nxn_finance_log` WHERE identifier = ? ORDER BY created_at DESC LIMIT ?',
        { identifier, limit }
    ) or {}
    return rows
end)
