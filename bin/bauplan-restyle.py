#!/usr/bin/env python3
"""Zieht bestehende Blattseiten auf den aktuellen Design-Kopf nach.

Der Kopf ist in jede Seite hineinkopiert — anders geht es nicht, weil eine
veroeffentlichte Seite in sich geschlossen sein muss. Aendert sich der
Design-Vertrag, muessen die Seiten also nachgezogen werden.

  bin/bauplan-restyle.py                 alle Repos
  bin/bauplan-restyle.py --repo emailservice

Der Rumpf bleibt unberuehrt: getrennt wird an `<div class="sheet">`, alles
danach wird Zeichen fuer Zeichen uebernommen. Danach ist ein erneutes
Veroeffentlichen faellig, sonst weicht die Seite auf claude.ai von der Quelle ab.
"""

import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bauplan_lib as lib  # noqa: E402

HEAD_ASSET = ".claude/skills/repo-bauplan/assets/bauplan-head.html"
TRENNER = '<div class="sheet">'


def restyle(path, head):
    with open(path, encoding="utf-8") as fh:
        alt = fh.read()
    if TRENNER not in alt:
        return None, "kein .sheet-Container"
    titel = re.search(r"<title>.*?</title>", alt, re.S)
    if not titel:
        return None, "kein <title>"
    rumpf = alt[alt.index(TRENNER):]
    neu = titel.group(0) + "\n" + head.rstrip("\n") + "\n" + rumpf
    if neu == alt:
        return False, None
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(neu)
    return True, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=None)
    ap.add_argument("--project", default=None)
    args = ap.parse_args()
    project = lib.project_root(args.project)

    with open(os.path.join(project, HEAD_ASSET), encoding="utf-8") as fh:
        head = fh.read()

    repos = [args.repo] if args.repo else [r for r, _p, _m in lib.iter_manifests(project)]
    geaendert = 0
    for repo in repos:
        manifest = lib.load_manifest(repo, project)
        if manifest is None:
            continue
        for etappe in manifest.get("etappen", []):
            path = lib.sheet_path(repo, etappe.get("nr"), project)
            if not os.path.isfile(path):
                print("  %s Etappe %s: keine Quelle" % (repo, etappe.get("nr")))
                continue
            ok, grund = restyle(path, head)
            rel = os.path.relpath(path, project)
            if ok is None:
                print("  UEBERSPRUNGEN %s — %s" % (rel, grund))
            elif ok:
                print("  nachgezogen   %s (%.0f KB)" % (rel, os.path.getsize(path) / 1024))
                geaendert += 1
            else:
                print("  unveraendert  %s" % rel)
    print("%d Seiten nachgezogen. Danach neu veroeffentlichen." % geaendert)
    return 0


if __name__ == "__main__":
    sys.exit(main())
