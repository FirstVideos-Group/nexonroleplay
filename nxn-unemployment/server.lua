-- ============================================================
--  nxn-unemployment | server.lua
-- ============================================================

-- Cache: [identifier] = { isActive, lastPaidAt (unix), totalPaid, totalAmount, registeredAt (unix) }
local cache = {}
-- src -> identifier gyorsító
local srcToId = {}

-- ── Belső helpers ─────────────────────────────────────────────

local function GetId(src)
    if srcToId[src] then return srcToId[src] end
    if GetResourceState('nxn-identity') == 'started' then
        local id = exports['nxn-identity']:getIdentifier(src)
        if id then srcToId[src] = id return id end
    end
    -- fallback steam
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 6) == 'steam:' then
            srcToId[src] = id
            return id
        end
    end
    return nil
end

local function NowUnix()
    return os.time()
end

local function DBSave(identifier, data)
    if GetResourceState('nxn-database') ~= 'started' then return end
    exports['nxn-database']:execute(
        'INSERT INTO nxn_unemployment (identifier, registered_at, last_paid_at, total_paid, total_amount, is_active)'
     .. ' VALUES (?, NOW(), ?, ?, ?, ?)'
     .. ' ON DUPLICATE KEY UPDATE last_paid_at=VALUES(last_paid_at),'
     .. ' total_paid=VALUES(total_paid), total_amount=VALUES(total_amount), is_active=VALUES(is_active)',
        {
            identifier,
            data.lastPaidAt and os.date('%Y-%m-%d %H:%M:%S', data.lastPaidAt) or nil,
            data.totalPaid  or 0,
            data.totalAmount or 0,
            data.isActive and 1 or 0,
        }
    )
end

local function IsUnemployed(src)
    if GetResourceState('nxn-job') ~= 'started' then return false end
    return exports['nxn-job']:hasJob(src, 'unemployed')
end

local function GetCash(src)
    if GetResourceState('nxn-finance') == 'started' then
        return exports['nxn-finance']:getMoney(src) or 0
    end
    return 0
end

-- ── DB tábla létrehozás ───────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if GetResourceState('nxn-database') ~= 'started' then return end
    exports['nxn-database']:execute([[
        CREATE TABLE IF NOT EXISTS `nxn_unemployment` (
            `identifier`    VARCHAR(100) NOT NULL PRIMARY KEY,
            `registered_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `last_paid_at`  DATETIME     DEFAULT NULL,
            `total_paid`    INT UNSIGNED NOT NULL DEFAULT 0,
            `total_amount`  INT UNSIGNED NOT NULL DEFAULT 0,
            `is_active`     TINYINT(1)   NOT NULL DEFAULT 1,
            `updated_at`    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]], {})
    NXN.Unemployment.Info('nxn_unemployment tábla ellenőrizve/létrehozva.')
end)

-- ── Játékos betöltés ──────────────────────────────────────────

local function LoadPlayer(src)
    local identifier = GetId(src)
    if not identifier then return end
    if GetResourceState('nxn-database') ~= 'started' then return end

    exports['nxn-database']:fetchOne(
        'SELECT is_active, UNIX_TIMESTAMP(last_paid_at) AS last_paid_unix, total_paid, total_amount FROM nxn_unemployment WHERE identifier = ?',
        { identifier },
        function(row)
            if row then
                cache[identifier] = {
                    isActive    = row.is_active == 1,
                    lastPaidAt  = row.last_paid_unix or 0,
                    totalPaid   = row.total_paid   or 0,
                    totalAmount = row.total_amount or 0,
                }
            else
                -- Új játékos: DB INSERT
                local now = NowUnix()
                cache[identifier] = {
                    isActive    = IsUnemployed(src),
                    lastPaidAt  = now,  -- FirstPayDelay: most-tól számítjuk
                    totalPaid   = 0,
                    totalAmount = 0,
                }
                DBSave(identifier, cache[identifier])
            end
            srcToId[src] = identifier
            NXN.Unemployment.Log(('LoadPlayer: src=%d id=%s active=%s'):format(src, identifier, tostring(cache[identifier].isActive)))
        end
    )
end

AddEventHandler('nxn-database:playerLoaded', function(src)
    LoadPlayer(src)
end)

AddEventHandler('nxn-job:server:loaded', function(src, data)
    -- Ha már betöltve van a cache, csak frissítsük az isActive értéket
    local identifier = GetId(src)
    if not identifier then return end
    if not cache[identifier] then
        LoadPlayer(src)
        return
    end
    if data and data.job then
        cache[identifier].isActive = (data.job == 'unemployed')
    end
end)

AddEventHandler('nxn-database:playerUnloading', function(src)
    local id = srcToId[src]
    if id then
        -- Mentés előtt
        if cache[id] then DBSave(id, cache[id]) end
        cache[id] = nil
    end
    srcToId[src] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    local id  = srcToId[src]
    if id and cache[id] then DBSave(id, cache[id]) end
    cache[id]    = nil
    srcToId[src] = nil
end)

-- ── nxn-job:server:jobUpdated figyelese ────────────────────────────

AddEventHandler('nxn-job:server:jobUpdated', function(src, oldJob, oldGrade, newJob, newGrade)
    local identifier = GetId(src)
    if not identifier then return end

    if newJob == 'unemployed' and oldJob ~= 'unemployed' then
        -- Munkakeszes - activate + FirstPayDelay cooldown
        if not cache[identifier] then
            cache[identifier] = { isActive = true, lastPaidAt = NowUnix(), totalPaid = 0, totalAmount = 0 }
        else
            cache[identifier].isActive   = true
            cache[identifier].lastPaidAt = NowUnix()  -- cooldown: most-tól számítjuk a FirstPayDelay-t
        end
        DBSave(identifier, cache[identifier])
        TriggerEvent('nxn-unemployment:server:activated', src)
        if GetResourceState('nxn-notify') == 'started' then
            exports['nxn-notify']:notifyPlayer(src,
                ('Regisztrálva a Munkáügyi Hivatalban. %d perc múlva kapod az első segélyt.'):
                format(math.floor(Config.FirstPayDelay / 60)),
                'info'
            )
        end

    elseif oldJob == 'unemployed' and newJob ~= 'unemployed' then
        if cache[identifier] then
            cache[identifier].isActive = false
            DBSave(identifier, cache[identifier])
        end
        TriggerEvent('nxn-unemployment:server:deactivated', src, 'job_found')
        if GetResourceState('nxn-notify') == 'started' then
            exports['nxn-notify']:notifyPlayer(src,
                'Gratulálunk az új munkához! A munkanélküli segély leállítva.',
                'success'
            )
        end
    end
end)

-- ── Kifizetési timer loop (60 másodpercenként) ────────────────────

local function DoPay(src, identifier)
    local data = cache[identifier]
    if not data then return end

    -- Jogosultság ellenőrzés
    if not data.isActive then return end
    if not IsUnemployed(src) then
        data.isActive = false
        return
    end

    -- PayInterval és FirstPayDelay ellenőrzés
    local now      = NowUnix()
    local elapsed  = now - (data.lastPaidAt or 0)
    local needed   = (data.totalPaid == 0) and Config.FirstPayDelay or Config.PayInterval
    if elapsed < needed then return end

    -- Pénz limit
    if Config.MaxCashLimit then
        local cash = GetCash(src)
        if cash >= Config.MaxCashLimit then return end
    end

    local amount = Config.BenefitAmount

    -- Stressz alapú csökkentés
    if Config.StressReduction and GetResourceState('nxn-needs') == 'started' then
        local stress = exports['nxn-needs']:getNeed(src, 'stress') or 0
        if stress > Config.StressThreshold then
            amount = math.floor(amount * Config.StressReductionRate)
        end
    end

    -- Bíróság levonás
    if Config.DeductFines and GetResourceState('nxn-cityhall') == 'started' then
        local fines = exports['nxn-cityhall']:getFines(src) or 0
        if fines > 0 then
            local deduction = math.min(math.floor(amount * Config.FineDeductionRate), fines)
            if deduction > 0 then
                exports['nxn-cityhall']:payFine(src, deduction)
                amount = amount - deduction
            end
        end
    end

    if amount <= 0 then return end

    -- Kifizetés
    if GetResourceState('nxn-finance') == 'started' then
        exports['nxn-finance']:addMoney(src, amount, 'cash', 'Munkanélküli segély', 'nxn-unemployment')
    end

    -- Cache + DB frissítés
    data.lastPaidAt   = now
    data.totalPaid    = (data.totalPaid  or 0) + 1
    data.totalAmount  = (data.totalAmount or 0) + amount
    DBSave(identifier, data)

    local nextPayIn = Config.PayInterval
    TriggerClientEvent('nxn-unemployment:client:paid', src, { amount = amount, nextPayIn = nextPayIn })
    TriggerEvent('nxn-unemployment:server:paid', src, amount, GetCash(src))
    NXN.Unemployment.Log(('DoPay: src=%d amount=%d'):format(src, amount))
end

CreateThread(function()
    while true do
        Wait(60000)  -- 60 másodpercenként fut
        for src, identifier in pairs(srcToId) do
            if DoesPlayerExist(tostring(src)) then
                local ok, err = pcall(DoPay, src, identifier)
                if not ok then NXN.Unemployment.Error(tostring(err)) end
            end
        end
    end
end)

-- ── Net eventek ───────────────────────────────────────────────

RegisterNetEvent('nxn-unemployment:server:getStatus', function()
    local src        = source
    local identifier = GetId(src)
    if not identifier then return end
    local data = cache[identifier]
    local now  = NowUnix()
    local nextPayIn = 0
    if data then
        local elapsed = now - (data.lastPaidAt or 0)
        nextPayIn = math.max(0, Config.PayInterval - elapsed)
    end
    local isActive = data and data.isActive or false
    TriggerClientEvent('nxn-unemployment:client:statusUpdate', src, {
        isActive   = isActive,
        nextPayIn  = nextPayIn,
        totalPaid  = data and data.totalPaid  or 0,
        totalAmount = data and data.totalAmount or 0,
    })
end)

-- ── Exportok ────────────────────────────────────────────────

exports('isEligible', function(src)
    if not IsUnemployed(src) then return false end
    local identifier = GetId(src)
    if not identifier then return false end
    local data = cache[identifier]
    if not data or not data.isActive then return false end
    if Config.MaxCashLimit then
        if GetCash(src) >= Config.MaxCashLimit then return false end
    end
    return true
end)

exports('getStatus', function(src)
    local identifier = GetId(src)
    if not identifier then return nil end
    local data = cache[identifier]
    local now  = NowUnix()
    local nextPayIn = 0
    if data then
        nextPayIn = math.max(0, Config.PayInterval - (now - (data.lastPaidAt or 0)))
    end
    return {
        isActive    = data and data.isActive   or false,
        lastPaidAt  = data and data.lastPaidAt or 0,
        totalPaid   = data and data.totalPaid  or 0,
        nextPayIn   = nextPayIn,
    }
end)

exports('getNextPayTime', function(src)
    local identifier = GetId(src)
    if not identifier then return 0 end
    local data = cache[identifier]
    if not data then return 0 end
    return math.max(0, Config.PayInterval - (NowUnix() - (data.lastPaidAt or 0)))
end)

exports('activate', function(src)
    local identifier = GetId(src)
    if not identifier then return false end
    if not cache[identifier] then
        cache[identifier] = { isActive = true, lastPaidAt = NowUnix(), totalPaid = 0, totalAmount = 0 }
    else
        cache[identifier].isActive = true
    end
    DBSave(identifier, cache[identifier])
    TriggerEvent('nxn-unemployment:server:activated', src)
    return true
end)

exports('deactivate', function(src, reason)
    local identifier = GetId(src)
    if not identifier or not cache[identifier] then return false end
    cache[identifier].isActive = false
    DBSave(identifier, cache[identifier])
    TriggerEvent('nxn-unemployment:server:deactivated', src, reason or 'admin')
    return true
end)

exports('manualPay', function(src, adminSrc)
    if adminSrc and adminSrc ~= 0 and not IsPlayerAceAllowed(adminSrc, Config.AdminAce) then
        NXN.Unemployment.Warn(('manualPay: ACE megtagadva adminSrc=%s'):format(tostring(adminSrc)))
        return false
    end
    local identifier = GetId(src)
    if not identifier then return false end
    if not IsUnemployed(src) then return false end

    local amount = Config.BenefitAmount
    if GetResourceState('nxn-finance') == 'started' then
        exports['nxn-finance']:addMoney(src, amount, 'cash', 'Munkanélküli segély (kézi)', 'nxn-unemployment')
    end
    if not cache[identifier] then
        cache[identifier] = { isActive = true, lastPaidAt = NowUnix(), totalPaid = 1, totalAmount = amount }
    else
        cache[identifier].lastPaidAt  = NowUnix()
        cache[identifier].totalPaid   = (cache[identifier].totalPaid  or 0) + 1
        cache[identifier].totalAmount = (cache[identifier].totalAmount or 0) + amount
    end
    DBSave(identifier, cache[identifier])
    TriggerClientEvent('nxn-unemployment:client:paid', src, { amount = amount, nextPayIn = Config.PayInterval })
    TriggerEvent('nxn-unemployment:server:paid', src, amount, GetCash(src))
    NXN.Unemployment.Info(('manualPay: src=%d amount=%d admin=%s'):format(src, amount, tostring(adminSrc)))
    return true
end)

exports('getStats', function()
    local activeCount = 0
    local totalAmount = 0
    for _, data in pairs(cache) do
        if data.isActive then activeCount = activeCount + 1 end
        totalAmount = totalAmount + (data.totalAmount or 0)
    end
    return { activeCount = activeCount, totalAmount = totalAmount }
end)

-- ── Admin parancs ─────────────────────────────────────────────

RegisterCommand('paybenefit', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.AdminAce) then return end
    local target = tonumber(args[1])
    if not target then
        print('[nxn-unemployment] Használat: /paybenefit [player_id]')
        return
    end
    local ok = exports['nxn-unemployment']:manualPay(target, src)
    if ok and GetResourceState('nxn-notify') == 'started' and src ~= 0 then
        exports['nxn-notify']:notifyPlayer(src,
            'Kézi segélykifizetés sikeres: ' .. (GetPlayerName(target) or tostring(target)),
            'success'
        )
    end
end, true)
