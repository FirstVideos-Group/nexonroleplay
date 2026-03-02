-- ============================================================
--  nxn-jobwork | server.lua
-- ============================================================

-- [src] = { job, grade, salary, clockIn, earnedSoFar, lastPartialPay, identifier, jobLabel }
local activeShifts = {}

-- ── Belső helpers ─────────────────────────────────────────────

local function GetId(src)
    if GetResourceState('nxn-identity') == 'started' then
        local id = exports['nxn-identity']:getIdentifier(src)
        if id then return id end
    end
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 6) == 'steam:' then return id end
    end
    return nil
end

local function Notify(src, msg, ntype)
    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:notifyPlayer(src, msg, ntype or 'info')
    end
end

local function DoClockOut(src, force)
    local s = activeShifts[src]
    if not s then return false end

    local elapsed = os.time() - s.clockIn
    local hours   = elapsed / 3600
    local payout  = math.floor(s.salary * hours)

    if Config.PayMode == 'interval' then
        payout = math.max(0, payout - (s.earnedSoFar or 0))
    end

    if payout > 0 and GetResourceState('nxn-finance') == 'started' then
        exports['nxn-finance']:addMoney(
            src, payout, Config.PayType,
            ('Fizets: %s'):format(s.jobLabel or s.job),
            'nxn-jobwork'
        )
    end

    if GetResourceState('nxn-database') == 'started' then
        exports['nxn-database']:execute(
            'UPDATE nxn_jobwork_shifts SET clock_out=NOW(), duration_sec=?, payout=? WHERE identifier=? AND clock_out IS NULL',
            { elapsed, payout, s.identifier }
        )
    end

    if Config.FatigueEnabled and GetResourceState('nxn-needs') == 'started' then
        exports['nxn-needs']:modifyNeed(src, 'fatigue', math.floor(hours * Config.FatiguePerHour))
        exports['nxn-needs']:modifyNeed(src, 'stress',  math.floor(hours * Config.StressPerHour))
    end

    local job   = s.job
    local grade = s.grade
    activeShifts[src] = nil

    TriggerClientEvent('nxn-jobwork:client:clockedOut', src, { payout = payout, duration = elapsed })
    TriggerEvent('nxn-jobwork:server:clockedOut', src, job, grade, elapsed, payout)

    if not force then
        Notify(src,
            ('Műszak vge! Fizets: %d Ft (%s)'):format(payout, NXN.JobWork.FormatTime(elapsed)),
            'success'
        )
    end
    NXN.JobWork.Info(('clockOut: src=%d job=%s payout=%d elapsed=%ds'):format(src, job, payout, elapsed))
    return true
end

-- ── DB tábla ────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if GetResourceState('nxn-database') ~= 'started' then return end
    exports['nxn-database']:execute([[
        CREATE TABLE IF NOT EXISTS `nxn_jobwork_shifts` (
            `id`           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `identifier`   VARCHAR(100)  NOT NULL,
            `job`          VARCHAR(50)   NOT NULL,
            `grade`        TINYINT       NOT NULL DEFAULT 0,
            `salary`       INT UNSIGNED  NOT NULL DEFAULT 0,
            `clock_in`     DATETIME      NOT NULL,
            `clock_out`    DATETIME      DEFAULT NULL,
            `duration_sec` INT UNSIGNED  DEFAULT NULL,
            `payout`       INT UNSIGNED  DEFAULT NULL,
            `created_at`   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_shifts_ident` (`identifier`),
            INDEX `idx_shifts_job`   (`job`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]], {})
    NXN.JobWork.Info('nxn_jobwork_shifts tábla ellenőrizve/létrehozva.')
end)

-- ── Játékos be/kilépés ──────────────────────────────────────────

AddEventHandler('nxn-database:playerLoaded', function(src)
    local identifier = GetId(src)
    if not identifier then return end
    if GetResourceState('nxn-database') ~= 'started' then return end

    -- Nyitott műszak visszacsatolsa (crash-safety)
    exports['nxn-database']:fetchOne(
        'SELECT job, grade, salary, UNIX_TIMESTAMP(clock_in) AS clock_in_unix FROM nxn_jobwork_shifts WHERE identifier = ? AND clock_out IS NULL ORDER BY clock_in DESC LIMIT 1',
        { identifier },
        function(row)
            if row then
                local jobData = nil
                if GetResourceState('nxn-job') == 'started' then
                    jobData = exports['nxn-job']:getJob(src)
                end
                activeShifts[src] = {
                    job            = row.job,
                    grade          = row.grade,
                    salary         = row.salary,
                    clockIn        = row.clock_in_unix or os.time(),
                    earnedSoFar    = 0,
                    lastPartialPay = row.clock_in_unix or os.time(),
                    identifier     = identifier,
                    jobLabel       = (jobData and jobData.label) or row.job,
                }
                TriggerClientEvent('nxn-jobwork:client:clockedIn', src, {
                    job        = row.job,
                    label      = activeShifts[src].jobLabel,
                    grade      = row.grade,
                    gradeLabel = (jobData and jobData.gradeLabel) or tostring(row.grade),
                })
                Notify(src, 'Folyamatban lv műszak visszalltva.', 'info')
                NXN.JobWork.Log(('playerLoaded: nyitott műszak visszalltva src=%d job=%s'):format(src, row.job))
            end

            if GetResourceState('nxn-loading') == 'started' then
                exports['nxn-loading']:updateModuleProgress('Műszak', 100)
            end
        end
    )
end)

AddEventHandler('nxn-database:playerUnloading', function(src)
    if activeShifts[src] then
        NXN.JobWork.Log(('playerUnloading: auto clockOut src=%d'):format(src))
        DoClockOut(src, true)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activeShifts[src] then
        DoClockOut(src, true)
    end
end)

-- ── nxn-job:server:jobUpdated ─────────────────────────────────

AddEventHandler('nxn-job:server:jobUpdated', function(src, oldJob, oldGrade, newJob, newGrade)
    -- Ha a munkakör megváltozott és aktív műszak volt, zárjuk le
    if activeShifts[src] and activeShifts[src].job ~= newJob then
        NXN.JobWork.Log(('jobUpdated: munkakrváltás, auto clockOut src=%d'):format(src))
        DoClockOut(src, false)
    end
end)

-- ── Net eventek ───────────────────────────────────────────────

RegisterNetEvent('nxn-jobwork:server:clockIn', function(locationId)
    local src        = source
    local identifier = GetId(src)
    if not identifier then return end

    if activeShifts[src] then
        Notify(src, 'Mr aktív műszakban vagy!', 'warning')
        return
    end

    if GetResourceState('nxn-job') ~= 'started' then return end
    local jobData = exports['nxn-job']:getJob(src)
    if not jobData or jobData.job == 'unemployed' then
        Notify(src, 'Nincs munkaköröd!', 'error')
        return
    end

    -- Helyszín ellenrzés
    if locationId then
        local loc = Config.JobLocations[locationId]
        if loc then
            if loc.requiredJob and loc.requiredJob ~= jobData.job then
                Notify(src, 'Nem megfelelő munkakör ehhez az NPC-hez!', 'error')
                return
            end
            if loc.requiredGrade and jobData.grade < loc.requiredGrade then
                Notify(src, 'Nincs elegendő rangod ehhez!', 'error')
                return
            end
        end
    end

    activeShifts[src] = {
        job            = jobData.job,
        grade          = jobData.grade,
        salary         = jobData.salary,
        clockIn        = os.time(),
        earnedSoFar    = 0,
        lastPartialPay = os.time(),
        identifier     = identifier,
        jobLabel       = jobData.label,
    }

    if GetResourceState('nxn-database') == 'started' then
        exports['nxn-database']:execute(
            'INSERT INTO nxn_jobwork_shifts (identifier, job, grade, salary, clock_in) VALUES (?, ?, ?, ?, NOW())',
            { identifier, jobData.job, jobData.grade, jobData.salary }
        )
    end

    TriggerClientEvent('nxn-jobwork:client:clockedIn', src, {
        job        = jobData.job,
        label      = jobData.label,
        grade      = jobData.grade,
        gradeLabel = jobData.gradeLabel,
    })
    TriggerEvent('nxn-jobwork:server:clockedIn', src, jobData.job, jobData.grade, os.time())
    Notify(src, 'Műszak elkezdve: ' .. jobData.label, 'success')
    NXN.JobWork.Info(('clockIn: src=%d job=%s grade=%d'):format(src, jobData.job, jobData.grade))
end)

RegisterNetEvent('nxn-jobwork:server:clockOut', function()
    local src = source
    if not activeShifts[src] then
        Notify(src, 'Nincs aktív műszakod!', 'warning')
        return
    end
    DoClockOut(src, false)
end)

RegisterNetEvent('nxn-jobwork:server:requestSalaryInfo', function()
    local src = source
    local s   = activeShifts[src]
    if not s then
        Notify(src, 'Nincs aktív műszakod.', 'warning')
        return
    end
    local elapsed = os.time() - s.clockIn
    local earned  = math.floor(s.salary * (elapsed / 3600))
    Notify(src,
        ('Jelenlegi kereset: %d Ft | Idő: %s'):format(earned, NXN.JobWork.FormatTime(elapsed)),
        'info'
    )
end)

-- ── Timer loop (60 mp) – részfizetés + fáradtság tick ───────────────

local lastFatigueTick = {}

CreateThread(function()
    while true do
        Wait(60000)
        local now = os.time()
        for src, s in pairs(activeShifts) do
            if DoesPlayerExist(tostring(src)) then
                local ok, err = pcall(function()
                    -- Részfizetés
                    if Config.PayMode == 'interval' or Config.PayMode == 'both' then
                        local sinceLastPay = now - (s.lastPartialPay or s.clockIn)
                        if sinceLastPay >= Config.PayInterval then
                            local partialPay = math.floor(s.salary * (Config.PayInterval / 3600))
                            if partialPay > 0 and GetResourceState('nxn-finance') == 'started' then
                                exports['nxn-finance']:addMoney(
                                    src, partialPay, Config.PayType,
                                    ('Részfizetés: %s'):format(s.jobLabel or s.job),
                                    'nxn-jobwork'
                                )
                            end
                            s.lastPartialPay = now
                            s.earnedSoFar    = (s.earnedSoFar or 0) + partialPay
                            TriggerClientEvent('nxn-jobwork:client:partialPay', src, {
                                amount      = partialPay,
                                earnedTotal = s.earnedSoFar,
                            })
                            TriggerEvent('nxn-jobwork:server:payoutSent', src, partialPay, s.job)
                        end
                    end

                    -- Fáradtság tick
                    if Config.FatigueEnabled and GetResourceState('nxn-needs') == 'started' then
                        local lastTick = lastFatigueTick[src] or s.clockIn
                        if (now - lastTick) >= Config.FatigueCheckInterval then
                            local tickHours = Config.FatigueCheckInterval / 3600
                            exports['nxn-needs']:modifyNeed(src, 'fatigue',
                                math.floor(Config.FatiguePerHour * tickHours * 100) / 100)
                            exports['nxn-needs']:modifyNeed(src, 'stress',
                                math.floor(Config.StressPerHour  * tickHours * 100) / 100)
                            lastFatigueTick[src] = now
                        end
                    end

                    -- Max műszak hossz ellenőrzés
                    if Config.MaxShiftDuration > 0 then
                        local elapsed = now - s.clockIn
                        if elapsed >= Config.MaxShiftDuration then
                            NXN.JobWork.Warn(('MaxShiftDuration elrve, auto clockOut: src=%d'):format(src))
                            DoClockOut(src, false)
                        end
                    end
                end)
                if not ok then NXN.JobWork.Error(tostring(err)) end
            else
                -- Játékos már nincs online, cleanup
                activeShifts[src]    = nil
                lastFatigueTick[src] = nil
            end
        end
    end
end)

-- ── Exportok ────────────────────────────────────────────────

exports('isOnDuty', function(src)
    return activeShifts[src] ~= nil
end)

exports('getShiftData', function(src)
    local s = activeShifts[src]
    if not s then return nil end
    local elapsed = os.time() - s.clockIn
    return {
        job         = s.job,
        grade       = s.grade,
        clockInTime = s.clockIn,
        elapsedSec  = elapsed,
        earnedSoFar = math.floor(s.salary * (elapsed / 3600)),
    }
end)

exports('getShiftDuration', function(src)
    local s = activeShifts[src]
    if not s then return 0 end
    return os.time() - s.clockIn
end)

exports('getCurrentPayout', function(src)
    local s = activeShifts[src]
    if not s then return 0 end
    return math.floor(s.salary * ((os.time() - s.clockIn) / 3600))
end)

exports('clockIn', function(src)
    if activeShifts[src] then return false end
    if GetResourceState('nxn-job') ~= 'started' then return false end
    local jobData = exports['nxn-job']:getJob(src)
    if not jobData or jobData.job == 'unemployed' then return false end
    local identifier = GetId(src)
    if not identifier then return false end

    activeShifts[src] = {
        job            = jobData.job,
        grade          = jobData.grade,
        salary         = jobData.salary,
        clockIn        = os.time(),
        earnedSoFar    = 0,
        lastPartialPay = os.time(),
        identifier     = identifier,
        jobLabel       = jobData.label,
    }

    if GetResourceState('nxn-database') == 'started' then
        exports['nxn-database']:execute(
            'INSERT INTO nxn_jobwork_shifts (identifier, job, grade, salary, clock_in) VALUES (?, ?, ?, ?, NOW())',
            { identifier, jobData.job, jobData.grade, jobData.salary }
        )
    end

    TriggerClientEvent('nxn-jobwork:client:clockedIn', src, {
        job        = jobData.job,
        label      = jobData.label,
        grade      = jobData.grade,
        gradeLabel = jobData.gradeLabel,
    })
    TriggerEvent('nxn-jobwork:server:clockedIn', src, jobData.job, jobData.grade, os.time())
    Notify(src, 'Műszak elkezdve: ' .. jobData.label, 'success')
    return true
end)

exports('clockOut', function(src, force)
    return DoClockOut(src, force)
end)

exports('getActiveWorkers', function(job)
    local result = {}
    for src, s in pairs(activeShifts) do
        if not job or s.job == job then
            result[#result + 1] = {
                src   = src,
                job   = s.job,
                grade = s.grade,
                clockInTime = s.clockIn,
            }
        end
    end
    return result
end)

-- ── Admin parancsok ───────────────────────────────────────────

RegisterCommand('hire', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.AdminAce) then return end
    local target = tonumber(args[1])
    local job    = args[2]
    local grade  = tonumber(args[3]) or 0
    if not target or not job then
        print('[nxn-jobwork] Hasznlat: /hire [player_id] [job] [grade]')
        return
    end
    if GetResourceState('nxn-job') ~= 'started' then return end
    local ok = exports['nxn-job']:setJob(target, job, grade)
    if ok then
        Notify(src,
            ('Felvtel sikeres: %s -> %s/%d'):format(GetPlayerName(target) or tostring(target), job, grade),
            'success'
        )
    else
        Notify(src, 'Felvtel sikertelen! Ellenrizd a job/grade rtket.', 'error')
    end
end, true)

RegisterCommand('fire', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.AdminAce) then return end
    local target = tonumber(args[1])
    if not target then
        print('[nxn-jobwork] Hasznlat: /fire [player_id]')
        return
    end
    if GetResourceState('nxn-job') ~= 'started' then return end
    exports['nxn-job']:setJob(target, 'unemployed', 0)
    Notify(src, 'Játékos elbocsjtva: ' .. (GetPlayerName(target) or tostring(target)), 'info')
end, true)

RegisterCommand('clockoutplayer', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.AdminAce) then return end
    local target = tonumber(args[1])
    if not target then
        print('[nxn-jobwork] Hasznlat: /clockoutplayer [player_id]')
        return
    end
    local ok = DoClockOut(target, false)
    if ok then
        Notify(src, 'Kézi clockOut sikeres: ' .. (GetPlayerName(target) or tostring(target)), 'success')
    else
        Notify(src, 'A játékos nem volt műszakban.', 'warning')
    end
end, true)
