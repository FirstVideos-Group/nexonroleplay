-- ============================================================
--  nxn-jobwork | client.lua
-- ============================================================

local isOnDuty     = false
local currentShift = nil  -- { job, grade, label, gradeLabel }

-- ── NPC regisztrálás ──────────────────────────────────────────

local function RegisterWorkplaceNPCs()
    if GetResourceState('nxn-npcconversation') ~= 'started' then return end

    for locationId, loc in pairs(Config.JobLocations) do
        local lid = locationId  -- closure
        exports['nxn-npcconversation']:registerNPC(loc.npc.id, {
            label    = loc.label,
            model    = loc.npc.model,
            coords   = loc.npc.coords,
            scenario = loc.npc.scenario,
            blip     = loc.npc.blip,
            dialogues = {
                {
                    id        = 'clockin',
                    label     = 'Műszak kezdete',
                    icon      = 'hgi-clock-01',
                    response  = 'Kezdjk el a műszakot!',
                    condition = 'nxn-jobwork:client:canClockIn',
                    eventName = 'nxn-jobwork:client:clockIn',
                    eventData = lid,
                },
                {
                    id        = 'clockout',
                    label     = 'Műszak vge',
                    icon      = 'hgi-door-01',
                    response  = 'Jó munkt vgzett!',
                    condition = 'nxn-jobwork:client:canClockOut',
                    eventName = 'nxn-jobwork:client:clockOut',
                },
                {
                    id        = 'salary',
                    label     = 'Fizets lekrdse',
                    icon      = 'hgi-dollar-01',
                    response  = 'Az aktulis kereseted:',
                    eventName = 'nxn-jobwork:client:requestSalaryInfo',
                },
            },
        })
    end
    NXN.JobWork.Log('Munkahelyi NPC-k regisztrálva: ' .. tostring(#Config.JobLocations or 0))
end

AddEventHandler('onClientResourceStart', function(res)
    if res ~= 'nxn-npcconversation' and res ~= GetCurrentResourceName() then return end
    RegisterWorkplaceNPCs()
end)

-- ── Dialóg feltételek ─────────────────────────────────────────

-- A nxn-npcconversation ha támogatja a condition callback-et:
AddEventHandler('nxn-jobwork:client:canClockIn', function(locationId, cb)
    if isOnDuty then
        if cb then cb(false) end
        return
    end
    local jobData = nil
    if GetResourceState('nxn-job') == 'started' then
        jobData = exports['nxn-job']:getLocalJob()
    end
    if not jobData or jobData.job == 'unemployed' then
        if cb then cb(false) end
        return
    end
    local loc = Config.JobLocations[locationId]
    if loc then
        local ok = (not loc.requiredJob or jobData.job == loc.requiredJob)
                and jobData.grade >= (loc.requiredGrade or 0)
        if cb then cb(ok) else return ok end
        return
    end
    if cb then cb(true) else return true end
end)

AddEventHandler('nxn-jobwork:client:canClockOut', function(cb)
    if cb then cb(isOnDuty) else return isOnDuty end
end)

-- ── Kliens eventek (NPC dialógokból triggerelve) ─────────────────

RegisterNetEvent('nxn-jobwork:client:clockIn', function(locationId)
    TriggerServerEvent('nxn-jobwork:server:clockIn', locationId)
end)

RegisterNetEvent('nxn-jobwork:client:clockOut', function()
    TriggerServerEvent('nxn-jobwork:server:clockOut')
end)

RegisterNetEvent('nxn-jobwork:client:requestSalaryInfo', function()
    TriggerServerEvent('nxn-jobwork:server:requestSalaryInfo')
end)

-- ── Szerver → kliens eventek ───────────────────────────────────

RegisterNetEvent('nxn-jobwork:client:clockedIn', function(data)
    isOnDuty     = true
    currentShift = data
    NXN.JobWork.Log(('clockedIn: job=%s grade=%s'):format(tostring(data.job), tostring(data.gradeLabel)))
end)

RegisterNetEvent('nxn-jobwork:client:clockedOut', function(data)
    isOnDuty     = false
    currentShift = nil
    NXN.JobWork.Log(('clockedOut: payout=%d duration=%ds'):format(data.payout or 0, data.duration or 0))
end)

RegisterNetEvent('nxn-jobwork:client:partialPay', function(data)
    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:send(
            ('Részfizets: +%d Ft | Összesen: %d Ft'):format(data.amount or 0, data.earnedTotal or 0),
            'success'
        )
    end
end)

-- ── Kliens exportok ──────────────────────────────────────────

exports('isOnDutyLocal', function()
    return isOnDuty
end)

exports('getCurrentShift', function()
    return currentShift
end)
