-- ============================================================
--  nxn-hud | modules/oxygen.lua
--  FIX: setTimeout/clearTimeout nem letezik Lua-ban
--       GetGameTimer alapu hide timer hasznalata helyette
-- ============================================================

local hideAt = nil

CreateThread(function()
    local lastOxygen = -1
    local cfg = Config.Modules.oxygen

    while true do
        Wait(Config.OxygenPollInterval)
        if not hudVisible then goto continue end
        if not moduleStates['oxygen'] then goto continue end

        local ped     = PlayerPedId()
        local oxygen  = math.floor(GetPlayerUnderwaterTimeRemaining(PlayerId()))
        local inWater = IsPedSwimmingUnderWater(ped)

        if inWater then
            if oxygen ~= lastOxygen then
                lastOxygen = oxygen
                NXN.HUD.Send('updateModule', { module = 'oxygen', value = oxygen })
            end
            if not cfg.alwaysVisible then
                -- Vizben: megjelenik, hide timer torlese
                SendNUIMessage({ action = 'showModuleTemporary', module = 'oxygen' })
                hideAt = nil
            end
        else
            -- Kijott a vizbol: hide timer beallitasa
            if not cfg.alwaysVisible and not hideAt then
                hideAt = GetGameTimer() + (cfg.hideDelay or 3000)
            end
        end

        -- Hide timer lejar-e?
        if hideAt and GetGameTimer() >= hideAt then
            SendNUIMessage({ action = 'hideModuleTemporary', module = 'oxygen' })
            NXN.HUD.Send('updateModule', { module = 'oxygen', value = 100 })
            hideAt = nil
        end

        ::continue::
    end
end)
