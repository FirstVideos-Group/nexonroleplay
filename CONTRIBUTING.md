# 🤝 Hozzájárulási útmutató — Nexon Roleplay

Köszönjük, hogy hozzá szeretnél járulni a Nexon Roleplay projekthez! Kérjük, olvasd el figyelmesen ezt az útmutatót, mielőtt elkezdesz dolgozni.

---

## 📌 Alapszabályok

- Minden resource neve kötelezően **`nxn-`** előtaggal kezdődik
- Framework-integráció (ESX, QBCore stb.) **tilos** külön jóváhagyás nélkül
- Minden script **önállóan működő** kell legyen
- A `backdrop-filter` CSS tulajdonság használata **tilos**
- Ikonkönyvtárként kizárólag **[Huge Icons](https://use.hugeicons.com/font/icons.css)** használható
- A [magatartási kódex](./CODE_OF_CONDUCT.md) minden közreműködőre kötelező

---

## 🚀 Első lépések

### Repó klónozása

```bash
git clone https://github.com/FirstVideos-Group/nexonroleplay.git
cd nexonroleplay
```

### Új resource létrehozása

Használd az `nxn-example` boilerplate-et kiindulóként:

```bash
cp -r nxn-example nxn-sajatscript
```

Minden új resourcenak tartalmaznia kell:

| Fájl | Leírás |
|---|---|
| `fxmanifest.lua` | Resource manifest |
| `config.lua` | Konfigurációs fájl |
| `client/main.lua` | Kliens oldali logika |
| `server/main.lua` | Szerver oldali logika |
| `html/index.html` | UI felület (ha szükséges) |
| `docs/index.html` | HTML dokumentáció |

---

## 🎨 Dizájnrendszer

Minden UI elemet a [`design-guide.html`](./design-guide.html) alapján kell elkészíteni. A legfontosabb szabályok:

- Kövesd az egységes színpalettát, tipográfiát és spacing rendszert
- Használj Huge Icons ikonokat, ne más könyvtárat
- A UI legyen **moduláris** — minden komponens illeszkedjen a többihez
- `backdrop-filter` **nem használható** egyetlen CSS fájlban sem

---

## 🔄 Export-kompatibilitás

Minden scriptnek export funkciókat kell biztosítania más resourcek számára. Ellenőrizd, hogy:

- Az új script exportjai nem ütköznek meglévő exportokkal
- Ha módosít egy meglévő resource exportját, az összes érintett scriptet **ugyanabban a PR-ban** frissítsd
- Teszteld az exportokat a kapcsolódó resourcekkal együtt

Export deklarálása (`server/main.lua` vagy `client/main.lua`):

```lua
-- Export példa
exports('getFunctionName', function(param)
    -- logika
    return result
end)
```

Export használata más resourceből:

```lua
local result = exports['nxn-sajatscript']:getFunctionName(param)
```

---

## 🌿 Git munkafolyamat

### Branch elnevezés

```
feature/nxn-<resource>-<rövid-leírás>
fix/nxn-<resource>-<rövid-leírás>
docs/nxn-<resource>-<rövid-leírás>
```

Példák:
```
feature/nxn-inventory-drag-drop
fix/nxn-hud-stamina-display
docs/nxn-notify-export-docs
```

### Commit üzenet konvenció

Használj [Conventional Commits](https://www.conventionalcommits.org/) formátumot:

```
feat(nxn-inventory): add drag and drop support
fix(nxn-hud): fix stamina bar not updating
docs(nxn-notify): add export usage examples
refactor(nxn-engine): simplify event handler logic
chore: update fxmanifest versions
```

### Pull Request folyamat

1. Fork-old vagy branch-elj el a `main`-ből
2. Hozz létre egy új branch-et a fenti elnevezési konvencióval
3. Fejlessz, tesztelj, dokumentálj
4. Győződj meg róla, hogy a kód nem töri meg a meglévő resourceket
5. Nyiss Pull Requestet az alábbi sablon szerint:

```markdown
## Áttekintés
<!-- Mit csinál ez a PR? -->

## Változtatások
- [ ] Új feature
- [ ] Hiba javítás
- [ ] Dokumentáció frissítés
- [ ] Refactor

## Érintett resourcek
<!-- Mely nxn-* resourceket érinti ez a változtatás? -->

## Tesztelés
<!-- Hogyan lett tesztelve? -->

## Kapcsolódó issue
<!-- Closes #xxx -->
```

6. Várj legalább **egy jóváhagyásra** merge előtt

---

## 🐛 Hiba jelentés

Ha hibát találsz, nyiss egy GitHub Issue-t az alábbi információkkal:

- **Érintett resource:** `nxn-xxx`
- **FiveM szerver verzió**
- **Hiba leírása** — mi történt vs. mi kellett volna történni
- **Reprodukálási lépések**
- **Konzol log/hibaüzenet** (ha van)

---

## 💡 Feature javaslat

Feature javaslat esetén nyiss egy GitHub Issue-t a következőkkel:

- A javasolt funkció részletes leírása
- Melyik resource-t érinti vagy új resourcera van szükség?
- Hogyan illeszkedik a projekt architektúrájába?
- Esetleges export API javaslat

---

## 📄 Dokumentáció

Minden új vagy módosított resource esetén frissíteni kell a `docs/index.html` fájlt. A dokumentációnak tartalmaznia kell:

- A resource rövid leírása és célja
- Konfigurációs beállítások (`config.lua` paraméterek)
- Elérhető exportok példakóddarabokkal
- Interaktív demonstráció (ha alkalmazható)

A dizájnért használd az `nxn-example/docs/index.html` sablonját.

---

<p align="center">
  <b>Nexon Roleplay</b> · Köszönjük a hozzájárulásodat! 🙏
</p>
