#!/usr/bin/env bash
# setup.sh — Interaktives Setup fuer den MDM-Workspace.
# Klont ausgewaehlte Repos und richtet die lokale Umgebung ein.
#
# Verwendung:
#   ./setup.sh          Ersteinrichtung oder Nachinstallation
#   ./setup.sh --add    Nur fehlende Repos anbieten
#   ./setup.sh --reset  Lokalen State zuruecksetzen (Repos bleiben)
#   ./setup.sh --sync   Nur sync.sh ausfuehren (kein Menue)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_YAML="${SCRIPT_DIR}/workspace.yaml"
LOCAL_YAML="${SCRIPT_DIR}/.workspace.local.yaml"
MODE="${1:-}"

# --- Farben (falls Terminal das unterstuetzt) ---

if [[ -t 1 ]]; then
  BOLD="\033[1m"
  DIM="\033[2m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  CYAN="\033[36m"
  RESET="\033[0m"
else
  BOLD="" DIM="" GREEN="" YELLOW="" CYAN="" RESET=""
fi

# --- Hilfsfunktionen ---

yaml_get() {
  local repo_id="$1" field="$2"
  sed -n "/^  ${repo_id}:$/,/^  [a-z]/p" "$WORKSPACE_YAML" \
    | grep "^    ${field}:" \
    | head -1 \
    | sed 's/^[^"]*"//; s/"$//'
}

get_repo_ids() {
  grep -E "^  [a-z][a-z0-9-]*:$" "$WORKSPACE_YAML" | sed 's/://; s/^ *//'
}

is_installed() {
  local repo_id="$1"
  [[ -f "$LOCAL_YAML" ]] && grep -q "^  ${repo_id}:$" "$LOCAL_YAML"
}

dir_exists() {
  local path
  path="$(yaml_get "$1" "path")"
  [[ -d "${SCRIPT_DIR}/${path}" ]]
}

is_default() {
  local val
  val=$(sed -n "/^  ${1}:$/,/^  [a-z]/p" "$WORKSPACE_YAML" \
    | grep "^    default:" | head -1 | awk '{print $2}')
  [[ "$val" == "true" ]]
}

# --- Banner ---

show_banner() {
  echo ""
  echo -e "${BOLD}  MDM Workspace Setup${RESET}"
  echo -e "${DIM}  ────────────────────${RESET}"
  echo ""
}

# --- Repo-Auswahl Menue ---

show_menu() {
  local -n _selected=$1
  local only_missing="${2:-false}"

  # Sammle Repos pro Gruppe
  local shopify_repos=()
  local middleware_repos=()

  while IFS= read -r repo_id; do
    if [[ "$only_missing" == "true" ]] && dir_exists "$repo_id"; then
      continue
    fi
    local group
    group="$(yaml_get "$repo_id" "group")"
    if [[ "$group" == "shopify" ]]; then
      shopify_repos+=("$repo_id")
    else
      middleware_repos+=("$repo_id")
    fi
  done < <(get_repo_ids)

  if [[ ${#shopify_repos[@]} -eq 0 && ${#middleware_repos[@]} -eq 0 ]]; then
    echo -e "  ${GREEN}Alle Repos sind bereits geklont.${RESET}"
    echo ""
    return 1
  fi

  # Pruefe ob gum verfuegbar ist
  if command -v gum &>/dev/null; then
    show_menu_gum _selected shopify_repos middleware_repos
  else
    show_menu_bash _selected shopify_repos middleware_repos
  fi
}

# --- gum-basiertes Menue ---

show_menu_gum() {
  local -n _sel=$1
  local -n _shopify=$2
  local -n _mw=$3

  local items=()
  local defaults=()

  for repo_id in "${_shopify[@]}"; do
    local name tech
    name="$(yaml_get "$repo_id" "name")"
    tech="$(yaml_get "$repo_id" "tech")"
    local label="${repo_id}  —  ${name} (${tech})"
    items+=("$label")
    if is_default "$repo_id"; then
      defaults+=("$label")
    fi
  done

  for repo_id in "${_mw[@]}"; do
    local name tech
    name="$(yaml_get "$repo_id" "name")"
    tech="$(yaml_get "$repo_id" "tech")"
    local label="${repo_id}  —  ${name} (${tech})"
    items+=("$label")
    if is_default "$repo_id"; then
      defaults+=("$label")
    fi
  done

  local selected_labels
  selected_labels=$(printf '%s\n' "${items[@]}" \
    | gum choose --no-limit \
        --header "Welche Repos klonen?" \
        --selected="$(IFS=,; echo "${defaults[*]}")" \
    || true)

  while IFS= read -r label; do
    [[ -z "$label" ]] && continue
    local id
    id=$(echo "$label" | awk '{print $1}')
    _sel+=("$id")
  done <<< "$selected_labels"
}

# --- Bash-Fallback-Menue ---

show_menu_bash() {
  local -n _sel=$1
  local -n _shopify=$2
  local -n _mw=$3

  # Alle Repos in einer Liste
  local all_repos=()
  local selected_state=()

  for repo_id in "${_shopify[@]}"; do
    all_repos+=("$repo_id")
    if is_default "$repo_id"; then
      selected_state+=(1)
    else
      selected_state+=(0)
    fi
  done

  local mw_start=${#all_repos[@]}

  for repo_id in "${_mw[@]}"; do
    all_repos+=("$repo_id")
    if is_default "$repo_id"; then
      selected_state+=(1)
    else
      selected_state+=(0)
    fi
  done

  while true; do
    echo -e "  ${BOLD}Welche Repos klonen?${RESET}"
    echo -e "  ${DIM}(Nummer eingeben zum Umschalten, Enter zum Bestaetigen, a = alle)${RESET}"
    echo ""

    local i=0
    # Shopify-Gruppe
    if [[ ${#_shopify[@]} -gt 0 ]]; then
      echo -e "  ${CYAN}SHOPIFY${RESET}"
    fi
    for repo_id in "${_shopify[@]}"; do
      local name tech marker
      name="$(yaml_get "$repo_id" "name")"
      tech="$(yaml_get "$repo_id" "tech")"
      if [[ ${selected_state[$i]} -eq 1 ]]; then
        marker="${GREEN}[x]${RESET}"
      else
        marker="${DIM}[ ]${RESET}"
      fi
      if dir_exists "$repo_id"; then
        echo -e "  ${DIM}  — ${repo_id} (bereits geklont)${RESET}"
      else
        printf "  %b %d) %-18s %s (%s)\n" "$marker" $((i + 1)) "$repo_id" "$name" "$tech"
      fi
      i=$((i + 1))
    done

    # Middleware-Gruppe
    if [[ ${#_mw[@]} -gt 0 ]]; then
      echo ""
      echo -e "  ${CYAN}MIDDLEWARE${RESET}"
      echo -e "  ${DIM}  (Zugang zu gitlab.mdm.de erforderlich)${RESET}"
    fi
    for repo_id in "${_mw[@]}"; do
      local name tech marker
      name="$(yaml_get "$repo_id" "name")"
      tech="$(yaml_get "$repo_id" "tech")"
      if [[ ${selected_state[$i]} -eq 1 ]]; then
        marker="${GREEN}[x]${RESET}"
      else
        marker="${DIM}[ ]${RESET}"
      fi
      if dir_exists "$repo_id"; then
        echo -e "  ${DIM}  — ${repo_id} (bereits geklont)${RESET}"
      else
        printf "  %b %d) %-18s %s (%s)\n" "$marker" $((i + 1)) "$repo_id" "$name" "$tech"
      fi
      i=$((i + 1))
    done

    echo ""
    read -rp "  > " input

    case "$input" in
      "")
        # Enter = bestaetigen
        break
        ;;
      a|A)
        for j in "${!selected_state[@]}"; do
          selected_state[$j]=1
        done
        ;;
      n|N)
        for j in "${!selected_state[@]}"; do
          selected_state[$j]=0
        done
        ;;
      q|Q)
        echo "  Abgebrochen."
        exit 0
        ;;
      *)
        if [[ "$input" =~ ^[0-9]+$ ]] && [[ $input -ge 1 ]] && [[ $input -le ${#all_repos[@]} ]]; then
          local idx=$((input - 1))
          if [[ ${selected_state[$idx]} -eq 1 ]]; then
            selected_state[$idx]=0
          else
            selected_state[$idx]=1
          fi
        else
          echo -e "  ${YELLOW}Ungueltige Eingabe. Nummer, a(lle), n(ichts), q(uit) oder Enter.${RESET}"
        fi
        ;;
    esac

    # Terminal aufraeumen
    echo ""
  done

  # Ausgewaehlte sammeln
  for j in "${!all_repos[@]}"; do
    if [[ ${selected_state[$j]} -eq 1 ]]; then
      _sel+=("${all_repos[$j]}")
    fi
  done
}

# --- Repos klonen ---

clone_repos() {
  local repos=("$@")

  for repo_id in "${repos[@]}"; do
    local path remote branch
    path="$(yaml_get "$repo_id" "path")"
    remote="$(yaml_get "$repo_id" "remote")"
    branch="$(yaml_get "$repo_id" "branch")"
    local full_path="${SCRIPT_DIR}/${path}"

    if [[ -d "$full_path/.git" ]]; then
      echo -e "  ${DIM}${repo_id}: bereits geklont, uebersprungen${RESET}"
      continue
    fi

    echo -e "  ${CYAN}${repo_id}${RESET}: klone ${remote} ..."
    # Pfade koennen verschachtelt sein (themes/<marke>/) — Elternverzeichnis anlegen.
    mkdir -p "$(dirname "${full_path%/}")"
    if git clone --branch "${branch:-main}" "$remote" "$full_path" 2>&1 | sed 's/^/    /'; then
      echo -e "  ${GREEN}${repo_id}: erfolgreich geklont${RESET}"
    else
      echo -e "  ${YELLOW}${repo_id}: FEHLER beim Klonen${RESET}" >&2
    fi

    # .env.template kopieren falls vorhanden
    if [[ -f "${full_path}/.env.template" ]] && [[ ! -f "${full_path}/.env" ]]; then
      cp "${full_path}/.env.template" "${full_path}/.env"
      echo -e "  ${DIM}  → .env.template nach .env kopiert${RESET}"
    fi
  done
}

# --- .workspace.local.yaml schreiben ---

write_local_yaml() {
  local repos=("$@")
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Bestehende Eintraege einlesen (falls vorhanden)
  local existing_ids=()
  if [[ -f "$LOCAL_YAML" ]]; then
    while IFS= read -r line; do
      existing_ids+=("$line")
    done < <(grep -E "^  [a-z][a-z0-9-]*:$" "$LOCAL_YAML" | sed 's/://; s/^ *//')
  fi

  # Alle bekannten installierten Repos sammeln (bestehende + neue)
  local all_installed=()
  for id in "${existing_ids[@]}"; do
    all_installed+=("$id")
  done
  for id in "${repos[@]}"; do
    # Nur hinzufuegen wenn nicht schon vorhanden
    local found=false
    for existing in "${existing_ids[@]}"; do
      [[ "$existing" == "$id" ]] && found=true && break
    done
    [[ "$found" == false ]] && all_installed+=("$id")
  done

  # Datei schreiben
  {
    echo "# .workspace.local.yaml — lokaler Zustand (gitignored)"
    echo "# Generiert von setup.sh. Nicht manuell bearbeiten."
    echo "#"
    echo "# Guard: Repos die hier NICHT stehen, wurden bewusst nicht geklont."
    echo "# Die Harness darf sie NIEMALS aus CLAUDE.md oder Konfiguration entfernen."
    echo ""
    echo "installed:"
    for id in "${all_installed[@]}"; do
      local cloned_at="$now"
      # Bestehenden cloned_at-Timestamp beibehalten
      if [[ -f "$LOCAL_YAML" ]]; then
        local existing_ts
        existing_ts=$(sed -n "/^  ${id}:$/,/^  [a-z]/p" "$LOCAL_YAML" \
          | grep "cloned_at:" | sed 's/^[^:]*: *//' | tr -d '"' || true)
        [[ -n "$existing_ts" ]] && cloned_at="$existing_ts"
      fi
      local branch
      branch="$(yaml_get "$id" "branch")"
      echo "  ${id}:"
      echo "    cloned_at: \"${cloned_at}\""
      echo "    last_sync: \"${now}\""
      echo "    branch: \"${branch:-main}\""
    done
  } > "$LOCAL_YAML"
}

# --- Zusammenfassung ---

show_summary() {
  local repos=("$@")
  echo ""
  echo -e "${BOLD}  Zusammenfassung${RESET}"
  echo -e "${DIM}  ────────────────${RESET}"
  echo ""
  echo "  Installierte Repos:"
  while IFS= read -r repo_id; do
    if is_installed "$repo_id"; then
      local name
      name="$(yaml_get "$repo_id" "name")"
      if dir_exists "$repo_id"; then
        echo -e "    ${GREEN}●${RESET} ${repo_id} — ${name}"
      else
        echo -e "    ${YELLOW}●${RESET} ${repo_id} — ${name} (Verzeichnis fehlt!)"
      fi
    else
      local name
      name="$(yaml_get "$repo_id" "name")"
      echo -e "    ${DIM}○ ${repo_id} — ${name} (nicht installiert)${RESET}"
    fi
  done < <(get_repo_ids)

  echo ""
  echo -e "  ${DIM}CLAUDE.md wurde generiert.${RESET}"
  echo -e "  ${DIM}Weitere Repos: ./setup.sh --add${RESET}"
  echo ""
}

# --- Hauptprogramm ---

main() {
  if [[ ! -f "$WORKSPACE_YAML" ]]; then
    echo "FEHLER: workspace.yaml nicht gefunden in ${SCRIPT_DIR}" >&2
    exit 1
  fi

  # --sync: nur sync.sh ausfuehren
  if [[ "$MODE" == "--sync" ]]; then
    exec "${SCRIPT_DIR}/sync.sh"
  fi

  # --reset: lokalen State zuruecksetzen
  if [[ "$MODE" == "--reset" ]]; then
    rm -f "$LOCAL_YAML"
    echo "  .workspace.local.yaml entfernt. Repos bleiben."
    echo "  Erneut ./setup.sh ausfuehren fuer frische Einrichtung."
    exit 0
  fi

  show_banner

  # Menue anzeigen
  local selected=()
  local only_missing=false
  [[ "$MODE" == "--add" ]] && only_missing=true

  if ! show_menu selected "$only_missing"; then
    "${SCRIPT_DIR}/sync.sh" --quiet
    exit 0
  fi

  if [[ ${#selected[@]} -eq 0 ]]; then
    echo -e "  ${YELLOW}Keine Repos ausgewaehlt.${RESET}"
    echo ""
    # Trotzdem sync ausfuehren fuer Guard-Konsistenz
    "${SCRIPT_DIR}/sync.sh" --quiet
    exit 0
  fi

  echo ""
  echo -e "  ${BOLD}Klone ${#selected[@]} Repo(s)...${RESET}"
  echo ""

  # Klonen
  clone_repos "${selected[@]}"

  # Local-State schreiben
  write_local_yaml "${selected[@]}"

  # Sync ausfuehren
  echo ""
  "${SCRIPT_DIR}/sync.sh" --quiet

  # Zusammenfassung
  show_summary "${selected[@]}"
}

main "$@"
