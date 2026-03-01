-- ============================================================
--  nxn-vehicle-hud | modules/fuel.lua
--  Az uzemanyag erteket az nxn-fuel resource kuldi
--  exports['nxn-vehicle-hud']:setFuel(value) hivason keresztul.
--  #121: Az indulaskor tortenl 'return' eltavolitva – a modul-check
--  a loopon belulre koltozott, igy kesobb engedelyezett modul is mukodik.
-- ============================================================

CreateThread(function()
    local lastFuel = -1

    while true do
        Wait(2000)

        if not NXN.VehHUD.State.inVehicle            then goto continue end
        -- #121: moduleStates ellenorzese minden ciklusban (nem indulaskor egyszer)
        if not NXN.VehHUD.State.moduleStates['fuel'] then goto continue end

        -- Ha az nxn-fuel fut, a setFuel export kezeli az erteket
        if GetResourceState('nxn-fuel') == 'started' then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        local tankMax   = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fPetrolTankVolume')
        local tankLevel = GetVehicleFuelLevel(veh)
        local pct = 0
        if tankMax and tankMax > 0 then
            pct = math.floor((tankLevel / tankMax) * 100)
        else
            pct = math.floor(tankLevel)
        end
        pct = math.max(0, math.min(100, pct))

        if pct ~= lastFuel then
            lastFuel = pct
            NXN.VehHUD.Log(('fuel fallback: %d%%'):format(pct))
            SendNUIMessage({
                action = 'updateModule',
                module = 'fuel',
                value  = pct,
            })
        end

        ::continue::
    end
end)
