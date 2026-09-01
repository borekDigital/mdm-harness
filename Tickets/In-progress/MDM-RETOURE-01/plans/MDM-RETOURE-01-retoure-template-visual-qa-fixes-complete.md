# Visual-QA-Nachbesserung abgeschlossen — 3 Abweichungen behoben

Ticket: MDM-RETOURE-01 · Datum: 24. August 2026

## Ergebnis

- Status: APPROVED (theme-reviewer ∥ security-reviewer, 0 Revisions-Loops, 0 Findings)
- Auslöser: Live-Test durch Konrad am Dev-Server (`?view=retoure`), Abgleich gegen
  Figma-Frame 4030-221 (Detail-View)

## Behobene Abweichungen

1. **Button-Hover — Label verschwand.** Ursache: Hyper zeichnet den Hover-Slide über ein
   `::before` (z-index 0, `assets/theme.css:2225-2239`); das Label bleibt nur sichtbar, wenn es
   in `<span class="btn__text">` liegt (z-index 1, `assets/theme.css:2240-2246`). Im
   `custom_liquid` standen die Labels nackt im `<a>`. Fix: beide Labels in `.btn__text` gewrappt
   (`templates/page.retoure.json:33`). Hover-Farbumkehr (`assets/theme.css:2434-2455`) greift nun
   korrekt: primary Slide weiß/Text Prussian, secondary Slide Prussian/Text weiß.
2. **Unterstrich unter Button-Labels.** Ursache: Buttons liegen im `.rte`; `.rte a` unterstreicht
   (`assets/theme.css:1822-1826`), `.btn` setzt kein `text-decoration: none`. Fix:
   `text-decoration: none` auf `.mdm-retoure-faq .accordion-details__content .btn`
   (`assets/mdm-section-retoure-faq.css`). Inline-Links (`a:not(.btn)`) bleiben unterstrichen.
3. **Fragen-Schriftgröße 25,92px statt 18px.** Ursache: `.h5`-Utility skaliert via
   `calc(--font-heading-scale * --font-h5-size)`. Design-Spec Zeile 47 fordert 18px/1.55. Fix:
   `font-size: 1.8rem; line-height: 1.55;` auf `.mdm-retoure-faq .accordion-details__summary h2`.
   Font-weight bewusst nicht angefasst (`.font-heading` erzwingt weight per !important; optisch
   deckungsgleich mit Design-Medium).

## Geänderte Dateien

- `templates/page.retoure.json` — Block item_1 custom_liquid: `.btn__text`-Wrapper
- `assets/mdm-section-retoure-faq.css` — h2 font-size/line-height; `.btn` text-decoration none

## Validierung

- `shopify theme check`: 0 Offenses (beide Dateien), Baseline 9E/20W unverändert
- Shopify Dev MCP `validate_theme`: VALID
- JSON-Parse OK (custom_liquid korrekt escaped)

## Prozess-Prävention (Claude-Files, nicht im Theme-Repo)

Damit diese Fehlerklassen künftig vor dem Live-Test auffallen:
- `.claude/skills/figma-to-liquid/SKILL.md` — neuer Abschnitt „Hyper-Fallstricke" (btn__text-Pflicht,
  RTE-Underline, `.h5`-Skalierung)
- `.claude/skills/mdm-template/qa-checklist.md` — Visual Parity: effektive px statt Utility-Klasse;
  neuer Block „Hyper-Komponenten-Fallstricke" inkl. Interaktionszustand-Prüfung (Hover/Focus lesbar,
  rein statisches Code-Review kann Render-State-Bugs übersehen → Live-Prüfung empfehlen)
- `.claude/skills/mdm-template/figma-mapping.md` — Button- und `.h5`-Zeile mit Fallstricken angereichert

## Unknowns (unverändert offen)

- ⚠️ Button-Ziel-URLs weiter Platzhalter `#briefmarke`/`#paketschein`
- ❌ `/pages/hilfe-service` existiert im Store?
- ⚠️ Antworttexte Items 2-10 redaktionell offen
- ⚠️ de.json `general.breadcrumbs.home` „Heim" vs. Design „STARTSEITE" (shopweit)
