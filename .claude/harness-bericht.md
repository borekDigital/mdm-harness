# Harness-Abgleich 16. Oktober 2026

Claude Code 2.1.290 → 2.1.301

## Befunde

| # | Changelog-Eintrag (Version) | Betroffene Stelle (Datei:Zeile) | Evidenz | Vorschlag |
|---|---|---|---|---|
| 1 | Neu: `onFailure: "block"` für command- und HTTP-Hooks. Ein Hook, der nicht startet, in den Timeout läuft oder mit einem unerwarteten Code endet, blockiert die Aktion, statt sie durchzulassen (2.1.295) | `.claude/settings.json:46-73`: die drei blockierenden PreToolUse-Wächter `git-safety.sh` (:50), `protect-merchant-files.sh` (:60) und `bauplan-guard.sh` (:70). Keiner setzt `onFailure`, Default ist `"continue"` | ✅ belegt (settings.json gelesen; Feld, Default und „ab v2.1.295“ laut hooks.md) | Für alle drei Wächter `"onFailure": "block"` setzen. Grenze: Die Skripte lassen selbst durch, wenn das JSON nicht lesbar ist (`git-safety.sh:13`, `protect-merchant-files.sh:13`, `bauplan-guard.sh:8`: `exit 0` ohne `bin/bauplan-guard.py`). Diesen Weg fängt `onFailure` nicht ab. Für die Stop-Hooks (`async`) hat das Feld laut Doku keine Wirkung |
| 2 | `claude -p` mit Textausgabe meldet ungültige Settings jetzt auf stderr (2.1.299) | `.github/workflows/harness-aktuell.yml:107-117`: stderr geht nach `claude-stderr.txt` und erscheint im Log nur bei Exit ≠ 0 | ⚠️ Vermutung: dass ein Lauf trotz ungültiger Settings mit Exit 0 endet, ist nicht belegt | `claude-stderr.txt` auch bei Erfolg ins Log schreiben (z. B. `tail -c 2000`), sonst bleiben Validierungsfehler an `.claude/settings.json` im CI unbemerkt |
| 3 | Neuer Haiku 5.5 als Default des Alias `haiku` (2.1.293) | `.claude/README.md:210` nennt docs-writer `haiku`, `.claude/agents/docs-writer.md:4` hat `model: sonnet`. Ausserdem nennen `README.md:186`, `:194` und `:202` die drei Implementer `inherit`, die Agenten-Dateien haben `model: sonnet` | ✅ belegt. Die Abweichung kommt nicht vom Changelog, der Eintrag hat sie nur aufgedeckt | README-Modellspalte an die Frontmatter angleichen. Ist für docs-writer Haiku gewollt, gilt jetzt Haiku 5.5, sonst `sonnet` in die Tabelle |
| 4 | MCP-Allow-Regeln gelten nur noch für den genannten Server, und `tools:`-Listen von Agenten nehmen nur dessen Werkzeuge (2.1.299) | `.claude/settings.json:19-22` (`mcp__shopify-dev-mcp__<werkzeug>` voll ausgeschrieben). Kein Agent führt `tools:` | ✅ belegt | Keine Anpassung nötig |
| 5 | `updatedInput` aus PreToolUse- und PermissionRequest-Hooks wird jetzt validiert (2.1.300) | `.claude/hooks/protect-merchant-files.sh:31-37` gibt nur `permissionDecision: ask` aus, kein `updatedInput`. Andere Hooks nutzen es auch nicht (grep) | ✅ belegt | Keine Anpassung nötig |
| 6 | `autoCompactWindow` im Frontmatter von Subagenten (2.1.296) | `bin/harness-referenz.json` `agent_felder` enthält das Feld bereits. Kein Agent nutzt es | ✅ belegt | Optional, z. B. für die Implementer mit `maxTurns: 50`. Nicht erforderlich |
| 7 | Alias `fable` (und `best`) fällt auf das vorherige Fable-Modell zurück (2.1.301) | `.claude/settings.json:3` `model: opus`. Kein Agent nutzt `fable` | ✅ belegt | Keine Anpassung nötig. Zum Alias `best` siehe den nächsten Abschnitt |

## Vorschläge für bin/harness-referenz.json

- `modell_aliase`: Alias `best` (im Changelog 2.1.301 genannt, in `model-config.md` dokumentiert: Fable, wo verfügbar, sonst wie `opus`). Prüfen, ob `best` auch im Agenten-Frontmatter `model:` gilt (⚠️ Vermutung). Sonst bleibt die Liste, wie sie ist.
- `agent_felder`: `autoCompactWindow` (2.1.296) steht schon drin, nichts zu tun.
- Hook-Felder (`onFailure`, ab 2.1.295) führt die Referenz nicht. Ein Eintrag lohnt sich nur, wenn `harness-check.py` künftig auch Felder einzelner Hooks prüfen soll.
- Neuer Settings-Schlüssel `idleCompaction` (2.1.299): Den prüft H15 über das Schemastore-Schema, die Referenz braucht ihn nicht.

## Harness-Check

Sauber. Alle Zeilen „uebersprungen“ kommen daher, dass der CI-Checkout nur `mdm-harness` enthält: Die Kind-Repos (`themes/`, `connector/`, `creditcheck/`, `emailservice/`, `payment-service/`) sind gitignored und fehlen dort. Deshalb lassen sich die `paths`-Globs der Rules (H06) und die Versionsbelege in `doku-quellen.md` (H19) nicht prüfen. Das ist kein Defekt der Harness.
