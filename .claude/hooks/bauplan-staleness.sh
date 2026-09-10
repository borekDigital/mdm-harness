#!/bin/bash
# PostToolUse (Edit|Write) — NICHT blockierend, exit 0 in jedem Fall.
#
# Ordnet eine geaenderte Datei den Etappen zu, die sie belegen, und schreibt
# einen Eintrag in das Staleness-Ledger. Regeneriert NICHTS — Hooks koennen
# keine Artifacts bauen. Der Ledger ist die Eingabe fuer
# `/repo-bauplan <repo> --refresh`.
#
# Zuordnung in bin/bauplan_lib.py — dieselbe Regel, die die CI anwendet.
PAYLOAD=$(cat)
PROJECT="${CLAUDE_PROJECT_DIR:-$HOME/MDM}"

FILE=$(printf '%s' "$PAYLOAD" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

[ -z "$FILE" ] && exit 0

python3 - "$PROJECT" "$FILE" <<'PY' 2>/dev/null
import datetime, json, os, sys

project, changed = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.join(project, "bin"))
try:
    import bauplan_lib as lib
except ImportError:
    sys.exit(0)

if lib.is_ignored(changed):
    sys.exit(0)

stamp = datetime.datetime.now().isoformat(timespec="seconds")
for repo, _path, manifest in lib.iter_manifests(project):
    rel = lib.split_repo_path(changed, repo)
    if rel is None:
        continue
    hits = lib.affected_etappen(manifest, [rel])
    if not hits:
        continue
    ledger = os.path.join(lib.manifest_dir(project), repo + ".staleness.jsonl")
    with open(ledger, "a", encoding="utf-8") as fh:
        for etappe, _triggers in hits:
            fh.write(json.dumps({
                "at": stamp,
                "file": rel,
                "etappe": etappe.get("nr"),
                "title": etappe.get("title"),
                "url": etappe.get("url"),
            }, ensure_ascii=False) + "\n")
PY

exit 0
