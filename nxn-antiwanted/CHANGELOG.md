# Changelog — nxn-antiwanted

Minden jelentősebb változtatás ebben a fájlban kerül dokumentálásra.
A formátum a [Keep a Changelog](https://keepachangelog.com/hu/1.0.0/) alapján készül,
és a projekt a [Szemantikus Verziózást](https://semver.org/lang/hu/) követi.

## [Unreleased]

## [1.0.1] - 2026-03-01

### Javítva

- Eltávolítva a felesleges `local ped = PlayerPedId()` változó a `ClearWanted()` függvényből — sehol nem volt felhasználva (#1)
- Hozzáadva a hiányzó kliens event handlerek: `nxn-antiwanted:client:clearWanted` és `nxn-antiwanted:client:setWantedState` — a szerver exportok (`clearWantedForPlayer`, `enableWantedForPlayer`, `disableWantedForPlayer`) ezek nélkül teljesen működésképtelenek voltak (#2)
- Hozzáadva a per-player `wantedState` szinkronizáció: szerver oldali állapottábla (`playerWantedState`) + kliens oldali `reportState` visszajelzés — az `allowWanted` változó korábban nem szinkronizálódott szerver és kliens között (#3)
- A nem létező `playerSpawned` szerver event helyett bevezetésre került a `nxn-antiwanted:server:playerReady` event, amelyet a kliens küld spawn után — korábban a szerver oldali spawn-követő inicializáció soha nem futott le (#4)
- Hozzáadva ACE jogosultság-ellenőrzés (`nxn-antiwanted.setWantedState`) a `setWantedState` szerver eventhez — korábban bármely kliens meg tudta hívni, biztonsági rést okozva (#5)

## [1.0.0] - 2026-03-01

### Hozzáadva

- Első kiadás: játék alapértelmezett körözési rendszerének automatikus kikapcsolása
- `ClearWanted()` kliens oldali függvény — folyamatosan törli a wanted szintet, ha `allowWanted` hamis
- `enableWanted()` és `disableWanted()` kliens exportok — körözés engedélyezése/tiltása játékosonként
- `clearWantedForPlayer(src)`, `enableWantedForPlayer(src)`, `disableWantedForPlayer(src)` szerver exportok
- `getWantedStateForPlayer(src)` szerver export — lekéri egy adott játékos aktuális körözési állapotát
- `config.lua`: `Config.AllowWanted`, `Config.ClearInterval`, `Config.Debug` beállítások
- `shared.lua`: egységes `NXN.AntiWanted` névtér, Log/Info/Warn/Error helper függvények
