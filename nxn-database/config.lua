Config = {}

Config.Debug           = false                -- Debug logok engedélyezése
Config.ResourceName    = GetCurrentResourceName()

-- Játékos azonosító típusa (license | steam | discord | ip)
Config.IdentifierType  = 'license'

-- Játékos tábla neve az adatbázisban
Config.PlayersTable    = 'nxn_players'

-- Automatikusan létrehozza a táblát, ha nem létezik
Config.AutoMigrate     = true

-- Hány másodpercenként frissüljön a last_online mező (0 = csak disconnectnél)
Config.HeartbeatInterval = 300  -- 5 perc
