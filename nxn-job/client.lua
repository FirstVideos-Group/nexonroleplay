-- ============================================================
--  nxn-job | client.lua
-- ============================================================

local localJobData = nil  -- cache: { job, grade, label, gradeLabel, salary, color }
local firstLoad    = true

-- ── Net Events ───────────────────────────────────────────────

RegisterNetEvent('nxn-job:client:jobUpdated', function(data)
    localJobData = data
    NXN.Job.Log(('jobUpdated: %s/%s'):format(tostring(data.job), tostring(data.gradeLabel)))

    -- HUD frissítés
    if GetResourceState('nxn-hud') == 'started' then
        exports['nxn-hud']:updateModuleData('job', {
            name  = data.label,
            grade = data.gradeLabel,
            color = data.color,
        })
    end

    -- Betöltési folyamat jelés
    if firstLoad then
        firstLoad = false
        if GetResourceState('nxn-loading') == 'started' then
            exports['nxn-loading']:updateModuleProgress('Munkakör', 100)
        end
    end
end)

-- ── Kliens exportok ───────────────────────────────────────────

exports('getLocalJob', function()
    if localJobData then return localJobData end
    -- fallback
    return NXN.Job.BuildJobData(Config.DefaultJob, Config.DefaultGrade)
end)

exports('hasLocalJob', function(job)
    return localJobData ~= nil and localJobData.job == job
end)
