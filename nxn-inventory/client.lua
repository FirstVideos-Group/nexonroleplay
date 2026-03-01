-- ============================================================
--  nxn-inventory | client.lua
-- ============================================================

local isOpen    = false
local inventory = { items = {}, hotbar = {} }

-- ── Notify helper (#38) ──────────────────────────────────────
-- GetResourceState guard véd a runtime hiba ellen ha nxn-notify még nem fut

local function Notify(msg, ntype)
    if GetResourceState('nxn-notify') ~= 'started' then return end
    local t = ntype or 'info'
    if     t == 'success' then exports['nxn-notify']:success(msg)
    elseif t == 'danger'  then exports['nxn-notify']:danger(msg)
    elseif t == 'warning' then exports['nxn-notify']:warning(msg)
    else                       exports['nxn-notify']:info(msg)
    end
end

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

--- String-kulcsú map elemeinek számlálása (# operátor nem működik számon)
local function countMap(t)
    local c = 0
    for _ in pairs(t) do c = c + 1 end
    return c
end

-- ── Inventory adat frissítése UI-ba ─────────────────────────────

local function PushToUI(inv)
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
        action      = 'updateInventory',
        items       = enriched,
        hotbar      = inv.hotbar or {},
        weight      = weight,
        maxWeight   = Config.MaxWeight,
        hotbarSlots = Config.HotbarSlots,
        itemDefs    = itemDefs,
    })

    NXN.Inventory.Log(('PushToUI: %d item, súly=%.2f/%.2f'):format(
        countMap(inv.items or {}),
        weight, Config.MaxWeight
    ))
end

-- ── Net events ──────────────────────────────────────────────

RegisterNetEvent('nxn-inventory:client:sync', function(data)
    NXN.Inventory.Log('Szinkronizáció fogadva')
    inventory = data or { items = {}, hotbar = {} }
    PushToUI(inventory)
end)

RegisterNetEvent('nxn-inventory:client:useResult', function(ok, itemName, errMsg)
    local def   = NXN.Inventory.GetItemDef(itemName)
    local label = def and def.label or itemName
    if ok then
        Notify(('Használtad: %s'):format(label), 'success')
    else
        Notify(errMsg or 'Nem használható.', 'warning')
    end
end)

-- #39 – dropResult: szerver visszaigazolás után értesítés
RegisterNetEvent('nxn-inventory:client:dropResult', function(ok, itemName)
    if not ok then return end
    local def   = NXN.Inventory.GetItemDef(itemName)
    local label = def and def.label or itemName
    Notify(('Eldobtad: %s'):format(label), 'info')
end)

RegisterNetEvent('nxn-inventory:client:applyHeal', function(amount)
    NXN.Inventory.Log(('applyHeal: +%d HP'):format(amount))
    local ped   = PlayerPedId()
    local curHp = GetEntityHealth(ped)
    SetEntityHealth(ped, math.min(curHp + amount, 200))
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

-- #39 – dropItem: értesítés csak szerver visszaigazolás után (dropResult event)
RegisterNUICallback('dropItem', function(data, cb)
    NXN.Inventory.Log(('NUI dropItem: %s x%d'):format(tostring(data.item), data.count or 1))
    TriggerServerEvent('nxn-inventory:server:dropItem', data.item, data.count or 1)
    cb('ok')
end)

-- #38 – deleteItem: Notify helper használata guard-dal
RegisterNUICallback('deleteItem', function(data, cb)
    NXN.Inventory.Log(('NUI deleteItem: %s x%d'):format(tostring(data.item), data.count or 1))
    TriggerServerEvent('nxn-inventory:server:deleteItem', data.item, data.count or 1)
    Notify(('Törölted: %s'):format(
        (NXN.Inventory.GetItemDef(data.item) or {}).label or data.item
    ), 'warning')
    cb('ok')
end)

RegisterNUICallback('updateHotbar', function(data, cb)
    NXN.Inventory.Log('NUI updateHotbar')
    TriggerServerEvent('nxn-inventory:server:updateHotbar', data.hotbar or {})
    inventory.hotbar = data.hotbar or {}
    cb('ok')
end)

-- ── Billentyűkezelés ──────────────────────────────────────────

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
        if isOpen then
            Citizen.Wait(0)
            if IsControlJustPressed(0, 322) then  -- ESC
                SetUIVisible(false)
            end
        else
            Citizen.Wait(100)
            if IsControlJustPressed(0, 289) then  -- F1
                TriggerServerEvent('nxn-inventory:server:requestSync')
                SetUIVisible(true)
            end
        end
    end
end)

-- ── Exportok ─────────────────────────────────────────────────

exports('openInventory',  function() if not isOpen then SetUIVisible(true)  end end)
exports('closeInventory', function() if isOpen     then SetUIVisible(false) end end)
exports('isOpen',         function() return isOpen end)

-- #43 (kliens oldal) – getLocalInventory shallow copy-t ad vissza
exports('getLocalInventory', function()
    local copy = { items = {}, hotbar = {} }
    for k, v in pairs(inventory.items  or {}) do copy.items[k]  = v end
    for k, v in pairs(inventory.hotbar or {}) do copy.hotbar[k] = v end
    return copy
end)

exports('getLocalWeight', function()
    return NXN.Inventory.CalcWeight(inventory.items or {})
end)
