-- ============================================================
--  nxn-cityhall | client.lua
-- ============================================================

local isOpen        = false
local activeView    = nil   -- 'licenses' | 'fines' | 'info' | 'custom'
local npcBlip       = nil
local buildingBlip  = nil
local npcRegistered = false

-- ── Segédfüggvények ───────────────────────────────────────────

local function NUISend(action, data)
    local p = data or {}
    p.action = action
    NXN.CityHall.Log(('NUI send: %s'):format(action))
    SendNUIMessage(p)
end

local function CloseUI()
    isOpen     = false
    activeView = nil
    SetNuiFocus(false, false)
    NUISend('setVisible', { visible = false })
    NXN.CityHall.Log('UI bezárva')
end

local function OpenView(view, extraData)
    isOpen     = true
    activeView = view
    SetNuiFocus(true, true)
    local payload = extraData or {}
    payload.view   = view
    payload.config = {
        finesTitle   = Config.FinesPanel.title,
        finesEmpty   = Config.FinesPanel.emptyMsg,
        infoTitle    = Config.InfoContent.title,
        infoItems    = Config.InfoContent.items,
    }
    NUISend('openView', payload)
    NXN.CityHall.Log(('OpenView: %s'):format(view))
end

-- ── Blipek ────────────────────────────────────────────────

local function CreateBuildingBlip()
    if not Config.Building.blip.enabled then return end
    local b = Config.Building
    buildingBlip = AddBlipForCoord(b.coords.x, b.coords.y, b.coords.z)
    SetBlipSprite(buildingBlip, b.blip.sprite or 475)
    SetBlipColour(buildingBlip, b.blip.color or 4)
    SetBlipScale(buildingBlip, b.blip.scale or 0.9)
    SetBlipAsShortRange(buildingBlip, false)  -- mindig látszik
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(b.blip.label or b.name)
    EndTextCommandSetBlipName(buildingBlip)
    NXN.CityHall.Log('Building blip létrehozva')
end

local function CreateNPCBlip(coords)
    if not Config.NPC.blip.enabled then return end
    npcBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(npcBlip, Config.NPC.blip.sprite or 446)
    SetBlipColour(npcBlip, Config.NPC.blip.color or 5)
    SetBlipScale(npcBlip, Config.NPC.blip.scale or 0.7)
    SetBlipAsShortRange(npcBlip, true)    -- csak közelről látszik
    SetBlipDisplay(npcBlip, 0)            -- először rejtett
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.NPC.blip.label or Config.NPC.label)
    EndTextCommandSetBlipName(npcBlip)
    NXN.CityHall.Log('NPC blip létrehozva (rejtett)')
end

-- ── NPC regisztrálás az nxn-npcconversation-ban ───────────────────

local function BuildDialogues()
    local dialogues = {}
    for _, item in ipairs(Config.MenuItems) do
        table.insert(dialogues, {
            id       = item.id,
            label    = item.label,
            icon     = item.icon,
            response = item.response,
            event    = 'nxn-cityhall:action:' .. item.id,
        })
    end
    return dialogues
end

local function RegisterNPCWithConversation()
    if npcRegistered then return end
    if GetResourceState('nxn-npcconversation') ~= 'started' then
        NXN.CityHall.Warn('nxn-npcconversation nem fut, NPC nem regisztrálható!')
        return
    end

    local npc = Config.NPC
    local ok  = exports['nxn-npcconversation']:registerNPC(npc.id, {
        label    = npc.label,
        model    = npc.model,
        coords   = npc.coords,
        scenario = npc.scenario,
        blip     = { enabled = false },  -- saját blipet kezelünk
        dialogues = BuildDialogues(),
    })

    if ok then
        npcRegistered = true
        NXN.CityHall.Info(('NPC regisztrálva: %s'):format(npc.id))
        CreateNPCBlip(npc.coords)
    else
        NXN.CityHall.Warn('NPC regisztráció sikertelen (újraprobalkozás 5mp múlva)')
        SetTimeout(5000, RegisterNPCWithConversation)
    end
end

-- ── Menü elem akciók kezelése ───────────────────────────────

local function HandleAction(item)
    NXN.CityHall.Log(('HandleAction: id=%s action=%s'):format(
        tostring(item.id), tostring(item.action)
    ))

    if item.action == 'openLicenses' then
        -- először zárjuk be a beszélgetést
        if GetResourceState('nxn-npcconversation') == 'started' then
            exports['nxn-npcconversation']:closeConversation()
        end
        Wait(120)
        if GetResourceState('nxn-licenses') == 'started' then
            exports['nxn-licenses']:openLicenses()
        else
            NXN.CityHall.Warn('nxn-licenses nem fut!')
        end

    elseif item.action == 'openFines' then
        if GetResourceState('nxn-npcconversation') == 'started' then
            exports['nxn-npcconversation']:closeConversation()
        end
        Wait(120)
        TriggerServerEvent('nxn-cityhall:server:getFines')

    elseif item.action == 'openInfo' then
        if GetResourceState('nxn-npcconversation') == 'started' then
            exports['nxn-npcconversation']:closeConversation()
        end
        Wait(120)
        OpenView('info')

    elseif item.action == 'custom' and item.eventName then
        if GetResourceState('nxn-npcconversation') == 'started' then
            exports['nxn-npcconversation']:closeConversation()
        end
        Wait(120)
        TriggerEvent(item.eventName, { menuItemId = item.id })
        NXN.CityHall.Log(('Custom event kiváltás: %s'):format(item.eventName))
    end
end

-- ── nxn-npcconversation action eventek ──────────────────────────
-- Minden Config.MenuItems elemhez létrejön 'nxn-cityhall:action:<id>' event

for _, item in ipairs(Config.MenuItems) do
    local capturedItem = item
    AddEventHandler('nxn-cityhall:action:' .. item.id, function(data)
        NXN.CityHall.Log(('Action event: %s'):format(capturedItem.id))
        HandleAction(capturedItem)
    end)
end

-- ── NUI Callbackok ──────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('payFine', function(data, cb)
    NXN.CityHall.Log(('payFine NUI: id=%s'):format(tostring(data.fineId)))
    TriggerServerEvent('nxn-cityhall:server:payFine', data.fineId)
    cb('ok')
end)

-- ── Szerver események ─────────────────────────────────────────

RegisterNetEvent('nxn-cityhall:client:openFines', function(fines)
    NXN.CityHall.Log(('openFines kapott: %d db'):format(#fines))
    OpenView('fines', { fines = fines })
end)

RegisterNetEvent('nxn-cityhall:client:finesPaid', function(fineId)
    NXN.CityHall.Log(('Fine fizettt: %s'):format(tostring(fineId)))
    -- Frissítés: újra lekérdezük
    TriggerServerEvent('nxn-cityhall:server:getFines')
end)

-- ── NPC blip dinamikus láthatóság ──────────────────────────────
-- Csak Config.NPC.blip.visibleDist méteren belül látszik a blip

CreateThread(function()
    local visDist = Config.NPC.blip.visibleDist or 80.0
    local npcC    = Config.NPC.coords
    while true do
        Wait(1000)
        if npcBlip then
            local myPos  = GetEntityCoords(PlayerPedId())
            local npcPos = vector3(npcC.x, npcC.y, npcC.z)
            local dist   = #(myPos - npcPos)
            if dist < visDist then
                SetBlipDisplay(npcBlip, 2)  -- látható
            else
                SetBlipDisplay(npcBlip, 0)  -- rejtett
            end
        end
    end
end)

-- ── Inicializálás ─────────────────────────────────────────────

AddEventHandler('playerSpawned', function()
    NXN.CityHall.Info('Inicializálás...')
    Wait(1500)
    CreateBuildingBlip()
    RegisterNPCWithConversation()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= Config.ResourceName then return end
    if buildingBlip then RemoveBlip(buildingBlip) end
    if npcBlip      then RemoveBlip(npcBlip)      end
    if npcRegistered and GetResourceState('nxn-npcconversation') == 'started' then
        exports['nxn-npcconversation']:unregisterNPC(Config.NPC.id)
    end
end)

-- ESC bezárás
CreateThread(function()
    while true do
        Wait(0)
        if isOpen and IsControlJustReleased(0, 322) then
            CloseUI()
        end
        Wait(isOpen and 0 or 200)
    end
end)

-- ── Kliens exportok ──────────────────────────────────────────

--- Menüelem hozzáadása futás közben (más resource-ból)
---@param item table { id, label, icon, response, action, eventName? }
---@return boolean
exports('addMenuItem', function(item)
    if not item or not item.id then
        NXN.CityHall.Warn('addMenuItem: hiányzik item.id')
        return false
    end
    -- Duplikát ellenőrzés
    for _, m in ipairs(Config.MenuItems) do
        if m.id == item.id then
            NXN.CityHall.Warn(('addMenuItem: duplikát id: %s'):format(item.id))
            return false
        end
    end
    table.insert(Config.MenuItems, item)

    -- Event handler regisztrálása
    AddEventHandler('nxn-cityhall:action:' .. item.id, function()
        HandleAction(item)
    end)

    -- nxn-npcconversation frissítése
    if npcRegistered and GetResourceState('nxn-npcconversation') == 'started' then
        exports['nxn-npcconversation']:addDialogue(Config.NPC.id, {
            id       = item.id,
            label    = item.label,
            icon     = item.icon,
            response = item.response,
            event    = 'nxn-cityhall:action:' .. item.id,
        })
    end

    NXN.CityHall.Log(('addMenuItem: %s hozzáadva'):format(item.id))
    return true
end)

--- Menüelem eltávolítása
---@param itemId string
---@return boolean
exports('removeMenuItem', function(itemId)
    for i, m in ipairs(Config.MenuItems) do
        if m.id == itemId then
            table.remove(Config.MenuItems, i)
            if npcRegistered and GetResourceState('nxn-npcconversation') == 'started' then
                exports['nxn-npcconversation']:removeDialogue(Config.NPC.id, itemId)
            end
            NXN.CityHall.Log(('removeMenuItem: %s eltávolítva'):format(itemId))
            return true
        end
    end
    return false
end)

exports('openView',    function(view) OpenView(view) end)
exports('closePanel',  function()     CloseUI()      end)
exports('isOpen',      function()     return isOpen  end)
