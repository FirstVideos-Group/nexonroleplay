-- ============================================================
--  nxn-hud | modules/stamina.lua
--  Stamina (kifejezetten futaskor jelenik meg)
-- ============================================================

local hideTimer = nil

CreateThread(function()
    local lastStamina = -1
    local cfg = Config.Modules.stamina

    while true do
        Wait(Config.PollInterval)
        if not hudVisible then goto continue end
        if not moduleStates['stamina'] then goto continue end

        -- GTA nativan: stamina 0-100, csokken futasnal
        local stamina = math.floor(GetPlayerSprintStaminaRemaining(PlayerId()))

        if stamina ~= lastStamina then
            lastStamina = stamina
            NXN.HUD.Send('updateModule', { module = 'stamina', value = stamina })
            NXN.HUD.Log(('stamina: %d'):format(stamina))

            -- Megjelenes / eltunes logika
            if not cfg.alwaysVisible then
                if stamina < (cfg.threshold or 99) then
                    -- Fut: megjelenik
                    SendNUIMessage({ action = 'showModuleTemporary', module = 'stamina' })
                    if hideTimer then
                        clearTimeout(hideTimer)
                        hideTimer = nil
                    end
                else
                    -- Megalt: hide delay utan eltuntetes
                    if not hideTimer then
                        hideTimer = setTimeout(function()
                            SendNUIMessage({ action = 'hideModuleTemporary', module = 'stamina' })
                            hideTimer = nil
                        end, cfg.hideDelay or 4000)
                    end
                end
            end
        end

        ::continue::
    end
end)
