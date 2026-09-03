#!/bin/bash
# PostToolUse (Edit|Write) — blocking
# Fuehrt PHPStan/PHPCS aus und meldet Probleme NUR fuer die editierte Datei.
# Greift nur bei PHP-Dateien in creditcheck/, emailservice/, payment-service/.
PAYLOAD=$(cat)
FILE=$(printf '%s' "$PAYLOAD" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

# Nur PHP-Dateien in Middleware-Repos
case "$FILE" in
  */creditcheck/*.php|*/emailservice/*.php|*/payment-service/*.php) : ;;
  *) exit 0 ;;
esac
# Harness/Tickets ausschliessen
case "$FILE" in
  */.claude/*|*/Tickets/*) exit 0 ;;
esac

PROJECT="${CLAUDE_PROJECT_DIR:-$HOME/MDM}"

# Repo-Name aus Pfad extrahieren
REPO=""
case "$FILE" in
  */creditcheck/*)      REPO="creditcheck" ;;
  */emailservice/*)     REPO="emailservice" ;;
  */payment-service/*)  REPO="payment-service" ;;
esac
[ -z "$REPO" ] && exit 0

REPO_DIR="$PROJECT/$REPO/www"
[ -d "$REPO_DIR" ] || exit 0
cd "$REPO_DIR" || exit 0

# Relativen Pfad zum www/-Root berechnen
REL_FILE=$(printf '%s' "$FILE" | sed "s|.*$REPO/www/||")
[ -z "$REL_FILE" ] && exit 0

FINDINGS=""

# PHPStan (emailservice und payment-service haben es konfiguriert)
if [ -f "vendor/bin/phpstan" ] && [ -f "../phpstan.neon" -o -f "phpstan.neon" -o -f "phpstan.neon.dist" ]; then
  PHPSTAN_OUT=$(vendor/bin/phpstan analyse --no-progress --error-format=json "$REL_FILE" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
findings = []
for err in data.get('files', {}).values():
    for msg in err.get('messages', []):
        findings.append(f\":{msg.get('line', 0)} [phpstan] {msg.get('message', '')}\")
if findings:
    print('\n'.join(findings[:10]))
" 2>/dev/null)
  [ -n "$PHPSTAN_OUT" ] && FINDINGS="${FINDINGS}${PHPSTAN_OUT}\n"
fi

# PHPCS (emailservice hat es konfiguriert)
if [ -f "vendor/bin/phpcs" ] && [ -f "../phpcs.xml.dist" -o -f "phpcs.xml.dist" -o -f "phpcs.xml" ]; then
  PHPCS_OUT=$(vendor/bin/phpcs --report=json "$REL_FILE" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
findings = []
for path, info in data.get('files', {}).items():
    for msg in info.get('messages', []):
        sev = 'error' if msg.get('type') == 'ERROR' else 'warning'
        findings.append(f\":{msg.get('line', 0)} [{sev}/{msg.get('source', '')}] {msg.get('message', '')}\")
if findings:
    print('\n'.join(findings[:10]))
" 2>/dev/null)
  [ -n "$PHPCS_OUT" ] && FINDINGS="${FINDINGS}${PHPCS_OUT}\n"
fi

if [ -n "$FINDINGS" ]; then
  {
    echo "PHPStan/PHPCS meldet Probleme in $REPO/$REL_FILE:"
    printf '%b' "$FINDINGS"
    echo "Bitte beheben, bevor weitergearbeitet wird."
  } >&2
  exit 2
fi
exit 0
