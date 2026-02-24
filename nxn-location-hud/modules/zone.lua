-- ============================================================
--  nxn-location-hud | modules/zone.lua
--  Zona es banda neve – passziv, az nxn-gang resource toltiheti
--  Export: exports['nxn-location-hud']:setZone(zoneName, gangName, gangColor)
--         exports['nxn-location-hud']:clearZone()
-- ============================================================

NXN.LocHUD.Log('zone modul betoltve (passziv, nxn-gang toltiheti)')

-- Peldakod az nxn-gang resource-ban:
-- AddEventHandler('nxn-gang:zoneEntered', function(zoneName, gangName, gangColor)
--     exports['nxn-location-hud']:setZone(zoneName, gangName, gangColor)
-- end)
-- AddEventHandler('nxn-gang:zoneLeft', function()
--     exports['nxn-location-hud']:clearZone()
-- end)
