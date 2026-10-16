#!/usr/bin/env python3
"""harness-stand.py — haelt fest, gegen welche Claude-Code-Version die Harness geprueft ist.

Spec: .claude/specs/harness/claude-struktur-aktuell.md, Teile D und E.

Die gepruefte Version steht in bin/harness-referenz.json (`claude_code_version`,
`stand`) — dieselbe Datei, aus der harness-check.py die erlaubten Felder liest.
Feldlisten und Version gehoeren zusammen: beide beschreiben denselben Doku-Stand.

Unterbefehle:
  hinweis   SessionStart-Hook: installierte Version neuer als gepruefte? -> Hinweis (JSON)
  changelog Changelog-Eintraege nach der geprueften Version (Exit 3) oder nichts (Exit 0)
  neueste   neueste Version im Changelog
  prompt    Auftrag fuer claude -p: Changelog-Differenz plus Harness-Check
  anheben   gepruefte Version und Stand in der Referenz setzen (nie rueckwaerts)
"""

import argparse
import datetime
import json
import os
import re
import shutil
import subprocess
import sys

BEFUND, DEFEKT = 3, 2
CHANGELOG_URL = "https://code.claude.com/docs/en/changelog.md"
MONATE = ["Januar", "Februar", "Maerz", "April", "Mai", "Juni", "Juli", "August",
          "September", "Oktober", "November", "Dezember"]


class Defekt(Exception):
    pass


def version(text):
    """'2.1.301 (Claude Code)' -> (2, 1, 301); None wenn nicht lesbar."""
    m = re.search(r"(\d+)\.(\d+)\.(\d+)", text or "")
    return tuple(int(x) for x in m.groups()) if m else None


def als_text(v):
    return ".".join(str(x) for x in v)


def heute():
    d = datetime.date.today()
    return "%d. %s %d" % (d.day, MONATE[d.month - 1], d.year)


class Stand:

    def __init__(self, root):
        self.root = root
        self.pfad = os.path.join(root, "bin", "harness-referenz.json")
        try:
            with open(self.pfad, encoding="utf-8") as fh:
                self.ref = json.load(fh)
        except (OSError, json.JSONDecodeError) as e:
            raise Defekt("bin/harness-referenz.json nicht lesbar: %s" % e)
        self.geprueft = version(self.ref.get("claude_code_version"))
        if not self.geprueft:
            raise Defekt("claude_code_version fehlt in bin/harness-referenz.json")

    def changelog_url(self):
        return self.ref.get("quellen", {}).get("changelog", CHANGELOG_URL)


def abschnitte(datei):
    """Changelog in [(version, text)] zerlegen, neueste zuerst."""
    with open(datei, encoding="utf-8") as fh:
        text = fh.read()
    teile = re.split(r"^## +(\d+\.\d+\.\d+)\s*$", text, flags=re.M)
    paare = [(version(teile[i]), "## %s\n%s" % (teile[i], teile[i + 1].strip()))
             for i in range(1, len(teile) - 1, 2)]
    if not paare:
        raise Defekt("%s enthaelt keine Versionen — Download fehlgeschlagen?" % datei)
    return paare


def neu_seit(datei, seit):
    return [text for v, text in abschnitte(datei) if v > seit]


# --- Unterbefehle -------------------------------------------------------


def cmd_hinweis(stand, args):
    installiert = args.installiert
    if installiert is None:
        claude = shutil.which("claude")
        if not claude:
            return 0
        try:
            installiert = subprocess.run([claude, "--version"], capture_output=True,
                                         text=True, timeout=5).stdout
        except (OSError, subprocess.TimeoutExpired):
            return 0
    v = version(installiert)
    if not v or v <= stand.geprueft:
        return 0
    text = ("Claude Code %s ist installiert, die Harness ist gegen %s geprueft (Stand %s). "
            "Neuerungen seither: %s — Abgleich ueber den Workflow „Harness aktuell halten“."
            % (als_text(v), als_text(stand.geprueft), stand.ref.get("stand", "?"),
               stand.changelog_url()))
    print(json.dumps({
        "systemMessage": text,
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": text + " Bei Aenderungen an Agenten, Skills, Rules, Hooks "
                                        "oder Settings den Changelog seit dieser Version beachten.",
        },
    }, ensure_ascii=False))
    return 0


def cmd_changelog(stand, args):
    seit = version(args.seit) if args.seit else stand.geprueft
    neu = neu_seit(args.datei, seit)
    if not neu:
        return 0
    print("\n\n".join(neu))
    return BEFUND


def cmd_neueste(stand, args):
    print(als_text(abschnitte(args.datei)[0][0]))
    return 0


def cmd_prompt(stand, args):
    seit = version(args.seit) if args.seit else stand.geprueft
    neu = neu_seit(args.datei, seit)
    check = ""
    if args.check:
        with open(args.check, encoding="utf-8") as fh:
            check = fh.read().strip()
    print(PROMPT.format(
        seit=als_text(seit),
        neueste=als_text(abschnitte(args.datei)[0][0]),
        changelog="\n\n".join(neu) or "(keine neuen Eintraege)",
        check=check or "(kein Befund)",
        datum=heute(),
    ))
    return 0


def cmd_anheben(stand, args):
    neu = version(args.version)
    if not neu:
        raise Defekt("Version %r nicht lesbar" % args.version)
    if neu < stand.geprueft:
        raise Defekt("%s ist aelter als die gepruefte Version %s — nie rueckwaerts"
                     % (als_text(neu), als_text(stand.geprueft)))
    stand.ref["claude_code_version"] = als_text(neu)
    stand.ref["stand"] = args.datum or heute()
    with open(stand.pfad, "w", encoding="utf-8") as fh:
        json.dump(stand.ref, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    return 0


PROMPT = """\
Du pruefst die Claude-Code-Harness in diesem Repo (mdm-harness) gegen neue Claude-Code-Versionen.
Du aenderst KEINE Datei. Deine Antwort ist ausschliesslich der Bericht in Markdown, nichts davor
oder danach — er wird unveraendert als `.claude/harness-bericht.md` in einen PR uebernommen.

Gepruefte Version: {seit}. Neueste Version: {neueste}. Datum: {datum}.

## Auftrag

1. Lies die Changelog-Eintraege unten. Waehle nur Eintraege, die die Harness betreffen koennen:
   Frontmatter von Agenten und Skills, Rules, Hook-Events und Hook-Ausgaben, Settings-Schluessel,
   Berechtigungen, MCP, Modelle und Modell-Aliase, `claude -p` und CI, Abkuendigungen.
   Reine Terminal-, IDE- oder Darstellungs-Fixes lass weg.
2. Suche fuer jeden gewaehlten Eintrag die betroffene Stelle in `.claude/` (agents, skills, rules,
   hooks, settings.json, README.md), `.mcp.json`, `templates/` und `bin/harness-referenz.json`.
   Lies die Dateien tatsaechlich — keine Annahmen ueber Inhalte.
3. Bei Unklarheit lies die Doku-Seite als Markdown (Index: https://code.claude.com/docs/llms.txt,
   jede Seite auch als `.md`).

## Format

# Harness-Abgleich {datum}

Claude Code {seit} → {neueste}

## Befunde

| # | Changelog-Eintrag (Version) | Betroffene Stelle (Datei:Zeile) | Evidenz | Vorschlag |
|---|---|---|---|---|

Evidenz ist genau eines von: ✅ belegt (aus gelesener Datei), ⚠️ Vermutung, ❌ unbekannt.
Gibt es keine Befunde, schreib eine Zeile „Keine Auswirkung auf die Harness.“

## Vorschlaege fuer bin/harness-referenz.json

Neue oder entfallene Frontmatter-Felder, Hook-Events, Modell-Aliase — als Liste, mit Version.
Sonst „Keine.“

## Harness-Check

Die Befunde unten aus `bin/harness-check.py`, jeweils mit kurzer Einordnung. Sonst „Sauber.“

Deutsch, sachlich, ohne Einleitung und ohne Schlussformel.

---

## Harness-Check (bin/harness-check.py)

{check}

## Changelog seit {seit}

{changelog}
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    sub = ap.add_subparsers(dest="befehl", required=True)
    p = sub.add_parser("hinweis")
    p.add_argument("--installiert", help="Version vorgeben statt `claude --version` (Tests)")
    for name in ("changelog", "prompt"):
        p = sub.add_parser(name)
        p.add_argument("--datei", required=True, help="lokale Kopie von CHANGELOG.md")
        p.add_argument("--seit", help="statt der geprueften Version")
        if name == "prompt":
            p.add_argument("--check", help="Ausgabe von harness-check.py")
    p = sub.add_parser("neueste")
    p.add_argument("--datei", required=True)
    p = sub.add_parser("anheben")
    p.add_argument("--version", required=True)
    p.add_argument("--datum", help="Stand, Standard: heute")
    args = ap.parse_args()

    try:
        stand = Stand(os.path.abspath(args.root))
        return globals()["cmd_" + args.befehl](stand, args)
    except Defekt as e:
        if args.befehl == "hinweis":
            return 0  # der Hook stoert nie eine Sitzung
        print("harness-stand: %s" % e, file=sys.stderr)
        return DEFEKT
    except OSError as e:
        print("harness-stand: %s" % e, file=sys.stderr)
        return DEFEKT


if __name__ == "__main__":
    sys.exit(main())
