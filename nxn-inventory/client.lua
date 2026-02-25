-- ============================================================
--  nxn-inventory | client.lua
-- ============================================================

local isOpen    = false
local inventory = { items = {}, hotbar = {} }

-- ── UI küldés ─────────────────────────────────────────────────

local function SendUI(data)
    SendNUIMessage(data)
end

local function SetUIVisible(state)
    isOpen = state
    SetNuiFocus(state, state)
    SendUI({ action = 'setVisible', visible = state })
    NXN.Inventory.Log(('SetUIVisible: %s'):format(tostring(state)))
end

-- ── Inventory adat frissítése UI-ba ────────────────────────────

local function PushToUI(inv)
    -- Kiegészítés: item definiciókat is küldjük
    local enriched = {}
    for name, slot in pairs(inv.items or {}) do
        local def = NXN.Inventory.GetItemDef(name)
        if def then
            enriched[name] = {
                count    = slot.count or 1,
                label    = def.label,
                icon     = def.icon,
                weight   = def.weight,
                usable   = def.usable or false,
                category = def.category or 'misc',
            }
        end
    end

    -- Item definiciók (hotbar képhez)
    local itemDefs = {}
    for name, def in pairs(Config.Items) do
        itemDefs[name] = {
            label    = def.label,
            icon     = def.icon,
            weight   = def.weight,
            usable   = def.usable or false,
            category = def.category or 'misc',
        }
    end

    local weight = NXN.Inventory.CalcWeight(inv.items or {})

    SendUI({
        action    = 'updateInventory',
        items     = enriched,
        hotbar    = inv.hotbar or {},
        weight    = weight,
        maxWeight = Config.MaxWeight,
        hotbarSlots = Config.HotbarSlots,
        itemDefs  = itemDefs,
    })
    NXN.Inventory.Log(('PushToUI: %d item, súly=%.2f/%.2f'):format(
        #(function() local c=0; for _ in pairs(inv.items or {}) do c=c+1 end; return c end)(),
        weight, Config.MaxWeight
    ))
end

-- ── Net events ────────────────────────────────────────────────

RegisterNetEvent('nxn-inventory:client:sync', function(data)
    NXN.Inventory.Log('Szinkronizáció fogadva')
    inventory = data or { items = {}, hotbar = {} }
    PushToUI(inventory)
end)

RegisterNetEvent('nxn-inventory:client:useResult', function(ok, itemName, errMsg)
    local def = NXN.Inventory.GetItemDef(itemName)
    local label = def and def.label or itemName
    if ok then
        exports['nxn-notify']:success(('Használtad: %s'):format(label))
    else
        exports['nxn-notify']:warning(errMsg or 'Nem használható.')
    end
end)

RegisterNetEvent('nxn-inventory:client:applyHeal', function(amount)
    NXN.Inventory.Log(('applyHeal: +%d HP'):format(amount))
    local ped  = PlayerPedId()
    local curHp = GetEntityHealth(ped)
    local maxHp = 200  -- GTA alap max
    SetEntityHealth(ped, math.min(curHp + amount, maxHp))
end)

-- ── NUI callbacks ────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    SetUIVisible(false)
    cb('ok')
end)

RegisterNUICallback('useItem', function(data, cb)
    NXN.Inventory.Log(('NUI useItem: %s'):format(tostring(data.item)))
    TriggerServerEvent('nxn-inventory:server:useItem', data.item)
    cb('ok')
end)

RegisterNUICallback('dropItem', function(data, cb)
    NXN.Inventory.Log(('NUI dropItem: %s x%d'):format(tostring(data.item), data.count or 1))
    TriggerServerEvent('nxn-inventory:server:dropItem', data.item, data.count or 1)
    exports['nxn-notify']:info(('Eldobtad: %s'):format(
        (NXN.Inventory.GetItemDef(data.item) or {}).label or data.item
    ))
    cb('ok')
end)

RegisterNUICallback('deleteItem', function(data, cb)
    NXN.Inventory.Log(('NUI deleteItem: %s x%d'):format(tostring(data.item), data.count or 1))
    TriggerServerEvent('nxn-inventory:server:deleteItem', data.item, data.count or 1)
    exports['nxn-notify']:warning(('Törölted: %s'):format(
        (NXN.Inventory.GetItemDef(data.item) or {}).label or data.item
    ))
    cb('ok')
end)

RegisterNUICallback('updateHotbar', function(data, cb)
    NXN.Inventory.Log('NUI updateHotbar')
    TriggerServerEvent('nxn-inventory:server:updateHotbar', data.hotbar or {})
    inventory.hotbar = data.hotbar or {}
    cb('ok')
end)

-- ── Billentyűkezelés ────────────────────────────────────────────

RegisterCommand('inventory', function()
    if isOpen then
        SetUIVisible(false)
    else
        TriggerServerEvent('nxn-inventory:server:requestSync')
        SetUIVisible(true)
    end
end, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        -- F1 (vagy config-olt billentyű)
        if IsControlJustPressed(0, 289) then  -- F1
            if isOpen then
                SetUIVisible(false)
            else
                TriggerServerEvent('nxn-inventory:server:requestSync')
                SetUIVisible(true)
            end
        end
        -- ESC bezárás
        if isOpen and IsControlJustPressed(0, 322) then
            SetUIVisible(false)
        end
    end
end)

-- ── Exportok ──────────────────────────────────────────────────

exports('openInventory',  function() if not isOpen then SetUIVisible(true)  end end)
exports('closeInventory', function() if isOpen     then SetUIVisible(false) end end)
exports('isOpen',         function() return isOpen end)
exports('getLocalInventory', function() return inventory end)
exports('getLocalWeight', function()
    return NXN.Inventory.CalcWeight(inventory.items or {})
end)
