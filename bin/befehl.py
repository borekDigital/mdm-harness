#!/usr/bin/env python3
"""befehl.py — zerlegt einen Bash-Befehl in einfache Befehle, fuer die Waechter-Hooks.

Spec: .claude/specs/harness/bauplan-guard-fehlalarme.md

Die Waechter pruefen Woerter, nicht Text: In `git commit -m "git push --force"` ist
„git push --force“ ein einzelnes Argument, kein Befehl. Heredoc-Inhalte sind Daten.
Befehlsersetzungen (`$(...)`, Backticks) und `bash -c`/`eval` werden mitzerlegt, weil
die Shell sie ausfuehrt.

Der Lexer folgt den Quoting-Regeln von Bash, nicht denen von shlex: `$(...)` oeffnet auch
in "..." einen eigenen Quoting-Kontext, `<<` ist nur ausserhalb von Strings ein Heredoc,
`$'...'` kennt Escapes, `#` beginnt nur am Wortanfang einen Kommentar. (shlex scheiterte an
den ersten beiden Faellen — Fund aus dem CI-Lauf von PR #23.)

Grenzen (bewusst): Variablen, Aliase und Funktionen werden nicht aufgeloest. Bei offenen
Anfuehrungszeichen oder Klammern wirft `zerlege` ValueError — der Aufrufer entscheidet fail-closed.
"""

import posixpath
import re

TRENNER = {";", "&&", "||", "|", "&", "|&", "(", ")", ";;"}
AUSGABE = {">", ">>", ">|", "&>", "&>>"}
EINGABE = {"<", "<<", "<<<", "<>", "<&", "<<-"}
WRAPPER = {"sudo", "env", "command", "builtin", "exec", "time", "nice", "nohup", "npx"}
SHELLS = {"bash", "sh", "zsh", "dash"}
# Laengste zuerst, damit "&&" vor "&" und "<<-" vor "<<" greift
OPERATOREN = sorted(TRENNER | AUSGABE | EINGABE | {">&"}, key=len, reverse=True)
WORTENDE = set(" \t\r\n;&|()<>")


class Befehl:
    def __init__(self, woerter, umleitungen, cwd):
        self.woerter = woerter
        self.umleitungen = umleitungen  # [(operator, ziel)] — nur Ausgaben, ohne /dev/null und fd-Kopien
        self.cwd = cwd  # relativ zum Startverzeichnis, "" = Start

    def __repr__(self):
        return "Befehl(%r, %r, cwd=%r)" % (self.woerter, self.umleitungen, self.cwd)


class _Lexer:
    """Text -> Token ('w', wort) | ('op', operator) | ('nl', '\\n').

    Sammelt nebenbei die Inhalte von Befehlsersetzungen, die die Shell ausfuehrt.
    """

    def __init__(self, text):
        self.t, self.i, self.n = text, 0, len(text)
        self.ersetzungen = []
        self.offene_heredocs = []  # [(ende, tabs_entfernen, gequotet)]

    def token(self):
        toks = []
        while self.i < self.n:
            c = self.t[self.i]
            if c in " \t\r":
                self.i += 1
            elif c == "\\" and self.t[self.i + 1:self.i + 2] == "\n":
                self.i += 2  # Zeilenfortsetzung
            elif c == "\n":
                self.i += 1
                toks.append(("nl", "\n"))
                self._heredoc_inhalte()
            elif c == "#":
                while self.i < self.n and self.t[self.i] != "\n":
                    self.i += 1
            else:
                op = next((o for o in OPERATOREN if self.t.startswith(o, self.i)), None)
                if op:
                    self.i += len(op)
                    toks.append(("op", op))
                    if op in ("<<", "<<-"):
                        while self.i < self.n and self.t[self.i] in " \t":
                            self.i += 1
                        roh_start = self.i
                        ende = self._wort()
                        gequotet = any(q in self.t[roh_start:self.i] for q in "'\"\\")
                        self.offene_heredocs.append((ende, op == "<<-", gequotet))
                        toks.append(("w", ende))
                else:
                    toks.append(("w", self._wort()))
        return toks

    def _wort(self):
        teile = []
        while self.i < self.n and self.t[self.i] not in WORTENDE:
            c = self.t[self.i]
            if c == "\\":
                if self.i + 1 >= self.n:
                    raise ValueError("Backslash am Ende")
                teile.append(self.t[self.i + 1])
                self.i += 2
            elif c == "'":
                ende = self.t.find("'", self.i + 1)
                if ende < 0:
                    raise ValueError("Kein schliessendes '")
                teile.append(self.t[self.i + 1:ende])
                self.i = ende + 1
            elif c == "$" and self.t[self.i + 1:self.i + 2] == "'":
                teile.append(self._ansi_c())
            elif c == '"':
                teile.append(self._doppelt())
            elif c == "$" and self.t[self.i + 1:self.i + 2] == "(":
                teile.append(self._klammer())
            elif c == "`":
                teile.append(self._backtick())
            else:
                teile.append(c)
                self.i += 1
        return "".join(teile)

    def _ansi_c(self):
        i, teile = self.i + 2, []
        while i < self.n and self.t[i] != "'":
            if self.t[i] == "\\" and i + 1 < self.n:
                teile.append(self.t[i + 1])
                i += 2
            else:
                teile.append(self.t[i])
                i += 1
        if i >= self.n:
            raise ValueError("Kein schliessendes ' in $'...'")
        self.i = i + 1
        return "".join(teile)

    def _doppelt(self):
        self.i += 1
        teile = []
        while self.i < self.n and self.t[self.i] != '"':
            c = self.t[self.i]
            if c == "\\" and self.i + 1 < self.n:
                nachfolger = self.t[self.i + 1]
                teile.append(nachfolger if nachfolger in '$`"\\\n' else "\\" + nachfolger)
                self.i += 2
            elif c == "$" and self.t[self.i + 1:self.i + 2] == "(":
                teile.append(self._klammer())
            elif c == "`":
                teile.append(self._backtick())
            else:
                teile.append(c)
                self.i += 1
        if self.i >= self.n:
            raise ValueError('Kein schliessendes "')
        self.i += 1
        return "".join(teile)

    def _klammer(self):
        """$(...) oder $((...)) ab self.i; liefert den Rohtext, merkt sich den Inhalt."""
        start = self.i
        arithmetik = self.t[start + 2:start + 3] == "("
        self.i += 2
        tiefe = 1
        while self.i < self.n:
            c = self.t[self.i]
            if c == "\\":
                self.i += 2
            elif c == "'":
                ende = self.t.find("'", self.i + 1)
                if ende < 0:
                    raise ValueError("Kein schliessendes ' in $(...)")
                self.i = ende + 1
            elif c == '"':
                self._doppelt()
            elif c == "`":
                self._backtick()
            elif c == "(":
                tiefe += 1
                self.i += 1
            elif c == ")":
                tiefe -= 1
                self.i += 1
                if tiefe == 0:
                    break
            else:
                self.i += 1
        if tiefe:
            raise ValueError("Keine schliessende Klammer fuer $(")
        roh = self.t[start:self.i]
        if not arithmetik:
            self.ersetzungen.append(self.t[start + 2:self.i - 1])
        return roh

    def _backtick(self):
        start = self.i
        i, teile = self.i + 1, []
        while i < self.n and self.t[i] != "`":
            if self.t[i] == "\\" and i + 1 < self.n:
                teile.append(self.t[i + 1])
                i += 2
            else:
                teile.append(self.t[i])
                i += 1
        if i >= self.n:
            raise ValueError("Kein schliessender Backtick")
        self.ersetzungen.append("".join(teile))
        self.i = i + 1
        return self.t[start:self.i]

    def _heredoc_inhalte(self):
        """Nach einem Zeilenumbruch: Inhalte offener Heredocs ueberspringen (Daten, kein Befehl)."""
        for ende, tabs, gequotet in self.offene_heredocs:
            zeilen = []
            while self.i < self.n:
                nl = self.t.find("\n", self.i)
                zeile = self.t[self.i:] if nl < 0 else self.t[self.i:nl]
                self.i = self.n if nl < 0 else nl + 1
                if (zeile.lstrip("\t") if tabs else zeile) == ende:
                    break
                zeilen.append(zeile)
            if not gequotet:  # ungequotet: die Shell fuehrt $(...) im Inhalt aus
                self.ersetzungen.extend(_ersetzungen_ohne_quoting("\n".join(zeilen)))
        self.offene_heredocs = []


def _ersetzungen_ohne_quoting(text):
    """$(...) und Backticks in Heredoc-Inhalten (dort gilt kein Quoting)."""
    funde, i, n = [], 0, len(text)
    while i < n:
        if text[i] == "\\":
            i += 2
        elif text.startswith("$(", i) and not text.startswith("$((", i):
            tiefe, j = 1, i + 2
            while j < n and tiefe:
                tiefe += {"(": 1, ")": -1}.get(text[j], 0)
                j += 1
            funde.append(text[i + 2:j - 1])
            i = j
        elif text[i] == "`":
            j = text.find("`", i + 1)
            if j < 0:
                break
            funde.append(text[i + 1:j])
            i = j + 1
        else:
            i += 1
    return funde


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
    """Befehlstext -> [Befehl]. Wirft ValueError bei offenen Anfuehrungszeichen oder Klammern."""
    lexer = _Lexer(text)
    toks = lexer.token()

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
        art, t = toks[i]
        if art == "nl" or (art == "op" and t in TRENNER):
            abschliessen()
        elif art == "op" and (t in AUSGABE or t == ">&"):
            ziel = toks[i + 1][1] if i + 1 < len(toks) and toks[i + 1][0] == "w" else ""
            i += 1
            if woerter and re.fullmatch(r"\d+", woerter[-1]):
                woerter.pop()  # "2>" — die 2 ist der Dateideskriptor, kein Argument
            if t == ">&" and re.fullmatch(r"\d+|-", ziel):
                pass  # 2>&1: Kopie eines Dateideskriptors
            elif ziel != "/dev/null":
                umleitungen.append((">" if t == ">&" else t, ziel))
        elif art == "op" and t in EINGABE:
            i += 1
            if woerter and re.fullmatch(r"\d+", woerter[-1]):
                woerter.pop()
        else:
            woerter.append(t)
        i += 1
    abschliessen()

    for inhalt in lexer.ersetzungen:
        ergebnis.extend(zerlege(inhalt, cwd))
    return ergebnis
