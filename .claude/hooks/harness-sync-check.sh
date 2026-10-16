#!/usr/bin/env bash
# Hook: SessionStart — meldet, was lokal fehlt oder nicht zum Stand passt:
# nicht geklonte Repos, abweichende generierte Dateien (CLAUDE.md, Bauplan-Uebersicht,
# Fusszeilen), veraltete Etappen, Setup-Warnungen. Ruft `sync.sh --check` auf und
# schreibt nichts. Ersetzt fuer Claude-Nutzer den lokal einzurichtenden post-merge-Hook
# (Spec harness-ohne-lokale-einrichtung).
#
# Kein Waechter: endet immer mit 0 und schweigt, wenn es nichts zu melden gibt oder
# sync.sh fehlt. Ausgabe als JSON: systemMessage fuer den Nutzer, additionalContext
# fuer Claude (code.claude.com/docs/en/hooks, Abschnitt SessionStart).

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SYNC="${ROOT}/sync.sh"
[[ -x "$SYNC" ]] || exit 0

MELDUNGEN=$("$SYNC" --check --quiet 2>&1 | sed 's/^ *//' | grep -v '^$')
[[ -n "$MELDUNGEN" ]] || exit 0

python3 - "$MELDUNGEN" <<'PY' 2>/dev/null
import json, sys

zeilen = sys.argv[1].splitlines()
kurz = "Harness: " + " · ".join(z.replace("WARNUNG: ", "") for z in zeilen)
if len(kurz) > 600:
    kurz = kurz[:597] + "…"
kontext = (
    "Lokaler Stand dieses Workspace laut sync.sh --check beim Sitzungsstart:\n"
    + "\n".join("- " + z for z in zeilen)
    + "\nNicht geklont heißt übersprungen, nicht abgeschafft: Repos aus workspace.yaml nie "
      "aus Konfiguration, Doku oder CLAUDE.md entfernen, nur weil sie hier fehlen."
)
print(json.dumps({
    "systemMessage": kurz,
    "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": kontext[:9000]},
}, ensure_ascii=False))
PY
exit 0
