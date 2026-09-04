#!/bin/bash
# Stop — async, nicht blockierend.
#
# Verdichtet das Staleness-Ledger zu einer lesbaren Datei je Repo und leert es.
# Ergebnis: .claude/bauplan/<repo>.STALE.md — die Arbeitsliste fuer
# `/repo-bauplan <repo> --refresh`.

PROJECT="${CLAUDE_PROJECT_DIR:-$HOME/MDM}"
BASE="$PROJECT/.claude/bauplan"
[ -d "$BASE" ] || exit 0

python3 - "$BASE" <<'PY' 2>/dev/null
import json, os, sys, datetime, collections

base = sys.argv[1]

for entry in sorted(os.listdir(base)):
    if not entry.endswith(".staleness.jsonl"):
        continue
    repo = entry[: -len(".staleness.jsonl")]
    ledger = os.path.join(base, entry)
    if os.path.getsize(ledger) == 0:
        continue

    rows = []
    with open(ledger, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except Exception:
                pass
    if not rows:
        continue

    by_etappe = collections.OrderedDict()
    for row in sorted(rows, key=lambda r: (r.get("etappe") or 0)):
        key = (row.get("etappe"), row.get("title"), row.get("url"))
        by_etappe.setdefault(key, set()).add(row.get("file"))

    stale_path = os.path.join(base, repo + ".STALE.md")
    previous = ""
    if os.path.isfile(stale_path):
        with open(stale_path, encoding="utf-8") as fh:
            previous = fh.read()

    lines = [
        "# Veraltete Blaetter — %s" % repo,
        "",
        "Zuletzt verdichtet: %s" % datetime.date.today().strftime("%d. %B %Y"),
        "",
        "Auffrischen mit `/repo-bauplan %s --refresh`." % repo,
        "",
    ]
    for (nr, title, url), files in by_etappe.items():
        lines.append("## Etappe %s — %s" % (nr, title))
        if url:
            lines.append("")
            lines.append(url)
        lines.append("")
        for f in sorted(files):
            lines.append("- `%s`" % f)
        lines.append("")

    merged = "\n".join(lines)
    if previous.strip() and previous.strip() != merged.strip():
        merged += "\n---\n\n<details><summary>Vorheriger Stand</summary>\n\n" \
                  + previous + "\n</details>\n"

    with open(stale_path, "w", encoding="utf-8") as fh:
        fh.write(merged)

    open(ledger, "w").close()
PY

exit 0
