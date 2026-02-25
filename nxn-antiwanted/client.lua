-- ============================================================
--  nxn-antiwanted | client.lua
-- ============================================================

local allowWanted = Config.AllowWanted

-- ── Dispatch letiltás ─────────────────────────────────────────
-- A GTA5 dispatch rendszer 1-15-ig számozott szolgálatokból áll.
-- EnableDispatchService(id, false) = adott szerviz hívásainak tiltása

local function DisableAllDispatch()
    if not Config.DisableDispatch then return end
    for _, id in ipairs(Config.DispatchServices) do
        EnableDispatchService(id, false)
    end
    NXN.AntiWanted.Log('Dispatch services disabled')
end

-- ── Körözési szint nullázása ──────────────────────────────────

local function ClearWanted()
    if allowWanted then return end
    local ped = PlayerPedId()
    if GetPlayerWantedLevel(PlayerId()) > 0 then
        SetPlayerWantedLevel(PlayerId(), 0, false)
        SetPlayerWantedLevelNow(PlayerId(), false)
        NXN.AntiWanted.Log('Wanted level cleared')
    end
end

-- ── Rendőrségi járőrök letiltása ─────────────────────────────
-- SetPoliceIgnorePlayer: rendőrök nem reagálnak a játékosra
-- SetPoliceRadarBlips: nem jelennek meg a térképen mint körözött

local function DisableCopBehaviour()
    if not Config.DisableCopSpawn then return end
    local playerId = PlayerId()
    SetPoliceIgnorePlayer(playerId, true)
    SetPoliceRadarBlips(false)
    NXN.AntiWanted.Log('Cop behaviour disabled')
end

-- ── Körözési event blokkok ────────────────────────────────────
-- A ClearOverrideWantedLevel és SetMaxWantedLevel(0) megakadályozza
-- hogy a GTA belső rendszere automatikusan adjon hozzá csillagot

local function BlockWantedSystem()
    if not Config.BlockWantedEvents then return end
    local playerId = PlayerId()
    SetMaxWantedLevel(0)
    ClearOverrideWantedLevel(playerId)
    NXN.AntiWanted.Log('Wanted system blocked (max level = 0)')
end

-- ── Fő loop ───────────────────────────────────────────────────

Citizen.CreateThread(function()
    -- Spawn utáni első tisztítás
    Citizen.Wait(1000)

    DisableAllDispatch()
    DisableCopBehaviour()
    BlockWantedSystem()

    if Config.ClearOnSpawn then
        ClearWanted()
        NXN.AntiWanted.Log('Initial wanted clear done')
    end

    -- Folyamatos körözés törlő loop
    while true do
        Citizen.Wait(Config.ClearInterval)

        if not allowWanted then
            ClearWanted()
            -- Dispatch és cop-blokk újrahívása (GTA néha visszaállítja)
            DisableAllDispatch()
            DisableCopBehaviour()
            BlockWantedSystem()
        end
    end
end)

-- ── Respawn után újra inicializálás ──────────────────────────
-- A respawn törölheti a beállításainkat

AddEventHandler('baseevents:onPlayerDied', function()
    NXN.AntiWanted.Log('Player died – reinitializing after respawn')
    Citizen.SetTimeout(2000, function()
        DisableAllDispatch()
        DisableCopBehaviour()
        BlockWantedSystem()
        ClearWanted()
    end)
end)

-- ── Exports ───────────────────────────────────────────────────

--- Visszaadja, hogy a körözési rendszer jelenleg engedélyezett-e
---@return boolean
exports('isWantedAllowed', function()
    return allowWanted
end)

--- Ideiglenesen engedélyezi a körözési rendszert (pl. rendőrségi eseményhez)
--- Más resource hívhatja: exports['nxn-antiwanted']:enableWanted()
exports('enableWanted', function()
    allowWanted = true
    local playerId = PlayerId()
    SetMaxWantedLevel(5)
    SetPoliceIgnorePlayer(playerId, false)
    SetPoliceRadarBlips(true)
    for _, id in ipairs(Config.DispatchServices) do
        EnableDispatchService(id, true)
    end
    NXN.AntiWanted.Log('Wanted system ENABLED (by export)')
end)

--- Visszaállítja a körözési tiltást
--- Más resource hívhatja: exports['nxn-antiwanted']:disableWanted()
exports('disableWanted', function()
    allowWanted = false
    DisableAllDispatch()
    DisableCopBehaviour()
    BlockWantedSystem()
    ClearWanted()
    NXN.AntiWanted.Log('Wanted system DISABLED (by export)')
end)

--- Azonnal nullázza a körözési szintet (egyszer)
exports('clearWantedNow', function()
    SetPlayerWantedLevel(PlayerId(), 0, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
    NXN.AntiWanted.Log('Manual clearWantedNow called')
end)

--- Visszaadja az aktuális körözési szintet
---@return integer
exports('getWantedLevel', function()
    return GetPlayerWantedLevel(PlayerId())
end)
