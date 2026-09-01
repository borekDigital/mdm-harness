# Phase 2 abgeschlossen — Seitentitel-Section (mdm-page-title)

Ticket: MDM-RETOURE-01 · Datum: 21. August 2026

## Ergebnis

- Status: APPROVED (theme-reviewer ∥ security-reviewer, 0 Revisions-Loops)

## Neue/geänderte Dateien

- NEU `sections/mdm-page-title.liquid` — minimale H1-Section:
  `<h1 class="mdm-page-title__heading font-heading h1">{{ page.title | escape }}</h1>`,
  Wrapper `page-width page-width--{container} section--padding` mit
  `--section-padding-*`-Inline-Vars. Schema: `container` (Default narrow),
  `padding_top` (Default 0), `padding_bottom` (Default 36), Preset, `limit: 1`,
  `disabled_on` header/footer/aside + index.
- NEU `assets/mdm-section-page-title.css` — `color: #002147` (Prussian),
  `line-height: 1.2`; font-size/family bewusst über Hyper-Utilities `.h1`/`.font-heading`.
- `locales/en.default.schema.json:2900-2902` — `sections.mdm-page-title.name` = „Page title"
- `locales/de.schema.json:2900-2902` — „Seitentitel"

## Bewusste Interpretationen (von Reviewern als tragfähig bestätigt)

- padding-bottom 36 als Schema-Default statt CSS-Hardcode (`.section--padding`-Formel,
  kein Doppel-Padding; Desktop exakt 36px, Tablet 27px — Design definiert kein Mobile-Spacing).
- font-size nicht hardcodiert — `.h1` liefert `--font-h1-size` inkl. Mobile-Scale.

## Reviews

- theme-reviewer: APPROVED, keine Findings (7 Dimensionen geprüft, Visual Parity
  auf Code-Ebene gegen Referenz-PNG bestätigt).
- security-reviewer: APPROVED, keine Findings. Hinweis fürs Protokoll: range-Settings
  in Inline-Styles brauchen kein `| escape` (Shopify erzwingt Integer serverseitig).

## Validierung

- `shopify theme check`: 0 Offenses auf allen 4 Dateien
- Shopify Dev MCP `validate_theme`: SUCCESS

## Unknowns

- ❌ Effektiver `--font-heading-scale`-Wert im Live-Store — weicht er von 100 % ab,
  weicht die H1-Größe von 40px ab (Prüfung im Dev-Server bei Abnahme).
