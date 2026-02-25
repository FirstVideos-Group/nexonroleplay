-- ============================================================
--  nxn-hud | modules/stress.lua
--  FIX: setTimeout/clearTimeout nem letezik Lua-ban
--       GetGameTimer alapu hide timer hasznalata helyette
-- ============================================================

local hideAt = nil
local cfg    = Config.Modules.stress

AddEventHandler('nxn-needs:client:updated', function(needs)
    if not moduleStates['stress'] then return end
    if not cfg then return end

    local stress = needs.stress or 0

    if not cfg.alwaysVisible then
        if stress > (cfg.threshold or 10) then
            -- Stresszes: megjelenik, hide timer torlese
            SendNUIMessage({ action = 'showModuleTemporary', module = 'stress' })
            hideAt = nil
        else
            -- Stressz visszacsment: hide timer beallitasa
            if not hideAt then
                hideAt = GetGameTimer() + (cfg.hideDelay or 5000)
            end
        end
    end
end)

-- Hide timer figyelese kulonallo szalban
CreateThread(function()
    while true do
        Wait(500)
        if hideAt and GetGameTimer() >= hideAt then
            SendNUIMessage({ action = 'hideModuleTemporary', module = 'stress' })
            hideAt = nil
        end
    end
end)
