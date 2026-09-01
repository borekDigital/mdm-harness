## Plan: Hilfe-Themenseite Retoure & Reklamation

Erstellt am: 21. August 2026

Ein neues Page-Template `page.retoure.json` liefert die Hilfe-Themenseite "Retoure & Reklamation" als Sections-basierte Seite. Die Seite besteht aus drei Sektionen: erweiterte Breadcrumbs (3 Ebenen), Seitentitel (H1) und FAQ-Akkordeon (10 Items mit Editor-Blöcken). Zentrale Entscheidung: `mdm-collapsible-tabs` wird wiederverwendet -- kein Neubau der Akkordeon-Logik. Breadcrumbs benötigen eine Erweiterung für mehrstufige Navigationspfade. Farbwerte werden als hardcodierte Hex-Werte im mdm-CSS eingesetzt (etabliertes Pattern, kein Hyper-Token vorhanden).

**Phasen:** 5

---

### 1. Phase 1: Breadcrumbs-Erweiterung fuer mehrstufige Seitenpfade

- **Ziel:** Die bestehende `sections/mdm-breadcrumbs.liquid` so erweitern, dass Page-Templates einen optionalen Eltern-Link konfigurieren koennen (z.B. "Hilfe & Service" zwischen "Startseite" und dem aktuellen Seitentitel). Das Design zeigt drei Ebenen: STARTSEITE | HILFE & SERVICE | RETOURE & REKLAMATION.

- **Analyse / Reuse-Entscheidung:**
  - `sections/mdm-breadcrumbs.liquid` (Zeile 67-69) rendert bei `template contains 'page'` nur zwei Ebenen: Home-Link + `page.title`. Das ist fuer das Design unzureichend. Die Section muss erweitert werden. ✅ Belegt: `sections/mdm-breadcrumbs.liquid:67-69`
  - `sections/breadcrumbs.liquid` (Original, Zeile 15-17) zeigt dasselbe Zwei-Ebenen-Pattern. ✅ Belegt: `sections/breadcrumbs.liquid:15-17`
  - Die mdm-Breadcrumbs-Section hat bereits ein Schema mit `container`, `text_alignment`, `padding_top/bottom`. ✅ Belegt: `sections/mdm-breadcrumbs.liquid:135-206`
  - CSS liegt in `assets/mdm-section-breadcrumbs.css` -- Separator-SVG wird inline gerendert (Zeile 52-56). ✅ Belegt: `sections/mdm-breadcrumbs.liquid:52-56`
  - Farbwerte im Design (Stone-80 `#615b4f`, Stone-100 `#3e3a32`, Prussian `#002147`) stimmen mit den bestehenden Breadcrumbs-CSS-Werten ueberein (`#6a6357` fuer Links, `#002147` fuer `.breadcrumbs--last`). Die Link-Farbe weicht leicht ab (`#6a6357` vs. `#615b4f`). ✅ Belegt: `sections/mdm-breadcrumbs.liquid:18,37`
  - Design zeigt Pipe-Separator (`|`), aktuell nutzt die mdm-Section ein SVG-Chevron. ✅ Belegt: `sections/mdm-breadcrumbs.liquid:53-55` vs. Design-Spec Abschnitt 3.1

- **Dateien:**
  - AENDERN: `sections/mdm-breadcrumbs.liquid` -- Zwei neue optionale Schema-Settings hinzufuegen: `parent_label` (Text) und `parent_url` (URL). Im `page`-Branch (Zeile 67-69) vor dem letzten Breadcrumb-Item ein optionales Eltern-Segment einfuegen, wenn `parent_url` gesetzt ist. Begruendung: Reuse der bestehenden mdm-Section, minimaler Eingriff, rueckwaertskompatibel (leere Settings = unveraendertes Verhalten).
  - AENDERN: `assets/mdm-section-breadcrumbs.css` -- Link-Farbe von `#6a6357` auf `#615b4f` korrigieren (Figma-Token Stone-80). Separator-Darstellung pruefen: falls Pipe statt SVG gewuenscht, ueber ein neues Setting `separator_style` (pipe/chevron) steuern oder per Retoure-Template-JSON-Settings uebersteuern.

- **Validierung:** `shopify theme check` auf `sections/mdm-breadcrumbs.liquid` und `assets/mdm-section-breadcrumbs.css`. Visueller Vergleich: Breadcrumbs zeigen drei Ebenen mit korrekten Farben und Separatoren.

- **Schritte:**
  1. Schema der mdm-Breadcrumbs-Section um `parent_label` (type: text, optional) und `parent_url` (type: url, optional) erweitern.
  2. Im Liquid-Template den `page`-Branch anpassen: Wenn `parent_url` belegt, Separator + verlinkten `parent_label` zwischen Home und `page.title` einfuegen.
  3. CSS-Farbwert `#6a6357` nach `#615b4f` aendern (Stone-80-Angleichung).
  4. Separator: Das Design zeigt einen vertikalen Strich (Pipe, 1px breit, 14px hoch). Pruefen, ob dies ueber CSS auf dem bestehenden SVG-Separator oder als alternatives Element umgesetzt wird. Empfehlung: Im Retoure-Template den Separator per `custom_css` im JSON uebersteuern oder ein Setting `separator_style` einfuegen.
  5. Uebersetzungs-Keys fuer die neuen Settings in `en.default.schema.json` und `de.schema.json` anlegen.

---

### 2. Phase 2: Seitentitel-Section (mdm-page-title)

- **Ziel:** Eine schlanke, wiederverwendbare Section fuer den H1-Seitentitel, die `page.title` in EB Garamond / 40px / Prussian rendert -- getrennt vom `main-page`-Content-Bereich und ohne den RTE-Inhalt der Shopify-Page.

- **Analyse / Reuse-Entscheidung:**
  - `sections/main-page.liquid` rendert Titel + RTE-Inhalt als Einheit und ist ein FoxEcom-Original. ✅ Belegt: `sections/main-page.liquid:9-18`
  - Fuer das Retoure-Template wird `main-page` NICHT verwendet, da der Seiteninhalt vollstaendig aus Section-Bloecken (Akkordeon) kommt und kein RTE-Content der Shopify-Seite benoetigt wird.
  - Hyper-Utility-Klassen `font-heading` und `.h1` existieren: `font-heading` setzt `font-family: var(--font-heading-family)` (EB Garamond im Store). `.h1` setzt `font-size: var(--custom-heading-size, calc(var(--font-heading-mobile-scale) * var(--font-h1-size)))`. ✅ Belegt: `assets/theme.css:970-973` und `assets/theme.css:902-904`
  - H1 im Design: EB Garamond Medium, 40px, line-height 1.2, Farbe Prussian #002147 -- passt zu `font-heading .h1`, Farbe muss per CSS gesetzt werden. ✅ Belegt: Design-Spec Abschnitt 3.2

- **Dateien:**
  - NEU: `sections/mdm-page-title.liquid` -- Minimale Section: rendert `page.title` als H1 mit Klassen `font-heading h1`, Farbe Prussian per Inline-Style oder zugehoeriger CSS-Datei. Schema-Settings: `padding_top`, `padding_bottom`, `container`. Preset vorhanden.
  - NEU: `assets/mdm-section-page-title.css` -- Setzt die Prussian-Farbe (#002147), font-size 40px (bzw. via Hyper h1-Variable), line-height 1.2, padding-bottom 36px gemaess Design. Responsive: Mobile font-size kleiner (Hyper heading_mobile_scale greift automatisch ueber .h1-Klasse). ✅ Belegt: `assets/theme.css:903` (mobile-scale-Variable)

- **Validierung:** `shopify theme check` auf `sections/mdm-page-title.liquid`. H1 zeigt korrekten Font, Groesse, Farbe. Editor-Preset sichtbar.

- **Schritte:**
  1. Neue Section-Datei anlegen mit einfachem Liquid: Container-Wrapper mit `page-width page-width--narrow section--padding`, darin ein `h1` mit `page.title`.
  2. CSS-Datei anlegen mit Prussian-Farbe und Spacing gemaess Design-Spec.
  3. Schema mit Container-Setting (narrow default), Padding-Settings, und Preset definieren.
  4. Responsives Verhalten: `h1`-Klasse nutzt automatisch `--font-heading-mobile-scale`, daher kein separater Mobile-Breakpoint noetig.

---

### 3. Phase 3: FAQ-Akkordeon-Section (Reuse mdm-collapsible-tabs)

- **Ziel:** Die bestehende `sections/mdm-collapsible-tabs.liquid` fuer das FAQ-Akkordeon wiederverwenden. Kein Neubau noetig. Die Section unterstuetzt bereits `collapsible_item`-Bloecke mit Frage (heading), Antwort (richtext content), Plus/Minus-Toggle, und Open/Close-Verhalten.

- **Analyse / Reuse-Entscheidung (zentral):**
  - `sections/mdm-collapsible-tabs.liquid` ist eine mdm-Kopie der FoxEcom-Section. ✅ Belegt: `sections/mdm-collapsible-tabs.liquid:36` (laedt `mdm-section-collapsible-tabs.css`)
  - Block-Typ `collapsible_item` hat Settings: `heading` (text), `content` (richtext), `custom_liquid` (liquid), `page` (page), `open` (checkbox), `icon` (select), `use_subtext_color` (checkbox). ✅ Belegt: collapsible-tabs Schema Zeile 757-927 (identisch in mdm-Variante)
  - Die Summary rendert `h2` mit konfigurierbarer Font-Klasse (`font-heading h5` bei Einstellung `item_heading_font: heading`, `item_heading_size: h5`). ✅ Belegt: `sections/mdm-collapsible-tabs.liquid:130` und Schema Zeile 540-576
  - Der Plus/Minus-Toggle wird via `snippets/mdm-icon-plus-toggle.liquid` gerendert -- ein SVG mit 20x20 ViewBox, `horizontal`- und `vertical`-Pfaden, stroke-width 1.5. ✅ Belegt: `snippets/mdm-icon-plus-toggle.liquid:1-9`
  - Das Akkordeon-Verhalten ist EXCLUSIV (nur ein Item gleichzeitig offen): `AccordionGroup` in `assets/theme.js:1051-1068` schliesst alle Geschwister-`details[is="accordion-group"]` innerhalb `.accordion-parent`, wenn eines geoeffnet wird. ✅ Belegt: `assets/theme.js:1057-1065`
  - Animation ist eingebaut: `AccordionDetails` (Basis-Klasse, `assets/theme.js:996-1031`) animiert per `FoxTheme.Motion.timeline` mit 250ms Slide + 150ms Fade. ✅ Belegt: `assets/theme.js:996-1014`
  - CSS in `assets/mdm-section-collapsible-tabs.css` definiert Accordion-Styles: `accordion-standard` hat `border: 0` auf `.accordion-details`, Content-Padding `1.6rem 0 0`. ✅ Belegt: `assets/mdm-section-collapsible-tabs.css:29-34`
  - Der Content-Bereich hat Klasse `rte`, die Standard-Absatzformatierung liefert (margins, link-styles). ✅ Belegt: `assets/theme.css:1717-1829`
  - Die Section hat einen eigenen Section-Heading-Bereich (`mdm-section-heading` Snippet), der hier NICHT benoetigt wird (Heading ist leer, kein Subheading). Das ist per leeres `heading`-Setting erreichbar.

- **Defizit: Buttons innerhalb Akkordeon-Content**
  - Das Design zeigt zwei Buttons ("Jetzt Briefmarke erstellen" + "Jetzt Paketschein anfragen") innerhalb des ersten Akkordeon-Items. Der Block-Typ `collapsible_item` hat ein `richtext`-Setting (`content`) und ein `custom_liquid`-Setting. Richtext unterstuetzt keine Button-Elemente. ⚠️ Vermutung: Buttons muessen ueber `custom_liquid` oder als HTML im Richtext (via `<a class="btn ...">`) eingefuegt werden.
  - Hyper-Button-Klassen `btn`, `btn--primary`, `btn--secondary` sind global definiert. `btn--primary` nutzt `--color-button` / `--color-button-text`. `btn--secondary` nutzt `--color-secondary-button` / `-text` / `-border`. ✅ Belegt: `assets/theme.css:2262-2272`
  - Im Default-Schema scheme-1 sind die Button-Farben `button: #000000`, NICHT Prussian (#002147). ✅ Belegt: `config/settings_data.json:123`
  - Das bedeutet: Die `btn--primary`/`btn--secondary`-Klassen wuerden schwarze Buttons erzeugen, nicht Prussian. Fuer das Design sind Prussian-Buttons noetig.
  - Loesung: Buttons via `custom_liquid`-Setting im Block als HTML mit inline-style oder eigener CSS-Klasse einfuegen. Alternativ: Im Template-JSON das Akkordeon-Item mit `custom_liquid` befuellen, das Button-HTML mit expliziten Farbwerten enthaelt.

- **Farbwerte im Akkordeon:**
  - Border `Stone-100` (#3e3a32) -- aktuell nutzt `mdm-section-collapsible-tabs.css` keine eigene Border-Farbe; die Standard-`accordion-standard`-Items haben Borders aus dem Hyper-Theme-CSS. Die Borders muessen auf #3e3a32 gesetzt werden.
  - Frage-Farbe: Prussian #002147 -- im Design `h2.font-heading.h5`. Die `font-heading`-Klasse setzt die Heading-Font-Family. Farbe muss per CSS uebersteuert werden.
  - Antwort-Farbe: Stone-100 #3e3a32 -- Standard-`rte`-Farbe ist `var(--color-foreground)` (schwarz im scheme-1). Muss uebersteuert werden.
  - Toggle-Icon-Farbe: Stone-100 #3e3a32 -- aktuell `currentColor`, erbt also die Textfarbe. Passt, wenn die Summary-Farbe korrekt ist.

- **Dateien:**
  - KEIN NEUBAU der Section. Reuse von `sections/mdm-collapsible-tabs.liquid`.
  - NEU: `assets/mdm-section-retoure-faq.css` -- Zusaetzliches CSS fuer die Retoure-spezifischen Anpassungen: Frage-Farbe Prussian, Antwort-Farbe Stone-100, Border-Farbe Stone-100, Button-Styling innerhalb des Akkordeon-Contents (Prussian primary, White/Prussian-Border secondary, keine border-radius, Hoehe 48px, Padding 24px seitlich, Gap 12px). Wird im Template-JSON per `custom_css` oder als separater CSS-Load im `custom_liquid`-Feld eingebunden.
  - Alternativ: Die Farbanpassungen als `custom_css` im Template-JSON hinterlegen (Hyper unterstuetzt `custom_css` auf Section-Ebene im JSON). ⚠️ Vermutung: Muss geprueft werden, ob `custom_css` in `mdm-collapsible-tabs` im Schema unterstuetzt wird.

- **Validierung:** Akkordeon zeigt 10 Items, Item 1 standardmaessig offen, Plus/Minus-Toggle funktioniert, exklusives Oeffnen. Farben stimmen mit Design ueberein.

- **Schritte:**
  1. Pruefen, ob `mdm-collapsible-tabs` Schema `custom_css` unterstuetzt (Hyper OS 2.0 Feature, typischerweise automatisch vorhanden). Falls ja, Farbanpassungen dort hinterlegen. Falls nein, separates CSS-Asset erstellen und per `custom_liquid` in einem Block laden.
  2. Akkordeon-Section im Template-JSON konfigurieren: `container: narrow`, `heading: ""` (leer -- kein Section-Heading), `item_heading_font: heading`, `item_heading_size: h5`, `item_style: standard`, `padding_top: 0`, `padding_bottom: 50`.
  3. 10 `collapsible_item`-Bloecke anlegen, jeweils mit `heading` (Fragetext aus Design-Spec), `icon: none`, `open: false` (ausser Item 1: `open: true`).
  4. Item 1 `content`-Setting: Richtext mit den zwei Absaetzen. Inline-Link "Widerrufsbelehrung" als `<a href="/pages/widerrufsbelehrung">`. `custom_liquid`-Setting: Button-HTML mit den zwei Buttons (Briefmarke + Paketschein) mit `btn`-Klassen und Retoure-spezifischem CSS.
  5. Items 2-10: `content`-Setting mit Platzhalter-Richtext ("Antworttext wird noch ergaenzt.") als Default.
  6. Separate CSS-Datei oder `custom_css` fuer Farbanpassungen definieren.

---

### 4. Phase 4: Template-JSON und Section-Verdrahtung

- **Ziel:** Neues Page-Template `templates/page.retoure.json` erstellen, das die drei Sections (Breadcrumbs, Titel, FAQ) in der korrekten Reihenfolge verdrahtet. Layout: `mdm-theme`.

- **Analyse:**
  - Bestehende Page-Templates (z.B. `page.faq.json`) nutzen `"layout": "mdm-theme"` und verdrahten Sections ueber `sections`-Objekt + `order`-Array. ✅ Belegt: `templates/page.faq.json:11,477-484`
  - Das FAQ-Template nutzt die Original-`breadcrumbs`-Section (nicht mdm-). Das Retoure-Template soll die erweiterte `mdm-breadcrumbs`-Section nutzen. ✅ Belegt: `templates/page.faq.json:13`
  - Content-Breite im Design: 880px bei 1440px Viewport = 61%. `page-width--narrow` hat `max-width: 88rem` (880px). Perfekte Uebereinstimmung. ✅ Belegt: `assets/theme.css:184-187`
  - Template-Naming-Konvention: `page.<slug>.json`. Slug: `retoure`. ✅ Belegt: CLAUDE.md Namensregel

- **Dateien:**
  - NEU: `templates/page.retoure.json` -- Reines JSON ohne Auto-Generated-Banner. Layout `mdm-theme`. Sections: `mdm-breadcrumbs` (mit parent_label/parent_url-Settings), `mdm-page-title`, `mdm-collapsible-tabs` (mit 10 Bloecken).

- **Validierung:** JSON-Parse erfolgreich. Template im Theme-Editor sichtbar. Sections in korrekter Reihenfolge. Seite im Dev-Server ladbar.

- **Schritte:**
  1. Template-JSON erstellen mit drei Section-Eintraegen und `order`-Array.
  2. Breadcrumbs-Section: `parent_label: "Hilfe & Service"`, `parent_url: "/pages/hilfe-service"` (URL als Platzhalter, muss ggf. angepasst werden), `container: narrow`, `padding_top: 20`, `padding_bottom: 20`.
  3. Page-Title-Section: `container: narrow`, `padding_top: 0`, `padding_bottom: 36`.
  4. Collapsible-Tabs-Section: `container: narrow`, `heading: ""`, `item_heading_font: heading`, `item_heading_size: h5`, `item_style: standard`, 10 Bloecke.
  5. JSON validieren (nach Entfernen etwaiger Kommentare, die hier ohnehin nicht gesetzt werden).
  6. Shopify-Admin: Neue Page erstellen, Template "retoure" zuweisen. ❌ Unbekannt: Muss im Store-Admin erfolgen.

---

### 5. Phase 5: Uebersetzungen und Figma-Mapping-Update

- **Ziel:** Neue Uebersetzungs-Keys in `en.default.json` / `de.json` (sowie Schema-Pendants) anlegen. Figma-Mapping-Tabelle aktualisieren.

- **Dateien:**
  - AENDERN: `locales/en.default.json` -- Neue Keys unter `sections.mdm_page_title`.
  - AENDERN: `locales/de.json` -- Deutsche Pendants.
  - AENDERN: `locales/en.default.schema.json` -- Schema-Labels fuer neue Section/Settings.
  - AENDERN: `locales/de.schema.json` -- Deutsche Schema-Labels.
  - VORSCHLAG (nicht selbst editieren): `figma-mapping.md` -- Neue verifizierte Zeilen.

- **Validierung:** `shopify theme check` auf Locale-Dateien. Alle neuen Keys in en.default + de paarig vorhanden.

- **Schritte:**
  1. Keys fuer `mdm-page-title`-Section anlegen (Name, Settings-Labels).
  2. Keys fuer erweiterte Breadcrumbs-Settings (`parent_label`, `parent_url`) anlegen.
  3. Figma-Mapping-Vorschlaege formulieren (siehe unten).

---

## Uebersetzungs-Keys

**en.default.schema.json / de.schema.json (Schema-Labels):**

| Key | en.default | de |
|---|---|---|
| `sections.mdm-page-title.name` | Page title | Seitentitel |
| `sections.mdm-breadcrumbs.settings.parent_label.label` | Parent page label | Elternseiten-Label |
| `sections.mdm-breadcrumbs.settings.parent_url.label` | Parent page link | Elternseiten-Link |
| `sections.mdm-breadcrumbs.settings.parent_label.info` | Optional middle breadcrumb level (e.g. "Help & Service") | Optionale mittlere Breadcrumb-Ebene (z.B. "Hilfe & Service") |

**en.default.json / de.json (Frontend-Texte):**

| Key | en.default | de |
|---|---|---|
| `sections.mdm_page_title.name` | Page title | Seitentitel |

---

## Figma-Mapping-Vorschlaege (verifiziert)

| Figma-Layer/Muster | Theme-Gegenstueck | Status | Beleg |
|---|---|---|---|
| `breadcrumbs (nav)` (3 Ebenen) | `sections/mdm-breadcrumbs.liquid` mit `parent_label`/`parent_url`-Settings | ✅ Geeignet nach Erweiterung | `sections/mdm-breadcrumbs.liquid:67-69` (aktuell 2 Ebenen) |
| `accordion-item` / FAQ-Liste | `sections/mdm-collapsible-tabs.liquid` mit `collapsible_item`-Bloecken | ✅ Geeignet (Reuse) | `sections/mdm-collapsible-tabs.liquid:110-140` |
| `btn--primary` / `btn--secondary` | Hyper-Klassen `btn btn--primary`, `btn btn--secondary` in `assets/theme.css:2262-2272` | ✅ Vorhanden, aber Farben weichen ab (scheme-1 = schwarz, nicht Prussian) | `config/settings_data.json:123` |
| `h2.font-heading.h5` | Hyper-Utility `.font-heading` + `.h5` in `assets/theme.css:920-926,970-973` | ✅ Vorhanden und passend | |
| `.rte` (Rich-Text-Content) | Hyper `.rte`-Wrapper in `assets/theme.css:1717-1829` | ✅ Vorhanden, liefert Absatz-Margins und Link-Styling | |
| `icon-plus-toggle` | `snippets/mdm-icon-plus-toggle.liquid` -- SVG 20x20, stroke 1.5 | ✅ Vorhanden und designkonform | `snippets/mdm-icon-plus-toggle.liquid:1-9` |
| `Stone-80` (#615b4f) | Kein Hyper-Token. Hardcoded in mdm-CSS-Dateien (z.B. `mdm-section-product-faq.css:28,85`) | ✅ Bestaetigt: MDM-Pattern = Hex-Hardcode | |
| `Stone-100` (#3e3a32) | Kein Hyper-Token. Hardcoded (z.B. `mdm-section-product-faq.css:73`, `mdm-section-main-product.css:62`) | ✅ Bestaetigt: MDM-Pattern = Hex-Hardcode | |
| `Prussian` (#002147) | Kein Hyper-Token. Hardcoded in 6+ mdm-CSS-Dateien (z.B. `mdm-section-product-faq.css:33`, `mdm-section-main-product.css:61`) | ✅ Bestaetigt: MDM-Pattern = Hex-Hardcode | |
| `White` (#ffffff) | Entspricht `--color-background` (scheme-1: #ffffff). ✅ Standard-Hyper-Variable. | ✅ Bestaetigt | `config/settings_data.json:121` |

---

## Risiken

1. **Breadcrumbs-Separator-Diskrepanz:** Design zeigt Pipe-Separator (`|`, 1px, 14px hoch), bestehende mdm-Breadcrumbs nutzen SVG-Chevron. Loesung muss visuell geprueft werden -- entweder SVG austauschen oder per CSS den Separator umgestalten. ⚠️
2. **Button-Farben im Akkordeon:** Die globalen `btn--primary`/`btn--secondary`-Klassen nutzen scheme-1-Farben (schwarz), nicht Prussian. Buttons muessen per zusaetzlichem CSS oder inline-Styles uebersteuert werden. Dieses Pattern ist nicht wiederverwendbar fuer andere Pages. ⚠️
3. **Elternseite "Hilfe & Service" existiert moeglicherweise nicht:** Die Breadcrumb-URL `/pages/hilfe-service` ist ein Platzhalter. Muss im Store-Admin angelegt oder angepasst werden. ❌ Unbekannt
4. **Richtext-Limitierung fuer Buttons:** Shopify-Richtext-Settings unterstuetzen keine Button-Elemente. Buttons muessen via `custom_liquid`-Setting eingefuegt werden, was die Merchant-Editierbarkeit einschraenkt (HTML-Kenntnisse noetig). ⚠️
5. **Mobile-Design fehlt:** Responsives Verhalten wird aus bestehenden Hyper-Patterns abgeleitet (heading-mobile-scale, page-width-Padding, Accordion-Summary-Padding-Reduktion). Visuelles Review auf Mobile zwingend noetig. ⚠️

---

## Offene Fragen (an Konrad)

1. **Akkordeon-Verhalten -- exklusiv oder multi-open?**
   Das bestehende `AccordionGroup` in theme.js erzwingt exklusives Oeffnen (nur ein Item gleichzeitig offen). Das Design zeigt genau dieses Verhalten. Soll es dabei bleiben, oder soll multi-open moeglich sein?
   - Option A: Exklusiv (Standard, kein Aufwand) -- **Empfehlung**
   - Option B: Multi-open (erfordert Wechsel von `is="accordion-group"` zu `is="accordion-details"` oder Entfernung des `is`-Attributs)

2. **Breadcrumbs-Separator -- Pipe oder Chevron?**
   Design zeigt einen vertikalen Strich als Separator. Die bestehenden mdm-Breadcrumbs nutzen ein SVG-Chevron (`>`). Welche Variante soll verwendet werden?
   - Option A: Pipe (designkonform, erfordert Separator-Aenderung)
   - Option B: Chevron beibehalten (konsistent mit restlichem Shop)

3. **Button-URLs fuer "Jetzt Briefmarke erstellen" und "Jetzt Paketschein anfragen":**
   Die Ziel-URLs sind im Design nicht definiert. Sollen Platzhalter-URLs verwendet werden (z.B. `#briefmarke`, `#paketschein`), die spaeter redaktionell ersetzt werden?

4. **Elternseite "Hilfe & Service":**
   Existiert eine Seite mit diesem Handle im Store? Falls nicht, soll eine erstellt werden, oder soll die Breadcrumb-URL auf eine bestehende Seite verweisen?

5. **Farbabweichung Breadcrumbs:**
   Die aktuelle mdm-Breadcrumb-Link-Farbe ist `#6a6357`, Figma zeigt `#615b4f` (Stone-80). Soll die bestehende Farbe auf Stone-80 geaendert werden (betrifft alle Seiten, die mdm-breadcrumbs nutzen)?

---

## Definition of Done

- [ ] `shopify theme check` fehlerfrei auf allen neuen/geaenderten Dateien (sections/mdm-breadcrumbs.liquid, sections/mdm-page-title.liquid, templates/page.retoure.json, assets/mdm-section-page-title.css, assets/mdm-section-retoure-faq.css, locale-Dateien)
- [ ] Shopify Dev MCP `validate_theme` bestanden
- [ ] Uebersetzungen komplett (en.default + de, Schema + Frontend)
- [ ] Alle neuen Sections haben Editor-Presets
- [ ] Template im Theme-Editor ladbar, Sections konfigurierbar
- [ ] JSON-Template ohne Kommentar-Banner, JSON-Parse sauber
- [ ] Responsives Verhalten definiert: Page-Width-Narrow (880px), Heading-Mobile-Scale, Accordion-Padding-Reduktion auf Mobile
- [ ] Visuelle Paritaet mit Referenz-Screenshot (`assets-src/reference-4030-195.png`) auf Desktop 1440px
- [ ] Breadcrumbs zeigen 3 Ebenen (Startseite | Hilfe & Service | Retoure & Reklamation)
- [ ] Akkordeon: 10 Items, Item 1 default offen, Plus/Minus-Toggle, exklusives Oeffnen
- [ ] Buttons im ersten Akkordeon-Item visuell korrekt (Prussian primary, White/Prussian secondary, eckig, 48px Hoehe)
- [ ] Figma-Mapping-Tabelle Aktualisierungsvorschlag im Plan dokumentiert
