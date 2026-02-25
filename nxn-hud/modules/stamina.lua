-- ============================================================
--  nxn-hud | modules/stamina.lua
--  FIX: setTimeout/clearTimeout nem letezik Lua-ban
--       GetGameTimer alapu hide timer hasznalata helyette
-- ============================================================

local hideAt = nil  -- GetGameTimer() ertek amikor el kell tunteni

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
            NXN.HUD.Send('updateModule', { module = 'stamina', value = stamina })

            if not cfg.alwaysVisible then
                if stamina < 100 then
                    -- Fogy: megjelenik, hide timer torlese
                    SendNUIMessage({ action = 'showModuleTemporary', module = 'stamina' })
                    hideAt = nil
                else
                    -- Teljesen visszatoltodott: hide timer beallitasa
                    if not hideAt then
                        hideAt = GetGameTimer() + (cfg.hideDelay or 4000)
                    end
                end
            end
        end

        -- Hide timer lejar-e?
        if hideAt and GetGameTimer() >= hideAt then
            SendNUIMessage({ action = 'hideModuleTemporary', module = 'stamina' })
            hideAt = nil
        end

        ::continue::
    end
end)
