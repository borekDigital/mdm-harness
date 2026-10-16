# Spec: Kollektion — „Mehr anzeigen“ im Intro in Dunkelblau

## Ziel

Der Button „Mehr anzeigen“ / „Weniger anzeigen“ unter dem Kollektionstext erscheint in
demselben Dunkelblau (Prussian `#002147`) wie die Überschriften der Seite, nicht in
Fast-Schwarz.

## Grundlage

- Hinweis von Konrad am 15. Oktober 2026 zu `/collections/kollektionen`.

## Ursache — Ist-Stand `main` `50dd9bc`, Dev-Server Port 9292

| Fundstelle | Befund |
|---|---|
| `sections/mdm-main-collection-banner.liquid:169-175` | Toggle ist `button` mit `btn btn--underline read-more__toggle`, ohne eigene Farbklasse |
| `assets/theme.css` (Regel `button, .btn`) | `color: rgb(var(--color-foreground))` |
| `assets/theme.css:2308-2314` | Unterstreichung ist `::after` mit `background: currentColor` |
| `assets/brand-overrides.css:315-319, 376-392` und Regel `h1…h6, .h1…` | Überschriften sind explizit `#002147` gesetzt |

✅ Belegt im Dev-Server, 15. Oktober 2026:

| Element | Farbe |
|---|---|
| Seitentitel (`h1.collection-hero__title.h2`) | `rgb(0, 33, 71)` |
| Überschriften im Beschreibungstext (`h3`, `h4`) | `rgb(0, 33, 71)` |
| „Mehr anzeigen“ (`.read-more__toggle`) und seine Unterstreichung | `rgb(30, 28, 23)` = `--color-foreground` von `color-scheme-1` |
| „Mehr anzeigen“ in der Filterleiste (`.button-show-more.btn--link`) | `rgb(0, 33, 71)` (schon korrekt) |

Der Button erbt die Textfarbe des Farbschemas. Die Marken-Overrides färben Überschriften und
Links, aber keinen `btn--underline`-Button.

## Anforderungen

- [ ] R1 `.read-more__toggle` im Kollektions-Intro (`.mdm-collection-hero`) ist Dunkelblau,
      Text und Unterstreichung (beides folgt `currentColor`).
- [ ] R2 Farbe als `#002147`, wie bei den Überschriften in `brand-overrides.css`
      (Vorgabe Konrad: „soll auch #002147 bekommen“). Kein Token, damit Button und
      Überschriften gleich bleiben, auch wenn sich das Scheme ändert.
- [ ] R3 Beide Zustände („Mehr anzeigen“, „Weniger anzeigen“) und Hover bleiben lesbar.

## Akzeptanzkriterien

Gemessen auf dem Dev-Server, 1440 px und 375 px, per `getComputedStyle`.

- [ ] A1 `/collections/kollektionen`: Toggle-Text und `::after`-Unterstreichung
      `rgb(0, 33, 71)`. (R1, R2)
- [ ] A2 Nach Klick („Weniger anzeigen“) weiterhin `rgb(0, 33, 71)`. (R3)
- [ ] A3 Kollektionstext, Überschriften, Filter-„Mehr anzeigen“: Farben unverändert.
- [ ] A4 Kein Diff an `templates/*.json`; kein JS.
- [ ] A5 `shopify theme check`: keine neuen Findings gegenüber `main`; `validate_theme` VALID.

## Constraints

- Theme-First: Änderung in `assets/mdm-section-collection-hero.css` (wird von
  `mdm-main-collection-banner` geladen), Selektor `.mdm-collection-hero .read-more__toggle`.
  Keine Änderung an `theme.css` (FoxEcom-Kern) und keiner Section.
- Blast-Radius: alle Kollektionsseiten mit Kollektionstext und Read-more-Toggle im Intro
  (`collection.json`, `collection.mdm.json`). Andere `.read-more__toggle` (Rich-Text, PDP,
  Vergleichstabellen) bleiben unberührt.

## Offene Punkte

- O1 „Die Überschrift h2 müsste das sein“: gelesen als „so soll die Farbe der h2-Überschriften
  sein“. Falls gemeint ist, dass die Überschriften im Beschreibungstext `h2` statt `h3`
  sein sollen: das steht im Beschreibungs-HTML der Kollektion im Shopify-Admin
  (aktuell `h3`/`h4`, kein `h2`) und ist keine Theme-Änderung.

## Revision — 15. Oktober 2026, nach dem Call mit Bhavani Govindan

PR #46 (`3eb77f7`, Dunkelblau `#002147`) ist gemergt. Im Call hat Bhavani die Farbe neu
festgelegt; R2 ist damit ersetzt:

- [ ] R2′ Farbe ist die **Subtext-Farbe** des Farbschemas, `rgb(var(--color-subtext))`
      (`scheme-1`: `#3e3a32`). Begründung: „damit es nicht so stark ist — nicht stärker als
      der Text“. Kein fester Hex-Wert: Code nimmt die Variablen aus den Theme-Settings.
- [ ] R4 Beim Hover keine eigene Farbe; Feedback ist die Unterstreichungs-Animation.

Akzeptanz A1/A2 gelten mit `rgb(62, 58, 50)` statt `rgb(0, 33, 71)`, zusätzlich im
Hover-Zustand. Umsetzung im Branch `fix/collection-read-more-subtext`, gesamt geführt in
`../templates-angleichen-plp-pdp.md` (R0.1, R0.2).

## Validierung — 15. Oktober 2026

Branch `fix/collection-read-more-color` auf `main` `50dd9bc`, eigener Dev-Server Port 9294
(Port 9292 gehört zu einem anderen Worktree und lieferte die alte CSS aus). Änderung: nur
`assets/mdm-section-collection-hero.css` (+5 Zeilen).

| AC | Ergebnis |
|---|---|
| A1 | erfüllt — Text und `::after` `rgb(0, 33, 71)` (Viewport 1024 px) |
| A2 | erfüllt — nach Klick „Weniger anzeigen“ weiterhin `rgb(0, 33, 71)` |
| A3 | erfüllt — Titel, `h3`, Filter-„Mehr anzeigen“ unverändert `rgb(0, 33, 71)` |
| A4 | erfüllt — Diff nur in der CSS-Datei |
| A5 | offen — `theme check` lieferte keine auswertbare Zusammenfassung, `validate_theme` braucht Parameter, die nicht gesetzt wurden; reine CSS-Änderung |
