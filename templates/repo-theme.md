## Theme (theme/)

Shopify-Theme des MDM-Muenzshops (Store-Handle `mdm-muenze`). Basis: kommerzielles
Theme Hyper v1.3.3 von FoxEcom (Online Store 2.0, Doku: docs.foxecom.com/hyper-theme).

### Befehle (ausfuehren in `theme/`)

- `shopify theme check --fail-level error` — Linter (Baseline: 9 Errors + 20 Warnings in Altlasten)
- `shopify theme dev --store mdm-muenze` — Dev-Server mit Hot-Reload
- `shopify theme pull --store mdm-muenze --theme <id>` — Stand vom Store holen
- `shopify theme push --unpublished --store mdm-muenze` — Upload als unveroeffent. Theme
- Kein `--theme-editor-sync` (CLI-Bug, community.shopify.dev/t/28292 — Hook blockiert)

### Namensraum

- FoxEcom-Kerndateien NIEMALS direkt bearbeiten. Jede Section, die in einem
  MDM-Template referenziert wird, MUSS als `mdm-`-Kopie existieren (update-sicher).
- Templates: `product.mdm.json`, `collection.mdm.json`; Landingpages `page.<slug>.json`.
- Locales: `en.default.json` (Default) + `de.json` (Shop-Sprache) — paarig pflegen.
- Bereichs-Details: `.claude/rules/`
