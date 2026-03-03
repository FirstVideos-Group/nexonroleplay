# Changelog — nxn-cityhall

Minden jelentősebb változtatás ebben a fájlban kerül dokumentálva.
A formátum a [Keep a Changelog](https://keepachangelog.com/hu/1.0.0/) alapján készül,
és a projekt a [Szemantikus Verziózást](https://semver.org/lang/hu/) követi.

## [Unreleased]

### Tervezett
- `nxn-court` integráció: bírósági időpont-foglalas az NPC ügyészón keresztül (#124)
- Admin bíráságkezelő panel: `/fines [playerid]` parancs, össz-bíráság nézet, szerkesztés (#124)
- `getMenuItems()` kliens export — jelenlegi menüelem lista lekérdezése (#124)
- Discord webhook támogatás `fineIssued` / `finePaid` esemenyekhez (#124)
- `Config.MaxFinesPerPlayer` bíráság-limit per játékos (#124)

---

## [1.0.1] - 2026-03-01

### Javítva

- `server.lua`: `exports['nxn-bank']:getBalance(src)` → `exports['nxn-finance']:getMoney(src, 'bank')` — a bíráság befizetese korábban semmilyen pénzlevást nem végzett, mivel az `nxn-bank` integráció csak kommentként volt jelen; most az `nxn-finance` exportokra váltott (#141, commit `27988d3`)
- `server.lua`: `exports['nxn-bank']:removeBalance(src, fine.amount)` → `exports['nxn-finance']:removeMoney(src, fine.amount, 'bank', fine.reason, 'nxn-cityhall')` (#141, commit `27988d3`)
- `fxmanifest.lua`: `nxn-bank` dependency eltávolítva, `nxn-finance` hozzáadva (#141, commit `27988d3`)

---

## [1.0.0] - 2026-03-01

### Hozzáadva

- Első kiadás: teljes önkormányzati rendszer (igazolvány, csekk, bíráságok, ügyek)
- **NPC-alapú müvi menü** — `nxn-npcconversation` integrációval, konfigurálható menüpontok (`addMenuItem` export)
- **Igazolvány lekérés** — NPC párbeszéden keresztül, `nxn-identity` adatokkal
- **Csekk kiváltás** — "felvétel" menüpont, szerver-oldali validacióval
- **Bíráságrendszer** — `nxn_fines` DB tábla, bíráság lista UI, befizetesi folyamat
- **Többkörös bíráság nézet** — szűrés (aktiv / fizetésre váró), pagálás
- `config.lua` — `Config.NPCLocation`, `Config.NPCModel`, `Config.BuildingBlip`, `Config.MenuItems`, `Config.InfoContent` beállítások
- `shared.lua` — `NXN.CityHall` névtér, egységes Log/Info/Warn/Error logger
- **Szerver exportok**: `issueFine(src, reason, amount, issuedBy)`, `revokeFine(fineId)`, `getFines(src)`, `getUnpaidTotal(src)`
- **Kliens exportok**: `addMenuItem(cfg)`, `removeMenuItem(id)`, `openFinesPanel()`
- `docs/index.html` — interaktív dokumentáció tabos kódpeldákkal, export/event táblázatokkal

### Integrációk

- `nxn-database` — `registerTable` + `getIdentifier` exportok, `nxn_fines` tábla
- `nxn-notify` — `success` / `danger` / `warning` / `info` visszajelzések
- `nxn-npcconversation` — `registerNPC` + `addMenuItem` NPC-alapú menürendszer
- `nxn-identity` — `getFullName(src)` igazolvány lekéréshez
- `nxn-finance` — `getMoney` / `removeMoney` bíráság befizeteshez (lásd: 1.0.1 javítás)

### Javítva (első kiadásba beolvasztva)

- `client.lua`: `playerSpawned` kizárólagos használata megbízhatatlanná tette az inicializálást, ha a resource a spawn után indult el — kiegészítve `onResourceStart` esemenykezelővel (#11)
- `server.lua` (`payFine`): bíráság befizeteskor nem történt pénzlevónás, mivel a bankintegráció csak kommentként volt jelen — pénzrendszer-integráció megvalósítva (#12)
- `server.lua` (`getFines` export): az export `finesCache[src]`-ből olvasott, ami `issueFine` hívás után nem frissült — cache szinkronizálva az `issueFine` exportban, vagy DB-ből olvas (#13)
- `server.lua` (`payFine`): `fineId` paraméter típusvalidáció hiányzott, kliensoldali `nil`/string érték MySQL runtime hibát okozhatott — egész-szamu validació hozzáadva (#14)
- `client.lua` (`finesPaid` event): a bíráság befizetése után teljes `OpenView` újrahívás történt, ami dupla NUI megnyitást és UI-villogást okozott — átváltva `updateFines` NUI üzenetre (#15)
- `config.lua`: számos elirás a játékosok számára látható szövegekben (pl. `'Nincs fiiggő bírásgod...'`, `'befaiti az önkormányzathoz'`, `'híd elő az igazolvány kezelőt!'`) — összes szöveghiba kijavítva (#16)
