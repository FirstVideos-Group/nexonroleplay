-- ============================================================
--  nxn-food | server.lua
-- ============================================================

-- ── Net events ───────────────────────────────────────────────

-- Inventory-ból item használat kérése
RegisterServerEvent('nxn-food:server:use', function(itemName)
    local src  = source
    local item = Config.Items[itemName]
    if not item then
        NXN.Food.Warn(('Ismeretlen item: %s (src: %s)'):format(itemName, src))
        return
    end

    -- Ellenőrzés: van-e az inventoryban
    local hasIt = exports['nxn-inventory']:hasItem(src, itemName)
    if not hasIt then
        exports['nxn-notify']:notifyPlayer(src, 'Nincs nálad ilyen tárgy!', 'danger')
        return
    end

    -- Ellenőrzés: nem teli-e a has (hunger)
    if item.hunger and item.hunger > 0 then
        local currentHunger = exports['nxn-needs']:getNeed(src, 'hunger')
        if currentHunger and currentHunger >= 90 then
            exports['nxn-notify']:notifyPlayer(src, 'Már nem vagy éhes!', 'warn')
            return
        end
    end

    -- Ellenőrzés: nem teli-e a szomjúság
    if item.thirst and item.thirst > 0 then
        local currentThirst = exports['nxn-needs']:getNeed(src, 'thirst')
        if currentThirst and currentThirst >= 90 then
            exports['nxn-notify']:notifyPlayer(src, 'Már nem vagy szomjas!', 'warn')
            return
        end
    end

    local itemData = {}
    for k, v in pairs(item) do itemData[k] = v end
    itemData.itemName = itemName

    TriggerClientEvent('nxn-food:client:consume', src, itemData)
    NXN.Food.Log(('consume triggerelve -> src:%s item:%s'):format(src, itemName))
end)

-- Animáció lefutott, hatás alkalmazása
RegisterServerEvent('nxn-food:server:consumed', function(itemName)
    local src  = source
    local item = Config.Items[itemName]
    if not item then return end

    -- nxn-needs hatások alkalmazása
    if item.hunger  and item.hunger  ~= 0 then exports['nxn-needs']:modifyNeed(src, 'hunger',  item.hunger)  end
    if item.thirst  and item.thirst  ~= 0 then exports['nxn-needs']:modifyNeed(src, 'thirst',  item.thirst)  end
    if item.stress  and item.stress  ~= 0 then exports['nxn-needs']:modifyNeed(src, 'stress',  item.stress)  end
    if item.fatigue and item.fatigue ~= 0 then exports['nxn-needs']:modifyNeed(src, 'fatigue', item.fatigue) end

    -- Item eltávolítása az inventoryból
    exports['nxn-inventory']:removeItem(src, itemName, 1)

    -- Értesítés
    exports['nxn-notify']:notifyPlayer(src, (item.label or itemName) .. ' elfogyasztva!', 'success')

    -- Lokális event más scriptek számára
    TriggerEvent('nxn-food:client:consumed', src, {
        itemName = itemName,
        effects  = {
            hunger  = item.hunger,
            thirst  = item.thirst,
            stress  = item.stress,
            fatigue = item.fatigue,
        },
    })

    NXN.Food.Log(('consumed: src:%s item:%s'):format(src, itemName))
end)

-- Bolt adatok küldése kliensnek
RegisterServerEvent('nxn-food:server:requestShop', function(shopId)
    local src  = source
    local shop = Config.Shops[shopId]
    if not shop then return end

    local money = 0
    if GetResourceState('nxn-finance') == 'started' then
        money = exports['nxn-finance']:getMoney(src) or 0
    end

    -- Összeállítjuk a bolt item listát (label-lel kiegészítve)
    local shopData = {
        label = shop.label,
        items = {},
    }
    for _, entry in ipairs(shop.items) do
        local itemDef = Config.Items[entry.item]
        if itemDef then
            table.insert(shopData.items, {
                item   = entry.item,
                label  = itemDef.label,
                icon   = itemDef.icon,
                price  = entry.price,
                hunger = itemDef.hunger,
                thirst = itemDef.thirst,
            })
        end
    end

    TriggerClientEvent('nxn-food:client:shopData', src, shopId, shopData, money)
end)

-- Vásárlás logika
RegisterServerEvent('nxn-food:server:buy', function(shopId, itemName)
    local src  = source
    local shop = Config.Shops[shopId]
    if not shop then return end

    -- Megkeressük az árat
    local price = nil
    for _, entry in ipairs(shop.items) do
        if entry.item == itemName then
            price = entry.price
            break
        end
    end
    if not price then
        exports['nxn-notify']:notifyPlayer(src, 'Ez a termék nem elérhető ebben a boltban!', 'danger')
        return
    end

    local item = Config.Items[itemName]
    if not item then return end

    -- Pénzellenőrzés
    if GetResourceState('nxn-finance') == 'started' then
        local balance = exports['nxn-finance']:getMoney(src) or 0
        if balance < price then
            exports['nxn-notify']:notifyPlayer(src, 'Nincs elég pénzed!', 'danger')
            return
        end
        exports['nxn-finance']:removeMoney(src, price, nil, 'Étel vásárlás: ' .. item.label, 'nxn-food')
    end

    -- Item hozzáadása az inventoryhoz
    local ok, err = exports['nxn-inventory']:addItem(src, itemName, 1)
    if not ok then
        -- Ha nem sikerült, pénzt visszaadjuk
        if GetResourceState('nxn-finance') == 'started' then
            exports['nxn-finance']:addMoney(src, price, nil, 'Visszatérítés: ' .. item.label, 'nxn-food')
        end
        exports['nxn-notify']:notifyPlayer(src, err or 'Nem sikerült hozzáadni a tárgyat!', 'warn')
        return
    end

    exports['nxn-notify']:notifyPlayer(src, (item.label or itemName) .. ' megvásárolva!', 'success')

    -- Frissített pénzegyenleg küldése a UI-nak
    local newMoney = 0
    if GetResourceState('nxn-finance') == 'started' then
        newMoney = exports['nxn-finance']:getMoney(src) or 0
    end
    TriggerClientEvent('nxn-food:client:buyResult', src, true, newMoney)

    NXN.Food.Log(('buy: src:%s item:%s price:%s'):format(src, itemName, price))
end)

-- ── Exports ──────────────────────────────────────────────────

exports('getItem', function(itemName)
    return Config.Items[itemName]
end)

exports('getAllItems', function()
    return Config.Items
end)

exports('getShops', function()
    return Config.Shops
end)

exports('isConsumable', function(itemName)
    return Config.Items[itemName] ~= nil
end)

exports('consumeItem', function(src, itemName)
    local item = Config.Items[itemName]
    if not item then return false end
    local itemData = {}
    for k, v in pairs(item) do itemData[k] = v end
    itemData.itemName = itemName
    TriggerClientEvent('nxn-food:client:consume', src, itemData)
    return true
end)
