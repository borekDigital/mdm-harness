#!/usr/bin/env python3
"""befehl.py — zerlegt einen Bash-Befehl in einfache Befehle, fuer die Waechter-Hooks.

Spec: .claude/specs/harness/bauplan-guard-fehlalarme.md

Die Waechter pruefen Woerter, nicht Text: In `git commit -m "git push --force"` ist
„git push --force“ ein einzelnes Argument, kein Befehl. Heredoc-Inhalte sind Daten.
Befehlsersetzungen (`$(...)`, Backticks) und `bash -c`/`eval` werden mitzerlegt, weil
die Shell sie ausfuehrt.

Grenzen (bewusst): Variablen, Aliase und Funktionen werden nicht aufgeloest. Bei offenen
Anfuehrungszeichen wirft `zerlege` ValueError — der Aufrufer entscheidet fail-closed.
"""

import posixpath
import re
import shlex

TRENNER = {";", "&&", "||", "|", "&", "|&", "(", ")", ";;"}
AUSGABE = {">", ">>", ">|", "&>", "&>>"}
EINGABE = {"<", "<<", "<<<", "<>", "<&", "<<-"}
WRAPPER = {"sudo", "env", "command", "builtin", "exec", "time", "nice", "nohup", "npx"}
SHELLS = {"bash", "sh", "zsh", "dash"}


class Befehl:
    def __init__(self, woerter, umleitungen, cwd):
        self.woerter = woerter
        self.umleitungen = umleitungen  # [(operator, ziel)] — nur Ausgaben, ohne /dev/null und fd-Kopien
        self.cwd = cwd  # relativ zum Startverzeichnis, "" = Start

    def __repr__(self):
        return "Befehl(%r, %r, cwd=%r)" % (self.woerter, self.umleitungen, self.cwd)


def _heredocs(text):
    """Heredoc-Inhalte entfernen. Liefert (befehlstext, inhalte_mit_ersetzung)."""
    zeilen = text.split("\n")
    raus, ersetzbar, i = [], [], 0
    while i < len(zeilen):
        zeile = zeilen[i]
        raus.append(zeile)
        i += 1
        for m in re.finditer(r"<<(-?)\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\2", zeile):
            tabs, quote, ende = m.group(1), m.group(2), m.group(3)
            inhalt = []
            while i < len(zeilen):
                z = zeilen[i].lstrip("\t") if tabs else zeilen[i]
                i += 1
                if z == ende:
                    break
                inhalt.append(zeilen[i - 1])
            if not quote:  # ungequotet: die Shell fuehrt $(...) im Inhalt aus
                ersetzbar.append("\n".join(inhalt))
    return "\n".join(raus), ersetzbar


def _ersetzungen(text, quoting=True):
    """Inhalte von $(...) und `...`, die die Shell ausfuehrt.

    Nicht ausgefuehrt werden: alles in einfachen Anfuehrungszeichen, escapte Backticks (\\`)
    und $((...)) (Arithmetik). In Heredoc-Inhalten gilt kein Quoting (quoting=False).
    """
    funde, i, n, einfach = [], 0, len(text), False
    while i < n:
        c = text[i]
        if c == "\\" and not einfach:
            i += 2
            continue
        if quoting and c == "'":
            einfach = not einfach
        elif einfach:
            pass
        elif c == "$" and text[i + 1:i + 2] == "(" and text[i + 2:i + 3] != "(":
            tiefe, j = 1, i + 2
            while j < n and tiefe:
                tiefe += {"(": 1, ")": -1}.get(text[j], 0)
                j += 1
            funde.append(text[i + 2:j - 1])
            i = j
            continue
        elif c == "`":
            puffer, j = [], i + 1
            while j < n and text[j] != "`":
                if text[j] == "\\" and j + 1 < n:
                    puffer.append(text[j + 1])
                    j += 2
                    continue
                puffer.append(text[j])
                j += 1
            funde.append("".join(puffer))
            i = j + 1
            continue
        i += 1
    return funde


def _token(text):
    lex = shlex.shlex(text, posix=True, punctuation_chars=True)
    lex.whitespace = " \t\r"
    lex.whitespace_split = False
    lex.commenters = "#"
    toks = []
    for t in lex:
        if t and set(t) <= set("();<>|&\n") and "\n" in t:
            # shlex fasst Satzzeichen zusammen ("|\n"): Zeilenumbruch abtrennen
            for teil in re.split(r"(\n)", t):
                if teil:
                    toks.append(teil)
        else:
            toks.append(t)
    return toks


def _ohne_wrapper(w):
    while w:
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", w[0]):
            w = w[1:]
        elif w[0] in WRAPPER:
            nimmt_wert = w[0] in ("nice", "sudo")
            w = w[1:]
            while w and (w[0].startswith("-") or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", w[0])):
                opt = w[0]
                w = w[1:]
                if nimmt_wert and opt in ("-n", "-u", "-g") and w:
                    w = w[1:]
        else:
            break
    return w


def zerlege(text, cwd=""):
    """Befehlstext -> [Befehl]. Wirft ValueError bei offenen Anfuehrungszeichen."""
    text = text.replace("\\\n", " ")
    befehlstext, heredoc_inhalte = _heredocs(text)
    toks = _token(befehlstext)

    ergebnis, woerter, umleitungen = [], [], []

    def abschliessen():
        nonlocal woerter, umleitungen, cwd
        w = _ohne_wrapper(woerter)
        if w:
            ergebnis.append(Befehl(w, umleitungen, cwd))
            if w[0] == "cd":
                ziel = w[1] if len(w) > 1 else "~"
                cwd = ziel if ziel.startswith(("/", "~")) else posixpath.normpath(posixpath.join(cwd or ".", ziel))
            if w[0] in SHELLS and "-c" in w[1:-1]:
                ergebnis.extend(zerlege(w[w.index("-c") + 1], cwd))
            if w[0] == "eval" and len(w) > 1:
                ergebnis.extend(zerlege(" ".join(w[1:]), cwd))
        woerter, umleitungen = [], []

    i = 0
    while i < len(toks):
        t = toks[i]
        if t in TRENNER or t == "\n":
            abschliessen()
        elif t in AUSGABE or t == ">&":
            ziel = toks[i + 1] if i + 1 < len(toks) else ""
            i += 1
            if woerter and re.fullmatch(r"\d+", woerter[-1]):
                woerter.pop()  # "2>" — die 2 ist der Dateideskriptor, kein Argument
            if t == ">&" and re.fullmatch(r"\d+|-", ziel):
                pass  # 2>&1: Kopie eines Dateideskriptors
            elif ziel != "/dev/null":
                umleitungen.append((">" if t == ">&" else t, ziel))
        elif t in EINGABE:
            i += 1
            if woerter and re.fullmatch(r"\d+", woerter[-1]):
                woerter.pop()
        else:
            woerter.append(t)
        i += 1
    abschliessen()

    for inhalt in _ersetzungen(befehlstext) + [e for h in heredoc_inhalte for e in _ersetzungen(h, quoting=False)]:
        ergebnis.extend(zerlege(inhalt, cwd))
    return ergebnis
