#!/bin/bash
# PreToolUse (Bash) — blocking
# Blockiert destruktive Git-Kommandos und riskante Shopify-CLI-Aufrufe.
# Fail-closed: Kann der Waechter nicht pruefen, blockiert er (Spec waechter-hooks-fail-closed).
blockiere() { echo "git-safety: $1 — Aktion blockiert (fail-closed)." >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || blockiere "python3 nicht gefunden"

# Globale Git-Optionen vor dem Unterkommando entfernen, damit `git -C dir push --force`
# genauso erkannt wird wie `git push --force`.
CMD=$(python3 -c "
import sys, json, re
try:
    cmd = json.load(sys.stdin)['tool_input']['command']
except Exception:
    sys.exit(3)
if not isinstance(cmd, str) or not cmd.strip():
    sys.exit(3)
wert = r'(?:\"[^\"]*\"|\'[^\']*\'|\S+)'
opt = (r'(?:\s+-[Cc]\s+' + wert +
       r'|\s+--(?:git-dir|work-tree|namespace|exec-path|super-prefix|config-env)(?:=' + wert + r'|\s+' + wert + r')'
       r'|\s+--(?:no-pager|paginate|bare|literal-pathspecs|glob-pathspecs|noglob-pathspecs|no-replace-objects|no-optional-locks)'
       r'|\s+-[pP])')
print(re.sub(r'\bgit(?:' + opt + r')+', 'git', cmd))
" 2>/dev/null) || blockiere "Hook-Eingabe nicht lesbar"

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
