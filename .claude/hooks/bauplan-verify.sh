#!/bin/bash
# Stop — async, nicht blockierend.
#
# Prueft den Bauplan-Bestand gegen den letzten Commit: geloeschte Blaetter,
# geschrumpfte Manifeste, Etappen ohne HTML-Quelle. Schreibt einen Befund nur,
# wenn etwas fehlt — Stille heisst unauffaellig.
PROJECT="${CLAUDE_PROJECT_DIR:-$HOME/MDM}"
GUARD="$PROJECT/bin/bauplan-guard.py"
[ -x "$GUARD" ] || exit 0

OUT=$("$GUARD" --verify --project "$PROJECT" 2>&1)
if [ $? -ne 0 ]; then
  REPORT="$PROJECT/.claude/bauplan/BESTAND-WARNUNG.md"
  {
    echo "# Bestandswarnung"
    echo
    echo "Geprueft: $(date '+%d.%m.%Y %H:%M')"
    echo
    echo "Der Bauplan-Bestand weicht vom letzten Commit ab:"
    echo
    printf '%s\n' "$OUT" | sed 's/^BAUPLAN-GUARD: /- /'
    echo
    echo "Alles aus dem Commit zurueckholen:"
    echo '```bash'
    echo "git -C \"$PROJECT\" checkout HEAD -- docs/bauplan .claude/bauplan workspace.yaml"
    echo '```'
  } > "$REPORT"
  printf '%s\n' "$OUT" >&2
fi
exit 0
