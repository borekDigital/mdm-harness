# Phase 4 abgeschlossen — Template-JSON und Section-Verdrahtung

Ticket: MDM-RETOURE-01 · Datum: 21. August 2026

## Ergebnis

- Status: APPROVED (theme-reviewer ∥ security-reviewer, 0 Revisions-Loops)

## Neue/geänderte Dateien

- NEU `templates/page.retoure.json` — Layout `mdm-theme`, Order
  mdm_breadcrumbs → mdm_page_title → mdm_retoure_faq. Breadcrumbs:
  parent_label „Hilfe & Service", parent_url `/pages/hilfe-service` (Platzhalter),
  link_color `#615b4f` (Stone-80 nur hier), container narrow. FAQ: custom_class
  `mdm-retoure-faq`, 10 collapsible_item-Blöcke — Item 1 offen mit Richtext
  (2 Absätze + Widerrufsbelehrungs-Link) und custom_liquid (stylesheet_tag
  mdm-section-retoure-faq.css + Buttons `#briefmarke`/`#paketschein`);
  Items 2-10 mit Fragetexten aus der Design-Spec und Platzhalter-Antwort.
- GEÄNDERT `sections/mdm-breadcrumbs.liquid` — link_color-Setting (color,
  Default `#6a6357` = alter Hardcode, rückwärtskompatibel; Zeile 18/23 speist
  den style-Block), `aria-current="page"` am letzten Item (Zeile 75, page-Branch),
  Container-Option `narrow` additiv ergänzt (Zeile 163-166; Plan forderte narrow,
  Schema kannte nur full/fixed).
- `locales/en.default.schema.json:2898-2900` + `locales/de.schema.json:2898-2900` —
  link_color-Labels („Link color" / „Linkfarbe").

## Reviews

- theme-reviewer: APPROVED. Alle 10 Fragetexte exakt gegen Design-Spec verifiziert,
  alle Setting-IDs gegen Schemas verifiziert, Rückwärtskompatibilität belegt
  (product/collection-Templates nutzen mdm-breadcrumbs ohne link_color → Default
  = altes Verhalten). 2 Minor-Findings, nicht blockierend:
  1. Button font-family nicht explizit (erbt Body-Font = Inter; optional in Phase 5
     `font-family: var(--font-body-family)` ergänzen)
  2. mdm-collection-layout.css-Load in mdm-breadcrumbs ist Vorbestand (out of scope)
- security-reviewer: APPROVED, keine Findings. color-Setting-Typ serverseitig auf
  Farbwerte beschränkt (keine CSS-Injection); custom_liquid-Inhalt nur eigene Assets
  + Fragment-Anker; Richtext nur erlaubte Tags mit relativen URLs.

## Validierung

- JSON-Parse OK, `shopify theme check`: 0 Offenses (4 Dateien)
- Shopify Dev MCP `validate_theme`: VALID

## Test-Hinweis für Konrad

- Dev-Server: `http://127.0.0.1:9292/pages/retoure?view=retoure`
  (`?view=` nötig, solange das Template nicht im Admin zugewiesen ist —
  Dropdown zeigt nur Templates des veröffentlichten Themes)

## Unknowns

- ❌ Seite `/pages/hilfe-service` existiert im Store? (Breadcrumb-Platzhalter)
- ⚠️ Button-URLs Platzhalter gemäß Freigabe
- ⚠️ Visuelle Live-Parität (Border offenes Item, Stone-80-Wirkung) — bei Abnahme prüfen
