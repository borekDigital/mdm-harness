## Themes (themes/)

Drei Shopify-Themes, ein Aufbau — je Marke ein eigenes Repo unter `themes/`:

| Marke | Pfad | Store-Handle |
|---|---|---|
| MDM | `themes/mdm/` | `mdm-muenze` |
| Borek | `themes/borek/` | — |
| IMM | `themes/imm/` | — |

Basis aller drei: kommerzielles Theme Hyper v1.3.3 von FoxEcom
(Online Store 2.0, Doku: docs.foxecom.com/hyper-theme).

Die drei Repos teilen **keine** Git-Historie (drei getrennte Wurzel-Commits), aber
rund 90 Prozent identische Dateien. MDM ist der aktive Zweig und laeuft den beiden
anderen voraus; Borek und IMM sind untereinander nahezu deckungsgleich.
Perspektivisch sollen alle drei Shops auf **einem** Theme laufen — bis dahin gilt
der Patch-Weg unten.

### Befehle (ausfuehren im jeweiligen Theme-Verzeichnis)

- `shopify theme check --fail-level error` — Linter (Baseline MDM: 9 Errors + 20 Warnings in Altlasten)
- `shopify theme dev --store mdm-muenze` — Dev-Server mit Hot-Reload
- `shopify theme pull --store mdm-muenze --theme <id>` — Stand vom Store holen
- `shopify theme push --unpublished --store mdm-muenze` — Upload als unveroeffent. Theme
- Kein `--theme-editor-sync` (CLI-Bug, community.shopify.dev/t/28292 — Hook blockiert)

Der Store-Handle gehoert zur Marke — `--store mdm-muenze` gilt nur fuer `themes/mdm/`.

### Namensraum

- Das Praefix `mdm-` ist die **Haus-Konvention aller drei Themes**, nicht die Marke MDM.
  Auch `themes/borek/` und `themes/imm/` fuehren `mdm-breadcrumbs.liquid`,
  `mdm-card-product.liquid` usw.
- FoxEcom-Kerndateien NIEMALS direkt bearbeiten. Jede Section, die in einem
  Template referenziert wird, MUSS als `mdm-`-Kopie existieren (update-sicher).
- Templates: `product.mdm.json`, `collection.mdm.json`; Landingpages `page.<slug>.json`.
- Locales: `en.default.json` (Default) + `de.json` (Shop-Sprache) — paarig pflegen.
- Markenspezifisch und nie zwischen Themes uebertragen: `config/settings_data.json`,
  `config/settings_schema.json`, `locales/`, `templates/`, `sections/*-group.json`,
  `layout/` (MDM hat `mdm-theme.liquid`, Borek `borek-theme.liquid`).
- Bereichs-Details: `.claude/rules/`

### Gleiche Aenderung in mehrere Themes (bin/theme-sync.sh)

Weil keine gemeinsame Historie existiert, wandert eine Aenderung als **Patch**,
nicht als Merge:

```bash
bin/theme-sync.sh drift                       # was laeuft auseinander?
bin/theme-sync.sh drift sections/             # nur ein Bereich
bin/theme-sync.sh port mdm borek,imm sections/mdm-card-product.liquid
bin/theme-sync.sh port mdm borek --commit <sha>
```

`port` legt im Ziel-Theme einen Branch `sync/<quelle>-<datum>` an und wendet den
Patch an — ohne zu committen und ohne zu pushen. Markenspezifische Pfade sind
blockiert. Pruefen, committen und PR macht Konrad.
