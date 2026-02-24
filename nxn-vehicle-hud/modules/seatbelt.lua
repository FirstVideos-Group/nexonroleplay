-- ============================================================
--  nxn-vehicle-hud | modules/seatbelt.lua
--  Biztonsagi ov – az nxn-seatbelt resource kezeli
--  Export: exports['nxn-vehicle-hud']:setSeatbelt(fastened)
--  Modul csak akkor latszik, ha nincs bekotve a ov.
-- ============================================================

NXN.VehHUD.Log('seatbelt modul betoltve (passziv, nxn-seatbelt kezeli)')

-- Peldakod az nxn-seatbelt resource-ban:
-- AddEventHandler('nxn-seatbelt:changed', function(fastened)
--     exports['nxn-vehicle-hud']:setSeatbelt(fastened)
-- end)
