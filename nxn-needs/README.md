# nxn-needs

**Verzió:** v1.0.0

Az **nxn-needs** kezeli a játékos alapvető szükségleteit:

* Éhség (`hunger`)
* Szomjúság (`thirst`)
* Stressz (`stress`)
* Fáradtság (`fatigue`)

Az adatokat az `nxn_needs` táblában tárolja, az **nxn-database** `registerTable` exportján keresztül regisztrálva.
A HUD resource exportokon és kliens eventeken keresztül jelenítheti meg az adatokat.

---

## 📦 Függőségek

* `oxmysql`
* `nxn-database`

> Mindkettőnek futnia kell az `nxn-needs` előtt.

---

## 📁 Fájlstruktúra

```
nxn-needs/
├── fxmanifest.lua
├── config.lua
├── shared.lua
├── client.lua
├── server.lua
└── docs/index.html
```

---

## 🔄 Adatfolyam

```
nxn-database:playerLoaded
        ↓
LoadNeeds() (DB / új rekord)
        ↓
needsCache[src] feltöltve
        ↓
SyncClient()
        ↓
nxn-needs:client:updated (HUD figyeli)
```

---

## ⚙️ Konfiguráció (`config.lua`)

| Kulcs                           | Alapértelmezett | Leírás                                 |
| ------------------------------- | --------------- | -------------------------------------- |
| `Config.Debug`                  | `false`         | Debug logok engedélyezése              |
| `Config.Needs.*`                | –               | Szükségletek min/max/default értékei   |
| `Config.AutoDecay.enabled`      | `true`          | Automatikus csökkentés/növekedés       |
| `Config.AutoDecay.interval`     | `60`            | Tick intervallum másodpercben          |
| `Config.AutoDecay.rates.*`      | –               | Szükségletek változási rátája / perc   |
| `Config.NeedsTable`             | `'nxn_needs'`   | DB tábla neve                          |
| `Config.SaveInterval`           | `300`           | Periodikus DB-mentés (mp), 0 = kikapcs |
| `Config.DamageOnEmpty.enabled`  | `true`          | HP csökkentés ha hunger/thirst = 0     |
| `Config.DamageOnEmpty.interval` | `10`            | Damage check intervallum (mp)          |
| `Config.DamageOnEmpty.amount`   | `1`             | HP csökkentés mértéke                  |

---

## 🗄 Adatbázis séma – `nxn_needs`

| Mező         | Típus              | Leírás                               |
| ------------ | ------------------ | ------------------------------------ |
| `id`         | INT UNSIGNED AI    | Belső azonosító                      |
| `identifier` | VARCHAR(60) UNIQUE | Játékos azonosító (nxn-database-ből) |
| `hunger`     | FLOAT              | Éhség szint (0–100)                  |
| `thirst`     | FLOAT              | Szomjúság szint (0–100)              |
| `stress`     | FLOAT              | Stressz szint (0–100)                |
| `fatigue`    | FLOAT              | Fáradtság szint (0–100)              |
| `updated_at` | DATETIME           | Utolsó frissítés                     |

---

## 🔌 Exportok

### 🖥 Server

| Export                          | Leírás                                |
| ------------------------------- | ------------------------------------- |
| `getNeeds(src)`                 | Összes szükséglet visszaadása (cache) |
| `getNeed(src, need)`            | Egy konkrét szükséglet értéke         |
| `setNeed(src, need, value)`     | Szükséglet beállítása (clamp + sync)  |
| `modifyNeed(src, need, amount)` | Relatív módosítás (+/-)               |
| `resetNeeds(src)`               | Visszaállítás alapértékekre           |
| `saveNeeds(src)`                | Azonnali DB-mentés                    |

### 🖥 Client

| Export               | Leírás                                |
| -------------------- | ------------------------------------- |
| `getLocalNeeds()`    | Lokális needs tábla                   |
| `getLocalNeed(need)` | Egy konkrét szükséglet kliens oldalon |

---

## 💻 Export használati példák

### 🍔 Evés / Ivás

```lua
-- Hamburger evése: hunger +35
exports['nxn-needs']:modifyNeed(source, 'hunger', 35)

-- Víz ivása: thirst +40
exports['nxn-needs']:modifyNeed(source, 'thirst', 40)

-- Pontos beállítás
exports['nxn-needs']:setNeed(source, 'hunger', 100)
```

---

### 😰 Stressz kezelés

```lua
-- Stressz növelése
exports['nxn-needs']:modifyNeed(source, 'stress', 20)

-- Stressz csökkentése
exports['nxn-needs']:modifyNeed(source, 'stress', -30)

-- Fáradtság ellenőrzése
local fatigue = exports['nxn-needs']:getNeed(source, 'fatigue')
if fatigue > 80 then
    -- játékos lassabb legyen
end
```

---

### 📊 HUD figyelés (kliens)

```lua
-- nxn-hud client.lua

AddEventHandler('nxn-needs:client:updated', function(needs)
    SendNUIMessage({
        action = 'updateNeeds',
        needs  = needs
    })
end)

-- Direkt lekérdezés
local needs = exports['nxn-needs']:getLocalNeeds()
local hunger = exports['nxn-needs']:getLocalNeed('hunger')
```

---

### 🛠 Admin reset

```lua
RegisterCommand('resetneeds', function(src, args)
    local target = tonumber(args[1]) or src
    exports['nxn-needs']:resetNeeds(target)
end, true)

local needs = exports['nxn-needs']:getNeeds(target)
if needs then
    print('Hunger: ' .. needs.hunger .. ' | Thirst: ' .. needs.thirst)
end
```

---

### 🔎 `getNeed` ellenőrzés

```lua
local hunger = exports['nxn-needs']:getNeed(source, 'hunger')

if hunger ~= nil and hunger < 20 then
    exports['nxn-database']:setMeta(source, 'isHungry', true)
end
```

---

## 📡 Net Events

| Event                          | Irány           | Leírás                     |
| ------------------------------ | --------------- | -------------------------- |
| `nxn-needs:server:requestSync` | Client → Server | Kliens szinkronizációt kér |
| `nxn-needs:client:sync`        | Server → Client | Needs adatok küldése       |
| `nxn-needs:client:applyDamage` | Server → Client | HP csökkentés              |
| `nxn-needs:client:updated`     | Client (local)  | HUD figyelheti             |
| `nxn-needs:server:needsLoaded` | Server (local)  | Needs betöltve             |

---

## 🖥 HUD integráció

Az `nxn-hud` resource:

* a `nxn-needs:client:updated` lokális eventet hallgatja
* a `getLocalNeeds()` exportot hívja

Szerver oldalon elérhető:

* `getNeeds(src)`
* `getNeed(src, need)`

---

## 🐞 Debug logok

`Config.Debug = true` esetén részletes naplókat kapsz:

* DB-műveletekről
* cache-hozzáférésekről
* AutoDecay tickről
* szinkronizációról

> Éles szerveren kapcsold ki.
