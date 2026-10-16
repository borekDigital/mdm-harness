#!/usr/bin/env bash
# test-sync-sauber.sh — Nach git pull plus post-merge-Hook bleibt git status sauber.
#
# Spec: .claude/specs/harness/bauplan-index-lokal-sauber.md (AK1, AK2, AK4, Befund 16)
# Jeder Fall laeuft in einer Kopie des Arbeitsbaums als eigenes Git-Repo. Lokaler
# Zustand (STALE-Bericht, Ledger) liegt dort wie im echten Checkout. Die Kopie liegt
# unter <HOME>/MDM — dorthin faellt bauplan_lib ohne --project zurueck, wie in ~/MDM.
#
# Verwendung: bin/test-sync-sauber.sh

set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PASS=0
FAIL=0

ok()   { echo "  ok    $1"; PASS=$((PASS + 1)); }
fehl() { echo "  FEHL  $1"; [ -n "${2:-}" ] && echo "$2" | sed 's/^/        /'; FAIL=$((FAIL + 1)); }

# Arbeitsbaum (versioniert plus neu, ohne Ignoriertes) als frisches Repo anlegen.
kopie() {
  local ziel="$1"
  mkdir -p "$ziel"
  (cd "$REPO" && git ls-files -z -c -o --exclude-standard \
    | while IFS= read -r -d '' f; do [ -e "$f" ] && printf '%s\0' "$f"; done \
    | tar --null -T - -cf -) | tar -xf - -C "$ziel"
  git -C "$ziel" init -q
  git -C "$ziel" add -A
  git -C "$ziel" -c user.name=test -c user.email=test@example.invalid commit -q -m stand
  # Alle Repos als installiert melden — sonst markiert sync.sh sie in CLAUDE.md
  # (Befund 12, eigene Spec) und der Test misst etwas anderes.
  {
    echo "installed:"
    grep -E "^  [a-z][a-z0-9-]*:$" "$ziel/workspace.yaml"
  } > "$ziel/.workspace.local.yaml"
  # Leere Repo-Verzeichnisse, damit die Konsistenzpruefung nicht jede Zeile anmahnt.
  sed -n 's/^    path: *"\{0,1\}\([^"]*\)"\{0,1\} *$/\1/p' "$ziel/workspace.yaml" \
    | while IFS= read -r d; do mkdir -p "$ziel/$d"; done
  # Lokaler Zustand wie nach einer Claude-Sitzung.
  cat > "$ziel/.claude/bauplan/harness.STALE.md" <<'EOF'
# Veraltete Blaetter — harness

## Etappe 1 — Aufbau

- `sync.sh`
EOF
  echo '{"etappe": 1, "file": "sync.sh"}' > "$ziel/.claude/bauplan/harness.staleness.jsonl"
}

post_merge() {
  # Wie git es tut: im Repo-Wurzelverzeichnis, ohne Claude-Umgebung.
  (cd "$1" && env -u CLAUDE_PROJECT_DIR HOME="$2" bash git-hooks/post-merge 2>&1)
}

status() { git -C "$1" status --porcelain; }

echo "Fall 1: post-merge mit STALE-Bericht"
WS="$WORK/home1/MDM"; kopie "$WS"
AUS=$(post_merge "$WS" "$WORK/home1")
S=$(status "$WS")
[ -z "$S" ] && ok "git status sauber" || fehl "git status sauber" "$S"
echo "$AUS" | grep -q "harness.*veraltet.*/repo-bauplan harness --refresh" \
  && ok "Konsole nennt veraltete Etappe (auch mit --quiet)" \
  || fehl "Konsole nennt veraltete Etappe (auch mit --quiet)" "$AUS"
grep -q 'f-alert">veraltet' "$WS/docs/bauplan/index.html" \
  && fehl "index.html ohne veraltet-Marker" || ok "index.html ohne veraltet-Marker"

echo "Fall 2: manuelles ./sync.sh"
S=$(cd "$WS" && env -u CLAUDE_PROJECT_DIR HOME="$WORK/home1" ./sync.sh >/dev/null 2>&1; status "$WS")
[ -z "$S" ] && ok "git status sauber" || fehl "git status sauber" "$S"

echo "Fall 3: Manifest geaendert, Uebersicht nicht neu erzeugt"
WS="$WORK/home3/MDM"; kopie "$WS"
python3 - "$WS/.claude/bauplan/harness.manifest.json" <<'PY'
import json, sys
p = sys.argv[1]
m = json.load(open(p, encoding="utf-8"))
m["etappen"][0]["title"] = m["etappen"][0]["title"] + " (neu)"
json.dump(m, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
PY
git -C "$WS" -c user.name=test -c user.email=test@example.invalid commit -q -am "upstream ohne Neubau"
AUS=$(post_merge "$WS" "$WORK/home3")
S=$(status "$WS")
[ -z "$S" ] && ok "git status sauber (nichts geschrieben)" || fehl "git status sauber (nichts geschrieben)" "$S"
echo "$AUS" | grep -q "weicht ab" && ok "Warnung: Uebersicht weicht ab" \
  || fehl "Warnung: Uebersicht weicht ab" "$AUS"

echo "Fall 4: Worktree schreibt nicht in den Haupt-Checkout (Befund 16)"
# HOME/MDM ist der Haupt-Checkout, auf den bauplan_lib ohne --project zurueckfaellt.
WS="$WORK/ws4"; kopie "$WS"
mkdir -p "$WORK/home4"; kopie "$WORK/home4/MDM"
post_merge "$WS" "$WORK/home4" >/dev/null
S=$(status "$WORK/home4/MDM")
[ -z "$S" ] && ok "Haupt-Checkout unberuehrt" || fehl "Haupt-Checkout unberuehrt" "$S"

# --- Spec harness-ohne-lokale-einrichtung ---------------------------------------

check() {
  # sync.sh --check wie im SessionStart-Hook und in der CI: ohne Claude-Umgebung.
  (cd "$1" && env -u CLAUDE_PROJECT_DIR HOME="$2" ./sync.sh --check --quiet 2>&1)
}
fingerabdruck() {
  # Inhalt und Aenderungszeit — "schreibt nichts" heisst beides unveraendert.
  for f in "$@"; do printf '%s %s\n' "$(cksum < "$f")" "$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f")"; done
}

echo "Fall 5: nur ein Repo geklont (Befund 6)"
WS="$WORK/home5/MDM"; kopie "$WS"
printf 'installed:\n  theme-mdm:\n' > "$WS/.workspace.local.yaml"
AUS=$(post_merge "$WS" "$WORK/home5")
S=$(status "$WS")
[ -z "$S" ] && ok "git status sauber" || fehl "git status sauber" "$S"
echo "$AUS" | grep -q "Nicht geklont.*connector" && ok "Konsole nennt nicht geklonte Repos" \
  || fehl "Konsole nennt nicht geklonte Repos" "$AUS"

echo "Fall 6: ohne .workspace.local.yaml"
WS="$WORK/home6/MDM"; kopie "$WS"
rm -f "$WS/.workspace.local.yaml"
post_merge "$WS" "$WORK/home6" >/dev/null
S=$(status "$WS")
[ -z "$S" ] && ok "git status sauber" || fehl "git status sauber" "$S"

echo "Fall 7: templates geaendert, CLAUDE.md nicht neu erzeugt"
WS="$WORK/home7/MDM"; kopie "$WS"
echo "Neue Zeile aus dem Template." >> "$WS/templates/footer.md"
git -C "$WS" -c user.name=test -c user.email=test@example.invalid commit -q -am "template ohne Neubau"
AUS=$(check "$WS" "$WORK/home7"); RC=$?
[ "$RC" -eq 3 ] && ok "--check endet mit 3" || fehl "--check endet mit 3 (ist $RC)" "$AUS"
echo "$AUS" | grep -q "CLAUDE.md.*\./sync.sh" && ok "Meldung nennt ./sync.sh" \
  || fehl "Meldung nennt ./sync.sh" "$AUS"
S=$(status "$WS")
[ -z "$S" ] && ok "--check schreibt nichts" || fehl "--check schreibt nichts" "$S"

echo "Fall 8: --check auf sauberem Stand"
WS="$WORK/home8/MDM"; kopie "$WS"
VORHER=$(fingerabdruck "$WS/CLAUDE.md" "$WS/.workspace.local.yaml")
sleep 1
AUS=$(check "$WS" "$WORK/home8"); RC=$?
[ "$RC" -eq 0 ] && ok "--check endet mit 0" || fehl "--check endet mit 0 (ist $RC)" "$AUS"
NACHHER=$(fingerabdruck "$WS/CLAUDE.md" "$WS/.workspace.local.yaml")
[ "$VORHER" = "$NACHHER" ] && ok "CLAUDE.md und .workspace.local.yaml unveraendert" \
  || fehl "CLAUDE.md und .workspace.local.yaml unveraendert" "$VORHER / $NACHHER"

echo "Fall 9: SessionStart-Hook"
HOOK="$REPO/.claude/hooks/harness-sync-check.sh"
hook() { (cd "$1" && env CLAUDE_PROJECT_DIR="$1" HOME="$2" bash "$HOOK" </dev/null 2>&1); }
AUS=$(hook "$WORK/home5/MDM" "$WORK/home5"); RC=$?
[ "$RC" -eq 0 ] && ok "Exit 0 bei Meldungen" || fehl "Exit 0 bei Meldungen (ist $RC)" "$AUS"
echo "$AUS" | python3 -c '
import json, sys
d = json.load(sys.stdin)
ctx = d["hookSpecificOutput"]["additionalContext"]
assert d["hookSpecificOutput"]["hookEventName"] == "SessionStart"
assert d["systemMessage"].strip()
assert "connector" in ctx and "abgeschafft" in ctx
' 2>/dev/null && ok "JSON mit systemMessage und additionalContext" \
  || fehl "JSON mit systemMessage und additionalContext" "$AUS"
rm -f "$WORK/home8/MDM/.claude/bauplan/harness.STALE.md" "$WORK/home8/MDM/.claude/bauplan/harness.staleness.jsonl"
AUS=$(hook "$WORK/home8/MDM" "$WORK/home8"); RC=$?
[ "$RC" -eq 0 ] && [ -z "$AUS" ] && ok "schweigt bei sauberem Stand" \
  || fehl "schweigt bei sauberem Stand (Exit $RC)" "$AUS"
mkdir -p "$WORK/leer"
AUS=$(hook "$WORK/leer" "$WORK/home8"); RC=$?
[ "$RC" -eq 0 ] && [ -z "$AUS" ] && ok "schweigt ohne sync.sh" || fehl "schweigt ohne sync.sh (Exit $RC)" "$AUS"

echo
echo "$PASS bestanden, $FAIL fehlgeschlagen"
[ "$FAIL" -eq 0 ]
