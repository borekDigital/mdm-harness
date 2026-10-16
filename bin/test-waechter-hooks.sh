#!/usr/bin/env bash
# test-waechter-hooks.sh — Tests fuer die drei Waechter-Hooks (PreToolUse).
#
# Spec: .claude/specs/harness/waechter-hooks-fail-closed.md
# Jeder Waechter bekommt eine Hook-Eingabe auf stdin, geprueft wird der Exit-Code:
# 2 = blockiert, 0 = erlaubt. Kann ein Waechter nicht pruefen, muss er blockieren.
#
# Verwendung: bin/test-waechter-hooks.sh

set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS="$REPO/.claude/hooks"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PASS=0
FAIL=0

# PATH ohne python3: nur die Werkzeuge, die die Hooks sonst brauchen.
mkdir -p "$WORK/ohne-python"
for t in bash sh grep cat basename dirname mktemp rm sed tr head printf env; do
  p=$(command -v "$t" 2>/dev/null) && ln -s "$p" "$WORK/ohne-python/$t"
done

# python3, das beim ersten Aufruf funktioniert und danach scheitert:
# trifft gezielt die Rueckfrage (ask) in protect-merchant-files.
mkdir -p "$WORK/halb-python"
ECHT_PY=$(command -v python3)
cat > "$WORK/halb-python/python3" <<EOF
#!/bin/bash
Z="$WORK/halb-python/zaehler"
n=\$(cat "\$Z" 2>/dev/null || echo 0); echo \$((n + 1)) > "\$Z"
[ "\$n" -ge 1 ] && exit 1
exec "$ECHT_PY" "\$@"
EOF
chmod +x "$WORK/halb-python/python3"

mkdir -p "$WORK/leer"

json() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }
bash_in() { printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$(json "$1")"; }
edit_in() { printf '{"tool_name":"Edit","tool_input":{"file_path":%s,"old_string":"a","new_string":"b"}}' "$(json "$1")"; }

# erwartet <name> <exit> <hook> <stdin> [VAR=wert ...]
erwartet() {
  local name="$1" soll="$2" hook="$3" eingabe="$4"
  shift 4
  printf '%s' "$eingabe" | env CLAUDE_PROJECT_DIR="$REPO" "$@" /bin/bash "$HOOKS/$hook" \
    >"$WORK/out" 2>"$WORK/err"
  local ist=$?
  if [ "$ist" = "$soll" ]; then
    PASS=$((PASS + 1)); echo "  ok      $name"
  else
    FAIL=$((FAIL + 1)); echo "  FEHLER  $name (Exit $ist, erwartet $soll)"
    sed 's/^/          /' "$WORK/err" | head -3
  fi
}

# stdout enthaelt <text> (Rueckfrage als JSON)
ausgabe_enthaelt() {
  local name="$1" text="$2"
  if grep -q "$text" "$WORK/out"; then
    PASS=$((PASS + 1)); echo "  ok      $name"
  else
    FAIL=$((FAIL + 1)); echo "  FEHLER  $name (stdout: $(head -c 200 "$WORK/out"))"
  fi
}

# --- git-safety ----------------------------------------------------------
echo "git-safety"
G=git-safety.sh
erwartet "force-push blockiert"              2 $G "$(bash_in 'git push --force origin feature')"
erwartet "push auf main blockiert"           2 $G "$(bash_in 'git push origin main')"
erwartet "reset --hard blockiert"            2 $G "$(bash_in 'git reset --hard HEAD~1')"
erwartet "theme publish blockiert"           2 $G "$(bash_in 'shopify theme publish --theme 1')"
erwartet "git status erlaubt"                0 $G "$(bash_in 'git status --short')"
erwartet "git commit erlaubt"                0 $G "$(bash_in 'git commit -m "fix: x"')"
erwartet "ls erlaubt"                        0 $G "$(bash_in 'ls -la')"
erwartet "git -C dir push --force"           2 $G "$(bash_in 'git -C connector push --force')"
erwartet "git -c k=v push origin main"       2 $G "$(bash_in 'git -c user.name=x push origin main')"
erwartet "git -C \"a b\" reset --hard"       2 $G "$(bash_in 'git -C "a b" reset --hard')"
erwartet "git --git-dir=.git clean -fd"      2 $G "$(bash_in 'git --git-dir=.git --work-tree=. clean -fd')"
erwartet "git -C dir status erlaubt"         0 $G "$(bash_in 'git -C connector status')"
erwartet "kaputtes JSON blockiert"           2 $G '{"tool_name": "Bash", kaputt'
erwartet "leeres stdin blockiert"            2 $G ''
erwartet "command fehlt blockiert"           2 $G '{"tool_name":"Bash","tool_input":{}}'
erwartet "ohne python3 blockiert"            2 $G "$(bash_in 'ls')" PATH="$WORK/ohne-python"
# Spec bauplan-guard-fehlalarme: Text ist kein Befehl
erwartet "Commit-Message mit Force-Push-Text"  0 $G "$(bash_in 'git commit -m "git push --force ist verboten"')"
erwartet "Heredoc mit Force-Push-Text"       0 $G "$(bash_in "$(printf "cat <<'EOF'\ngit push --force\nEOF")")"
erwartet "PR-Text mit escapten Backticks"    0 $G "$(bash_in 'gh pr create --base main --body "Spec \`x.md\` ok"')"
erwartet "bash -c mit Force-Push blockiert"  2 $G "$(bash_in 'bash -c "git push --force"')"
erwartet "Pruefskript fehlt: blockiert"      2 $G "$(bash_in 'ls')" CLAUDE_PROJECT_DIR="$WORK/leer"

# --- protect-merchant-files ----------------------------------------------
echo "protect-merchant-files"
P=protect-merchant-files.sh
T="$WORK/p/themes/mdm"
mkdir -p "$T/config" "$T/sections"
echo x > "$T/sections/header.liquid"
erwartet "settings_data.json blockiert"      2 $P "$(edit_in "$T/config/settings_data.json")"
erwartet "mdm-Section erlaubt"               0 $P "$(edit_in "$T/sections/mdm-header.liquid")"
erwartet "Kerndatei fragt nach"              0 $P "$(edit_in "$T/sections/header.liquid")"
ausgabe_enthaelt "Kerndatei: permissionDecision ask" '"permissionDecision": "ask"'
erwartet "Datei ausserhalb erlaubt"          0 $P "$(edit_in "$WORK/p/README.md")"
erwartet "kaputtes JSON blockiert"           2 $P '{"tool_input": kaputt'
erwartet "leeres stdin blockiert"            2 $P ''
erwartet "file_path fehlt blockiert"         2 $P '{"tool_name":"Edit","tool_input":{}}'
erwartet "ohne python3 blockiert"            2 $P "$(edit_in "$T/sections/mdm-x.liquid")" PATH="$WORK/ohne-python"
rm -f "$WORK/halb-python/zaehler"
erwartet "Rueckfrage scheitert: blockiert"   2 $P "$(edit_in "$T/sections/header.liquid")" PATH="$WORK/halb-python:$PATH"

# --- bauplan-guard -------------------------------------------------------
echo "bauplan-guard"
B=bauplan-guard.sh
erwartet "rm docs/bauplan blockiert"         2 $B "$(bash_in 'rm -rf docs/bauplan/theme-mdm')"
erwartet "ls erlaubt"                        0 $B "$(bash_in 'ls docs')"
erwartet "Edit fremder Datei erlaubt"        0 $B "$(edit_in "$REPO/README.md")"
erwartet "kaputtes JSON blockiert"           2 $B '{"tool_name": kaputt'
erwartet "leeres stdin blockiert"            2 $B ''
erwartet "tool_name fehlt blockiert"         2 $B '{"tool_input":{"command":"ls"}}'
erwartet "Edit ohne file_path blockiert"     2 $B '{"tool_name":"Edit","tool_input":{}}'
erwartet "ohne python3 blockiert"            2 $B "$(bash_in 'ls')" PATH="$WORK/ohne-python"
erwartet "Pruefskript fehlt: blockiert"      2 $B "$(bash_in 'ls')" CLAUDE_PROJECT_DIR="$WORK/leer"
# Spec bauplan-guard-fehlalarme: nennen ist erlaubt, zerstoeren nicht
erwartet "grep mit 2>/dev/null erlaubt"      0 $B "$(bash_in 'grep -n tech workspace.yaml 2>/dev/null')"
erwartet "Session-Befehl #1 erlaubt"         0 $B "$(bash_in "git pull -q 2>/dev/null; grep -n 'tech: \"PHP' workspace.yaml")"
erwartet "Heredoc nennt Bestand erlaubt"     0 $B "$(bash_in "$(printf "python3 - <<'PY'\nopen('x.txt', 'w').write('workspace.yaml')\nPY")")"
erwartet "cat | head erlaubt"                0 $B "$(bash_in 'cat docs/bauplan/index.html | head')"
erwartet "mv workspace.yaml blockiert"       2 $B "$(bash_in 'mv workspace.yaml w.bak')"
erwartet "Umleitung auf Manifest blockiert"  2 $B "$(bash_in 'echo x > .claude/bauplan/theme-mdm.manifest.json')"
erwartet "git rm docs/bauplan blockiert"     2 $B "$(bash_in 'git rm -r docs/bauplan')"
erwartet "rm -rf docs blockiert"             2 $B "$(bash_in 'rm -rf docs')"

echo
echo "$PASS ok, $FAIL Fehler"
[ "$FAIL" -eq 0 ]
