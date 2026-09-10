# Spec: Globale Brand-Overrides

## Ziel
Shopweite visuelle Anpassungen an das MDM-Brand-Design (Farben, Typografie, Radien, Badges).
Quelle: Design-Dateien der Designerin.

## Kontext
Zwei Branches: `feat/theme-settings` (Shopify Theme-Settings) und
`feat/global-css-overrides` (CSS-Overrides die ueber theme.css liegen).

## Anforderungen — Theme Settings (`settings_data.json`)
- [x] Farbschema: Prussian Blue (#002147) als Primary Accent
- [x] Badges: Sale (#B82E1F), Hot (#2C4767), New (#2D5F3F), Sold Out (#615B4F), Coming Soon (#B8922A)
- [x] Typografie: EB Garamond 500 fuer Headings, Inter fuer Body
- [x] Corner-Radii: square (statt round)
- [x] Produktkarten: Heading-Font mit Weight 500, Quickview aktiv
- [x] Logo-Breite Mobile: 80px (statt 90px)

## Anforderungen — CSS Overrides (`brand-overrides.css`)
- [x] Nav-Hover: Burgund (#82212E) fuer Links, Dropdowns, Mobile-Drawer
- [x] Topbar: 14px / Weight 500 (Inter Medium)
- [x] Focus-Visible matched Hover (Accessibility-Paritaet)
- [x] Spezifitaet: gewinnt gegen Nexvo-Defaults durch Cascade-Order

## Akzeptanzkriterien
- [x] Alle Farbwerte stimmen mit Brand-Dokument ueberein
- [x] Nav-Hover zeigt Burgund auf Desktop und Mobile
- [x] Keine visuellen Regressionen auf bestehenden Seiten (Startseite, Produkt, Collection)
- [x] `shopify theme check` ohne neue Errors

## Constraints
- Blast-Radius: SHOPWEIT — betrifft alle Seiten
- `brand-overrides.css` wird nach `theme.css` geladen (Layout-Include)
- Hyper-Kerndateien bleiben unangetastet

## Dateien
- `theme/config/settings_data.json` (Branch: `feat/theme-settings`)
- `theme/assets/brand-overrides.css` (Branch: `feat/global-css-overrides`)
- `theme/layout/mdm-theme.liquid` (Include der CSS-Datei)

## Status
IMPLEMENTIERT
