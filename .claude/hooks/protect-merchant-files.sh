#!/bin/bash
# PreToolUse (Edit|Write) — deny/ask für geschützte Theme-Dateien.
PAYLOAD=$(cat)
FILE=$(printf '%s' "$PAYLOAD" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

[ -z "$FILE" ] && exit 0

# settings_data.json: hart blockieren (Theme-Editor-Hoheit)
case "$FILE" in
  */theme/config/settings_data.json)
    echo "BLOCKED: config/settings_data.json wird vom Theme-Editor verwaltet — lokale Änderungen würden beim Push Live-Einstellungen überschreiben." >&2
    exit 2 ;;
esac

BASE=$(basename "$FILE")
PARENT=$(basename "$(dirname "$FILE")")

# AI-generierte Blöcke: nicht editieren (Shopify-generiert, Namen nicht änderbar)
case "$FILE" in
  */theme/blocks/ai_gen_block_*)
    echo "BLOCKED: ai_gen_block_*-Dateien werden vom Shopify-Theme-Editor generiert — nicht hand-editieren." >&2
    exit 2 ;;
esac

ask() {
  python3 -c "
import json, sys
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'ask', 'permissionDecisionReason': sys.argv[1]}}))
" "$1"
  exit 0
}

case "$PARENT" in
  sections|snippets|blocks)
    case "$BASE" in
      mdm-*) : ;;
      *)
        if [ -f "$FILE" ]; then
          ask "FoxEcom-Kerndatei ($PARENT/$BASE). Konvention: Kopie als $PARENT/mdm-$BASE anlegen statt das Original zu ändern. Trotzdem fortfahren?"
        else
          ask "Neue Datei ohne mdm--Präfix in $PARENT/. Konvention wäre: mdm-$BASE. Trotzdem fortfahren?"
        fi ;;
    esac ;;
  layout)
    case "$BASE" in
      mdm-*) : ;;
      *)
        if [ -f "$FILE" ]; then
          ask "Layout-Kerndatei ($BASE) — Änderungen wirken auf alle Seiten. Fortfahren?"
        fi ;;
    esac ;;
  templates|customers)
    if [ -f "$FILE" ]; then
      ask "Bestehendes Template ($BASE) — wird vom Theme-Editor mitverwaltet; lokale Änderungen können Editor-Stand überschreiben. Fortfahren?"
    fi ;;
esac

exit 0
