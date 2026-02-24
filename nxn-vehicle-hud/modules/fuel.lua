-- ============================================================
--  nxn-vehicle-hud | modules/fuel.lua
--  Uzemanyag – az nxn-fuel resource toltiheti
--  Export: exports['nxn-vehicle-hud']:setFuel(value)  (0-100)
--  Ez a modul passziv: csak a NUI frissiteset tartalmazza,
--  az adatot az nxn-fuel client.lua-ja pusholja.
-- ============================================================

NXN.VehHUD.Log('fuel modul betoltve (passziv, nxn-fuel toltiheti)')

-- Peldakod az nxn-fuel resource-ban (sajat client.lua):
-- AddEventHandler('nxn-fuel:updated', function(value)
--     exports['nxn-vehicle-hud']:setFuel(value)
-- end)
