-- ============================================================
--  nxn-vehicle-hud | modules/siren.lua
--  Szirena statusz – az nxn-sirencontrol resource kezeli
--  Export: exports['nxn-vehicle-hud']:setSiren(active, mode)
--  Modul csak akkor latszik, ha a szirena aktiv.
-- ============================================================

NXN.VehHUD.Log('siren modul betoltve (passziv, nxn-sirencontrol kezeli)')

-- Peldakod az nxn-sirencontrol resource-ban:
-- AddEventHandler('nxn-sirencontrol:changed', function(active, mode)
--     exports['nxn-vehicle-hud']:setSiren(active, mode)
-- end)
