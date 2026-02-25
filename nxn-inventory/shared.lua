-- ============================================================
--  nxn-inventory | shared.lua
-- ============================================================

NXN = NXN or {}
NXN.Inventory = {}

--- Debug log
---@param msg string
function NXN.Inventory.Log(msg)
    if Config and Config.Debug then
        print(('[nxn-inventory] [DEBUG] %s'):format(tostring(msg)))
    end
end

function NXN.Inventory.Info(msg)
    print(('[nxn-inventory] [INFO] %s'):format(tostring(msg)))
end

function NXN.Inventory.Warn(msg)
    print(('[nxn-inventory] [WARN] %s'):format(tostring(msg)))
end

function NXN.Inventory.Error(msg)
    print(('[nxn-inventory] [ERROR] %s'):format(tostring(msg)))
end

--- Súlyolás: inventory jelenlegi súlya
---@param items table  { [itemName] = { count=N, ... }, ... }
---@return number
function NXN.Inventory.CalcWeight(items)
    local total = 0.0
    for name, slot in pairs(items) do
        local def = Config.Items[name]
        if def then
            total = total + (def.weight * (slot.count or 1))
        end
    end
    return math.floor(total * 100) / 100
end

--- Item definició visszaadása
---@param name string
---@return table|nil
function NXN.Inventory.GetItemDef(name)
    return Config.Items[name] or nil
end

--- Ellenőrzi, hogy egy item használható-e
---@param name string
---@return boolean
function NXN.Inventory.IsUsable(name)
    local def = Config.Items[name]
    return def and def.usable == true
end
