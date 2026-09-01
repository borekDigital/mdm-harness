#!/usr/bin/env bash
# Hook: Stop-Event — prueft ob Harness-Dateien mit README.md UND
# harness-app/data.json uebereinstimmen.
# Gibt eine Warnung aus falls neue Agenten, Skills, Hooks oder Rules
# existieren die nicht dokumentiert sind.

set -euo pipefail

HARNESS_DIR="${CLAUDE_PROJECT_DIR}/.claude"
README="${HARNESS_DIR}/README.md"
DATA_JSON="${CLAUDE_PROJECT_DIR}/harness-app/data.json"

changes_found=false
messages=()

# --- Hilfsfunktion: Name in Datei pruefen ---
check_in_file() {
  local name="$1" file="$2" label="$3"
  if [[ -f "$file" ]] && ! grep -q "$name" "$file" 2>/dev/null; then
    changes_found=true
    messages+=("$label '$name' fehlt in $(basename "$file")")
  fi
}

# --- Agenten pruefen ---
for agent_file in "$HARNESS_DIR"/agents/*.md; do
  [[ -f "$agent_file" ]] || continue
  agent_name=$(basename "$agent_file" .md)
  check_in_file "$agent_name" "$README" "Agent"
  check_in_file "$agent_name" "$DATA_JSON" "Agent"
done

# --- Skills pruefen ---
for skill_dir in "$HARNESS_DIR"/skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name=$(basename "$skill_dir")
  check_in_file "$skill_name" "$README" "Skill"
  check_in_file "$skill_name" "$DATA_JSON" "Skill"
done

# --- Hooks pruefen ---
for hook_file in "$HARNESS_DIR"/hooks/*.sh; do
  [[ -f "$hook_file" ]] || continue
  hook_name=$(basename "$hook_file" .sh)
  check_in_file "$hook_name" "$README" "Hook"
  check_in_file "$hook_name" "$DATA_JSON" "Hook"
done

# --- Rules pruefen ---
for rule_file in "$HARNESS_DIR"/rules/*.md; do
  [[ -f "$rule_file" ]] || continue
  rule_name=$(basename "$rule_file" .md)
  check_in_file "$rule_name" "$README" "Rule"
  check_in_file "$rule_name" "$DATA_JSON" "Rule"
done

if [[ "$changes_found" == true ]]; then
  echo "⚠️  Harness-Doku nicht synchron:"
  for msg in "${messages[@]}"; do
    echo "   - $msg"
  done
  echo "   → .claude/README.md und/oder harness-app/data.json aktualisieren"
fi

exit 0
