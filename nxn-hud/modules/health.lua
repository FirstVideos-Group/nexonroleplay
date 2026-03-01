-- ============================================================
--  nxn-hud | modules/health.lua
--  Health (HP) es armor (pajzs) kezelese
-- ============================================================

CreateThread(function()
    local lastHp    = -1
    local lastArmor = -1

    while true do
        Wait(Config.PollInterval)
        if not NXN.HUD.visible then goto continue end
        if not NXN.HUD.moduleStates['health'] then goto continue end

        local ped   = PlayerPedId()
        -- #26: GetEntityMaxHealth-szel skalazt HP, math.min(100) felso korlat
        local rawHp = GetEntityHealth(ped)
        local maxHp = GetEntityMaxHealth(ped)
        local hp    = math.floor(math.max(0, math.min(100,
            (rawHp - 100) / math.max(1, maxHp - 100) * 100
        )))
        local armor = math.floor(GetPedArmour(ped))

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
