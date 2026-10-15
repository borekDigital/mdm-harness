#!/usr/bin/env bash
# theme-sync.sh — Gleiche Aenderungen zwischen den Marken-Themes bewegen.
#
# Die drei Themes (themes/mdm, themes/borek, themes/imm) teilen KEINE Git-Historie
# — drei getrennte Wurzel-Commits. `git merge` scheidet damit aus. Was sie teilen,
# sind rund 90 Prozent identische Dateien. Eine Aenderung wandert deshalb als
# Patch von Arbeitsbaum zu Arbeitsbaum, nicht als Merge.
#
# Verwendung:
#   theme-sync.sh list
#   theme-sync.sh drift [pfad-praefix]
#   theme-sync.sh settings <schluessel>
#   theme-sync.sh port <quelle> <ziel[,ziel]> <pfad> [<pfad> ...]
#   theme-sync.sh port <quelle> <ziel[,ziel]> --commit <sha> [--as-patch]
#   theme-sync.sh align <quelle> <ziel[,ziel]> [--branch <name>] [--report <datei>]
#
# Beispiele:
#   theme-sync.sh drift sections/
#   theme-sync.sh port mdm borek,imm sections/mdm-card-product.liquid
#   theme-sync.sh port mdm borek --commit 49f6f62
#   theme-sync.sh port mdm borek,imm --commit 2bc9365 --as-patch
#
# Zwei Uebertragungsarten:
#   ohne --as-patch  ganze Datei kopieren. Richtig, wenn Quelle und Ziel sonst
#                    identisch sind. Ueberschreibt abweichende Zielarbeit.
#   mit  --as-patch  nur die Hunks des Commits anwenden. Richtig, wenn die Quelle
#                    in derselben Datei vorauslaeuft. Braucht --commit. Ein Ziel,
#                    auf das der Patch nicht passt, wird uebersprungen.
#
# align bringt das Ziel auf den committeten Stand der Quelle: alle gemeinsamen
# Theme-Dateien ausser markenspezifischen, die geteilten Templates mit dem Layout
# der Zielmarke, neue Dateien dazu. Geloescht wird nichts. Der Branch (Standard
# sync/theme-<quelle>) wird vom aktuellen Stand des Ziels neu aufgebaut. Eigene
# Aenderungen des Ziels, die dabei ueberschrieben werden, meldet align — es
# sperrt sie nicht. --report schreibt die PR-Beschreibung (nur mit einem Ziel).
#
# Markenspezifische Pfade bleiben liegen. --allow-brand hebt den Schutz fuer den
# ganzen Lauf auf, --allow-brand=<pfad>[,<pfad>] nur fuer die genannten Pfade.
# Ausnahme sind die PLP- und PDP-Templates (SHARED_TEMPLATES): Sie sind seit dem
# 15. Oktober 2026 in allen Marken gleich. Jedes kopierte Template bekommt das
# Layout der Zielmarke (layout/<marke>-theme.liquid).
#
# Exit-Codes von port und align:
#   0  alle Ziele geschrieben
#   1  Abbruch vor der Ziel-Schleife — kein Ziel beruehrt
#   2  teilweise — mindestens ein Ziel geschrieben, mindestens eines uebersprungen
#   3  kein Ziel geschrieben, alle uebersprungen
#
# Das Skript committet nie und pusht nie. Es legt im Ziel einen Branch an und
# laesst die Aenderung dort unveraendert stehen — pruefen und committen ist
# Handarbeit. Ob eine Aenderung inhaltlich in die Zielmarke passt, prueft es
# nicht: `settings <schluessel>` vergleicht Layout-Grundwerte, die visuelle
# Gegenprobe im Ziel-Theme bleibt Voraussetzung.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# THEME_SYNC_THEMES_DIR lenkt auf Wegwerf-Themes um (bin/test-theme-sync.sh).
THEMES_DIR="${THEME_SYNC_THEMES_DIR:-${ROOT}/themes}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ -t 1 ]]; then
  BOLD="\033[1m"; DIM="\033[2m"; RED="\033[31m"; GREEN="\033[32m"
  YELLOW="\033[33m"; CYAN="\033[36m"; RESET="\033[0m"
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; CYAN=""; RESET=""
fi

# --- Markenspezifische Pfade -------------------------------------------------
# Diese Dateien gehoeren der Marke, nicht der Codebasis. Sie zwischen Themes zu
# kopieren ueberschreibt Live-Einstellungen, Uebersetzungen oder Seitenaufbau.
# Bewusst uebertragen: --allow-brand.
BRAND_PATTERNS='
config/settings_data.json
config/settings_schema.json
config/markets.json
locales/*
templates/*
sections/*-group.json
layout/*
.shopifyignore
.gitignore
README.md
temp/*
'

# --- Geteilte Templates ------------------------------------------------------
# Seit dem Call mit Bhavani am 15. Oktober 2026 nutzen alle Marken auf PLP und PDP
# dieselben Templates, Vorlage ist MDM. Markenspezifisch bleibt nur der
# layout-Schluessel. Weitere Templates kommen erst nach Abstimmung dazu.
SHARED_TEMPLATES='
templates/collection.json
templates/collection.mdm.json
templates/product.json
templates/product.mdm.json
'

is_shared_template() {
  local path="$1" entry
  while IFS= read -r entry; do
    [[ "$entry" != "$path" ]] || return 0
  done <<< "$SHARED_TEMPLATES"
  return 1
}

is_brand_path() {
  local path="$1" pattern
  is_shared_template "$path" && return 1
  # Zeilenweise lesen statt `for pattern in $BRAND_PATTERNS`: unquotiert expandiert
  # die Shell templates/* gegen das aktuelle Verzeichnis. Im Workspace-Root liegt
  # ein Ordner templates/ — die Sperre traf dort dessen Dateien statt der Themes.
  while IFS= read -r pattern; do
    [[ -n "$pattern" ]] || continue
    # shellcheck disable=SC2254
    case "$path" in $pattern) return 0 ;; esac
  done <<< "$BRAND_PATTERNS"
  return 1
}

# Jedes Theme rendert seine Templates ueber layout/<marke>-theme.liquid. Ein
# kopiertes Template bekommt deshalb das Layout der Zielmarke; das der Quelle
# gibt es dort nicht. Ausgabe auf stdout.
with_target_layout() {
  local file="$1" src="$2" target="$3"
  sed "s/^  \"layout\": \"${src}-theme\",\$/  \"layout\": \"${target}-theme\",/" "$file"
}

# Ist dieser markenspezifische Pfad ausdruecklich freigegeben?
# ALLOW_BRAND_LIST leer  -> nichts freigegeben
# ALLOW_BRAND_LIST "ALL" -> alles freigegeben (--allow-brand ohne Wert)
# sonst                  -> nur die genannten Pfade
is_allowed_brand_path() {
  local path="$1" entry
  [[ -n "$ALLOW_BRAND_LIST" ]] || return 1
  [[ "$ALLOW_BRAND_LIST" != "ALL" ]] || return 0
  for entry in ${ALLOW_BRAND_LIST//,/ }; do
    [[ "$entry" != "$path" ]] || return 0
  done
  return 1
}

# --- Themes ermitteln --------------------------------------------------------
# Ein Verzeichnis unter themes/ zaehlt nur als Theme, wenn es ein Git-Repo mit
# Shopify-Struktur ist. Nicht geklonte Marken werden still uebersprungen —
# abwesend heisst uebersprungen, nicht abgeschafft.
discover_themes() {
  local d name
  for d in "$THEMES_DIR"/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    [[ -d "${d}.git" ]] || continue
    [[ -f "${d}config/settings_schema.json" ]] || continue
    echo "$name"
  done
}

theme_dir() { echo "${THEMES_DIR}/$1"; }

assert_theme() {
  # Ohne Pipe pruefen: ein frueh schliessender Leser (grep -q) liesse
  # discover_themes an SIGPIPE sterben und mit pipefail den Test scheitern.
  local t="$1" candidate found=false
  for candidate in $(discover_themes); do
    if [[ "$candidate" == "$t" ]]; then found=true; break; fi
  done
  if [[ "$found" == false ]]; then
    echo -e "${RED}FEHLER:${RESET} '$t' ist kein geklontes Theme unter themes/." >&2
    echo -e "  Vorhanden: $(discover_themes | tr '\n' ' ')" >&2
    exit 1
  fi
}

# --- list --------------------------------------------------------------------
cmd_list() {
  echo ""
  echo -e "${BOLD}  Themes unter themes/${RESET}"
  echo ""
  local t dir branch dirty
  for t in $(discover_themes); do
    dir="$(theme_dir "$t")"
    branch="$(git -C "$dir" branch --show-current 2>/dev/null || echo '?')"
    if [[ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]]; then
      dirty="${YELLOW}uncommittete Aenderungen${RESET}"
    else
      dirty="${GREEN}sauber${RESET}"
    fi
    printf "  %-8s %-28s %b\n" "$t" "$branch" "$dirty"
  done
  echo ""
}

# --- drift -------------------------------------------------------------------
# Zeigt, welche gemeinsamen Dateien zwischen den Themes auseinanderlaufen.
# Verglichen wird der Arbeitsbaum (nicht HEAD) — das ist der Stand, den man sieht.
cmd_drift() {
  local prefix="${1:-}"
  local themes
  themes="$(discover_themes)"
  local count
  count="$(echo "$themes" | grep -c . || true)"
  if [[ "$count" -lt 2 ]]; then
    echo -e "${RED}FEHLER:${RESET} Mindestens zwei geklonte Themes noetig (gefunden: $count)." >&2
    exit 1
  fi

  local t dir p h
  for t in $themes; do
    dir="$(theme_dir "$t")"
    git -C "$dir" ls-files > "${TMP}/fl-${t}"
    # hash-object liest die Pfade in derselben Reihenfolge und liefert je Zeile
    # den Blob-Hash des Arbeitsbaums.
    git -C "$dir" hash-object --stdin-paths < "${TMP}/fl-${t}" > "${TMP}/h-${t}" 2>/dev/null
    paste "${TMP}/fl-${t}" "${TMP}/h-${t}" > "${TMP}/ph-${t}"
    # Geteilte Templates unterscheiden sich gewollt im layout-Schluessel. Fuer den
    # Vergleich zaehlt er nicht, sonst stuende jedes davon dauerhaft im Bericht.
    while IFS= read -r p; do
      [[ -n "$p" && -f "${dir}/${p}" ]] || continue
      h="$(with_target_layout "${dir}/${p}" "$t" "MARKE" | git -C "$dir" hash-object --stdin)"
      awk -v p="$p" -v h="$h" 'BEGIN { FS = OFS = "\t" } $1 == p { $2 = h } { print }' \
        "${TMP}/ph-${t}" > "${TMP}/ph-${t}.tmp"
      mv "${TMP}/ph-${t}.tmp" "${TMP}/ph-${t}"
    done <<< "$SHARED_TEMPLATES"
  done

  echo ""
  echo -e "${BOLD}  Drift zwischen den Themes${RESET}${prefix:+ ${DIM}(nur ${prefix})${RESET}}"
  echo -e "${DIM}  Verglichen wird der Arbeitsbaum. = gleich, | trennt Gruppen.${RESET}"
  echo ""

  # shellcheck disable=SC2086
  THEMES="$themes" PREFIX="$prefix" BRAND_PATTERNS="$BRAND_PATTERNS" SHARED_TEMPLATES="$SHARED_TEMPLATES" \
    awk -f /dev/stdin $(for t in $themes; do echo "${TMP}/ph-${t}"; done) \
    > "${TMP}/drift.out" <<'AWK'
BEGIN {
  n = split(ENVIRON["THEMES"], themes, /[ \t\n]+/)
  # split laesst bei fuehrendem/abschliessendem Whitespace Leerstrings zurueck
  m = 0
  for (i = 1; i <= n; i++) if (themes[i] != "") order[++m] = themes[i]
  bn = split(ENVIRON["BRAND_PATTERNS"], bp, /[ \t\n]+/)
  sn = split(ENVIRON["SHARED_TEMPLATES"], sp, /[ \t\n]+/)
  for (i = 1; i <= sn; i++) if (sp[i] != "") shared[sp[i]] = 1
  prefix = ENVIRON["PREFIX"]
}
FNR == 1 {
  # Dateiname -> Theme-Name (ph-<theme>)
  cur = FILENAME
  sub(/.*\/ph-/, "", cur)
}
{
  path = $1; hash = $2
  key = path SUBSEP cur
  seen[key] = hash
  present[path] = present[path] " " cur
}
function is_brand(p,   i, pat, rx) {
  if (p in shared) return 0
  for (i = 1; i <= bn; i++) {
    pat = bp[i]
    if (pat == "") continue
    rx = pat
    gsub(/\./, "\\.", rx)
    gsub(/\*/, ".*", rx)
    if (p ~ ("^" rx "$")) return 1
  }
  return 0
}
END {
  drift = 0; brandskip = 0; only = 0
  for (path in present) {
    if (prefix != "" && index(path, prefix) != 1) continue

    # in wie vielen Themes vorhanden?
    cnt = 0
    for (i = 1; i <= m; i++) if ((path SUBSEP order[i]) in seen) cnt++
    if (cnt < 2) { if (prefix == "" || index(path, prefix) == 1) only++; continue }

    if (is_brand(path)) { brandskip++; continue }

    # Gruppen gleicher Inhalte bilden, Reihenfolge stabil halten
    gcount = 0
    for (i = 1; i <= m; i++) {
      t = order[i]
      k = path SUBSEP t
      if (!(k in seen)) continue
      h = seen[k]
      found = 0
      for (g = 1; g <= gcount; g++) if (ghash[g] == h) { gmem[g] = gmem[g] "=" t; found = 1; break }
      if (!found) { gcount++; ghash[gcount] = h; gmem[gcount] = t }
    }
    if (gcount < 2) continue          # alle gleich -> kein Drift

    line = ""
    for (g = 1; g <= gcount; g++) line = line (g > 1 ? " | " : "") gmem[g]
    printf "  %-58s %s\n", path, line
    drift++
  }
  # Die Zusammenfassung wird markiert, damit die Shell die Dateizeilen
  # sortieren kann, ohne sie zwischen die Zeilen zu mischen.
  summary = sprintf("  %d Datei(en) mit Drift", drift)
  if (brandskip > 0) summary = summary sprintf(", %d markenspezifisch (uebersprungen)", brandskip)
  if (only > 0) summary = summary sprintf(", %d nur in einem Theme", only)
  printf "SUMMARY\t%s\n", summary
}
AWK

  grep -v '^SUMMARY' "${TMP}/drift.out" | sort || true
  echo ""
  grep '^SUMMARY' "${TMP}/drift.out" | cut -f2- || true
  echo ""
}

# --- settings ----------------------------------------------------------------
# Vergleicht einen Schluessel aus config/settings_data.json ueber alle Themes.
# Layout-Grundwerte wie page_width entscheiden, ob eine uebertragene CSS-Regel
# in der Zielmarke dieselbe Wirkung hat. Die Dateien beginnen mit einem
# /* ... */-Kommentarblock und sind damit kein reines JSON.
cmd_settings() {
  local key="${1:-}"
  [[ -n "$key" ]] || { echo -e "${RED}FEHLER:${RESET} Schluessel fehlt. Beispiel: theme-sync.sh settings page_width" >&2; exit 1; }

  echo ""
  echo -e "${BOLD}  settings_data.json · ${key}${RESET}"
  echo ""

  local t dir value
  for t in $(discover_themes); do
    dir="$(theme_dir "$t")"
    value="$(THEME_KEY="$key" python3 - "${dir}/config/settings_data.json" <<'PYEOF'
import json, os, re, sys
try:
    raw = open(sys.argv[1], encoding='utf-8').read()
except OSError:
    print('(Datei fehlt)'); sys.exit(0)
raw = re.sub(r'/\*.*?\*/', '', raw, flags=re.S)
try:
    data = json.loads(raw)
except ValueError as exc:
    print('(kein JSON: %s)' % exc); sys.exit(0)
current = data.get('current', {})
if isinstance(current, str):
    current = data.get('presets', {}).get(current, {})
print(current.get(os.environ['THEME_KEY'], '(nicht gesetzt)'))
PYEOF
)"
    printf "  %-8s %s\n" "$t" "$value"
  done
  echo ""
  echo -e "${DIM}  Gleiche Werte heissen: eine uebertragene Layout-Regel wirkt in allen Marken gleich.${RESET}"
  echo -e "${DIM}  Sie heissen nicht, dass die Regel fuer jede Marke gewollt ist.${RESET}"
  echo ""
}

# --- port --------------------------------------------------------------------
cmd_port() {
  local src="${1:-}" targets_raw="${2:-}"
  shift 2 || true
  [[ -n "$src" && -n "$targets_raw" ]] || { usage; exit 1; }
  assert_theme "$src"

  local as_patch=false commit_sha="" paths=()
  ALLOW_BRAND_LIST=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --allow-brand) ALLOW_BRAND_LIST="ALL"; shift ;;
      --allow-brand=*) ALLOW_BRAND_LIST="${1#--allow-brand=}"; shift ;;
      --as-patch) as_patch=true; shift ;;
      --commit) commit_sha="${2:-}"; shift 2 ;;
      -*) echo -e "${RED}FEHLER:${RESET} Unbekannte Option $1" >&2; exit 1 ;;
      *) paths+=("$1"); shift ;;
    esac
  done

  if [[ "$as_patch" == true && -z "$commit_sha" ]]; then
    echo -e "${RED}FEHLER:${RESET} --as-patch braucht --commit <sha> als Grundlage." >&2
    echo -e "${DIM}  Ein Patch braucht einen Vorher-Stand; einzelne Pfade liefern den nicht.${RESET}" >&2
    exit 1
  fi

  local targets
  targets="$(echo "$targets_raw" | tr ',' ' ')"
  local t
  for t in $targets; do
    assert_theme "$t"
    [[ "$t" != "$src" ]] || { echo -e "${RED}FEHLER:${RESET} Quelle und Ziel sind identisch ($t)." >&2; exit 1; }
  done

  local src_dir
  src_dir="$(theme_dir "$src")"

  # Pfade aus einem Commit ableiten, wenn --commit gegeben ist
  if [[ -n "$commit_sha" ]]; then
    if [[ ${#paths[@]} -gt 0 ]]; then
      echo -e "${RED}FEHLER:${RESET} --commit und einzelne Pfade schliessen sich aus." >&2; exit 1
    fi
    git -C "$src_dir" rev-parse --verify "${commit_sha}^{commit}" >/dev/null 2>&1 \
      || { echo -e "${RED}FEHLER:${RESET} Commit $commit_sha nicht in $src gefunden." >&2; exit 1; }
    while IFS= read -r p; do
      [[ -n "$p" ]] && paths+=("$p")
    done < <(git -C "$src_dir" show --pretty=format: --name-only "$commit_sha" | grep -v '^$' || true)
    echo -e "${DIM}  Commit $commit_sha beruehrt ${#paths[@]} Datei(en).${RESET}"
  fi

  [[ ${#paths[@]} -gt 0 ]] || { echo -e "${RED}FEHLER:${RESET} Keine Pfade angegeben." >&2; exit 1; }

  # Pfade pruefen: markenspezifisch? in der Quelle vorhanden?
  local usable=() skipped=() missing=() p
  for p in "${paths[@]}"; do
    if is_brand_path "$p" && ! is_allowed_brand_path "$p"; then
      skipped+=("$p"); continue
    fi
    if [[ ! -f "${src_dir}/${p}" ]]; then
      missing+=("$p"); continue
    fi
    usable+=("$p")
  done

  echo ""
  local mode_label="ganze Dateien"
  [[ "$as_patch" == true ]] && mode_label="Patch aus ${commit_sha}"
  echo -e "${BOLD}  port: ${src} -> ${targets_raw}${RESET} ${DIM}(${mode_label})${RESET}"
  echo ""
  if [[ ${#skipped[@]} -gt 0 ]]; then
    echo -e "  ${YELLOW}Markenspezifisch, nicht uebertragen${RESET} ${DIM}(--allow-brand=<pfad> gibt einzeln frei)${RESET}:"
    for p in "${skipped[@]}"; do echo "    - $p"; done
    echo ""
  fi
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "  ${YELLOW}In ${src} nicht vorhanden (z. B. spaeter geloescht), uebersprungen:${RESET}"
    for p in "${missing[@]}"; do echo "    - $p"; done
    echo ""
  fi
  if [[ ${#usable[@]} -eq 0 ]]; then
    echo -e "  ${RED}Nichts zu uebertragen.${RESET}"
    echo ""
    exit 1
  fi

  # Patch aus dem Commit erzeugen — nur ueber die nicht-markenspezifischen Pfade.
  local patch_file=""
  if [[ "$as_patch" == true ]]; then
    if ! git -C "$src_dir" rev-parse --verify "${commit_sha}^^{commit}" >/dev/null 2>&1; then
      echo -e "${RED}FEHLER:${RESET} $commit_sha hat keinen Vorgaenger (Wurzel-Commit) — kein Patch ableitbar." >&2
      exit 1
    fi
    patch_file="${TMP}/port.patch"
    git -C "$src_dir" diff "${commit_sha}^" "$commit_sha" -- "${usable[@]}" > "$patch_file"
    if [[ ! -s "$patch_file" ]]; then
      echo -e "  ${RED}Patch ist leer — nach dem Filtern bleibt nichts uebrig.${RESET}"
      echo ""
      exit 1
    fi
    echo -e "  ${DIM}Patch aus ${commit_sha}: $(command grep -c '^@@' "$patch_file") Hunk(s) ueber ${#usable[@]} Datei(en).${RESET}"
    echo ""
  fi

  local branch
  branch="sync/${src}-$(date +%Y-%m-%d)"
  local written=0 skipped_targets=0

  local has_templates=false
  for p in "${usable[@]}"; do
    [[ "$p" != templates/*.json ]] || has_templates=true
  done

  for t in $targets; do
    local dir prev
    dir="$(theme_dir "$t")"
    prev="$(git -C "$dir" branch --show-current 2>/dev/null || echo '')"

    if [[ -n "$(git -C "$dir" status --porcelain)" ]]; then
      echo -e "  ${RED}${t}: uebersprungen — Arbeitsbaum nicht sauber.${RESET}"
      echo -e "  ${DIM}    Erst committen oder stashen, dann erneut.${RESET}"
      skipped_targets=$((skipped_targets + 1))
      continue
    fi

    # Ein kopiertes Template zeigt auf layout/<ziel>-theme.liquid — ohne die Datei
    # waere es im Ziel nicht renderbar.
    if [[ "$as_patch" == false && "$has_templates" == true && ! -f "${dir}/layout/${t}-theme.liquid" ]]; then
      echo -e "  ${RED}${t}: uebersprungen — layout/${t}-theme.liquid fehlt.${RESET}"
      echo -e "  ${DIM}    Templates bekommen beim Kopieren das Layout der Zielmarke.${RESET}"
      skipped_targets=$((skipped_targets + 1))
      continue
    fi

    # Erst pruefen, dann den Branch anlegen. Sonst bliebe ein Ziel, auf das der
    # Patch nicht passt, auf einem leeren sync-Branch stehen.
    if [[ "$as_patch" == true ]] && ! git -C "$dir" apply --check "$patch_file" 2>/dev/null; then
      echo -e "  ${RED}${t}: uebersprungen — Patch passt nicht.${RESET}"
      echo -e "  ${DIM}    Der Kontext weicht ab. Von Hand uebertragen:${RESET}"
      echo -e "  ${DIM}    git -C themes/${t} apply --3way --reject <patch>${RESET}"
      skipped_targets=$((skipped_targets + 1))
      continue
    fi

    if git -C "$dir" rev-parse --verify "$branch" >/dev/null 2>&1; then
      git -C "$dir" checkout "$branch" >/dev/null 2>&1
      echo -e "  ${CYAN}${t}${RESET}: Branch ${branch} ${DIM}(bestand bereits, vorher: ${prev})${RESET}"
    else
      git -C "$dir" checkout -b "$branch" >/dev/null 2>&1
      echo -e "  ${CYAN}${t}${RESET}: Branch ${branch} ${DIM}(neu, vorher: ${prev})${RESET}"
    fi

    if [[ "$as_patch" == true ]]; then
      git -C "$dir" apply "$patch_file"
      local touched
      touched="$(git -C "$dir" diff --name-only | wc -l | tr -d ' ')"
      while IFS= read -r p; do
        [[ -n "$p" ]] && echo -e "    ${GREEN}~${RESET} $p"
      done < <(git -C "$dir" diff --name-only)
      echo -e "    ${DIM}${touched} Datei(en) gepatcht — nicht committet.${RESET}"
    else
      local changed=0 identical=0
      for p in "${usable[@]}"; do
        mkdir -p "$(dirname "${dir}/${p}")"
        local from="${src_dir}/${p}"
        if [[ "$p" == templates/*.json ]]; then
          from="${TMP}/template-${t}.json"
          with_target_layout "${src_dir}/${p}" "$src" "$t" > "$from"
        fi
        if [[ -f "${dir}/${p}" ]] && cmp -s "$from" "${dir}/${p}"; then
          identical=$((identical + 1))
          continue
        fi
        cp "$from" "${dir}/${p}"
        echo -e "    ${GREEN}+${RESET} $p"
        changed=$((changed + 1))
      done
      echo -e "    ${DIM}${changed} geaendert, ${identical} bereits identisch — nicht committet.${RESET}"
    fi
    written=$((written + 1))
  done

  echo ""
  echo -e "  ${BOLD}Ergebnis${RESET}: ${written} Ziel(e) geschrieben, ${skipped_targets} uebersprungen."
  echo -e "  ${BOLD}Naechster Schritt${RESET} je geschriebenem Ziel-Theme:"
  echo -e "    ${DIM}git -C themes/<ziel> diff        # pruefen${RESET}"
  echo -e "    ${DIM}git -C themes/<ziel> commit -am \"…\"${RESET}"
  echo -e "    ${DIM}danach im Zielshop ansehen — die Anwendbarkeit sagt nichts ueber die Wirkung${RESET}"
  echo ""

  # 0 alles geschrieben · 2 teilweise · 3 nichts geschrieben, alles uebersprungen
  if [[ "$skipped_targets" -eq 0 ]]; then
    return 0
  elif [[ "$written" -gt 0 ]]; then
    return 2
  else
    return 3
  fi
}

# --- align -------------------------------------------------------------------
# Nur diese Ordner gehoeren zum Theme. Alles andere im Repo (README, CI,
# .theme-check.yml) bleibt der jeweiligen Marke.
THEME_DIRS_RE='^(assets|blocks|config|layout|locales|sections|snippets|templates)/'

brand_label() {
  case "$1" in
    mdm|imm) echo "$1" | tr '[:lower:]' '[:upper:]' ;;
    *) echo "$1" | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }' ;;
  esac
}

german_date() {
  local months=(Januar Februar März April Mai Juni Juli August September Oktober November Dezember)
  echo "$((10#$(date +%d))). ${months[$((10#$(date +%m) - 1))]} $(date +%Y)"
}

# Hat das Ziel in dieser Datei einen Stand, den es in der Quelle nie gab? Dann
# ist es eine eigene Aenderung des Ziels und kein veralteter Quellstand.
# Geteilte Templates werden dafuer auf das Layout der Quelle zurueckgesetzt.
target_has_own_change() {
  local src_dir="$1" dir="$2" p="$3" src="$4" t="$5" blob
  if [[ "$p" == templates/*.json ]]; then
    blob="$(with_target_layout "${dir}/${p}" "$t" "$src" | git -C "$dir" hash-object --stdin)"
  else
    blob="$(git -C "$dir" hash-object -- "$p")"
  fi
  git -C "$src_dir" log --format= --raw --no-abbrev -- "$p" > "${TMP}/blobs"
  ! awk -v b="$blob" '$3 == b || $4 == b { found = 1 } END { exit !found }' "${TMP}/blobs"
}

# Wer hat die Datei im Ziel zuletzt geaendert? Bei Bot-Commits steht die Person
# aus dem Theme-Editor im Commit-Text.
last_change_row() {
  local dir="$1" p="$2" when author body editor
  when="$(git -C "$dir" log -1 --format=%ad --date=format-local:'%d.%m.%Y %H:%M' -- "$p")"
  author="$(git -C "$dir" log -1 --format=%an -- "$p")"
  if [[ "$author" == "shopify[bot]" ]]; then
    body="$(git -C "$dir" log -1 --format=%b -- "$p")"
    editor="$(sed -n 's/^Theme last edited by: //p' <<< "$body")"
    author="Theme-Editor (${editor%%$'\n'*})"
  fi
  echo "| \`${p}\` | ${when} | ${author} |"
}

# Schluessel aus den Locale-Dateien der Quelle, die dem Ziel fehlen. Schluessel
# aus dem Sprachen-Editor (customer_accounts.*, shopify.*) bleiben aussen vor.
missing_locale_keys() {
  python3 - "$1" "$2" <<'PYEOF'
import json, os, re, sys
src, dst = sys.argv[1], sys.argv[2]
skip = ('customer_accounts.', 'shopify.')
def load(path):
    try:
        raw = open(path, encoding='utf-8').read()
    except OSError:
        return None
    raw = re.sub(r'^\s*/\*.*?\*/', '', raw, count=1, flags=re.S)
    try:
        return json.loads(raw)
    except ValueError:
        return None
def flat(d, prefix=''):
    keys = set()
    for k, v in d.items():
        key = prefix + '.' + k if prefix else k
        keys |= flat(v, key) if isinstance(v, dict) else {key}
    return keys
ldir = os.path.join(src, 'locales')
names = sorted(os.listdir(ldir)) if os.path.isdir(ldir) else []
for name in names:
    if not name.endswith('.json'):
        continue
    a = load(os.path.join(ldir, name))
    b = load(os.path.join(dst, 'locales', name))
    if not isinstance(a, dict) or not isinstance(b, dict):
        continue
    miss = sorted(k for k in flat(a) - flat(b) if not k.startswith(skip))
    if miss:
        shown = ', '.join('`%s`' % k for k in miss[:15])
        more = ' und %d weitere' % (len(miss) - 15) if len(miss) > 15 else ''
        print('locales/%s\t%d\t%s%s' % (name, len(miss), shown, more))
PYEOF
}

cmd_align() {
  local src="${1:-}" targets_raw="${2:-}"
  shift 2 || true
  [[ -n "$src" && -n "$targets_raw" ]] || { usage; exit 1; }
  assert_theme "$src"

  local branch="sync/theme-${src}" report=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --branch) branch="${2:-}"; shift 2 ;;
      --report) report="${2:-}"; shift 2 ;;
      *) echo -e "${RED}FEHLER:${RESET} Unbekannte Option $1" >&2; exit 1 ;;
    esac
  done

  local targets t count=0
  targets="$(echo "$targets_raw" | tr ',' ' ')"
  for t in $targets; do
    assert_theme "$t"
    [[ "$t" != "$src" ]] || { echo -e "${RED}FEHLER:${RESET} Quelle und Ziel sind identisch ($t)." >&2; exit 1; }
    count=$((count + 1))
  done
  if [[ -n "$report" && "$count" -gt 1 ]]; then
    echo -e "${RED}FEHLER:${RESET} --report schreibt die Beschreibung fuer genau ein Ziel." >&2
    exit 1
  fi

  local src_dir src_sha src_label
  src_dir="$(theme_dir "$src")"
  src_sha="$(git -C "$src_dir" rev-parse --short HEAD)"
  src_label="$(brand_label "$src")"
  git -C "$src_dir" ls-files | grep -E "$THEME_DIRS_RE" > "${TMP}/align-src" || true

  echo ""
  echo -e "${BOLD}  align: ${src} @ ${src_sha} -> ${targets_raw}${RESET} ${DIM}(Branch ${branch})${RESET}"
  echo ""

  local written=0 skipped_targets=0
  for t in $targets; do
    local dir t_label base p from
    dir="$(theme_dir "$t")"
    t_label="$(brand_label "$t")"

    if [[ -n "$(git -C "$dir" status --porcelain)" ]]; then
      echo -e "  ${RED}${t}: uebersprungen — Arbeitsbaum nicht sauber.${RESET}"
      skipped_targets=$((skipped_targets + 1))
      continue
    fi
    if [[ ! -f "${dir}/layout/${t}-theme.liquid" ]]; then
      echo -e "  ${RED}${t}: uebersprungen — layout/${t}-theme.liquid fehlt.${RESET}"
      echo -e "  ${DIM}    Templates bekommen beim Abgleich das Layout der Zielmarke.${RESET}"
      skipped_targets=$((skipped_targets + 1))
      continue
    fi

    base="$(git -C "$dir" branch --show-current 2>/dev/null || true) $(git -C "$dir" rev-parse --short HEAD)"
    git -C "$dir" checkout -q -B "$branch"
    echo -e "  ${CYAN}${t}${RESET}: Branch ${branch} ${DIM}(neu aufgebaut auf ${base})${RESET}"

    : > "${TMP}/rows"
    : > "${TMP}/own"
    while IFS= read -r p; do
      [[ -n "$p" && -f "${src_dir}/${p}" ]] || continue
      if is_brand_path "$p"; then continue; fi
      from="${src_dir}/${p}"
      if [[ "$p" == templates/*.json ]]; then
        from="${TMP}/template-${t}.json"
        with_target_layout "${src_dir}/${p}" "$src" "$t" > "$from"
      fi
      if [[ ! -f "${dir}/${p}" ]]; then
        mkdir -p "$(dirname "${dir}/${p}")"
        cp "$from" "${dir}/${p}"
        echo "| \`${p}\` | neu |" >> "${TMP}/rows"
        echo -e "    ${GREEN}+${RESET} $p"
      elif ! cmp -s "$from" "${dir}/${p}"; then
        if target_has_own_change "$src_dir" "$dir" "$p" "$src" "$t"; then
          last_change_row "$dir" "$p" >> "${TMP}/own"
          echo -e "    ${YELLOW}⚠${RESET} $p ${YELLOW}— eigene Aenderung in ${t_label} wird ueberschrieben${RESET}"
        else
          echo -e "    ${GREEN}~${RESET} $p"
        fi
        cp "$from" "${dir}/${p}"
        if [[ "$p" == templates/*.json ]]; then
          echo "| \`${p}\` | geändert, Layout \`${t}-theme\` |" >> "${TMP}/rows"
        else
          echo "| \`${p}\` | geändert |" >> "${TMP}/rows"
        fi
      fi
    done < "${TMP}/align-src"

    local changed own_count
    changed="$(grep -c . "${TMP}/rows" || true)"
    own_count="$(grep -c . "${TMP}/own" || true)"
    echo -e "    ${DIM}${changed} Datei(en) abgeglichen, ${own_count} mit eigener Aenderung im Ziel — nicht committet.${RESET}"
    if [[ "$own_count" -gt 0 ]]; then
      echo -e "    ${YELLOW}Gegenrichtung pruefen: gewollt (${t_label} folgt ${src_label}) oder Fehler (Aenderung gehoert erst nach ${src_label})?${RESET}"
    fi

    [[ -z "$report" ]] || align_report "$src" "$t" "$src_dir" "$dir" "$src_sha" "$report"
    written=$((written + 1))
  done

  echo ""
  echo -e "  ${BOLD}Ergebnis${RESET}: ${written} Ziel(e) abgeglichen, ${skipped_targets} uebersprungen."
  echo ""
  if [[ "$skipped_targets" -eq 0 ]]; then
    return 0
  elif [[ "$written" -gt 0 ]]; then
    return 2
  else
    return 3
  fi
}

# PR-Beschreibung fuer ein Ziel aus den Zwischenstaenden von cmd_align.
align_report() {
  local src="$1" t="$2" src_dir="$3" dir="$4" src_sha="$5" out="$6"
  local src_label t_label last="" history
  src_label="$(brand_label "$src")"
  t_label="$(brand_label "$t")"

  # Letzter uebernommener Stand: Commit- oder PR-Titel des vorigen Syncs im Ziel.
  history="$(git -C "$dir" log -n 300 --format=%B)"
  last="$(sed -n -E "s/.*(align with ${src} main|sync\/theme-${src}: .* @) ([0-9a-f]{7,40}).*/\2/p" <<< "$history")"
  last="${last%%$'\n'*}"
  if [[ -n "$last" ]] && ! git -C "$src_dir" rev-parse -q --verify "${last}^{commit}" >/dev/null; then
    last=""
  fi

  {
    echo "Übernimmt den Stand von ${src_label} \`main\` @ ${src_sha} nach ${t_label} ($(german_date))."
    echo ""
    if [[ -z "$last" ]]; then
      echo "Erster Sync — in ${t_label} ist kein früherer Sync-Commit zu finden."
    else
      local line sha author subject bots=0
      echo "Seit dem letzten Sync (\`${last}\`):"
      echo ""
      while IFS=$'\x1f' read -r sha author subject; do
        [[ -n "$sha" ]] || continue
        if [[ "$author" == "shopify[bot]" ]]; then
          bots=$((bots + 1))
        else
          echo "- \`${sha}\` ${subject}"
        fi
      done < <(git -C "$src_dir" log --first-parent --format='%h%x1f%an%x1f%s' "${last}..HEAD")
      [[ "$bots" -eq 0 ]] || echo "- ${bots} Commit(s) aus dem ${src_label}-Theme-Editor (shopify[bot])"
    fi
    echo ""

    echo "## Enthalten"
    echo ""
    if [[ -s "${TMP}/rows" ]]; then
      echo "| Datei | Änderung |"
      echo "|---|---|"
      cat "${TMP}/rows"
    else
      echo "Keine Unterschiede — ${t_label} entspricht bereits dem Stand von ${src_label}."
    fi
    echo ""

    if [[ -s "${TMP}/own" ]]; then
      echo "## ⚠️ Prüfen: Änderungen in ${t_label}, die dieser Sync überschreibt"
      echo ""
      echo "Diese Dateien haben in ${t_label} einen Stand, den es in ${src_label} nie gab. Gewollt (${t_label} folgt ${src_label}) oder ein Fehler (die Änderung gehört zuerst nach ${src_label})?"
      echo ""
      echo "| Datei | letzte Änderung in ${t_label} | von |"
      echo "|---|---|---|"
      cat "${TMP}/own"
      echo ""
    fi

    if [[ -n "$last" ]]; then
      local shared_list=() s sha when body editor files
      while IFS= read -r s; do [[ -n "$s" ]] && shared_list+=("$s"); done <<< "$SHARED_TEMPLATES"
      git -C "$src_dir" log --author='^shopify\[bot\]' --format=%h "${last}..HEAD" -- "${shared_list[@]}" > "${TMP}/editor"
      if [[ -s "${TMP}/editor" ]]; then
        echo "## ⚠️ Im ${src_label}-Theme-Editor geändert"
        echo ""
        echo "Diese geteilten Templates wurden seit dem letzten Sync im ${src_label}-Theme-Editor gespeichert und gehen mit."
        echo ""
        echo "| Commit | Datum | von | Dateien |"
        echo "|---|---|---|---|"
        while IFS= read -r sha; do
          when="$(git -C "$src_dir" log -1 --format=%ad --date=format-local:'%d.%m.%Y %H:%M' "$sha")"
          body="$(git -C "$src_dir" log -1 --format=%b "$sha")"
          editor="$(sed -n 's/^Theme last edited by: //p' <<< "$body")"
          files="$(git -C "$src_dir" show --name-only --format= "$sha" -- "${shared_list[@]}" | sed 's/.*/`&`/' | paste -sd, - | sed 's/,/, /g')"
          echo "| \`${sha}\` | ${when} | ${editor%%$'\n'*} | ${files} |"
        done < "${TMP}/editor"
        echo ""
      fi
    fi

    local locales brand_changed=""
    locales="$(missing_locale_keys "$src_dir" "$dir")"
    if [[ -n "$last" ]]; then
      while IFS= read -r p; do
        [[ -n "$p" ]] || continue
        if is_brand_path "$p"; then brand_changed="${brand_changed}${brand_changed:+, }\`${p}\`"; fi
      done < <(git -C "$src_dir" diff --name-only "$last" HEAD | grep -E "$THEME_DIRS_RE" || true)
    fi
    if [[ -n "$locales" || -n "$brand_changed" ]]; then
      echo "## Nicht übertragen (markenspezifisch)"
      echo ""
      local file n keys
      while IFS=$'\t' read -r file n keys; do
        [[ -n "$file" ]] || continue
        if [[ "$n" -eq 1 ]]; then
          echo "- \`${file}\`: 1 Schlüssel aus ${src_label} fehlt in ${t_label}: ${keys}"
        else
          echo "- \`${file}\`: ${n} Schlüssel aus ${src_label} fehlen in ${t_label}: ${keys}"
        fi
      done <<< "$locales"
      [[ -z "$brand_changed" ]] || echo "- Seit dem letzten Sync in ${src_label} geändert: ${brand_changed}"
      [[ -z "$locales" ]] || echo "- Ausgenommen sind Schlüssel aus dem Sprachen-Editor (\`customer_accounts.*\`, \`shopify.*\`)."
      echo ""
    fi

    git -C "$dir" ls-files | grep -E "$THEME_DIRS_RE" > "${TMP}/align-dst" || true
    local only=()
    while IFS= read -r p; do
      [[ -n "$p" ]] || continue
      if is_brand_path "$p"; then continue; fi
      grep -qxF -- "$p" "${TMP}/align-src" || only+=("$p")
    done < "${TMP}/align-dst"
    if [[ ${#only[@]} -gt 0 ]]; then
      echo "## Nur in ${t_label} vorhanden"
      echo ""
      echo "Nicht gelöscht. Prüfen, ob sie in ${src_label} entfernt wurden oder zu ${t_label} gehören."
      echo ""
      for p in "${only[@]}"; do echo "- \`${p}\`"; done
      echo ""
    fi

    echo "## Vor dem Merge"
    echo ""
    echo "- [ ] Warnungen oben entschieden"
    echo "- [ ] Vorschau im ${t_label}-Store geprüft"
    echo "- [ ] Merge auf \`main\` ist ein Deploy auf das veröffentlichte ${t_label}-Theme"
  } > "$out"
  echo -e "    ${DIM}Bericht: ${out}${RESET}"
}

usage() {
  # Kopfkommentar bis zur ersten Leerzeile — kein fester Zeilenbereich, damit
  # ein Nachtrag im Kopf die Hilfe nicht abschneidet.
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

main() {
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
    list)     cmd_list ;;
    drift)    cmd_drift "$@" ;;
    settings) cmd_settings "$@" ;;
    port)     cmd_port "$@" ;;
    align)    cmd_align "$@" ;;
    ""|-h|--help|help) usage ;;
    *) echo -e "${RED}FEHLER:${RESET} Unbekanntes Kommando '$cmd'" >&2; usage >&2; exit 1 ;;
  esac
}

main "$@"
