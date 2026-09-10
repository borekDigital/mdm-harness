#!/usr/bin/env python3
"""Holt eine veroeffentlichte Bauplan-Seite als HTML-Quelle ins Repo zurueck.

Eingabe ist die Datei, die WebFetch beim Abruf eines Artifacts ablegt: ein
vollstaendiges Dokument, dem die Artifact-Laufzeit einen eigenen <head> mit
Frame-Runtime voranstellt. Gebraucht wird daraus das Fragment, das beim
Veroeffentlichen uebergeben wurde — also alles ab <title>, ohne </body></html>.

Das Fragment ist absichtlich kein vollstaendiges Dokument: genau in dieser Form
nimmt es das Artifact-Tool wieder an, ohne Umformung. Chrome und der
PDF-Export ergaenzen den Rahmen beim Rendern.
"""

import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bauplan_lib as lib  # noqa: E402


def extract_fragment(raw):
    """Fragment zwischen <title> und </body> herausschneiden."""
    start = raw.find("<title>")
    if start < 0:
        raise ValueError("kein <title> gefunden — ist das eine Bauplan-Seite?")
    end = raw.rfind("</body>")
    if end < 0:
        end = len(raw)
    fragment = raw[start:end].strip()
    if "<div class=\"sheet\">" not in fragment:
        raise ValueError("kein .sheet-Container — Design-Vertrag bauplan-v1 nicht erkannt")
    return fragment + "\n"


def check_svg_balance(fragment):
    """Unbalancierte <text>-Tags sind der Fehler, der eine Figur unsichtbar macht."""
    opened = len(re.findall(r"<text[\s>]", fragment))
    closed = len(re.findall(r"</text>", fragment))
    return opened, closed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--nr", required=True, type=int)
    ap.add_argument("--from-file", required=True, help="von WebFetch abgelegtes Dokument")
    ap.add_argument("--project", default=None)
    args = ap.parse_args()

    project = lib.project_root(args.project)
    with open(args.from_file, encoding="utf-8", errors="replace") as fh:
        fragment = extract_fragment(fh.read())

    target = lib.sheet_path(args.repo, args.nr, project)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(target, "w", encoding="utf-8") as fh:
        fh.write(fragment)

    title = re.search(r"<title>(.*?)</title>", fragment)
    opened, closed = check_svg_balance(fragment)
    print("%s Etappe %02d -> %s" % (args.repo, args.nr, os.path.relpath(target, project)))
    print("  Titel:   %s" % (title.group(1) if title else "(fehlt)"))
    print("  Groesse: %d Zeichen" % len(fragment))
    print("  <text>:  %d offen / %d geschlossen %s"
          % (opened, closed, "OK" if opened == closed else "UNBALANCIERT"))
    return 0 if opened == closed else 1


if __name__ == "__main__":
    sys.exit(main())
