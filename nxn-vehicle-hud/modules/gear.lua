-- ============================================================
--  nxn-vehicle-hud | modules/gear.lua
--  Fokozat: R / N / 1-8
-- ============================================================

CreateThread(function()
    local lastGear    = -1
    local lastReverse = false

    while true do
        Wait(Config.PollInterval)

        if not inVehicle then goto continue end
        if not moduleStates['gear'] then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        local gear = GetVehicleCurrentGear(veh)

        -- Hatra: GetVehicleCurrentGear == 0 ES a jarmű hatrafele halad
        -- GetEntitySpeedVector z-tengely nem megbizható, ezert
        -- a GetVehicleLastGear() + negatív gas kombót ellenőrizzük
        local reverse = false
        if gear == 0 then
            -- Ha a gaz-pedal lenyomva es az auto nem megy elore: hatra
            local speed = GetEntitySpeed(veh)
            local throttle = GetVehicleThrottleOffset(veh)
            -- ha sebesseg ~0 es gas lenyomva hatra
            -- Legjobb check: GetVehicleTransmissionMode visszater 0=drive,1=neutral,2=reverse
            -- de ez nem minden jarmuben mukodik. Biztosabb:
            -- negatív sebesség vektor dot forward
            local fwdX, fwdY, _ = table.unpack(GetEntityForwardVector(veh))
            local velX, velY, _ = table.unpack(GetEntityVelocity(veh))
            local dot = fwdX * velX + fwdY * velY
            reverse = speed > 0.5 and dot < -0.1
        end

        if gear ~= lastGear or reverse ~= lastReverse then
            lastGear    = gear
            lastReverse = reverse
            NXN.VehHUD.Log(('gear: %d reverse=%s'):format(gear, tostring(reverse)))
            SendNUIMessage({
                action  = 'updateModule',
                module  = 'gear',
                gear    = gear,
                reverse = reverse,
            })
        end

        ::continue::
    end
end)
