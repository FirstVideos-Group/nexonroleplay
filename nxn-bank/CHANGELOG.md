# Changelog — nxn-bank

Minden jelentősebb változtatás ebben a fájlban kerül dokumentálva.
A formátum a [Keep a Changelog](https://keepachangelog.com/hu/1.0.0/) alapján készül,
és a projekt a [Szemantikus Verziózást](https://semver.org/lang/hu/) követi.

## [Unreleased]

## [1.0.0] - 2026-03-01

### Hozzáadva

- Első kiadás: teljes ATM / bankrendszer (commit `a7e261e`) (#142)
- `fxmanifest.lua` — függőségek: `nxn-finance`, `nxn-database`, `nxn-notify`, `nxn-identity`
- `config.lua` — ATM és bankfiók helyszínek, marker beállítások, tranzakció cooldown, lapozás limit
- `shared.lua` — `NXN.Bank` névtér, egységes Log/Info/Warn/Error logger
- `server.lua` — `nxn_bank_transactions` DB tábla regisztrálás (`nxn-database:registerTable`), deposit / withdraw / transfer / getTransactions net eventek és szerver exportok
- `client.lua` — közelség-ellenőrzés, marker + szöveg rajzolás, NUI vezérlés, kliens exportok
- `html/index.html` + `html/style.css` + `html/app.js` — ATM és bankpult UI (Nexon dizájnsablon); tab-ok: befáfizetés, felvét, átutálás, napló; lapozás a tranzakciólistaban
- `docs/index.html` — teljes dokumentáció exportokkal, net event táblázattal, kód-snippetekkel
- Szerver exportok: `deposit(src, amount)`, `withdraw(src, amount)`, `transfer(src, targetId, amount, reason?)`, `getTransactions(src, page?, perPage?)`
- Kliens exportok: `openATM(atmId?)`, `closeATM()`, `isATMOpen()`, `syncBalance()`
- `nxn-finance` exportok használata minden pénzmozgásnál: `getMoney`, `addMoney`, `removeMoney`
- `nxn-hud` `updateModuleData('money', ...)` szinkronizálás egyenlegváltozáskor
- `nxn-identity` `getFullName` integráció átutálásnál (fogadó név megjelenítése)
- `nxn-database` `registerTable` és `getIdentifier` integráció
- `nxn-notify` visszajelzések minden tranzakciós műveletnél
- Szerver-oldali biztonsági ellenőrzések: negatív / float / 0 összeg szűrése, tranzakció cooldown, célszeMély validálása átutálásnál, egyenleg-ellenőrzés levonás előtt
- `GetResourceState` ellenőrzés minden külső export hívás előtt
- `docs/index.html` nem szerepel a `files` szekcióban (rendszerszintű policy alapján, ld. #69)

### Integrációk

- `nxn-cityhall` már `nxn-finance` exportokat hív — az `nxn-bank` közvetlen hívására nincs szükség (#12 bug nélkülözhetővé válik, mivel a fizetési logika `nxn-finance`-en át történik)
