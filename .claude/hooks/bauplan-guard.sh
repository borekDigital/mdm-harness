#!/bin/bash
# PreToolUse (Bash|Edit|Write) — blocking
# Schuetzt den Bauplan-Bestand: HTML-Quellen, Manifeste, workspace.yaml.
# Prueflogik in bin/bauplan-guard.py, damit CI dieselbe Regel anwendet.
# Fail-closed: Kann der Waechter nicht pruefen, blockiert er (Spec waechter-hooks-fail-closed).
blockiere() { echo "bauplan-guard: $1 — Aktion blockiert (fail-closed)." >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || blockiere "python3 nicht gefunden"

PAYLOAD=$(cat)
PROJECT="${CLAUDE_PROJECT_DIR:-$HOME/MDM}"
GUARD="$PROJECT/bin/bauplan-guard.py"
[ -x "$GUARD" ] || blockiere "Pruefskript $GUARD fehlt oder ist nicht ausfuehrbar"

KOPF=$(printf '%s' "$PAYLOAD" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    tool, ti = d['tool_name'], d.get('tool_input') or {}
except Exception:
    sys.exit(3)
if not isinstance(tool, str) or not tool:
    sys.exit(3)
# Bash hat immer command, Edit und Write haben immer file_path — fehlt es, ist die Eingabe kaputt.
if tool == 'Bash' and not ti.get('command'):
    sys.exit(3)
if tool in ('Edit', 'Write') and not ti.get('file_path'):
    sys.exit(3)
print(tool, ti.get('file_path') or '-')
" 2>/dev/null) || blockiere "Hook-Eingabe nicht lesbar"
read -r TOOL FILE <<< "$KOPF"

# --- Bash: Loeschen und Verschieben von Bestand ---
if [ "$TOOL" = "Bash" ]; then
  CMD=$(printf '%s' "$PAYLOAD" | python3 -c "
import sys, json
print(json.load(sys.stdin)['tool_input']['command'])
" 2>/dev/null) || blockiere "Befehl nicht lesbar"
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
sys.stdout.write(json.load(sys.stdin)['tool_input'].get('content', ''))
" > "$TMP" 2>/dev/null || { rm -f "$TMP"; blockiere "Inhalt nicht lesbar"; }
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
