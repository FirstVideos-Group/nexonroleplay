-- ============================================================
--  nxn-vehicles | client.lua
-- ============================================================

local inVehicle      = false
local currentVehicle = 0
local currentPlate   = ''
local currentClass   = -1

-- ── Járműbe lépés detekció loop ─────────────────────────────────────
CreateThread(function()
    while true do
        Wait(Config.VehicleCheckInterval)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        -- Szállj be egy járműbe
        if veh ~= 0 and not inVehicle then
            inVehicle      = true
            currentVehicle = veh
            currentPlate   = NXN.Vehicles.NormalizePlate(GetVehicleNumberPlateText(veh))
            currentClass   = GetVehicleClass(veh)

            NXN.Vehicles.Log(('entered: plate=%s class=%d'):format(currentPlate, currentClass))
            TriggerServerEvent('nxn-vehicles:server:entered', currentPlate, currentClass)

        -- Kiszallás
        elseif veh == 0 and inVehicle then
            NXN.Vehicles.Log(('exited: plate=%s'):format(currentPlate))
            TriggerServerEvent('nxn-vehicles:server:exited', currentPlate)

            -- Motor HP mentése kiszalláskor (ha nxn-engine fut)
            if Config.PersistEngineHP and GetResourceState('nxn-engine') == 'started' then
                local hp = exports['nxn-engine']:getEngineHP()
                if type(hp) == 'number' then
                    TriggerServerEvent('nxn-vehicles:server:saveHP', currentPlate, hp)
                end
            end

            inVehicle      = false
            currentVehicle = 0
            currentPlate   = ''
            currentClass   = -1
        end
    end
end)

-- ── Net eventek ───────────────────────────────────────────────

-- Motor HP szinkronizáció (szerver küldi belépéskor)
RegisterNetEvent('nxn-vehicles:client:engineHPSync', function(data)
    if not data or not data.hp then return end
    NXN.Vehicles.Log(('engineHPSync: plate=%s hp=%.1f'):format(tostring(data.plate), data.hp))

    -- nxn-engine setEngineHP kliens export
    if GetResourceState('nxn-engine') == 'started' then
        exports['nxn-engine']:setEngineHP(data.hp)
    end
end)

-- ── Kliens exportok ──────────────────────────────────────────

--- Aktuális jármű rendszáma
---@return string
exports('getCurrentVehiclePlate', function()
    return currentPlate
end)

--- Aktuális jármű osztálya
---@return integer
exports('getCurrentVehicleClass', function()
    return currentClass
end)

--- Járműben van-e a játékos
---@return boolean
exports('isInVehicle', function()
    return inVehicle
end)
