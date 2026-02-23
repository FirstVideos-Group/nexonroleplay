-- ============================================================
--  nxn-needs | client.lua
--  Lokális cache + damage kezelés + HUD sync
-- ============================================================

--- Lokális needs cache (szinkronizált a szerverrel)
local localNeeds = {}

-- ── Segédfüggvények ──────────────────────────────────────────

--- Lokális cache frissítése és HUD értesítése
---@param data table
local function UpdateLocalNeeds(data)
    localNeeds = data
    NXN.Needs.Log(('Lokális needs frissítve: hunger=%.1f thirst=%.1f stress=%.1f fatigue=%.1f')
        :format(data.hunger or 0, data.thirst or 0, data.stress or 0, data.fatigue or 0))
    -- HUD resource tud figyelni erre az eventre:
    TriggerEvent('nxn-needs:client:updated', localNeeds)
end

-- ── Net events ────────────────────────────────────────────────

--- Szerver szinkronizálja a needs-t
RegisterNetEvent('nxn-needs:client:sync', function(data)
    NXN.Needs.Log('Szerver sync fogadva')
    UpdateLocalNeeds(data)
end)

--- Szerver HP-csökkentést kér (hunger/thirst = 0)
RegisterNetEvent('nxn-needs:client:applyDamage', function(amount)
    NXN.Needs.Log(('applyDamage: %d HP csökkentés'):format(amount))
    local ped = PlayerPedId()
    local hp  = GetEntityHealth(ped)
    if hp > 100 then  -- ne ölje meg azonnal (GTA alap HP 100 = halál határa)
        SetEntityHealth(ped, math.max(100, hp - amount))
    end
end)

-- ── Spawn után sync kérés ────────────────────────────────────

AddEventHandler('playerSpawned', function()
    NXN.Needs.Log('playerSpawned – sync kérés küldve')
    TriggerServerEvent('nxn-needs:server:requestSync')
end)

-- ── Exportok ─────────────────────────────────────────────────

--- Visszaadja az összes needs adatot kliens oldalon
---@return table
exports('getLocalNeeds', function()
    return localNeeds
end)

--- Visszaad egy konkrét szükséglet értékét kliens oldalon
---@param need string
---@return number|nil
exports('getLocalNeed', function(need)
    return localNeeds[need]
end)
