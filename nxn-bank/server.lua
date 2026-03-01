-- ============================================================
--  nxn-bank | server.lua
-- ============================================================

-- ── Cooldown cache ──────────────────────────────────────────
-- { [src] = timestamp (ms) }
local lastTx = {}

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

local function CheckCooldown(src)
    local now = GetGameTimer()
    if lastTx[src] and (now - lastTx[src]) < Config.TransactionCooldown then
        return false
    end
    lastTx[src] = now
    return true
end

local function ValidateAmount(amount)
    return type(amount) == 'number'
        and math.floor(amount) == amount
        and amount > 0
end

local function SyncBalance(src)
    if GetResourceState('nxn-finance') ~= 'started' then return end
    local cash = exports['nxn-finance']:getMoney(src, 'cash') or 0
    local bank = exports['nxn-finance']:getMoney(src, 'bank') or 0
    TriggerClientEvent('nxn-bank:client:syncBalance', src, { cash = cash, bank = bank })
end

local function LogTx(identifier, txType, amount, description, targetId)
    if GetResourceState('nxn-database') ~= 'started' then return end
    MySQL.insert(
        'INSERT INTO `nxn_bank_transactions` (identifier, type, amount, description, target_id) VALUES (?, ?, ?, ?, ?)',
        { identifier, txType, amount, description or '', targetId or nil }
    )
end

-- ── DB init ──────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(res)
    if res ~= Config.ResourceName then return end
    NXN.Bank.Info('nxn-bank elindul...')
    CreateThread(function()
        if GetResourceState('nxn-database') ~= 'started' then
            NXN.Bank.Warn('nxn-database nem fut – tranzakciótábla nem hozható létre')
            return
        end
        exports['nxn-database']:registerTable(Config.ResourceName, {
            name = 'nxn_bank_transactions',
            sql  = [[
                CREATE TABLE IF NOT EXISTS `nxn_bank_transactions` (
                    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
                    `identifier`  VARCHAR(64)  NOT NULL,
                    `type`        ENUM('deposit','withdraw','transfer_in','transfer_out','fine') NOT NULL,
                    `amount`      INT          NOT NULL,
                    `description` VARCHAR(255) DEFAULT NULL,
                    `target_id`   VARCHAR(64)  DEFAULT NULL,
                    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (`id`),
                    INDEX `idx_identifier` (`identifier`),
                    INDEX `idx_created_at` (`created_at`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]]
        })
        NXN.Bank.Info('nxn_bank_transactions tábla OK.')
    end)
end)

-- ── Cleanup ──────────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    lastTx[source] = nil
end)

-- ── Net events ───────────────────────────────────────────────

-- Befizetés: készpénz → bankszámla
RegisterNetEvent('nxn-bank:server:deposit', function(amount)
    local src = source
    if not ValidateAmount(amount) then return end
    if not CheckCooldown(src) then
        Notify(src, 'Kérjük várj egy kicsit a következő művelet előtt!', 'warning')
        return
    end

    local identifier = GetIdentifier(src)
    if not identifier then return end

    if GetResourceState('nxn-finance') ~= 'started' then
        Notify(src, 'A pénzrendszer jelenleg nem elérhető!', 'danger')
        return
    end

    local cash = exports['nxn-finance']:getMoney(src, 'cash') or 0
    if cash < amount then
        Notify(src, ('Nincs elég készpénzed! (Van: $%d)'):format(cash), 'danger')
        TriggerClientEvent('nxn-bank:client:transactionResult', src, { ok = false, message = 'Nincs elég készpénz' })
        return
    end

    local ok1 = exports['nxn-finance']:removeMoney(src, amount, 'cash', 'ATM befizetés', 'nxn-bank')
    local ok2 = ok1 and exports['nxn-finance']:addMoney(src, amount, 'bank', 'ATM befizetés', 'nxn-bank')

    if ok1 and ok2 then
        LogTx(identifier, 'deposit', amount, 'ATM befizetés', nil)
        Notify(src, ('Befizetés sikeres: $%d'):format(amount), 'success')
        TriggerClientEvent('nxn-bank:client:transactionResult', src, { ok = true, message = ('Befizetés sikeres: $%d'):format(amount) })
        SyncBalance(src)
        NXN.Bank.Log(('deposit: src=%d amount=%d'):format(src, amount))
    else
        Notify(src, 'Befizetés sikertelen!', 'danger')
        TriggerClientEvent('nxn-bank:client:transactionResult', src, { ok = false, message = 'Befizetés sikertelen' })
    end
end)

-- Felvét: bankszámla → készpénz
RegisterNetEvent('nxn-bank:server:withdraw', function(amount)
    local src = source
    if not ValidateAmount(amount) then return end
    if not CheckCooldown(src) then
        Notify(src, 'Kérjük várj egy kicsit a következő művelet előtt!', 'warning')
        return
    end

    local identifier = GetIdentifier(src)
    if not identifier then return end

    if GetResourceState('nxn-finance') ~= 'started' then
        Notify(src, 'A pénzrendszer jelenleg nem elérhető!', 'danger')
        return
    end

    local bank = exports['nxn-finance']:getMoney(src, 'bank') or 0
    if bank < amount then
        Notify(src, ('Nincs elég pénz a bankszámládon! (Van: $%d)'):format(bank), 'danger')
        TriggerClientEvent('nxn-bank:client:transactionResult', src, { ok = false, message = 'Nincs elég pénz a számlán' })
        return
    end

    local ok1 = exports['nxn-finance']:removeMoney(src, amount, 'bank', 'ATM felvét', 'nxn-bank')
    local ok2 = ok1 and exports['nxn-finance']:addMoney(src, amount, 'cash', 'ATM felvét', 'nxn-bank')

    if ok1 and ok2 then
        LogTx(identifier, 'withdraw', amount, 'ATM felvét', nil)
        Notify(src, ('Felvét sikeres: $%d'):format(amount), 'success')
        TriggerClientEvent('nxn-bank:client:transactionResult', src, { ok = true, message = ('Felvét sikeres: $%d'):format(amount) })
        SyncBalance(src)
        NXN.Bank.Log(('withdraw: src=%d amount=%d'):format(src, amount))
    else
        Notify(src, 'Felvét sikertelen!', 'danger')
        TriggerClientEvent('nxn-bank:client:transactionResult', src, { ok = false, message = 'Felvét sikertelen' })
    end
end)

-- Átutalás: bankszámla → másik játékos bankszámlája
RegisterNetEvent('nxn-bank:server:transfer', function(targetId, amount, description)
    local src = source
    if not ValidateAmount(amount) then return end
    if amount < Config.MinTransferAmount then
        Notify(src, ('Minimum átutalási összeg: $%d'):format(Config.MinTransferAmount), 'warning')
        return
    end
    if not CheckCooldown(src) then
        Notify(src, 'Kérjük várj egy kicsit a következő művelet előtt!', 'warning')
        return
    end

    local identifier = GetIdentifier(src)
    if not identifier then return end

    -- Célszemély validálása
    local targetSrc = tonumber(targetId)
    if not targetSrc then
        Notify(src, 'Érvénytelen célszemély!', 'danger')
        TriggerClientEvent('nxn-bank:client:transactionResult', src, { ok = false, message = 'Érvénytelen célszemély' })
        return
    end

    local targetIdentifier = GetIdentifier(targetSrc)
    if not targetIdentifier then
        Notify(src, 'A célszemély nem elérhető!', 'danger')
        TriggerClientEvent('nxn-bank:client:transactionResult', src, { ok = false, message = 'Célszemély nem elérhető' })
        return
    end

    if targetSrc == src then
        Notify(src, 'Magadnak nem utalhatsz!', 'warning')
        return
    end

    if GetResourceState('nxn-finance') ~= 'started' then
        Notify(src, 'A pénzrendszer jelenleg nem elérhető!', 'danger')
        return
    end

    local bank = exports['nxn-finance']:getMoney(src, 'bank') or 0
    if bank < amount then
        Notify(src, ('Nincs elég pénz a bankszámládon! (Van: $%d)'):format(bank), 'danger')
        TriggerClientEvent('nxn-bank:client:transactionResult', src, { ok = false, message = 'Nincs elég pénz a számlán' })
        return
    end

    local desc = description or 'Átutalás'
    local ok1 = exports['nxn-finance']:removeMoney(src, amount, 'bank', desc, 'nxn-bank')
    local ok2 = ok1 and exports['nxn-finance']:addMoney(targetSrc, amount, 'bank', desc, 'nxn-bank')

    if ok1 and ok2 then
        local senderName = ''
        local targetName = ''
        if GetResourceState('nxn-identity') == 'started' then
            senderName = exports['nxn-identity']:getFullName(src) or GetPlayerName(src)
            targetName = exports['nxn-identity']:getFullName(targetSrc) or GetPlayerName(targetSrc)
        else
            senderName = GetPlayerName(src)
            targetName = GetPlayerName(targetSrc)
        end

        LogTx(identifier,       'transfer_out', amount, desc, targetIdentifier)
        LogTx(targetIdentifier, 'transfer_in',  amount, desc, identifier)

        Notify(src,       ('Átutalás sikeres: $%d → %s'):format(amount, targetName),   'success')
        Notify(targetSrc, ('Átutalás érkezett: $%d – %s'):format(amount, senderName),   'success')

        TriggerClientEvent('nxn-bank:client:transactionResult', src, { ok = true, message = ('Átutalás sikeres: $%d'):format(amount) })
        SyncBalance(src)
        SyncBalance(targetSrc)
        NXN.Bank.Log(('transfer: src=%d target=%d amount=%d'):format(src, targetSrc, amount))
    else
        Notify(src, 'Átutalás sikertelen!', 'danger')
        TriggerClientEvent('nxn-bank:client:transactionResult', src, { ok = false, message = 'Átutalás sikertelen' })
    end
end)

-- Tranzakciónapló lekérés
RegisterNetEvent('nxn-bank:server:getTransactions', function(page)
    local src  = source
    page = type(page) == 'number' and page > 0 and page or 1
    local identifier = GetIdentifier(src)
    if not identifier then return end

    if GetResourceState('nxn-database') ~= 'started' then return end

    local offset = (page - 1) * Config.TransactionLogPageSize

    local items = MySQL.query.await(
        'SELECT * FROM `nxn_bank_transactions` WHERE identifier = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
        { identifier, Config.TransactionLogPageSize, offset }
    ) or {}

    local countRow = MySQL.single.await(
        'SELECT COUNT(*) as cnt FROM `nxn_bank_transactions` WHERE identifier = ?',
        { identifier }
    ) or { cnt = 0 }

    TriggerClientEvent('nxn-bank:client:transactions', src, {
        items = items,
        page  = page,
        total = countRow.cnt or 0,
    })
end)

-- ── Szerver exportok ─────────────────────────────────────────

--- Befizetés scriptből
---@param src    integer
---@param amount integer
---@return boolean
exports('deposit', function(src, amount)
    if not ValidateAmount(amount) then return false end
    if GetResourceState('nxn-finance') ~= 'started' then return false end
    local cash = exports['nxn-finance']:getMoney(src, 'cash') or 0
    if cash < amount then return false end
    local ok1 = exports['nxn-finance']:removeMoney(src, amount, 'cash', 'Befizetés', 'nxn-bank')
    local ok2 = ok1 and exports['nxn-finance']:addMoney(src, amount, 'bank', 'Befizetés', 'nxn-bank')
    if ok1 and ok2 then
        local identifier = GetIdentifier(src)
        if identifier then LogTx(identifier, 'deposit', amount, 'Befizetés', nil) end
        SyncBalance(src)
        return true
    end
    return false
end)

--- Felvét scriptből
---@param src    integer
---@param amount integer
---@return boolean
exports('withdraw', function(src, amount)
    if not ValidateAmount(amount) then return false end
    if GetResourceState('nxn-finance') ~= 'started' then return false end
    local bank = exports['nxn-finance']:getMoney(src, 'bank') or 0
    if bank < amount then return false end
    local ok1 = exports['nxn-finance']:removeMoney(src, amount, 'bank', 'Felvét', 'nxn-bank')
    local ok2 = ok1 and exports['nxn-finance']:addMoney(src, amount, 'cash', 'Felvét', 'nxn-bank')
    if ok1 and ok2 then
        local identifier = GetIdentifier(src)
        if identifier then LogTx(identifier, 'withdraw', amount, 'Felvét', nil) end
        SyncBalance(src)
        return true
    end
    return false
end)

--- Átutalás scriptből
---@param src         integer
---@param targetSrc   integer
---@param amount      integer
---@param description string?
---@return boolean
exports('transfer', function(src, targetSrc, amount, description)
    if not ValidateAmount(amount) then return false end
    if src == targetSrc then return false end
    if GetResourceState('nxn-finance') ~= 'started' then return false end
    local bank = exports['nxn-finance']:getMoney(src, 'bank') or 0
    if bank < amount then return false end
    local desc = description or 'Átutalás'
    local ok1 = exports['nxn-finance']:removeMoney(src, amount, 'bank', desc, 'nxn-bank')
    local ok2 = ok1 and exports['nxn-finance']:addMoney(targetSrc, amount, 'bank', desc, 'nxn-bank')
    if ok1 and ok2 then
        local idSrc = GetIdentifier(src)
        local idTgt = GetIdentifier(targetSrc)
        if idSrc then LogTx(idSrc, 'transfer_out', amount, desc, idTgt) end
        if idTgt then LogTx(idTgt, 'transfer_in',  amount, desc, idSrc) end
        SyncBalance(src)
        SyncBalance(targetSrc)
        return true
    end
    return false
end)

--- Tranzakciónapló lekérése (szerver oldali híváshoz)
---@param identifier string
---@param page       integer?
---@return table
exports('getTransactions', function(identifier, page)
    page = type(page) == 'number' and page > 0 and page or 1
    if GetResourceState('nxn-database') ~= 'started' then return {} end
    local offset = (page - 1) * Config.TransactionLogPageSize
    local items = MySQL.query.await(
        'SELECT * FROM `nxn_bank_transactions` WHERE identifier = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
        { identifier, Config.TransactionLogPageSize, offset }
    ) or {}
    return items
end)

--- Tranzakció manuális naplózása
---@param identifier string
---@param txType     string  'deposit'|'withdraw'|'transfer_in'|'transfer_out'|'fine'
---@param amount     integer
---@param desc       string?
---@param targetId   string?
exports('logTransaction', function(identifier, txType, amount, desc, targetId)
    LogTx(identifier, txType, amount, desc, targetId)
end)
