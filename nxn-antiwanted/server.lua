-- ============================================================
--  nxn-antiwanted | server.lua
-- ============================================================

-- ── Játékos csatlakozás után nullázza a körözési szintet ─────
-- Szerver oldali védelmi réteg: a ClearPlayerWantedLevel
-- megakadályozza, hogy a szerver által kezelt wanted-state
-- visszaszivárogjon más játékosokhoz

AddEventHandler('playerSpawned', function()
    -- Ez az event nem létezik natívan FiveM-ben szerver oldalon,
    -- de más scriptek (pl. spawnmanager) triggerelhetik
    local src = source
    NXN.AntiWanted.Log(('playerSpawned: clearing wanted for src=%s'):format(src))
    -- Szerver oldalon nem tudjuk közvetlenül nullázni a wanted-et,
    -- ezért az eseményt a kliensnek küldjük
    TriggerClientEvent('nxn-antiwanted:client:clearWanted', src)
end)

-- ── Net event: kliens kéri a wanted state átállítását ────────

RegisterServerEvent('nxn-antiwanted:server:setWantedState', function(allow)
    local src = source
    NXN.AntiWanted.Log(('setWantedState: src=%s allow=%s'):format(src, tostring(allow)))
    TriggerClientEvent('nxn-antiwanted:client:setWantedState', src, allow)
end)

-- ── Exports ───────────────────────────────────────────────────

--- Szerver oldalról kényszeríti a körözés törlését egy játékosnál
---@param src integer  játékos source ID
exports('clearWantedForPlayer', function(src)
    NXN.AntiWanted.Log(('Server export: clearWantedForPlayer src=%s'):format(src))
    TriggerClientEvent('nxn-antiwanted:client:clearWanted', src)
end)

--- Szerver oldalról engedélyezi a körözési rendszert egy játékosnál
---@param src integer
exports('enableWantedForPlayer', function(src)
    NXN.AntiWanted.Log(('Server export: enableWantedForPlayer src=%s'):format(src))
    TriggerClientEvent('nxn-antiwanted:client:setWantedState', src, true)
end)

--- Szerver oldalról letiltja a körözési rendszert egy játékosnál
---@param src integer
exports('disableWantedForPlayer', function(src)
    NXN.AntiWanted.Log(('Server export: disableWantedForPlayer src=%s'):format(src))
    TriggerClientEvent('nxn-antiwanted:client:setWantedState', src, false)
end)
