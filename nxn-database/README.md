# nxn-database

**Verzió:** v1.0.0

Az **nxn-database** a Nexon szerver centrális adatbázis-kezelő resource-a.
`oxmysql`-re épül, kezeli a játékos alapadatait (join, last_online, playtime, metadata), és bővíthető interfészt nyújt más `nxn-*` resource-ok számára.

---

## 📦 Dependency

> **Kötelező:** `oxmysql`
> A resource csak akkor indul el, ha az `oxmysql` fut.

---

## 📁 Fájlstruktúra

```
nxn-database/
├── fxmanifest.lua
├── config.lua
├── shared.lua
├── server.lua
└── docs/index.html
```

---

## ⚙️ Konfiguráció (`config.lua`)

| Kulcs                      | Alapértelmezett | Leírás                                                   |
| -------------------------- | --------------- | -------------------------------------------------------- |
| `Config.Debug`             | `false`         | Debug logok engedélyezése a konzolban                    |
| `Config.IdentifierType`    | `'license'`     | Azonosító típusa: `license` | `steam` | `discord` | `ip` |
| `Config.PlayersTable`      | `'nxn_players'` | Játékos tábla neve az adatbázisban                       |
| `Config.AutoMigrate`       | `true`          | Automatikus tábla-létrehozás induláskor                  |
| `Config.HeartbeatInterval` | `300`           | `last_online` frissítés másodpercenként (0 = kikapcs)    |

---

## 🗄 Adatbázis séma – `nxn_players`

| Mező             | Típus              | Leírás                                      |
| ---------------- | ------------------ | ------------------------------------------- |
| `id`             | INT UNSIGNED AI    | Belső azonosító                             |
| `identifier`     | VARCHAR(60) UNIQUE | Játékos licensz / steam / discord azonosító |
| `name`           | VARCHAR(60)        | Játékon belüli név (automatikusan frissül)  |
| `first_joined`   | DATETIME           | Első csatlakozás időpontja                  |
| `last_online`    | DATETIME           | Utolsó aktív időpont                        |
| `total_playtime` | INT UNSIGNED       | Összesített játékidő (másodpercben)         |
| `metadata`       | LONGTEXT (JSON)    | Szabad JSON mező – más resource-ok adatai   |

---

## 🔌 Exportok

| Export neve                              | Oldal  | Leírás                                      |
| ---------------------------------------- | ------ | ------------------------------------------- |
| `getPlayer(src)`                         | server | Cache-elt játékosadat visszaadása           |
| `getIdentifier(src)`                     | server | Játékos identifier string                   |
| `getAllPlayers()`                        | server | Összes online játékos cache-e               |
| `getPlayerByIdentifier(ident, cb)`       | server | DB lekérdezés identifier alapján (async)    |
| `getMeta(src, key)`                      | server | Metadata JSON mező olvasása kulcs szerint   |
| `setMeta(src, key, value)`               | server | Metadata JSON mező írása / frissítése       |
| `queryAllPlayers(cb)`                    | server | Teljes játékoslista DB-ből (admin)          |
| `registerTable(resourceName, tableInfo)` | server | Más resource saját tábláját regisztrálhatja |

---

## 💻 Export használati példák

### `getPlayer`

```lua
local player = exports['nxn-database']:getPlayer(source)

if player then
    print('Játékos neve: ' .. player.name)
    print('Azonosító: ' .. player.identifier)
    print('Utoljára online: ' .. player.last_online)
    print('Játékidő (s): ' .. player.total_playtime)
end
```

---

### `getMeta / setMeta`

```lua
-- Metadata írása
exports['nxn-database']:setMeta(source, 'job', { name = 'police', grade = 2 })

-- Metadata olvasása
local job = exports['nxn-database']:getMeta(source, 'job')

if job then
    print('Munkakör: ' .. job.name .. ' | Rang: ' .. job.grade)
end
```

---

### `registerTable`

```lua
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end

    exports['nxn-database']:registerTable(GetCurrentResourceName(), {
        name = 'nxn_vehicles',
        sql  = [[
            CREATE TABLE IF NOT EXISTS `nxn_vehicles` (
                `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `identifier` VARCHAR(60)  NOT NULL,
                `plate`      VARCHAR(8)   NOT NULL UNIQUE,
                `model`      VARCHAR(60)  NOT NULL,
                PRIMARY KEY (`id`),
                INDEX `idx_owner` (`identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    })
end)
```

---

### `queryAllPlayers`

```lua
exports['nxn-database']:queryAllPlayers(function(rows)
    for _, row in ipairs(rows) do
        print(row.name, row.identifier, row.last_online)
    end
end)
```

---

### `getPlayerByIdentifier`

```lua
exports['nxn-database']:getPlayerByIdentifier('license:abc123', function(row)
    if row then
        print('Játékos megtalálva: ' .. row.name)
    else
        print('Nem található ilyen azonosítóval')
    end
end)
```

---

## 📡 Net Events

| Event neve                         | Irány           | Leírás                                                                          |
| ---------------------------------- | --------------- | ------------------------------------------------------------------------------- |
| `nxn-database:server:playerLoaded` | Server → Server | Más resource-ok figyelhetik, mikor töltött be egy játékos (`src`, `playerData`) |

### Figyelés más resource-ból

```lua
AddEventHandler('nxn-database:server:playerLoaded', function(src, data)
    print(('Betöltött: %s | id: %d'):format(data.name, data.id))
end)
```

---

## 🐞 Debug logok

A `Config.Debug = true` beállítással részletes naplókat kapsz a konzolban minden:

* DB-műveletről
* cache-hozzáférésről
* heartbeat-frissítésről

> Éles szerveren kapcsold ki.
