-- ============================================================
--  nxn-antiwanted | config.lua
-- ============================================================

Config = {}

Config.Debug = false  -- Debug üzenetek megjelenítése

-- Ha true, a script indulásakor azonnal nulla csillag szintre állítja a játékost
-- Ha false, csak megakadályozza az ÚJ körözés hozzáadását, a meglévő marad
Config.ClearOnSpawn = true

-- Körözési szint folyamatos törlésének intervalluma (milliszekundum)
-- Ajánlott: 0 (minden tick), ha problémák adódnak, növelhető 500-ra
Config.ClearInterval = 0

-- Megakadályozza-e a rendőrség spawn-olását körözés esetén?
-- (DispatchService letiltása – GTA5 natív dispatch hívások blokkolása)
Config.DisableDispatch = true

-- Dispatch események listája amiket le kell tiltani (1-7 az összes)
-- https://docs.fivem.net/natives/?_0xDC0F817884CDD856
Config.DispatchServices = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }

-- Rendőrségi járőrök automata spawn-jának letiltása
Config.DisableCopSpawn = true

-- Ha true, minden körözési-esemény nativ hívást blokkol (teljes letiltás)
Config.BlockWantedEvents = true

-- Exportot más resource is hívhatja: manuálisan engedélyezhet/tilthat körözést
-- Ha AllowWanted = true, a script NEM törli a körözést (ideiglenesen felfüggesztve)
Config.AllowWanted = false
