# Spec: Rich-Text-Inhalte (`.rte`) auf dunklen Farbschemata lesbar

## Ziel

Fließtext, Fettdruck, Links, Listen, Zitate und Tabellen in `.rte`-Containern übernehmen ihre
Farben aus dem Farbschema. Auf dunklen Schemes erfüllen sie WCAG AA. Auf `scheme-1` bleibt
jede berechnete Farbe gleich, außer den in E2 und E3 entschiedenen Werten.

## Grundlage

- Befund F1 aus `rich-text-kontrast-dunkle-schemes.md`
- Baut auf `fix/rich-text-dark-scheme-contrast` auf. Ohne diesen Fix ist auch der Absatz in
  `.rich-text__text` unlesbar.
- Analyse am 13. Oktober 2026 auf origin/main `292d777` plus Fix. Methoden:
  - statische Analyse
  - Laufzeitmessung auf 10 Seiten
  - Simulation aller Elementtypen auf allen 5 Schemes (Dev-Server, Store `mdm-muenze`)

## Korrektur gegenüber der F1-Liste

- ✅ **`h5`/`h6` gehören nicht dazu.** Auf scheme-inverse und scheme-2 macht die
  Überschriften-Regel `brand-overrides.css:658-686` sie weiß (16,05:1 und 9,52:1).
- ✅ **`.rte p` (`:454`) gehört dazu.** In `.rte`-Containern ohne `.rich-text__text` bleibt der
  Absatz hart `#3E3A32`. Bisher stand er unter „weitere harte Werte“.
- ✅ `th`, `code` und `hr` sind auf dunklen Schemes lesbar, weil sie eine eigene Fläche
  haben oder hell sind.

## Kontext: Ist-Stand

### Regeln (`assets/brand-overrides.css`, Block 342-566)

Kontrast heute, gemessen per Simulation mit Fix. Das erste Wertepaar gilt für `.rte`, das
zweite für `.rich-text__text.rte`.

| Element | Zeilen | Wert heute | scheme-inverse | scheme-2 |
|---|---|---|---|---|
| `p` | 448-456 | `#3E3A32` | **1,42** / 9,90 | **1,19** / 6,78 |
| `strong` | 460-463 | `#1E1C17` | **1,06** | **1,79** |
| `a` | 470-476 | `#002147` | **1,00** | **1,69** |
| `a:hover`, `a:focus-visible` | 477-481 | `#2C4767` | **1,68** | **1,00** |
| `ul`, `ol`, `li` | 484-491 | `#3E3A32` | **1,42** | **1,19** |
| `li::marker` | 497-499 | `#867E6F` | 3,99 | **2,37** |
| `blockquote` Text | 510 | `#3E3A32` | **1,42** | **1,19** |
| `blockquote` Rahmen | 503 | `#002147` | **1,00** | **1,69** |
| `td` Text | 550 | `#3E3A32` | **1,42** | **1,19** |
| `td` Rahmen | 548 | `#D6CAB3` | 9,90 | 5,87 |
| `th` | 535-545 | `#FFFFFF` auf `#002147` | 16,05, Fläche verschmilzt mit Hintergrund | 16,05 |
| `code` | 558-565 | `#002147` auf `#F6F3EE` | 14,50 | 14,50 |
| `hr` | 514-518 | `#D6CAB3` | 9,90 | 5,87 |
| `h1`-`h6` | 362-421 | — | weiß | weiß |

Fett: unter 4,5:1 bei Text, unter 3:1 bei Rahmen und Markern.
`em` erbt (`:466`), `b` ist nicht gestylt.

### Theme-Variablen mit identischem scheme-1-Wert

Die Werte wurden zur Laufzeit gemessen.

| heute | Variable | scheme-1-Wert |
|---|---|---|
| `#3E3A32` | `--color-subtext` | `62,58,50` |
| `#1E1C17` | `--color-foreground` | `30,28,23` |
| `#002147` | `--color-primary` und `--color-button` | `0,33,71` |
| `#FFFFFF` (th) | `--color-button-text` | `255,255,255` |
| `#F6F3EE` (code) | `--color-secondary-background` | `246,243,238` |
| `#D6CAB3` (td, hr) | `--color-border` | `214,202,179` |
| `#2C4767` (Hover) | keine. 80 % Primary in Hintergrund ergäbe `#334D6C` | — |
| `#867E6F` (Marker) | keine. `--color-foreground-lighten-60` ist `#787774` | — |

## Blast Radius

### Statisch

- ✅ 136 `.rte`-Fundstellen in 91 Liquid-Dateien. Dazu gehören unter anderem:
  - Seiten-, Artikel-, Produkt- und Kollektionsbeschreibungen
  - Akkordeons und Tabs
  - Footer, Topbar und Ankündigungsleiste
  - Warenkorb-Drawer
  - alle Rich-Text-Blöcke
- ✅ Wirksam auf 76 von 79 Templates (Layout `mdm-theme`).
- ✅ `/pages/hilfe_bestellwiderruf` nutzt `page.Forms - Hilfeservice` mit Layout `theme`. Dort
  lädt `brand-overrides.css` nicht (Laufzeit: `brand=false`).

### Laufzeit (`292d777` plus Fix, 1440 px)

Gemessen auf `/`, `/collections`, `/collections/deutschland-muenzen`, Produkt, `/pages/hilfe`,
`/pages/uber-mdm`, `/pages/faq_retoure`, `/blogs/news`, `/search?q=euro` und `/cart`.

- ✅ Auf dunklem Grund stehen nur zwei `.rte`-Inhalte, beide reine `<p>` in `.rich-text__text`:
  - die Trust-Section, seit PR #41 im Footer auf jeder Seite (9,90:1)
  - der Promo-Banner auf `/collections` (6,78:1)
- ✅ Kein `strong`, `a`, keine Liste, kein Zitat und keine Tabelle steht heute auf
  dunklem Grund. F1 ist vorbeugend.
- ✅ Auf scheme-1 stehen 10 Listenpunkte im Rich Text der Startseite (Marker `#867E6F`, 4,02:1).
  Sie wären von E3 betroffen.

### Latente Stellen

- ✅ Footer-Block „Wir versenden mit“ (`footer-group.json`, Block `image_text_GJnz8p`,
  scheme-inverse) hat heute leeren Text. Wer dort Text einträgt, erzeugt auf jeder Seite
  `.footer-image-box__text.rte` mit Absatz auf 1,42:1.
- ✅ Jeder Link und jeder Fettdruck, den jemand im Editor in einen Trust-Text setzt, landet
  auf 1,00:1 bzw. 1,06:1.
- ⚠️ Mega-Menü-Promos (scheme-inverse) und Demo-Templates rendern heute keine `.rte`-Inhalte
  auf dunklem Grund.

## Zielwerte

Abgeleitet aus den Scheme-Variablen.

| Element | Variable | scheme-1 | scheme-inverse | scheme-2 | scheme-info | scheme-3 |
|---|---|---|---|---|---|---|
| `p`, Listen, Zitattext, `td` | Subtext | `#3E3A32` 11,31 | `#D6CAB3` 9,90 | `#EDD8A4` 6,78 | `#615B4F` 6,09 | `#3E3A32` 6,98 |
| `strong` | Text | `#1E1C17` 17,02 | `#F6F3EE` 14,50 | `#FFFFFF` 9,52 | `#3E3A32` 10,22 | `#3E3A32` 6,98 |
| `a`, Zitat-Rahmen | Primary | `#002147` 16,05 | `#EDD8A4` 11,43 | `#FFFFFF` 9,52 | `#002147` 14,50 | `#002147` 9,90 |
| `th` | Button / Button-Text | `#FFF` auf `#002147` 16,05 | `#002147` auf `#F6F3EE` 14,50 | `#82212E` auf `#FFF` 9,52 | wie scheme-1 | wie scheme-1 |
| `code` | Primary auf Sekundär-Hintergrund | 14,50 | 12,42 | 13,34 | 16,05 | 14,50 |
| `td`-Rahmen, `hr` | Border | `#D6CAB3` | `#867E6F` 3,99 | `#EDD8A4` 6,78 | `#D6CAB3` | `#ADA390` |

## Entscheidungen

### E1: Verschiebungen auf scheme-info und scheme-3

Mit den Variablen ändern sich auch helle Nicht-Standard-Schemes. Alle Werte bleiben über AA.

| Element | scheme-info | scheme-3 |
|---|---|---|
| `p` (nur `.rte`), Listen, Zitat, `td` | `#3E3A32` → `#615B4F` (10,22 → 6,09) | gleich |
| `strong` | `#1E1C17` → `#3E3A32` (15,38 → 10,22) | `#1E1C17` → `#3E3A32` (10,50 → 6,98) |
| `code`-Fläche | `#F6F3EE` → `#FFFFFF` | gleich |
| `td`-Rahmen, `hr` | gleich | `#D6CAB3` → `#ADA390` |

✅ Live betrifft das heute kein Element. Der Newsletter auf scheme-info enthält nur `p`
(schon `#615B4F`) und `a` (bleibt `#002147`).

**Empfehlung: annehmen.** Das ist dasselbe Prinzip wie Variante A der Vorgänger-Spec.

**Entschieden am 13. Oktober 2026 durch Konrad: angenommen.**

### E2: Hover- und Fokusfarbe der Links (heute `#2C4767`)

| | A: wie Link | B: Mischung 80 % Primary, 20 % Hintergrund (**empfohlen**) | C: `#2C4767` behalten |
|---|---|---|---|
| scheme-1 | `#002147`. Hover nur über dickere Unterstreichung, die es schon gibt | `#334D6C`, 8,68:1 (heute 9,53) | unverändert |
| dunkle Schemes | 11,43 / 9,52 | 7,68 / 6,64 | braucht Scheme-IDs im Selektor |
| Mindestwert | 9,52 | 6,28 (scheme-3) | — |

B erhält den sichtbaren Farbwechsel beim Hover. Die Abweichung auf scheme-1 ist gering.
`color-mix()` mit Theme-Variablen enthält kein Farbliteral.

**Entschieden am 13. Oktober 2026 durch Konrad: Variante B.**

### E3: Listenpunkte (heute `#867E6F`)

| | A: Farbe des Listentexts (**empfohlen**) | B: Mischung 60 % Text, 40 % Hintergrund |
|---|---|---|
| scheme-1 | `#3E3A32` statt `#867E6F`. Kräftigere Punkte, 10 Stück live auf `/` | `#8B8984`, nah an heute |
| Mindestwert | 6,09:1 | **2,59:1 auf scheme-info**, 2,86:1 auf scheme-3 |

B erfüllt 3:1 nicht überall.

**Entschieden am 13. Oktober 2026 durch Konrad: Variante A.**

## Anforderungen

- [ ] R1 In `.rte`-Inhalten haben Absatz, Listen, Zitattext und Tabellenzellen die Subtext-Farbe
      des nächstgelegenen Schemes.
- [ ] R2 Fettdruck (`strong`) hat die Textfarbe des Schemes.
- [ ] R3 Links und der Zitat-Rahmen haben die Primary-Farbe des Schemes. Hover und Fokus sind eine
      Mischung aus 80 % Primary und 20 % Hintergrund des Schemes (E2: B).
- [ ] R4 Der Tabellenkopf nutzt die Button-Farben des Schemes. Zellrahmen und `hr` nutzen die
      Rahmenfarbe. Code nutzt Primary auf Sekundär-Hintergrund.
- [ ] R5 Listenpunkte haben die Farbe ihres Listentexts (E3: A).
- [ ] R6 Auf scheme-1 bleibt jede berechnete Farbe gleich, ausgenommen Hover und Fokus (E2)
      und Listenpunkte (E3).
- [ ] R7 Auf scheme-inverse und scheme-2 haben Text-Elemente mindestens 4,5:1. Rahmen und
      Marker haben mindestens 3:1.
- [ ] R8 Überschriften in `.rte` bleiben auf allen Schemes unverändert.
- [ ] R9 Schrift, Abstände und Unterstreichung bleiben unverändert.
- [ ] R10 Geänderte Deklarationen enthalten kein Farbliteral. Die Farben werden am Element
      aufgelöst.
- [ ] R11 Die Kommentare im Block beschreiben das neue Verhalten, also keine „Prussian“- oder
      „Stone-…“-Angaben als festen Wert.

## Akzeptanzkriterien

### Messverfahren

Dev-Server (Store `mdm-muenze`, Port 9292), vorher und nachher auf demselben Dev-Theme.

- **Simulation:** Ein Testfragment mit `p`, `strong`, `a`, `ul`, `ol`, `blockquote`, Tabelle,
  `code`, `hr` und `h2`-`h6` wird in je einen `.rte`- und einen `.rich-text__text.rte`-Container
  auf allen 5 Schemes eingefügt (1440 px). Erfasst werden Farbe, Fläche und Kontrast.
- **Live:** Alle `.rte`-Elemente und ihre Kinder auf den 10 Seiten der Laufzeitmessung,
  bei 1440 und 375 px.
- **Hover und Fokus:** echter Maus-Hover und Tastaturfokus auf einen Link, dann
  `getComputedStyle`.

| AC | Kriterium | Req |
|---|---|---|
| A1 | Simulation scheme-inverse und scheme-2, beide Container: `p`, `strong`, `a`, `li`, Zitat, `td` mindestens 4,5:1; Marker, Zitat-Rahmen, `td`-Rahmen und `hr` mindestens 3:1. Werte wie in der Tabelle Zielwerte. | R1-R5, R7 |
| A2 | Simulation scheme-1: alle Werte vorher = nachher, außer Hover/Fokus und Marker mit den Werten aus E2/E3 | R6 |
| A3 | Simulation scheme-info und scheme-3: Werte wie in der E1-Tabelle; Text mindestens 4,5:1, Marker mindestens 3:1 | R1, R2, R5 |
| A4 | Simulation, alle Schemes: `h2`-`h6` vorher = nachher | R8 |
| A5 | Live, alle 10 Seiten, 1440 und 375 px: alle Farben vorher = nachher, außer den 10 Listenpunkten auf `/` (`#867E6F` → `#3E3A32`) | R6 |
| A6 | Hover und Fokus auf einen Link im Rich Text der Startseite (scheme-1) und auf einen Link im Simulations-Container (scheme-inverse, scheme-2): scheme-1 `#334D6C`, scheme-inverse `#BEB391`, scheme-2 `#E6D3D5`, jeweils mindestens 4,5:1 | R3, R7 |
| A7 | Schriftfamilie, -gewicht, -größe, Zeilenhöhe, Abstände und Unterstreichung aller gemessenen Elemente vorher = nachher | R9 |
| A8 | Diff gegen origin/main ändert nur `assets/brand-overrides.css` im Block 342-566. Hinzugefügte Deklarationen enthalten kein Farbliteral (Kommentare ausgenommen). | R10 |
| A9 | Review: Kommentare und Regeln stimmen überein | R11 |
| A10 | `shopify theme check --output json` in sauberen Worktrees, main gegen Branch: Findings identisch. Den Ausgangswert auf dem dann aktuellen main neu bestimmen (auf `dc86009` waren es 37/22). | — |
| A11 | `validate_theme` für `assets/brand-overrides.css` gültig | — |
| A12 | theme-reviewer und security-reviewer: APPROVED | — |

## Constraints

- **Reihenfolge:** Erst `fix/rich-text-dark-scheme-contrast` mergen, dann diesen Branch von
  origin/main abzweigen.
  - ✅ Dringend: PR #41 hat die Trust-Section am 13. Oktober 2026 auf alle Seiten gebracht.
    Ohne den Fix steht ihr Text live mit 1,42:1.
- Nur `assets/brand-overrides.css`. Keine Nexvo-Datei, kein Liquid, kein `settings_data.json`.
- Keine hartcodierten Farben (`liquid-conventions.md`). Die `--mdm-color-*`-Tokens
  (`:1151-1161`) eignen sich nicht, weil sie auf `:root` gebunden sind.
- `color-mix()` mit Theme-Variablen ist zulässig. ✅ Im Dev-Browser unterstützt
  (`CSS.supports` = true).
- Blast Radius: shopweit, 76 Templates. Nach dem Merge sofort live.
- Ein PR, ein Thema: Branch von origin/main, PR gegen main.
- Nur MDM-Theme.
- ✅ Borek und IMM haben auf ihrem lokalen origin/main-Stand keine `.rte`-Regeln in
  `brand-overrides.css`.

## Nicht Teil dieser Spec

- Globale Überschriften-Farben (`brand-overrides.css:653-686`, hart `#002147`/`#FFFFFF`)
- `.page__content.rich-text__text.rte h1`-`h6` (`:364-445`)
- **F2:** `h5`/`h6` `#615B4F` auf scheme-3 mit 4,16:1, also unter AA. scheme-3 steht in
  `cart.json`, `page.about.json`, `collection.banner-without-image.json` und
  `customers/addresses.json`.
- `hr` und `td`-Rahmen auf hellen Schemes. Das sind dekorative Haarlinien, auf scheme-1
  1,62:1, so gewollt laut Brand-Doc.
- Seiten mit Layout `theme`, zum Beispiel `/pages/hilfe_bestellwiderruf`, die
  `brand-overrides.css` nicht laden
- Harte Farben außerhalb des `.rte`-Blocks (PLP, Filter, Breadcrumbs)

## Offene Punkte

- ~~O1 Entscheidung E1~~ — erledigt, angenommen
- ~~O2 Entscheidung E2~~ — erledigt, Variante B
- ~~O3 Entscheidung E3~~ — erledigt, Variante A
- O4 Voraussetzung: `fix/rich-text-dark-scheme-contrast` ist noch nicht committet
  (Stand 13. Oktober 2026, origin/main `d40ba64`). Die Umsetzung beginnt nach dem Merge.

## Status

FREIGEGEBEN — 13. Oktober 2026 (E1 angenommen, E2 B, E3 A)
