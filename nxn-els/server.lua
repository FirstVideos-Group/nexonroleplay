-- ============================================================
--  nxn-els | server.lua
--  Szerver-oldali szinkron, jogosultságkezelés, export API
-- ============================================================

-- ── Állapottár ────────────────────────────────────────────
-- Format: vehicleStates[netId] = { stage, muted, owner }
local vehicleStates = {}
-- Format: playerJobs[src]   = { job, allowed }
local playerJobs    = {}

-- ── Admin segéd ──────────────────────────────────────────
-- A config-ban megadott ace jogosultságot ellenőrzi.
-- server.cfg-ben add: add_ace group.admin nxn.els.admin allow

---@param src number  player source
---@return boolean
local function IsAdmin(src)
    return IsPlayerAceAllowed(src, Config.AdminAce)
end

--- Egy játékos általános ELS-engedélye (job VAGY admin)
---@param src number
---@return boolean
local function HasElsPermission(src)
    if IsAdmin(src) then return true end
    return playerJobs[src] ~= nil and playerJobs[src].allowed == true
end

--- Admin flag push a kliensnek (késleltetett, ACE biztosan betöltött)
---@param src number
local function PushAdminState(src)
    local isAdm = IsAdmin(src)
    TriggerClientEvent('nxn-els:client:setAdminState', src, isAdm)
    NXN.ELS.Log(('PushAdminState: src=%d isAdmin=%s'):format(src, tostring(isAdm)))
end

-- ── State update (kliens → szerver) ────────────────────────────

RegisterServerEvent('nxn-els:server:updateState', function(netId, stage, muted)
    local src = source
    if not HasElsPermission(src) then
        NXN.ELS.Warn(('updateState: Player %d nincs jogosultsaga!'):format(src))
        return
    end
    vehicleStates[netId] = { stage = stage, muted = muted, owner = src }
    NXN.ELS.Log(('updateState: netId=%d stage=%d muted=%s src=%d admin=%s'):format(
        netId, stage, tostring(muted), src, tostring(IsAdmin(src))))
    TriggerClientEvent('nxn-els:client:syncState', -1, netId, stage, muted)
end)

-- ── Sziréna hang szinkron ──────────────────────────────────────

RegisterServerEvent('nxn-els:server:setSirenSound', function(netId, tone)
    local src = source
    TriggerClientEvent('nxn-els:client:sirenSound', -1, netId, tone, src)
end)

-- ── Jogosultság megadása (nxn-police / nxn-ems stb. hívja) ───────

RegisterServerEvent('nxn-els:server:setJobPermission', function(job, allowed)
    local src = source
    playerJobs[src] = { job = job, allowed = allowed and NXN.ELS.IsJobAllowed(job) }
    -- Admin esetén a job-tól függetlenül engedélyezve marad
    local finalAllowed = playerJobs[src].allowed or IsAdmin(src)
    TriggerClientEvent('nxn-els:client:setJobPermission', src, job, finalAllowed)
    NXN.ELS.Log(('setJobPermission: src=%d job=%s jobAllowed=%s admin=%s'):format(
        src, job, tostring(playerJobs[src].allowed), tostring(IsAdmin(src))))
end)

-- ── Admin állapot lekérdezése (kliens kéri) ───────────────────

RegisterServerEvent('nxn-els:server:requestAdminCheck', function()
    local src = source
    PushAdminState(src)
end)

-- ── Játékos betöltés: admin állapot push ─────────────────────────
-- FIX: playerJoining helyett nxn-database:server:playerLoaded használata.
-- playerJoining-kor az ACE jogosultságok még nem töltöttek be teljesen,
-- ezért IsPlayerAceAllowed mindig false-t adott vissza.
-- A playerLoaded event-kor a játékos már teljesen inicializált.

AddEventHandler('nxn-database:server:playerLoaded', function(src)
    -- Rövid várakozás hogy az ACE scope biztosan érvényes legyen
    CreateThread(function()
        Wait(500)
        PushAdminState(src)
    end)
end)

-- Fallback: ha nxn-database nem fut, hagyományos playerSpawned
AddEventHandler('playerSpawned', function()
    local src = source
    -- Csak akkor push-ol, ha nxn-database nem futott előtte
    if GetResourceState('nxn-database') ~= 'started' then
        CreateThread(function()
            Wait(500)
            PushAdminState(src)
        end)
    end
end)

-- ── Játékos kilép: cleanup ────────────────────────────────────

AddEventHandler('playerDropped', function()
    local src = source
    playerJobs[src] = nil
    for netId, state in pairs(vehicleStates) do
        if state.owner == src then
            TriggerClientEvent('nxn-els:client:syncState', -1, netId, 0, false)
            vehicleStates[netId] = nil
        end
    end
    NXN.ELS.Log(('playerDropped: src=%d cleanup kesz'):format(src))
end)

-- ── Szerver Export API ─────────────────────────────────────────

exports('getVehicleState', function(netId)
    return vehicleStates[netId]
end)

exports('isElsActive', function(netId)
    local s = vehicleStates[netId]
    return s ~= nil and s.stage > 0
end)

exports('playerHasPermission', function(src)
    return HasElsPermission(src)
end)

exports('isPlayerAdmin', function(src)
    return IsAdmin(src)
end)

exports('setPlayerJobPermission', function(src, job, allowed)
    playerJobs[src] = { job = job, allowed = allowed and NXN.ELS.IsJobAllowed(job) }
    local finalAllowed = playerJobs[src].allowed or IsAdmin(src)
    TriggerClientEvent('nxn-els:client:setJobPermission', src, job, finalAllowed)
    NXN.ELS.Log(('setPlayerJobPermission: src=%d job=%s final=%s'):format(
        src, job, tostring(finalAllowed)))
end)

exports('getAllVehicleStates', function()
    return vehicleStates
end)

exports('forceStage', function(netId, stage)
    vehicleStates[netId] = vehicleStates[netId] or { stage = 0, muted = false, owner = -1 }
    vehicleStates[netId].stage = stage
    TriggerClientEvent('nxn-els:client:syncState', -1, netId, stage, false)
end)
