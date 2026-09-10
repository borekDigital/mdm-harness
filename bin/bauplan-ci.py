#!/usr/bin/env python3
"""Auffrischungslauf fuer die CI — auch wenn niemand Claude benutzt hat.

Der Hook in `.claude/hooks/bauplan-staleness.sh` greift nur in einer
Claude-Sitzung. Wer normal committet und pusht, loest ihn nicht aus. Dieses
Script schliesst die Luecke: es vergleicht `last_seen_sha` aus dem Manifest mit
`HEAD` des Arbeits-Repos und leitet mit derselben Regel wie der Hook ab, welche
Etappen betroffen sind.

  bin/bauplan-ci.py --report                  nur ermitteln und ausgeben
  bin/bauplan-ci.py --regenerate              betroffene Etappen neu bauen lassen
  bin/bauplan-ci.py --regenerate --repo emailservice

Ohne `--regenerate` wird nichts geschrieben. Exit 3 heisst „es gibt Veraltetes",
damit ein CI-Schritt das ohne Ausgabe-Parsing auswerten kann.
"""

import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bauplan_lib as lib  # noqa: E402

CLAUDE_TIMEOUT = 3600


def sh(*args, cwd=None, check=False):
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=check)


def repo_head(repo_path):
    out = sh("git", "-C", repo_path, "rev-parse", "HEAD")
    return out.stdout.strip() if out.returncode == 0 else None


def stale_for(project, repo):
    """Betroffene Etappen eines Repos. None, wenn nicht auswertbar."""
    manifest = lib.load_manifest(repo, project)
    if manifest is None:
        return None, "kein Manifest"
    root = lib.manifest_root(manifest, repo)
    repo_path = project if root == "." else os.path.join(project, root)
    if not os.path.isdir(os.path.join(repo_path, ".git")):
        # Nicht geklont heisst uebersprungen, nicht abgeschafft.
        return None, "nicht geklont"
    since = manifest.get("last_seen_sha")
    head = repo_head(repo_path)
    if not since:
        return None, "kein last_seen_sha — erster Lauf"
    if since == head:
        return [], None
    out = sh("git", "-C", repo_path, "diff", "--name-only", "%s..HEAD" % since)
    if out.returncode != 0:
        return None, "Commit %s nicht im Klon (fetch-depth zu klein?)" % since[:8]
    root = lib.manifest_root(manifest, repo)
    changed = [line for line in out.stdout.splitlines()
               if line.strip() and not lib.is_ignored("/" + line, root)]
    return lib.affected_etappen(manifest, changed), None


def allowed_paths(project, repo, hits):
    """Genau die Dateien, die ein Auffrischungslauf anfassen darf."""
    paths = {os.path.relpath(lib.manifest_dir(project), project) + "/%s.manifest.json" % repo,
             "docs/bauplan/index.html"}
    for etappe, _ in hits:
        paths.add(os.path.relpath(lib.sheet_path(repo, etappe.get("nr"), project), project))
    return paths


def regenerate(project, repo, hits):
    """Claude Code headless nur fuer die betroffenen Etappen aufrufen."""
    nrs = ",".join(str(e.get("nr")) for e, _ in hits)
    prompt = (
        "/repo-bauplan %s --refresh\n\n"
        "Auffrischen ausschliesslich die Etappen %s. Alle anderen Blaetter bleiben "
        "Zeichen fuer Zeichen unveraendert. Halte dich an den Abschnitt "
        "'Auffrischen — nur das Veraltete' im Skill." % (repo, nrs)
    )
    cmd = ["claude", "-p", prompt, "--permission-mode", "acceptEdits"]
    print("  -> %s" % " ".join(cmd[:3]))
    try:
        res = subprocess.run(cmd, cwd=project, capture_output=True, text=True,
                             timeout=CLAUDE_TIMEOUT)
    except FileNotFoundError:
        print("  Claude Code CLI nicht gefunden — nur Bericht moeglich.", file=sys.stderr)
        return False
    except subprocess.TimeoutExpired:
        print("  Zeitueberschreitung nach %d s." % CLAUDE_TIMEOUT, file=sys.stderr)
        return False
    if res.returncode != 0:
        print(res.stderr.strip()[-1200:], file=sys.stderr)
        return False
    return True


def diff_within(project, allowed):
    """Hat der Lauf nur angefasst, was er anfassen durfte?"""
    out = sh("git", "-C", project, "diff", "--name-only", "--",
             "docs/bauplan", ".claude/bauplan")
    touched = {line for line in out.stdout.splitlines() if line.strip()}
    return touched, touched - allowed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--regenerate", action="store_true")
    ap.add_argument("--repo", default=None, help="nur dieses Repo")
    ap.add_argument("--project", default=None)
    args = ap.parse_args()
    project = lib.project_root(args.project)
    lib.assert_project(project)

    repos = ([args.repo] if args.repo
             else [r for r, _p, _m in lib.iter_manifests(project)])

    gesamt, uebersprungen, fehler = {}, {}, []
    for repo in repos:
        hits, grund = stale_for(project, repo)
        if hits is None:
            uebersprungen[repo] = grund
            print("%-16s uebersprungen — %s" % (repo, grund))
            continue
        gesamt[repo] = hits
        if hits:
            print("%-16s %d Etappen veraltet: %s" % (
                repo, len(hits), ", ".join(str(e.get("nr")) for e, _ in hits)))
            for etappe, triggers in hits:
                print("    Etappe %s (%s)" % (etappe.get("nr"), etappe.get("title")))
                for t in triggers[:6]:
                    print("      %s" % t)
                if len(triggers) > 6:
                    print("      ... und %d weitere" % (len(triggers) - 6))
        else:
            print("%-16s aktuell" % repo)

    veraltet = {r: h for r, h in gesamt.items() if h}

    if args.regenerate and veraltet:
        for repo, hits in veraltet.items():
            print("\nAuffrischen %s ..." % repo)
            allowed = allowed_paths(project, repo, hits)
            if not regenerate(project, repo, hits):
                fehler.append(repo)
                continue
            touched, ausserhalb = diff_within(project, allowed)
            if ausserhalb:
                print("  ABBRUCH: der Lauf hat Dateien ausserhalb des Auftrags geaendert:",
                      file=sys.stderr)
                for p in sorted(ausserhalb):
                    print("    %s" % p, file=sys.stderr)
                print("  Zuruecknehmen: git checkout HEAD -- %s"
                      % " ".join(sorted(ausserhalb)), file=sys.stderr)
                fehler.append(repo)
                continue
            print("  geaendert: %s" % (", ".join(sorted(touched)) or "nichts"))

            # Stand nachziehen — sonst meldet der naechste Lauf dieselben
            # Etappen erneut als veraltet und die Auffrischung laeuft im Kreis.
            # Das ist eine Tatsache, keine Ermessensfrage: nicht dem Modell
            # ueberlassen, sondern hier setzen.
            head = repo_head(project if lib.manifest_root(
                lib.load_manifest(repo, project), repo) == "." else os.path.join(project, repo))
            if head:
                manifest = lib.load_manifest(repo, project)
                manifest["last_seen_sha"] = head
                lib.save_manifest(repo, manifest, project)
                print("  last_seen_sha -> %s" % head[:10])

        # Bestand pruefen, bevor irgendetwas committet wird.
        guard = sh(sys.executable, os.path.join(project, "bin", "bauplan-guard.py"),
                   "--verify", "--project", project)
        if guard.returncode != 0:
            print(guard.stderr.strip(), file=sys.stderr)
            fehler.append("guard")

    summary = {
        "veraltet": {r: [e.get("nr") for e, _ in h] for r, h in veraltet.items()},
        "aktuell": [r for r, h in gesamt.items() if not h],
        "uebersprungen": uebersprungen,
        "fehler": fehler,
    }
    out_path = os.path.join(lib.manifest_dir(project), "CI-BERICHT.json")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as fh:
        json.dump(summary, fh, ensure_ascii=False, indent=2)
        fh.write("\n")

    if fehler:
        return 1
    return 3 if veraltet else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except lib.ProjectError as exc:
        print("FEHLER: %s" % exc, file=sys.stderr)
        sys.exit(2)
