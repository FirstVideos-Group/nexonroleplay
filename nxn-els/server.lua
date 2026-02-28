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
-- FIX: a finalAllowed kiszámításakor az IsAdmin() eredménye is beépül,
-- így a kliens helyes jogosultságot kap akkor is, ha az admin check
-- előbb fut le mint a job push.

RegisterServerEvent('nxn-els:server:setJobPermission', function(job, allowed)
    local src = source
    local jobIsAllowed = allowed and NXN.ELS.IsJobAllowed(job)
    playerJobs[src] = { job = job, allowed = jobIsAllowed }
    local finalAllowed = jobIsAllowed or IsAdmin(src)
    TriggerClientEvent('nxn-els:client:setJobPermission', src, job, finalAllowed)
    NXN.ELS.Log(('setJobPermission: src=%d job=%s jobAllowed=%s isAdmin=%s final=%s'):format(
        src, job, tostring(jobIsAllowed), tostring(IsAdmin(src)), tostring(finalAllowed)))
end)

-- ── Admin check (kliens kéri) ─────────────────────────────────

RegisterServerEvent('nxn-els:server:requestAdminCheck', function()
    PushAdminState(source)
end)

-- ── Játékos betöltés: admin push ─────────────────────────────
-- FIX: az event handler a `src` paramétert használja, nem a `source` globálist,
-- mert a playerLoaded event kontextusában a `source` nem megbízható.

AddEventHandler('nxn-database:server:playerLoaded', function(src, _playerData)
    -- src paraméterként érkezik, nem source-ként
    if not src or not GetPlayerName(src) then return end
    CreateThread(function()
        Wait(300)  -- ACE scope garantáltan érvényes rövid várakozás után
        PushAdminState(src)
    end)
end)

-- Fallback ha nxn-database nem fut
AddEventHandler('playerSpawned', function()
    if GetResourceState('nxn-database') ~= 'started' then
        -- FIX: source-t a handler tetején mentjük, ne aszinkron kontextusban olvassuk
        local src = source
        CreateThread(function()
            Wait(300)
            if GetPlayerName(src) then
                PushAdminState(src)
            end
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
    local jobIsAllowed = allowed and NXN.ELS.IsJobAllowed(job)
    playerJobs[src] = { job = job, allowed = jobIsAllowed }
    local finalAllowed = jobIsAllowed or IsAdmin(src)
    TriggerClientEvent('nxn-els:client:setJobPermission', src, job, finalAllowed)
    NXN.ELS.Log(('setPlayerJobPermission export: src=%d job=%s final=%s'):format(
        src, job, tostring(finalAllowed)))
end)
exports('forceStage', function(netId, stage)
    vehicleStates[netId] = vehicleStates[netId] or { stage = 0, muted = false, owner = -1 }
    vehicleStates[netId].stage = stage
    TriggerClientEvent('nxn-els:client:syncState', -1, netId, stage, false)
end)
