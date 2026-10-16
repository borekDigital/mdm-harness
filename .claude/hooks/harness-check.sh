#!/usr/bin/env bash
# Hook: Stop-Event — prueft die Claude-Struktur mit bin/harness-check.py.
# Offline (ohne Netz und claude-CLI), damit der Lauf unter einer Sekunde bleibt.
# Schweigt, solange alles sauber ist; ein Defekt des Pruefskripts wird gemeldet,
# blockiert aber nie.

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SCRIPT="${ROOT}/bin/harness-check.py"
[[ -f "$SCRIPT" ]] || exit 0

ausgabe=$(python3 "$SCRIPT" --root "$ROOT" --offline 2>&1)
rc=$?

if [[ $rc -eq 3 ]]; then
  echo "⚠️  Harness-Check:"
  echo "$ausgabe" | grep -v '^   uebersprungen:' | sed 's/^/   /'
elif [[ $rc -ne 0 ]]; then
  echo "⚠️  Harness-Check defekt (Exit $rc): $ausgabe"
fi

exit 0
