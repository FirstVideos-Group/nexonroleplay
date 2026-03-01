-- ============================================================
--  nxn-vehicle-hud | modules/gear.lua
--  Fokozat: R / N / 1-8
-- ============================================================

CreateThread(function()
    local lastGear    = -1
    local lastReverse = false

    while true do
        Wait(Config.PollInterval)

        if not NXN.VehHUD.State.inVehicle    then goto continue end
        if not NXN.VehHUD.State.moduleStates['gear'] then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        local gear = GetVehicleCurrentGear(veh)

        -- Hatra-eszleles: vector3 mezo-hozzaferes (.x/.y) GetEntityForwardVector/Velocity
        -- #118: table.unpack(vector3) runtime hibat dobott (vector3 != Lua table)
        local reverse = false
        if gear == 0 then
            local speed = GetEntitySpeed(veh)
            local fwd   = GetEntityForwardVector(veh)
            local vel   = GetEntityVelocity(veh)
            local dot   = fwd.x * vel.x + fwd.y * vel.y
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
