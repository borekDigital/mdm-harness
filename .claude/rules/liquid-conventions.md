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
- **Kein globales JS als Workaround fuer Liquid-Probleme.** Wenn ein Verhalten (z. B.
  `target="_blank"`) in Liquid geloest werden kann, MUSS es in Liquid geloest werden —
  auch wenn das mehr Dateien (Kopie-Kaskade) bedeutet. Ein globales Script, das DOM-Elemente
  nachtraeglich manipuliert, ist fragil (Klassenname aendert sich → bricht still) und
  laedt auf jeder Seite, auch wo das Feature nicht existiert. Ausfuehrbare Regel:
  Snippet-Kopie + Render-Aufruf-Update > nachtraegliches DOM-Patching.
- **Kopie-Kaskade vollstaendig durchziehen.** Wenn ein Snippet kopiert wird (`mdm-<name>.liquid`),
  muessen auch alle Sections/Snippets, die das Original rendern, als `mdm-`-Kopie existieren
  und den Render-Aufruf auf die Kopie umstellen. Unvollstaendige Kaskaden (Original rendert
  noch das alte Snippet) fuehren zu inkonsistentem Verhalten.
- JS: eigene Datei `assets/mdm-<name>.js`, als Modul mit `defer` einbinden; Interaktivität
  nach Hyper-Muster (Custom Elements, siehe bestehende `assets/*.js`).
  JS-Dateien nur dort laden, wo sie gebraucht werden (in der Section, nicht global im Layout),
  es sei denn, das Feature ist tatsaechlich auf jeder Seite aktiv.
- CSS: Section-Layout in `assets/mdm-section-<name>.css`, wiederverwendbare Komponente in
  `assets/mdm-component-<name>.css`; Werte aus dem Design als CSS-Custom-Properties,
  vorhandene Theme-Variablen bevorzugen.
- **Keine hardgecodeten Farbwerte** (#002147, #D6CAB3 etc.) in neuen oder geaenderten CSS-Regeln.
  Stattdessen Theme-Variablen verwenden: `rgb(var(--color-heading))`, `rgb(var(--color-border))`,
  `rgb(var(--color-subtext))` usw. Bestehende Hyper-Variablen (definiert in `css-variables.liquid`)
  haben Vorrang vor eigenen Custom Properties. Ausnahme: ein Wert existiert nachweislich nicht
  als Theme-Variable — dann als `--mdm-<name>` in der Section-CSS definieren und dokumentieren.
- **Abstaende: entweder margin ODER padding**, nicht beides gleichzeitig auf demselben Element
  fuer denselben Zweck (Richtung). Doppelter Abstand (margin + padding in dieselbe Richtung)
  ist schwer nachvollziehbar und erschwert Uebersteuerung. Wenn interner und externer Abstand
  getrennt gebraucht werden, gehoeren sie auf verschiedene Elemente (Wrapper vs. Content).
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
