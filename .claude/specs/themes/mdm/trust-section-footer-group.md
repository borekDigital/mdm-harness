# Spec: Trust-Section zentral über die Footer-Gruppe

## Ziel

Die Trust-Section erscheint auf jeder Shop-Seite mit Footer, im Design der Startseite, und
wird an genau einer Stelle im Theme-Editor gepflegt. Die hartcodierte Trust-Variante der
Kollektionsseiten entfällt.

## Grundlage

- Ticket SHOP-2, Kriterium 5: „#3 TrustSection ist auf jeder Seite angezeigt. wird mit Design
  von Startseite automatich geleifert.“
- Auslegung durch Konrad am 13. Oktober 2026:
  1. Zentrale Quelle in der bestehenden Footer-Gruppe (Lesart B)
  2. Die eigene Trust-Instanz der Startseite entfällt
  3. Erstbefüllung mit den Texten der Startseite
- Vorarbeit: PR #34 (Merge-Commit `2d3f27c`), Prüfbericht vom 13. Oktober 2026

## Kontext — Ist-Stand origin/main `dc86009`

| Fundstelle | Befund |
|---|---|
| `sections/mdm-main-collection-banner.liquid:274-315` | Trust-Markup, vier Karten mit deutschen Texten direkt in Liquid |
| `sections/mdm-main-collection-banner.liquid:393-410` | Settings `show_trust_section`, `trust_eyebrow`, `trust_heading` |
| `assets/mdm-section-collection-hero.css:243-319, 349-401` | Trust-Regeln `.mdm-trust-*` (Desktop und mobil) |
| `templates/collection.json:159-184` | Section `mdm_bottom_sections_r4WkDz` „Vertrauens-Box“; `trust_*`-Keys zusätzlich in Z. 55-57 und 145-147 |
| `templates/collection.mdm.json:164-188` | gleiche Section; `trust_*`-Keys zusätzlich in Z. 48-50 und 150-152 |
| `templates/index.json:699` | `multicolumn_icon_kqg3wM`, Typ `multicolumn-icon` (Nexvo-Original), Position 9 von 14 |
| `sections/footer-group.json` | Reihenfolge: newsletter (aus), custom_liquid „Seit über 50 Jahren“, spacer, footer, mobile_sticky_bar (aus) |
| `sections/mdm-multicolumn-icon.liquid:210` | `disabled_on` nur `header` und `custom.overlay` — Footer-Gruppe erlaubt |
| `assets/mdm-component-multicolumn-card.css:140-251` | MDM-Zusätze aus dem Hilfe-Hub mit globalen Selektoren, u. a. Rahmen `#d6cab3` auf `.multicolumn-card:not(.color-scheme-inherit)` |
| `layout/mdm-theme.liquid:140`, `layout/theme.liquid:131` | rendern `footer-group` — 77 Templates (alle außer `password`) |

Startseiten-Instanz heute: Scheme `scheme-inverse` für Section und Karten, 4 Punkte im
2×2-Raster (`columns_desktop: 2`), mobil 1 Spalte mit Swipe, Icon `check`, Überschrift
„Darauf können Sie sich verlassen“ (h2), Abstand oben 32 px, unten 64 px.

## Anforderungen

### Trust-Section

- [ ] R1 Die Footer-Gruppe enthält genau eine Trust-Section, als erste Section, oberhalb des
      Blocks „Seit über 50 Jahren“.
- [ ] R2 Die Section ist eine `mdm-`-Kopie, kein Nexvo-Original.
- [ ] R3 Design wie auf der Startseite: alle Section- und Block-Settings von
      `multicolumn_icon_kqg3wM` werden übernommen.
- [ ] R4 Inhalt bei Erstbefüllung: Überschrift und die vier Punkte der Startseite in heutiger
      Reihenfolge und mit heutigem Wortlaut. Danach ist der Inhalt Editor-Inhalt.
- [ ] R5 Im Theme-Editor heißt die Section „Vertrauens-Box“, ist in der Footer-Gruppe
      bearbeitbar sowie ein- und ausschaltbar. Eine Änderung wirkt auf allen Seiten.

### Startseite

- [ ] R6 `templates/index.json` enthält `multicolumn_icon_kqg3wM` nicht mehr. Alle übrigen
      Sections, Settings und die Reihenfolge bleiben unverändert.

### Kollektionsseiten

- [ ] R7 `collection.json` und `collection.mdm.json` enthalten keine Trust-Section mehr.
      Alle übrigen Sections, Settings und die Reihenfolge entsprechen origin/main zum
      Zeitpunkt der Umsetzung.
- [ ] R8 In beiden Templates gibt es keine Keys `show_trust_section`, `trust_eyebrow`,
      `trust_heading` mehr.

### Banner-Section

- [ ] R9 `mdm-main-collection-banner` rendert kein Trust-Markup mehr und hat keine Settings
      `show_trust_section`, `trust_eyebrow`, `trust_heading`.
- [ ] R10 Die Regeln `.mdm-trust-*` sind aus dem CSS entfernt. Hero und Verwandte Kategorien
      bleiben unverändert.

### Keine Nebenwirkungen

- [ ] R11 Andere Multicolumn-Sections ändern ihr Aussehen nicht dadurch, dass die
      Trust-Section ihr CSS jetzt auf jeder Seite lädt. Bekannte Kandidaten: `page.faq.json`
      (Karten-Scheme ungleich Section-Scheme), `list-collections.json` (`/collections`).
- [ ] R12 Der Hilfe-Hub (`page.hilfe.json`, Stretched Links, Responsive-Flip) bleibt
      unverändert.

## Akzeptanzkriterien

Gemessen auf dem Dev-Server (Store `mdm-muenze`, Port 9292), Desktop 1440 px und mobil
375 px, Referenzwerte vorher auf main.

- [ ] A1 `/collections/deutschland-muenzen`, `/collections/neuheiten` und
      `/collections/neuheiten?view=mdm`: Trust-Section genau einmal, direkt über
      „Seit über 50 Jahren“; `.mdm-trust-section` kommt im DOM nicht vor. (R1, R7, R9)
- [ ] A2 Startseite: Trust-Section genau einmal, über dem Footer; nach dem Rich-Text-Block
      keine Trust-Section mehr. (R1, R6)
- [ ] A3 Eine Seite ohne Trust heute (Produktseite) zeigt die Trust-Section genau einmal
      über dem Footer. (R1)
- [ ] A4 Design-Parität Kollektionsseite gegen Startseite vorher: Hintergrund- und
      Textfarbe, Schriftgröße der Überschrift, Icon-Größe und -Farbe, Spaltenzahl,
      Spaltenabstand, Section-Abstände. Toleranz 1 px. (R3)
- [ ] A5 Maschineller JSON-Vergleich: Settings, Blocks und `block_order` der neuen Section
      gleich `multicolumn_icon_kqg3wM`, ausgenommen Typ, ID und Name. (R3, R4)
- [ ] A6 Theme-Editor: Section „Vertrauens-Box“ in der Footer-Gruppe sichtbar, Text
      änderbar, ausschaltbar. (R5)
- [ ] A7 `/pages/faq` und `/collections`: Rahmen, Größe und Position der Multicolumn-Karten
      vorher und nachher gleich (`getComputedStyle`, `getBoundingClientRect`).
      `/pages/hilfe`: Kachel-Geometrie und Klickfläche unverändert. (R11, R12)
- [ ] A8 `deutschland-muenzen`: Hero mit „Mehr anzeigen“ klappt auf und zu, 12 Chips in
      Verwandte Kategorien. (R10)
- [ ] A9 Suche nach `trust_` und `mdm-trust` in `sections/`, `assets/`, `templates/` ohne
      Treffer. (R8, R9, R10)
- [ ] A10 JSON-Diff von `index.json`, `collection.json`, `collection.mdm.json` und
      `footer-group.json` gegen origin/main zeigt nur die spezifizierten Änderungen; alle
      Dateien parsen nach Entfernen des Kommentar-Banners. (R6, R7)
- [ ] A11 `shopify theme check` als JSON im sauberen Worktree, Branch gegen main: keine
      neuen Findings (Ausgangswert 37 Errors, 22 Warnings).
- [ ] A12 `validate_theme` ohne Fehler für alle geänderten Dateien.
- [ ] A13 Keine neuen hartcodierten Farbwerte, keine neuen Texte in Liquid, kein neues
      globales JS.

## Constraints

- Theme-First: Basis ist Nexvo `multicolumn-icon.liquid`, Override ist das bestehende
  `sections/mdm-multicolumn-icon.liquid`. Keine neue Section, keine neue Section Group, keine
  Layout-Änderung.
- Blast-Radius: shopweit, 77 Templates. Nach dem Merge sofort live (main per
  GitHub-Integration synchron).
- `footer-group.json`, `index.json`, `collection.json` und `collection.mdm.json` werden vom
  Theme-Editor und vom shopify[bot] beschrieben: auf aktuellem origin/main aufsetzen, vor dem
  PR erneut fetchen und vergleichen, Live-Werte nie überschreiben.
- Trust-Inhalte sind Editor-Inhalt (Block-Settings). Neue Locale-Keys nur für Schema-Labels,
  im Namespace `mdm.*`, in `en.default` und `de` paarig.
- Ein PR, ein Thema: Branch von origin/main, PR gegen main.
- Nur MDM-Theme. Borek und IMM sind nicht Teil dieser Spec.

## Nicht Teil dieser Spec

- Umstellung weiterer Original-Referenzen auf `mdm-`-Kopien (33 Stellen in Templates,
  Footer-Gruppe)
- Findings F2, F4, F6, F7 aus der Prüfung von PR #34
- Textdoublette „Geprüfte Qualität“ und „Echtheitsgarantie“ — Inhaltsfrage an die Fachseite
- Verwaiste Color Schemes (`scheme-9`, `scheme-10`)
- Ausnahmen für einzelne Seiten (Warenkorb, Kundenkonto, 404)

## Offene Punkte

- O1 Sind `page.faq.json` und `list-collections.json` im Store live zugewiesen? Nur im Store
  prüfbar; entscheidet, wie dringend R11 ist, nicht ob es gilt.

## Validierung — 13. Oktober 2026

Branch `feat/trust-section-footer-group` auf origin/main `dc86009`, Dev-Server vorher (main)
und nachher (Branch) auf demselben Dev-Theme.

| AC | Ergebnis |
|---|---|
| A1–A3 | erfüllt — Trust genau einmal, direkt vor „Seit über 50 Jahren“, auf Kollektionen, `?view=mdm`, Startseite, Produkt, Warenkorb, Suche, Hilfe, Blog, 404 |
| A4 | erfüllt — Desktop: bei gleicher Scrollbar identisch; mobil 375 px exakt gleich wie Startseite vorher |
| A5, A9, A10 | erfüllt — maschineller JSON-Vergleich gegen origin/main |
| A6 | offen — Theme-Editor nicht geprüft |
| A7, A8 | erfüllt — Karten auf FAQ-Template und `/collections` unverändert; Hilfe-Kacheln und Stretched Links unverändert; Read-more 73 → 405 → 73 px, 12 Chips |
| A11, A12 | erfüllt — 37 Errors / 22 Warnings auf main und Branch, keine neuen Findings; `validate_theme` gültig |
| A13 | erfüllt |

Korrektur zu R11: Der befürchtete Rahmen auf Nexvo-Multicolumns tritt heute auf keiner
geprüften Seite auf. Verwaiste oder leere Karten-Schemes rendern zur Laufzeit als
`color-scheme-inherit`. Das Scoping in `mdm-component-multicolumn-card.css` wirkt vorbeugend
(greift erst, wenn jemand einer Nexvo-Multicolumn ein abweichendes Karten-Scheme gibt).

Neuer Befund außerhalb dieser Spec: `assets/brand-overrides.css:615-619` färbt
`.rich-text__text` hart `#3E3A32`. Auf der navy Trust-Section ergibt das 1,42:1 Kontrast
(Scheme-eigener Subtext `#d6cab3`: 9,9:1). Besteht seit PR #8 auf der Startseite, gilt mit
dieser Spec auf allen Seiten.

## Status

IMPLEMENTIERT — 13. Oktober 2026 (Reviews APPROVED; A6 offen)
