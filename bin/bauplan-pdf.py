#!/usr/bin/env python3
"""PDF-Export eines Blattsatzes — fuer Weitergabe an Externe ohne Claude-Zugang.

  bin/bauplan-pdf.py connector              ganzer Satz als ein PDF
  bin/bauplan-pdf.py connector --einzeln    ein PDF je Etappe
  bin/bauplan-pdf.py connector --nr 6       nur eine Etappe

Gerendert wird mit Google Chrome im Headless-Modus, weil die Seiten Inline-SVG
und Webfonts verwenden — ein reiner HTML-nach-PDF-Konverter gibt das nicht
verlaesslich wieder.

Beim Zusammenfuehren mehrerer Blaetter zu einem Dokument werden SVG-IDs je
Etappe praefixiert. IDs gelten dokumentweit: zwei Etappen mit einem Marker
namens `ah1` wuerden sich sonst gegenseitig die Pfeilspitzen ausknipsen.
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bauplan_lib as lib  # noqa: E402

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Zeit fuer Webfonts vom CDN. Offline rendert es mit Systemschriften weiter.
WAIT_MS = 8000

# Druckregeln. Bewusst hier und nicht nur im Design-Kopf, damit auch aeltere
# Seiten sauber drucken, die noch ohne Druckblock veroeffentlicht wurden.
PRINT_CSS = """
<style>
  @page { size: A4; margin: 12mm 10mm; }
  html { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  body { background-image: none; font-size: 11.5px; }
  .sheet { max-width: none; padding: 0 0 8mm; }
  .sheet + .sheet { break-before: page; }
  .plate { break-inside: avoid-page; margin-top: 26px; }
  figure { break-inside: avoid-page; }
  figure svg { min-width: 0 !important; }
  .check { break-inside: avoid-page; }
  .titleblock { break-after: avoid-page; }
  footer { break-inside: avoid-page; }
  h1 { font-size: 30px !important; }
  h2 { font-size: 19px !important; }
  a { text-decoration: none; }
</style>
"""


def namespace_svg_ids(fragment, prefix):
    """SVG-IDs und ihre url(#...)-Verweise praefixieren."""
    ids = set(re.findall(r'\sid="([^"]+)"', fragment))
    for ident in sorted(ids, key=len, reverse=True):
        new = "%s-%s" % (prefix, ident)
        fragment = fragment.replace('id="%s"' % ident, 'id="%s"' % new)
        fragment = fragment.replace("url(#%s)" % ident, "url(#%s)" % new)
        fragment = fragment.replace('href="#%s"' % ident, 'href="#%s"' % new)
    return fragment


def strip_head_bits(fragment):
    """<title>, <link> und <style> entfernen — im Sammeldokument nur einmal."""
    fragment = re.sub(r"<title>.*?</title>\s*", "", fragment, flags=re.S)
    fragment = re.sub(r"<link\b[^>]*>\s*", "", fragment)
    fragment = re.sub(r"<style>.*?</style>\s*", "", fragment, flags=re.S)
    return fragment.strip()


def head_bits(fragment):
    """Die gemeinsamen Kopfteile der ersten Etappe uebernehmen."""
    links = "\n".join(re.findall(r"<link\b[^>]*>", fragment))
    styles = "\n".join(re.findall(r"<style>.*?</style>", fragment, flags=re.S))
    return links + "\n" + styles


def build_document(sheets, title):
    """Ein vollstaendiges, druckfertiges Dokument aus n Fragmenten.

    data-theme="light" erzwingt die helle Palette: der Design-Vertrag laesst
    Dunkel nur ueber prefers-color-scheme oder data-theme="dark" greifen.
    """
    if not sheets:
        raise ValueError("keine Blaetter")
    parts = [
        '<!doctype html><html lang="de" data-theme="light"><head>',
        '<meta charset="utf-8">',
        "<title>%s</title>" % title,
        head_bits(sheets[0][1]),
        PRINT_CSS,
        "</head><body>",
    ]
    for nr, fragment in sheets:
        body = namespace_svg_ids(strip_head_bits(fragment), "e%02d" % nr)
        parts.append(body)
    parts.append("</body></html>")
    return "\n".join(parts)


def render(html, out_pdf):
    if not os.path.isfile(CHROME):
        print("Google Chrome nicht gefunden: %s" % CHROME, file=sys.stderr)
        return 1
    with tempfile.TemporaryDirectory() as tmp:
        src = os.path.join(tmp, "satz.html")
        with open(src, "w", encoding="utf-8") as fh:
            fh.write(html)
        cmd = [
            CHROME, "--headless", "--disable-gpu", "--no-sandbox",
            "--no-first-run", "--no-default-browser-check",
            "--disable-extensions", "--disable-sync",
            "--no-pdf-header-footer",
            "--run-all-compositor-stages-before-draw",
            "--virtual-time-budget=%d" % (WAIT_MS,),
            "--user-data-dir=%s" % os.path.join(tmp, "profile"),
            "--print-to-pdf=%s" % out_pdf,
            "file://%s" % src,
        ]
        # Chrome schreibt das PDF und bleibt danach gelegentlich haengen, statt
        # sich zu beenden. Entscheidend ist die Datei, nicht der Exit — deshalb
        # harter Timeout und danach die Datei pruefen.
        try:
            res = subprocess.run(cmd, capture_output=True, text=True,
                                 timeout=WAIT_MS / 1000.0 + 20)
            stderr = res.stderr
        except subprocess.TimeoutExpired as exc:
            stderr = (exc.stderr or b"").decode("utf-8", "replace") if isinstance(exc.stderr, bytes) else (exc.stderr or "")
        if not os.path.isfile(out_pdf) or os.path.getsize(out_pdf) < 1024:
            print(stderr.strip()[-800:], file=sys.stderr)
            return 1
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("repo")
    ap.add_argument("--nr", type=int, help="nur diese Etappe")
    ap.add_argument("--einzeln", action="store_true", help="ein PDF je Etappe")
    ap.add_argument("--out", default=None, help="Zielverzeichnis (Standard: docs/bauplan/pdf)")
    ap.add_argument("--project", default=None)
    args = ap.parse_args()

    project = lib.project_root(args.project)
    manifest = lib.load_manifest(args.repo, project)
    if manifest is None:
        print("Kein Manifest fuer %s" % args.repo, file=sys.stderr)
        return 2

    etappen = manifest.get("etappen", [])
    if args.nr:
        etappen = [e for e in etappen if e.get("nr") == args.nr]
        if not etappen:
            print("Etappe %s gibt es nicht" % args.nr, file=sys.stderr)
            return 2

    sheets, fehlend = [], []
    for etappe in etappen:
        nr = etappe.get("nr")
        path = lib.sheet_path(args.repo, nr, project)
        if not os.path.isfile(path):
            fehlend.append(nr)
            continue
        with open(path, encoding="utf-8") as fh:
            sheets.append((nr, fh.read(), etappe.get("title", "")))

    if fehlend:
        # Nie stillschweigend weniger exportieren als das Manifest kennt.
        print("Hinweis: keine Quelle fuer Etappe %s — nicht im PDF."
              % ", ".join(str(n) for n in fehlend), file=sys.stderr)
    if not sheets:
        print("Keine HTML-Quellen gefunden. Erst /repo-bauplan %s laufen lassen."
              % args.repo, file=sys.stderr)
        return 2

    out_dir = args.out or os.path.join(lib.docs_dir(project), "pdf")
    os.makedirs(out_dir, exist_ok=True)
    stand = manifest.get("generated", "")

    if args.einzeln or args.nr:
        rc = 0
        for nr, fragment, title in sheets:
            out = os.path.join(out_dir, "%s-etappe-%02d.pdf" % (args.repo, nr))
            doc = build_document([(nr, fragment)], "%s — Etappe %d: %s" % (args.repo, nr, title))
            if render(doc, out) == 0:
                print("%s  (%.1f KB)" % (out, os.path.getsize(out) / 1024))
            else:
                rc = 1
        return rc

    out = os.path.join(out_dir, "%s-blattsatz.pdf" % args.repo)
    doc = build_document([(nr, f) for nr, f, _ in sheets],
                         "%s — Architektur-Blattsatz%s" % (args.repo, " (%s)" % stand if stand else ""))
    if render(doc, out) != 0:
        return 1
    print("%s  (%.1f KB, %d Blaetter)" % (out, os.path.getsize(out) / 1024, len(sheets)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
