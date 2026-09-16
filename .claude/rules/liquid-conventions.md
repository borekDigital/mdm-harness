---
paths:
  - "themes/*/sections/**"
  - "themes/*/snippets/**"
  - "themes/*/blocks/**"
  - "themes/*/layout/**"
---
# Liquid-Konventionen (Hyper-Theme)

- Neue Dateien: kebab-case mit `mdm-`-Präfix. FoxEcom-Dateien (ohne Präfix) nicht editieren —
  bei Anpassungsbedarf Kopie als `mdm-<name>.liquid` anlegen und diese im Template referenzieren.
- Vor jedem Neubau prüfen, ob eine Vorlage existiert: erst `sections/`, `snippets/`, `blocks/`
  durchsuchen (Beispiel: `collapsible-tabs.liquid` liefert bereits Accordion-Verhalten).
  Die Original-Section vollständig lesen, bevor eine `mdm-`-Kopie entsteht.
- Snippet-Kopie-Strategie (3 Stufen):
  - **Must:** Jede Datei die geändert wird + jede Section/Layout/Template → `mdm-`-Kopie.
  - **Should:** Snippets mit custom Design-Markup (z. B. `mdm-card-product`, `mdm-price`) → kopieren.
  - **Not needed:** Unveränderte generische Primitives (`icon-caret-down`, `divider`, `swatch`)
    → direkt aus Original rendern, NICHT kopieren (sonst verpasst man Upstream-Fixes).
- Snippet-Dokumentation: Parameter am Dateikopf dokumentieren (Usage-Beispiel + required/optional):
  ```liquid
  {% comment %}
    Renders a product badge row.
    Usage: {% render 'mdm-product-badges', product: product, compact: true %}
    - product (required): product object
    - compact (optional, default false): reduces padding
  {% endcomment %}
  ```
- Ausgaben von Merchant-/Kundeneingaben escapen: `{{ var | escape }}`. Ausnahme nur für
  bewusst gerenderte Rich-Text-Settings (`richtext`), dann `.rte`-Wrapper verwenden.
- Texte über `{{ 'key' | t }}`; Keys in `locales/en.default.json` und `locales/de.json`
  pflegen. Setting-Labels über `t:`-Keys in den `*.schema.json`-Dateien.
- Bilder: `image_url` + `image_tag` mit `width`/`height` (CLS-Schutz) und `srcset`/`sizes`.
  Below-the-fold `loading="lazy"`; das LCP-Bild nie lazy, stattdessen `fetchpriority="high"`.
- JS: eigene Datei `assets/mdm-<name>.js`, als Modul mit `defer` einbinden; Interaktivität
  nach Hyper-Muster (Custom Elements, siehe bestehende `assets/*.js`).
- CSS: Section-Layout in `assets/mdm-section-<name>.css`, wiederverwendbare Komponente in
  `assets/mdm-component-<name>.css`; Werte aus dem Design als CSS-Custom-Properties,
  vorhandene Theme-Variablen bevorzugen.
- CSS-Klassennamen: Dateinamen tragen `mdm-`-Präfix, Klassennamen aktuell NICHT.
  Für neue Komponenten einen distinctiven Class-Root wählen (z. B. `.mdm-testimonials`),
  um Kollisionen mit künftigen Hyper-Klassen zu vermeiden.
- Neue Locale-Keys unter dem Top-Level-Key `mdm` anlegen (`mdm.sections.<name>.<key>`),
  damit ein Theme-Update sie nicht versehentlich entfernt.
- Section-Schema: `{% schema %}` mit `name`, `settings`, `presets` — ohne Preset erscheint
  die Section nicht im Theme-Editor.
- Keine externen Ressourcen (Fonts, Scripts, iframes) ohne Abstimmung — Fonts liegen
  self-hosted in `assets/` (DSGVO).
- Strict Liquid Parsing (Shopify, seit 13.01.2026): keine toleranten Syntax-Tricks;
  nach jeder Änderung besteht `shopify theme check --fail-level error`.
