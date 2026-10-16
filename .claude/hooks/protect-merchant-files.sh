#!/bin/bash
# PreToolUse (Edit|Write) — deny/ask für geschützte Theme-Dateien.
# Fail-closed: Kann der Waechter nicht pruefen, blockiert er (Spec waechter-hooks-fail-closed).
blockiere() { echo "protect-merchant-files: $1 — Aktion blockiert (fail-closed)." >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || blockiere "python3 nicht gefunden"

PAYLOAD=$(cat)
FILE=$(printf '%s' "$PAYLOAD" | python3 -c "
import sys, json
try:
    f = json.load(sys.stdin)['tool_input']['file_path']
except Exception:
    sys.exit(3)
if not isinstance(f, str) or not f:
    sys.exit(3)
print(f)
" 2>/dev/null) || blockiere "Hook-Eingabe nicht lesbar"

# settings_data.json: hart blockieren (Theme-Editor-Hoheit)
case "$FILE" in
  */themes/*/config/settings_data.json)
    echo "BLOCKED: config/settings_data.json wird vom Theme-Editor verwaltet — lokale Änderungen würden beim Push Live-Einstellungen überschreiben." >&2
    exit 2 ;;
esac

BASE=$(basename "$FILE")
PARENT=$(basename "$(dirname "$FILE")")

# AI-generierte Blöcke: nicht editieren (Shopify-generiert, Namen nicht änderbar)
case "$FILE" in
  */themes/*/blocks/ai_gen_block_*)
    echo "BLOCKED: ai_gen_block_*-Dateien werden vom Shopify-Theme-Editor generiert — nicht hand-editieren." >&2
    exit 2 ;;
esac

ask() {
  # Erst erzeugen, dann ausgeben: scheitert python3 hier, faellt die Rueckfrage
  # nicht still weg, sondern die Aktion wird blockiert.
  local antwort
  antwort=$(python3 -c "
import json, sys
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'ask', 'permissionDecisionReason': sys.argv[1]}}))
" "$1" 2>/dev/null) && [ -n "$antwort" ] || blockiere "Rueckfrage nicht erzeugbar"
  printf '%s\n' "$antwort"
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
