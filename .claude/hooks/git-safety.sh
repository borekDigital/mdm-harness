#!/bin/bash
# PreToolUse (Bash) — blocking
# Blockiert destruktive Git-Kommandos und riskante Shopify-CLI-Aufrufe.
CMD=$(python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null)

[ -z "$CMD" ] && exit 0

# --- Git-Schutz ---
if echo "$CMD" | grep -qE "(^|[[:space:];&|])git([[:space:]]|$)"; then
  if echo "$CMD" | grep -qE "git push.*(--force|-f)\b"; then
    echo "BLOCKED: Force-Push ist nicht erlaubt." >&2; exit 2
  fi
  if echo "$CMD" | grep -qE "git push\b.*(origin\s+)?(main|master)\b"; then
    echo "BLOCKED: Direkter Push auf main/master ist nicht erlaubt." >&2; exit 2
  fi
  if echo "$CMD" | grep -qE "git reset --hard"; then
    echo "BLOCKED: git reset --hard blockiert — nutze git stash." >&2; exit 2
  fi
  if echo "$CMD" | grep -qE "git clean.*-[a-z]*f"; then
    echo "BLOCKED: git clean -f blockiert." >&2; exit 2
  fi
  if echo "$CMD" | grep -qE "git push\b.*\blatori\b"; then
    echo "BLOCKED: Push auf Remote 'latori' ist nicht erlaubt — nur historische Referenz." >&2; exit 2
  fi
fi

# --- Shopify-CLI-Schutz ---
if echo "$CMD" | grep -qE "\bshopify\s+theme\b"; then
  if echo "$CMD" | grep -qE "\btheme\s+publish\b"; then
    echo "BLOCKED: 'theme publish' führt Konrad selbst im Admin/Terminal aus." >&2; exit 2
  fi
  if echo "$CMD" | grep -qE "\btheme\s+delete\b"; then
    echo "BLOCKED: 'theme delete' führt Konrad selbst aus." >&2; exit 2
  fi
  if echo "$CMD" | grep -qE "\btheme\s+push\b" && echo "$CMD" | grep -qE "(--live\b|\s-l\b|--allow-live\b)"; then
    echo "BLOCKED: Push auf das Live-Theme ist nicht erlaubt — nur --unpublished/--development." >&2; exit 2
  fi
  if echo "$CMD" | grep -qE -- "--theme-editor-sync"; then
    echo "BLOCKED: --theme-editor-sync löscht extern geänderte JSON-Dateien (CLI-Bug, community.shopify.dev/t/28292)." >&2; exit 2
  fi
fi

exit 0
