# 📜 Magatartási Kódex — Nexon Roleplay

## Bevezetés

A Nexon Roleplay projekt fejlesztői közösségének célja egy **tiszteletteljes, inkluzív és professzionális** környezet fenntartása. Ez a dokumentum meghatározza az elvárt magatartási normákat mindenki számára, aki a projekthez hozzájárul, fejleszt, kérdez vagy visszajelzést ad.

---

## ✅ Elvárt magatartás

Minden résztvevőtől elvárjuk, hogy:

- **Legyen tiszteletteljes** — Kezelje udvariasan a többi fejlesztőt és közreműködőt, tekintet nélkül tapasztalati szintre, háttérre vagy szerepre
- **Adjon konstruktív visszajelzést** — Kritikát kizárólag a kód vagy a megoldás ellen irányozzon, soha ne a személy ellen
- **Legyen nyitott** — Fogadja el mások ötleteit és javaslatait, még akkor is, ha azok eltérnek a sajátjától
- **Dokumentáljon gondosan** — Minden hozzájárulás esetén tartsa be a projekt dokumentációs és kódolási szabványait
- **Tartsa be az architektúrát** — Új resourcek kizárólag az `nxn-example` boilerplate alapján, az egységes dizájnrendszer szerint készülhetnek
- **Kommunikáljon proaktívan** — Ha elakad vagy kérdése van, jelezze mielőbb a csapatnak

---

## 🚫 Tiltott magatartás

A következők **semmilyen körülmények között** nem megengedettek:

- Sértő, bántó vagy lekezelő kommunikáció
- Személyes támadások, zaklatás, vagy diszkrimináció bármilyen formája
- Más fejlesztők munkájának engedély nélküli módosítása vagy törlése
- Framework-integráció bevezetése külön jóváhagyás nélkül
- A projekt kódjának, scriptjeinek jogosulatlan terjesztése vagy felhasználása harmadik fél számára
- Szándékos hibák, backdoorok vagy kártékony kód bevitele a repóba

---

## 🛠️ Hozzájárulási szabályok

### Kódminőség
- Minden script neve kötelezően az `nxn-` előtaggal kezdődik
- Minden resourcehoz tartoznia kell `config.lua` konfigurációs fájlnak és HTML dokumentációnak
- A UI elemek kötelezően a [design-guide.html](./design-guide.html) dizájnsablonjához igazodnak
- Ikonkönyvtárként kizárólag [Huge Icons](https://use.hugeicons.com/font/icons.css) használható
- `backdrop-filter` CSS tulajdonság használata **tilos**

### Kompatibilitás
- Új script commitálása előtt ellenőrizni kell, hogy az nem töri-e meg a meglévő resourcek exportjait
- Ha egy új resource módosítást igényel egy meglévőn, azt **ugyanabban a commit/PR-ban** kell elvégezni

### Pull Request folyamat
1. Hozz létre egy új branch-et a feature vagy fix számára (`feature/nxn-xxx` vagy `fix/nxn-xxx`)
2. Győződj meg róla, hogy a kód működik és dokumentált
3. Nyiss Pull Requestet részletes leírással
4. Várj legalább egy review-ra merge előtt

---

## ⚖️ Érvényesítés

A magatartási kódex megsértése esetén a projekt karbantartói jogosultak:

- Figyelmeztetést adni
- Hozzájárulást visszautasítani vagy eltávolítani
- A közreműködőt ideiglenesen vagy véglegesen kizárni a projektből

Visszaélések és problémák jelzése a projekt karbantartóinak privát üzenetben lehetséges.

---

## 📌 Hatály

Ez a magatartási kódex érvényes minden olyan helyszínen, ahol a Nexon Roleplay projekt képviselve van: GitHub repó, issue tracker, pull requestek, belső kommunikációs csatornák.

---

<p align="center">
  <b>Nexon Roleplay</b> · Fejlesztői közösség · Közösen, tisztelettel építve
</p>
