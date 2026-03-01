# 🎮 Nexon Roleplay — FiveM Script Collection

> Moduláris, framework-független FiveM scriptek a Nexon Roleplay szerverhez.  
> Minden resource az `nxn-` előtagot használja, egységes dizájnrendszerrel és teljes export-kompatibilitással.

---

## 📦 Resourcek

| Resource | Leírás |
|---|---|
| [`nxn-antiwanted`](./nxn-antiwanted) | Körözöttség (wanted level) automatikus kezelése és blokkolása |
| [`nxn-autoseatbelt`](./nxn-autoseatbelt) | Automatikus biztonsági öv felcsatolása járműbe szállásnál |
| [`nxn-cityhall`](./nxn-cityhall) | Városháza rendszer — ügyintézés, iratok, karakterkezelés |
| [`nxn-database`](./nxn-database) | Központi adatbázis-kezelő modul minden script számára |
| [`nxn-engine`](./nxn-engine) | Szerver core engine — alaprendszer és közös logika |
| [`nxn-example`](./nxn-example) | Boilerplate / sablon resource új scriptek készítéséhez |
| [`nxn-hud`](./nxn-hud) | Fő HUD rendszer — élet, páncél, egyéb státusz indikátorok |
| [`nxn-identity`](./nxn-identity) | Karakteridentitás kezelése (név, születési dátum, stb.) |
| [`nxn-inventory`](./nxn-inventory) | Inventory / tárgykezelő rendszer |
| [`nxn-licenses`](./nxn-licenses) | Jogosítványok és engedélyek kezelése |
| [`nxn-loading`](./nxn-loading) | Betöltőképernyő és szerver-csatlakozás UI |
| [`nxn-location-hud`](./nxn-location-hud) | Helyszín megjelenítő HUD elem (utcanév, kerület) |
| [`nxn-minimap`](./nxn-minimap) | Minimap testreszabás és kezelés |
| [`nxn-needs`](./nxn-needs) | Karakter szükségletek rendszere (éhség, szomjúság, stb.) |
| [`nxn-notify`](./nxn-notify) | Értesítési rendszer — toastok, alertek, visszajelzések |
| [`nxn-npcconversation`](./nxn-npcconversation) | NPC párbeszéd és interakció rendszer |
| [`nxn-seatbelt`](./nxn-seatbelt) | Biztonsági öv rendszer — állapot nyilvántartás és logika |
| [`nxn-seatbelt-extras`](./nxn-seatbelt-extras) | Kiegészítők az `nxn-seatbelt` scripthez |
| [`nxn-signs`](./nxn-signs) | Közúti és egyéb táblák megjelenítése a világban |
| [`nxn-vehicle-hud`](./nxn-vehicle-hud) | Jármű HUD — sebesség, üzemanyag, fordulatszám kijelzés |

---

## 🏗️ Architektúra

- **Framework-független** — minden script önállóan működik, nem igényel ESX / QBCore integrációt
- **Export-alapú kommunikáció** — a resourcek egymás exportjain keresztül kommunikálnak
- **Egységes dizájnrendszer** — minden UI a közös [dizájn-dokumentáció](./design-guide.html) alapján épül fel
- **Ikon-könyvtár:** [Huge Icons](https://use.hugeicons.com/font/icons.css)
- **Minden resourcehoz** tartozik konfigurációs fájl és HTML dokumentáció

---

## 🚀 Telepítés

1. Klónozd vagy töltsd le a repót
2. Másold a kívánt `nxn-*` mappákat a szervered `resources/` könyvtárába
3. Add hozzá a resourceket a `server.cfg` fájlhoz az ajánlott sorrendben:

```cfg
# Core
ensure nxn-database
ensure nxn-engine

# UI / HUD
ensure nxn-loading
ensure nxn-notify
ensure nxn-hud
ensure nxn-minimap
ensure nxn-location-hud
ensure nxn-vehicle-hud

# Karakter & Identitás
ensure nxn-identity
ensure nxn-needs
ensure nxn-licenses
ensure nxn-inventory
ensure nxn-cityhall

# Járművek
ensure nxn-seatbelt
ensure nxn-autoseatbelt
ensure nxn-seatbelt-extras
ensure nxn-antiwanted

# Világ
ensure nxn-signs
ensure nxn-npcconversation
```

> ⚠️ Az `nxn-database` és `nxn-engine` resourceket mindig **elsőként** kell elindítani, mivel a többi script ezektől függ.

---

## 🛠️ Fejlesztés

Új resource létrehozásához használd az [`nxn-example`](./nxn-example) boilerplate-et sablonként.  
Minden új scriptnek meg kell felelnie a következő követelményeknek:

- `nxn-` előtag a resource nevében
- Saját `config.lua` konfigurációs fájl
- Export funkciók más resourcek számára
- HTML dokumentáció a dizájn-dokumentáció stílusában
- Kompatibilitás a többi `nxn-*` scripttel

A dizájnrendszer részletei a [`design-guide.html`](./design-guide.html) fájlban találhatók.

---

## 📄 Licensz

Ez a projekt a **Nexon Roleplay** belső fejlesztése. Kizárólag a szerver saját használatára készült.

---

<p align="center">
  <b>Nexon Roleplay</b> · FiveM Roleplay Server · Made with ❤️ in Hungary
</p>
