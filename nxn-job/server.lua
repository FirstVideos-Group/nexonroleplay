-- ============================================================
--  nxn-job | server.lua
-- ============================================================

local playerJobs = {}  -- [src] = { job, grade }

-- ── Belső helpers ─────────────────────────────────────────────

local function GetIdentifier(src)
    if GetResourceState('nxn-identity') == 'started' then
        return exports['nxn-identity']:getIdentifier(src)
    end
    -- fallback: steam license
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 6) == 'steam:' then return id end
    end
    return nil
end

local function LoadPlayerJob(src)
    local identifier = GetIdentifier(src)
    if not identifier then
        NXN.Job.Warn(('LoadPlayerJob: nincs identifier src=%d'):format(src))
        playerJobs[src] = { job = Config.DefaultJob, grade = Config.DefaultGrade }
        return
    end

    if GetResourceState('nxn-database') ~= 'started' then
        NXN.Job.Warn('nxn-database nem fut, alapértelmezett munkakör használva.')
        playerJobs[src] = { job = Config.DefaultJob, grade = Config.DefaultGrade }
        return
    end

    exports['nxn-database']:fetchOne(
        'SELECT job, grade FROM nxn_player_jobs WHERE identifier = ?',
        { identifier },
        function(row)
            local job, grade
            if row then
                job   = row.job   or Config.DefaultJob
                grade = row.grade or Config.DefaultGrade
                -- Érvényesség ellenőrzés (ha a config módosult)
                if not NXN.Job.IsValid(job, grade) then
                    NXN.Job.Warn(('Ismeretlen job/grade a DB-ben: %s/%d – reset'):format(job, grade))
                    job   = Config.DefaultJob
                    grade = Config.DefaultGrade
                end
            else
                -- Nincs sor: INSERT default
                job   = Config.DefaultJob
                grade = Config.DefaultGrade
                exports['nxn-database']:execute(
                    'INSERT IGNORE INTO nxn_player_jobs (identifier, job, grade) VALUES (?, ?, ?)',
                    { identifier, job, grade }
                )
            end

            playerJobs[src] = { job = job, grade = grade }

            local jobData = NXN.Job.BuildJobData(job, grade)
            if jobData then
                TriggerClientEvent('nxn-job:client:jobUpdated', src, jobData)
            end

            TriggerEvent('nxn-job:server:loaded', src, { job = job, grade = grade })
            NXN.Job.Log(('LoadPlayerJob: src=%d job=%s grade=%d'):format(src, job, grade))
        end
    )
end

-- ── Adatbázis tábla regisztráció ─────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if GetResourceState('nxn-database') ~= 'started' then return end
    exports['nxn-database']:execute([[
        CREATE TABLE IF NOT EXISTS `nxn_player_jobs` (
            `identifier` VARCHAR(100) NOT NULL PRIMARY KEY,
            `job`        VARCHAR(50)  NOT NULL DEFAULT 'unemployed',
            `grade`      TINYINT      NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]], {})
    NXN.Job.Info('nxn_player_jobs tábla ellenőrizve/létrehozva.')
end)

-- ── Játékos be/kilépés ──────────────────────────────────────────

AddEventHandler('nxn-database:playerLoaded', function(src)
    LoadPlayerJob(src)
end)

-- Fallback: vanilla playerConnecting / ha nxn-database később tölt
AddEventHandler('playerConnecting', function()
    -- csak akkor, ha nxn-database nem fut (más esetben a fenti handler hozza be)
end)

AddEventHandler('nxn-database:playerUnloading', function(src)
    playerJobs[src] = nil
    NXN.Job.Log(('playerUnloading: cache törölve src=%d'):format(src))
end)

AddEventHandler('playerDropped', function()
    playerJobs[source] = nil
end)

-- ── Szerver exportok ───────────────────────────────────────────

exports('getJob', function(src)
    local data = playerJobs[src]
    if not data then return NXN.Job.BuildJobData(Config.DefaultJob, Config.DefaultGrade) end
    return NXN.Job.BuildJobData(data.job, data.grade)
end)

exports('setJob', function(src, job, grade)
    if not Config.Jobs[job] then
        NXN.Job.Warn(('setJob: ismeretlen munka: %s'):format(tostring(job)))
        return false
    end
    if not Config.Jobs[job].grades[grade] then
        NXN.Job.Warn(('setJob: ismeretlen rang: %s/%s'):format(tostring(job), tostring(grade)))
        return false
    end

    local identifier = GetIdentifier(src)
    if not identifier then return false end

    local oldData = playerJobs[src] or { job = Config.DefaultJob, grade = Config.DefaultGrade }

    if GetResourceState('nxn-database') == 'started' then
        exports['nxn-database']:execute(
            'INSERT INTO nxn_player_jobs (identifier, job, grade) VALUES (?, ?, ?) '
         .. 'ON DUPLICATE KEY UPDATE job=VALUES(job), grade=VALUES(grade)',
            { identifier, job, grade }
        )
    end

    playerJobs[src] = { job = job, grade = grade }

    local jobData = NXN.Job.BuildJobData(job, grade)
    TriggerClientEvent('nxn-job:client:jobUpdated', src, jobData)
    TriggerEvent('nxn-job:server:jobUpdated', src, oldData.job, oldData.grade, job, grade)

    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:notifyPlayer(src,
            ('Munkakör: %s – %s'):format(jobData.label, jobData.gradeLabel),
            'info'
        )
    end

    NXN.Job.Info(('setJob: src=%d %s/%d'):format(src, job, grade))
    return true
end)

exports('hasJob', function(src, job)
    local data = playerJobs[src]
    return data ~= nil and data.job == job
end)

exports('hasJobGrade', function(src, job, minGrade)
    local data = playerJobs[src]
    if not data then return false end
    return data.job == job and data.grade >= minGrade
end)

exports('getJobGrade', function(src)
    local data = playerJobs[src]
    return data and data.grade or Config.DefaultGrade
end)

exports('getSalary', function(src)
    local data = playerJobs[src]
    if not data then return 0 end
    local cfg = Config.Jobs[data.job]
    if not cfg then return 0 end
    local gradeCfg = cfg.grades[data.grade]
    return gradeCfg and gradeCfg.salary or 0
end)

exports('getJobConfig', function(jobId)
    return Config.Jobs[jobId]
end)

exports('getAllJobs', function()
    return Config.Jobs
end)

exports('getPlayersInJob', function(job)
    local result = {}
    for src, data in pairs(playerJobs) do
        if data.job == job then
            result[#result + 1] = { src = src, grade = data.grade }
        end
    end
    return result
end)

-- ── Admin parancs ───────────────────────────────────────────────

RegisterCommand('setjob', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.AdminAce) then
        NXN.Job.Warn(('setjob parancs megtagadva: src=%d'):format(src))
        return
    end
    local target = tonumber(args[1])
    local job    = args[2]
    local grade  = tonumber(args[3]) or 0
    if not target or not job then
        print('[nxn-job] Használat: /setjob [player_id] [job] [grade]')
        return
    end
    local ok = exports['nxn-job']:setJob(target, job, grade)
    if ok then
        NXN.Job.Info(('Admin setjob: src=%d target=%d job=%s grade=%d'):format(src, target, job, grade))
    end
end, true)
