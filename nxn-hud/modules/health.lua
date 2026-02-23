-- ============================================================
--  nxn-hud | modules/health.lua
--  Health (HP) es armor (pajzs) kezelese
-- ============================================================

CreateThread(function()
    local lastHp    = -1
    local lastArmor = -1

    while true do
        Wait(Config.PollInterval)
        if not hudVisible then goto continue end
        if not moduleStates['health'] then goto continue end

        local ped   = PlayerPedId()
        local hp    = math.floor(math.max(0, (GetEntityHealth(ped) - 100) / 1))
        local armor = math.floor(GetPedArmour(ped))

        -- Csak ha valtozott
        if hp ~= lastHp or armor ~= lastArmor then
            lastHp    = hp
            lastArmor = armor
            NXN.HUD.Log(('health poll: hp=%d armor=%d'):format(hp, armor))
            NXN.HUD.Send('updateModule', {
                module = 'health',
                value  = hp,
                armor  = armor,
            })
        end

        ::continue::
    end
end)
