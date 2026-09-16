# Spec: Repo-Pfad eines Blattsatzes an einer Stelle aufloesen

Stand: 16. September 2026
Quelle: Nebenbefund beim `themes/`-Umbau und beim Wording-Review, 16. September 2026
Status: UMGESETZT (16. September 2026) — siehe „Umsetzung“ am Ende

## Ziel

Der Pfad, unter dem ein Blattsatz sein Repo findet, wird an **einer** Stelle bestimmt.
Heute bestimmt ihn jeder Aufrufer selbst, und zwei von drei tun es falsch.

## Ist-Zustand

`bauplan_lib.py` traegt die Regel bereits — aber nur halb. `manifest_root(manifest, repo)`
liefert die Wurzel (`root` aus dem Manifest, sonst der Repo-Name). Den Schritt von der
Wurzel zum absoluten Pfad macht jeder Aufrufer selbst:

| Stelle | Aufloesung | Bewertung |
|---|---|---|
| `bin/bauplan-ci.py:44–45` | `project if root == "." else os.path.join(project, root)` | ✅ belegt korrekt |
| `bin/bauplan-ci.py:165–166` | prueft `root == "."`, joint dann aber `repo` statt `root` | ❌ falsch |
| `bin/bauplan-stale.py:62` | `os.path.join(project, args.repo)` — `root` ignoriert | ❌ war falsch, am 16.09.2026 behoben |
| `.github/workflows/bauplan-refresh.yml:130` | klont nach `name` (Manifest-Schluessel) | ❌ ignoriert `path` aus `workspace.yaml` |

`bauplan_lib.py` beschreibt sich im Kopfkommentar als „Eine Regel, drei Aufrufer". Fuer die
Zuordnung von Dateien zu Etappen stimmt das. Fuer den Repo-Pfad stimmt es nicht.

### Wirkung heute

Kein aktiver Defekt. Die drei Manifeste sind so gebaut, dass die falsche Aufloesung
zufaellig dasselbe Ergebnis liefert:

| Manifest | Schluessel | `root` | Verzeichnis |
|---|---|---|---|
| `connector` | `connector` | fehlt → Schluessel | `connector/` |
| `emailservice` | `emailservice` | fehlt → Schluessel | `emailservice/` |
| `harness` | `harness` | `.` | Workspace selbst |

Schluessel und Verzeichnis sind identisch, also faellt der Unterschied nicht auf.

### Wann es bricht

Sobald ein Blattsatz fuer ein Theme entsteht. `workspace.yaml` fuehrt seit dem
16. September 2026 `theme-mdm` mit `path: "themes/mdm/"` — Schluessel und Verzeichnis
sind dort **nicht** mehr gleich. Ein Manifest `theme-mdm.manifest.json` mit
`root: "themes/mdm"` haette zur Folge:

- `bauplan-ci.py:165` sucht `~/MDM/theme-mdm` → kein `last_seen_sha`, die Auffrischung
  laeuft im Kreis (genau der Fall, gegen den der Kommentar an dieser Stelle warnt)
- Die CI klont nach `theme-mdm/`, waehrend jede andere Stelle `themes/mdm/` erwartet →
  „nicht klonbar" oder ein Klon, den niemand liest

Dass `bauplan-stale.py` denselben Fehler hatte, ist der Beleg, dass die Stelle ohne
gemeinsamen Helfer wiederholt falsch gebaut wird: dort meldete der Lauf fuer `harness`
`{"error": "nicht geklont"}`, obwohl das Repo der Workspace selbst ist.

### Zweiter, kleinerer Befund

`.github/workflows/bauplan-refresh.yml:90` meldet
`GH_REPO_TOKEN fehlt — theme, connector, datalayer werden uebersprungen`.
Den Repo-Schluessel `theme` gibt es seit dem 16. September 2026 nicht mehr; ausserdem
nennt die Zeile mit `datalayer` ein Repo, das gar kein Manifest hat und deshalb nie
geklont wird. Reiner Meldungstext, keine Wirkung auf den Lauf.

## Soll-Zustand

### A. Ein Helfer in `bauplan_lib.py`

```python
def repo_path(manifest, repo, project=None):
    """Absoluter Pfad des Repos, das ein Blattsatz beschreibt.

    `root: "."` heisst: der Workspace selbst ist der Gegenstand — so
    dokumentiert sich die Harness. Jeder andere Wert ist workspace-relativ.
    """
    wurzel = manifest_root(manifest, repo)
    basis = project_root(project)
    return basis if wurzel in (".", "") else os.path.join(basis, wurzel)
```

Alle Aufrufer nutzen ihn. `manifest_root` bleibt bestehen — es beantwortet die andere
Frage (worauf beziehen sich die `sources`).

### B. Aufrufer umstellen

- `bin/bauplan-ci.py:44–45` → `lib.repo_path(manifest, repo, project)`
- `bin/bauplan-ci.py:165–166` → derselbe Aufruf; behebt den Fehler
- `bin/bauplan-stale.py:62` → derselbe Aufruf; ersetzt die Einzelfall-Korrektur
  vom 16. September 2026 durch die gemeinsame Regel

### C. Die CI klont nach `path` aus `workspace.yaml`

Der Klon-Schritt liest `remote` und `branch` bereits aus `workspace.yaml`. Er liest
zusaetzlich `path` und klont dorthin, statt nach dem Manifest-Schluessel:

```python
m = re.match(r'^    (remote|branch|path):\s*"?([^"\n]*)"?\s*$', line)
...
ziel = (cfg.get("path") or name).rstrip("/")
os.makedirs(os.path.dirname(ziel) or ".", exist_ok=True)
rc = subprocess.run(args + [cfg["remote"], ziel]).returncode
```

Verschachtelte Ziele (`themes/mdm/`) brauchen das Elternverzeichnis — `git clone` legt es
an, `os.makedirs` ist die Absicherung fuer den Fall, dass ein Ziel tiefer liegt.

### D. Meldungstext

Zeile 90 nennt keine Repo-Namen mehr, sondern die Bedingung:
`GH_REPO_TOKEN fehlt — GitHub-Repos werden uebersprungen`.

## Anforderungen

- [x] `bauplan_lib.repo_path()` angelegt, mit Docstring zur `"."`-Semantik
- [x] `bauplan-ci.py` an beiden Stellen umgestellt
- [x] `bauplan-stale.py` auf den Helfer umgestellt
- [x] CI klont nach `path` aus `workspace.yaml`, Elternverzeichnis abgesichert
- [x] CI-Meldungstext ohne veraltete Repo-Namen
- [x] Kein Aufrufer baut den Repo-Pfad noch selbst

## Akzeptanzkriterien

- [x] `grep -n "os.path.join(project, repo)" bin/*.py` liefert keinen Treffer
- [x] `python3 bin/bauplan-stale.py --repo harness --since <sha>` liefert einen Befund
      statt `{"error": "nicht geklont"}`
- [x] Ein Testmanifest mit `root: "themes/mdm"` wird von `bauplan-ci.py` und
      `bauplan-stale.py` unter `themes/mdm/` gefunden — nachweisbar ohne echtes Manifest,
      ueber einen direkten Aufruf von `repo_path()`
- [x] `python3 bin/bauplan-ci.py --report` laeuft unveraendert durch (Exit 0 oder 3)
- [x] `grep -n "theme, connector, datalayer" .github/workflows/` liefert keinen Treffer

## Constraints

- **Eigener Commit.** Diese Aenderung gehoert nicht in die Wording-Commits aus
  `bauplan-wording-rueckbau.md`. Sie beruehrt andere Dateien und hat eine andere
  Begruendung.
- **Kein Verhaltenswechsel im Bestand.** Fuer die drei vorhandenen Manifeste liefert der
  Helfer dasselbe Ergebnis wie heute. Der Fix ist Vorsorge, kein Reparieren eines
  laufenden Schadens — das gehoert so in die Commit-Message.
- Die CI laesst sich lokal nicht vollstaendig pruefen. Die Klon-Aenderung wird gegen
  `workspace.yaml` trocken geprueft (Zielpfad berechnen und ausgeben), nicht durch einen
  echten Lauf.


## Umsetzung

Durchgefuehrt am 16. September 2026, eigener Commit.

| Datei | Aenderung |
|---|---|
| `bin/bauplan_lib.py` | `repo_path(manifest, repo, project)` ergaenzt |
| `bin/bauplan-ci.py` | zwei Aufrufer umgestellt, davon einer fehlerhaft |
| `bin/bauplan-stale.py` | Einzelfall-Korrektur durch den gemeinsamen Helfer ersetzt |
| `.github/workflows/bauplan-refresh.yml` | klont nach `path`, Elternverzeichnis abgesichert, Meldungstext bereinigt |

### Nachweis

```
repo_path({}, "connector")               -> <ws>/connector
repo_path({"root": "."}, "harness")      -> <ws>
repo_path({"root": "themes/mdm"}, …)     -> <ws>/themes/mdm   (existiert, ist Git-Repo)
bauplan-stale.py --repo harness          -> Befund mit 47 Dateien statt "nicht geklont"
bauplan-ci.py --report                   -> Exit 3 (veraltete Etappen gemeldet)
bauplan-guard.py --verify                -> Exit 0
grep "os.path.join(project, repo)" bin/  -> kein Treffer
grep "theme, connector, datalayer" .github/ -> kein Treffer
```

### Nicht geprueft

Der CI-Lauf selbst. Die Klon-Aenderung ist gegen `workspace.yaml` trocken geprueft
(Zielpfad berechnen), nicht durch einen echten Lauf auf einem Runner. Der naechste
geplante Lauf zeigt es.
