#!/usr/bin/env python3
"""Verlinkt die Fusszeilen-Navigation der Blattseiten.

Jedes Blatt nennt am Fuss bereits, was als naechstes kommt — bisher als
Fliesstext. Diese Zeile wird hier zum Sprung: der Titel verlinkt die lokale
Datei, daneben steht das veroeffentlichte Artefakt. Dasselbe Paar wie in der
Uebersicht (`HTML · Artefakt`), damit lokal und veroeffentlicht derselbe Weg
gilt.

Quelle der Reihenfolge ist das Manifest, nicht der Fliesstext: `etappen` ist
geordnet, jede Etappe kennt `nr`, `title` und `url`. Der von Hand geschriebene
Nachsatz („— Hochfahren und Prozesse") bleibt erhalten; nur die Verlinkung
kommt aus dem Manifest.

  bin/bauplan-nav.py --dry-run     zeigt, was sich aendern wuerde
  bin/bauplan-nav.py               schreibt
  bin/bauplan-nav.py --repo harness

Idempotent: ein zweiter Lauf aendert nichts. Bestehende Links werden vor dem
Neuschreiben entfernt, damit sich nichts verschachtelt.
"""

import argparse
import html
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bauplan_lib as lib  # noqa: E402

FOOTER_RE = re.compile(r"<footer>(.*?)</footer>", re.S)
NEXT_RE = re.compile(r"<span>\s*Als n(?:ä|&auml;)chstes:\s*(.*?)</span>", re.S)
ENDE_RE = re.compile(r"<span>\s*Ende des Blattsatzes\s*(.*?)</span>", re.S)
TAG_RE = re.compile(r"<[^>]+>")
# „Etappe 4 von 4" — die Gesamtzahl kommt aus dem Manifest, nicht aus dem Text.
# Kommt eine Etappe dazu, ist sie sonst auf jedem aelteren Blatt falsch.
COUNT_RE = re.compile(r"(Etappe\s+\d+\s+von\s+)(\d+)")


def drop_span(footer, muster):
    """Entfernt eine Fusszeilen-Zeile samt fuehrendem Zeilenumbruch."""
    treffer = muster.search(footer)
    if not treffer:
        return footer
    start = treffer.start()
    # den Einzug der Zeile mitnehmen, damit keine Leerzeile bleibt
    while start > 0 and footer[start - 1] in " \t":
        start -= 1
    if start > 0 and footer[start - 1] == "\n":
        start -= 1
    return footer[:start] + footer[treffer.end():]


def plain(fragment):
    """Fliesstext ohne Auszeichnung — entfernt eine fruehere Verlinkung."""
    return re.sub(r"\s+", " ", TAG_RE.sub("", fragment)).strip()


def strip_trailing_links(text):
    """Entfernt ein angehaengtes ` · Artefakt` aus einem frueheren Lauf."""
    return re.sub(r"\s*·\s*Artefakt\s*$", "", text).strip()


def next_span(etappe_next, prosa):
    """Fusszeile fuer ein Blatt, dem eine weitere Etappe folgt."""
    ziel = "etappe-%02d.html" % int(etappe_next["nr"])
    text = html.escape(prosa, quote=False)
    teile = ['<span>Als nächstes: <a href="%s">%s</a>' % (ziel, text)]
    if etappe_next.get("url"):
        teile.append(' · <a href="%s">Artefakt</a>' % html.escape(etappe_next["url"]))
    teile.append("</span>")
    return "".join(teile)


def ende_span():
    """Fusszeile fuer das letzte Blatt eines Satzes — zurueck zur Uebersicht.

    Der Satz ist vollstaendig bestimmt; ein Rest aus der alten Zeile wird
    NICHT uebernommen. Sonst haengt jeder Lauf den eigenen Linktext erneut an
    ("… Übersicht — Übersicht — Übersicht") und das Blatt waechst bei jedem
    Aufruf."""
    return ('<span>Ende des Blattsatzes — '
            '<a href="../index.html">Übersicht</a></span>')


def rewrite(path, etappe_next, gesamt=None):
    with open(path, encoding="utf-8") as fh:
        alt = fh.read()

    m = FOOTER_RE.search(alt)
    if not m:
        return None, "kein <footer>"
    original = m.group(1)
    footer = original

    if gesamt:
        footer = COUNT_RE.sub(lambda t: t.group(1) + str(gesamt), footer)

    if etappe_next is not None:
        # Ein Blatt mit Nachfolger ist nicht das Ende — eine alte Schlusszeile
        # muss weg, sonst steht beides nebeneinander und widerspricht sich.
        footer = drop_span(footer, ENDE_RE)
        treffer = NEXT_RE.search(footer)
        if treffer:
            prosa = strip_trailing_links(plain(treffer.group(1)))
            if not prosa:
                prosa = etappe_next.get("title", "weiter")
            neu_footer = footer[:treffer.start()] + next_span(etappe_next, prosa) \
                + footer[treffer.end():]
        else:
            # Blatt ohne Nachsatz: Zeile aus dem Manifest ergaenzen, damit der
            # Satz durchgehend blaetterbar ist.
            neu_footer = footer.rstrip() + "\n    " \
                + next_span(etappe_next, etappe_next.get("title", "weiter")) + "\n  "
    else:
        # Umgekehrt: das letzte Blatt darf keine „Als naechstes"-Zeile tragen.
        footer = drop_span(footer, NEXT_RE)
        treffer = ENDE_RE.search(footer)
        if treffer:
            neu_footer = footer[:treffer.start()] + ende_span() \
                + footer[treffer.end():]
        else:
            neu_footer = footer.rstrip() + "\n    " + ende_span() + "\n  "

    # Gegen das Original vergleichen, nicht gegen die bereits bearbeitete
    # Fassung — sonst meldet der Lauf "unveraendert", obwohl er die Zaehlung
    # oder eine widersprechende Zeile korrigiert hat.
    if neu_footer == original:
        return False, None
    neu = alt[:m.start(1)] + neu_footer + alt[m.end(1):]
    return neu, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=None)
    ap.add_argument("--project", default=None)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    project = lib.project_root(args.project)
    lib.assert_project(project)

    repos = [args.repo] if args.repo else [r for r, _p, _m in lib.iter_manifests(project)]
    geaendert = fehlend = 0

    for repo in repos:
        manifest = lib.load_manifest(repo, project)
        if manifest is None:
            print("  %s: kein Manifest" % repo)
            continue
        etappen = manifest.get("etappen", [])
        for i, etappe in enumerate(etappen):
            path = lib.sheet_path(repo, etappe.get("nr"), project)
            rel = os.path.relpath(path, project)
            if not os.path.isfile(path):
                print("  FEHLT        %s" % rel)
                fehlend += 1
                continue
            nachfolger = etappen[i + 1] if i + 1 < len(etappen) else None
            neu, grund = rewrite(path, nachfolger, gesamt=len(etappen))
            if neu is None:
                print("  UEBERSPRUNGEN %s — %s" % (rel, grund))
            elif neu is False:
                print("  unveraendert  %s" % rel)
            else:
                ziel = ("Etappe %s" % nachfolger["nr"]) if nachfolger else "Übersicht"
                print("  %s %s -> %s" % (
                    "wuerde setzen" if args.dry_run else "verlinkt     ", rel, ziel))
                if not args.dry_run:
                    with open(path, "w", encoding="utf-8") as fh:
                        fh.write(neu)
                geaendert += 1

    print("%d Fusszeile(n) %s%s."
          % (geaendert,
             "zu setzen" if args.dry_run else "verlinkt",
             ", %d Quelle(n) fehlen" % fehlend if fehlend else ""))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except lib.ProjectError as exc:
        print("FEHLER: %s" % exc, file=sys.stderr)
        sys.exit(2)
