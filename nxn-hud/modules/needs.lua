-- ============================================================
--  nxn-hud | modules/needs.lua
--  Hunger es thirst – az nxn-needs:client:updated eventre reagal
--  (nxn-needs exportok + event, lasd nxn-needs/client.lua)
-- ============================================================

-- Az nxn-needs:client:updated event figyelese a client.lua kozponti
-- AddEventHandlereben tortenik (client.lua ~70. sor)
-- Ez a fajl csak a kezdeti lekerdezest vegzi spawn utan.

AddEventHandler('playerSpawned', function()
    Wait(800)
    local ok, needs = pcall(function()
        return exports['nxn-needs']:getLocalNeeds()
    end)
    if ok and needs and next(needs) then
        NXN.HUD.Log('needs modul: kezdeti adatok betoltve spawn utan')
        NXN.HUD.Send('updateModule', { module = 'hunger', value = needs.hunger or 100 })
        NXN.HUD.Send('updateModule', { module = 'thirst', value = needs.thirst or 100 })
    else
        NXN.HUD.Warn('needs modul: nxn-needs nem elerheto vagy ures')
    end
end)
