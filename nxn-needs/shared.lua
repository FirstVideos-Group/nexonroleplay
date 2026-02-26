-- ============================================================
--  nxn-needs | shared.lua
-- ============================================================

NXN            = NXN or {}
NXN.Needs      = NXN.Needs or {}

-- ── Segédfüggvények ──────────────────────────────────────────

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

-- ── Item–Needs hatástáblázat összeállítása ───────────────────
-- Szerver oldalon fut (az inventory config csak szerveren elérhető).
-- Client oldalon üres marad – a szerver kezeli a needs módosítást.

--- Visszaadja egy item needs-hatásait.
--- Először az nxn-inventory Config.Items[item].needs-t nézi,
--- majd az nxn-needs Config.ItemOverrides[item] felülírja ha van.
---@param itemName string
---@return table  { hunger=N, thirst=N, stress=N, fatigue=N } vagy {}
function NXN.Needs.GetItemEffects(itemName)
    local effects = {}

    -- Forrás 1: nxn-inventory item definíció
    local invOk, invConfig = pcall(function()
        return exports['nxn-inventory']:getItemDef(itemName)
    end)
    if invOk and invConfig and invConfig.needs then
        for need, val in pairs(invConfig.needs) do
            effects[need] = val
        end
    end

    -- Forrás 2: helyi felülírások (Config.ItemOverrides)
    if Config and Config.ItemOverrides and Config.ItemOverrides[itemName] then
        for need, val in pairs(Config.ItemOverrides[itemName]) do
            effects[need] = val
        end
    end

    return effects
end
