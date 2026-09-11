# Spec: Portabler Workspace — Name und Pfad nicht erzwingen

Stand: 11. September 2026
Quelle: Review Seniorentwickler, 11. September 2026
Status: ENTWURF

## Ziel

Der Workspace funktioniert unter jedem Verzeichnisnamen an jedem Ort im Dateisystem.
Weder `MDM` als Name noch `~/MDM` als Pfad ist eine Voraussetzung.

## Ist-Zustand

Zwei getrennte Annahmen sind im Code verdrahtet.

### Annahme 1 — der Pfad ist `$HOME/MDM`

Neun Stellen setzen denselben Rückfallwert:

| Datei | Zeile | Inhalt |
|---|---|---|
| `bin/bauplan_lib.py` | 21 | `explicit or os.environ.get("CLAUDE_PROJECT_DIR") or os.path.expanduser("~/MDM")` |
| `bin/bauplan-fonts.sh` | 16 | `PROJECT="${CLAUDE_PROJECT_DIR:-$HOME/MDM}"` |
| `.claude/hooks/bauplan-guard.sh` | 6 | dito |
| `.claude/hooks/bauplan-verify.sh` | 7 | dito |
| `.claude/hooks/bauplan-report.sh` | 8 | dito |
| `.claude/hooks/bauplan-staleness.sh` | 11 | dito |
| `.claude/hooks/post-edit-theme-check.sh` | 24 | dito |
| `.claude/hooks/post-edit-phpstan.sh` | 25 | dito |
| `.claude/hooks/post-edit-rubocop.sh` | 25 | dito |

Der Rückfallwert greift immer dann, wenn `CLAUDE_PROJECT_DIR` nicht gesetzt ist. Auf einem
Rechner ohne `~/MDM` zeigt er auf ein Verzeichnis, das nicht existiert. Die Folge ist in
`bin/bauplan_lib.py:36–39` beschrieben und dort auf einen realen Fall zurückgeführt: Der erste
CI-Lauf am 10. September 2026 endete grün, weil er keine Manifeste fand — nicht, weil alles
aktuell war. `assert_project()`
fängt diesen Fall heute ab, aber erst nachgelagert.

### Annahme 2 — das Projekt heißt `MDM`

| Datei | Zeile | Inhalt |
|---|---|---|
| `bin/bauplan-index.py` | 156 | `<title>MDM Architektur-Blattsätze</title>` |
| `bin/bauplan-index.py` | 162 | `<p class="tb-eyebrow">MDM Workspace · Übersicht</p>` |
| `setup.sh` | 2 | `# setup.sh — Interaktives Setup fuer den MDM-Workspace.` |
| `setup.sh` | 67 | `MDM Workspace Setup` |
| `sync.sh` | 62 | `~/MDM/    Workspace-Root (Harness-Repo)` |
| `README.md` | 8 | `git clone … mdm-harness.git MDM` — erzwingt den Verzeichnisnamen |
| `CLAUDE.md` | 12 | `~/MDM/    Workspace-Root (Harness-Repo)` |

`CLAUDE.md` wird von `sync.sh` erzeugt, ist also Folge von `sync.sh:62`, keine eigene Stelle.

## Soll-Zustand

### Wurzel aus der eigenen Lage bestimmen

Alle Werkzeuge liegen innerhalb des Repos (`bin/`, `.claude/hooks/`). Ihre eigene Lage
bestimmt die Wurzel eindeutig. Ein Rückfall auf einen festen Pfad entfällt damit ersatzlos.

Rangfolge:

1. `--project` (Argument, nur CLI)
2. `CLAUDE_PROJECT_DIR` (gesetzt von Claude Code und vom CI-Lauf)
3. Aufstieg vom Skriptverzeichnis bis zum ersten Verzeichnis mit `workspace.yaml`
4. Kein Treffer → Abbruch mit Meldung, **kein** stiller Rückfall

Stufe 3 ist bewusst an `workspace.yaml` gebunden und nicht an `.git`: Ein Werkzeug, das in
einem Arbeits-Repo (`connector/`) aufgerufen wird, soll den Workspace finden, nicht das
Arbeits-Repo. `git rev-parse --show-toplevel` liefert dort das Falsche.

### Name aus der Konfiguration, mit Rückfall auf den Verzeichnisnamen

`workspace.yaml` erhält einen Kopfblock:

```yaml
version: 1

workspace:
  name: "MDM Shopify"          # optional; ohne Angabe: Basename des Wurzelverzeichnisses
  short: "MDM"                 # optional; für Titel und Kopfzeilen
```

Beide Felder sind optional. Fehlen sie, gilt der Basename der Wurzel. Wer sein Verzeichnis
`~/workspace/shopify` nennt, bekommt „shopify" — ohne Konfiguration, ohne Fehler.

Die Repo-Namen bleiben unverändert. `workspace.yaml` führt weiterhin `name: "Shopify Theme"`
und das vollständige Remote mit `shopifyFrontend_MDM` — die Zugehörigkeit zum Projekt bleibt
also ablesbar. Vereinheitlicht werden nur die **Verzeichnisnamen** unterhalb der Wurzel
(`theme/`, `connector/`, …), nicht die Repo-Identität.

### Pfadangaben in der Ausgabe

Alle erzeugten Texte nennen Pfade relativ zur Wurzel. `sync.sh:62` gibt statt
`~/MDM/` künftig `<workspace>/` oder den Basename aus. Absolute Pfade erscheinen nur in
Fehlermeldungen, wenn sie zur Fehlersuche gebraucht werden.

## Anforderungen

- [ ] `bin/bauplan_lib.py`: `project_root()` implementiert die vierstufige Rangfolge; der
      Rückfall auf `~/MDM` entfällt
- [ ] Neue Hilfsfunktion `workspace_name(project)` liest `workspace.name` aus
      `workspace.yaml`, sonst `os.path.basename(project)`
- [ ] Die acht Shell-Skripte beziehen `PROJECT` aus einer gemeinsamen Quelle statt aus einer
      kopierten Zeile — Vorschlag: `.claude/hooks/_project.sh`, per `source` eingebunden
- [ ] `bin/bauplan-index.py:156,162` nutzt den ermittelten Namen
- [ ] `setup.sh:2,67` und `sync.sh:62` nutzen den ermittelten Namen
- [ ] `README.md:8` gibt kein Zielverzeichnis mehr vor
- [ ] `workspace.yaml` erhält den optionalen `workspace:`-Block, dokumentiert im Kopfkommentar

## Akzeptanzkriterien

- [ ] `grep -rn 'MDM' bin/ .claude/hooks/ setup.sh sync.sh` liefert keinen Treffer, der einen
      Pfad oder einen Namen festlegt
- [ ] Ein Klon nach `/tmp/beliebig-benannt` besteht `bin/bauplan-ci.py --report` ohne gesetzte
      Umgebungsvariable
- [ ] Derselbe Klon erzeugt mit `bin/bauplan-index.py` eine Übersicht mit dem Titel
      „beliebig-benannt Architektur-Blattsätze"
- [ ] Ohne `workspace.yaml` im Aufstiegspfad bricht jedes Werkzeug mit einer Meldung ab, die
      den geprüften Pfad nennt — Rückgabewert ungleich 0
- [ ] Der bestehende CI-Lauf bleibt grün: `CLAUDE_PROJECT_DIR` gewinnt weiterhin vor Stufe 3

## Constraints

- Blast-Radius: 9 Skripte, `workspace.yaml`, `README.md`. Die erzeugte `CLAUDE.md` ändert sich
  mit `sync.sh` automatisch.
- Kein Verhaltenswechsel für bestehende Installationen unter `~/MDM`: Stufe 3 findet dieselbe
  Wurzel, die Stufe 4 heute rät.
- `.claude/bauplan/*.manifest.json` enthält keine absoluten Pfade — geprüft. Kein Umzug nötig.
- Die Blattsätze unter `docs/bauplan/` nennen „MDM Connector" in der Eyebrow-Zeile. Das ist
  Inhalt, kein Pfad, und bleibt.

## Offene Frage

Soll Stufe 3 auch greifen, wenn `CLAUDE_PROJECT_DIR` gesetzt ist, aber dort keine
`workspace.yaml` liegt? Heute gewinnt die Variable bedingungslos. Ein Fehlwert wäre damit
weiterhin möglich — allerdings mit klarer Meldung aus `assert_project()`.

Vorschlag: Variable gewinnt, aber `assert_project()` prüft zusätzlich auf `workspace.yaml`
und nennt im Fehlerfall beide Kandidaten.
