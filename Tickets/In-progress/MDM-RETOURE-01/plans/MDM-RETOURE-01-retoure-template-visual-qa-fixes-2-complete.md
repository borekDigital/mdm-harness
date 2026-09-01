# Visual-QA-Nachbesserung Runde 2 abgeschlossen — Button-Textfarben behoben

Ticket: MDM-RETOURE-01 · Datum: 24. August 2026

## Ergebnis

- Status: APPROVED (theme-reviewer ∥ security-reviewer, 0 Revisions-Loops, 0 Findings)
- Auslöser: Live-Test durch Konrad — Button-Textfarben stimmten in zwei States nicht:
  blauer (primary) Button hatte im Default keine weiße Schrift, weißer (secondary)
  Button bekam beim Hover keine weiße Schrift.

## Behobene Abweichung

**Button-Textfarbe wurde von der RTE-Link-Farbe überschrieben.** Die Buttons liegen im
`.accordion-details__content` (= `.rte`). Runde 1 setzte zwar die korrekten CSS-Variablen
(`--color-button-text` etc.), aber `.rte a` (`assets/theme.css:1822`, Spezifität 0,1,1) und
`.rte a:hover` (`assets/theme.css:1829`, 0,2,1) schlagen die button-eigenen `color`-Regeln
`.btn--primary`/`.btn--secondary` (0,1,0) bzw. deren `:hover` (0,1,1). Die effektive Textfarbe
blieb daher die RTE-Link-Farbe statt der Button-Farbe — die Variablen allein greifen nicht.

Fix: explizite `color`-Deklarationen am Scope
`.mdm-retoure-faq .accordion-details__content .btn--primary`/`.btn--secondary` (inkl. `:hover`),
Spezifität 0,3,0 bzw. 0,4,0, die `.rte a`/`.rte a:hover` überstimmen. Werte spiegeln die
theme-eigenen Regeln (`assets/theme.css:2262-2272` default, `:2434/:2437` hover).

Effektive Kaskade (vom theme-reviewer per Spezifität durchgerechnet):
- primary default → `rgb(var(--color-button-text))` = weiß ✅
- primary hover → `rgb(var(--color-button))` = Prussian ✅
- secondary default → `rgb(var(--color-secondary-button-text))` = Prussian ✅
- secondary hover → `rgb(var(--color-button-text))` = weiß ✅

## Geänderte Dateien

- `assets/mdm-section-retoure-faq.css` — explizite `color` (default + `:hover`) für
  `.btn--primary` und `.btn--secondary`

## Validierung

- `shopify theme check -o json`: 0 Offenses für die Datei
- Kontrast weiß/Prussian #002147: 18,1:1 (WCAG AA ✓)
- security-reviewer: reine statische CSS-Farbregeln, keine externen Ressourcen, keine Findings

## Root-Cause-Lehre (warum es 2× durchrutschte)

1. **Figma-Bearbeitung:** Der Fix Runde 1 vertraute darauf, dass gesetzte CSS-Variablen die
   Textfarbe bestimmen — ohne die effektive Kaskade im `.rte`-Kontext durchzurechnen.
2. **Screenshot-Review:** Statisches Code-Review prüfte die Variablen-Präsenz, nicht die per
   Spezifität tatsächlich gewinnende Regel je State. Hover ist zudem ein Render-State, den
   Standbild-Review nicht sieht.

→ Prozess-Prävention wurde allgemein (prinzipienbasiert) in die Claude-Files eingearbeitet,
  siehe separates Artefakt zur Verallgemeinerung + Designer-Handoff-Empfehlungen.
