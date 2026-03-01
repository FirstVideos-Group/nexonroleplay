-- ============================================================
--  nxn-shop | server.lua
-- ============================================================

-- Runtime boltok cache (registerShop exporthoz)
local runtimeShops = {}

-- Stock cache: { [shopId] = { [itemName] = amount } }
local stockCache = {}

-- ── Segédfüggvények ──────────────────────────────────────────

local function GetShopDef(shopId)
    return Config.Shops[shopId] or runtimeShops[shopId]
end

local function GetAllShopDefs()
    local all = {}
    for k, v in pairs(Config.Shops) do all[k] = v end
    for k, v in pairs(runtimeShops) do all[k] = v end
    return all
end

-- Bolt item megkeresése
local function FindShopItem(shop, itemName)
    for _, entry in ipairs(shop.items or {}) do
        if entry.item == itemName then return entry end
    end
    return nil
end

-- Stock beolvasás cache-be ha nincs ott
local function EnsureStock(shopId, itemName, defaultStock)
    stockCache[shopId] = stockCache[shopId] or {}
    if stockCache[shopId][itemName] ~= nil then
        return stockCache[shopId][itemName]
    end
    -- DB-ből próbálunk betölteni
    local row = MySQL.single.await(
        'SELECT stock FROM `nxn_shop_stock` WHERE shop_id = ? AND item_name = ?',
        { shopId, itemName }
    )
    if row then
        stockCache[shopId][itemName] = row.stock
    else
        stockCache[shopId][itemName] = defaultStock
        MySQL.insert.await(
            'INSERT INTO `nxn_shop_stock` (shop_id, item_name, stock) VALUES (?, ?, ?)',
            { shopId, itemName, defaultStock }
        )
    end
    return stockCache[shopId][itemName]
end

local function SaveStock(shopId, itemName, amount)
    stockCache[shopId] = stockCache[shopId] or {}
    stockCache[shopId][itemName] = amount
    MySQL.update(
        'UPDATE `nxn_shop_stock` SET stock = ? WHERE shop_id = ? AND item_name = ?',
        { amount, shopId, itemName }
    )
end

-- Inventory item def lekérdezés (nxn-inventory config)
local function GetItemDef(itemName)
    if GetResourceState('nxn-inventory') == 'started' then
        -- nxn-inventory nem exportálja a config-ot, de a szerveren shared script fut, Config megosztott
        -- Fallback: visszaadjuk az item nevét
        return { label = itemName, icon = 'hgi-store-01', weight = 0 }
    end
    return { label = itemName, icon = 'hgi-store-01', weight = 0 }
end

-- ── DB tábla regisztrálás ─────────────────────────────────────

local function RegisterTable()
    NXN.Shop.Info('nxn_shop_stock tábla regisztrálása...')
    local ok = exports['nxn-database']:registerTable(Config.ResourceName, {
        name = 'nxn_shop_stock',
        sql  = [[
            CREATE TABLE IF NOT EXISTS `nxn_shop_stock` (
                `shop_id`   VARCHAR(64)  NOT NULL,
                `item_name` VARCHAR(64)  NOT NULL,
                `stock`     INT          NOT NULL DEFAULT 0,
                `updated_at` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`shop_id`, `item_name`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]]
    })
    if ok then NXN.Shop.Info('nxn_shop_stock tábla OK.')
    else       NXN.Shop.Error('Tábla regisztrálás sikertelen!') end
end

-- ── Auto stock refill ─────────────────────────────────────────

if Config.StockRefillInterval and Config.StockRefillInterval > 0 then
    CreateThread(function()
        while true do
            Wait(Config.StockRefillInterval * 1000)
            NXN.Shop.Info('Stock refill futtatása...')
            local allShops = GetAllShopDefs()
            for shopId, shop in pairs(allShops) do
                for _, entry in ipairs(shop.items or {}) do
                    if entry.stock and entry.stock > 0 then
                        SaveStock(shopId, entry.item, entry.stock)
                        TriggerEvent('nxn-shop:server:stockUpdated', shopId, entry.item, entry.stock)
                        NXN.Shop.Log(('Refill: %s/%s -> %d'):format(shopId, entry.item, entry.stock))
                    end
                end
            end
        end
    end)
end

-- ── Bolt adatok összeállítása kliensnek ──────────────────────

local function BuildShopData(shopId, shop)
    local items = {}
    for _, entry in ipairs(shop.items or {}) do
        -- nxn-inventory Config megosztott, hozzáférhetünk
        local invItem = (type(Config) == 'table' and type(Config.Items) == 'table') and Config.Items[entry.item] or nil
        local stock = nil
        if entry.stock ~= nil then
            stock = EnsureStock(shopId, entry.item, entry.stock)
        end
        table.insert(items, {
            item   = entry.item,
            label  = entry.label or (invItem and invItem.label) or entry.item,
            icon   = (invItem and invItem.icon) or 'hgi-store-01',
            price  = entry.price,
            weight = (invItem and invItem.weight) or 0,
            stock  = stock,
        })
    end
    return {
        label    = shop.label,
        category = shop.category or 'general',
        canSell  = shop.canSell and Config.SellEnabled or false,
        sellPriceMultiplier = shop.sellPriceMultiplier or 0.4,
        items    = items,
    }
end

-- ── Net events ───────────────────────────────────────────────

RegisterServerEvent('nxn-shop:server:requestShop', function(shopId, mode)
    local src  = source
    local shop = GetShopDef(shopId)
    if not shop then
        NXN.Shop.Warn(('requestShop: ismeretlen bolt: %s'):format(shopId))
        return
    end

    local money = 0
    if GetResourceState('nxn-finance') == 'started' then
        money = exports['nxn-finance']:getMoney(src) or 0
    end

    local shopData = BuildShopData(shopId, shop)
    TriggerClientEvent('nxn-shop:client:shopData', src, shopId, shopData, money, mode or 'buy')
    NXN.Shop.Log(('requestShop: src=%d shop=%s mode=%s'):format(src, shopId, mode or 'buy'))
end)

RegisterServerEvent('nxn-shop:server:requestInventory', function()
    local src = source
    local inv = exports['nxn-inventory']:getInventory(src)
    local result = {}
    if inv and inv.items then
        for itemName, slot in pairs(inv.items) do
            local invItem = (type(Config) == 'table' and type(Config.Items) == 'table') and Config.Items[itemName] or nil
            table.insert(result, {
                item   = itemName,
                label  = (invItem and invItem.label) or itemName,
                icon   = (invItem and invItem.icon) or 'hgi-store-01',
                count  = slot.count or 1,
                weight = (invItem and invItem.weight) or 0,
            })
        end
    end
    TriggerClientEvent('nxn-shop:client:inventoryData', src, result)
end)

RegisterServerEvent('nxn-shop:server:buy', function(shopId, itemName, amount)
    local src    = source
    local amount = math.max(1, tonumber(amount) or 1)
    local shop   = GetShopDef(shopId)
    if not shop then
        NXN.Shop.Warn(('buy: ismeretlen bolt: %s'):format(shopId))
        return
    end

    local entry = FindShopItem(shop, itemName)
    if not entry then
        exports['nxn-notify']:notifyPlayer(src, 'Ez a termék nem elérhető ebben a boltban!', 'danger')
        return
    end

    local invItem = (type(Config.Items) == 'table') and Config.Items[itemName] or nil
    local label   = entry.label or (invItem and invItem.label) or itemName
    local total   = entry.price * amount

    -- 1. Pénz ellenőrzés
    local balance = 0
    if GetResourceState('nxn-finance') == 'started' then
        balance = exports['nxn-finance']:getMoney(src) or 0
    end
    if balance < total then
        exports['nxn-notify']:notifyPlayer(src, 'Nincs elég pénzed!', 'danger')
        TriggerClientEvent('nxn-shop:client:buyResult', src, false, 'Nincs elég pénzed!', balance)
        return
    end

    -- 2. Stock ellenőrzés (ha véges)
    if entry.stock ~= nil then
        local currentStock = EnsureStock(shopId, itemName, entry.stock)
        if currentStock < amount then
            exports['nxn-notify']:notifyPlayer(src, 'Elfogyott a készlet!', 'warn')
            TriggerClientEvent('nxn-shop:client:buyResult', src, false, 'Elfogyott a készlet!', balance)
            return
        end
    end

    -- 3. Pénz levonás
    if GetResourceState('nxn-finance') == 'started' then
        exports['nxn-finance']:removeMoney(src, total, nil, label .. ' vásárlás (' .. shopId .. ')', 'nxn-shop')
    end

    -- 4. Item hozzáadás
    local ok, err = exports['nxn-inventory']:addItem(src, itemName, amount)
    if not ok then
        -- Visszatérítés
        if GetResourceState('nxn-finance') == 'started' then
            exports['nxn-finance']:addMoney(src, total, nil, 'Visszatérítés: ' .. label, 'nxn-shop')
        end
        local errMsg = err or 'Nincs elég helyed!'
        exports['nxn-notify']:notifyPlayer(src, errMsg, 'warn')
        TriggerClientEvent('nxn-shop:client:buyResult', src, false, errMsg, balance)
        return
    end

    -- 5. Stock csökkentés
    if entry.stock ~= nil then
        local newStock = (stockCache[shopId] and stockCache[shopId][itemName] or entry.stock) - amount
        SaveStock(shopId, itemName, math.max(0, newStock))
        TriggerEvent('nxn-shop:server:stockUpdated', shopId, itemName, newStock)
    end

    -- 6. Értesítés + result
    local newBalance = 0
    if GetResourceState('nxn-finance') == 'started' then
        newBalance = exports['nxn-finance']:getMoney(src) or 0
    end
    exports['nxn-notify']:notifyPlayer(src, ('%s x%d megvásárolva! -$%s'):format(label, amount, total), 'success')
    TriggerClientEvent('nxn-shop:client:buyResult', src, true, nil, newBalance)

    NXN.Shop.Log(('buy OK: src=%d shop=%s item=%s x%d total=$%d'):format(src, shopId, itemName, amount, total))
end)

RegisterServerEvent('nxn-shop:server:sell', function(shopId, itemName, amount)
    local src    = source
    local amount = math.max(1, tonumber(amount) or 1)
    local shop   = GetShopDef(shopId)
    if not shop then return end

    if not shop.canSell or not Config.SellEnabled then
        exports['nxn-notify']:notifyPlayer(src, 'Ebben a boltban nem lehet eladni!', 'danger')
        return
    end

    local entry = FindShopItem(shop, itemName)
    if not entry then
        exports['nxn-notify']:notifyPlayer(src, 'Ezt a tárgyat nem vesszük meg!', 'danger')
        return
    end

    local invItem = (type(Config.Items) == 'table') and Config.Items[itemName] or nil
    local label   = entry.label or (invItem and invItem.label) or itemName
    local sellPrice = math.floor(entry.price * (shop.sellPriceMultiplier or 0.4)) * amount

    -- Ellenőrzés: van-e az inventoryban
    local hasIt = exports['nxn-inventory']:hasItem(src, itemName, amount)
    if not hasIt then
        exports['nxn-notify']:notifyPlayer(src, 'Nincs nálad annyi tárgy!', 'danger')
        TriggerClientEvent('nxn-shop:client:sellResult', src, false, 'Nincs nálad annyi tárgy!', nil)
        return
    end

    -- Item eltávolítás
    local ok = exports['nxn-inventory']:removeItem(src, itemName, amount)
    if not ok then
        exports['nxn-notify']:notifyPlayer(src, 'Eladás sikertelen!', 'danger')
        TriggerClientEvent('nxn-shop:client:sellResult', src, false, 'Eladás sikertelen!', nil)
        return
    end

    -- Pénz hozzáadás
    if GetResourceState('nxn-finance') == 'started' then
        exports['nxn-finance']:addMoney(src, sellPrice, nil, label .. ' eladás (' .. shopId .. ')', 'nxn-shop')
    end

    local newBalance = 0
    if GetResourceState('nxn-finance') == 'started' then
        newBalance = exports['nxn-finance']:getMoney(src) or 0
    end
    exports['nxn-notify']:notifyPlayer(src, ('%s x%d eladva! +$%d'):format(label, amount, sellPrice), 'success')
    TriggerClientEvent('nxn-shop:client:sellResult', src, true, nil, newBalance)

    NXN.Shop.Log(('sell OK: src=%d shop=%s item=%s x%d earn=$%d'):format(src, shopId, itemName, amount, sellPrice))
end)

-- ── Resource start ───────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= Config.ResourceName then return end
    NXN.Shop.Info('nxn-shop elindul...')
    CreateThread(function()
        RegisterTable()
        NXN.Shop.Info('nxn-shop kész.')
    end)
end)

-- ── Exportok ─────────────────────────────────────────────────

exports('getShop', function(shopId)
    return GetShopDef(shopId)
end)

exports('getAllShops', function()
    return GetAllShopDefs()
end)

exports('getShopStock', function(shopId, itemName)
    if not stockCache[shopId] then return nil end
    return stockCache[shopId][itemName]
end)

exports('setShopStock', function(shopId, itemName, amount)
    local amount = tonumber(amount) or 0
    SaveStock(shopId, itemName, amount)
    TriggerEvent('nxn-shop:server:stockUpdated', shopId, itemName, amount)
    NXN.Shop.Log(('setShopStock: %s/%s = %d'):format(shopId, itemName, amount))
end)

exports('addShopItem', function(shopId, itemDef)
    local shop = GetShopDef(shopId)
    if not shop then return false end
    table.insert(shop.items, itemDef)
    NXN.Shop.Log(('addShopItem: %s -> %s'):format(shopId, itemDef.item))
    return true
end)

exports('removeShopItem', function(shopId, itemName)
    local shop = GetShopDef(shopId)
    if not shop then return false end
    for i, entry in ipairs(shop.items or {}) do
        if entry.item == itemName then
            table.remove(shop.items, i)
            NXN.Shop.Log(('removeShopItem: %s/%s eltávolítva'):format(shopId, itemName))
            return true
        end
    end
    return false
end)

exports('registerShop', function(shopId, cfg)
    if runtimeShops[shopId] then
        NXN.Shop.Warn(('registerShop: %s már létezik, felülírás...'):format(shopId))
    end
    runtimeShops[shopId] = cfg
    NXN.Shop.Log(('registerShop: %s regisztrálva'):format(shopId))
    return true
end)

exports('unregisterShop', function(shopId)
    if runtimeShops[shopId] then
        runtimeShops[shopId] = nil
        NXN.Shop.Log(('unregisterShop: %s eltávolítva'):format(shopId))
        return true
    end
    return false
end)
