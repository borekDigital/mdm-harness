#!/usr/bin/env bash
# test-theme-sync.sh — Tests fuer bin/theme-sync.sh gegen Wegwerf-Themes.
#
# Legt drei Mini-Themes (mdm, borek, imm) als Git-Repos in einem Temp-Verzeichnis
# an und ruft theme-sync.sh mit THEME_SYNC_THEMES_DIR darauf auf. Die echten
# Themes unter themes/ werden nicht beruehrt.
#
# Verwendung: bin/test-theme-sync.sh

set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/theme-sync.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
T="$WORK/themes"
PASS=0
FAIL=0

check() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    PASS=$((PASS + 1)); echo "  ok      $name"
  else
    FAIL=$((FAIL + 1)); echo "  FEHLER  $name"
  fi
}

# Ein JSON-Template wie aus dem Theme-Editor: Banner, dann layout als erster Schluessel.
template() {
  printf '/*\n * auto-generated\n */\n{\n  "layout": "%s-theme",\n  "sections": {\n    "main": {\n      "type": "%s"\n    }\n  },\n  "order": [\n    "main"\n  ]\n}\n' "$1" "$2"
}

commit_all() {
  git -C "$1" add -A
  git -C "$1" -c user.email=test@example.com -c user.name=test commit -qm "$2"
}

# Commit wie vom Shopify-Bot nach einer Aenderung im Theme-Editor.
bot_commit() {
  git -C "$1" add -A
  git -C "$1" -c user.email=bot@example.com -c 'user.name=shopify[bot]' commit -q \
    -m "Update from Shopify for theme shopifyFrontend_test/main" \
    -m "Committed from shop: Test" -m "Theme last edited by: $2"
}

# Locale-Datei mit /* */-Kopf wie im Theme; weitere Schluessel als "a.b=wert".
locale() {
  printf '/*\n * banner\n */\n'
  python3 - "$@" <<'PYEOF'
import json, sys
d = {"general": {"title": "Titel"}}
for arg in sys.argv[1:]:
    key, value = arg.split('=', 1)
    node = d
    *parents, last = key.split('.')
    for p in parents:
        node = node.setdefault(p, {})
    node[last] = value
print(json.dumps(d, indent=2, ensure_ascii=False))
PYEOF
}

not() { ! "$@"; }

make_theme() {
  local d="$T/$1"
  mkdir -p "$d/config" "$d/layout" "$d/templates" "$d/assets" "$d/sections" "$d/locales"
  echo '[]' > "$d/config/settings_schema.json"
  echo '{{ content_for_layout }}' > "$d/layout/$1-theme.liquid"
  template "$1" "mdm-main-collection-banner" > "$d/templates/collection.json"
  template "$1" "main-page" > "$d/templates/page.json"
  echo 'body { color: black; }' > "$d/assets/app.css"
  echo '<div class="mdm-x"></div>' > "$d/sections/mdm-x.liquid"
  locale > "$d/locales/de.json"
  git -C "$d" init -q -b main
  commit_all "$d" init
}

reset_themes() {
  rm -rf "$T"
  local m
  for m in mdm borek imm; do make_theme "$m"; done
}

# Aufruf wie im Alltag aus dem Workspace-Root. Der hat einen Ordner templates/
# (Vorlagen fuer CLAUDE.md) — ein ungeschuetztes Glob-Muster templates/* traefe
# dort diese Dateien statt der Theme-Templates.
mkdir -p "$WORK/root/templates"
echo '# header' > "$WORK/root/templates/header.md"

# Exit-Code in RC, Ausgabe in $WORK/out
run() {
  RC=0
  (cd "$WORK/root" && THEME_SYNC_THEMES_DIR="$T" "$SCRIPT" "$@") > "$WORK/out" 2>&1 || RC=$?
}

echo ""
echo "  port: geteilte Templates"
reset_themes
template mdm "mdm-breadcrumbs" > "$T/mdm/templates/collection.json"
run port mdm borek templates/collection.json
check "geteiltes Template wird uebertragen (Exit 0)" test "$RC" -eq 0
check "Inhalt gleich der Quelle bis auf layout" \
  diff <(sed 's/"layout": "mdm-theme"/"layout": "borek-theme"/' "$T/mdm/templates/collection.json") \
       "$T/borek/templates/collection.json"
check "layout zeigt auf das Layout der Zielmarke" \
  grep -q '^  "layout": "borek-theme",$' "$T/borek/templates/collection.json"

reset_themes
run port mdm borek templates/collection.json
check "nur im layout verschieden zaehlt als identisch" grep -q '0 geaendert, 1 bereits identisch' "$WORK/out"

echo ""
echo "  port: uebrige Templates"
reset_themes
template mdm "main-page-neu" > "$T/mdm/templates/page.json"
run port mdm borek templates/page.json
check "uebriges Template bleibt gesperrt (Exit 1)" test "$RC" -eq 1
check "Ziel bleibt unveraendert" git -C "$T/borek" diff --quiet
run port mdm borek templates/page.json --allow-brand=templates/page.json
check "freigegebenes Template wird uebertragen" grep -q 'main-page-neu' "$T/borek/templates/page.json"
check "freigegebenes Template bekommt das Ziel-Layout" \
  grep -q '^  "layout": "borek-theme",$' "$T/borek/templates/page.json"

echo ""
echo "  port: Ziel ohne eigenes Layout"
reset_themes
rm "$T/imm/layout/imm-theme.liquid"
commit_all "$T/imm" "layout entfernt"
template mdm "mdm-breadcrumbs" > "$T/mdm/templates/collection.json"
run port mdm borek,imm templates/collection.json
check "Ziel ohne <marke>-theme.liquid wird uebersprungen (Exit 2)" test "$RC" -eq 2
check "uebersprungenes Ziel bleibt unveraendert" git -C "$T/imm" diff --quiet
check "anderes Ziel wird geschrieben" grep -q 'mdm-breadcrumbs' "$T/borek/templates/collection.json"

echo ""
echo "  drift: geteilte Templates"
reset_themes
run drift templates/
check "nur layout verschieden ist kein Drift" grep -q '0 Datei(en) mit Drift' "$WORK/out"
template mdm "mdm-breadcrumbs" > "$T/mdm/templates/collection.json"
run drift templates/
check "abweichender Inhalt wird gemeldet" grep -q 'templates/collection.json' "$WORK/out"
check "uebrige Templates bleiben markenspezifisch" grep -q '1 markenspezifisch' "$WORK/out"

echo ""
echo "  align: Stand der Quelle uebernehmen"
reset_themes
echo 'body { color: red; }' > "$T/mdm/assets/app.css"
echo '<div class="neu"></div>' > "$T/mdm/sections/neu.liquid"
template mdm "mdm-breadcrumbs" > "$T/mdm/templates/collection.json"
template mdm "main-page-neu" > "$T/mdm/templates/page.json"
commit_all "$T/mdm" "feat: neue section"
echo '/* nur borek */' > "$T/borek/assets/borek-only.css"
commit_all "$T/borek" "feat: borek-eigene datei"
run align mdm borek --report "$WORK/r.md"
check "align endet mit Exit 0" test "$RC" -eq 0
check "Branch sync/theme-mdm ist ausgecheckt" test "$(git -C "$T/borek" branch --show-current)" = "sync/theme-mdm"
check "geaenderte Datei hat den Stand der Quelle" cmp "$T/mdm/assets/app.css" "$T/borek/assets/app.css"
check "neue Datei ist angelegt" cmp "$T/mdm/sections/neu.liquid" "$T/borek/sections/neu.liquid"
check "geteiltes Template uebernommen" grep -q 'mdm-breadcrumbs' "$T/borek/templates/collection.json"
check "geteiltes Template mit Ziel-Layout" grep -q '^  "layout": "borek-theme",$' "$T/borek/templates/collection.json"
check "uebriges Template bleibt unberuehrt" not grep -q 'main-page-neu' "$T/borek/templates/page.json"
check "Datei nur im Ziel wird nicht geloescht" test -f "$T/borek/assets/borek-only.css"
check "align committet nicht" test "$(git -C "$T/borek" log -1 --format=%s)" = "feat: borek-eigene datei"
check "Bericht: Quelle mit SHA" grep -qF "Übernimmt den Stand von MDM \`main\` @ $(git -C "$T/mdm" rev-parse --short HEAD)" "$WORK/r.md"
check "Bericht: geaenderte Datei" grep -qF '| `assets/app.css` | geändert |' "$WORK/r.md"
check "Bericht: neue Datei" grep -qF '| `sections/neu.liquid` | neu |' "$WORK/r.md"
check "Bericht: geteiltes Template mit Layout" grep -qF '| `templates/collection.json` | geändert, Layout `borek-theme` |' "$WORK/r.md"
check "Bericht: Datei nur im Ziel" grep -qF -- '- `assets/borek-only.css`' "$WORK/r.md"
check "Bericht: erster Sync erkannt" grep -qF 'Erster Sync' "$WORK/r.md"
check "Bericht: veralteter Zielstand ist keine Warnung" not grep -qF 'Prüfen: Änderungen in Borek' "$WORK/r.md"

echo ""
echo "  align: eigene Aenderungen im Ziel (Gegenrichtung melden, nicht sperren)"
reset_themes
echo 'body { color: blue; }' > "$T/borek/assets/app.css"
template borek "eigene-section" > "$T/borek/templates/collection.json"
bot_commit "$T/borek" "Bhavani"
echo 'body { color: red; }' > "$T/mdm/assets/app.css"
commit_all "$T/mdm" "fix: farbe"
run align mdm borek --report "$WORK/r.md"
check "eigene Ziel-Aenderung wird trotzdem ueberschrieben" cmp "$T/mdm/assets/app.css" "$T/borek/assets/app.css"
check "Bericht: Pruef-Abschnitt" grep -qF '## ⚠️ Prüfen: Änderungen in Borek, die dieser Sync überschreibt' "$WORK/r.md"
check "Bericht: Code-Datei mit Editor-Autor" grep -qE '^\| `assets/app\.css` \| .* \| Theme-Editor \(Bhavani\) \|$' "$WORK/r.md"
check "Bericht: geteiltes Template mit eigener Aenderung" grep -qE '^\| `templates/collection\.json` \| .* \| Theme-Editor \(Bhavani\) \|$' "$WORK/r.md"

echo ""
echo "  align: seit dem letzten Sync"
reset_themes
last="$(git -C "$T/mdm" rev-parse --short HEAD)"
git -C "$T/borek" -c user.email=t@example.com -c user.name=t commit -q --allow-empty -m "chore(sync): align with mdm main $last"
template mdm "mdm-breadcrumbs" > "$T/mdm/templates/collection.json"
bot_commit "$T/mdm" "Bhavani"
echo 'body { color: red; }' > "$T/mdm/assets/app.css"
echo '{{ content_for_layout }} <!-- neu -->' > "$T/mdm/layout/mdm-theme.liquid"
commit_all "$T/mdm" "Merge pull request #46 from borekDigital/fix/farbe"
run align mdm borek --report "$WORK/r.md"
check "Bericht: letzter Sync erkannt" grep -qF "Seit dem letzten Sync (\`$last\`)" "$WORK/r.md"
check "Bericht: MDM-Commit gelistet" grep -qF 'Merge pull request #46' "$WORK/r.md"
check "Bericht: MDM-Editor-Abschnitt" grep -qF '## ⚠️ Im MDM-Theme-Editor geändert' "$WORK/r.md"
check "Bericht: MDM-Editor-Commit mit Autor" grep -qE '^\| `[0-9a-f]{7}` \| .* \| Bhavani \| `templates/collection\.json` \|$' "$WORK/r.md"
check "Bericht: geaendertes Marken-Layout gemeldet" grep -qF '`layout/mdm-theme.liquid`' "$WORK/r.md"
check "Marken-Layout wird nicht uebertragen" not grep -q 'neu' "$T/borek/layout/borek-theme.liquid"

echo ""
echo "  align: Locale-Schluessel"
reset_themes
locale "mdm.neu=Neu" "shopify.checkout.x=X" > "$T/mdm/locales/de.json"
commit_all "$T/mdm" "feat: neuer schluessel"
run align mdm borek --report "$WORK/r.md"
check "Locale-Datei bleibt unberuehrt" git -C "$T/borek" diff --quiet -- locales/
check "Bericht: fehlender Schluessel gemeldet" grep -qF '`mdm.neu`' "$WORK/r.md"
check "Bericht: Sprachen-Editor-Schluessel ausgenommen" not grep -qF 'shopify.checkout.x' "$WORK/r.md"

echo ""
echo "  align: Randfaelle"
reset_themes
run align mdm borek --report "$WORK/r.md"
check "ohne Unterschied Exit 0" test "$RC" -eq 0
check "ohne Unterschied bleibt der Arbeitsbaum sauber" test -z "$(git -C "$T/borek" status --porcelain)"
check "Bericht: keine Unterschiede" grep -qF 'Keine Unterschiede' "$WORK/r.md"
run align mdm borek,imm --report "$WORK/r.md"
check "--report mit zwei Zielen wird abgelehnt (Exit 1)" test "$RC" -eq 1
reset_themes
echo 'body { color: red; }' > "$T/mdm/assets/app.css"
commit_all "$T/mdm" "fix: farbe"
echo 'lokal' > "$T/imm/assets/app.css"
run align mdm borek,imm
check "Ziel mit unsauberem Arbeitsbaum wird uebersprungen (Exit 2)" test "$RC" -eq 2
check "uebersprungenes Ziel bleibt wie es war" grep -q 'lokal' "$T/imm/assets/app.css"
check "anderes Ziel wird abgeglichen" cmp "$T/mdm/assets/app.css" "$T/borek/assets/app.css"

echo ""
echo "  ${PASS} bestanden, ${FAIL} fehlgeschlagen"
echo ""
[[ "$FAIL" -eq 0 ]]
