# Spec: Breadcrumbs (Section-Override)

## Ziel
Shopweite Breadcrumb-Navigation mit MDM-Brand-Styling, aligned an Page-Breite.

## Kontext
Override von Hyper `breadcrumbs.liquid`. Shopweit genutzt auf allen Seiten
mit `mdm-theme` Layout.

## Anforderungen
- [x] Zwei-Ebenen-Wrapper (aeusserer Container an Page-Breite, innerer an Content)
- [x] Breadcrumb-Pfad: Home > Kategorie > Aktuelle Seite
- [x] Letzte Ebene nicht verlinkt (aktuelle Seite)
- [x] Responsive: gleiche Struktur auf Mobile und Desktop
- [x] Alignment an Page, nicht an Content-Bereich

## Akzeptanzkriterien
- [x] `shopify theme check` ohne neue Errors
- [x] Breadcrumbs auf allen Seitentypen sichtbar (Product, Collection, Page)
- [x] Styling konsistent mit Brand-Overrides (Farben, Typografie)
- [x] Kein Bruch bestehender Seiten (Blast-Radius geprueft)

## Constraints
- Hyper-Basis: `sections/breadcrumbs.liquid`
- Blast-Radius: SHOPWEIT — jede Aenderung betrifft alle Seiten
- Designerin-Absprache 26.08.: Alignment an Page, nicht Content

## Dateien
- `theme/sections/mdm-breadcrumbs.liquid`
- `theme/assets/mdm-section-breadcrumbs.css`
- Branch: `feat/section-breadcrumbs`

## Status
IMPLEMENTIERT
