# Figma ↔ Hyper-Theme Mapping

Gepflegte Zuordnung von Figma-Komponenten/Layer-Namen zu Theme-Dateien.
figma-extractor und theme-planner lesen diese Tabelle; theme-planner schlägt
Ergänzungen vor, sobald neue Zuordnungen verifiziert sind.

Figma-Datei: „MDM — Templates (Internal)" (`vnEStNM7qm0qThY39RqiFL`)

| Figma-Layer/Muster | Theme-Gegenstück | Status |
|---|---|---|
| `breadcrumbs (nav)` (auch 3 Ebenen) | `sections/mdm-breadcrumbs.liquid` (Original: `sections/breadcrumbs.liquid`) — mehrstufiger Pfad über Settings `parent_label`/`parent_url` | ✅ Verifiziert (MDM-RETOURE-01): `sections/mdm-breadcrumbs.liquid:67-75` |
| `accordion-item` / FAQ-Liste | `sections/mdm-collapsible-tabs.liquid` mit `collapsible_item`-Blöcken (exklusives Öffnen via `AccordionGroup`, `assets/theme.js:1051-1068`) | ✅ Verifiziert (MDM-RETOURE-01): `sections/mdm-collapsible-tabs.liquid:110-140` |
| `btn--primary` / `btn--secondary` | Hyper-Klassen `btn btn--primary`, `btn btn--secondary`; Farben CSS-Var-getrieben (`--color-button` etc.), scheme-1 = Schwarz, nicht Prussian — Abweichungen per CSS-Var-Override lösen. **Handgeschriebene Buttons IMMER mit `<span class="btn__text">Label</span>`** (Hover-Slide-`::before` z-index 0 verdeckt sonst nacktes Label; nur `.btn__text` hat z-index 1). **Buttons im `.rte` brauchen `text-decoration: none`** (RTE unterstreicht Links). | ✅ Verifiziert (MDM-RETOURE-01): `assets/theme.css:2262-2272` (Farben), `:2225-2246` (Hover-Slide/z-index), `:2434-2455` (Hover-Umkehr), `:1822-1826` (RTE-Underline); Farbquelle `config/settings_data.json:123` |
| `h2.font-heading.h5` | Hyper-Utilities `.font-heading` + `.h5`. **Achtung:** `.h5` skaliert via `calc(--font-heading-scale * --font-h5-size)` ≈ 25,92px, NICHT 18px. Für explizite Design-px (z. B. 18px) `font-size`/`line-height` im Component-CSS überschreiben. | ✅ Verifiziert: `assets/theme.css:920-926` (.h5), `:970-973` (.font-heading); Override-Beispiel `assets/mdm-section-retoure-faq.css:19-23` |
| `.rte` (Rich-Text-Content) | Hyper `.rte`-Wrapper (Absatz-Margins, Link-Styling) | ✅ Verifiziert: `assets/theme.css:1717-1829` |
| Serifen-Headline | `assets/eb-garamond-variable.ttf` | ✅ Font liegt im Theme |
| Fließtext | `assets/inter-variable.ttf` | ✅ Font liegt im Theme |
| `icon-plus-toggle` | `snippets/mdm-icon-plus-toggle.liquid` — SVG 20x20, stroke 1.5, `currentColor` | ✅ Verifiziert: `snippets/mdm-icon-plus-toggle.liquid:1-9`. ❌ verworfen: `assets/icon-plus.svg` (statisches Asset, nicht das Toggle-Pattern) |
| `Stone-80` (#615b4f) | Kein Hyper-Token; MDM-Pattern = Hex-Hardcode in mdm-CSS | ✅ Verifiziert: `assets/mdm-section-product-faq.css:28,85` |
| `Stone-100` (#3e3a32) | Kein Hyper-Token; MDM-Pattern = Hex-Hardcode in mdm-CSS | ✅ Verifiziert: `assets/mdm-section-product-faq.css:73`, `assets/mdm-section-main-product.css:62` |
| `Prussian` (#002147) | Kein Hyper-Token; MDM-Pattern = Hex-Hardcode in mdm-CSS (6+ Dateien) | ✅ Verifiziert: `assets/mdm-section-product-faq.css:33`, `assets/mdm-section-main-product.css:61` |
| `White` (#ffffff) | `--color-background` (scheme-1: #ffffff), Standard-Hyper-Variable | ✅ Verifiziert: `config/settings_data.json:121` |
| `Stone-20` (#d6cab3) | `--color-border` in scheme-1 (`config/settings_data.json:119`). CSS-Zugriff: `rgb(var(--color-border))`. Kein Hex-Hardcode noetig. | ✅ Verifiziert (MDM-HILFE-01): `config/settings_data.json:119` (`"border": "#D6CAB3"`), `snippets/css-variables.liquid:200` |
| `Stone-5` (#f6f3ee) | Kein Hyper-Token; MDM-Pattern vermutlich Hex-Hardcode | ❌ Neu entdeckt (MDM-HILFE-01), noch nicht verifiziert — Newsletter-Section-Hintergrund |
| Themenkachel-Grid (6 Kacheln, Hub) | Zwei Kandidaten: (A) `sections/mdm-multicolumn-icon.liquid` (generisches Grid, muesste um Stretched-Link/Responsive-Flip/Mobile-Titel/Inline-Icons erweitert werden) oder (B) `sections/mdm-help-topic-cards.liquid` (zweckgebaut, alle Features bereits implementiert inkl. Stretched-Link, Responsive-Flip, Mobile-Titel, Inline-SVG-Icons, Focus-Management). Entscheidung haengt von Konrads Freigabe ab (Block-Plan MDM-HILFE-01). | ⚠️ Offene Entscheidung (26.08.2026) — beide Varianten gegen Figma abgeglichen, Pfad B deckt Design exakter ab |
| FAQ-Accordion (Hilfe-Hub) | `sections/collapsible-tabs.liquid` → Override als `sections/mdm-collapsible-tabs.liquid` (existiert bereits). Accordion-Verhalten via `AccordionGroup` (`assets/theme.js:1051-1068`). | ✅ Verifiziert (MDM-RETOURE-01): `sections/mdm-collapsible-tabs.liquid:110-140` |
| Muenzlexikon-Teaser (Hilfe-Hub) | Hyper-Section noch zu identifizieren — Kandidaten: `image-with-text.liquid`, `rich-text.liquid`, `custom-liquid.liquid` | ❌ Noch nicht untersucht |

## Pflege-Regeln

1. Neue Zeile erst nach Lesen der Theme-Datei — Status dann auf ✅ mit `path:line`-Beleg.
2. Verworfene Zuordnungen nicht löschen, sondern als „❌ verworfen: <Grund>" dokumentieren.
3. Figma-Layer-Namen wörtlich übernehmen (Suchbarkeit).
