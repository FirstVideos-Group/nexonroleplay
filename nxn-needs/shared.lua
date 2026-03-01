-- ============================================================
--  nxn-needs | shared.lua
-- ============================================================

NXN            = NXN or {}
NXN.Needs      = NXN.Needs or {}

-- ── Segédfüggvények ────────────────────────────────────────────

---@param v number
---@param min number
---@param max number
---@return number
function NXN.Needs.Clamp(v, min, max)
    return math.max(min, math.min(max, v))
end

---@param msg string
function NXN.Needs.Log(msg)
    if Config and Config.Debug then
        print('[nxn-needs][DEBUG] ' .. tostring(msg))
    end
end

---@param msg string
function NXN.Needs.Info(msg)
    print('[nxn-needs][INFO]  ' .. tostring(msg))
end

---@param msg string
function NXN.Needs.Warn(msg)
    print('[nxn-needs][WARN]  ' .. tostring(msg))
end

---@param msg string
function NXN.Needs.Error(msg)
    print('[nxn-needs][ERROR] ' .. tostring(msg))
end

-- #82: NXN.Needs.GetItemEffects eltávolítva innen – áthelyezve server.lua-ba
-- (szerver export hívás kliens kontextusból nem szükséges, pcall overhead megszűnt)
