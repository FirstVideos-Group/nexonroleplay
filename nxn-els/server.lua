-- ============================================================
--  nxn-els | server.lua
--  Szerver-oldali szinkron, jogosultságkezelés, export API
-- ============================================================

-- ── Állapottár ───────────────────────────────────────────────
local vehicleStates = {}  -- [netId] = { stage, muted, owner }
local playerJobs    = {}  -- [src]   = { job, allowed }

-- ── Admin segéd ──────────────────────────────────────────────

---@param src number
---@return boolean
local function IsAdmin(src)
    return IsPlayerAceAllowed(src, Config.AdminAce)
end

---@param src number
---@return boolean
local function HasElsPermission(src)
    if IsAdmin(src) then return true end
    return playerJobs[src] ~= nil and playerJobs[src].allowed == true
end

--- Admin flag biztonságos push a kliensnek
---@param src number
local function PushAdminState(src)
    -- Ellenőrzés: érvényes, csatlakozott játékos-e még
    if not GetPlayerName(src) then return end
    local isAdm = IsAdmin(src)
    TriggerClientEvent('nxn-els:client:setAdminState', src, isAdm)
    NXN.ELS.Log(('PushAdminState: src=%d isAdmin=%s'):format(src, tostring(isAdm)))
end

-- ── State update ─────────────────────────────────────────────

RegisterServerEvent('nxn-els:server:updateState', function(netId, stage, muted)
    local src = source
    if not HasElsPermission(src) then
        NXN.ELS.Warn(('updateState megtagadva: src=%d'):format(src))
        return
    end
    vehicleStates[netId] = { stage = stage, muted = muted, owner = src }
    TriggerClientEvent('nxn-els:client:syncState', -1, netId, stage, muted)
    NXN.ELS.Log(('updateState: netId=%d stage=%d src=%d admin=%s'):format(
        netId, stage, src, tostring(IsAdmin(src))))
end)

-- ── Sziréna hang szinkron ─────────────────────────────────────

RegisterServerEvent('nxn-els:server:setSirenSound', function(netId, tone)
    local src = source
    TriggerClientEvent('nxn-els:client:sirenSound', -1, netId, tone, src)
end)

-- ── Job jogosultság ───────────────────────────────────────────

RegisterServerEvent('nxn-els:server:setJobPermission', function(job, allowed)
    local src = source
    playerJobs[src] = { job = job, allowed = allowed and NXN.ELS.IsJobAllowed(job) }
    local finalAllowed = playerJobs[src].allowed or IsAdmin(src)
    TriggerClientEvent('nxn-els:client:setJobPermission', src, job, finalAllowed)
    NXN.ELS.Log(('setJobPermission: src=%d job=%s final=%s'):format(
        src, job, tostring(finalAllowed)))
end)

-- ── Admin check (kliens kéri) ─────────────────────────────────

RegisterServerEvent('nxn-els:server:requestAdminCheck', function()
    PushAdminState(source)
end)

-- ── Játékos betöltés: admin push ─────────────────────────────
-- FIX: playerJoining helyett nxn-database:server:playerLoaded
-- Az event handler a `source` globálist használja, nem a paramétert,
-- mert a playerLoaded első paramétere a src number.

AddEventHandler('nxn-database:server:playerLoaded', function(src, _playerData)
    CreateThread(function()
        Wait(500)  -- ACE scope garantáltan érvényes 500ms után
        PushAdminState(src)
    end)
end)

-- Fallback ha nxn-database nem fut
AddEventHandler('playerSpawned', function()
    if GetResourceState('nxn-database') ~= 'started' then
        local src = source
        CreateThread(function()
            Wait(500)
            PushAdminState(src)
        end)
    end
end)

-- ── Játékos kilép ─────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    local src = source
    playerJobs[src] = nil
    for netId, state in pairs(vehicleStates) do
        if state.owner == src then
            TriggerClientEvent('nxn-els:client:syncState', -1, netId, 0, false)
            vehicleStates[netId] = nil
        end
    end
    NXN.ELS.Log(('playerDropped cleanup: src=%d'):format(src))
end)

-- ── Export API ────────────────────────────────────────────────

exports('getVehicleState',      function(netId) return vehicleStates[netId] end)
exports('getAllVehicleStates',   function()      return vehicleStates end)
exports('isElsActive',          function(netId)
    local s = vehicleStates[netId]
    return s ~= nil and s.stage > 0
end)
exports('playerHasPermission',  function(src) return HasElsPermission(src) end)
exports('isPlayerAdmin',        function(src) return IsAdmin(src) end)
exports('setPlayerJobPermission', function(src, job, allowed)
    playerJobs[src] = { job = job, allowed = allowed and NXN.ELS.IsJobAllowed(job) }
    local finalAllowed = playerJobs[src].allowed or IsAdmin(src)
    TriggerClientEvent('nxn-els:client:setJobPermission', src, job, finalAllowed)
    NXN.ELS.Log(('setPlayerJobPermission export: src=%d job=%s final=%s'):format(
        src, job, tostring(finalAllowed)))
end)
exports('forceStage', function(netId, stage)
    vehicleStates[netId] = vehicleStates[netId] or { stage = 0, muted = false, owner = -1 }
    vehicleStates[netId].stage = stage
    TriggerClientEvent('nxn-els:client:syncState', -1, netId, stage, false)
end)
