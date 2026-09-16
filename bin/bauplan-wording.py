#!/usr/bin/env python3
"""Prueft Blattseiten gegen die Wortregeln aus design-system.md.

Zwei Ausgabeklassen, und die Trennung ist der Kern des Werkzeugs:

  VERSTOSS    mechanisch entscheidbar. Ueberschriftenlaenge, Wortliste,
              Leseransprache, verbotener Bildunterschriften-Anfang, Eyebrow
              gleich Titel. Exit 3.

  DURCHSICHT  nicht entscheidbar. Metaphern-Kandidaten, lange Saetze. Wird
              gemeldet, zaehlt aber nicht als Fehler. Exit bleibt 0.

Der Grund fuer die Trennung steht in .claude/specs/harness/bauplan-wording-rueckbau.md:
Ein erster Entwurf pruefte die Bildunterschriften gegen die im Vertrag genannten
*zulaessigen* Anfaenge und meldete 65 von 78 als falsch — die Liste ist aber eine
Beispielliste, keine Whitelist. Wer nicht entscheidbare Regeln als Verstoss meldet,
erzeugt Arbeit, die keine ist.

  bin/bauplan-wording.py                  alle Blattseiten
  bin/bauplan-wording.py --repo harness   ein Blattsatz
  bin/bauplan-wording.py --datei <pfad>   eine Seite
  bin/bauplan-wording.py --json           maschinenlesbar
  bin/bauplan-wording.py --quiet          nur die Summe

Exit 0 = keine Verstoesse, 3 = Verstoesse gefunden, 2 = Aufrufproblem.
"""

import argparse
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bauplan_lib as lib  # noqa: E402

MAX_WOERTER = 3
MAX_SATZ = 25

# --- Wortliste (design-system.md, Abschnitt Wortliste) ---
UNSCHARF = ["einfach", "schnell", "problemlos", "normalerweise", "in der Regel",
            "etc.", "usw.", "gegebenenfalls", "möglichst", "ein bisschen",
            "entsprechend", "wie gewohnt"]
WERTUNG = ["bemerkenswert", "erstaunlich", "überraschend", "absurd", "elegant",
           "durchaus", "eigentlich", "quasi", "relativ", "ziemlich", "leider"]

# --- Leseransprache ---
ANSPRACHE = [r"\bman\b", r"\bwer\b", r"\bdu\b", r"\bdein(e|em|en|er|es)?\b",
             r"\bdich\b", r"\bunser(e|em|en|er|es)?\b"]

# --- Metaphern ohne Fachbezug. NUR Durchsicht, nie Verstoss: ein Wort kann
#     im Fachzusammenhang richtig sein, und das entscheidet kein Muster. ---
METAPHER = [r"\bHerzschlag\b", r"\bUhrwerk\b", r"\bTaktgeber\b", r"\bFlie(ß|ss)band\b",
            r"\bGeschwister\b", r"\bFremde\b", r"\bNervensystem\b", r"\bRückgrat\b",
            r"\bAder\b", r"\bLandkarte\b", r"\bWerkstück\b"]

# --- Erzaehlende Rahmung ---
RAHMUNG = [r"daraus folgt alles", r"der wichtigste punkt", r"das ist die eigentliche",
           r"sieht aus wie", r"auf den ersten blick", r"in wahrheit",
           r"stellt sich heraus"]

# --- Verbotene Anfaenge einer Bildunterschrift ---
CAPTION_VERBOTEN = re.compile(
    r"^(Das Interessante|Das zeigt|Das bedeutet|Interessant ist|Auffällig ist|"
    r"Hier sieht man|Man sieht|Zu sehen ist|Die Figur zeigt|Dargestellt ist)", re.I)

TAG = re.compile(r"<[^>]+>")
CODE = re.compile(r"<(code|pre)\b.*?</\1>", re.S)


def klartext(fragment, ohne_code=True):
    """Prosa ohne Auszeichnung. Code wird entfernt — in `<code>` steht kein Deutsch."""
    if ohne_code:
        fragment = CODE.sub(" ", fragment)
    return re.sub(r"\s+", " ", TAG.sub(" ", fragment)).strip()


def woerter(t):
    return [w for w in t.split() if w.strip(".,:;—–-()")]


def fliesstext(body):
    """Nur laufender Text: Anrisse, Bildunterschriften, Pruefpunkte.

    Absichtlich ohne SVG und Tabellen. Deren Inhalt ist Beschriftung, nicht
    Prosa — fuer die Satzlaenge gemessen ergaebe er sinnlose Befunde. Fuer die
    uebrigen Pruefungen bleibt er drin: eine Leseransprache in einer
    SVG-Beschriftung ist genauso ein Verstoss.
    """
    stuecke = re.findall(r"<(?:p|figcaption)\b[^>]*>(.*?)</(?:p|figcaption)>", body, re.S)
    return " ".join(klartext(x) for x in stuecke)


def pruefe(pfad, projekt):
    roh = open(pfad, encoding="utf-8").read()
    if '<div class="sheet">' not in roh:
        return None
    body = roh[roh.index('<div class="sheet">'):]
    prosa = klartext(body)
    rel = os.path.relpath(pfad, projekt)
    verstoesse, durchsicht = [], []

    # --- A1: Titel und Ueberschriften ---
    h1 = re.search(r"<h1>(.*?)</h1>", body, re.S)
    if h1:
        t = klartext(h1.group(1), ohne_code=False)
        if len(woerter(t)) > MAX_WOERTER:
            verstoesse.append("H1 hat %d Woerter (max %d): „%s\""
                              % (len(woerter(t)), MAX_WOERTER, t))
    for h in re.findall(r"<h2>(.*?)</h2>", body, re.S):
        t = klartext(h, ohne_code=False)
        n = len(woerter(t))
        if n > MAX_WOERTER:
            verstoesse.append("H2 hat %d Woerter (max %d): „%s\"" % (n, MAX_WOERTER, t))
        elif t.endswith("?"):
            verstoesse.append("H2 ist eine Frage: „%s\"" % t)

    # --- A6: Eyebrow wiederholt den Titel ---
    eb = re.search(r'class="tb-eyebrow">(.*?)</p>', body, re.S)
    if eb and h1:
        letzte = klartext(eb.group(1), ohne_code=False).split("·")[-1].strip()
        if letzte and letzte == klartext(h1.group(1), ohne_code=False):
            verstoesse.append("Eyebrow wiederholt den Titel wortgleich: „%s\"" % letzte)

    # --- A3: Wortliste ---
    for gruppe, woerterliste in [("unscharf", UNSCHARF), ("Wertung", WERTUNG)]:
        for w in woerterliste:
            if re.search(r"\b%s" % re.escape(w), prosa, re.I):
                verstoesse.append("Wortliste (%s): „%s\"" % (gruppe, w))

    # --- A2: Leseransprache ---
    for muster in ANSPRACHE:
        treffer = {m.group(0).lower() for m in re.finditer(muster, prosa, re.I)}
        for tr in sorted(treffer):
            verstoesse.append("Leseransprache: „%s\"" % tr)

    # --- Erzaehlende Rahmung ---
    for muster in RAHMUNG:
        if re.search(muster, prosa, re.I):
            verstoesse.append("Erzaehlende Rahmung: „%s\"" % muster)

    # --- A5: Bildunterschrift, nur die Verbotsliste ---
    for c in re.findall(r"<figcaption>(.*?)</figcaption>", body, re.S):
        t = klartext(c, ohne_code=False)
        if CAPTION_VERBOTEN.match(t):
            verstoesse.append("Bildunterschrift beschreibt die Figur: „%s…\"" % t[:52])

    # --- Durchsicht: Metaphern-Kandidaten ---
    for muster in METAPHER:
        for tr in sorted({m.group(0) for m in re.finditer(muster, prosa)}):
            durchsicht.append("Metapher pruefen: „%s\"" % tr)

    # --- Durchsicht: lange Saetze ---
    # Nur Fliesstext. SVG-Beschriftungen und Tabellenzellen sind keine Saetze;
    # aneinandergereiht ergeben sie Wortketten, die nichts melden.
    for satz in re.split(r"(?<=[.!?]) ", fliesstext(body)):
        n = len(woerter(satz))
        if n > MAX_SATZ:
            durchsicht.append("Satz mit %d Woertern: „%s…\"" % (n, satz[:56]))

    return {"datei": rel, "verstoesse": verstoesse, "durchsicht": durchsicht}


def sammle(args, projekt):
    if args.datei:
        return [os.path.abspath(args.datei)]
    docs = lib.docs_dir(projekt)
    if args.repo:
        return sorted(glob.glob(os.path.join(docs, args.repo, "etappe-*.html")))
    return (sorted(glob.glob(os.path.join(docs, "*", "etappe-*.html")))
            + [p for p in sorted(glob.glob(os.path.join(docs, "*.html")))
               if not p.endswith("index.html")])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=None)
    ap.add_argument("--datei", default=None)
    ap.add_argument("--project", default=None)
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()
    projekt = lib.project_root(args.project)

    pfade = sammle(args, projekt)
    if not pfade:
        print("Keine Blattseiten gefunden.", file=sys.stderr)
        return 2

    blaetter = [b for b in (pruefe(p, projekt) for p in pfade) if b]
    n_v = sum(len(b["verstoesse"]) for b in blaetter)
    n_d = sum(len(b["durchsicht"]) for b in blaetter)

    if args.json:
        print(json.dumps({"blaetter": blaetter, "verstoesse": n_v,
                          "durchsicht": n_d}, ensure_ascii=False, indent=2))
        return 3 if n_v else 0

    if not args.quiet:
        for b in blaetter:
            if not (b["verstoesse"] or b["durchsicht"]):
                continue
            print("\n%s" % b["datei"])
            for v in b["verstoesse"]:
                print("  VERSTOSS    %s" % v)
            for d in b["durchsicht"]:
                print("  durchsicht  %s" % d)
        print("")

    sauber = sum(1 for b in blaetter if not b["verstoesse"])
    print("%d Blattseite(n): %d ohne Verstoss, %d Verstoesse, %d zur Durchsicht."
          % (len(blaetter), sauber, n_v, n_d))
    return 3 if n_v else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except lib.ProjectError as exc:
        print("FEHLER: %s" % exc, file=sys.stderr)
        sys.exit(2)
