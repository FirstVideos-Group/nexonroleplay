-- ============================================================
--  nxn-signs | client.lua
--  Zona-alapu jelzotabla megjelenites, SVG, fade animaciok
-- ============================================================

-- ── Runtime tablak rejeisztere ─────────────────────────────────────
local zones     = {}   -- { [id] = zoneCfg }
local activeIds = {}   -- { [id] = true }  jelenleg latszodik
local timers    = {}   -- { [id] = expireTime }  duration kovetese

-- Config zonak betoltese
for id, z in pairs(Config.Zones) do
    zones[id] = z
end

-- ── NUI kommunikacio ─────────────────────────────────────────────

local function NUISend(data)
    SendNUIMessage(data)
end

-- ── Tabla megjelenites ───────────────────────────────────────────

---@param id     string
---@param zone   table
local function ShowSign(id, zone)
    if activeIds[id] then return end
    activeIds[id] = true

    local svgUrl = ('nui://%s/signs/%s'):format(Config.ResourceName, zone.file)
    NXN.Signs.Log(('ShowSign: id=%s file=%s cat=%s'):format(id, zone.file, zone.category))

    NUISend({
        action   = 'showSign',
        id       = id,
        svgUrl   = svgUrl,
        label    = zone.label or id,
        category = zone.category or 'info',
        fadeIn   = zone.fadeIn  or Config.FadeInMs,
        fadeOut  = zone.fadeOut or Config.FadeOutMs,
    })

    -- #109: Explicit nil-check (duration=0 Lua-ban truthy, de >0 nem teljesul)
    -- duration=nil  -> nincs timer (orokos)
    -- duration>0    -> timer keszul
    -- duration=0    -> warn log, nincs timer (definialt viselkedes)
    if zone.duration ~= nil then
        if zone.duration > 0 then
            timers[id] = GetGameTimer() + (zone.duration * 1000)
            NXN.Signs.Log(('  duration: %.1f mp'):format(zone.duration))
        else
            NXN.Signs.Warn(('ShowSign: duration=0 – vegtelen megjelenitesnek szamit: id=%s'):format(id))
        end
    end

    TriggerEvent('nxn-signs:shown', { id = id, zone = zone })
end

---@param id     string
---@param zone   table
local function HideSign(id, zone)
    if not activeIds[id] then return end
    activeIds[id] = nil
    timers[id]    = nil

    NXN.Signs.Log(('HideSign: id=%s'):format(id))
    NUISend({
        action  = 'hideSign',
        id      = id,
        fadeOut = (zone and zone.fadeOut) or Config.FadeOutMs,
    })

    TriggerEvent('nxn-signs:hidden', { id = id })
end

-- ── Zona-ellenorzo loop ─────────────────────────────────────────────
-- #108 / #111: Manual (_manual=true) zonakon nem fut proximity check –
-- csak a duration timer kezeli oket. Ez kizarja hogy a radius=0 miatt
-- azonnal eltunjenek a showSign exporttal letrehozott tablak.

CreateThread(function()
    while true do
        Wait(Config.CheckInterval)

        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local now    = GetGameTimer()

        for id, zone in pairs(zones) do
            -- Duration lejarata – minden zona tipuson fut
            if timers[id] and now >= timers[id] then
                NXN.Signs.Log(('Duration lejart: id=%s'):format(id))
                HideSign(id, zone)
                if zone._manual then
                    zones[id] = nil  -- temp definicio torlese
                end
            end

            -- Proximity check: csak zona-alapu (nem manual) bejegyzeseken
            if not zone._manual then
                local dist   = #(coords - zone.center)
                local inZone = dist <= zone.radius

                if inZone then
                    if not activeIds[id] then
                        NXN.Signs.Log(('Zona belepes: id=%s dist=%.1f'):format(id, dist))
                        ShowSign(id, zone)
                    end
                else
                    if activeIds[id] and not timers[id] then
                        NXN.Signs.Log(('Zona elhagyas: id=%s dist=%.1f'):format(id, dist))
                        HideSign(id, zone)
                    end
                end
            end
        end
    end
end)

-- ── Exportok ──────────────────────────────────────────────────────

--- Tabla manualis megjelenitesehez (mas resource, esemeny, script)
---@param id       string
---@param cfg      table    { file, category, label?, duration?, fadeIn?, fadeOut? }
exports('showSign', function(id, cfg)
    if not cfg or not cfg.file then
        NXN.Signs.Warn(('showSign: hianyzik a cfg.file: id=%s'):format(id))
        return
    end
    -- #109: Explicit nil-check a duration-ra (0 is ervenyes ertek Lua-ban)
    local duration = (cfg.duration ~= nil) and cfg.duration or 4
    zones[id] = {
        label    = cfg.label    or id,
        category = cfg.category or 'info',
        file     = cfg.file,
        center   = vector3(0, 0, 0),
        radius   = 0,
        duration = duration,
        fadeIn   = cfg.fadeIn  or Config.FadeInMs,
        fadeOut  = cfg.fadeOut or Config.FadeOutMs,
        _manual  = true,
    }
    NXN.Signs.Log(('showSign (export): id=%s file=%s dur=%s'):format(
        id, cfg.file, tostring(duration)
    ))
    ShowSign(id, zones[id])
end)

--- Tabla elrejtese
---@param id string
exports('hideSign', function(id)
    NXN.Signs.Log(('hideSign (export): id=%s'):format(id))
    HideSign(id, zones[id])
    if zones[id] and zones[id]._manual then
        zones[id] = nil
    end
end)

--- Uj zona regisztralasa runtime-ban
---@param id   string
---@param zone table  { label, category, file, center (vector3), radius, duration?, fadeIn?, fadeOut? }
exports('registerZone', function(id, zone)
    if zones[id] then
        NXN.Signs.Warn(('registerZone: felulirja a meglevo zona-t: %s'):format(id))
    end
    zones[id] = zone
    NXN.Signs.Log(('registerZone: id=%s r=%.1f'):format(id, zone.radius or 0))
end)

--- Zona eltavolitasa
---@param id string
exports('unregisterZone', function(id)
    HideSign(id, zones[id])
    zones[id]     = nil
    activeIds[id] = nil
    timers[id]    = nil
    NXN.Signs.Log(('unregisterZone: id=%s'):format(id))
end)

--- Aktiv tablak listaja – shallow copy, belso referencia nem szivarg ki (#110)
---@return table  { [id] = true }
exports('getActiveSigns', function()
    local copy = {}
    for k, v in pairs(activeIds) do copy[k] = v end
    return copy
end)

--- Zona definicio lekerdezes – shallow copy (#110)
---@param id string
---@return table|nil
exports('getZone', function(id)
    local z = zones[id]
    if not z then return nil end
    local copy = {}
    for k, v in pairs(z) do copy[k] = v end
    return copy
end)

--- Osszes zona listaja – shallow copy (#110)
---@return table
exports('getAllZones', function()
    local copy = {}
    for zid, z in pairs(zones) do
        copy[zid] = {}
        for k, v in pairs(z) do copy[zid][k] = v end
    end
    return copy
end)

--- Folyamatosan lathato tabla rogzitese (duration=nil, timer torlese)
---@param id string
exports('pinSign', function(id)
    -- #113: Warn ismeretlen id eseten
    if not zones[id] then
        NXN.Signs.Warn(('pinSign: ismeretlen id: %s'):format(id))
        return
    end
    zones[id].duration = nil
    timers[id] = nil
    NXN.Signs.Log(('pinSign: id=%s'):format(id))
end)

--- Tabla rogzitesenek feloldasa
---@param id      string
---@param seconds number|nil
exports('unpinSign', function(id, seconds)
    -- #113: Warn ismeretlen id eseten
    if not zones[id] then
        NXN.Signs.Warn(('unpinSign: ismeretlen id: %s'):format(id))
        return
    end
    zones[id].duration = seconds
    -- #112: Mindig torolje a meglevo timert, majd ha van seconds, ujat allitson
    if seconds and seconds > 0 then
        timers[id] = GetGameTimer() + (seconds * 1000)
    else
        timers[id] = nil  -- seconds=nil vagy 0: timer torlese (orokos tabla)
    end
    NXN.Signs.Log(('unpinSign: id=%s sec=%s'):format(id, tostring(seconds)))
end)
