-- ============================================================
--  nxn-location-hud | modules/danger.lua
--  Veszelyesseg szint – passziv, az nxn-dispatch resource toltiheti
--  Export: exports['nxn-location-hud']:setDanger(level, label)
--  level: 0 (nincs) - 5 (kritikus)
-- ============================================================

NXN.LocHUD.Log('danger modul betoltve (passziv, nxn-dispatch toltiheti)')

-- Peldakod az nxn-dispatch resource-ban:
-- AddEventHandler('nxn-dispatch:alert', function(level, label)
--     exports['nxn-location-hud']:setDanger(level, label)
-- end)
-- AddEventHandler('nxn-dispatch:clear', function()
--     exports['nxn-location-hud']:setDanger(0)
-- end)
