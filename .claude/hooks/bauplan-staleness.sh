#!/bin/bash
# PostToolUse (Edit|Write) — NICHT blockierend, exit 0 in jedem Fall.
#
# Ordnet eine geaenderte Datei den Blattsaetzen zu, die sie belegen, und schreibt
# einen Eintrag in das Staleness-Ledger. Regeneriert NICHTS — Hooks koennen keine
# Artifacts bauen. Der Ledger ist die Eingabe fuer `/repo-bauplan <repo> --refresh`.
#
# Quelle der Zuordnung: .claude/bauplan/<repo>.manifest.json, Feld "sources".

PAYLOAD=$(cat)
PROJECT="${CLAUDE_PROJECT_DIR:-$HOME/MDM}"

FILE=$(printf '%s' "$PAYLOAD" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

[ -z "$FILE" ] && exit 0

# Harness, Tickets und Scratch nie beruecksichtigen
case "$FILE" in
  */.claude/*|*/Tickets/*|/tmp/*|/private/tmp/*) exit 0 ;;
esac

python3 - "$PROJECT" "$FILE" <<'PY' 2>/dev/null
import json, os, sys, fnmatch, datetime

project, changed = sys.argv[1], sys.argv[2]
base = os.path.join(project, ".claude", "bauplan")
if not os.path.isdir(base):
    sys.exit(0)

for entry in sorted(os.listdir(base)):
    if not entry.endswith(".manifest.json"):
        continue
    repo = entry[: -len(".manifest.json")]
    manifest_path = os.path.join(base, entry)

    # Liegt die Datei in diesem Repo?
    marker = "/%s/" % repo
    if marker not in changed:
        continue
    rel = changed.split(marker, 1)[1]

    try:
        with open(manifest_path, encoding="utf-8") as fh:
            manifest = json.load(fh)
    except Exception:
        continue

    hits = []
    for etappe in manifest.get("etappen", []):
        for pattern in etappe.get("sources", []):
            if fnmatch.fnmatch(rel, pattern) or rel == pattern \
               or (pattern.endswith("/**") and rel.startswith(pattern[:-3] + "/")):
                hits.append(etappe)
                break

    if not hits:
        continue

    ledger = os.path.join(base, repo + ".staleness.jsonl")
    stamp = datetime.datetime.now().isoformat(timespec="seconds")
    with open(ledger, "a", encoding="utf-8") as fh:
        for etappe in hits:
            fh.write(json.dumps({
                "at": stamp,
                "file": rel,
                "etappe": etappe.get("nr"),
                "title": etappe.get("title"),
                "url": etappe.get("url"),
            }, ensure_ascii=False) + "\n")
PY

exit 0
