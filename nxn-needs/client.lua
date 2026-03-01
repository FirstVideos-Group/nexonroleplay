-- ============================================================
--  nxn-needs | client.lua
-- ============================================================

--- Lokális needs cache (szinkronizált a szerverrel)
local localNeeds = {}

-- ── Segédfüggvények ────────────────────────────────────────────

---@param data table
local function UpdateLocalNeeds(data)
    localNeeds = data
    NXN.Needs.Log(('Lokális needs frissítve: hunger=%.1f thirst=%.1f stress=%.1f fatigue=%.1f')
        :format(data.hunger or 0, data.thirst or 0, data.stress or 0, data.fatigue or 0))
    TriggerEvent('nxn-needs:client:updated', localNeeds)
end

-- ── Net events ───────────────────────────────────────────────

RegisterNetEvent('nxn-needs:client:sync', function(data)
    NXN.Needs.Log('Szerver sync fogadva')
    UpdateLocalNeeds(data)
end)

-- #80: GTA5 HP skála: 0 = halál határa, 100 = alap max HP, 200 = teljes armor+HP
-- Korábban: hp > 100 feltétel + math.max(100) – alap HP-jú játékosnak soha
-- nem csökkent az élete, és 100 alá sem mehetett soha (DamageOnEmpty teljesen nem működött)
RegisterNetEvent('nxn-needs:client:applyDamage', function(amount)
    local ped = PlayerPedId()
    local hp  = GetEntityHealth(ped)
    -- Csak élő játékosra alkalmazz damage-t
    if hp > 0 then
        local newHp = math.max(0, hp - amount)
        SetEntityHealth(ped, newHp)
        NXN.Needs.Log(('applyDamage: HP %d -> %d'):format(hp, newHp))
    end
end)

-- ── Spawn után sync kérés ───────────────────────────────────────

AddEventHandler('playerSpawned', function()
    NXN.Needs.Log('playerSpawned – sync kérés küldve')
    TriggerServerEvent('nxn-needs:server:requestSync')
end)

-- ── Exportok ────────────────────────────────────────────────

-- #79: shallow copy – külső resource nem tudja közvetlenül módosítani a lokális cache-t
exports('getLocalNeeds', function()
    local copy = {}
    for k, v in pairs(localNeeds) do copy[k] = v end
    return copy
end)

exports('getLocalNeed', function(need)
    return localNeeds[need]
end)
