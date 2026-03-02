-- ============================================================
--  nxn-unemployment | client.lua
-- ============================================================

-- ── NPC regisztrálás ──────────────────────────────────────────

local function RegisterClerk()
    if GetResourceState('nxn-npcconversation') ~= 'started' then return end
    exports['nxn-npcconversation']:registerNPC('unemployment_clerk', {
        label    = Config.NPCLabel,
        model    = Config.NPCModel,
        coords   = Config.NPCCoords,
        scenario = Config.NPCScenario,
        blip     = Config.NPCBlip,
        dialogues = {
            {
                id        = 'status',
                label     = 'Segély állapota',
                icon      = 'hgi-file-01',
                response  = 'Egybő megnézem az adatait...',
                event     = 'nxn-unemployment:client:requestStatus',
            },
            {
                id        = 'nextpay',
                label     = 'Mikor kapom a következő segélyt?',
                icon      = 'hgi-clock-01',
                response  = 'A következő utalás időpontja:',
                event     = 'nxn-unemployment:client:requestNextPay',
            },
        },
    })
    NXN.Unemployment.Log('NPC regisztrálva: unemployment_clerk')
end

AddEventHandler('onClientResourceStart', function(res)
    if res ~= 'nxn-npcconversation' and res ~= GetCurrentResourceName() then return end
    RegisterClerk()
end)

-- ── Kliens eventek ──────────────────────────────────────────

RegisterNetEvent('nxn-unemployment:client:paid', function(data)
    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:send(
            ('Munkanélküli segély: +%d Ft'):format(data.amount),
            'success'
        )
    end
    NXN.Unemployment.Log(('paid: %d Ft, következő: %s'):format(data.amount, NXN.Unemployment.FormatTime(data.nextPayIn)))
end)

RegisterNetEvent('nxn-unemployment:client:statusUpdate', function(data)
    if GetResourceState('nxn-notify') ~= 'started' then return end
    if data.isActive then
        local timeStr = NXN.Unemployment.FormatTime(data.nextPayIn)
        exports['nxn-notify']:send(
            ('Segély aktív. Következő kifizetés: %s múlva.'):format(timeStr)
            .. ('\nEddigi készülés: %d alkalom, %d Ft'):format(data.totalPaid or 0, data.totalAmount or 0),
            'info'
        )
    else
        exports['nxn-notify']:send(
            'Nincs aktív segélyed. Jelenlegi munkaköröd nem munkanélküli.',
            'warning'
        )
    end
end)

-- ── NPC dialóg eventek ──────────────────────────────────────

RegisterNetEvent('nxn-unemployment:client:requestStatus', function()
    TriggerServerEvent('nxn-unemployment:server:getStatus')
end)

RegisterNetEvent('nxn-unemployment:client:requestNextPay', function()
    TriggerServerEvent('nxn-unemployment:server:getStatus')
end)

-- ── Loading progress ─────────────────────────────────────────

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if GetResourceState('nxn-loading') == 'started' then
        exports['nxn-loading']:updateModuleProgress('Segély', 100)
    end
end)
