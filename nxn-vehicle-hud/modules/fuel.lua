-- ============================================================
--  nxn-vehicle-hud | modules/fuel.lua
--  Az uzemanyag erteket az nxn-fuel resource kuldi
--  exports['nxn-vehicle-hud']:setFuel(value) hivason keresztul.
--  Ez a modul csak a HUD-ra valo beiratkozasrol gondoskodik.
-- ============================================================

-- Ha az nxn-fuel nem fut, de a fuel modul engedelyezve van,
-- GTA alap tank erteket olvassuk ki fallback-kent
if not Config.Modules.fuel.enabled then return end

CreateThread(function()
    local lastFuel = -1

    while true do
        Wait(2000)  -- uzemanyag lassan valtozik

        if not inVehicle then goto continue end

        -- Csak akkor hasznalunk fallback-et, ha az nxn-fuel nem fut
        if GetResourceState('nxn-fuel') == 'started' then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        -- GTA natív tank level: 0.0 - 65.0 (max tank kapacitas)
        local tankMax   = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fPetrolTankVolume')
        local tankLevel = GetVehicleFuelLevel(veh)
        local pct = 0
        if tankMax and tankMax > 0 then
            pct = math.floor((tankLevel / tankMax) * 100)
        else
            pct = math.floor(tankLevel)  -- fallback: direkt ertek
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
