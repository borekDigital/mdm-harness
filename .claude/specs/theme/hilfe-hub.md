# Spec: Hilfe-Hub Einstiegsseite

## Ziel
Zentrale Hilfe-Einstiegsseite mit Icon-Kacheln, die zu den einzelnen Hilfe-Unterseiten verlinken.

## Kontext
Nutzt `mdm-multicolumn-icon` (neue Section, da Hyper-Multicolumn keine Inline-Icons
mit Slug-Pattern unterstuetzt). Template: `page.hilfe.json`.

## Anforderungen
- [x] Icon-Kacheln mit Stretched Links (ganze Kachel klickbar)
- [x] Responsive Flip (Desktop: Raster, Mobile: Liste)
- [x] Inline-Icons ueber Slug-Pattern (Merchant gibt "hilfe-bestellung", Code baut "mdm-icon-hilfe-bestellung.svg")
- [x] 6 initiale Kategorien: Bestellung, Bezahlung, Versand, Retoure, Kundendaten, Kollektion

## Akzeptanzkriterien
- [x] `shopify theme check` ohne neue Errors
- [x] Alle 6 Icons laden korrekt
- [x] Kacheln verlinken auf die jeweilige Unterseite
- [x] Responsive Layout funktioniert (Mobile und Desktop)
- [x] Merchant kann Kacheln im Admin hinzufuegen/entfernen/umsortieren

## Constraints
- Hyper-Basis: `multicolumn.liquid` (konzeptionell, aber neue Section wegen Icon-Slug-Pattern)
- Template `page.hilfe.json` nutzt Layout `mdm-theme`
- Preview: `?view=hilfe` erzwingt Template ohne Admin-Zuweisung

## Dateien
- `theme/sections/mdm-multicolumn-icon.liquid`
- `theme/assets/mdm-component-multicolumn-card.css`
- `theme/assets/mdm-icon-hilfe-*.svg` (6 Icons)
- `theme/templates/page.hilfe.json`
- Branch: `feat/page-hilfe-hub`

## Status
IMPLEMENTIERT
