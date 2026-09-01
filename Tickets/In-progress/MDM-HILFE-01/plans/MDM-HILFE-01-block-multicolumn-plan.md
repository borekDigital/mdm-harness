## Plan: Themenkacheln -- Multicolumn-Reuse vs. Custom-Section

Die Hilfe-Einstiegsseite zeigt 6 Themenkacheln (3x2 Desktop, 1-spaltig Mobile) mit
vollflaechig klickbaren Cards, Icons, responsivem Layout-Wechsel (Desktop: col/zentriert,
Mobile: row/links). Dieser Plan bewertet den Einsatz von `mdm-multicolumn-icon.liquid`
als Basis und stellt ihn der bereits implementierten Loesung `mdm-help-topic-cards.liquid`
gegenueber. **Bevor implementiert wird, muss Konrad entscheiden, welchen Pfad er waehlt.**

---

## 0. Entscheidungslage

### Ist-Zustand: `mdm-help-topic-cards.liquid` existiert bereits

Im Rahmen des Hauptplans (MDM-HILFE-01-hilfe-einstiegsseite-plan.md, Phase 2) wurde
eine zweckgebaute Section implementiert, die alle Design-Anforderungen abdeckt:

| Anforderung | mdm-help-topic-cards | mdm-multicolumn-icon |
|---|---|---|
| Vollflaechig klickbare Kachel | Ja (Stretched-Link via `::after`) | Nein -- kein Link-Wrapper |
| Responsive Layout-Flip (col/row) | Ja (CSS `@media`) | Nein -- `image_position` ist global statisch |
| Mobiler Alternativ-Titel | Ja (`title_mobile` Setting) | Nein |
| Eigene SVG-Icons (Inline) | Ja (`inline_asset_content`) | Nein -- nur Icon-Select oder `image_picker` |
| Figma-Gap 24px/14px | Ja (exakte Werte) | Nein -- f-grid naechster Wert: 20px oder 30px |
| Kein Section-Heading | Ja (optional) | Ja (Heading leer lassen) |
| In `page.hilfe.json` integriert | Ja (als `mdm_topic_cards`) | Nein |
| Translations vorhanden | Nein (Keys fehlen in Locales) | Teilweise (erbt FoxEcom-Keys) |
| CSS vorhanden | Ja (`mdm-section-help-topic-cards.css`, 125 Zeilen) | Teilweise (`mdm-component-multicolumn-card.css`) |
| SVG-Assets deployed | Ja (6x `mdm-icon-hilfe-*.svg`) | -- |

Quellbelege:
- Stretched Link: `mdm-section-help-topic-cards.css:96-100` (`.mdm-help-card__link::after { content: ""; position: absolute; inset: 0; }`)
- Responsive Flip: `mdm-section-help-topic-cards.css:47-63` (Desktop flex-col, Mobile flex-row)
- Mobile-Titel: `mdm-help-topic-cards.liquid:36-39` (`mdm-help-card__title-desktop` / `mdm-help-card__title-mobile`)
- Inline-Icons: `mdm-help-topic-cards.liquid:27` (`inline_asset_content`)
- Focus-Management: `mdm-section-help-topic-cards.css:117-124` (`:has(a:focus-visible)`)
- Template-Referenz: `page.hilfe.json:27-28` (`"type": "mdm-help-topic-cards"`)
- SVG-Assets: 6 Dateien `theme/assets/mdm-icon-hilfe-{bestellung,bezahlung,versand-lieferung,retoure-reklamation,kundendaten,kollektion}.svg`

### Soll-Vorgabe aus dem Briefing

Konrad hat mit der Designerin gesprochen: „Die Kacheln sollen ueber die bestehende
Multicolumn-Section abgebildet werden, kein Custom-Section-Neubau."

### Widerspruch

`mdm-help-topic-cards.liquid` IST bereits gebaut und funktioniert. Die Frage ist nicht
mehr „Neubau vs. Reuse", sondern: **Soll die funktionierende Custom-Section zugunsten
eines umgebauten Multicolumn verworfen werden?**

---

## 1. Pfad A: `mdm-multicolumn-icon.liquid` erweitern

### 1.1 Notwendige Aenderungen an der Section

Die folgenden fuenf Aenderungen sind noetig, um die Figma-Anforderungen abzudecken.
**`mdm-multicolumn-icon.liquid` wird aktuell in keinem Template genutzt** (Belegt:
Grep ueber alle `templates/*.json` ergibt 0 Treffer), daher sind Aenderungen risikofrei.

**A1: Vollflaeching klickbare Kachel (Stretched Link)**

- Neues Block-Setting `link` (Typ `url`) im Schema hinzufuegen
- Im Liquid: wenn `block.settings.link` gesetzt, einen `<a>`-Tag mit CSS-Klasse
  `mdm-multicolumn-card__link` in die `.multicolumn-card` einfuegen, positioniert
  nach dem `.multicolumn-card__info`-Block
- CSS-Overlay-Pattern: `position: absolute; inset: 0; z-index: 1` auf dem `::after`
  des Links (Hyper-bewaehrtes Pattern, identisch mit der Produktkarten-Mechanik)
- `.multicolumn-card` benoetigt `position: relative` (aktuell nicht gesetzt; der
  Wrapper `.multicolumn-card-wrapper` hat es via `relative`-Klasse)
- Focus-Styling: `:has(a:focus-visible)` Outline auf `.multicolumn-card`, Link
  selbst `outline: none`
- Semantik: der `<a>` bekommt `aria-label` aus `block.settings.title` und
  `tabindex="0"` (Default)

**A2: Responsive Layout-Flip (Desktop col/center, Mobile row/left)**

Aktuell kontrolliert `image_position` (global Setting) ob die Kachel flex-col oder
flex-row ist. Der Figma-Entwurf verlangt: Desktop immer col/zentriert, Mobile immer
row/links -- unabhaengig vom Setting.

Zwei Loesungsoptionen:
- Option 1: Neues Section-Setting `responsive_layout` (Typ Checkbox, Default false).
  Wenn aktiv, wird eine CSS-Klasse `multicolumn-card--responsive-flip` gesetzt, und
  ein CSS-Block ueberschreibt die Richtung per `@media`-Query.
- Option 2: Rein per CSS im page-scoped Stylesheet `mdm-page-hilfe.css` mit
  Section-ID-Selektor.

Option 1 ist vorzuziehen, weil sie die Section wiederverwendbar macht.

**A3: Mobiler Alternativ-Titel**

- Neues Block-Setting `title_mobile` (Typ `inline_richtext`, optional)
- Im Liquid: wenn gesetzt, Desktop-Span und Mobile-Span mit
  `small-hide medium-hide` / `large-up-hide` Klassen rendern
- Wird nur fuer die Kachel „Kollektion und Sammeln" -> „Kollektion" benoetigt

**A4: Eigene SVG-Icons**

Die Section nutzt aktuell `mdm-icons` Snippet (Select) oder `image_picker`.
Die Platzhalter-SVGs liegen als Theme-Assets bereit (`mdm-icon-hilfe-*.svg`).

Zwei Loesungsoptionen:
- Option 1: Icons per `image_picker` hochladen (Nachteil: keine `currentColor`-
  Kontrolle, kein Inline-SVG, also keine Farbvererbung ueber `--icon-color`)
- Option 2: Das Icon-Select um die 6 Hilfe-Icons erweitern und sie in `mdm-icons`
  Snippet aufnehmen (Nachteil: verschmutzt die globale Icon-Liste fuer einen
  einzelnen Anwendungsfall)
- Option 3: Neues Block-Setting `custom_icon_asset` (Typ `text`) und Rendering via
  `inline_asset_content` (wie in `mdm-help-topic-cards.liquid:27`), mit Fallback
  auf das Icon-Select

Option 3 ist am saubersten, erfordert aber ein freies Texteingabefeld, was den
Theme-Editor-Komfort reduziert.

**A5: Gap-Anpassung**

Figma: 24px Spalten-Gap, 24px Zeilen-Gap (Desktop), 14px (Mobile).
f-grid naechste Werte: `small` = 20px, `medium` = 30px (Desktop), beide 12px (Mobile).

- Im CSS muss der Gap per Override auf die exakten Werte gesetzt werden
- Entweder im page-scoped CSS oder als neue `{% style %}`-Variablen in der Section

### 1.2 Aufwand-Einschaetzung Pfad A

- Liquid-Aenderungen an `mdm-multicolumn-icon.liquid`: 5 Bereiche (Schema + Markup)
- CSS-Aenderungen/-Ergaenzungen: ca. 60-80 Zeilen
- Template-Aenderung `page.hilfe.json`: Section-Typ austauschen, Block-Struktur anpassen
- Translation-Keys: vorhandene FoxEcom-Keys teilweise nutzbar, aber neue Keys fuer
  `title_mobile`, `link`, `responsive_layout`
- SVG-Assets: bereits deployed (von Phase 2 des Hauptplans)

### 1.3 Nachteile Pfad A

1. **Zweckentfremdung:** `mdm-multicolumn-icon` ist ein generisches Grid-Layout.
   Fuenf strukturelle Aenderungen fuer einen einzelnen Anwendungsfall machen es
   weniger generisch.
2. **Redundanz:** Die gleiche Funktionalitaet existiert bereits in
   `mdm-help-topic-cards.liquid`.
3. **Scoping-Direktive:** Die bestehende Direktive (Revision 3 des Hauptplans, Zeile
   56-59) sagt „keine bestehende .liquid-Datei wird angefasst". `mdm-multicolumn-icon`
   IST eine bestehende .liquid-Datei. Die Direktive muesste aufgehoben werden.
4. **Translations:** Die FoxEcom-Translations sind Englisch; deutsche Pendants muessten
   dennoch in `de.json` gepflegt werden.

---

## 2. Pfad B: `mdm-help-topic-cards.liquid` behalten und vervollstaendigen

### 2.1 Fehlende Arbeiten

Die Section ist funktional fertig. Es fehlen nur:

1. **Locale-Keys:** Die Schema-Translations (`t:sections.mdm-help-topic-cards.*`)
   wurden noch nicht in `locales/en.default.schema.json` und `locales/de.schema.json`
   eingetragen. Im Theme-Editor erscheinen daher die Translation-Keys als Rohtext.
   (Belegt: Grep ueber `theme/locales/` ergibt 0 Treffer fuer `mdm-help-topic-cards`)

2. **Farbabstimmung Border:** Die Section nutzt `rgb(var(--color-border))`, was in
   scheme-1 zu `#D6CAB3` (Stone-20) aufloest.
   (Belegt: `config/settings_data.json:119`, `mdm-section-help-topic-cards.css:43`)
   Das ist korrekt laut Figma -- kein Delta.

3. **Padding-Delta:** Card-Padding ist `2.4rem 2rem` Desktop / `2.4rem 1.6rem` Mobile.
   Figma verlangt `28px` (2.8rem) allseitig Desktop / `20px` (2rem) Mobile.
   Delta: 4px/8px Desktop, 4px Mobile. Unter „maximal vererben" kein Blocker,
   aber koennnte bei visueller Abnahme auffallen.

4. **Icon-Groesse:** Nutzt `.icon--extra-large` = 3.2rem = 32px. Figma: 32px. Kein Delta.
   (Belegt: `theme.css:5335-5336`, `mdm-help-topic-cards.liquid:26`)

5. **Typo-Delta Titel:** Section nutzt Section-Setting `title_size` (aktuell `text-base`
   im Template). Figma: 19px Inter SemiBold 600. `text-base` = 16px (Belegt:
   `theme.css:882`). Naechster Wert: `.h6` = 16px, `.h5` = 18px. Unter
   „maximal vererben" akzeptabel, oder Template-JSON auf `h5` aendern (1px Delta).

6. **Hover-Effekt:** Figma zeigt keinen expliziten Hover-State. Die Section hat
   keinen Card-Hover definiert (kein `box-shadow` o.ae.). Falls gewuenscht,
   waere das ein kleiner CSS-Nachtrag.

### 2.2 Aufwand-Einschaetzung Pfad B

- Locale-Keys hinzufuegen: ca. 30 Zeilen pro Datei (rein additiv)
- Optional: `title_size` in `page.hilfe.json` auf `h5` aendern (1 Zeile)
- Kein Liquid-Umbau, kein neues CSS, kein Template-Umbau

### 2.3 Nachteile Pfad B

1. **Custom Section statt Reuse:** Widerspricht der Vorgabe „bestehende
   Multicolumn-Section nutzen, kein Custom-Section-Neubau".
2. **Eine Section mehr im Theme:** 1 zusaetzliche Section-Datei + 1 CSS-Datei +
   6 SVG-Assets.

---

## 3. Empfehlung

**Pfad B** (behalten und vervollstaendigen) ist objektiv der schnellere, risikoaermere
und praezisere Weg. Die Section existiert, funktioniert, trifft das Design und hat
keinerlei Blast-Radius. Der einzige Nachteil ist: es ist kein Multicolumn-Reuse.

**Pfad A** (Multicolumn erweitern) wuerde 5 nicht-triviale Aenderungen an einer
generischen Section erfordern, die in Summe den gleichen Funktionsumfang erzeugen,
der in `mdm-help-topic-cards` bereits fertig ist. Das Ergebnis waere eine
Multicolumn-Section, die mit Hilfe-spezifischen Features ueberladen ist.

**Die Entscheidung liegt bei Konrad.** Falls er bei „Multicolumn nutzen" bleibt,
folgt der Implementierungsplan fuer Pfad A (Phasen 1-5 unten). Falls er Pfad B
waehlt, folgt ein reduzierter Plan (nur Locale-Keys + optionale Typo-Anpassung).

---

## 4. Implementierungsplan: Pfad A (Multicolumn-Erweiterung)

Nur relevant, wenn Konrad Pfad A waehlt.

**Phasen:** 5

### Phase 1: Schema-Erweiterung Block-Settings

- **Ziel:** Block um `link`, `title_mobile` und `custom_icon_asset` erweitern
- **Dateien:**
  - `theme/sections/mdm-multicolumn-icon.liquid` aendern -- Schema-Block `column`
    um drei Settings ergaenzen. Begruendung: MDM-Override, kein FoxEcom-Original.
- **Schritte:**
  1. Block-Setting `link` (Typ `url`) nach `button_icon` einfuegen
  2. Block-Setting `title_mobile` (Typ `inline_richtext`, optional) nach `title`
     einfuegen
  3. Block-Setting `custom_icon_asset` (Typ `text`, optional, Info-Text mit
     Namenskonvention) nach `image` einfuegen
  4. Neue Translation-Keys fuer alle drei Settings in `en.default.schema.json`
     und `de.schema.json` anlegen
- **Validierung:** JSON-Parse des Schema-Blocks, `shopify theme check --fail-level error`,
  Theme-Editor oeffnen und pruefen, dass die neuen Settings sichtbar sind

### Phase 2: Section-Setting `responsive_layout` und CSS-Klasse

- **Ziel:** Section-level Checkbox fuer responsiven Layout-Flip
- **Dateien:**
  - `theme/sections/mdm-multicolumn-icon.liquid` aendern -- neues Setting
    `responsive_layout` im Schema, CSS-Klasse im Markup
  - `theme/assets/mdm-component-multicolumn-card.css` aendern -- CSS-Regeln fuer
    `.multicolumn-card--responsive-flip`
- **Schritte:**
  1. Section-Setting `responsive_layout` (Typ `checkbox`, Default `false`) im
     Schema nach `image_position` einfuegen
  2. Im Liquid: wenn aktiv, Klasse `multicolumn-card--responsive-flip` zur
     `.multicolumn-card`-Div hinzufuegen; `image_position`-Klasse entfaellt dann
  3. CSS-Regeln schreiben:
     - Desktop (ab 768px): `flex-direction: column; align-items: center; text-align: center`
     - Mobile (bis 767px): `flex-direction: row; align-items: center; gap: 1.6rem; text-align: left`
     - Icon `margin-bottom` auf Desktop beibehalten, auf Mobile auf 0 setzen
  4. Translation-Keys fuer das neue Setting
- **Validierung:** Theme-Editor: Setting togglen, Desktop- und Mobile-Vorschau pruefen.
  `shopify theme check`.

### Phase 3: Liquid-Markup fuer Stretched Link, Mobile-Titel, Inline-Icons

- **Ziel:** Die drei Markup-Aenderungen im Block-Loop
- **Dateien:**
  - `theme/sections/mdm-multicolumn-icon.liquid` aendern -- Block-Loop (Zeile 83-177)
- **Schritte:**
  1. **Stretched Link:** Nach dem `.multicolumn-card__info`-Block: wenn
     `block.settings.link` gesetzt, ein `<a href="..." class="mdm-multicolumn-card__link" aria-label="..."></a>` rendern.
     `.multicolumn-card` mit `position: relative; isolation: isolate` versehen
     (inline oder via CSS).
  2. **Mobile-Titel:** Im `.multicolumn-card__title` h3: wenn `block.settings.title_mobile`
     gesetzt, zwei Spans mit Visibility-Klassen rendern (`small-hide medium-hide` /
     `large-up-hide`). Sonst unveraendert.
  3. **Inline-Icons:** Im `.multicolumn-card__image`-Block: neuer Zweig vor dem
     `image_picker`-Check: wenn `block.settings.custom_icon_asset` gesetzt, das Asset
     per `inline_asset_content` rendern (identisch mit Pattern in
     `mdm-help-topic-cards.liquid:27`). Fallback auf Icon-Select und `image_picker`.
- **Validierung:** Dev-Server: alle 6 Kacheln mit Icons, Links und einem Mobile-Titel
  konfigurieren. Link-Klick testen. `shopify theme check`.

### Phase 4: CSS fuer Stretched Link, Gap-Override, Padding-Feinschliff

- **Ziel:** Visuelles Finish
- **Dateien:**
  - `theme/assets/mdm-component-multicolumn-card.css` aendern -- Stretched-Link-CSS,
    Focus-Management, optionaler Gap-Override
- **Schritte:**
  1. Stretched-Link-CSS: `.mdm-multicolumn-card__link::after { content: ""; position: absolute; inset: 0; }`
  2. Focus: `.multicolumn-card:has(a:focus-visible) { outline: 0.2rem solid rgb(var(--color-keyboard-focus)); outline-offset: 0.2rem; }` und `.mdm-multicolumn-card__link:focus-visible { outline: none; }`
  3. Hover: `cursor: pointer` auf `.multicolumn-card:has(.mdm-multicolumn-card__link)`
  4. Gap-Override fuer die Hilfe-Seite: ggf. als page-scoped CSS oder als CSS-Custom-
     Property im `{% style %}`-Block der Section
  5. Card-Padding auf `2.8rem` (28px) Desktop, `2rem` (20px) Mobile setzen, sofern
     die „maximal vererben"-Direktive hier aufgehoben wird
- **Validierung:** Responsive Vorschau Desktop/Tablet/Mobile, Focus-Tab-Test,
  `shopify theme check`.

### Phase 5: Template-JSON und Locale-Keys

- **Ziel:** `page.hilfe.json` auf die erweiterte Multicolumn-Section umstellen
- **Dateien:**
  - `theme/templates/page.hilfe.json` aendern -- Section `mdm_topic_cards` von
    `mdm-help-topic-cards` auf `mdm-multicolumn-icon` umstellen, Block-Struktur
    an das Multicolumn-Schema anpassen
  - `theme/locales/en.default.schema.json` aendern -- neue Keys
  - `theme/locales/de.schema.json` aendern -- neue Keys
- **Schritte:**
  1. Section-Typ auf `mdm-multicolumn-icon` aendern
  2. Section-Settings: `columns_desktop: 3`, `columns_mobile: "1"`,
     `column_gap: "small"` (20px, naechster Wert zu 24px), `row_gap: "inherit"`,
     `image_position: "top"`, `responsive_layout: true`, `content_alignment: "center"`,
     `heading: ""` (leer), `show_divider_col: false`, `card_color_scheme: "scheme-1"`,
     `icon_color: "#002147"`, `padding_top: 0`, `padding_bottom: 48`
  3. Bloecke: 6 Bloecke vom Typ `column` mit `title`, `title_mobile` (nur Kollektion),
     `text`, `link`, `custom_icon_asset` (z.B. `mdm-icon-hilfe-bestellung.svg`)
  4. Translation-Keys in beiden Locale-Dateien
  5. Entscheidung: `mdm-help-topic-cards.liquid`, `mdm-section-help-topic-cards.css`
     und die Locale-Keys entfernen oder als Dead-Code belassen (fuer Konrad)
- **Validierung:** JSON-Parse, Dev-Server, Theme-Editor-Vorschau, Desktop/Mobile-Vergleich
  mit Referenz-Screenshots, `shopify theme check`, `validate_theme`.

---

## 5. Implementierungsplan: Pfad B (Vervollstaendigung mdm-help-topic-cards)

Nur relevant, wenn Konrad Pfad B waehlt.

**Phasen:** 2

### Phase 1: Locale-Keys ergaenzen

- **Ziel:** Alle `t:sections.mdm-help-topic-cards.*` Keys verfuegbar machen
- **Dateien:**
  - `theme/locales/en.default.schema.json` aendern -- neuer Abschnitt
    `sections.mdm-help-topic-cards` mit allen 25+ Keys
  - `theme/locales/de.schema.json` aendern -- deutsche Pendants
- **Schritte:**
  1. Alle `t:`-Referenzen aus dem Schema von `mdm-help-topic-cards.liquid` extrahieren
     (ca. 25 Keys)
  2. Englische Defaults in `en.default.schema.json` eintragen
  3. Deutsche Uebersetzungen in `de.schema.json` eintragen
- **Validierung:** Theme-Editor oeffnen, Section-Settings und Block-Settings pruefen:
  keine rohen Translation-Keys sichtbar. `shopify theme check`.

### Phase 2: Optionale Feinjustierung (Template-JSON)

- **Ziel:** Typo-Setting naeher an Figma-Spec
- **Dateien:**
  - `theme/templates/page.hilfe.json` aendern -- `title_size` von `text-base` auf
    `h5` aendern (18px statt 16px, naeher an Figma 19px)
  - Optional: `title_font` von `body` auf `body-bolder` aendern (SemiBold-Annaeherung,
    da `body-bolder` = Inter 700 vs. Figma 600 -- aber naeher als 400)
- **Schritte:**
  1. In `page.hilfe.json` die Settings `title_size` und `title_font` anpassen
  2. Visuellen Vergleich mit Referenz-Screenshot pruefen
- **Validierung:** JSON-Parse, Dev-Server, visueller Vergleich.

---

## Uebersetzungs-Keys

### Pfad A (neue Keys fuer mdm-multicolumn-icon)

| Key | en.default | de |
|---|---|---|
| `sections.mdm-multicolumn-icon.settings.responsive_layout.label` | Responsive layout flip | Responsiver Layout-Wechsel |
| `sections.mdm-multicolumn-icon.blocks.column.settings.link.label` | Card link | Kachel-Link |
| `sections.mdm-multicolumn-icon.blocks.column.settings.title_mobile.label` | Title (mobile) | Titel (mobil) |
| `sections.mdm-multicolumn-icon.blocks.column.settings.custom_icon_asset.label` | Custom icon asset | Eigenes Icon-Asset |
| `sections.mdm-multicolumn-icon.blocks.column.settings.custom_icon_asset.info` | Enter SVG asset filename (e.g. mdm-icon-hilfe-bestellung.svg) | SVG-Asset-Dateiname eingeben (z.B. mdm-icon-hilfe-bestellung.svg) |

### Pfad B (fehlende Keys fuer mdm-help-topic-cards)

Ca. 25 Keys aus dem Schema von `mdm-help-topic-cards.liquid` (Zeile 69-271).
Vollstaendige Liste wird in Phase 1 der Implementierung erstellt.

---

## Risiken

1. **Pfad A -- Feature-Creep:** 5 nicht-triviale Aenderungen an einer generischen
   Section koennten Seiteneffekte haben, falls die Section spaeter anderswo eingesetzt
   wird (z.B. Stretched Link bei einer Kachel ohne Link).
   Mitigierung: Alle neuen Features sind per Setting deaktivierbar (Default: aus).

2. **Pfad A -- `inline_asset_content` in generischer Section:** Das Texteingabefeld
   fuer den Asset-Dateinamen ist fehleranfaellig (Tippfehler = kein Icon).
   Mitigierung: Fallback auf Icon-Select.

3. **Pfad A -- Scoping-Direktive-Bruch:** Die bestehende Direktive verbietet
   Aenderungen an bestehenden .liquid-Dateien. Muss explizit aufgehoben werden.

4. **Pfad B -- Konrad-Vorgabe:** Widerspricht der Aussage „bestehende Multicolumn
   nutzen". Muss explizit bestaetigt werden.

5. **Beide Pfade -- Gap-Delta:** Unter „maximal vererben" akzeptabel (20px statt 24px
   bei Pfad A mit f-grid `small`). Pfad B hat exakte Werte.

---

## Offene Fragen

1. **Pfad-Entscheidung:** Soll Pfad A (Multicolumn erweitern) oder Pfad B
   (mdm-help-topic-cards behalten) verfolgt werden?
   -- Pfad A: mehr Aufwand, Reuse-Dogma erfuellt, aber Zweckentfremdung.
   -- Pfad B: minimal, exakt, aber Custom-Section bleibt.

2. **Falls Pfad A:** Soll die Scoping-Direktive (keine bestehenden .liquid-Dateien
   aendern) fuer `mdm-multicolumn-icon.liquid` aufgehoben werden?

3. **Falls Pfad A:** Welche Icon-Strategie? Option 1 (`image_picker`, keine Farb-
   kontrolle), Option 2 (Icon-Select erweitern, globale Verschmutzung) oder Option 3
   (`custom_icon_asset` Textfeld, fehleranfaellig aber sauber)?

4. **Falls Pfad A:** Soll `mdm-help-topic-cards.liquid` samt CSS und SVG-Assets
   entfernt oder als Dead-Code belassen werden?

5. **Gap-Toleranz:** Ist 20px (f-grid `small`) statt 24px (Figma) akzeptabel,
   oder soll ein CSS-Override auf exakt 24px gesetzt werden?

---

## Definition of Done

- [ ] File-scoped `shopify theme check` clean (Baseline-Ausnahmen)
- [ ] Dev-MCP `validate_theme` passed
- [ ] Translations vollstaendig (en.default + de) -- im Theme-Editor keine rohen Keys
- [ ] Section hat Editor-Preset (bereits vorhanden bei beiden Pfaden)
- [ ] Responsive Verhalten definiert und visuell geprueft:
  - Desktop: 3-Spalten-Grid, Cards vertikal (Icon oben, Text zentriert)
  - Tablet: 2-Spalten-Grid (abhaengig von Settings)
  - Mobile: 1-Spalte, Cards horizontal (Icon links, Text links)
- [ ] Visuelle Paritaet mit Referenz-Screenshots (unter Beruecksichtigung der
  „maximal vererben"-Deviations)
- [ ] Alle 6 Kacheln klickbar (Stretched Link funktioniert)
- [ ] Kachel 6 zeigt „Kollektion" statt „Kollektion und Sammeln" auf Mobile
- [ ] Focus-Styling per Tastatur-Navigation sichtbar
