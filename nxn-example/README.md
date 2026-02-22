> **Nexon FiveM Boilerplate Resource**  
> Minden új `nxn-*` script kiindulópontja. Tartalmaz kliens/szerver kommunikációt, NUI panelt, értesítési rendszert, exportokat és dokumentációt.

---

## 📦 Tartalomjegyzék

- [Telepítés](#telepítés)
- [Mappastruktúra](#mappastruktúra)
- [Konfiguráció](#konfiguráció)
- [Parancsok](#parancsok)
- [Exportok](#exportok)
- [Net Events](#net-events)
- [NUI üzenetek](#nui-üzenetek)
- [Kompatibilitás](#kompatibilitás)
- [Fejlesztői útmutató](#fejlesztői-útmutató)

---

## 🚀 Telepítés

1. Másold az `nxn-example` mappát a szervered `resources/` könyvtárába.
2. Add hozzá a `server.cfg`-hez:
   ```
   ensure nxn-example
   ```
3. Indítsd újra a szervert vagy használd a `refresh` + `start nxn-example` parancsot.

---

## 📁 Mappastruktúra

```
nxn-example/
├── fxmanifest.lua          # Resource manifest
├── config.lua              # Konfigurációs fájl
├── shared/
│   └── shared.lua          # Közös segédfüggvények (client + server)
├── client/
│   └── client.lua          # Kliens oldali logika, exportok, NUI bridge
├── server/
│   └── server.lua          # Szerver oldali logika, exportok
├── html/
│   ├── index.html          # NUI felület
│   ├── style.css           # Nexon Design System stílusok
│   └── app.js              # NUI JavaScript logika
└── docs/
    └── index.html          # Interaktív HTML dokumentáció
```

---

## ⚙️ Konfiguráció

A `config.lua` fájlban módosíthatók az alábbi beállítások:

| Kulcs                  | Alapértelmezett | Leírás                                      |
|------------------------|-----------------|---------------------------------------------|
| `Config.Debug`         | `false`         | Debug logok engedélyezése a konzolon        |
| `Config.ResourceName`  | *(auto)*        | A resource neve (automatikusan töltődik be) |
| `Config.NotifyDuration`| `4000`          | Értesítés megjelenési ideje milliszekundumban |
| `Config.ExampleText`   | `'Hello Nexon!'`| Alapértelmezett szöveg                      |
| `Config.UI.position`   | `'top-right'`   | Értesítések pozíciója (`top-right`, `top-left`, `bottom-right`, `bottom-left`) |
| `Config.UI.theme`      | `'dark'`        | UI téma (`dark` / `light`)                  |

---

## 🕹️ Parancsok

| Parancs        | Leírás                              |
|----------------|-------------------------------------|
| `/nxnexample`  | Megnyitja / bezárja a UI panelt     |

---

## 📤 Exportok

### 🖥️ Kliens oldali exportok

```lua
-- UI megnyitása
exports['nxn-example']:openUI()

-- UI bezárása
exports['nxn-example']:closeUI()

-- Ellenőrzés: nyitva van-e a UI?
local open = exports['nxn-example']:isUIOpen()

-- Értesítés küldése a helyi játékosnak
exports['nxn-example']:sendNotify('Üzenet szövege')
```

### 🖧 Szerver oldali exportok

```lua
-- Értesítés küldése egy adott játékosnak
exports['nxn-example']:notifyPlayer(source, 'Üdvözöllek!')

-- Értesítés broadcast minden játékosnak
exports['nxn-example']:broadcastNotify('Szerver újraindul 5 perc múlva!')

-- UI megnyitása egy adott játékosnál
exports['nxn-example']:openUIForPlayer(source)
```

---

## 📡 Net Events

| Event neve                              | Irány              | Leírás                                 |
|-----------------------------------------|--------------------|----------------------------------------|
| `nxn-example:server:doAction`           | Client → Server    | Általános akció küldése a szervernek   |
| `nxn-example:server:openUIForPlayer`    | Client → Server    | UI megnyitás kérése szerver felé       |
| `nxn-example:client:notify`             | Server → Client    | Értesítés megjelenítése a kliensen     |
| `nxn-example:client:openUI`             | Server → Client    | UI panel megnyitása a kliensen         |

---

## 💬 NUI üzenetek

A szerver/kliens a `SendNUIMessage()` hívással kommunikál a HTML felülettel:

| `action`        | Adatok                      | Leírás                          |
|-----------------|-----------------------------|---------------------------------|
| `setVisible`    | `{ visible: true/false }`   | Panel megjelenítése / elrejtése |
| `showNotify`    | `{ message, type }`         | Értesítés megjelenítése         |

**Példa JavaScript oldalon:**
```javascript
window.addEventListener('message', ({ data }) => {
    if (data.action === 'showNotify') {
        showNotify(data.message, data.type);
    }
});
```

---

## 🔗 Kompatibilitás

Ez a resource a **Nexon ökoszisztéma** része. Más `nxn-*` resource-ok szabadon hívhatják az exportjait:

```lua
-- Bármely más nxn-* resource kliens oldalán:
exports['nxn-example']:openUI()

-- Bármely más nxn-* resource szerver oldalán:
exports['nxn-example']:notifyPlayer(source, 'Üzenet')
```

> ⚠️ **Fontos:** Ha ezt a boilerplate-et új resource alapjaként használod,
> cseréld le az összes `nxn-example` hivatkozást az új resource nevére,
> beleértve az event neveket és export hívásokat is.

---

## 🛠️ Fejlesztői útmutató

### Új script készítése ebből a sablonból

1. Másold le a mappát, nevezd át `nxn-sajatscript`-re
2. Cseréld le az `nxn-example` stringet mindenhol az új névre
3. Bővítsd a `shared/shared.lua`-t közös logikával
4. Adj hozzá új exportokat a `client.lua` és `server.lua` fájlokhoz
5. Frissítsd a `docs/index.html`-t az új exportokkal és eseményekkel

### Design szabályok

- ❌ **Tilos** `backdrop-filter` CSS property használata
- ✅ Ikonokhoz kizárólag **Huge Icons** használandó: `https://use.hugeicons.com/font/icons.css`
- ✅ A CSS változók (`--nxn-*`) egységesek kell maradjanak minden `nxn-*` resource-ban
- ✅ Minden UI elem illeszkedjen a **Nexon Design System**-hez

### Debug mód

Állítsd `Config.Debug = true` értékre a `config.lua`-ban, ekkor az összes belső esemény és hívás megjelenik a szerver/kliens konzolon.

---

## 📄 Licensz

Belső Nexon fejlesztés – kizárólag saját szerver használatra.

---

*Nexon FiveM Scripts © 2026*
