# Changelog — nxn-autoseatbelt

Minden jelentősebb változtatás ebben a fájlban kerül dokumentálásra.
A formátum a [Keep a Changelog](https://keepachangelog.com/hu/1.0.0/) alapján készül,
és a projekt a [Szemantikus Verziózást](https://semver.org/lang/hu/) követi.

## [Unreleased]

## [1.0.1] - 2026-03-01

### Javítva

- Hozzáadva `GetResourceState('nxn-seatbelt')` ellenőrzés a `DoAutoFasten()` függvénybe — korábban Lua runtime hibát okozott, ha az `nxn-seatbelt` nem futott (#6)
- Szétválasztva a `triggerNow` és `forceAutoFasten` exportok logikája: a `triggerNow` mostantól megvizsgálja a `ShouldAutoFasten()` feltételeket, a `forceAutoFasten` valóban kényszer-bekötést végez ellenőrzés nélkül (#7)
- Bevezetésre került a `fastenSession` számláló a gyors ki-be szállás esetén keletkező race condition megakadályozására — több párhuzamos szál többszörös bekötést végezhetett (#8)
- Hozzáadva `nxn-notify` a `fxmanifest.lua` `dependencies` listájához — korábban hiányzó dependency miatt a FiveM nem garantalta az indítási sorrendet (#9)
- Implementálva a `Config.AutoClasses = { -1 }` (minden osztály) kezelése a `ShouldAutoFasten()`-ben (#10)

## [1.0.0] - 2026-03-01

### Hozzáadva

- Első kiadás: automatikus biztonsági öv bekötés járműbe szálláskor
- `DoAutoFasten(vehicle)` — késleltetett auto-bekötési logika
- `ShouldAutoFasten(vehicle)` — járműosztály és kizárási lista ellenőrzése
- `FastenViaSeatbelt()` — `nxn-seatbelt` export hívása resource-állapot-ellenőrzéssel
- `triggerNow()` export — azonnali auto-bekötés kiváltása
- `forceAutoFasten()` export — kényszer-bekötés járműlista-ellenőrzés nélkül
- `addAutoClass(class)`, `removeAutoClass(class)`, `getAutoClasses()` exportok — járműosztályok futtatás közbeni módosítása
- `config.lua`: `Config.AutoFastenDelay`, `Config.AutoClasses`, `Config.ExcludedVehicles`, `Config.Debug` beállítások
- `shared.lua`: egységes `NXN.AutoSeatbelt` névtér, Log/Info/Warn/Error helper függvények
- Auto-bekötési hang effekt (`sounds/seatbelt_auto.ogg`) lejátszása bekötéskor
