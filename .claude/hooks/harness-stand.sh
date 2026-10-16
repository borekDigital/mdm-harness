#!/usr/bin/env bash
# Hook: SessionStart (startup) — meldet, wenn die installierte Claude-Code-Version
# neuer ist als die, gegen die die Harness geprueft ist (bin/harness-referenz.json).
# Kein Netzzugriff; schweigt bei gleicher oder aelterer Version und bei jedem Fehler.

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SCRIPT="${ROOT}/bin/harness-stand.py"
[[ -f "$SCRIPT" ]] || exit 0

python3 "$SCRIPT" --root "$ROOT" hinweis 2>/dev/null
exit 0
