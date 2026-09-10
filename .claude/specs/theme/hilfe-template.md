# Spec: Hilfe-Unterseiten-Template (Blaupause)

## Ziel
Ein wiederverwendbares Template fuer alle Hilfe-Unterseiten (Retoure, Versand, etc.).
Wird einmal als Code gebaut, danach pflegt der Merchant die Inhalte im Shopify-Admin.

## Kontext
Die Retoure-Seite (`page.retoure.json`) dient als Referenz-Implementierung.
Weitere Unterseiten (Versand, Bezahlung, etc.) werden im Admin nach diesem Muster angelegt
— kein zusaetzlicher Code noetig.

## Anforderungen
- [x] Section-Reihenfolge: Breadcrumbs → Page Title → FAQ (Collapsible Tabs) → optional: Teaser
- [x] Collapsible Tabs als Override von Hyper `collapsible-tabs.liquid`
- [x] Merchant kann Fragen/Antworten im Admin pflegen (Schema-Blocks)
- [x] Seitenlokales CSS ueber `mdm-page-<suffix>.css` moeglich
- [x] Layout: `mdm-theme`

## Akzeptanzkriterien
- [x] `shopify theme check` ohne neue Errors
- [x] Collapsible Tabs oeffnen/schliessen korrekt (Accessibility: aria-expanded)
- [x] Merchant kann neue FAQ-Eintraege hinzufuegen ohne Code-Aenderung
- [x] Template ist zuweisbar im Shopify-Admin (Pages → Template-Auswahl)

## Constraints
- Hyper-Basis fuer FAQ: `sections/collapsible-tabs.liquid`
- Neue Unterseiten: nur im Admin anlegen, Template zuweisen, Inhalte pflegen
- KEIN neuer Code pro Unterseite — das ist der Kern dieser Spec

## Dateien
- `theme/sections/mdm-collapsible-tabs.liquid`
- `theme/assets/mdm-section-retoure-faq.css`
- `theme/assets/mdm-page-retoure.css`
- `theme/templates/page.retoure.json`
- Branch: `feat/page-retoure`

## Status
IMPLEMENTIERT
