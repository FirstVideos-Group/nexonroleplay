# Changelog — nxn-cartheft

Minden jelentősebb változtatás ebben a fájlban kerül dokumentálva.
A formátum a [Keep a Changelog](https://keepachangelog.com/hu/1.0.0/) alapján készül,
és a projekt a [Szemantikus Verziózást](https://semver.org/lang/hu/) követi.

## [Unreleased]

## [1.0.1] - 2026-03-02

### Javítva

- `GetClosestLockedVehicle()` függvényben a `GetEntityCoords()` visszatérési értékét többsörös Lua változóba bontották szet (`px, py, pz`), ami `nil` értékeket eredményezett `py` és `pz` számára, és `bad argument #2 to 'vector3' (invalid vector dimensions)` crash-t okozott két különböző `CreateThread`-ben (client.lua:32, sorok 149 és 171) — javítva közvetlen `vector3` típusú változók használatával (`pPos`, `vPos`) (#187, commit `3a50378`)

## [1.0.0] - 2026-03-01

### Hozzáadva

- Első kiadás: teljes autófeltörés rendszer (commit `d44e2ad`) (#148)
- **Lockpick miniejáték** — SVG-alapú forgó tű + célzózna, `[E]`-vel megállítás, többkörös (1–N zár), minden körrel gyorsuló tű, zöld/piros flash visszajelzés, timer progress bar
- **Keypad miniejáték (Simon Says)** — véletlenszerű szimbólumsorozat megjelenítés → elrejtés → bevitel, időlimit, helyes/helytelen visszajelzés
- **`random` mód** — véletlenszerűen választ lockpick vagy keypad között (`Config.MinigameMode = 'random'`)
- **Timer progress bar** — zöld/sárga/piros szín az idő függvényében
- **Animáció + prop** — csavarhúzó kézben, feltörési animáció a kliensen
- **6 rétegű szerver-oldali biztonság** — cooldown, `hasKey`, `isOwner`, `isBeingBrokenInto`, `MaxAttemptsPerVehicle`, koordináta re-ellenőrzés
- **Rendőrségi riasztás** — `nxn-cartheft:server:attemptLogged` event, `nxn-police` `GetResourceState` guard
- **DB logolás** — `nxn_cartheft_log` tábla, `nxn-database:registerTable()` regisztrálás
- `config.lua` — `Config.MinigameMode`, `Config.LockpickRounds`, `Config.KeypadLength`, `Config.CooldownMs`, `Config.MaxAttemptsPerVehicle`, `Config.AlertPolice` beállítások
- `shared.lua` — `NXN.CarTheft` névtér, egységes Log/Info/Warn/Error logger
- Szerver exportok: `isBeingBrokenInto(plate)`, `getAttemptLog(plate, limit?)`
- Kliens exportok: `startTheft(vehicle?)`, `cancelTheft()`
- `docs/index.html` — interaktív dokumentáció tabos kódpeldákkal, flow-lánccal, export/event táblázatokkal

### Integrációk

- `nxn-engine` — `setLocked(false)` hívás feltörés sikerén (kliensre delegált), `isLocked` ellenőrzés
- `nxn-keys` — `hasKey(src, plate)` kötelező szerver-oldali ellenőrzés
- `nxn-vehicles` — `isOwner(src, plate)` kötelező szerver-oldali ellenőrzés
- `nxn-notify` — `success` / `danger` / `warning` / `info` visszajelzések
- `nxn-database` — `registerTable` + MySQL insert logolás
- `nxn-identity` — `getIdentifier(src)` fallback azonosító lekéréshez
- `nxn-police` — `attemptLogged` event figyelhető rendőrségi riasztáshoz, `GetResourceState` guard
- `nxn-hotwire` — feltörés után `TaskEnterVehicle`; motor indítás az `nxn-hotwire` feladata (`startHotwire(veh)` export előkészítve)
