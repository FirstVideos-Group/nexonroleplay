-- ============================================================
--  nxn-cityhall | shared.lua
-- ============================================================

NXN        = NXN or {}
NXN.CityHall = {}

function NXN.CityHall.Log(msg)
    if Config and Config.Debug then
        print(('[nxn-cityhall] [DEBUG] %s'):format(tostring(msg)))
    end
end

function NXN.CityHall.Info(msg)
    print(('[nxn-cityhall] [INFO] %s'):format(tostring(msg)))
end

function NXN.CityHall.Warn(msg)
    print(('[nxn-cityhall] [WARN] %s'):format(tostring(msg)))
end

function NXN.CityHall.Error(msg)
    print(('[nxn-cityhall] [ERROR] %s'):format(tostring(msg)))
end
