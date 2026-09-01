# Visual-QA-Nachbesserung Runde 5 abgeschlossen — Padding (Breadcrumbs + FAQ-Inhalt)

Ticket: MDM-RETOURE-01 · Datum: 24. August 2026

## Ergebnis

- Status: APPROVED (theme-reviewer ∥ security-reviewer, 0 Revisions-Loops, 0 Findings)
- Auslöser: Konrad meldete per zwei Figma-Dev-Mode-Screenshots (mit Pixel-Annotationen) zwei
  Padding-Werte, die im Design definiert, aber nicht umgesetzt waren.

## Behobene Abweichungen (beide in design-spec.md belegt)

1. **Breadcrumb-Bereich padding-y = 28 px.** (design-spec.md Z. 57: „Zurück-Bereich Höhe 73 px,
   padding-y 28 px".) Umsetzung stand auf 20/20; das Schema-`range` in `mdm-breadcrumbs.liquid`
   hatte `max: 24` und blockierte den 28er-Wert.
   Fix: Schema-`max` bei `padding_top` und `padding_bottom` von 24 auf 40 angehoben (Default-Werte
   16/20 unverändert), danach in `page.retoure.json` 28/28 gesetzt.
2. **FAQ-Inhalt padding-bottom = 16 px.** (design-spec.md Z. 177: „padding-bottom innerhalb
   accordion-item 16 px".) Die Hyper-Basisregel `.accordion-standard .accordion-details__content`
   (`assets/section-collapsible-tabs.css:32-34`) rendert nur `padding: 1.6rem 0 0` — also
   padding-top 16 px, padding-bottom 0.
   Fix: In `mdm-section-retoure-faq.css` `padding-bottom: 1.6rem` auf `.mdm-retoure-faq
   .accordion-details__content` ergänzt (gleiche Spezifität wie Basisregel, später in Ladereihenfolge
   → gewinnt; padding-top 16 px bleibt erhalten).
3. **Absatz-Gap im FAQ-Inhalt = 16 px.** (design-spec.md Z. 61: „Gap zwischen Inhalt-Absätzen
   16 px"; per Figma-Dev-Mode-Screenshot nachgemeldet.) Die Hyper-Basis `.rte p`
   (`assets/theme.css:1734-1743`) setzt `margin: var(--paragraph-*-spacing, 1.2rem)`; benachbarte
   Absatz-Margins kollabieren auf 12 px.
   Fix: In `mdm-section-retoure-faq.css` `--paragraph-top-spacing` und `--paragraph-bottom-spacing`
   auf `1.6rem` gesetzt (vererbt auf `.rte p`; Margins kollabieren zu 16 px; `p:first-child`/
   `p:last-child` mit margin 0 bleiben erhalten). Scope bleibt auf `.mdm-retoure-faq`.

## Geänderte Dateien

- `sections/mdm-breadcrumbs.liquid` — Schema-`max` padding_top/padding_bottom 24 → 40
- `templates/page.retoure.json` — Breadcrumb padding_top/padding_bottom 20/20 → 28/28
- `assets/mdm-section-retoure-faq.css` — `.accordion-details__content` padding-bottom 1.6rem
  + Absatz-Gap-Variablen (`--paragraph-top-spacing`/`--paragraph-bottom-spacing` 1.6rem)

## Validierung

- `shopify theme check -o json`: 0 Offenses für alle 3 geänderten Dateien
- JSON valide; padding-Werte 28 innerhalb des neuen Range [0, 40]
- theme-reviewer: Spezifität der scoped padding-bottom-Regel gewinnt gegen Hyper-Basis
  (gleich spezifisch, spätere Ladereihenfolge); padding-top 16 px erhalten; Blast-Radius des
  max-Anhebens null — alle anderen Templates (product/collection-Varianten) liegen mit 8–20 px
  weit unter 40, reine Range-Relaxierung ändert keinen bestehenden Computed-Wert
- security-reviewer: rein numerische Änderungen (CSS-Länge, Schema-Range-Max, JSON-Integer),
  kein neuer Ausgabe-Pfad, keine externen Ressourcen, keine Secrets

## Prozess-Lehre (warum Spacing erneut durchrutschte)

Beide Werte lagen in der design-spec-Maßtabelle vor — es war KEINE Extraktionslücke, sondern eine
Verifikationslücke: In den QA-Runden wurden Typo/Farbe/Text/Trenner geprüft, aber die Padding-Werte
nicht Kante für Kante gegen die Maßtabelle abgeglichen. Zwei strukturelle Fallen:
- Spacing steht oft NUR im Figma-Dev-Mode (Pixel-Annotationen), nicht sichtbar in einer flachen
  Referenz-PNG → die design-spec-Maßtabelle ist die Quelle, nicht das PNG allein.
- Hyper-Basisregeln liefern häufig nur EINE Kante (hier `padding: 1.6rem 0 0` = nur top) → der
  effektive Computed-Wert je Kante muss geprüft werden, nicht die bloße Existenz einer padding-Regel.

Prävention: neuer Punkt in `qa-checklist.md` (Visual Parity) — „Jeder Spacing-/Padding-Wert der
design-spec einzeln gegen den effektiv gerenderten Wert je Kante geprüft"; inkl. Hinweis auf
Dev-Mode-only-Spacing, einseitige Hyper-Basis-Paddings und Schema-`range`-Grenzen (nicht
stillschweigend kappen, sondern `max` anheben).
