-- ============================================================
--  nxn-hud | modules/stamina.lua
--  FIX: stamina megjelenesi logika javitva
--   - GetPlayerSprintStaminaRemaining: 100 = teli, 0 = ures
--   - megjelenik ha stamina < 100 (azaz fut / fogyaszt)
--   - eltunk ha visszatoltodott 100-ra (hideDelay utan)
--   - a bar ertek: stamina (0-100), nem megforditva
-- ============================================================

local hideTimer = nil

CreateThread(function()
    local lastStamina = -1
    local cfg = Config.Modules.stamina

    while true do
        Wait(Config.PollInterval)
        if not hudVisible then goto continue end
        if not moduleStates['stamina'] then goto continue end

        -- 100 = teli stamina, 0 = teljesen lemerult
        local stamina = math.floor(GetPlayerSprintStaminaRemaining(PlayerId()))

        if stamina ~= lastStamina then
            lastStamina = stamina

            -- A bar egyenesen toltodik: 100% = teli, 0% = ures
            NXN.HUD.Send('updateModule', { module = 'stamina', value = stamina })
            NXN.HUD.Log(('stamina: %d'):format(stamina))

            if not cfg.alwaysVisible then
                if stamina < 100 then
                    -- Fogy a stamina: megjelenik
                    SendNUIMessage({ action = 'showModuleTemporary', module = 'stamina' })
                    if hideTimer then
                        clearTimeout(hideTimer)
                        hideTimer = nil
                    end
                else
                    -- Teljesen visszatoltodott: hideDelay utan eltuntetes
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
