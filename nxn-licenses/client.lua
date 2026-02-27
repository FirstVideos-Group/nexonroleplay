-- ============================================================
--  nxn-licenses | client.lua
-- ============================================================

local isOpen       = false
local licenses     = {}   -- { [type] = row }
local pending      = {}   -- { [type] = row }

-- ── UI ──────────────────────────────────────────────────────

local function SetUIVisible(state)
    isOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = 'setVisible', visible = state })
    NXN.Licenses.Log(('UI látható: %s'):format(tostring(state)))
end

local function PushToUI()
    local enriched = {}
    for _, def in ipairs(Config.LicenseTypes) do
        enriched[def.id] = {
            def     = def,
            license = licenses[def.id] or nil,
            pending = pending[def.id]  or nil,
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

-- ── Net events ──────────────────────────────────────────────

RegisterNetEvent('nxn-licenses:client:sync', function(data, pend)
    NXN.Licenses.Log('Szinkronizáció fogadva')
    licenses = data or {}
    pending  = pend or {}
    if isOpen then PushToUI() end
end)

-- Más játékos megmutatja az igazolványát
RegisterNetEvent('nxn-licenses:client:viewShown', function(payload)
    -- FIX: showedBy integer, tostring() helyett %d formatum
    NXN.Licenses.Log(('viewShown: type=%s from=%d'):format(
        tostring(payload.licenseType),
        tonumber(payload.showedBy) or 0
    ))
    SendNUIMessage({
        action  = 'showCard',
        payload = payload,
    })
    SetNuiFocus(true, true)
    isOpen = true
end)

-- ── NUI callbacks ─────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('apply', function(data, cb)
    NXN.Licenses.Log(('NUI apply: %s'):format(tostring(data.licenseType)))
    TriggerServerEvent('nxn-licenses:server:apply', data.licenseType)
    cb('ok')
end)

RegisterNUICallback('showTo', function(data, cb)
    NXN.Licenses.Log(('NUI showTo: type=%s target=%s'):format(
        tostring(data.licenseType), tostring(data.targetSrc)
    ))
    TriggerServerEvent('nxn-licenses:server:showTo', data.licenseType, tonumber(data.targetSrc))
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

-- ── Parancs + billentyű ─────────────────────────────────────────────

RegisterCommand(Config.Command, function()
    if isOpen then CloseUI() else OpenUI() end
end, false)

-- FIX: Wait(0) helyett Wait(100) + isOpen guard, hogy ne pörögjön minden frame-ben
Citizen.CreateThread(function()
    while true do
        if isOpen then
            Citizen.Wait(0)
            if IsControlJustPressed(0, 322) then  -- ESC
                CloseUI()
            end
        else
            Citizen.Wait(100)  -- UI zárva: ritkán ellenőriz, nincs CPU terhelés
        end
    end
end)

-- ── Exportok ──────────────────────────────────────────────────

exports('openLicenses',     function() if not isOpen then OpenUI()  end end)
exports('closeLicenses',    function() if isOpen     then CloseUI() end end)
exports('isOpen',           function() return isOpen end)
exports('getLocalLicenses', function() return licenses end)
