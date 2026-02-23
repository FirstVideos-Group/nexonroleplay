-- ============================================================
--  nxn-hud | modules/oxygen.lua
--  Oxigen – csak vizben jelenik meg
-- ============================================================

local hideTimer = nil

CreateThread(function()
    local lastOxygen = -1
    local cfg = Config.Modules.oxygen

    while true do
        Wait(Config.OxygenPollInterval)
        if not hudVisible then goto continue end
        if not moduleStates['oxygen'] then goto continue end

        local ped    = PlayerPedId()
        local oxygen = math.floor(GetPlayerUnderwaterTimeRemaining(PlayerId()))
        -- GTA: viz alatti levego 100-tol 0-ig csokken
        -- Ha nem viz alatt van, 100 (vagy max)
        local inWater = IsPedSwimmingUnderWater(ped)

        if inWater then
            if oxygen ~= lastOxygen then
                lastOxygen = oxygen
                NXN.HUD.Send('updateModule', { module = 'oxygen', value = oxygen })
                NXN.HUD.Log(('oxygen: %d'):format(oxygen))
            end
            if not cfg.alwaysVisible then
                SendNUIMessage({ action = 'showModuleTemporary', module = 'oxygen' })
                if hideTimer then
                    clearTimeout(hideTimer)
                    hideTimer = nil
                end
            end
        else
            -- Kijott a vizbol
            if not cfg.alwaysVisible and not hideTimer then
                hideTimer = setTimeout(function()
                    SendNUIMessage({ action = 'hideModuleTemporary', module = 'oxygen' })
                    NXN.HUD.Send('updateModule', { module = 'oxygen', value = 100 })
                    hideTimer = nil
                end, cfg.hideDelay or 3000)
            end
        end

        ::continue::
    end
end)
