-- ============================================================
--  nxn-fuel | config.lua
-- ============================================================

Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug        = false

-- Fogyasztás frissitési intervallum (ms)
Config.PollInterval = 2000

-- Alapértelmezett tankméret (liter), ha nxn-vehicles nem adja meg
Config.DefaultTankSize = 65.0

-- Fogyasztási alap (liter / másodperc, mozgás közben)
Config.BaseConsumption = 0.003   -- liter/mp, alapjáraton
Config.SpeedMultiplier = 0.0001  -- extra liter/km/h

-- Motor nélküli fogyasztás (pl. parkoló, alapjárat)
Config.IdleConsumption = 0.0008  -- liter/mp

-- Üzemanyag 0% esetén motor leállítása
Config.StallOnEmpty = true

-- Alacsony üzemanyag figyelmeztetési küszöb (%)
Config.LowFuelThreshold = 15.0

-- Figyelmeztetés cooldown (másodperc)
Config.LowFuelNotifyCooldown = 60

-- DB mentési intervallum (ms)
Config.SaveInterval = 30000

-- Spawn üzemanyag
-- 'random': SpawnFuelMin–SpawnFuelMax között
-- 'full':   100%
-- 'last':   utolsó mentett érték (DB-ből)
Config.DefaultFuelOnSpawn = 'random'
Config.SpawnFuelMin       = 30.0
Config.SpawnFuelMax       = 90.0

-- HUD frissitési min. változás (liter, ennél kisebb delta nem triggerel HUD push-t)
Config.HudUpdateThreshold = 0.1
