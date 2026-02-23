-- ============================================================
--  nxn-hud | modules/stress.lua
--  Stress – az nxn-needs eventbol jon, kuszob felett jelenik meg
-- ============================================================

local hideTimer = nil
local cfg = Config.Modules.stress

-- A stress erteket az nxn-needs event adja (client.lua kezeli)
-- Ez a fajl a show/hide logika ra iranyítasara szolgal

AddEventHandler('nxn-needs:client:updated', function(needs)
    if not moduleStates['stress'] then return end
    if not cfg then return end

    local stress = needs.stress or 0

    if not cfg.alwaysVisible then
        if stress > (cfg.threshold or 10) then
            SendNUIMessage({ action = 'showModuleTemporary', module = 'stress' })
            if hideTimer then
                clearTimeout(hideTimer)
                hideTimer = nil
            end
            NXN.HUD.Log(('stress megjelenik: %d'):format(stress))
        else
            if not hideTimer then
                hideTimer = setTimeout(function()
                    SendNUIMessage({ action = 'hideModuleTemporary', module = 'stress' })
                    hideTimer = nil
                end, cfg.hideDelay or 5000)
            end
        end
    end
end)
