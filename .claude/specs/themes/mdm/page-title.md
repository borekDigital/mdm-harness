# Spec: Page Title (Neue Section)

## Ziel
Eigenstaendige Seitentitel-Section fuer Content-Seiten (Hilfe, Info-Seiten).

## Kontext
Hyper hat keinen separaten Page-Title-Block. Neue Section, da kein Override moeglich.
Wird von `page.hilfe.json` und `page.retoure.json` referenziert.

## Anforderungen
- [x] Rendert `page.title` als H1 mit Brand-Typografie
- [x] Unterstuetzt optionalen Untertitel (Schema-Setting)
- [x] Konsistentes Spacing mit Breadcrumbs darueber und Content darunter
- [x] Schema-Settings fuer Merchant-Anpassbarkeit

## Akzeptanzkriterien
- [x] `shopify theme check` ohne neue Errors
- [x] H1-Hierarchie korrekt (nur ein H1 pro Seite)
- [x] Responsive Typografie (Desktop/Mobile)

## Constraints
- KEINE Hyper-Basis (neue Section)
- Muss VOR page-hilfe-hub und page-retoure gemerged werden (Abhaengigkeit)

## Dateien
- `theme/sections/mdm-page-title.liquid`
- `theme/assets/mdm-section-page-title.css`
- Branch: `feat/section-page-title`

## Status
IMPLEMENTIERT
