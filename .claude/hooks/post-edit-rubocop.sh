#!/bin/bash
# PostToolUse (Edit|Write) — blocking
# Fuehrt RuboCop aus und meldet Offenses NUR fuer die editierte Datei.
# Greift nur bei connector/-Dateien (.rb, .rake, .gemspec).
PAYLOAD=$(cat)
FILE=$(printf '%s' "$PAYLOAD" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

# Nur Ruby-Dateien im Connector
case "$FILE" in
  */connector/*.rb|*/connector/*.rake|*/connector/*.gemspec) : ;;
  *) exit 0 ;;
esac
# Harness/Tickets ausschliessen
case "$FILE" in
  */.claude/*|*/Tickets/*) exit 0 ;;
esac

PROJECT="${CLAUDE_PROJECT_DIR:-$HOME/MDM}"
cd "$PROJECT/connector" || exit 0

# Relativen Pfad zum Connector-Root berechnen
REL_FILE=$(printf '%s' "$FILE" | sed "s|.*connector/||")
[ -z "$REL_FILE" ] && exit 0

# RuboCop nur auf die geaenderte Datei
REPORT=$(bundle exec rubocop --format json "$REL_FILE" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
findings = []
for f in data.get('files', []):
    for o in f.get('offenses', []):
        sev = o.get('severity', '')
        if sev in ('error', 'warning', 'convention', 'refactor'):
            loc = o.get('location', {})
            findings.append(
                f\"{f['path']}:{loc.get('line', 0)} \"
                f\"[{sev}/{o.get('cop_name', '')}] {o.get('message', '')}\"
            )
if findings:
    print('\n'.join(findings[:15]))
")

if [ -n "$REPORT" ]; then
  {
    echo "RuboCop meldet Probleme in der geaenderten Datei:"
    echo "$REPORT"
    echo "Bitte beheben, bevor weitergearbeitet wird."
  } >&2
  exit 2
fi
exit 0
