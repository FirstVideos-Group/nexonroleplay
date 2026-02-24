-- ============================================================
--  nxn-location-hud | modules/wanted.lua
--  Korozesi informacio – passziv, az nxn-wantedstatus resource toltiheti
--  Export: exports['nxn-location-hud']:setWanted(wanted, level, label)
-- ============================================================

NXN.LocHUD.Log('wanted modul betoltve (passziv, nxn-wantedstatus toltiheti)')

-- Peldakod az nxn-wantedstatus resource-ban:
-- RegisterNetEvent('nxn-wantedstatus:client:update', function(wanted, stars, label)
--     exports['nxn-location-hud']:setWanted(wanted, stars, label)
-- end)
