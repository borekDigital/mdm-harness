# Phase 1 abgeschlossen — Breadcrumbs-Erweiterung

Ticket: MDM-RETOURE-01 · Datum: 21. August 2026

## Ergebnis

- Status: APPROVED (theme-reviewer ∥ security-reviewer, 1 Revisions-Loop)

## Geänderte Dateien

- `sections/mdm-breadcrumbs.liquid` — Zeile 68–73: optionales Eltern-Segment im page-Branch
  (rendert nur, wenn `parent_url` UND `parent_label` gesetzt sind; Chevron-Separator aus
  bestehendem Capture; Ausgabe von Label und URL jeweils mit `| escape`). Zeile 186–196:
  Schema-Settings `parent_label` (text, mit info) und `parent_url` (url).
- `locales/en.default.schema.json:2889-2899` — neue Keys `sections.mdm-breadcrumbs.settings.*`
- `locales/de.schema.json:2889-2899` — deutsche Pendants

## Reviews

- theme-reviewer: APPROVED. 2 Minor-Findings, nicht blockierend:
  1. `sections/mdm-breadcrumbs.liquid:75` — `aria-current="page"` fehlt am letzten
     Breadcrumb-Item (vorbestehende Lücke; Empfehlung: in Plan-Phase 4 nachziehen).
  2. Separator Chevron statt Pipe — per Freigabe-Entscheidung akzeptiert.
- security-reviewer: Revision 1 gefordert (fehlendes `| escape` auf `parent_url`,
  Zeile 70) → umgesetzt → APPROVED. Einordnung: `| escape` deckt Attribut-Breakout ab;
  `javascript:`-Protokollrisiko verbleibt im Merchant-Trust-Modell (alle url-Settings des
  Hyper-Themes identisch exponiert); theme-weiter Whitelist-Check wäre separate technische
  Schuld, kein Blocker.

## Validierung

- `shopify theme check`: 0 Offenses auf allen drei Dateien
- Shopify Dev MCP `validate_theme`: SUCCESS (3 Dateien, nach Revision erneut)

## Übergabe an Plan-Phase 4

- Stone-80-Farbfix (#6a6357 → #615b4f) nur für Retoure-Seite: Empfehlung des Implementers —
  optionales `color`-Setting `link_color` (Default `#6a6357`) in `mdm-breadcrumbs` ergänzen,
  das den bestehenden `{%- style -%}`-Block speist; nur in `page.retoure.json` auf `#615b4f`
  setzen. `custom_css` im Template-JSON ist plattform-verwaltet und wird nicht genutzt.
- `aria-current="page"` auf letztem Breadcrumb-Item ergänzen (Minor-Finding 1).
