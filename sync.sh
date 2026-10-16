#!/usr/bin/env bash
# sync.sh — Regeneriert CLAUDE.md aus Templates + workspace.yaml
# und prueft Harness-Konsistenz.
#
# Idempotent: mehrfaches Ausfuehren liefert gleiches Ergebnis.
# Verwendung: ./sync.sh [--quiet] [--check]
#
#   --check  schreibt nichts: vergleicht CLAUDE.md, Bauplan-Uebersicht und Fusszeilen
#            mit dem, was sie sein muessten, und meldet lokale Hinweise. Exit 3, wenn
#            eine versionierte Datei abweicht, sonst 0. So laufen der SessionStart-Hook
#            und die CI (Spec harness-ohne-lokale-einrichtung).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_YAML="${SCRIPT_DIR}/workspace.yaml"
LOCAL_YAML="${SCRIPT_DIR}/.workspace.local.yaml"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
OUTPUT="${SCRIPT_DIR}/CLAUDE.md"
INDEX_SCRIPT="${SCRIPT_DIR}/bin/bauplan-index.py"
NAV_SCRIPT="${SCRIPT_DIR}/bin/bauplan-nav.py"
WORDING_SCRIPT="${SCRIPT_DIR}/bin/bauplan-wording.py"
QUIET=""
CHECK=""
for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET="--quiet" ;;
    --check) CHECK="--check" ;;
    *) echo "FEHLER: unbekannte Option ${arg} — erlaubt: --quiet, --check" >&2; exit 1 ;;
  esac
done
# Versionierte Dateien, die im Pruefmodus abweichen. Bestimmt den Exit-Code.
ABWEICHUNGEN=0

# --- Hilfsfunktionen ---

log() {
  [[ "$QUIET" == "--quiet" ]] && return
  echo "$1"
}

warn() {
  echo "  WARNUNG: $1" >&2
}

# Liest einen Wert aus workspace.yaml fuer ein bestimmtes Repo.
# Verwendung: yaml_get <repo_id> <field>
yaml_get() {
  local repo_id="$1" field="$2"
  sed -n "/^  ${repo_id}:$/,/^  [a-z]/p" "$WORKSPACE_YAML" \
    | grep "^    ${field}:" \
    | head -1 \
    | sed 's/^[^"]*"//; s/"$//'
}

# Alle Repo-IDs aus workspace.yaml extrahieren.
get_repo_ids() {
  grep -E "^  [a-z][a-z0-9-]*:$" "$WORKSPACE_YAML" | sed 's/://; s/^ *//'
}

# Prueft ob ein Repo lokal installiert ist (in .workspace.local.yaml).
is_installed() {
  local repo_id="$1"
  [[ -f "$LOCAL_YAML" ]] && grep -q "^  ${repo_id}:$" "$LOCAL_YAML"
}

# Prueft ob das Repo-Verzeichnis tatsaechlich existiert.
dir_exists() {
  local path
  path="$(yaml_get "$1" "path")"
  [[ -d "${SCRIPT_DIR}/${path}" ]]
}

# --- Repo-Tabelle generieren ---

# Eine kompakte Tabelle statt Baum + zwei Plattform-Tabellen. Pfade, Stack und
# Branch stehen im Manifest; die Remote-URLs nicht mehr — die stehen in der
# .git/config des jeweiligen Repos und muessen nicht in jede Session geladen
# werden. Die Tabelle nennt alle Repos aus dem Manifest und haengt nicht vom
# lokalen Klon ab: CLAUDE.md ist versioniert. Welche Repos hier fehlen, meldet
# report_nicht_geklont in der Konsole und beim Sitzungsstart (Guard-Semantik:
# nicht geklont heisst uebersprungen, nicht abgeschafft).
generate_repo_table() {
  local table=""
  table+='| Repo | Pfad | Stack | Branch |\n'
  table+='|---|---|---|---|\n'

  while IFS= read -r repo_id; do
    local name path tech branch
    name="$(yaml_get "$repo_id" "name")"
    path="$(yaml_get "$repo_id" "path")"
    tech="$(yaml_get "$repo_id" "tech")"
    branch="$(yaml_get "$repo_id" "branch")"
    table+="| ${name} | \`${path}\` | ${tech} | \`${branch}\` |\n"
  done < <(get_repo_ids)

  echo -e "$table"
}

# --- CLAUDE.md assemblieren ---

generate_claude_md() {
  local content=""

  # Header mit dynamischen Platzhaltern
  local header
  header="$(cat "${TEMPLATES_DIR}/header.md")"
  local repo_table
  repo_table="$(generate_repo_table)"

  header="${header/\{\{REPO_TABLE\}\}/$repo_table}"
  content+="${header}"

  # Repo-Sections. "themes" ist kein Repo-Schluessel, sondern der gemeinsame
  # Abschnitt der drei Marken-Themes (theme-mdm, theme-borek, theme-imm): sie
  # unterscheiden sich in der Marke, nicht in den Konventionen.
  local repo_order="themes connector datalayer middleware"
  for repo_id in $repo_order; do
    local tmpl="${TEMPLATES_DIR}/repo-${repo_id}.md"
    [[ -f "$tmpl" ]] || continue

    content+=$'\n'

    content+=$'\n'"$(cat "$tmpl")"
  done

  # Workflows + Footer
  content+=$'\n\n'"$(cat "${TEMPLATES_DIR}/workflows.md")"
  content+=$'\n\n'"$(cat "${TEMPLATES_DIR}/footer.md")"

  echo "$content"
}

# --- Bauplan-Uebersicht pruefen ---

# Prueft nur, schreibt nie unter docs/bauplan/. Uebersicht und Fusszeilen sind
# versioniert und werden im PR erzeugt, der ihre Eingaben aendert (Skill, CI).
# Schriebe dieser Lauf sie neu, waeren sie nach jedem Pull lokal geaendert —
# Spec bauplan-index-lokal-sauber. --project, weil bauplan_lib sonst auf
# ~/MDM zurueckfaellt: ein Lauf im Worktree traefe dann den Haupt-Checkout.
check_bauplan() {
  local script name rc
  for script in "$INDEX_SCRIPT" "$NAV_SCRIPT"; do
    [[ -x "$script" ]] || continue
    name="$(basename "$script")"
    rc=0
    "$script" --project "$SCRIPT_DIR" --check >/dev/null 2>&1 || rc=$?
    case "$rc" in
      0) ;;
      3) warn "${name}: versionierter Stand weicht ab — \`bin/${name}\` ausfuehren und mit dem PR committen, der die Eingaben aendert"
         ABWEICHUNGEN=$((ABWEICHUNGEN + 1)) ;;
      *) warn "${name} fehlgeschlagen (Exit ${rc})" ;;
    esac
  done
}

# Veraltete Etappen aus den lokalen STALE-Berichten. Nur Konsole, auch mit
# --quiet: nach einem Pull ist das die einzige Stelle, an der sie auftauchen.
report_veraltet() {
  [[ -x "$INDEX_SCRIPT" ]] || return 0
  local zeile
  while IFS= read -r zeile; do
    [[ -n "$zeile" ]] && echo "  Bauplan: $zeile"
  done < <("$INDEX_SCRIPT" --project "$SCRIPT_DIR" --veraltet 2>/dev/null || true)
}

# --- CLAUDE.md gegen Templates pruefen (nur --check) ---

check_claude_md() {
  local soll
  soll="$(generate_claude_md)"
  if [[ ! -f "$OUTPUT" ]] || [[ "$soll" != "$(cat "$OUTPUT")" ]]; then
    warn "CLAUDE.md weicht von templates/ und workspace.yaml ab — \`./sync.sh\` ausfuehren und mit dem PR committen"
    ABWEICHUNGEN=$((ABWEICHUNGEN + 1))
  fi
}

# --- Nicht geklonte Repos melden ---

# Ersetzt die fruehere Markierung in CLAUDE.md. Auch mit --quiet: nach einem
# Pull und beim Sitzungsstart ist das die Stelle, an der es auftaucht.
report_nicht_geklont() {
  local fehlend=() repo_id
  while IFS= read -r repo_id; do
    is_installed "$repo_id" || fehlend+=("$repo_id")
  done < <(get_repo_ids)
  [[ ${#fehlend[@]} -gt 0 ]] || return 0
  local liste
  liste="$(printf '%s, ' "${fehlend[@]}")"
  echo "  Nicht geklont (uebersprungen, nicht abgeschafft): ${liste%, }"
}

# --- Wording der Blattseiten melden ---

# Nicht blockierend: Prosa ist kein Linter-Gegenstand. Der Lauf meldet die
# Summe; behoben wird sie beim Auffrischen einer Etappe, nicht hier.
check_wording() {
  [[ -x "$WORDING_SCRIPT" ]] || return 0
  # Exit 3 heisst "Verstoesse gefunden", nicht "Lauf kaputt". Ohne das || true
  # bricht die Zuweisung unter set -e mitsamt sync.sh ab.
  local summe
  summe=$("$WORDING_SCRIPT" --quiet 2>/dev/null | tail -1) || true
  [[ -n "$summe" ]] || return 0
  case "$summe" in
    *" 0 Verstoesse"*) log "  → Wording: $summe" ;;
    *) warn "Wording: $summe" ;;
  esac
}

# --- Konsistenz pruefen ---

check_consistency() {
  local issues=0

  while IFS= read -r repo_id; do
    if is_installed "$repo_id" && ! dir_exists "$repo_id"; then
      warn "${repo_id} ist in .workspace.local.yaml aber Verzeichnis fehlt!"
      warn "  → \`./setup.sh --add\` oder Eintrag aus .workspace.local.yaml entfernen"
      issues=$((issues + 1))
    fi
  done < <(get_repo_ids)

  # Staleness-Check
  if [[ -f "$LOCAL_YAML" ]]; then
    local now
    now=$(date +%s)
    while IFS= read -r repo_id; do
      is_installed "$repo_id" || continue
      local last_sync
      last_sync=$(sed -n "/^  ${repo_id}:$/,/^  [a-z]/p" "$LOCAL_YAML" \
        | grep "last_sync:" | sed 's/^[^:]*: *//' | tr -d '"' || true)
      if [[ -n "$last_sync" ]]; then
        local sync_epoch
        sync_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_sync" +%s 2>/dev/null || echo 0)
        local days_ago=$(( (now - sync_epoch) / 86400 ))
        if [[ $days_ago -gt 7 ]]; then
          warn "${repo_id}: letzter Sync vor ${days_ago} Tagen (> 7 Tage)"
          issues=$((issues + 1))
        fi
      fi
    done < <(get_repo_ids)
  fi

  return $issues
}

# --- .workspace.local.yaml Timestamps aktualisieren ---

update_local_timestamps() {
  [[ -f "$LOCAL_YAML" ]] || return 0
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local tmp
  tmp=$(mktemp)

  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]+last_sync: ]]; then
      echo "    last_sync: \"${now}\"" >> "$tmp"
    else
      echo "$line" >> "$tmp"
    fi
  done < "$LOCAL_YAML"

  mv "$tmp" "$LOCAL_YAML"
}

# --- Hauptprogramm ---

main() {
  log "sync.sh — CLAUDE.md regenerieren und Konsistenz pruefen"
  log ""

  if [[ ! -f "$WORKSPACE_YAML" ]]; then
    echo "FEHLER: workspace.yaml nicht gefunden in ${SCRIPT_DIR}" >&2
    exit 1
  fi

  if [[ -n "$CHECK" ]]; then
    check_claude_md
  else
    log "  CLAUDE.md generieren..."
    generate_claude_md > "$OUTPUT"
    log "  → ${OUTPUT} geschrieben"
  fi
  report_nicht_geklont

  # Bauplan-Uebersicht pruefen (schreibt nicht)
  if [[ -x "$INDEX_SCRIPT" ]]; then
    log "  Bauplan-Uebersicht pruefen..."
    check_bauplan
    report_veraltet
  fi

  # Reihenfolge ist bindend: erst pruefen, dann stempeln. Umgekehrt liest
  # check_consistency den Zeitstempel, den derselbe Lauf gerade geschrieben hat
  # — der 7-Tage-Check kann dann nie ausloesen. Siehe Blattsatz Harness,
  # Etappe 1, Blatt 03 ("Zwei Fehler im 7-Tage-Check, die sich maskieren").

  # Konsistenz pruefen
  log ""
  log "  Konsistenz pruefen..."
  if check_consistency; then
    log "  → Alles konsistent"
  fi

  # Pruefmodus: kein Wording-Lauf (Prosa ist kein versionierter Stand), keine
  # Zeitstempel. Er schreibt nichts, auch nicht .workspace.local.yaml.
  if [[ -n "$CHECK" ]]; then
    log ""
    log "Fertig (Pruefmodus, nichts geschrieben)."
    [[ "$ABWEICHUNGEN" -eq 0 ]] || exit 3
    return 0
  fi

  check_wording

  # Erst jetzt stempeln — nach der Pruefung.
  if [[ -f "$LOCAL_YAML" ]]; then
    update_local_timestamps
  fi

  log ""
  log "Fertig."
}

main "$@"
