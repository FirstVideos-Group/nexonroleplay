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

- Az új script exportjai nem ütköznek a meglévő exportokkal
- Ha módosítasz egy meglévő resource exportján, az összes érintett scriptet **ugyanabban a PR-ban** frissítsd
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

## 🐛 Issue létrehozása

Mielőtt új issue-t nyitnál, kérjük **keresd meg a meglévő issue-kat**, hogy ne duplikálj már bejelentett hibát vagy javaslatot.

### 🔴 Hiba jelentés (Bug Report)

Ha hibát találsz valamelyik `nxn-*` scriptben, nyiss egy **Bug Report** issue-t. Címezd értelmesén, pl.:

> `[nxn-hud] A stamina sáv nem frissül jármű kilépés után`

Az issue leírásában add meg az alábbiakat:

```markdown
## 🐛 Hiba leírása
<!-- Rövid, értelmes leírás arról, hogy mi a probléma -->

## 📋 Érintett resource
- **Resource neve:** `nxn-xxx`
- **Fájl (ha ismert):** `client/main.lua`

## ✅ Várt viselkedés
<!-- Mi kéne, hogy történjen? -->

## ❌ Jelenlegi viselkedés
<!-- Mi történik helyette? -->

## 🔁 Reprodukálási lépések
1. ...
2. ...
3. ...

## 📸 Képernyőkép / konzol log
<!-- Ha van, illeszd ide a hibaüzenetet vagy képernyőképet -->

## 💻 Környezet
- **FiveM Build:**
- **Szerver artefakt verzió:**
- **Érintett OS:**
```

**Címkék:** használd a `bug` és az érintett resource nevét (pl. `nxn-hud`) címkéként, ha elérhetők.

---

### 🟡 Feature javaslat (Feature Request)

Ha új funkciót szeretnél javasolni, nyiss egy **Feature Request** issue-t. Címe legyen leíró, pl.:

> `[nxn-inventory] Drag & drop támogatott tárgyak között`

Az issue leírásában add meg az alábbiakat:

```markdown
## 💡 Ötlet leírása
<!-- Mit szeretnél, hogy a script tudjon? -->

## 📋 Érintett resource
- **Resource neve:** `nxn-xxx` *(vagy új resource szükséges)*

## 🎯 Probléma / Motiváció
<!-- Miért lenne hasznos ez a funkció? Mit old meg? -->

## 🛠️ Javasolt megvalósítás
<!-- Ha van ötleted a megvalósításról, írd le itt (opcionális) -->

## 🔗 Export API javaslat
<!-- Ha új exportot igényel, add meg a javasolt szignatúrát (opcionális)
exports['nxn-xxx']:functionName(param1, param2) -->

## ⚖️ Alternatívák
<!-- Fontoltál-e más megoldásokat? -->
```

**Címkék:** használd az `enhancement` és az érintett resource nevét címkéként.

---

### 🟢 Új resource javaslat (New Resource)

Ha teljesen új `nxn-*` scriptet javasolsz, nyiss egy **New Resource** issue-t. Címe legyen:

> `[NEW] nxn-mechanic — Szerelői munkakör rendszer`

```markdown
## 📦 Resource neve
`nxn-<név>`

## 📝 Leírás
<!-- Mit csinál ez a script? Mi a fő feladata? -->

## 🔗 Függőségek
<!-- Mely meglévő nxn-* resourcek exportjait használná fel? -->
- `nxn-database` — adatmentéshez
- `nxn-notify` — értesítésekhez

## 📤 Javasolt exportok
<!-- Milyen exportokat biztosítana más scriptek számára?
exports['nxn-xxx']:functionName(param) -->

## 🎨 UI igény
<!-- Van szükség UI-ra? Ha igen, milyen jellegű? (menü, HUD elem, értesítés stb.) -->

## ⚖️ Prioritás / indoklás
<!-- Miért fontos ez a szerver számára? -->
```

**Címkék:** használd a `new resource` és `enhancement` címkéket.

---

### 🟣 Dokumentációs issue

Ha hibás, hiányos vagy elavult dokumentációt találsz:

```markdown
## 📄 Érintett fájl
<!-- pl. `nxn-inventory/docs/index.html` vagy `CONTRIBUTING.md` -->

## ❌ Probléma
<!-- Mi a hibás vagy hiányzó rész? -->

## ✅ Javasolt javítás
<!-- Hogyan kéne kinéznie a helyes verziónak? -->
```

**Címkék:** használd a `documentation` címkét.

---

### ❗ Issue írási tippek

- **Egy issue = egy probléma vagy javaslat** — ne írd össze a különböző dolgokat
- **Magyar nyelven írj** — a projekt magyar nyelvű
- **Legyenek konkrétak** a leírások — kerüld az általános fogalmazást
- **Ne hagyj ki információt** — mindig add meg az érintett resource nevét
- **Kommentelj, ne nyiss új issue-t**, ha már létezik hasonló bejelentés

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
