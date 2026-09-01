# Design-Spezifikation: MDM-RETOURE-01
## Hilfe-Themenseite „Retoure & Reklamation"

Erstellt: 21. August 2026
Nachextraktion / Erweiterung: 24. August 2026
Figma-Datei: `vnEStNM7qm0qThY39RqiFL`
Root-Node (Figma-Seite): `4030:8` („FAQs")

---

## 1. Überblick

| Eigenschaft | Wert | Evidenz |
|---|---|---|
| Desktop-Frame-Name | `Hilfe · Themenseite (Retoure & Reklamation) · Desktop 1440` | ✅ get_metadata |
| Desktop-Node-ID | `4030:195` | ✅ get_metadata |
| Desktop-Breite | 1440 px | ✅ get_metadata |
| Desktop-Höhe | 1264 px | ✅ get_metadata |
| Mobile-Frame-Name | `Hilfe · Themenseite (Retoure & Reklamation) · Mobile 390` | ✅ get_metadata |
| Mobile-Node-ID | `4030:273` | ✅ get_metadata |
| Mobile-Breite | 390 px | ✅ get_metadata |
| Mobile-Höhe | 1586 px | ✅ get_metadata |
| Canvas-Position Desktop | x=1680, y=100 | ✅ get_metadata |
| Canvas-Position Mobile | x=3220, y=100 | ✅ get_metadata |
| Template-Typ | `page.<slug>.json` (Hilfe-/Service-Landingpage) | ⚠️ Vermutung aus Seitenstruktur |
| Desktop Layout-Breite | Content-Spalte 880 px, beidseitiger Abstand je 280 px | ✅ get_metadata (x=280, width=880) |
| Mobile Layout-Breite | Content-Spalte 350 px, seitlicher Abstand je 20 px | ✅ get_metadata (x=20, width=350) |

Referenz-Screenshots:
- Desktop: `assets-src/reference-4030-195.png` ✅
- Mobile: `assets-src/reference-4030-273.png` ✅ (heruntergeladen 24. August 2026)

---

## 2. Tokens

Alle vier Figma-Variablen stammen aus `get_variable_defs` auf Node `4030:195`.

| Figma-Variablenname | Hex-Wert | Vorgeschlagene CSS Custom Property | Hyper-Äquivalent (figma-mapping.md) |
|---|---|---|---|
| `Stone-80` | `#615b4f` | `--color-stone-80` | ❌ kein Eintrag in mapping.md |
| `Stone-100` | `#3e3a32` | `--color-stone-100` | ❌ kein Eintrag in mapping.md |
| `Prussian` | `#002147` | `--color-prussian` | ❌ kein Eintrag in mapping.md |
| `White` | `#ffffff` | `--color-white` | ⚠️ Entspricht Hyper `--color-background` (Standard weiß), ungelesen |

### Typografie — Desktop

Alle Werte ✅ aus get_design_context (Erstextraktion 21. August 2026, bestätigt 24. August 2026).

| Rolle | Font | Weight | Size | Line-Height | Letter-Spacing | Farbe |
|---|---|---|---|---|---|---|
| Breadcrumbs-Link (1. und 2. Segment) | Inter | SemiBold (600) | 12 px | 1.4 | 1.2 px (tracking) | `Stone-80` (#615b4f) |
| Breadcrumbs letztes Item (aktuelle Seite) | Inter | SemiBold (600) | 12 px | 1.4 | 1.2 px | `Prussian` (#002147) |
| Breadcrumbs — alle Texte | — | — | — | — | uppercase | ✅ |
| H1 Seitentitel | EB Garamond | Medium (500) | 40 px | 1.2 | keiner | `Prussian` (#002147) |
| Akkordeon-Frage (`h2.font-heading.h5`) | EB Garamond | Medium (500) | 18 px | 1.55 | keiner | `Prussian` (#002147) |
| Fließtext Akkordeon-Inhalt (`p`) | Inter | Regular (400) | 16 px | 1.7 | keiner | `Stone-100` (#3e3a32) |
| Inline-Textlink im Fließtext | Inter | Regular (400) | 16 px | 1.7 | keiner | `#002147` + underline |
| Button-Label (primary + secondary) | Inter | Bold (700) | 16 px | 1.4 | keiner | primary: `White`; secondary: `Prussian` |

### Typografie — Mobile (Ergänzung 24. August 2026)

| Rolle | Font | Weight | Size | Line-Height | Letter-Spacing | Farbe |
|---|---|---|---|---|---|---|
| H1 Seitentitel | EB Garamond | Medium (500) | **28 px** | 1.2 | keiner | `Prussian` (#002147) |
| Akkordeon-Frage (`h2.font-heading.h5`) | EB Garamond | Medium (500) | **16 px** | **1.62** | keiner | `Prussian` (#002147) |
| Fließtext Akkordeon-Inhalt (`p`) | Inter | Regular (400) | 16 px | 1.7 | keiner | `Stone-100` (#3e3a32) |
| Inline-Textlink im Fließtext | Inter | Regular (400) | 16 px | 1.7 | keiner | `#002147` + underline |
| Button-Label (primary + secondary) | Inter | Bold (700) | 16 px | 1.4 | keiner | primary: `White`; secondary: `Prussian` |

Hinweis: Breadcrumbs sind im Mobile-Frame **nicht vorhanden** — der Zurück-Bereich (`4030:274`) ist ein leerer Frame. ✅ get_design_context

### Spacing / Layout — Desktop

| Element | Wert | Evidenz |
|---|---|---|
| Seitlicher Padding (Content-Bereich) | 280 px | ✅ get_metadata |
| Zurück-Bereich Höhe | 73 px | ✅ get_metadata |
| Breadcrumbs-Nav y-Position im Zurück-Bereich | 28 px (= padding-top) | ✅ get_metadata |
| Breadcrumbs-Nav gap (zwischen Items) | 12 px | ✅ get_design_context |
| Breadcrumbs-Separator | 1 px breit, 14 px hoch | ✅ get_design_context |
| Breadcrumbs-Separator Farbe (1. Trenner, nach „STARTSEITE") | `Stone-80` (#615b4f) | ✅ get_design_context |
| Breadcrumbs-Separator Farbe (2. Trenner, vor letztem Item) | `Stone-100` (#3e3a32) | ✅ get_design_context |
| Titelbereich Höhe | 84 px | ✅ get_metadata |
| Titelbereich padding-top | 0 px (H1 liegt direkt oben im Frame) | ✅ get_design_context |
| Titelbereich padding-bottom | 36 px | ✅ get_design_context |
| Titelbereich padding-x | 280 px | ✅ get_design_context |
| Akkordeon-summary Höhe (geschlossen) | 60 px (padding-y 16 px + Text 28 px) | ✅ get_design_context |
| Akkordeon-summary padding-y | 16 px | ✅ get_design_context |
| Akkordeon-summary border-bottom | 1 px solid `Stone-100` | ✅ get_design_context |
| Akkordeon-Inhalt padding-top | 16 px | ✅ get_design_context |
| Akkordeon-Inhalt padding-bottom | 16 px | ✅ get_design_context |
| Gap zwischen Inhalt-Absätzen | 16 px | ✅ get_design_context |
| Button-Links padding-top | 8 px | ✅ get_design_context |
| Gap zwischen Buttons | 12 px | ✅ get_design_context |
| Button-Padding seitlich | 24 px | ✅ get_design_context |
| Button-Höhe | 48 px | ✅ get_design_context |
| Buttons Layout Desktop | Zeile (flex-row) | ✅ get_design_context |

### Spacing / Layout — Mobile (Ergänzung 24. August 2026)

| Element | Wert | Evidenz |
|---|---|---|
| Seitlicher Padding (Content-Bereich) | 20 px | ✅ get_metadata (x=20, width=350 in 390 px Frame) |
| Zurück-Bereich Höhe | 84 px (leerer Frame, kein Inhalt) | ✅ get_metadata + get_design_context |
| Breadcrumbs mobil | nicht vorhanden | ✅ get_design_context |
| Titelbereich Höhe | 58 px | ✅ get_metadata |
| Titelbereich padding-top | 0 px | ✅ get_design_context |
| Titelbereich padding-bottom | 24 px | ✅ get_design_context |
| Titelbereich padding-x | 20 px | ✅ get_design_context |
| Akkordeon-summary min-height (einzeilige Frage) | 50 px (padding-y 12 px + Text 26 px) | ✅ get_design_context + get_metadata |
| Akkordeon-summary Höhe (zweizeilige Frage) | 76 px (padding-y 12 px + Text 52 px) | ✅ get_metadata |
| Akkordeon-summary padding-y | **12 px** (vs. 16 px Desktop) | ✅ get_design_context |
| Akkordeon-summary border-bottom | 1 px solid `Stone-100` | ✅ get_design_context |
| Akkordeon-Inhalt padding-top | 16 px | ✅ get_design_context |
| Akkordeon-Inhalt padding-bottom | **8 px** (vs. 16 px Desktop) | ✅ get_design_context |
| Gap zwischen Inhalt-Absätzen | 16 px (identisch Desktop) | ✅ get_design_context |
| Button-Links padding-top | 8 px | ✅ get_design_context |
| Gap zwischen Buttons | 12 px | ✅ get_design_context |
| Buttons Layout mobil | **Spalte (flex-col), full-width** | ✅ get_design_context |
| Button-Breite mobil | 350 px (full-width des Content-Bereichs) | ✅ get_metadata |
| Button-Text-Ausrichtung mobil | zentriert | ✅ get_design_context |
| Button-Höhe | 48 px (identisch Desktop) | ✅ get_design_context |

**Wesentliche Unterschiede Desktop vs. Mobile:**

| Eigenschaft | Desktop | Mobile |
|---|---|---|
| Breadcrumbs | vorhanden, 3 Segmente | nicht vorhanden (leerer Frame) |
| H1-Größe | 40 px | 28 px |
| Akkordeon-Frage-Größe | 18 px | 16 px |
| Akkordeon-Frage line-height | 1.55 | 1.62 |
| Akkordeon-summary padding-y | 16 px | 12 px |
| Akkordeon-Inhalt padding-bottom | 16 px | 8 px |
| Buttons Layout | Zeile, intrinsische Breite | Spalte, full-width |
| Seitlicher Padding | 280 px | 20 px |
| Titelbereich padding-bottom | 36 px | 24 px |

---

## 3. Komponenten

### 3.1 Abschnitt: Zurück-Bereich

#### Desktop (`4030:196`)

**Figma-Layer:** `Zurück-Bereich`
**Entsprechung im Theme:** `sections/mdm-breadcrumbs.liquid` ⚠️

**Struktur:**
```
<nav>                                             <!-- 4030:197 "breadcrumbs (nav)" -->
  <a href="/">STARTSEITE</a>                      <!-- 4030:198, Stone-80 -->
  <span aria-hidden>|</span>                      <!-- 4030:199, 1px × 14px, Stone-80 -->
  <a href="/hilfe">HILFE & SERVICE</a>            <!-- 4030:200, Stone-80 -->
  <span aria-hidden>|</span>                      <!-- 4030:201, 1px × 14px, Stone-100 -->
  <span aria-current="page">RETOURE & REKLAMATION</span>  <!-- 4030:202, Prussian -->
</nav>
```

**Detailmaße:**
- Nav-Container: x=280, y=28 im Frame → padding-top: 28 px ✅
- Nav-Breite: 430 px (intrinsisch) ✅
- gap zwischen Items: 12 px (flex, items-center) ✅
- Alle Texte: uppercase, letter-spacing 1.2 px, Inter SemiBold 12 px ✅
- 1. Separator (nach „STARTSEITE"): `Stone-80` (#615b4f) ✅
- 2. Separator (vor letztem Item): `Stone-100` (#3e3a32) ✅
- 1. und 2. verlinktes Segment: `Stone-80` ✅
- Letztes Item: `Prussian` (#002147) ✅

**Interaktionen:** Hover-Zustand für Links nicht im Design definiert. ⚠️

#### Mobile (`4030:274`)

**Figma-Layer:** `Zurück-Bereich`
- Frame: 390 px breit, 84 px hoch ✅
- Inhalt: **leer** — keine Breadcrumbs, keine Kinder-Nodes ✅ get_design_context
- Verwendungszweck der 84 px unklar: Leerraum, mobiler Zurück-Link oder Platzhalter. ❌

---

### 3.2 Abschnitt: Titelbereich

#### Desktop (`4030:203`)

**Figma-Layer:** `Titelbereich`

```html
<h1>Retoure & Reklamation</h1>  <!-- 4030:204 -->
```

- H1: EB Garamond Medium, 40 px, line-height 1.2, letter-spacing: keiner, `Prussian` ✅
- Frame: full-width 1440 px, Höhe 84 px ✅
- padding: top 0 px / bottom 36 px / x 280 px ✅

#### Mobile (`4030:275`)

```html
<h1>Retoure & Reklamation</h1>  <!-- 4030:276 -->
```

- H1: EB Garamond Medium, **28 px**, line-height 1.2, letter-spacing: keiner, `Prussian` ✅
- Frame: full-width 390 px, Höhe 58 px ✅
- padding: top 0 px / bottom 24 px / x 20 px ✅

---

### 3.3 Abschnitt: FAQ-Liste

#### Desktop (`4030:205`) — Akkordeon-Item geschlossen

```html
<details class="accordion-item">
  <summary class="accordion-item__summary">
    <h2 class="font-heading h5">Frage-Text</h2>
    <span class="icon-plus-toggle" aria-hidden="true"></span>
  </summary>
</details>
```

- summary: Höhe 60 px, padding-y 16 px, border-bottom 1 px solid `Stone-100` ✅
- Layout: flex, justify-between, items-center ✅

**icon-plus-toggle (Plus):**
- Container: 20 × 20 px ✅
- Horizontale Linie: 13.75 × 1.5 px, left 3.13 px, top 9.25 px, border-radius 0.75 px ✅
- Vertikale Linie: 1.5 × 13.75 px, left 9.25 px, top 3.13 px, border-radius 0.75 px ✅
- Farbe: `Stone-100` (#3e3a32) ✅

#### Desktop (`4030:206`) — Akkordeon-Item offen

```html
<details class="accordion-item" open>
  <summary class="accordion-item__summary">
    <h2 class="font-heading h5">Wie funktioniert die Rücksendung?</h2>
    <span class="icon-plus-toggle icon-plus-toggle--open" aria-hidden="true">
      <!-- nur horizontale Linie, keine vertikale -->
    </span>
  </summary>
  <div class="accordion-details__content rte">
    <p>...Text mit <a href="/widerrufsbelehrung">Widerrufsbelehrung</a>.</p>
    <p>...Text...</p>
    <div class="accordion-item__buttons">
      <a href="#" class="btn btn--primary">Jetzt Briefmarke erstellen</a>
      <a href="#" class="btn btn--secondary">Jetzt Paketschein anfragen</a>
    </div>
  </div>
</details>
```

- accordion-details__content: padding-top 16 px, padding-bottom 16 px, gap 16 px ✅
- Inline-Link: underline, `#002147`, text-decoration-skip-ink: none ✅

**Button-Leiste Desktop (`4030:214`):**

| Button | Typ | Text | Breite | BG | Text-Farbe | Border |
|---|---|---|---|---|---|---|
| Primär | `btn--primary` | Jetzt Briefmarke erstellen | 251 px | `Prussian` | `White` | keiner |
| Sekundär | `btn--secondary` | Jetzt Paketschein anfragen | 263 px | `White` | `Prussian` | 1 px solid `Prussian` |

- Layout: Zeile (flex-row), gap 12 px, padding-top 8 px ✅
- Buttons: keine border-radius, Höhe 48 px, padding-x 24 px ✅

#### Mobile (`4030:277`) — Akkordeon-Item geschlossen (Muster: `4030:291`)

- summary: min-height 50 px (einzeilig) / 76 px (zweizeilig), padding-y **12 px**, border-bottom 1 px solid `Stone-100` ✅
- Fragentext: EB Garamond Medium, **16 px**, line-height **1.62**, `Prussian` ✅
- icon-plus-toggle: identisch Desktop (20 × 20 px, gleiche Geometrie) ✅

#### Mobile (`4030:278`) — Akkordeon-Item offen

- summary: identisch geschlossen (min-height 50 px, padding-y 12 px) ✅
- accordion-details__content: padding-top 16 px, padding-bottom **8 px**, gap 16 px ✅

**Button-Leiste Mobile (`4030:286`):**

| Button | Typ | Text | Breite | BG | Text-Farbe | Border |
|---|---|---|---|---|---|---|
| Primär | `btn--primary` | Jetzt Briefmarke erstellen | 350 px (full-width) | `Prussian` | `White` | keiner |
| Sekundär | `btn--secondary` | Jetzt Paketschein anfragen | 350 px (full-width) | `White` | `Prussian` | 1 px solid `Prussian` |

- Layout: **Spalte (flex-col)**, gap 12 px, padding-top 8 px ✅
- Buttons: full-width, Text zentriert, keine border-radius, Höhe 48 px ✅

---

### 3.4 Vollständige Liste aller Akkordeon-Fragen

| # | Desktop Node | Mobile Node | Fragentext | Zustand |
|---|---|---|---|---|
| 1 | `4030:206` | `4030:278` | Wie funktioniert die Rücksendung? | offen (mit Inhalt) |
| 2 | `4030:219` | `4030:291` | In welchem Zustand dürfen Produkte zurückgesendet werden? | geschlossen |
| 3 | `4030:225` | `4030:297` | Können einzelne Produkte aus einer Bestellung zurückgesendet werden? | geschlossen |
| 4 | `4030:231` | `4030:303` | Können mehrere Bestellungen gemeinsam zurückgesendet werden? | geschlossen |
| 5 | `4030:237` | `4030:309` | Ist ein Umtausch möglich? | geschlossen |
| 6 | `4030:243` | `4030:315` | Wie lange dauert die Bearbeitung meiner Rücksendung? | geschlossen |
| 7 | `4030:249` | `4030:321` | Wie erfolgt die Rückerstattung des Kaufpreises? | geschlossen |
| 8 | `4030:255` | `4030:327` | Was ist bei einem beschädigten Produkt zu tun? | geschlossen |
| 9 | `4030:261` | `4030:333` | Was ist zu tun, wenn ein falsches Produkt geliefert wurde? | geschlossen |
| 10 | `4030:267` | `4030:339` | Was ist bei einem fehlenden Produkt zu tun? | geschlossen |

Nur Item 1 zeigt Inhaltstext. Items 2–10 zeigen ausschließlich die Frage. Antwort-Inhalte für Items 2–10 sind im Design nicht definiert. ⚠️

---

## 4. Figma-Mapping-Abgleich

| Figma-Layer/Muster | Treffer in figma-mapping.md | Notiz |
|---|---|---|
| `breadcrumbs (nav)` | ✅ `sections/mdm-breadcrumbs.liquid` | Desktop; mobil nicht vorhanden |
| `accordion-item` / FAQ-Liste | ✅ `sections/mdm-collapsible-tabs.liquid`, `sections/mdm-product-faq.liquid` | Eignung noch zu verifizieren |
| `btn--primary` / `btn--secondary` | ⚠️ Hyper-Button-Klassen | Klassennamen im Theme-CSS ungelesen |
| `h2.font-heading.h5` | ⚠️ Hyper Heading-Utilities | Layer-Name deutet auf Theme-Klassen |
| `accordion-details__content (.rte)` | ⚠️ Hyper `.rte`-Wrapper | Konvention Shopify-üblich |
| `icon-plus-toggle` | ⚠️ kein SVG-Asset — rein CSS-gezeichnet | Kein Download nötig |
| Serifen-Headline (EB Garamond) | ✅ `assets/eb-garamond-variable.ttf` | Font liegt im Theme |
| Fließtext (Inter) | ✅ `assets/inter-variable.ttf` | Font liegt im Theme |

---

## 5. Assets

| Datei | Pfad | Quelle | Verwendung |
|---|---|---|---|
| `reference-4030-195.png` | `assets-src/reference-4030-195.png` | Figma Screenshot (2048 px, 1440×1264 px) | Visuelles Referenz-Bild Desktop |
| `reference-4030-273.png` | `assets-src/reference-4030-273.png` | Figma Screenshot (390×1586 px, 1:1) | Visuelles Referenz-Bild Mobile — heruntergeladen 24. August 2026 |

Keine weiteren Download-Assets: Das Plus/Minus-Icon ist rein via CSS gezeichnet. Keine Bilder oder Vektorgrafiken im Design. ✅

---

## 6. Offene Punkte / Unknowns

### Inhalt
1. **Antwort-Texte für Items 2–10 fehlen vollständig im Figma-Design.** Nur Item 1 hat sichtbaren Inhalt. Entweder Platzhalter für Redaktion oder in anderer Figma-Seite. ⚠️
2. **Button-Ziele (URLs) nicht definiert.** „Jetzt Briefmarke erstellen" und „Jetzt Paketschein anfragen" ohne konkrete URLs. ⚠️
3. **Inline-Link „Widerrufsbelehrung"** — Ziel-URL nicht im Design definiert. ⚠️

### Interaktionen
4. **Akkordeon-Öffnen/Schließen-Animation** — keine Transitions spezifiziert. ⚠️
5. **Mehrfach geöffnete Items** — Accordion-Modus (1 offen) oder Mehrfachöffnung? Nicht definiert. ⚠️
6. **Hover-Zustände** für Akkordeon-Summary, Buttons und Breadcrumb-Links nicht im Design. ⚠️
7. **Focus-Zustände** (Accessibility) nicht im Design. ⚠️

### Layout / Responsiveness
8. ~~**Mobile-Breakpoint fehlt** — Design zeigt ausschließlich Desktop 1440 px. Kein Mobile-Frame vorhanden.~~
   **Korrektur 24. August 2026:** Mobile-Frame existiert. Node `4030:273`, Breite 390 px, vollständig im Figma vorhanden und nun extrahiert. Der ursprüngliche offene Punkt war falsch — der Frame war bei der Erstextraktion (21. August 2026, nur Node `4030:195`) nicht berücksichtigt worden, da nur der Desktop-Frame abgefragt wurde.
9. **Breakpoint-Schwellenwert** (ab welcher Viewport-Breite Mobile-Layout greift) ist im Design nicht definiert. ⚠️
10. **Tablet-Breakpoint** (768–1024 px) — kein Frame vorhanden. ⚠️
11. **Sticky-Verhalten** des Breadcrumb- oder Titelbereichs nicht definiert. ⚠️

### Theme-Integration
12. **Seitentemplate-Typ:** Wahrscheinlich `page.<slug>.json` (z.B. `page.retoure.json`) mit 2–3 Custom Sections. Muss vom Planner entschieden werden. ⚠️
13. **Breadcrumbs-Section** — ob `mdm-breadcrumbs.liquid` Breadcrumb-Daten automatisch aus Shopify-Kontext zieht oder manuell konfiguriert wird, ist nicht aus Figma ableitbar. ❌
14. **Mobiles Zurück-Bereich-Verhalten** — der 84 px hohe leere Frame mobil enthält keinen Figma-Inhalt. Ob hier ein Zurück-Link, eine mobile Breadcrumb-Variante oder schlicht Leerraum gerendert werden soll, muss mit Konrad geklärt werden. ❌
15. **Accordion-Section-Settings** — FAQ-Daten als Schema-Settings (Repeater-Blöcke) oder statischer Liquid-Content: Planungsentscheidung. ⚠️
16. **Token-Mapping zu Hyper-CSS-Variablen:** `Stone-80`, `Stone-100`, `Prussian` sind Figma-eigene Variablen — Entsprechungen in Theme-CSS müssen vom Planner recherchiert werden. ❌
17. **Trennlinie oben im ersten Akkordeon-Item** — ob das erste Item eine `border-top` zur Abgrenzung vom Titelbereich braucht, ist im Design nicht eindeutig. ⚠️
