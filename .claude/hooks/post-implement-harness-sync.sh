#!/usr/bin/env bash
# Hook: Stop-Event — prueft ob Harness-Dateien in .claude/README.md
# dokumentiert sind.
# Gibt eine Warnung aus falls neue Agenten, Skills, Hooks oder Rules
# existieren die nicht dokumentiert sind.

set -euo pipefail

HARNESS_DIR="${CLAUDE_PROJECT_DIR}/.claude"
README="${HARNESS_DIR}/README.md"

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
  check_in_file "$(basename "$agent_file" .md)" "$README" "Agent"
done

# --- Skills pruefen ---
for skill_dir in "$HARNESS_DIR"/skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  check_in_file "$(basename "$skill_dir")" "$README" "Skill"
done

# --- Hooks pruefen ---
for hook_file in "$HARNESS_DIR"/hooks/*.sh; do
  [[ -f "$hook_file" ]] || continue
  check_in_file "$(basename "$hook_file" .sh)" "$README" "Hook"
done

# --- Rules pruefen ---
for rule_file in "$HARNESS_DIR"/rules/*.md; do
  [[ -f "$rule_file" ]] || continue
  check_in_file "$(basename "$rule_file" .md)" "$README" "Rule"
done

if [[ "$changes_found" == true ]]; then
  echo "⚠️  Harness-Doku nicht synchron:"
  for msg in "${messages[@]}"; do
    echo "   - $msg"
  done
  echo "   → .claude/README.md aktualisieren"
fi

exit 0
