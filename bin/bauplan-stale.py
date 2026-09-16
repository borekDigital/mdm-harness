#!/usr/bin/env python3
"""Ermittelt, welche Etappen eine Menge geaenderter Dateien veraltet.

Zwei Betriebsarten:

  # Dateien aus git ableiten (CI, Push ohne Claude)
  bin/bauplan-stale.py --repo emailservice --since <sha>

  # Dateien explizit uebergeben (Hook, Test)
  git diff --name-only HEAD~1 | bin/bauplan-stale.py --repo emailservice --stdin

Ausgabe: JSON auf stdout. Exit 0, wenn nichts veraltet ist; Exit 3, wenn ja.
Der abweichende Code macht die Frage in einem CI-Schritt direkt verwendbar,
ohne die Ausgabe zu parsen.
"""

import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bauplan_lib as lib  # noqa: E402


def changed_from_git(repo_path, since):
    """Geaenderte Dateien zwischen `since` und HEAD, repo-relativ."""
    out = subprocess.run(
        ["git", "-C", repo_path, "diff", "--name-only", "%s..HEAD" % since],
        capture_output=True, text=True, check=True,
    )
    return [line for line in out.stdout.splitlines() if line.strip()]


def head_sha(repo_path):
    out = subprocess.run(
        ["git", "-C", repo_path, "rev-parse", "HEAD"],
        capture_output=True, text=True, check=True,
    )
    return out.stdout.strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--since", help="Basis-Commit; Standard: last_seen_sha aus dem Manifest")
    ap.add_argument("--stdin", action="store_true", help="Dateiliste von stdin lesen")
    ap.add_argument("--project", default=None)
    args = ap.parse_args()

    project = lib.project_root(args.project)
    lib.assert_project(project)
    manifest = lib.load_manifest(args.repo, project)
    if manifest is None:
        print(json.dumps({"repo": args.repo, "error": "kein Manifest"}), file=sys.stderr)
        return 2

    if args.stdin:
        changed = [line.strip() for line in sys.stdin if line.strip()]
        new_sha = None
    else:
        # Die Wurzel steht im Manifest. `root: "."` heisst: der Workspace selbst
        # ist der Gegenstand — so dokumentiert sich die Harness. Ohne diese
        # Aufloesung sucht der Lauf ~/MDM/harness/ und meldet "nicht geklont",
        # obwohl das Repo direkt vor ihm liegt.
        manifest_wurzel = lib.manifest_root(manifest, args.repo)
        repo_path = project if manifest_wurzel in (".", "") \
            else os.path.join(project, manifest_wurzel)
        if not os.path.isdir(os.path.join(repo_path, ".git")):
            print(json.dumps({"repo": args.repo, "error": "nicht geklont"}), file=sys.stderr)
            return 2
        since = args.since or manifest.get("last_seen_sha")
        if not since:
            # Erster Lauf: nichts zu vergleichen, nur den Stand festhalten.
            print(json.dumps({
                "repo": args.repo, "first_run": True,
                "head": head_sha(repo_path), "stale": [],
            }, ensure_ascii=False, indent=2))
            return 0
        changed = changed_from_git(repo_path, since)
        new_sha = head_sha(repo_path)

    root = lib.manifest_root(manifest, args.repo)
    relevant = [c for c in changed if not lib.is_ignored("/" + c, root)]
    hits = lib.affected_etappen(manifest, relevant)

    result = {
        "repo": args.repo,
        "changed": len(relevant),
        "head": new_sha,
        "stale": [
            {
                "nr": e.get("nr"),
                "title": e.get("title"),
                "url": e.get("url"),
                "sheet": os.path.relpath(lib.sheet_path(args.repo, e.get("nr"), project), project),
                "triggers": triggers,
            }
            for e, triggers in hits
        ],
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 3 if result["stale"] else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except lib.ProjectError as exc:
        print("FEHLER: %s" % exc, file=sys.stderr)
        sys.exit(2)
