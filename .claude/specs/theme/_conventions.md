# Theme-Konventionen (Spec-Referenz)

## Theme-First-Prinzip

**So wenig wie moeglich neu entwickeln, so viel wie noetig.**

1. Bestehende Hyper-Section identifizieren, die dem gewuenschten Block am naechsten kommt
2. `mdm-`-Kopie anlegen (z. B. `mdm-breadcrumbs.liquid` als Override von `breadcrumbs.liquid`)
3. Nur die Teile aendern, die vom Design abweichen
4. Neue Sections NUR wenn keine passende Hyper-Section existiert

**Wichtig:** Hyper-Originaldateien NIEMALS direkt bearbeiten.

### Kopie-Strategie (3 Stufen)

| Stufe | Regel | Beispiel |
|---|---|---|
| **Must** | Jede Datei die wir aendern (Risk A: Overwrite) + jede Section/Layout/Template | `mdm-price.liquid`, `mdm-breadcrumbs.liquid` |
| **Should** | Snippets deren Markup/Parameter ein Custom Design tragen — Drift ist ein Regressionsrisiko | `mdm-card-product`, `mdm-collection-cards-item`, `mdm-facets-active`, `mdm-product-badges`, `mdm-product-information-blocks` u.a. |
| **Not needed** | Unveraenderte generische Primitives (Icons, `divider`, `swatch`) — Kopie bringt nichts und kostet Upstream-Fixes | `icon-caret-down`, `icon-close`, `divider` |

Sections und Layouts sind immer „Must" — sobald sie in einem unserer Templates
referenziert werden, MUSS eine `mdm-`-Kopie existieren. Damit sind unsere Anpassungen
update-sicher — ein Theme-Update ueberschreibt nur die Originale, nicht die `mdm-`-Kopien.

Snippets differenzieren: nur kopieren wenn geaendert oder designkritisch (Must/Should).
Generische Primitives direkt aus dem Hyper-Original rendern (Not needed).

## Mapping-Tabelle (bekannte Overrides)

| Design-Element | Hyper-Section | MDM-Override | Neu? |
|---|---|---|---|
| Breadcrumbs | `breadcrumbs.liquid` | `mdm-breadcrumbs.liquid` | Nein (Override) |
| Themenkacheln (Icons) | `multicolumn.liquid` | `mdm-multicolumn-icon.liquid` | Ja (kein Icon-Multicolumn in Hyper) |
| FAQ / Collapsible | `collapsible-tabs.liquid` | `mdm-collapsible-tabs.liquid` | Nein (Override) |
| Seitentitel | — | `mdm-page-title.liquid` | Ja (Hyper hat keinen separaten Page-Title-Block) |
| Rich Text | `rich-text.liquid` | `mdm-rich-text.liquid` | Nein (1:1-Kopie, update-sicher) |
| Newsletter | `newsletter.liquid` | `mdm-newsletter.liquid` | Nein (1:1-Kopie, update-sicher) |

## Namensraeume

- Sections: `mdm-<name>.liquid`
- CSS: `mdm-section-<name>.css` (section-spezifisch), `mdm-page-<suffix>.css` (seitenlokale Overrides)
- Templates: `page.<handle>.json`
- Locales: `de.json` + `en.default.schema.json` paarig pflegen

## Template-Blaupause

Die Retoure-Seite (`page.retoure.json`) ist die Blaupause fuer alle Hilfe-Unterseiten:
- Layout: `mdm-theme`
- Sections: mdm-breadcrumbs → mdm-page-title → Inhalts-Sections → (optional: Teaser)
- Neue Unterseiten werden im Shopify-Admin gepflegt, nicht als Code-Template
- Nur das JSON-Template und die Sections muessen einmal existieren

## Blast-Radius

- `mdm-breadcrumbs.liquid` ist SHOPWEIT aktiv — Aenderungen betreffen alle Seiten
- `brand-overrides.css` ist SHOPWEIT aktiv — Aenderungen betreffen alle Seiten
- Page-spezifisches CSS (`mdm-page-<suffix>.css`) betrifft nur eine Seite
- Template-JSON betrifft nur Seiten, denen dieses Template zugewiesen ist
