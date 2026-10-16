#!/usr/bin/env python3
"""git-safety.py — Regeln des Hooks .claude/hooks/git-safety.sh.

Blockiert destruktive Git-Kommandos und riskante Shopify-CLI-Aufrufe. Geprueft werden
die einfachen Befehle aus bin/befehl.py, nicht der Text: Eine Commit-Message, die
„git push --force“ enthaelt, ist kein Force-Push.

Verwendung im Hook: Hook-JSON auf stdin.
Exit 0 = erlaubt, 2 = blockiert (Grund auf stderr), sonst Defekt (der Hook blockiert).
"""

import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import befehl  # noqa: E402

GIT_OPT_MIT_WERT = {"-C", "-c"}
GIT_OPT_LANG_MIT_WERT = ("--git-dir", "--work-tree", "--namespace", "--exec-path", "--super-prefix", "--config-env")
GIT_OPT_OHNE_WERT = {"--no-pager", "--paginate", "--bare", "-p", "-P", "--literal-pathspecs", "--glob-pathspecs",
                     "--noglob-pathspecs", "--no-replace-objects", "--no-optional-locks"}


def git_unterkommando(w):
    """['git', '-C', 'd', 'push', ...] -> ('push', [...]). Globale Optionen werden uebersprungen."""
    i = 1
    while i < len(w):
        a = w[i]
        if a in GIT_OPT_MIT_WERT:
            i += 2
        elif a.startswith(GIT_OPT_LANG_MIT_WERT):
            i += 1 if "=" in a else 2
        elif a in GIT_OPT_OHNE_WERT:
            i += 1
        else:
            return a, w[i + 1:]
    return None, []


def kurzflag(args, buchstabe):
    return any(re.match(r"^-[A-Za-z]*%s[A-Za-z]*$" % buchstabe, a) for a in args)


def pruefe_befehl(w):
    if w[0] == "git":
        sub, rest = git_unterkommando(w)
        argumente = [a for a in rest if not a.startswith("-")]
        if sub == "push":
            if (kurzflag(rest, "f") or any(a == "--force" or a.startswith(("--force-with-lease", "--force-if-includes"))
                                          for a in rest) or any(a.startswith("+") for a in argumente)):
                return "Force-Push ist nicht erlaubt."
            if any(re.search(r"(^|:|/)(main|master)$", a) for a in argumente):
                return "Direkter Push auf main/master ist nicht erlaubt."
            if "latori" in argumente:
                return "Push auf Remote 'latori' ist nicht erlaubt — nur historische Referenz."
        if sub == "reset" and "--hard" in rest:
            return "git reset --hard blockiert — nutze git stash."
        if sub == "clean" and (kurzflag(rest, "f") or "--force" in rest):
            return "git clean -f blockiert."
    if w[0] == "shopify" and len(w) > 2 and w[1] == "theme":
        sub = w[2]
        if sub == "publish":
            return "'theme publish' führt Konrad selbst im Admin/Terminal aus."
        if sub == "delete":
            return "'theme delete' führt Konrad selbst aus."
        if sub == "push" and any(a in ("--live", "-l", "--allow-live") for a in w[3:]):
            return "Push auf das Live-Theme ist nicht erlaubt — nur --unpublished/--development."
        if "--theme-editor-sync" in w:
            return "--theme-editor-sync löscht extern geänderte JSON-Dateien (CLI-Bug, community.shopify.dev/t/28292)."
    return None


def pruefe(cmd):
    """Befehlstext -> Grund (str) oder None."""
    try:
        befehle = befehl.zerlege(cmd)
    except ValueError as e:
        if re.search(r"\b(git|shopify)\b", cmd):
            return "Befehl nicht zerlegbar (%s) — mit git/shopify im Text wird fail-closed blockiert." % e
        return None
    for b in befehle:
        grund = pruefe_befehl(b.woerter)
        if grund:
            return grund
    return None


def main():
    try:
        cmd = json.load(sys.stdin)["tool_input"]["command"]
        if not isinstance(cmd, str) or not cmd.strip():
            raise ValueError("command leer")
    except Exception as e:
        print("git-safety: Hook-Eingabe nicht lesbar (%s) — Aktion blockiert (fail-closed)." % e, file=sys.stderr)
        return 2
    grund = pruefe(cmd)
    if grund:
        print("BLOCKED: " + grund, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
