# Phase 5 abgeschlossen — Übersetzungen und Figma-Mapping-Update

Ticket: MDM-RETOURE-01 · Datum: 21. August 2026 · Letzte Plan-Phase

## Ergebnis

- Status: OK — bereit für Review

## Übersetzungs-Vollständigkeits-Check

- Schema-Keys (5 Stück, aus Phasen 1/2/4) paarig in `locales/en.default.schema.json:2889-2905`
  und `locales/de.schema.json:2889-2905` verifiziert: `sections.mdm-breadcrumbs.settings.parent_label.label/.info`,
  `.parent_url.label`, `.link_color.label`, `sections.mdm-page-title.name`. ✅ Belegt
- Frontend-Keys: KEINE nötig. `sections/mdm-page-title.liquid` enthält kein `| t`
  (nur `t:`-Schema-Referenzen, Zeilen 10/60); der neue page-Branch in
  `sections/mdm-breadcrumbs.liquid:66-75` nutzt ausschließlich vorbestehende Keys
  (`general.breadcrumbs.home`, vorhanden in `en.default.json:56` / `de.json:56`);
  `sections/mdm-collapsible-tabs.liquid:710-715` nutzt vorbestehende generische
  `t:general.custom_attr.*`-Keys (alle 6 Schema-Locales, Zeile 1007). Der
  Plan-Tabellen-Eintrag `sections.mdm_page_title.name` für en.default.json/de.json
  wurde daher NICHT angelegt (wäre toter Key). ✅ Belegt
- REGRESSION GEFUNDEN UND BEHOBEN: Die 5 neuen Schema-Keys fehlten in
  `locales/es|fr|it|vi.schema.json` → Theme-Check `MatchingTranslations` meldete
  je 5 neue Errors pro Datei (Gesamt 29E statt Baseline 9E). Keys in allen vier
  Dateien ergänzt (jeweils nach dem `breadcrumbs`-Eintrag, Zeile 2889-2905),
  Baseline exakt wiederhergestellt. Hinweis: Der dateibezogene PostToolUse-Hook
  hatte das in Phasen 1-4 nicht gemeldet, weil nur die editierten en/de-Dateien
  geprüft wurden.

## Neue/geänderte Dateien

- GEÄNDERT `assets/mdm-section-retoure-faq.css:45` — `font-family: var(--font-body-family)`
  in der gemeinsamen `.btn`-Regel ergänzt (deckt primary + secondary; Variable
  belegt in `snippets/css-variables.liquid:263`). Phase-4-Minor-Finding 1 umgesetzt.
- GEÄNDERT `locales/es.schema.json`, `locales/fr.schema.json`, `locales/it.schema.json`,
  `locales/vi.schema.json` — je 5 fehlende mdm-Keys ergänzt (Zeile 2889-2905),
  Übersetzungen in der jeweiligen Sprache.
- GEÄNDERT `.claude/skills/mdm-template/figma-mapping.md` — 6 Bestandszeilen auf
  ✅ verifiziert mit `path:line`-Belegen gehoben (breadcrumbs, accordion-item,
  btn-Klassen, h2.font-heading.h5, .rte, icon-plus-toggle; alte icon-plus.svg-Zuordnung
  als „❌ verworfen" dokumentiert), 4 neue Farb-Token-Zeilen (Stone-80/Stone-100/
  Prussian = Hex-Hardcode-Pattern, White = `--color-background`). Alle Belege
  in dieser Session gegen die Dateien spot-geprüft. Datei ist unversionierte
  KI-Arbeitskonfiguration.

## Validierung

- `shopify theme check -o json` (gesamtes Theme): 9 Errors / 20 Warnings —
  entspricht exakt der dokumentierten Baseline vom 21.08.2026 (es|fr|it|vi.json
  MatchingTranslations, ai_gen-Block, 20 Legacy-Warnings in unberührten Snippets).
  Alle Ticket-Dateien: 0 Errors, 0 Warnings.
- JSON-Parse OK: alle 6 Schema-Locales + en.default.json + de.json (Banner-Strip)
  + templates/page.retoure.json.
- Shopify Dev MCP `validate_theme`: VALID auf allen 12 Ticket-Dateien
  (3 Sections, Template-JSON, 2 CSS-Assets, 6 Schema-Locales).

## Handover Notes für Reviewer

- `assets/mdm-section-retoure-faq.css:45` — einzige CSS-Änderung dieser Phase.
- `locales/es.schema.json:2889-2905` (analog fr/it/vi) — neue Keys; Übersetzungen
  bitte sprachlich gegenprüfen (es/fr/it/vi sind im Shop nicht aktiv).
- Beobachtung (out of scope, vorbestehend): `de.json:56` übersetzt
  `general.breadcrumbs.home` mit „Heim" (Alt-Maschinenübersetzung). Das Design
  fordert „STARTSEITE" — Änderung wäre shopweit wirksam (alle Breadcrumbs) und
  braucht Konrads Entscheid. DoD-Punkt „Breadcrumbs zeigen Startseite" ist damit
  aktuell NICHT erfüllt, solange der Key „Heim" lautet.
- Beobachtung (vorbestehend, Phasen 1-4 approved): `sections/mdm-breadcrumbs.liquid:75`
  rendert `{{ page.title }}` ohne `| escape` — konsistent mit FoxEcom-Original,
  Security-Review hatte keine Findings.

## Unknowns

- ❌ `/pages/hilfe-service` existiert im Store? (Breadcrumb-Platzhalter, seit Phase 4)
- ❌ „Heim"→„Startseite" in `de.json:56`: shopweite Auswirkung, Konrad-Entscheid nötig
- ⚠️ Button-URLs `#briefmarke`/`#paketschein` Platzhalter gemäß Freigabe
