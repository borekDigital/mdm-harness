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

Die drei Themes teilen keine Git-Historie, deshalb scheidet `git merge` aus. Eine
Aenderung wandert von Arbeitsbaum zu Arbeitsbaum.

**Es gibt keine Automatik.** Nichts erzeugt von selbst einen Commit, einen Push
oder einen PR in den anderen Themes. Jede Uebertragung wird angestossen.

#### Ablauf

```bash
# 1. Im Quell-Theme fertig: committet und gemergt.
#    Der Commit-SHA aus dem Quell-Theme ist der Schluessel.

# 2. Sehen, wo die Themes stehen
bin/theme-sync.sh list
bin/theme-sync.sh drift assets/          # optional: was laeuft auseinander?

# 3. Uebertragen — Modus nach Lage waehlen (siehe Tabelle)
bin/theme-sync.sh port mdm borek,imm --commit <sha> --as-patch

# 4. Je Ziel-Theme pruefen und committen
git -C themes/borek diff
git -C themes/borek commit -am "…"       # gleiche Message wie in der Quelle
git -C themes/borek push -u origin sync/mdm-<datum>

# 5. PR je Ziel-Theme von Hand
```

#### Welcher Modus?

| Lage | Kommando | Wirkung |
|---|---|---|
| Datei in Quelle und Ziel sonst identisch | `port <q> <ziele> <pfad>` | kopiert die ganze Datei |
| Quelle laeuft in derselben Datei voraus | `port <q> <ziele> --commit <sha> --as-patch` | wendet nur die Hunks des Commits an |

Der Normalfall ist `--as-patch`, weil MDM den beiden anderen vorauslaeuft. Ohne
`--as-patch` wuerde die Ganzdatei-Kopie die abweichende Zielarbeit ueberschreiben.

#### Sicherungen

- Ziel mit unsauberem Arbeitsbaum wird uebersprungen, nicht ueberschrieben.
- Mit `--as-patch`: passt der Patch nicht, wird das Ziel uebersprungen, **bevor**
  der Branch angelegt wird. Ausweg: `git -C themes/<ziel> apply --3way --reject`.
- Markenspezifische Pfade (`locales/`, `templates/`, `config/settings_*.json`,
  `layout/`, `sections/*-group.json`) werden uebersprungen; `--allow-brand` erzwingt.
- Das Skript committet nie und pusht nie.

#### Was das Skript nicht pruefen kann

Ob die Aenderung **inhaltlich** in die andere Marke passt. Hart verdrahtete
Layout-Zahlen aus einem Marken-Figma (Spaltenbreiten, Verhaeltnisse, Breakpoints)
laufen sauber durch den Patch und sind im Zielshop trotzdem falsch. Nach jeder
Uebertragung im Ziel-Theme visuell gegenpruefen:

```bash
cd themes/<ziel> && shopify theme check --output json   # JSON parsen, nicht Exit-Code
cd themes/<ziel> && shopify theme dev --store <handle>
```
