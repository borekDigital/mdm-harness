#!/bin/bash
# PreToolUse (Bash|Edit|Write) — blocking
# Schuetzt den Bauplan-Bestand: HTML-Quellen, Manifeste, workspace.yaml.
# Prueflogik in bin/bauplan-guard.py, damit CI dieselbe Regel anwendet.
PAYLOAD=$(cat)
PROJECT="${CLAUDE_PROJECT_DIR:-$HOME/MDM}"
GUARD="$PROJECT/bin/bauplan-guard.py"
[ -x "$GUARD" ] || exit 0

read -r TOOL FILE < <(printf '%s' "$PAYLOAD" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_name', ''), d.get('tool_input', {}).get('file_path', '-'))
except Exception:
    print(' -')
" 2>/dev/null)

# --- Bash: Loeschen und Verschieben von Bestand ---
if [ "$TOOL" = "Bash" ]; then
  CMD=$(printf '%s' "$PAYLOAD" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null)
  if echo "$CMD" | grep -qE "(\brm\b|git[[:space:]]+rm\b|\bmv\b|\btruncate\b|>[[:space:]]*[^|]*)" \
     && echo "$CMD" | grep -qE "(docs/bauplan|\.claude/bauplan/[^[:space:]]*\.manifest\.json|workspace\.yaml)"; then
    echo "BLOCKED: Bauplan-Bestand wird nicht per Shell entfernt oder verschoben." >&2
    echo "Betroffen: docs/bauplan, .claude/bauplan/*.manifest.json oder workspace.yaml." >&2
    echo "Eine Etappe wird aktualisiert (/repo-bauplan <repo> --refresh), nicht geloescht." >&2
    echo "Ist ein Repo lokal nicht geklont, heisst das uebersprungen — nicht abgeschafft." >&2
    exit 2
  fi
  exit 0
fi

[ "$FILE" = "-" ] && exit 0

case "$FILE" in
  *.manifest.json|*/workspace.yaml) : ;;
  *) exit 0 ;;
esac

# --- Write: neuen Inhalt gegen den Bestand pruefen ---
if [ "$TOOL" = "Write" ]; then
  TMP=$(mktemp)
  printf '%s' "$PAYLOAD" | python3 -c "
import sys, json
try:
    sys.stdout.write(json.load(sys.stdin).get('tool_input', {}).get('content', ''))
except Exception:
    pass
" > "$TMP" 2>/dev/null
  "$GUARD" --check-write "$FILE" "$TMP" --project "$PROJECT"
  RC=$?
  rm -f "$TMP"
  [ $RC -ne 0 ] && exit 2
  exit 0
fi

# --- Edit: entfernt die Ersetzung Etappen- oder Repo-Eintraege? ---
if [ "$TOOL" = "Edit" ]; then
  printf '%s' "$PAYLOAD" | python3 -c "
import sys, json, re
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
old, new = ti.get('old_string', ''), ti.get('new_string', '')
key = r'\"nr\"\s*:' if ti.get('file_path', '').endswith('.manifest.json') else r'^  [A-Za-z0-9_-]+:\s*$'
flags = 0 if 'nr' in key else re.M
lost = len(re.findall(key, old, flags)) - len(re.findall(key, new, flags))
if lost > 0:
    wort = 'einen Eintrag' if lost == 1 else '%d Eintraege' % lost
    print('BLOCKED: Die Ersetzung entfernt %s aus dem Bauplan-Bestand.' % wort, file=sys.stderr)
    print('Etappen und Repos werden aktualisiert, nicht entfernt.', file=sys.stderr)
    sys.exit(2)
" 2>&1 >/dev/null || exit 2
fi

exit 0
