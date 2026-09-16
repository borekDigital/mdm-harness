"""Gemeinsame Zuordnungslogik fuer Bauplaene.

Eine Regel, drei Aufrufer: der PostToolUse-Hook (lokale Claude-Session), die CI
(Push ohne Claude) und der Guard. Wuerde jeder seine eigene Zuordnung mitbringen,
koennte lokal etwas als aktuell gelten, was in CI als veraltet erscheint.

Quelle der Zuordnung: .claude/bauplan/<repo>.manifest.json, Feld "sources".
Dort stehen repo-relative Pfade oder Globs; jede Etappe belegt ihre Aussagen mit
diesen Dateien. Aendert sich eine davon, ist die Etappe fraglich.
"""

import fnmatch
import json
import os

MANIFEST_SUFFIX = ".manifest.json"


def project_root(explicit=None):
    """Workspace-Wurzel. CLAUDE_PROJECT_DIR gewinnt, sonst ~/MDM."""
    return explicit or os.environ.get("CLAUDE_PROJECT_DIR") or os.path.expanduser("~/MDM")


def manifest_dir(project=None):
    return os.path.join(project_root(project), ".claude", "bauplan")


class ProjectError(RuntimeError):
    """Der Workspace wurde falsch aufgeloest."""


def assert_project(project=None):
    """Prueft, dass der Workspace Manifeste enthaelt.

    Ohne diese Pruefung liest sich ein falsch aufgeloester Pfad als
    "keine Etappen, nichts zu tun" — in CI ein gruener Lauf ohne Wirkung.
    Genau so ist der erste Lauf am 10. September 2026 durchgelaufen, weil
    CLAUDE_PROJECT_DIR dort nicht gesetzt war und der Standard ~/MDM auf dem
    Runner nicht existiert.
    """
    base = manifest_dir(project)
    if not os.path.isdir(base):
        raise ProjectError(
            "Kein Manifest-Verzeichnis unter %s.\n"
            "CLAUDE_PROJECT_DIR loest auf %s auf. In CI auf den Checkout-Pfad setzen."
            % (base, project_root(project)))
    if not any(f.endswith(MANIFEST_SUFFIX) for f in os.listdir(base)):
        raise ProjectError("Keine Manifeste in %s." % base)


def docs_dir(project=None):
    return os.path.join(project_root(project), "docs", "bauplan")


def sheet_path(repo, nr, project=None):
    """Pfad der HTML-Quelle einer Etappe. Die Quelle liegt im Repo, nicht im
    Scratchpad — daher Historie, PDF-Export und CI-Zugriff."""
    return os.path.join(docs_dir(project), repo, "etappe-%02d.html" % int(nr))


def iter_manifests(project=None):
    """(repo, pfad, manifest) je Manifest. Defekte Manifeste werden uebersprungen,
    nicht verschluckt — der Aufrufer sieht sie im Rueckgabewert nicht, der Guard
    prueft sie separat."""
    base = manifest_dir(project)
    if not os.path.isdir(base):
        return
    for entry in sorted(os.listdir(base)):
        if not entry.endswith(MANIFEST_SUFFIX):
            continue
        repo = entry[: -len(MANIFEST_SUFFIX)]
        path = os.path.join(base, entry)
        try:
            with open(path, encoding="utf-8") as fh:
                yield repo, path, json.load(fh)
        except (OSError, ValueError):
            continue


def load_manifest(repo, project=None):
    path = os.path.join(manifest_dir(project), repo + MANIFEST_SUFFIX)
    if not os.path.isfile(path):
        return None
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def save_manifest(repo, manifest, project=None):
    path = os.path.join(manifest_dir(project), repo + MANIFEST_SUFFIX)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    os.replace(tmp, path)


def path_matches(pattern, rel):
    """Traegt `pattern` die Datei `rel`? Beide repo-relativ, Trenner '/'.

    Drei Formen, absteigend spezifisch:
      exakt          config/messenger.yaml
      Verzeichnis    src/Queueing/**      deckt alles darunter ab
      Glob           extensions/*/package.json
    """
    if rel == pattern:
        return True
    if pattern.endswith("/**"):
        prefix = pattern[:-3] + "/"
        if rel.startswith(prefix):
            return True
    return fnmatch.fnmatch(rel, pattern)


def affected_etappen(manifest, rel_paths):
    """Etappen, die von mindestens einer der Dateien belegt werden.

    Rueckgabe in Manifest-Reihenfolge, je Etappe die ausloesenden Dateien.
    Reihenfolge ist stabil, damit Ledger und CI-Ausgabe vergleichbar bleiben.
    """
    hits = []
    for etappe in manifest.get("etappen", []):
        patterns = etappe.get("sources", [])
        triggers = sorted(
            {rel for rel in rel_paths for p in patterns if path_matches(p, rel)}
        )
        if triggers:
            hits.append((etappe, triggers))
    return hits


def manifest_root(manifest, repo):
    """Wurzel, auf die sich die `sources` eines Blattsatzes beziehen.

    Normalfall: das gleichnamige Unterverzeichnis des Workspace. Der Wert `"."`
    heisst: der Workspace selbst ist der Gegenstand — so dokumentiert sich die
    Harness. Ohne diese Unterscheidung waere ihr Blattsatz nicht pflegbar, weil
    ihre Dateien in keinem Repo-Unterverzeichnis liegen.
    """
    return (manifest or {}).get("root", repo)


def repo_path(manifest, repo, project=None):
    """Absoluter Pfad des Repos, das ein Blattsatz beschreibt.

    `root: "."` heisst: der Workspace selbst ist der Gegenstand — so
    dokumentiert sich die Harness. Jeder andere Wert ist workspace-relativ.

    Diese Umrechnung gehoert hierher und nicht zu den Aufrufern. Solange jeder
    Aufrufer sie selbst baute, war sie an zwei von vier Stellen falsch: sie
    verband den Manifest-**Schluessel** mit dem Workspace statt die Wurzel.
    Bei den vorhandenen Manifesten faellt das nicht auf, weil Schluessel und
    Verzeichnis gleich heissen. Sobald beides auseinanderfaellt — `theme-mdm`
    liegt unter `themes/mdm/` — sucht der Lauf am falschen Ort und meldet
    "nicht geklont".
    """
    wurzel = manifest_root(manifest, repo)
    basis = project_root(project)
    return basis if wurzel in (".", "") else os.path.join(basis, wurzel)


def split_repo_path(changed_abs, repo):
    """Absoluten Pfad in repo-relativ umrechnen, sofern er in diesem Repo liegt.

    Der Workspace haelt die Repos als Unterverzeichnisse (~/MDM/emailservice/...),
    daher genuegt das Verzeichnis-Segment als Marker.
    """
    marker = "/%s/" % repo
    if marker not in changed_abs:
        return None
    return changed_abs.split(marker, 1)[1]


def relative_for(project, manifest, repo, changed_abs):
    """Geaenderte Datei in die Bezugsgroesse des Blattsatzes umrechnen."""
    root = manifest_root(manifest, repo)
    if root != ".":
        return split_repo_path(changed_abs, root)
    proj = os.path.abspath(project)
    path = os.path.abspath(changed_abs)
    if path == proj or not path.startswith(proj + os.sep):
        return None
    return os.path.relpath(path, proj)


IGNORED_SEGMENTS = ("/.claude/", "/Tickets/", "/.git/", "/node_modules/",
                    "/vendor/", "/docs/bauplan/", "/.claude/bauplan/")


def is_ignored(path, root=None):
    """Tickets, Fremdcode, Scratch und die Doku selbst belegen keine Aussage.

    Fuer den Workspace-Blattsatz (`root == "."`) ist `.claude` der Gegenstand
    und darf nicht ausgeschlossen werden.
    """
    if path.startswith("/tmp/") or path.startswith("/private/tmp/"):
        return True
    segmente = IGNORED_SEGMENTS
    if root == ".":
        segmente = tuple(s for s in segmente if s != "/.claude/")
    return any(seg in path for seg in segmente)
