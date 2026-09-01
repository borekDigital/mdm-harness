# Phase 3 abgeschlossen — FAQ-Akkordeon (Reuse mdm-collapsible-tabs)

Ticket: MDM-RETOURE-01 · Datum: 21. August 2026

## Ergebnis

- Status: APPROVED (theme-reviewer ∥ security-reviewer; APPROVED mit 3 Minor-Findings,
  alle drei anschließend behoben und re-approved)

## Neue/geänderte Dateien

- NEU `assets/mdm-section-retoure-faq.css` — Retoure-spezifisches Akkordeon-Styling,
  vollständig unter `.mdm-retoure-faq` gescoped:
  - Summary Stone-100 #3e3a32 (Toggle-Icon erbt via currentColor), Frage-h2 Prussian #002147
  - Open-State-Border-Override gegen theme.css:3057 (`[aria-expanded="true"]`)
  - Trennlinie über erstem Item (`.accordion-parent > .accordion-item:first-child`)
  - Buttons über Hyper-CSS-Variablen (Hover-Slide bleibt): primary Prussian/weiß,
    secondary weiß/Prussian-Border; eckig, 48px hoch, 24px Padding, Gap 12px,
    `--buttons-transform: none`, Inter Bold 16px explizit
- GEÄNDERT `sections/mdm-collapsible-tabs.liquid` — minimales `custom_class`-Setting
  (Zeile 40-43 escaped an section_css_class angehängt; Schema Zeile 713-721 mit
  vorhandenen Keys `t:general.custom_attr.*` — keine Locale-Edits nötig).
  Leerer Default = byte-identisches Verhalten; kein Template nutzt die Section bisher
  (✅ Belegt per grep, Rückwärtskompatibilität bestätigt).

## Architektur-Entscheidung (Mini-ADR)

- Kontext: CSS darf nur auf der Retoure-Seite greifen; section.id ist bei
  JSON-Templates nicht stabil; Schema hat kein section-level custom_liquid/custom_css.
- Entscheidung: generisches `custom_class`-Setting (Hyper-Pattern aus custom-content.liquid)
  + CSS-Load über das bestehende `custom_liquid`-Block-Setting von Block 1 in Plan-Phase 4.
- Konsequenz: Löscht ein Merchant Block 1 bzw. dessen custom_liquid, verschwindet das
  Retoure-Styling (dokumentierter Trade-off, in Doku aufnehmen). Kein JS geändert —
  exklusives Verhalten aus AccordionGroup (theme.js:1051-1068) unverändert.

## Vorgaben für Plan-Phase 4 (vom Implementer)

- Section-Settings: `custom_class: "mdm-retoure-faq"`, `container: narrow`, `heading: ""`,
  `item_heading_font: heading`, `item_heading_size: h5`, `item_style: standard`,
  `item_color_scheme: scheme-1`
- Block 1 custom_liquid: `{{ 'mdm-section-retoure-faq.css' | asset_url | stylesheet_tag }}`
  + Buttons `<a href="#briefmarke" class="btn btn--primary">Jetzt Briefmarke erstellen</a>`
  / `<a href="#paketschein" class="btn btn--secondary">Jetzt Paketschein anfragen</a>`
  in `.mdm-retoure-faq__buttons`
- Items 2-10: nur heading + Platzhalter-content, `icon: "none"`, `open: false`; Item 1 `open: true`
- Aus Phase 1 offen: `aria-current="page"` am letzten Breadcrumb-Item;
  Breadcrumb-Link-Farbe Stone-80 nur für Retoure (Empfehlung: `link_color`-Setting)

## Validierung

- `shopify theme check`: 0 Offenses (beide Dateien, nach Fixes erneut)
- Shopify Dev MCP `validate_theme`: VALID (Liquid-Änderung)

## Unknowns

- ⚠️ Border-Position beim offenen Item (Linie zwischen Frage und Antwort, Hyper-bedingt
  am Summary) — visuelles Review gegen Referenz-PNG nach Phase 4.
- ⚠️ Button-Fonts: globale `--font-button-*`-Store-Settings zur Laufzeit unbekannt,
  daher Inter Bold 16px explizit gesetzt.
