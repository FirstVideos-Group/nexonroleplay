-- ============================================================
--  nxn-hud | modules/stress.lua
--  Stressz kezeles: ertek kuldese + show/hide logika
--  #27: updateModule kuldese (ertek)
--  #28: teljes stress logika itt van, client.lua-ban nincs stress ag
-- ============================================================

local hideAt = nil
local cfg    = Config.Modules.stress

AddEventHandler('nxn-needs:client:updated', function(needs)
    if not NXN.HUD.moduleStates['stress'] then return end
    if not cfg then return end

    local stress = needs.stress or 0

    -- #27: Ertek kuldese a NUI-ba
    NXN.HUD.Send('updateModule', { module = 'stress', value = stress })

    -- Show/hide logika
    if not cfg.alwaysVisible then
        if stress > (cfg.threshold or 10) then
            SendNUIMessage({ action = 'showModuleTemporary', module = 'stress' })
            hideAt = nil
        else
            if not hideAt then
                hideAt = GetGameTimer() + (cfg.hideDelay or 5000)
            end
        end
    end
end)

-- Hide timer figyelese
CreateThread(function()
    while true do
        Wait(500)
        if hideAt and GetGameTimer() >= hideAt then
            SendNUIMessage({ action = 'hideModuleTemporary', module = 'stress' })
            hideAt = nil
        end
    end
end)
