# Visual-QA-Nachbesserung Runde 4 abgeschlossen — zwei Divider-Linien entfernt

Ticket: MDM-RETOURE-01 · Datum: 24. August 2026

## Ergebnis

- Status: APPROVED (theme-reviewer ∥ security-reviewer, 0 Revisions-Loops, 0 Findings)
- Auslöser: Konrad meldete per markiertem Screenshot zwei horizontale Linien, die es im
  Figma-Design nicht gibt. (Die zuvor vermuteten „stale render"-Abweichungen — STARTSEITE, Pipe —
  waren nach Reload korrekt; übrig blieben zwei echte, im Design nicht vorgesehene Linien.)

## Behobene Abweichungen

1. **Feine Linie unter den Breadcrumbs (zwischen Breadcrumbs und H1).**
   Ursache: `border-bottom: 0.1rem solid #ece7de` auf `.mdm-breadcrumbs-{{ section.id }}` —
   ORIGINAL-Bestand von `mdm-breadcrumbs` (per `git diff HEAD` verifiziert, nicht aus diesem
   Ticket), wirkt SHOPWEIT (product/collection/etc.).
   Fix: NICHT global entfernt, sondern per neuem Section-Setting `show_divider` (checkbox,
   Default `true` = rückwärtskompatibel) abschaltbar gemacht; der border-bottom-Regelblock ist
   in `{%- if section.settings.show_divider -%}` gewrappt. Auf `page.retoure.json`
   `show_divider: false` gesetzt. Alle anderen Templates behalten die Linie unverändert.

2. **Dunkle Linie über dem ersten FAQ-Item.**
   Ursache: `.mdm-retoure-faq .accordion-parent > .accordion-item:first-child
   .accordion-details__summary { border-block-start: 0.1rem solid #3e3a32; }` in
   `mdm-section-retoure-faq.css` (scoped, nur diese Seite).
   Fix: Regelblock ersatzlos gelöscht. Die Bottom-Border je Item (Trennlinie UNTER jeder Frage,
   im Figma gewollt) bleibt erhalten.

## Geänderte Dateien

- `sections/mdm-breadcrumbs.liquid` — neues Setting `show_divider` (checkbox, default true),
  border-bottom bedingt gerendert
- `templates/page.retoure.json` — `show_divider: false`
- `assets/mdm-section-retoure-faq.css` — first-child-Top-Border entfernt
- `locales/en.default.schema.json` + `locales/de.schema.json` — Setting-Label `show_divider`

## Validierung

- `shopify theme check -o json`: 0 Offenses für alle geänderten Dateien
- theme-reviewer: Rückwärtskompatibilität shopweit über `default: true` abgesichert; Bottom-Border
  je Item erhalten; `{% if %}` in `{% style %}` strict-parse-sauber
- security-reviewer: `show_divider` ist Boolean, nur als Kontrollfluss-Bedingung genutzt, kein
  interpolierter Output; keine externen Ressourcen, keine Secrets

## Prozess-Lehre

Bestätigt die neuen Checklisten-Regeln (Runde-2/3-Härtung): bei Datei ↔ Screenshot-Widerspruch
erst die Render-Quelle klären (STARTSEITE/Pipe waren nur stale); bewusst gesetzte optische Elemente
— hier der ererbte shopweite Breadcrumb-Border — explizit gegen das Design abgleichen, statt
„Bestand = korrekt" anzunehmen. Blast-Radius eines ererbten Stils immer prüfen und per
rückwärtskompatiblem Setting scopen, nie global entfernen.
