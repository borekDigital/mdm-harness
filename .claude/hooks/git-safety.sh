#!/bin/bash
# PreToolUse (Bash) — blocking
# Blockiert destruktive Git-Kommandos und riskante Shopify-CLI-Aufrufe.
# Regeln in bin/git-safety.py: geprueft werden zerlegte Befehle (bin/befehl.py), nicht Text —
# eine Commit-Message mit „git push --force“ ist kein Force-Push (Spec bauplan-guard-fehlalarme).
# Fail-closed: Kann der Waechter nicht pruefen, blockiert er (Spec waechter-hooks-fail-closed).
blockiere() { echo "git-safety: $1 — Aktion blockiert (fail-closed)." >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || blockiere "python3 nicht gefunden"

PROJECT="${CLAUDE_PROJECT_DIR:-$HOME/MDM}"
REGELN="$PROJECT/bin/git-safety.py"
[ -f "$REGELN" ] || blockiere "Regeln $REGELN fehlen"

python3 "$REGELN"
RC=$?
[ $RC -eq 0 ] && exit 0
[ $RC -eq 2 ] && exit 2
blockiere "Regelpruefung endete mit Exit $RC"
