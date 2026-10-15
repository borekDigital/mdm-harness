## Themes (themes/)

Drei Marken-Themes, ein Aufbau. Basis aller drei: kommerzielles Theme **Hyper v1.3.3**
von FoxEcom (Online Store 2.0, Doku: docs.foxecom.com/hyper-theme).

| Marke | Pfad | Store-Handle |
|---|---|---|
| MDM | `themes/mdm/` | `mdm-muenze` |
| Borek | `themes/borek/` | — |
| IMM | `themes/imm/` | — |

Die drei Repos teilen **keine** Git-Historie, aber rund 90 Prozent identische Dateien.
MDM ist der aktive Zweig und laeuft den beiden anderen voraus; Borek und IMM sind
untereinander nahezu deckungsgleich. Perspektivisch sollen alle drei Shops auf **einem**
Theme laufen. Uebertragung zwischen den Marken: Skill `/theme-port`. Automatisch: der
Workflow `theme-sync.yml` im MDM-Theme oeffnet je Push auf `main` den PR `sync/theme-mdm`
in Borek und IMM (`bin/theme-sync.sh align`), sobald die Repo-Variable `THEME_SYNC_ENABLED`
auf `true` steht; gemergt wird von Hand.

### Befehle (im jeweiligen Theme-Verzeichnis, nicht im Workspace-Root)

- `shopify theme check --fail-level error` — Linter
- `shopify theme dev --store mdm-muenze` — Dev-Server mit Hot-Reload
- Upload nur als unveroeffentlichtes Theme (`--unpublished`), nie aufs Live-Theme
- Kein `--theme-editor-sync` (CLI-Bug, community.shopify.dev/t/28292 — Hook blockiert)

Der Store-Handle gehoert zur Marke — `--store mdm-muenze` gilt nur fuer `themes/mdm/`.

### Namensraum

- Das Praefix `mdm-` ist die **Haus-Konvention aller drei Themes**, nicht die Marke MDM.
  Auch `themes/borek/` und `themes/imm/` fuehren `mdm-breadcrumbs.liquid` usw.
- FoxEcom-Kerndateien NIEMALS direkt bearbeiten. Jede Section, die in einem Template
  referenziert wird, MUSS als `mdm-`-Kopie existieren (update-sicher).
- Markenspezifisch, nie zwischen Themes uebertragen: `config/settings_data.json`,
  `config/settings_schema.json`, `locales/`, `sections/*-group.json`, `layout/` sowie
  alle Templates ausser den geteilten.
- Geteilte Templates (seit 15. Oktober 2026): `collection.json`, `collection.mdm.json`,
  `product.json`, `product.mdm.json` sind in allen drei Themes gleich — gleiche Sections,
  Reihenfolge, IDs und Namen. Vorlage ist MDM; nur der `layout`-Schluessel bleibt
  markenspezifisch (`mdm-theme`, `borek-theme`, `imm-theme`). Weitere Templates kommen
  erst nach Abstimmung mit Bhavani dazu. Spec: `.claude/specs/themes/templates-angleichen-plp-pdp.md`.
- Details je Bereich: `.claude/rules/` (liquid-, templates-json-, merchant-config-)
