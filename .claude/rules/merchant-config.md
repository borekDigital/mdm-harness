---
paths:
  - "themes/*/config/**"
  - "themes/*/locales/**"
---
# Merchant-verwaltete Dateien

- `config/settings_data.json` gehört dem Theme-Editor (Live-Einstellungen). Lokale Edits
  würden beim Push Live-Einstellungen überschreiben — die Datei bleibt unangetastet
  (Hook + Permission-Deny blockieren Edits). Wertänderungen macht Konrad im Theme-Editor.
- `config/settings_schema.json`: Erweiterungen nur additiv am Ende, FoxEcom-Struktur
  unverändert lassen.
- Locales: `en.default.json` ist Default-Locale, der Shop läuft deutsch über `de.json`.
  Neue Keys immer in beiden pflegen (Theme-Check `MatchingTranslations` schlägt sonst an);
  `es/fr/it/vi` sind vorhandene FoxEcom-Übersetzungen und werden nur bei Bedarf ergänzt.
- Setting-Labels (`t:settings_schema…`, `t:sections…`) gehören in die `*.schema.json`-Pendants.
- shopify[bot]-Commits: Der Shopify-GitHub-Connector schreibt Änderungen aus dem Theme-Editor
  direkt auf `main`. Bei Merge-Konflikten in `settings_data.json` oder Template-JSON gilt:
  Shopify-Version gewinnt (`--theirs`), eigene strukturelle Änderung darauf re-applyen.
  Im Zweifel: `shopify theme pull --only=<datei>` statt manueller 3-Way-Merge.
