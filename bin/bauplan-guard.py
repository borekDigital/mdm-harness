#!/usr/bin/env python3
"""Invarianten des Bauplan-Bestands.

Der Schadensfall, gegen den das schuetzt: Es ist nur ein Repo geklont, eine
Sitzung schliesst daraus, die anderen existierten nicht, und raeumt deren Doku
weg. Deshalb gilt: **Bestand wird nie aus lokaler Anwesenheit abgeleitet.**
Referenz ist workspace.yaml und der letzte Commit, nicht das Dateisystem.

Zwei Betriebsarten:

  --check-write <ziel> <neuer-inhalt>   PreToolUse: verhindert Schrumpfen
  --verify                              Nachlauf: Arbeitsbaum gegen git HEAD

Exit 0 = unauffaellig, 2 = Verstoss (blockiert im Hook, faellt in CI durch).
"""

import argparse
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bauplan_lib as lib  # noqa: E402


def git(project, *args):
    return subprocess.run(
        ["git", "-C", project, *args], capture_output=True, text=True,
    )


def head_version(project, rel):
    """Datei aus dem letzten Commit. None, wenn dort noch unbekannt."""
    out = git(project, "show", "HEAD:%s" % rel)
    return out.stdout if out.returncode == 0 else None


def etappen_nrs(raw):
    try:
        return {e.get("nr") for e in json.loads(raw).get("etappen", [])}
    except (ValueError, AttributeError):
        return None


def repo_entries(raw):
    """Repos aus workspace.yaml als {schluessel: remote}, ohne YAML-Abhaengigkeit.
    Die Datei ist flach genug, dass die Einrueckung als Grammatik reicht.

    Das Remote wird mitgelesen, weil erst es ein Repo identifiziert. Der
    Schluessel ist nur ein Name und darf sich aendern (`theme` -> `theme-mdm`);
    das Remote bleibt. Siehe check_write."""
    entries, in_repos, current = {}, False, None
    for line in raw.splitlines():
        if re.match(r"^repos:\s*$", line):
            in_repos = True
            continue
        if in_repos:
            if re.match(r"^\S", line):
                break
            m = re.match(r"^  ([A-Za-z0-9_-]+):\s*$", line)
            if m:
                current = m.group(1)
                entries.setdefault(current, None)
                continue
            m = re.match(r"^    remote:\s*\"?([^\"]+)\"?\s*$", line)
            if m and current:
                entries[current] = m.group(1).strip()
    return entries


def repo_keys(raw):
    """Nur die Schluessel — fuer Aufrufer, die das Remote nicht brauchen."""
    return set(repo_entries(raw))


def check_write(project, target, new_content):
    """Verhindert, dass ein Schreibvorgang Bestand verliert."""
    rel = os.path.relpath(os.path.abspath(target), project)
    violations = []

    if rel.endswith(lib.MANIFEST_SUFFIX):
        if os.path.isfile(target):
            with open(target, encoding="utf-8") as fh:
                old = etappen_nrs(fh.read())
            new = etappen_nrs(new_content)
            if new is None:
                violations.append("Der neue Inhalt ist kein gueltiges JSON.")
            elif old:
                lost = sorted(n for n in old - new if n is not None)
                if lost:
                    violations.append(
                        "Etappen %s wuerden aus %s verschwinden. Etappen werden "
                        "aktualisiert, nicht entfernt." % (
                            ", ".join(str(n) for n in lost), rel)
                    )

    if os.path.basename(rel) == "workspace.yaml":
        if os.path.isfile(target):
            with open(target, encoding="utf-8") as fh:
                old = repo_entries(fh.read())
            new = repo_entries(new_content)
            new_remotes = {r for r in new.values() if r}
            # Ein Schluessel darf verschwinden, solange sein Remote bleibt — das
            # ist eine Umbenennung, kein Verlust. Weg ist ein Repo erst, wenn
            # auch sein Remote nirgends mehr steht.
            lost = sorted(
                key for key, remote in old.items()
                if key not in new and (remote is None or remote not in new_remotes)
            )
            if lost:
                violations.append(
                    "Repos %s wuerden aus workspace.yaml verschwinden. Ein nicht "
                    "geklontes Repo ist uebersprungen, nicht abgeschafft." % ", ".join(lost)
                )
    return violations


def verify(project):
    """Arbeitsbaum gegen den letzten Commit.

    Rueckgabe: (verluste, luecken). Der Unterschied ist wesentlich.

    **Verlust** heisst: etwas war da und ist weg — geloeschte Blaetter, aus einem
    Manifest entfernte Etappen. Das ist der Schadensfall, gegen den der Guard
    gebaut wurde, und muss den Lauf rot machen.

    **Luecke** heisst: eine Etappe steht im Manifest, ihre Quelle wurde aber noch
    nie angelegt — etwa weil ein aelterer Blattsatz erst teilweise zurueckgeholt
    ist. Das ist ein offener Posten, kein Schaden. Wuerde er den Lauf rot machen,
    waere jeder Lauf rot und die Warnung damit wertlos.
    """
    verluste, luecken = [], []

    out = git(project, "diff", "--name-status", "HEAD", "--",
              "docs/bauplan", ".claude/bauplan", "workspace.yaml")
    if out.returncode == 0:
        for line in out.stdout.splitlines():
            parts = line.split("\t")
            if parts and parts[0].startswith("D"):
                verluste.append(
                    "%s ist geloescht. Wiederherstellen: git checkout HEAD -- %s"
                    % (parts[-1], parts[-1])
                )

    for repo, path, manifest in lib.iter_manifests(project):
        rel = os.path.relpath(path, project)
        old_raw = head_version(project, rel)
        if old_raw:
            old, new = etappen_nrs(old_raw), {e.get("nr") for e in manifest.get("etappen", [])}
            lost = sorted(n for n in (old or set()) - new if n is not None)
            if lost:
                verluste.append(
                    "%s: Etappen %s fehlen gegenueber HEAD."
                    % (rel, ", ".join(str(n) for n in lost))
                )
        # Jede Etappe im Manifest braucht ihre HTML-Quelle.
        for etappe in manifest.get("etappen", []):
            sheet = lib.sheet_path(repo, etappe.get("nr"), project)
            if not os.path.isfile(sheet):
                luecken.append(
                    "%s Etappe %s (%s): Quelle %s fehlt."
                    % (repo, etappe.get("nr"), etappe.get("title"),
                       os.path.relpath(sheet, project))
                )
    return verluste, luecken


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check-write", nargs=2, metavar=("ZIEL", "INHALTSDATEI"))
    ap.add_argument("--verify", action="store_true")
    ap.add_argument("--strict", action="store_true",
                    help="auch offene Luecken als Verstoss werten")
    ap.add_argument("--project", default=None)
    args = ap.parse_args()
    project = lib.project_root(args.project)

    if args.check_write:
        target, content_file = args.check_write
        with open(content_file, encoding="utf-8") as fh:
            violations = check_write(project, target, fh.read())
    elif args.verify:
        lib.assert_project(project)
        verluste, luecken = verify(project)
        for l in luecken:
            print("BAUPLAN-LUECKE: %s" % l, file=sys.stderr)
        if luecken:
            print("BAUPLAN-LUECKE: %d Etappe(n) ohne Quelle — offener Posten, "
                  "kein Verlust. Zurueckholen mit bin/bauplan-import.py."
                  % len(luecken), file=sys.stderr)
        violations = verluste + (luecken if args.strict else [])
    else:
        ap.error("--check-write oder --verify angeben")
        return 2

    if violations:
        for v in violations:
            print("BAUPLAN-GUARD: %s" % v, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except lib.ProjectError as exc:
        print("FEHLER: %s" % exc, file=sys.stderr)
        sys.exit(2)
