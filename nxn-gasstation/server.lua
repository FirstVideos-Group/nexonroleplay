-- ============================================================
--  nxn-gasstation | server.lua
-- ============================================================

local activeRefuels = {}  -- [plate] = { src, stationId, requestedLiters }

-- ── Helpers ──────────────────────────────────────────────────

local function GetPricePerLiter(stationId)
    local s = Config.Stations[stationId]
    return (s and s.pricePerLiter) or Config.DefaultPricePerLiter
end

local function LogTransaction(identifier, plate, stationId, liters, price)
    if not Config.LogTransactions then return end
    if GetResourceState('nxn-database') ~= 'started' then return end
    exports['nxn-database']:execute(
        'INSERT INTO nxn_gasstation_log (identifier, plate, station, amount_l, price) VALUES (?, ?, ?, ?, ?)',
        { identifier, plate, stationId, liters, price }
    )
end

-- ── Net Events ───────────────────────────────────────────────

RegisterNetEvent('nxn-gasstation:server:startRefuel', function(data)
    local src       = source
    local plate     = data.plate
    local stationId = data.stationId
    local liters    = tonumber(data.requestedLiters) or 0

    if not plate or not stationId then return end
    if activeRefuels[plate] then
        TriggerClientEvent('nxn-gasstation:client:refuelFailed', src, { reason = 'Ez a jármű már tankálás alatt van!' })
        return
    end

    -- Szerver oldali közelség ellenőrzés
    local station = Config.Stations[stationId]
    if not station then
        TriggerClientEvent('nxn-gasstation:client:refuelFailed', src, { reason = 'Ismeretlen töltőállomás.' })
        return
    end

    local ped    = GetPlayerPed(src)
    local pedPos = GetEntityCoords(ped)
    local inRange = false
    for _, pump in ipairs(station.pumps) do
        if NXN.Gas.Distance(pedPos, pump.coords) <= Config.ServerCheckDistance then
            inRange = true
            break
        end
    end

    if not inRange then
        TriggerClientEvent('nxn-gasstation:client:refuelFailed', src, { reason = 'Túl messze vagy a pumpától.' })
        return
    end

    -- Liter clamp
    local tankSize    = 65.0
    local currentFuel = 50.0
    if GetResourceState('nxn-fuel') == 'started' then
        local f = exports['nxn-fuel']:getFuel(plate)
        local t = exports['nxn-fuel']:getTankSize(plate)
        if f then currentFuel = f end
        if t then tankSize    = t end
    end
    local maxFill = tankSize * (1 - currentFuel / 100)
    liters = math.min(liters, maxFill)
    liters = math.max(liters, 0)

    if liters < Config.MinRefuelAmount then
        TriggerClientEvent('nxn-gasstation:client:refuelFailed', src, { reason = 'A tartály tele van vagy nincs mit tölteni.' })
        return
    end

    -- Pénz ellenőrzés
    local pricePerL  = GetPricePerLiter(stationId)
    local totalPrice = math.floor(liters * pricePerL)

    if GetResourceState('nxn-finance') == 'started' then
        local balance = exports['nxn-finance']:getMoney(src)
        if (balance or 0) < totalPrice then
            TriggerClientEvent('nxn-gasstation:client:refuelFailed', src, { reason = 'Nincs elég pénzed!' })
            return
        end
    end

    -- Zár megnyitása
    activeRefuels[plate] = { src = src, stationId = stationId, requestedLiters = liters }

    TriggerClientEvent('nxn-gasstation:client:refuelAllowed', src, {
        ok              = true,
        maxLiters       = maxFill,
        pricePerLiter   = pricePerL,
        requestedLiters = liters,
    })

    NXN.Gas.Log(('startRefuel: src=%d plate=%s station=%s liters=%.1f price=%d'):format(src, plate, stationId, liters, totalPrice))
end)

RegisterNetEvent('nxn-gasstation:server:confirmRefuel', function(data)
    local src       = source
    local plate     = data.plate
    local stationId = data.stationId
    local liters    = tonumber(data.liters) or 0

    if not activeRefuels[plate] or activeRefuels[plate].src ~= src then
        TriggerClientEvent('nxn-gasstation:client:refuelFailed', src, { reason = 'Érvénytelen tankálási munkamenet.' })
        return
    end

    -- Re-clamp biztonsági ellenőrzés
    local tankSize    = 65.0
    local currentFuel = 50.0
    if GetResourceState('nxn-fuel') == 'started' then
        local f = exports['nxn-fuel']:getFuel(plate)
        local t = exports['nxn-fuel']:getTankSize(plate)
        if f then currentFuel = f end
        if t then tankSize    = t end
    end
    local maxFill = tankSize * (1 - currentFuel / 100)
    liters = math.min(liters, maxFill)
    liters = math.max(liters, 0)

    local pricePerL  = GetPricePerLiter(stationId)
    local totalPrice = math.floor(liters * pricePerL)

    -- Fizetés
    if GetResourceState('nxn-finance') == 'started' then
        local balance = exports['nxn-finance']:getMoney(src)
        if (balance or 0) < totalPrice then
            activeRefuels[plate] = nil
            TriggerClientEvent('nxn-gasstation:client:refuelFailed', src, { reason = 'Nincs elég pénzed!' })
            return
        end
        exports['nxn-finance']:removeMoney(src, totalPrice)
    end

    -- Üzemanyag hozzáadása (nxn-fuel kezeli)
    if GetResourceState('nxn-fuel') == 'started' then
        local addPercent = (liters / tankSize) * 100
        exports['nxn-fuel']:addFuel(plate, addPercent)
    end

    activeRefuels[plate] = nil

    -- Tranzakció broadcast + log
    local identifier = ''
    if GetResourceState('nxn-identity') == 'started' then
        identifier = tostring(exports['nxn-identity']:getIdentifier(src) or '')
    end
    TriggerEvent('nxn-gasstation:server:transaction', src, plate, stationId, liters, totalPrice)
    LogTransaction(identifier, plate, stationId, liters, totalPrice)

    TriggerClientEvent('nxn-gasstation:client:refuelDone', src, {
        plate       = plate,
        litersAdded = liters,
        totalPrice  = totalPrice,
    })

    NXN.Gas.Log(('confirmRefuel: src=%d plate=%s liters=%.1f price=%d'):format(src, plate, liters, totalPrice))
end)

RegisterNetEvent('nxn-gasstation:server:cancelRefuel', function(data)
    local plate = data and data.plate
    if plate and activeRefuels[plate] and activeRefuels[plate].src == source then
        activeRefuels[plate] = nil
        NXN.Gas.Log(('cancelRefuel: plate=%s'):format(plate))
    end
end)

-- ── Exports ──────────────────────────────────────────────────

exports('getStations', function()
    return Config.Stations
end)

exports('getPricePerLiter', function(stationId)
    return GetPricePerLiter(stationId)
end)

exports('isRefueling', function(plate)
    return activeRefuels[plate] ~= nil
end)
