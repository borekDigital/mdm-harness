# Spec: Section-Überschriften — Standardgröße „Überschrift xl“

## Ziel

Neu hinzugefügte Sections starten mit der Überschriftengröße „Überschrift xl“ (`h2`) statt
„Überschrift 2xl“ (`h1`). Damit gilt die in shopifyFrontend_MDM#44 vereinbarte Regel „Section-Überschriften
sind xl, nur der Seitentitel ist 2xl“ auch für Sections, die künftig im Theme-Editor
hinzukommen.

## Grundlage

- PR borekDigital/shopifyFrontend_MDM#44 „Überschriften: feste Größen entfernt,
  Nexvo-Skala überall“: Bhavani bestätigt am 14. Oktober 2026, dass alle
  Section-Überschriften einheitlich „Überschrift xl“ sein sollen.
- Verbesserungsvorschlag im selben PR vom 16. Oktober 2026 (Kommentar 6215905517).
- Umsetzung: borekDigital/shopifyFrontend_MDM#54 (Branch `feature/heading-default-xl`,
  Commit `722eea8`).

## Ist-Stand — origin/main `0da6653`

### ✅ Belegt: Sechs `mdm-`-Sections haben `h1` als Standard

Das Section-Setting `heading_size` steht im Schema auf `"default": "h1"`:

| Section | Zeile |
|---|---|
| `sections/mdm-product-faq.liquid` | 237 |
| `sections/mdm-recently-viewed-products.liquid` | 373 |
| `sections/mdm-related-products.liquid` | 363 |
| `sections/mdm-collapsible-tabs.liquid` | 370 |
| `sections/mdm-collection-list-slider.liquid` | 266 |
| `sections/mdm-featured-collection.liquid` | 440 |

„Überschrift 2xl“ = `h1`, „Überschrift xl“ = `h2` (`locales/de.schema.json`,
`general.text_size.options__h1/__h2`).

### ✅ Belegt: Kein platzierter Abschnitt nutzt den Standardwert

In allen Templates und Section-Gruppen von MDM, Borek und IMM (19 Dateien mit Instanzen
dieser sechs Sections) speichert jede Instanz `heading_size` ausdrücklich. Keine Instanz
fällt auf den Schema-Standard zurück.

### ✅ Belegt: Die Sections sind in allen drei Themes identisch

Die sechs Dateien sind in `themes/borek` und `themes/imm` auf `origin/main` byte-gleich
mit MDM und werden über `bin/theme-sync.sh align` (Workflow `theme-sync.yml`,
`THEME_SYNC_ENABLED = true`) übertragen.

## Anforderungen

- [ ] A1: In den sechs Sections steht der Standard von `heading_size` auf `h2`.
- [ ] A2: Block-Settings gleichen Namens (z. B. in `mdm-product-faq`) bleiben unverändert.
- [ ] A3: Keine weiteren Änderungen, keine FoxEcom-Kerndatei angefasst.

## Akzeptanzkriterien

- [ ] K1: Je Datei genau eine geänderte Zeile (`"default": "h1"` → `"default": "h2"`).
- [ ] K2: `shopify theme check --fail-level error` meldet für die sechs Dateien keinen neuen
  Fehler gegenüber `origin/main`.
- [ ] K3: Wird im Theme-Editor eine der sechs Sections neu hinzugefügt, steht
  „Überschriftengröße“ auf „Überschrift xl“ (Smoke-Test auf dem Staging-Theme).
- [ ] K4: Bestehende Seiten (PDP, FAQ-Seite, Kollektionsseiten) sehen unverändert aus.

## Constraints

- Nur `mdm-`-Kopien, update-sicher (Theme-First).
- Blast-Radius: nur neu hinzugefügte Sections. ⚠️ Vermutung, nicht in der Shopify-Doku
  belegt: Ein im Template gespeicherter Wert hat Vorrang vor dem Schema-Standard. Die
  Doku beschreibt `default` nur als „Standardwert des Settings“. K4 prüft das.
- Bestehende Instanzen stellt Bhavani im Theme-Editor um (shopifyFrontend_MDM#44, Punkt 4) — nicht Teil
  dieser Spec.
- Unabhängig von shopifyFrontend_MDM#44: keine gemeinsamen Dateien, Merge-Reihenfolge beliebig.
