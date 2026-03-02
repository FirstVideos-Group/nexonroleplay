-- ============================================================
--  nxn-vehicleshop | server.lua
-- ============================================================

-- ── Segédfüggvények ──────────────────────────────────────────

local function Notify(src, msg, ntype)
    if GetResourceState('nxn-notify') ~= 'started' then return end
    exports['nxn-notify']:notify(src, msg, ntype or 'info')
end

local function GetIdentifier(src)
    if GetResourceState('nxn-database') ~= 'started' then return nil end
    return exports['nxn-database']:getIdentifier(src)
end

--- Kereskedő és jármű adatainak keresése
---@param dealerId string
---@param model    string
---@return table|nil, table|nil
local function FindDealerAndItem(dealerId, model)
    for _, dealer in ipairs(Config.Dealers) do
        if dealer.id == dealerId then
            for _, v in ipairs(dealer.vehicles) do
                if v.model == model then
                    return dealer, v
                end
            end
        end
    end
    return nil, nil
end

--- Van-e már ilyen modellje a játékosnak
---@param src   integer
---@param model string
---@return boolean
local function HasVehicleModel(src, model)
    if GetResourceState('nxn-vehicles') ~= 'started' then return false end
    local identifier = GetIdentifier(src)
    if not identifier then return false end
    local vehicles = exports['nxn-vehicles']:getVehicles(identifier)
    for _, v in ipairs(vehicles or {}) do
        if v.model == model then return true end
    end
    return false
end

-- ── Vásárlás net event ───────────────────────────────────────

RegisterNetEvent('nxn-vehicleshop:server:buy', function(model, dealerId, useFinancing, months)
    local src = source
    NXN.VehicleShop.Log(('buy: src=%d model=%s dealer=%s finance=%s'):format(src, tostring(model), tostring(dealerId), tostring(useFinancing)))

    local dealer, item = FindDealerAndItem(dealerId, model)
    if not dealer or not item then
        Notify(src, 'Érvénytelen jármű vagy kereskedő.', 'danger')
        return
    end

    -- Jogosítvány ellenőrzés
    if Config.RequireLicense and GetResourceState('nxn-licenses') == 'started' then
        local hasLic = exports['nxn-licenses']:hasLicense(src, 'drivers_license')
        if not hasLic then
            Notify(src, 'Nincs érvényes jogosítványod! Vásárláshoz szükséges.', 'danger')
            return
        end
    end

    -- Duplikált jármű ellenőrzés
    if not Config.AllowDuplicatePurchase and HasVehicleModel(src, model) then
        Notify(src, 'Már van ilyen járműved!', 'warning')
        return
    end

    local price = item.price

    -- Finanszírozás
    if useFinancing and Config.FinancingEnabled and GetResourceState('nxn-finance') == 'started' then
        local mths = math.max(Config.Financing.MinMonths, math.min(Config.Financing.MaxMonths, tonumber(months) or Config.Financing.DefaultMonths))
        local total = math.floor(price * (1 + Config.Financing.InterestRate * (mths / 12)))
        local monthly = math.ceil(total / mths)

        -- Elég pénz az első részlethez
        local balance = exports['nxn-finance']:getMoney(src, 'bank')
        if balance < monthly then
            Notify(src, ('Nincs elég pénz az első részlethez! (Szükséges: $%d)'):format(monthly), 'danger')
            return
        end

        local ok = exports['nxn-finance']:removeMoney(src, monthly, 'bank', 'Járművásárlás – 1. részlet: ' .. item.label, 'nxn-vehicleshop')
        if not ok then
            Notify(src, 'Pénzlevonás sikertelen.', 'danger')
            return
        end

        -- Adósság regisztrálása (ha az nxn-finance támogatja)
        if exports['nxn-finance']['addDebt'] then
            exports['nxn-finance']:addDebt(src, total - monthly, monthly, item.label .. ' – részlet')
        end

        NXN.VehicleShop.Log(('financing: src=%d total=%d monthly=%d months=%d'):format(src, total, monthly, mths))
    else
        -- Egyszeri vásárlás
        if GetResourceState('nxn-finance') ~= 'started' then
            Notify(src, 'A pénzügyi rendszer nem elérhető.', 'danger')
            return
        end

        local balance = exports['nxn-finance']:getMoney(src, 'bank')
        if balance < price then
            Notify(src, ('Nincs elég pénzed! (Szükséges: $%d)'):format(price), 'danger')
            return
        end

        local ok = exports['nxn-finance']:removeMoney(src, price, 'bank', 'Járművásárlás: ' .. item.label, 'nxn-vehicleshop')
        if not ok then
            Notify(src, 'Pénzlevonás sikertelen.', 'danger')
            return
        end
    end

    -- Jármű regisztrálása
    if GetResourceState('nxn-vehicles') ~= 'started' then
        -- Visszatérítés ha a vehicles script nem fut
        exports['nxn-finance']:addMoney(src, price, 'bank', 'Visszatérítés – nxn-vehicles nem fut', 'nxn-vehicleshop')
        Notify(src, 'Jármű rendszer nem elérhető!', 'danger')
        return
    end

    local identifier = GetIdentifier(src)
    if not identifier then
        exports['nxn-finance']:addMoney(src, price, 'bank', 'Visszatérítés – azonosító hiba', 'nxn-vehicleshop')
        Notify(src, 'Azonosítási hiba, próbáld újra.', 'danger')
        return
    end

    local plate = exports['nxn-vehicles']:addVehicle(identifier, model, item.label, 0, nil)
    if not plate then
        exports['nxn-finance']:addMoney(src, price, 'bank', 'Visszatérítés – jármű regisztrálás sikertelen', 'nxn-vehicleshop')
        Notify(src, 'Jármű regisztrálása sikertelen!', 'danger')
        return
    end

    -- Garázsba mentés vásárlás után
    if GetResourceState('nxn-garage') == 'started' then
        exports['nxn-vehicles']:setStored(plate, true)
        exports['nxn-vehicles']:setGarage(plate, dealer.defaultGarage or 'main_garage')
        NXN.VehicleShop.Log(('setStored+setGarage: plate=%s garage=%s'):format(plate, dealer.defaultGarage or 'main_garage'))
    end

    TriggerClientEvent('nxn-vehicleshop:client:purchased', src, model, item.label, plate)
    Notify(src, ('Gratulálunk! Megvásároltad: %s – Rendszám: %s'):format(item.label, plate), 'success')

    TriggerEvent('nxn-vehicleshop:server:purchased', src, model, plate, item.price)
    NXN.VehicleShop.Info(('Vásárlás: src=%d model=%s plate=%s price=%d'):format(src, model, plate, item.price))
end)

-- ── Teszt-menet jármű törlés (disconnect) ───────────────────

AddEventHandler('playerDropped', function()
    local src = source
    TriggerEvent('nxn-vehicleshop:server:cleanTestDrive', src)
end)

-- ── Exportok (szerver) ───────────────────────────────────────

--- Kereskedő összes járműve
---@param dealerId string
---@return table[]
exports('getShopItems', function(dealerId)
    for _, dealer in ipairs(Config.Dealers) do
        if dealer.id == dealerId then
            return dealer.vehicles
        end
    end
    return {}
end)

--- Egy konkrét jármű adatai
---@param dealerId string
---@param model    string
---@return table|nil
exports('getShopItem', function(dealerId, model)
    local _, item = FindDealerAndItem(dealerId, model)
    return item
end)
