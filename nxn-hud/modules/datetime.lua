-- ============================================================
--  nxn-hud | modules/datetime.lua
--  Valos ido es datum megjelenitese (percenkent frissul)
-- ============================================================

CreateThread(function()
    while true do
        if hudVisible and moduleStates['datetime'] then
            -- FiveM nem fedi le az os.date-t NUI kezeles nelkul,
            -- ezert NUI-n at a JS oldal kezeli az idos megjeleniteset
            SendNUIMessage({ action = 'tickDatetime' })
        end
        Wait(60000)  -- percenkent frissul
    end
end)

-- Inicializalas spawn utan
AddEventHandler('playerSpawned', function()
    if moduleStates['datetime'] then
        SendNUIMessage({ action = 'tickDatetime' })
    end
end)
