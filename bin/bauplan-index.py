#!/usr/bin/env python3
"""Erzeugt die Uebersichtsseite mit Inhaltsverzeichnis: docs/bauplan/index.html.

Bestandsquelle ist workspace.yaml, nicht das Dateisystem. Ein Repo ohne
Blattsatz erscheint als offener Posten — nicht als Luecke, die man
wegraeumt. Genau diese Richtung verhindert, dass ein halb geklonter
Workspace zur Kuerzung der Doku fuehrt.
"""

import argparse
import html
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bauplan_lib as lib  # noqa: E402

HEAD_ASSET = ".claude/skills/repo-bauplan/assets/bauplan-head.html"


def read_workspace(project):
    """Repo-Schluessel mit Name und Tech aus workspace.yaml, ohne YAML-Modul."""
    path = os.path.join(project, "workspace.yaml")
    repos, current, in_repos = {}, None, False
    if not os.path.isfile(path):
        return repos
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if re.match(r"^repos:\s*$", line):
                in_repos = True
                continue
            if not in_repos:
                continue
            if re.match(r"^\S", line):
                break
            m = re.match(r"^  ([A-Za-z0-9_-]+):\s*$", line)
            if m:
                current = m.group(1)
                repos[current] = {"key": current}
                continue
            m = re.match(r'^    (name|tech|group|path):\s*"?([^"\n]*)"?\s*$', line)
            if m and current:
                repos[current][m.group(1)] = m.group(2).strip()
    return repos


def stale_etappen(project, repo):
    """Etappennummern aus <repo>.STALE.md — die Arbeitsliste des Staleness-Hooks."""
    path = os.path.join(lib.manifest_dir(project), repo + ".STALE.md")
    if not os.path.isfile(path):
        return set()
    with open(path, encoding="utf-8") as fh:
        head = fh.read().split("---", 1)[0]
    return {int(n) for n in re.findall(r"^## Etappe (\d+)", head, re.M)}


def esc(v):
    return html.escape(str(v if v is not None else ""), quote=True)


def repo_section(project, key, meta, manifest, stale):
    name = meta.get("name", key)
    tech = meta.get("tech", "")
    rows = []

    if manifest is None:
        return """
  <section class="plate">
    <div class="plate-head">
      <span class="plate-no">%s</span>
      <h2>%s</h2>
    </div>
    <p class="lead">Noch kein Blattsatz. Anlegen mit <code>/repo-bauplan %s</code>.
      %s</p>
  </section>""" % (esc(key), esc(name), esc(key), esc(tech))

    for e in manifest.get("etappen", []):
        nr = e.get("nr")
        sheet = lib.sheet_path(key, nr, project)
        local = os.path.relpath(sheet, lib.docs_dir(project)) if os.path.isfile(sheet) else None
        offen = len(e.get("open_questions", []) or [])
        marker = ' <span class="f-alert">veraltet</span>' if nr in stale else ""
        links = []
        if local:
            links.append('<a href="%s">HTML</a>' % esc(local))
        if e.get("url"):
            links.append('<a href="%s">Artefakt</a>' % esc(e["url"]))
        rows.append(
            "<tr><td class=\"m\">%02d</td><td>%s%s</td><td class=\"m\">%s</td>"
            "<td class=\"m\">%s</td><td class=\"m\">%s</td><td class=\"m\">%s</td></tr>"
            % (nr, esc(e.get("title", "")), marker, esc(e.get("blaetter", "")),
               esc(e.get("findings", "")), offen or "—",
               " · ".join(links) or "<span class=\"f-alert\">fehlt</span>")
        )

    return """
  <section class="plate">
    <div class="plate-head">
      <span class="plate-no">%s</span>
      <h2>%s</h2>
    </div>
    <p class="lead">%s — %d Etappen, Stand %s.%s</p>
    <div class="tw">
      <table>
        <caption>Inhaltsverzeichnis %s</caption>
        <thead><tr><th class="m">Nr</th><th>Etappe</th><th class="m">Blätter</th>
          <th class="m">Funde</th><th class="m">Offen</th><th class="m">Quelle</th></tr></thead>
        <tbody>%s</tbody>
      </table>
    </div>
  </section>""" % (
        esc(key), esc(name), esc(tech), len(manifest.get("etappen", [])),
        esc(manifest.get("generated", "unbekannt")),
        (" <b>%d Etappen veraltet</b> — auffrischen mit <code>/repo-bauplan %s --refresh</code>."
         % (len(stale), key)) if stale else "",
        esc(key), "\n          ".join(rows),
    )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", default=None)
    ap.add_argument("--stand", default=None, help="Datum fuer die Meta-Zeile")
    args = ap.parse_args()
    project = lib.project_root(args.project)
    lib.assert_project(project)

    with open(os.path.join(project, HEAD_ASSET), encoding="utf-8") as fh:
        head = fh.read()

    repos = read_workspace(project)
    manifests = {r: m for r, _p, m in lib.iter_manifests(project)}

    gesamt_etappen = sum(len(m.get("etappen", [])) for m in manifests.values())
    mit_satz = sum(1 for r in repos if r in manifests)
    quellen = sum(
        1 for r, m in manifests.items() for e in m.get("etappen", [])
        if os.path.isfile(lib.sheet_path(r, e.get("nr"), project))
    )

    sections = "".join(
        repo_section(project, key, meta, manifests.get(key), stale_etappen(project, key))
        for key, meta in repos.items()
    )
    # Blattsaetze ohne Repo-Eintrag (z. B. die Harness selbst) hinten anhaengen.
    # Name und Tech kommen dann aus dem Manifest, nicht aus workspace.yaml.
    sections += "".join(
        repo_section(project, key,
                     {"name": m.get("name", key), "tech": m.get("tech", "")},
                     m, stale_etappen(project, key))
        for key, m in manifests.items() if key not in repos
    )

    body = """<title>MDM Architektur-Blattsätze</title>
%s
<div class="sheet">

  <div class="titleblock">
    <div class="tb-main">
      <p class="tb-eyebrow">MDM Workspace · Übersicht</p>
      <h1>Architektur-<br>Blattsätze</h1>
      <p>Einstiegspunkt in die Architektur-Dokumentation des Workspace. Jeder Blattsatz
         deckt ein Repo ab, jede Etappe eine Frage, jede Aussage ist mit
         <code>Datei:Zeile</code> belegt. Die HTML-Quellen liegen unter
         <code>docs/bauplan/</code> und sind versioniert — Stände lassen sich also
         vergleichen und als PDF weitergeben.</p>
    </div>
    <dl class="tb-meta">
      <div class="tb-cell"><dt>Repos</dt><dd>%d von %d dokumentiert</dd></div>
      <div class="tb-cell"><dt>Etappen</dt><dd>%d</dd></div>
      <div class="tb-cell"><dt>HTML-Quellen</dt><dd>%d von %d</dd></div>
      <div class="tb-cell"><dt>Design</dt><dd>bauplan-v1</dd></div>
      <div class="tb-cell"><dt>Stand</dt><dd>%s</dd></div>
    </dl>
  </div>

  <div class="legend">
    <span class="legend-item"><i class="swatch sw-web"></i>HTML <span>— Quelle im Repo</span></span>
    <span class="legend-item"><i class="swatch sw-worker"></i>Artefakt <span>— veröffentlichte Seite</span></span>
    <span class="legend-item"><i class="swatch sw-alert"></i>veraltet <span>— Quelldatei hat sich geändert</span></span>
    <span class="legend-item"><i class="swatch sw-vite"></i>offener Posten <span>— Repo ohne Blattsatz</span></span>
  </div>
%s

  <section class="plate">
    <div class="plate-head">
      <span class="plate-no">Werkzeuge</span>
      <h2>Erzeugen, prüfen, weitergeben</h2>
    </div>
    <div class="tw">
      <table>
        <caption>Befehle im Workspace-Root</caption>
        <thead><tr><th class="m">Befehl</th><th>Wirkung</th></tr></thead>
        <tbody>
          <tr><td class="m">/repo-bauplan &lt;repo&gt;</td><td>Kompletten Blattsatz bauen</td></tr>
          <tr><td class="m">/repo-bauplan &lt;repo&gt; --refresh</td><td>Nur die veralteten Etappen neu bauen</td></tr>
          <tr><td class="m">bin/bauplan-index.py</td><td>Diese Übersicht neu erzeugen</td></tr>
          <tr><td class="m">bin/bauplan-pdf.py &lt;repo&gt;</td><td>Ganzen Satz als ein PDF</td></tr>
          <tr><td class="m">bin/bauplan-pdf.py &lt;repo&gt; --einzeln</td><td>Ein PDF je Etappe</td></tr>
          <tr><td class="m">bin/bauplan-stale.py --repo &lt;repo&gt;</td><td>Veraltete Etappen ermitteln</td></tr>
          <tr><td class="m">bin/bauplan-guard.py --verify</td><td>Bestand gegen den letzten Commit prüfen</td></tr>
        </tbody>
      </table>
    </div>
  </section>

  <footer>
    <span>MDM Workspace · docs/bauplan/index.html</span>
    <span>Erzeugt von bin/bauplan-index.py</span>
    <span>Bestandsquelle: workspace.yaml</span>
  </footer>

</div>
""" % (head, mit_satz, len(repos), gesamt_etappen, quellen, gesamt_etappen,
       args.stand or "—", sections)

    out = os.path.join(lib.docs_dir(project), "index.html")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(body)
    print("%s (%d Repos, %d Etappen, %d Quellen)"
          % (os.path.relpath(out, project), len(repos), gesamt_etappen, quellen))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except lib.ProjectError as exc:
        print("FEHLER: %s" % exc, file=sys.stderr)
        sys.exit(2)
