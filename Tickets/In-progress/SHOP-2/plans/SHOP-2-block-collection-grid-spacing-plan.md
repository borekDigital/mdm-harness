## Block-Plan: collection-grid-spacing

Wenn auf einer Kollektionsseite keine verwandten Kategorien gerendert werden, bekommt das
Produkt-Grid unten mindestens 60 px (ab 768 px) bzw. 40 px (mobil) Innenabstand. Ein höherer
Editor-Wert gewinnt. Die Änderung besteht aus wenigen CSS-Zeilen in `assets/mdm-collection.css`,
ohne Liquid, Template oder JS.

Grundlage: Spec `.claude/specs/themes/mdm/kollektion-abstand-ohne-verwandte-kategorien.md`
(ENTWURF, 15. Oktober 2026). Worktree `themes/.worktrees/mdm-collection-spacing`, Branch
`fix/collection-grid-bottom-spacing` auf origin/main `b3467e8`.

**Hyper-Quelle:** `assets/theme.css:168-171`, `:177-182`, `:202-205` (`.section--padding`)
**mdm-Kopie:** `sections/mdm-main-collection-product-grid.liquid` (existiert, bleibt unverändert),
CSS-Ziel `assets/mdm-collection.css` (existiert)
**Mapping-Stufe:** (b) Override in einer bestehenden mdm-Datei, nur CSS

### Befundlage

| # | Aussage | Label |
|---|---|---|
| B1 | `mdm-collection.css` wird nur von der Grid-Section geladen | ✅ Belegt `sections/mdm-main-collection-product-grid.liquid:1`, einziger Treffer der Suche |
| B2 | `.mdm-collection-grid` sitzt am Section-Root, zusammen mit `section--padding` und Inline-`--section-padding-bottom` | ✅ Belegt `sections/mdm-main-collection-product-grid.liquid:46-48` |
| B3 | Der Wrapper der Grid-Section trägt die Klasse `collection-section` | ✅ Belegt Schema `sections/mdm-main-collection-product-grid.liquid:282`; dass die Klasse am Wrapper landet, ist Plattformverhalten → T0 |
| B4 | Hyper-Padding unten: unter 768 px `var(--section-padding-bottom-mobile, min(4rem, B*0.6))`, von 768 bis 1279 px `max(min(B, 6rem), B*0.75)`, ab 1280 px `B` | ✅ Belegt `assets/theme.css:170`, `:180` (Query `min-width: 768px`, `:177`), `:204` (Query `min-width: 1280px`, `:198`) |
| B5 | Mobil deckelt Hyper bei 4rem, ein höherer Editor-Wert wirkt dort also nie über 40 px | ✅ Belegt `assets/theme.css:170`. `--section-padding-bottom-mobile` setzt nur `sections/spacer.liquid` (Suche) |
| B6 | Die mobile Related-Regel greift unter 767.98 px, die Desktop-Regel ab 768 px. Damit passt die Trennlinie zu Hyper | ✅ Belegt `assets/mdm-section-collection-hero.css:243`, `:258-261`, `:139-142` |
| B7 | `.mdm-related-categories` gibt es nur, wenn `related_count > 0`; die Section-Instanz `banner` hinter dem Grid hat `show_related_categories: true` | ✅ Belegt `sections/mdm-main-collection-banner.liquid:236-238`; `templates/collection.json` und `collection.mdm.json` (Reihenfolge `product-grid` → `banner`) |
| B8 | Die Hero-Instanz oben (`mdm_main_collection_banner_gbjBJD`) hat `show_related_categories: false` | ✅ Belegt in beiden Templates |
| B9 | Beide Templates nutzen das Layout `mdm-theme`. Dort steht `<main id="MainContent">` mit `content_for_layout` direkt darin; die Footer-Gruppe (Vertrauens-Box) folgt außerhalb von `main` | ✅ Belegt `layout/mdm-theme.liquid:135-139` (gleicher Aufbau in `layout/theme.liquid:127-131`) |
| B10 | Shopify legt die Section-Wrapper (`.shopify-section`) als direkte Geschwister unter `main` an | ⚠️ Vermutung (Plattformverhalten), im Testschritt T0 prüfen |
| B11 | Die Filterleiste ist nur ab 1280 px im Fluss, darunter sitzt sie im Drawer | ✅ Belegt `sections/mdm-main-collection-product-grid.liquid:131` (`hidden xl:block`), `assets/theme.css:6190` |
| B12 | Hyper selbst verwendet `:has()` (39 Stellen in theme.css, weitere in mdm-CSS) | ✅ Belegt (Suche) |

### Änderungen

1. **Mindest-Padding unten am Grid, wenn hinter dem Grid keine verwandten Kategorien folgen.** Das ist die einzige Änderung.
   - Datei: `assets/mdm-collection.css`, ein neuer Block direkt hinter dem Scope-Block
     `.mdm-collection-grid { --mdm-radius … }` (`:395-398`), mit einem einzeiligen Kommentar zum Zweck.
   - Selektor (Empfehlung):
     `.collection-section:not(:has(~ .shopify-section .mdm-related-categories)) > .mdm-collection-grid`
     Er greift nur, wenn **nach** der Grid-Section keine Chips folgen, und ist an den eigenen Section-Wrapper
     gebunden (vgl. SKILL-Regel 3, „block-lokales CSS über Section-Selektor“). Die Spezifität liegt bei (0,4,0) und schlägt
     `.section--padding` mit (0,1,0) sicher.
   - Werte, jeweils als `max()` aus Mindestwert und dem geltenden Hyper-Ausdruck. Damit gewinnt ein höherer
     Editor-Wert (R3):
     - Basis (unter 768 px): `padding-block-end: max(4rem, var(--section-padding-bottom-mobile, min(4rem, var(--section-padding-bottom, 0px) * 0.6)));`
       Das ergibt faktisch immer 4rem (B5). Der volle Ausdruck bleibt trotzdem stehen, damit die Regel bei einem
       Hyper-Update nachvollziehbar mitwandert.
     - `@media (min-width: 768px)`: `max(6rem, max(min(var(--section-padding-bottom, 0px), 6rem), var(--section-padding-bottom, 0px) * 0.75))`
     - `@media (min-width: 1280px)`: `max(6rem, var(--section-padding-bottom, 0px))`
   - Nur `padding-block-end`, `padding-block-start` bleibt unberührt.
   - Begründung: Die Grid-Section kann per Liquid nicht wissen, ob die Banner-Section Chips rendert. Die Chips
     kommen aus einem Metafeld **oder** aus dem Menü-Setting der Banner-Section (`mdm-main-collection-banner.liquid:195-196`),
     und Section-Settings sind in einer anderen Section nicht lesbar ✅. Eine Liquid-Lösung müsste diese Logik
     verdoppeln, deshalb wird sie verworfen.
   - Validierung: T1 bis T5 unten.

**Variante V2, Konrads Vorschlag:** `main:not(:has(.mdm-related-categories)) .mdm-collection-grid`.
Die Spezifität ist (0,2,1) und reicht aus. Bei den heutigen Templates verhält sie sich gleich (B7, B8). Der Unterschied
zeigt sich erst, wenn jemand im Editor die Chips an der Hero-Instanz **oben** einschaltet: Dann sieht V2 die Chips
auf der Seite und lässt das Grid ohne Abstand, obwohl darunter nichts mehr folgt. Das wäre dann der heutige Zustand,
also keine Regression. V1 deckt diesen Fall ab, hängt aber an B10. Wenn T0 B10 widerlegt, wird V2 umgesetzt.

**Verworfen: Alternative B (Template-Setting `padding_bottom` 0 → 60, dazu Related `padding-top: 0`).**
- Sie ändert `templates/collection.json` und `collection.mdm.json`. Das verletzt A6 und die Constraint-Regel. Beide Dateien schreibt
  auch der shopify[bot], Konflikte sind damit absehbar (✅ Belegt im Spec-Kapitel „Nicht Teil“, `b639091`).
- Mobil liefert Hyper mit 60 nur `min(40, 36)` = 36 px statt 40 (R1 verfehlt, B4). Mit Chips würde
  es Grid 36 + Related 0 = 36 px statt heute 32 px (R2 verfehlt).
- Mit Chips verdoppelt sich der Abstand auf Desktop (60 + 60), wenn die Related-Regel nicht gleichzeitig angepasst
  wird. Das wären also zwei Dateien und mehr Risiko.

**Browser-Support `:has()`:** Unterstützt in Safari ab 15.4, Chrome/Edge ab 105 und Firefox ab 121
(⚠️ Vermutung aus Stand-Wissen, nicht im Repo belegt). `:has()` innerhalb von `:not()` ist gültig; nur
verschachteltes `:has(:has())` ist verboten. Ohne Unterstützung verwirft der Browser die ganze Regel. Es bleibt dann
der heutige Zustand mit 0 px, also eine Degradation ohne Regression. Das Theme verlässt sich ohnehin schon auf `:has()` (B12).

### Übersetzungs-Keys

Keine. Es gibt keine neuen Texte und kein neues Schema-Setting.

### Abgrenzung

- Kein Diff an `templates/*.json`, `sections/*-group.json`, Liquid oder JS (A6, A9).
- Die leere Instanz `mdm_bottom_sections_r4WkDz` wird im Theme-Editor aufgeräumt, nicht hier.
- Die Abstände der Nexvo-Kollektions-Templates (`collection.banner-*.json`), der Suche und der Startseite bleiben unberührt: Sie laden
  `mdm-collection.css` nicht (B1).
- Die Related-Regel in `mdm-section-collection-hero.css` bleibt unverändert (R2).
- Borek/IMM: kein Port in diesem PR. In Phase 3 mit `bin/theme-sync.sh drift assets/mdm-collection.css` prüfen.
  Laut Spec gibt es die Related-Section dort nicht in dieser Form; ⚠️ Vermutung: kein Port nötig.

### Testschritte (Dev-Server `http://127.0.0.1:9293`, dieser Worktree)

Messung per Konsole auf Dokument-Koordinaten (`getBoundingClientRect().top/bottom + scrollY`), Toleranz 1 px:
- Inhalt unten: `.mdm-collection-grid .collection__content` (Flex-Container, umfasst Grid, Paginierung und Filterleiste)
- Paginierung: `.mdm-collection-grid .pagination` (nur bei `paginate.pages > 1`, `:268-271`)
- Filterleiste: `#FacetFiltersContainer` (nur ab 1280 px sichtbar, B11)
- Vertrauens-Box: `[id$="__mdm_multicolumn_icon_trust"]` (Footer-Gruppe, `sections/footer-group.json:14`)
- Verwandte Kategorien: `.mdm-related-categories` bzw. `.mdm-related-categories__title`

| Schritt | Akzeptanz | Vorgehen | Erwartung |
|---|---|---|---|
| T0 | (B10) | `document.querySelector('.collection-section').parentElement.id === 'MainContent'` und `nextElementSibling.classList.contains('shopify-section')` | beide `true`, sonst V2 |
| T1 | A1 | `/collections/deutschland-muenzen-euro-goldmuenzen`, 1440 und 375 px | Paginierung unten → Box oben = 60 bzw. 40 px |
| T1b | R1 Tablet | dieselbe Seite bei 1024 px | 60 px (Bereich 768 bis 1279 px) |
| T2 | A2 | Seite aus T1 bei 1440 px. In `#FacetFiltersContainer` einen Filterwert suchen, dessen `.count` ≤ 4 ist (die Spans sind im DOM, aber per `.count { display:none }` ausgeblendet, `assets/mdm-collection.css:5-7`; Markup in `snippets/facets.liquid`, Zählung um Zeile 162 und 197). Parametername und Wert stehen in `name`/`value` des zugehörigen Inputs; daraus entsteht `?<name>=<value>` | Filterleiste reicht tiefer als das Grid; `.collection__content` unten → Box ≥ 60 px. Bei 375 px entfällt der Fall, weil die Filterleiste dann im Drawer liegt (B11) |
| T3 | A3, R2 | `/collections/deutschland-muenzen`, 1440 und 375 px | 60/60 bzw. 32/40 px wie in der Spec-Tabelle, 12 Chips |
| T4 | A4, R4 | T1 und T3 mit `?view=mdm` | gleiche Werte |
| T5 | A5, R3 | `templates/collection.json` → `product-grid.settings.padding_bottom` lokal auf 80 setzen, Hot-Reload abwarten, T1 messen. Danach `git checkout -- templates/collection.json` | 80 px bei 1440 px; 40 px bei 375 px (Hyper-Deckel B5); 60 px bei 1024 px (`max(min(80,60), 60)`) |
| T6 | A6 | `git diff --name-only origin/main -- templates sections/*-group.json` | leer |
| T7 | A7 | `shopify theme check --fail-level error` im Worktree, Vergleich mit einem Lauf auf `b3467e8` (Kontrolltest auf demselben Commit) | keine neuen Findings |
| T8 | A8 | `validate_theme` für die geänderten Dateien | ohne Fehler. ❌ Unbekannt: ob `validate_theme` reine CSS-Assets überhaupt prüft. Falls nicht, im Ergebnis vermerken |
| T9 | A9 | Diff durchsehen | keine Farbwerte, keine Texte, kein JS; nur `padding-block-end` in rem bzw. über `var()` |
| T10 | Blast-Radius | `/search?q=gold` und eine Seite mit `collection.banner-*`-Template, sofern vorhanden | unverändert |

### Definition of Done

- [ ] T0 bis T10 erfüllt, Messwerte ins Complete-Artefakt
- [ ] theme check clean (geänderte Datei), keine neuen Findings gegenüber `b3467e8`
- [ ] Keine Übersetzungen nötig (bestätigt)
- [ ] Kein Editor-Preset nötig (keine neue Section)
- [ ] Sichtprüfung 1440, 1024 und 375 px: der Abstand ohne Chips sieht aus wie der Abstand Chips → Vertrauens-Box
- [ ] Spec-Status von ENTWURF auf FREIGEGEBEN, vor der Implementierung durch Konrad

### Offene Punkte

- O1 Selektor-Variante V1 (Geschwister, Empfehlung) oder V2 (`main`): Entscheidung Konrad. Wenn T0 scheitert, gilt V2.
- O2 ❌ Unbekannt: welche Filter in Search & Discovery für `deutschland-muenzen-euro-goldmuenzen` aktiv sind und
  ob ein Wert mit ≤ 4 Treffern existiert. Das Verfahren aus T2 findet ihn zur Laufzeit. Fehlt ein solcher Wert, bleibt A2
  am Live-Bestand nicht prüfbar; Ersatz wäre `?page=<letzte Seite>`, falls dort ≤ 4 Produkte stehen (`products_per_page: 12`,
  `templates/collection.json:110`).
- O3 ⚠️ Vermutung (aus der Spec übernommen): Kerstins Screenshot zeigt denselben Fall.
