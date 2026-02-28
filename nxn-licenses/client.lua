-- ============================================================
--  nxn-licenses | client.lua
-- ============================================================

local isOpen        = false
local licenses      = {}   -- { [type] = row }
local pending       = {}   -- { [type] = row }
local invItems      = {}   -- { [itemName] = true } – helyi inventory cache tükrözés

-- ── Inventory szinkron figyelese ──────────────────────────────
-- Minden alkalommal amikor az nxn-inventory szinkronizál a klienssel,
-- frissítjük a helyi invItems cache-t is.

RegisterNetEvent('nxn-inventory:client:sync', function(data)
    invItems = {}
    if data and data.items then
        for itemName, _ in pairs(data.items) do
            invItems[itemName] = true
        end
    end
    NXN.Licenses.Log(('invItems frissítve: %d tárgy'):format((function()
        local c = 0
        for _ in pairs(invItems) do c = c + 1 end
        return c
    end)()))
    -- Ha az UI nyitva van, frissítjük a nézetet
    if isOpen then PushToUI() end
end)

-- ── Helyi inventory segéd ─────────────────────────────────────

--- Kliens oldalon ellenőrzi, hogy az igazolvány fizikailag nála van-e.
--- Csak UI logikához használjuk – a szerver oldal is ellenőriz.
---@param licenseType string
---@return boolean
local function ClientHasItem(licenseType)
    if not Config.InventoryCheck then return true end
    local def = NXN.Licenses.GetTypeDef(licenseType)
    if not def or not def.inventoryItem then return false end
    return invItems[def.inventoryItem] == true
end

-- ── UI ──────────────────────────────────────────────────

local function SetUIVisible(state)
    isOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = 'setVisible', visible = state })
    NXN.Licenses.Log(('UI látható: %s'):format(tostring(state)))
end

-- PushToUI most átadja az inventory állapotot is minden kártyához
function PushToUI()
    local enriched = {}
    for _, def in ipairs(Config.LicenseTypes) do
        enriched[def.id] = {
            def        = def,
            license    = licenses[def.id] or nil,
            pending    = pending[def.id]  or nil,
            hasInInv   = ClientHasItem(def.id),   -- ★ új mező: fizikailag nála van-e
        }
    end
    SendNUIMessage({
        action   = 'updateData',
        licenses = enriched,
    })
end

local function OpenUI()
    TriggerServerEvent('nxn-licenses:server:requestSync')
    SetUIVisible(true)
end

local function CloseUI()
    SetUIVisible(false)
end

-- ── Net events ───────────────────────────────────────────

RegisterNetEvent('nxn-licenses:client:sync', function(data, pend)
    NXN.Licenses.Log('Szinkronizáció fogadva')
    licenses = data or {}
    pending  = pend or {}
    if isOpen then PushToUI() end
end)

RegisterNetEvent('nxn-licenses:client:viewShown', function(payload)
    NXN.Licenses.Log(('viewShown: type=%s from=%d'):format(
        tostring(payload.licenseType), tonumber(payload.showedBy) or 0
    ))
    SendNUIMessage({ action = 'showCard', payload = payload })
    SetNuiFocus(true, true)
    isOpen = true
end)

-- ── NUI callbacks ─────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('apply', function(data, cb)
    NXN.Licenses.Log(('NUI apply: %s'):format(tostring(data.licenseType)))
    TriggerServerEvent('nxn-licenses:server:apply', data.licenseType)
    cb('ok')
end)

-- ★ showTo előtt kliens oldalon is ellenőrizzük (gyors visszajelzés)
RegisterNUICallback('showTo', function(data, cb)
    local licType = data.licenseType
    NXN.Licenses.Log(('NUI showTo: type=%s target=%s'):format(
        tostring(licType), tostring(data.targetSrc)
    ))
    -- Gyors kliens oldali ellenőrzés
    if Config.InventoryCheck and not ClientHasItem(licType) then
        SendNUIMessage({
            action  = 'showError',
            message = 'Az igazolvány nincs nálad! Tedd az inventory-dba.',
        })
        cb('ok')
        return
    end
    TriggerServerEvent('nxn-licenses:server:showTo', licType, tonumber(data.targetSrc))
    cb('ok')
end)

-- ★ viewLicense: megtekintés előtt inventory ellenőrzés
RegisterNUICallback('viewLicense', function(data, cb)
    local licType = data.licenseType
    NXN.Licenses.Log(('NUI viewLicense: %s'):format(tostring(licType)))
    if Config.InventoryCheck and not ClientHasItem(licType) then
        SendNUIMessage({
            action  = 'showError',
            message = 'Az igazolvány nincs nálad! Vedd ki az inventory-ból, vagy váltsd ki az Önkormányzatnál.',
        })
        cb('ok')
        return
    end
    -- Ha megvan: szerver küldött adatokat már a sync-ben, csak UI-t nyitúk
    SendNUIMessage({ action = 'openLicenseView', licenseType = licType })
    cb('ok')
end)

RegisterNUICallback('getNearbyPlayers', function(_, cb)
    local ped    = PlayerPedId()
    local myPos  = GetEntityCoords(ped)
    local result = {}
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local pos       = GetEntityCoords(targetPed)
            local dist      = #(myPos - pos)
            if dist < 10.0 then
                table.insert(result, {
                    src  = GetPlayerServerId(playerId),
                    name = GetPlayerName(playerId),
                    dist = math.floor(dist * 10) / 10,
                })
            end
        end
    end
    table.sort(result, function(a,b) return a.dist < b.dist end)
    cb(result)
end)

-- ── Parancs + ESC ──────────────────────────────────────────

RegisterCommand(Config.Command, function()
    if isOpen then CloseUI() else OpenUI() end
end, false)

Citizen.CreateThread(function()
    while true do
        if isOpen then
            Citizen.Wait(0)
            if IsControlJustPressed(0, 322) then CloseUI() end
        else
            Citizen.Wait(100)
        end
    end
end)

-- ── Exportok ─────────────────────────────────────────────

exports('openLicenses',     function() if not isOpen then OpenUI()  end end)
exports('closeLicenses',    function() if isOpen     then CloseUI() end end)
exports('isOpen',           function() return isOpen end)
exports('getLocalLicenses', function() return licenses end)
--- Kliens oldali gyors inventory check
exports('clientHasItem',    function(licenseType) return ClientHasItem(licenseType) end)
