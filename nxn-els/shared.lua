-- ============================================================
--  nxn-els | shared.lua
--  Közös segédfüggvények – CSAK tiszta Lua, nincs GTA natív!
--  Kliens-specifikus natívok (GetEntityModel stb.) → client.lua
-- ============================================================

NXN     = NXN or {}
NXN.ELS = {}

-- ── Logger ───────────────────────────────────────────────────

function NXN.ELS.Log(msg)
    if Config and Config.Debug then
        print(('^9[nxn-els]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

function NXN.ELS.Info(msg)
    print(('^9[nxn-els]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

function NXN.ELS.Warn(msg)
    print(('^9[nxn-els]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

function NXN.ELS.Error(msg)
    print(('^9[nxn-els]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

-- ── Job-ellenőrzés (kliens + szerver közös) ───────────────────

---@param job string
---@return boolean
function NXN.ELS.IsJobAllowed(job)
    for _, allowedJob in ipairs(Config.AllowedJobs) do
        if allowedJob == job then return true end
    end
    return false
end

-- ── Stage alap-konfig lekérése (tiszta tábla lookup, nincs natív) ─
-- Jármű-specifikus felülírás a client.lua-ban történik, ahol
-- GetEntityModel / GetHashKey elérhető.

---@param stage number
---@return table
function NXN.ELS.GetBaseStageConfig(stage)
    if not stage or stage == 0 then
        return { label = 'KI', sirenActive = false, pattern = nil, sirenTone = 0 }
    end
    return Config.Stages[stage] or
           { label = 'KI', sirenActive = false, pattern = nil, sirenTone = 0 }
end
