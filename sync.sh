#!/usr/bin/env bash
# sync.sh — Regeneriert CLAUDE.md aus Templates + workspace.yaml
# und prueft Harness-Konsistenz.
#
# Idempotent: mehrfaches Ausfuehren liefert gleiches Ergebnis.
# Verwendung: ./sync.sh [--quiet]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_YAML="${SCRIPT_DIR}/workspace.yaml"
LOCAL_YAML="${SCRIPT_DIR}/.workspace.local.yaml"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
OUTPUT="${SCRIPT_DIR}/CLAUDE.md"
INDEX_SCRIPT="${SCRIPT_DIR}/bin/bauplan-index.py"
NAV_SCRIPT="${SCRIPT_DIR}/bin/bauplan-nav.py"
QUIET="${1:-}"

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

# --- Workspace-Baum generieren ---

generate_tree() {
  local tree=""
  tree+='```\n'
  tree+='~/MDM/                        Workspace-Root (Harness-Repo)\n'

  while IFS= read -r repo_id; do
    local name path
    name="$(yaml_get "$repo_id" "name")"
    path="$(yaml_get "$repo_id" "path")"
    local marker=""
    if ! is_installed "$repo_id"; then
      marker=" (nicht installiert)"
    fi
    # Padding fuer Alignment
    local padded
    padded=$(printf "%-25s" "${path}")
    tree+="├── ${padded} ${name}${marker}\n"
  done < <(get_repo_ids)

  tree+='├── Tickets/                  Ticket-Artefakte (planuebergreifend)\n'
  tree+='├── .claude/                  Harness: Agenten, Skills, Hooks, Rules\n'
  tree+='├── .mcp.json                 MCP-Server\n'
  tree+='└── CLAUDE.md                 diese Datei (generiert durch sync.sh)\n'
  tree+='```'

  echo -e "$tree"
}

# --- Repo-Tabelle generieren ---

generate_repo_table() {
  local table=""

  # Shopify-Repos
  local repo_count
  repo_count=$(get_repo_ids | wc -l | tr -d ' ')
  table+="${repo_count} unabhaengige Git-Repos auf zwei Plattformen:\\n"
  table+='\n'
  table+='**Shopify-Repos** — GitHub via SSH-Alias `github.com-borek`\n'
  table+='(Key `~/.ssh/id_ed25519_borek`, GitHub-Account `Konrad-Thiemann`, Org `borekDigital`):\n'
  table+='\n'
  table+='| Repo | Pfad | Remote |\n'
  table+='|---|---|---|\n'

  while IFS= read -r repo_id; do
    local group
    group="$(yaml_get "$repo_id" "group")"
    [[ "$group" == "shopify" ]] || continue
    local name path remote
    name="$(yaml_get "$repo_id" "name")"
    path="$(yaml_get "$repo_id" "path")"
    remote="$(yaml_get "$repo_id" "remote")"
    table+="| ${name} | \`${path}\` | \`${remote}\` |\n"
  done < <(get_repo_ids)

  # Middleware-Repos
  table+='\n'
  table+='**Middleware-Repos** — GitLab (gitlab.mdm.de).\n'
  table+='Zugang zu gitlab.mdm.de erforderlich fuer diese Repos.\n'
  table+='\n'
  table+='| Repo | Pfad | Remote |\n'
  table+='|---|---|---|\n'

  while IFS= read -r repo_id; do
    local group
    group="$(yaml_get "$repo_id" "group")"
    [[ "$group" == "middleware" ]] || continue
    local name path remote
    name="$(yaml_get "$repo_id" "name")"
    path="$(yaml_get "$repo_id" "path")"
    remote="$(yaml_get "$repo_id" "remote")"
    table+="| ${name} | \`${path}\` | \`${remote}\` |\n"
  done < <(get_repo_ids)

  echo -e "$table"
}

# --- CLAUDE.md assemblieren ---

generate_claude_md() {
  local content=""

  # Header mit dynamischen Platzhaltern
  local header
  header="$(cat "${TEMPLATES_DIR}/header.md")"
  local tree
  tree="$(generate_tree)"
  local repo_table
  repo_table="$(generate_repo_table)"

  header="${header/\{\{WORKSPACE_TREE\}\}/$tree}"
  header="${header/\{\{REPO_TABLE\}\}/$repo_table}"
  content+="${header}"

  # Repo-Sections. "themes" ist kein Repo-Schluessel, sondern der gemeinsame
  # Abschnitt der drei Marken-Themes (theme-mdm, theme-borek, theme-imm): sie
  # unterscheiden sich in der Marke, nicht in den Konventionen.
  local repo_order="themes connector datalayer creditcheck emailservice payment-service"
  for repo_id in $repo_order; do
    local tmpl="${TEMPLATES_DIR}/repo-${repo_id}.md"
    [[ -f "$tmpl" ]] || continue

    content+=$'\n'

    if [[ "$repo_id" == "themes" ]]; then
      while IFS= read -r theme_id; do
        [[ "$theme_id" == theme-* ]] || continue
        is_installed "$theme_id" && continue
        local name
        name="$(yaml_get "$theme_id" "name")"
        content+=$'\n'"> **Hinweis:** ${name} ist nicht lokal installiert. \`./setup.sh --add\` zum Nachinstallieren."$'\n'
      done < <(get_repo_ids)
    elif ! is_installed "$repo_id"; then
      local name
      name="$(yaml_get "$repo_id" "name")"
      content+=$'\n'"> **Hinweis:** ${name} ist nicht lokal installiert. \`./setup.sh --add\` zum Nachinstallieren."$'\n'
    fi

    content+=$'\n'"$(cat "$tmpl")"
  done

  # Workflows + Footer
  content+=$'\n\n'"$(cat "${TEMPLATES_DIR}/workflows.md")"
  content+=$'\n\n'"$(cat "${TEMPLATES_DIR}/footer.md")"

  echo "$content"
}

# --- Bauplan-Uebersicht neu erzeugen ---

# Ersetzt das fruehere Patchen von harness-app/data.json. Die Uebersicht wird
# aus den Manifesten in .claude/bauplan/ erzeugt, nicht aus einer handgepflegten
# Datei — damit kann sie nicht mehr vom Bestand abweichen.
update_index() {
  [[ -x "$INDEX_SCRIPT" ]] || return 0
  local today
  today=$(date "+%-d. %B %Y" | sed 's/January/Januar/;s/February/Februar/;s/March/Maerz/;s/May/Mai/;s/June/Juni/;s/July/Juli/;s/October/Oktober/;s/December/Dezember/')
  "$INDEX_SCRIPT" --stand "$today" >/dev/null 2>&1 || warn "bauplan-index.py fehlgeschlagen"
  # Fusszeilen-Navigation aus demselben Manifest nachziehen. Idempotent —
  # kommt eine Etappe dazu, zeigt das Blatt davor danach auf sie.
  [[ -x "$NAV_SCRIPT" ]] || return 0
  "$NAV_SCRIPT" >/dev/null 2>&1 || warn "bauplan-nav.py fehlgeschlagen"
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

  # CLAUDE.md generieren
  log "  CLAUDE.md generieren..."
  generate_claude_md > "$OUTPUT"
  log "  → ${OUTPUT} geschrieben"

  # Bauplan-Uebersicht aktualisieren
  if [[ -x "$INDEX_SCRIPT" ]]; then
    log "  Bauplan-Uebersicht aktualisieren..."
    update_index
    log "  → docs/bauplan/index.html aktualisiert"
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

  # Erst jetzt stempeln — nach der Pruefung.
  if [[ -f "$LOCAL_YAML" ]]; then
    update_local_timestamps
  fi

  log ""
  log "Fertig."
}

main "$@"
