#!/bin/bash
# PostToolUse (Edit|Write) — blocking
# Führt Theme Check aus und meldet Errors/Warnings NUR für die editierte Datei
# (Altlasten in FoxEcom-Locales/ai_gen-Blocks blockieren so keine Edits).
PAYLOAD=$(cat)
FILE=$(printf '%s' "$PAYLOAD" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

case "$FILE" in
  */themes/*.liquid) : ;;
  */themes/*/templates/*.json|*/themes/*/config/*.json|*/themes/*/locales/*.json|*/themes/*/sections/*.json|*/themes/*/blocks/*.json) : ;;
  *) exit 0 ;;
esac
case "$FILE" in
  */.claude/*|*/Tickets/*|*/docs/*|*/connector/*|*/datalayer/*) exit 0 ;;
esac

PROJECT="${CLAUDE_PROJECT_DIR:-$HOME/MDM}"
command -v shopify >/dev/null 2>&1 || exit 0

# Welches Theme? Aus dem Pfad herleiten statt fest verdrahten — themes/ traegt
# eine Marke je Unterverzeichnis (mdm, borek, imm).
REST="${FILE#*/themes/}"
BRAND="${REST%%/*}"
THEME_DIR="$PROJECT/themes/$BRAND"

# Still aussteigen, wenn das Verzeichnis gar kein Shopify-Theme ist
# (z. B. eine Datei direkt unter themes/).
[ -n "$BRAND" ] || exit 0
[ -f "$THEME_DIR/config/settings_schema.json" ] || exit 0
cd "$THEME_DIR" || exit 0

REPORT=$(shopify theme check -o json 2>/dev/null | FILE="$FILE" python3 -c "
import sys, json, os
target = os.environ.get('FILE', '')
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
findings = []
for entry in data:
    if entry.get('path') != target:
        continue
    for o in entry.get('offenses', []):
        if o.get('severity') in ('error', 'warning'):
            findings.append(
                f\"{entry['path']}:{o.get('start_row', 0) + 1} \"
                f\"[{o.get('severity')}/{o.get('check')}] {o.get('message')}\"
            )
if findings:
    print('\n'.join(findings[:15]))
")

if [ -n "$REPORT" ]; then
  {
    echo "Theme Check meldet Probleme in der geänderten Datei:"
    echo "$REPORT"
    echo "Bitte beheben, bevor weitergearbeitet wird."
  } >&2
  exit 2
fi
exit 0
