# 🎮 Nexon Roleplay — FiveM Script Collection

> Moduláris, framework-független FiveM scriptek a Nexon Roleplay szerverhez.  
> Minden resource az `nxn-` előtagot használja, egységes dizájnrendszerrel és teljes export-kompatibilitással.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](./LICENSE)
[![Code of Conduct](https://img.shields.io/badge/Magatart%C3%A1si%20K%C3%B3dex-2025-green)](./CODE_OF_CONDUCT.md)
[![Contributing](https://img.shields.io/badge/Hozz%C3%A1j%C3%A1rul%C3%A1s-welcome-orange)](./CONTRIBUTING.md)

---

## 📦 Resourcek

### 🔧 Core

| Resource | Leírás |
|---|---|
| [`nxn-database`](./nxn-database) | Központi adatbázis-kezelő modul minden script számára |
| [`nxn-example`](./nxn-example) | Boilerplate / sablon resource új scriptek készítéséhez |

### 🖼️ UI / HUD

| Resource | Leírás |
|---|---|
| [`nxn-loading`](./nxn-loading) | Betöltőképernyő és szerver-csatlakozás UI |
| [`nxn-notify`](./nxn-notify) | Értesítési rendszer — toastok, alertek, visszajelzések |
| [`nxn-hud`](./nxn-hud) | Fő HUD rendszer — élet, páncél, egyéb státusz indikátorok |
| [`nxn-minimap`](./nxn-minimap) | Minimap testreszabás és kezelés |
| [`nxn-location-hud`](./nxn-location-hud) | Helyszín megjelenítő HUD elem (utcanév, kerület) |
| [`nxn-vehicle-hud`](./nxn-vehicle-hud) | Jármű HUD — sebesség, üzemanyag, fordulatszám kijelzés |

### 👤 Karakter & Identitás

| Resource | Leírás |
|---|---|
| [`nxn-identity`](./nxn-identity) | Karakteridentitás kezelése (név, születési dátum, stb.) |
| [`nxn-needs`](./nxn-needs) | Karakter szükségletek rendszere (éhség, szomjúság, stb.) |
| [`nxn-licenses`](./nxn-licenses) | Jogosítványok és engedélyek kezelése |
| [`nxn-inventory`](./nxn-inventory) | Inventory / tárgykezelő rendszer |
| [`nxn-cityhall`](./nxn-cityhall) | Városháza rendszer — ügyintézés, iratok, karakterkezelés |

### 💼 Munka & Foglalkoztatás

| Resource | Leírás |
|---|---|
| [`nxn-job`](./nxn-job) | Munkahelyek kezelése — foglalkozások, szerepkörök, besorolás |
| [`nxn-jobwork`](./nxn-jobwork) | Munkafeladatok rendszere — aktiválható munkafolyamatok |
| [`nxn-delivery`](./nxn-delivery) | Kézbesítői munkakör rendszer |
| [`nxn-unemployment`](./nxn-unemployment) | Munkanélküli segély és állami támogatás kezelése |

### 💰 Gazdaság & Kereskedelem

| Resource | Leírás |
|---|---|
| [`nxn-finance`](./nxn-finance) | Pénzügyi rendszer — központi gazdasági logika |
| [`nxn-bank`](./nxn-bank) | Banki műveletek — számlakezelés, utalás, egyenleg |
| [`nxn-shop`](./nxn-shop) | Üzlet / bolt rendszer — termékek vásárlása és eladása |
| [`nxn-food`](./nxn-food) | Étel és ital rendszer — fogyasztás, szükségletek kielégítése |

### 🚗 Járművek

| Resource | Leírás |
|---|---|
| [`nxn-vehicles`](./nxn-vehicles) | Jármű adatbázis és alapkezelés |
| [`nxn-vehicleshop`](./nxn-vehicleshop) | Jármű vásárlás — showroom, vétel, finanszírozás |
| [`nxn-garage`](./nxn-garage) | Garázsrendszer — jármű tárolás, ki- és beparkoltatás |
| [`nxn-keys`](./nxn-keys) | Járműkulcs rendszer — kulcsosztás, zár/nyit |
| [`nxn-trunk`](./nxn-trunk) | Jármű csomagtartó — tárolt tárgyak kezelése |
| [`nxn-fuel`](./nxn-fuel) | Üzemányag rendszer — fogyasztás, feltöltés logika |
| [`nxn-gasstation`](./nxn-gasstation) | Benzínkut interakció — feltöltés, fizetés |
| [`nxn-engine`](./nxn-engine) | Jármű motor kezelése — motor indítás, leállítás és állapot logika |
| [`nxn-seatbelt`](./nxn-seatbelt) | Biztonsági öv rendszer — állapot nyilvántartás és logika |
| [`nxn-autoseatbelt`](./nxn-autoseatbelt) | Automatikus biztonsági öv felcsatolása járműbe szállásnál |
| [`nxn-seatbelt-extras`](./nxn-seatbelt-extras) | Kiegészítők az `nxn-seatbelt` scripthez |
| [`nxn-antiwanted`](./nxn-antiwanted) | Körözöttség (wanted level) automatikus kezelése és blokkolása |

### 🔓 Bűnözés

| Resource | Leírás |
|---|---|
| [`nxn-cartheft`](./nxn-cartheft) | Autólopás rendszer — jármű eltulajonítási mechanika |
| [`nxn-hotwire`](./nxn-hotwire) | Drótokosolás (hotwire) — jármű indítása kulcs nélkül |

### 🌍 Világ

| Resource | Leírás |
|---|---|
| [`nxn-signs`](./nxn-signs) | Közúti és egyéb táblák megjelenítése a világban |
| [`nxn-npcconversation`](./nxn-npcconversation) | NPC párbeszéd és interakció rendszer |

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

# Munka & Foglalkoztatás
ensure nxn-job
ensure nxn-jobwork
ensure nxn-delivery
ensure nxn-unemployment

# Gazdaság & Kereskedelem
ensure nxn-finance
ensure nxn-bank
ensure nxn-shop
ensure nxn-food

# Járművek
ensure nxn-vehicles
ensure nxn-vehicleshop
ensure nxn-garage
ensure nxn-keys
ensure nxn-trunk
ensure nxn-fuel
ensure nxn-gasstation
ensure nxn-engine
ensure nxn-seatbelt
ensure nxn-autoseatbelt
ensure nxn-seatbelt-extras
ensure nxn-antiwanted

# Bűnözés
ensure nxn-cartheft
ensure nxn-hotwire

# Világ
ensure nxn-signs
ensure nxn-npcconversation
```

> ⚠️ Az `nxn-database` resourcet mindig **elsőként** kell elindítani, mivel a többi script etől függ.

---

## 🛠️ Fejlesztés

Új resource létrehozásához használd az [`nxn-example`](./nxn-example) boilerplate-et sablonként.  
Minden új scriptnek meg kell felelnie a következő követelményeknek:

- `nxn-` előtag a resource nevében
- Saját `config.lua` konfigurációs fájl
- Export funkciók más resourcek számára
- HTML dokumentáció a dizájn-dokumentáció stílusában
- Kompatibilitás a többi `nxn-*` scripttel

Részletek a [hozzájárulási útmutatóban](./CONTRIBUTING.md) és a [magatartási kódexben](./CODE_OF_CONDUCT.md).

A dizájnrendszer részletei a [`design-guide.html`](./design-guide.html) fájlban találhatók.

---

## 📄 Licensz

Ez a projekt **GNU General Public License v3** alatt került kiadásra. Lásd: [LICENSE](./LICENSE).

---

<p align="center">
  <b>Nexon Roleplay</b> · FiveM Roleplay Server · Made with ❤️ in Hungary
</p>
