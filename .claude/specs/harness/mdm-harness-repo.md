# Spec: mdm-harness Repository

Stand: 1. September 2026
Ticket: —
Status: ENTWURF

## Ziel

Das MDM-Workspace-Root (`~/MDM/`) wird selbst ein Git-Repo (`mdm-harness`) auf
GitHub (borekDigital). Es enthaelt die KI-Steuerungsschicht (Harness), die
Workspace-Dokumentation und ein Setup-System, mit dem Kollegen interaktiv die
Arbeits-Repos klonen koennen.

## Ist-Zustand

```
~/MDM/                     kein Git-Repo
├── .claude/               Harness (Agenten, Skills, Hooks, Rules, Specs)
├── CLAUDE.md              manuell gepflegt
├── .mcp.json              MCP-Config
├── harness-app/           Dashboard (HTML/JS/CSS + data.json)
├── Tickets/               Ticket-Artefakte
└── theme/, connector/, …  6 eigenstaendige Git-Repos
```

## Soll-Zustand

```
~/MDM/                     Git-Repo "mdm-harness" (borekDigital)
├── .claude/               versioniert (Harness)
│   ├── agents/
│   ├── skills/
│   │   ├── setup/         NEU — Skill fuer Repo-Setup
│   │   └── …
│   ├── hooks/
│   ├── rules/
│   ├── specs/
│   ├── agent-memory/      gitignored (lokal)
│   ├── settings.json      versioniert (shared)
│   └── settings.local.json  gitignored (persoenlich)
├── harness-app/           versioniert (Dashboard)
├── templates/             NEU — Bausteine fuer CLAUDE.md-Generierung
│   ├── header.md
│   ├── repo-theme.md
│   ├── repo-connector.md
│   ├── repo-datalayer.md
│   ├── repo-creditcheck.md
│   ├── repo-emailservice.md
│   ├── repo-payment-service.md
│   ├── workflows.md
│   └── footer.md
├── workspace.yaml         NEU — Manifest aller Repos (versioniert)
├── .workspace.local.yaml  NEU — lokaler Zustand (gitignored)
├── setup.sh               NEU — interaktives Setup-Script
├── sync.sh                NEU — CLAUDE.md regenerieren + Konsistenz pruefen
├── CLAUDE.md              generiert (durch sync.sh)
├── .mcp.json              versioniert
├── .gitignore             NEU
├── Tickets/               versioniert (Ticket-Artefakte)
└── theme/, connector/, …  gitignored (eigenstaendige Repos)
```

## Komponenten

### 1. workspace.yaml (Manifest)

Einzige Quelle der Wahrheit fuer alle verfuegbaren Repos. Versioniert.

Felder pro Repo:
- `id` — Kurzname (z.B. `theme`, `connector`)
- `name` — Anzeigename
- `path` — Verzeichnis relativ zum Workspace-Root
- `remote` — Git-Remote-URL
- `platform` — `github` oder `gitlab`
- `tech` — Tech-Stack (Freitext)
- `group` — Gruppierung fuer Menueanzeige (`shopify` oder `middleware`)
- `default` — `true` wenn im Setup vorausgewaehlt
- `branch` — Default-Branch beim Klonen (default: `main`)

### 2. .workspace.local.yaml (lokaler Zustand)

Gitignored. Wird von `setup.sh` und `sync.sh` geschrieben.

Felder pro installiertem Repo:
- `cloned_at` — ISO-Timestamp des ersten Klonens
- `last_sync` — ISO-Timestamp des letzten `sync.sh`-Laufs
- `branch` — aktuell ausgecheckter Branch

Guard-Semantik:
- Repo in `workspace.yaml` aber NICHT in `.workspace.local.yaml`
  = bewusst nicht geklont. Darf NIEMALS aus Konfiguration entfernt werden.
- Repo in `.workspace.local.yaml` aber Verzeichnis fehlt
  = Warnung ausgeben, User fragen ob re-klonen oder Eintrag entfernen.

### 3. setup.sh (interaktives Setup)

Ausfuehrbar als `/setup`-Skill oder direkt via `./setup.sh`.

Ablauf:
1. Pruefen ob `workspace.yaml` existiert
2. Pruefen ob `.workspace.local.yaml` existiert (Ersteinrichtung vs. Nachinstallation)
3. Repos aus `workspace.yaml` lesen, gruppiert anzeigen
4. Interaktives Menue: Checkboxen pro Repo (Defaults aus `workspace.yaml`)
   - Falls `gum` installiert: `gum choose --no-limit` fuer huebsche Checkboxen
   - Fallback: nummeriertes Bash-Menue mit Toggle
5. Ausgewaehlte Repos klonen (`git clone <remote> <path>`)
6. `.workspace.local.yaml` schreiben/aktualisieren
7. `sync.sh` aufrufen (CLAUDE.md regenerieren)
8. Pro Repo: `.env.template` nach `.env` kopieren falls vorhanden
9. Zusammenfassung anzeigen

Wiederholbar: `./setup.sh` erkennt bereits geklonte Repos und bietet nur
fehlende an. Option `--add` fuer Nachinstallation, `--reset` fuer Neuanfang.

### 4. sync.sh (Harness-Synchronisation)

Regeneriert `CLAUDE.md` aus Templates und prueft Konsistenz.

Ablauf:
1. `workspace.yaml` lesen (alle bekannten Repos)
2. `.workspace.local.yaml` lesen (installierte Repos)
3. Fuer jedes Repo in `workspace.yaml`:
   - Template `templates/repo-<id>.md` lesen
   - Wenn lokal installiert: Section normal einbauen
   - Wenn NICHT installiert: Section mit Hinweis
     `(nicht lokal installiert — ./setup.sh --add)` einbauen
4. Templates assemblieren: header + repo-sections + workflows + footer
5. `CLAUDE.md` schreiben
6. `harness-app/data.json` aktualisieren (Repo-Status)
7. Konsistenz pruefen (Agenten, Skills, Hooks vs. README + data.json)
8. Staleness-Warnung: Repos mit `last_sync` aelter als 7 Tage

Idempotent: mehrfaches Ausfuehren liefert gleiches Ergebnis.

### 5. CLAUDE.md-Generierung (Hybrid)

Struktur:
- `templates/header.md` — Zweck, Workspace-Struktur, Git-Zugang (statisch)
- `templates/repo-<id>.md` — Pro Repo: Tech-Stack, Befehle, Secrets (statisch)
- `templates/workflows.md` — Workflows, Spec-Driven, TDD, Git Worktree (statisch)
- `templates/footer.md` — Sprache, Commits, Analyse-Qualitaet (statisch)

Die Repo-Sections sind statische Markdown-Dateien (keine Templating-Engine noetig).
`sync.sh` konkateniert sie per `cat` in der richtigen Reihenfolge.
Einzige dynamische Elemente:
- Workspace-Struktur-Baum (generiert aus workspace.yaml + .workspace.local.yaml)
- Repo-Tabelle unter "Repos und Git" (generiert aus workspace.yaml)
- Hinweis "(nicht lokal installiert)" bei fehlenden Repos

### 6. Guard-Mechanismus (drei Schichten)

#### Schicht 1: Manifest-Guard (statisch)
`workspace.yaml` definiert alle bekannten Repos. Diese Liste ist die Referenz.
Kein automatischer Prozess darf Repos aus `CLAUDE.md`, `data.json` oder
`settings.json` entfernen, die in `workspace.yaml` stehen.

#### Schicht 2: Local-State-Guard (Setup/Sync)
`.workspace.local.yaml` dokumentiert explizit welche Repos geklont wurden.
"Nicht in local = nicht gewollt" (nicht "verschwunden").
`sync.sh` nutzt diese Unterscheidung beim Generieren von CLAUDE.md.

#### Schicht 3: Git-Hook-Guard (automatisch)
Git-Hook `post-merge` auf dem Harness-Repo fuehrt `sync.sh` aus.
So wird nach jedem `git pull` die CLAUDE.md regeneriert und neue
Agenten/Skills/Hooks automatisch aktiviert.

Zusaetzlich: der bestehende Claude-Hook `Stop` (post-implement-harness-sync.sh)
wird erweitert um workspace.yaml-Konsistenz zu pruefen.

### 7. /setup Skill

Claude-Code-Skill unter `.claude/skills/setup/SKILL.md`.

Beschreibung: "Interaktives Setup fuer den MDM-Workspace. Klont ausgewaehlte
Repos und richtet die lokale Umgebung ein."

Der Skill ruft `setup.sh` auf und fuehrt den User durch den Prozess.

### 8. .gitignore

```
# Eigenstaendige Repos (via setup.sh geklont)
theme/
connector/
datalayer/
creditcheck/
emailservice/
payment-service/
connector-worktrees/

# Lokaler Zustand
.workspace.local.yaml
.claude/settings.local.json
.claude/agent-memory/

# OS
.DS_Store
```

## Akzeptanzkriterien

### Setup
- [ ] `git clone <mdm-harness-remote> MDM && cd MDM && ./setup.sh` klappt
- [ ] Menue zeigt alle 6 Repos gruppiert (Shopify / Middleware)
- [ ] Defaults (theme, connector) sind vorausgewaehlt
- [ ] Nur ausgewaehlte Repos werden geklont
- [ ] `.workspace.local.yaml` wird korrekt geschrieben
- [ ] `CLAUDE.md` wird nach Setup automatisch generiert
- [ ] Wiederholtes `./setup.sh` erkennt bereits geklonte Repos

### Guard
- [ ] Nicht geklonte Repos stehen trotzdem in CLAUDE.md (mit Hinweis)
- [ ] `sync.sh` entfernt NIEMALS Repo-Sections aus CLAUDE.md
- [ ] Repo in `.workspace.local.yaml` aber Verzeichnis fehlt: Warnung
- [ ] Neues Repo in `workspace.yaml` nach Pull: wird beim naechsten Sync eingebaut

### Sync
- [ ] `sync.sh` ist idempotent (mehrfach ausfuehren = gleiches Ergebnis)
- [ ] `post-merge` Hook fuehrt `sync.sh` automatisch aus
- [ ] `data.json` wird aktualisiert
- [ ] Staleness-Warnung bei Repos aelter als 7 Tage

### Harness-Versionierung
- [ ] `.claude/agents/`, `skills/`, `hooks/`, `rules/` sind versioniert
- [ ] `.claude/agent-memory/` ist gitignored
- [ ] `.claude/settings.local.json` ist gitignored
- [ ] `settings.json` (shared) ist versioniert
- [ ] Keine Secrets in versionierten Dateien

## Abgrenzung

- Die 6 Arbeits-Repos behalten ihre eigenen Git-Historien und Remotes.
  Sie werden NICHT als Submodules eingebunden.
- Der Harness-Repo-Commit-Verlauf ist unabhaengig von den Arbeits-Repos.
- Apple-Notes-Integration bleibt user-scoped und ist nicht Teil des Repos.
- `~/.claude/CLAUDE.md` (globale User-Regeln) ist nicht Teil des Repos.

## Entscheidungen

- [x] `Tickets/` ist versioniert (Teil des Harness-Repos)
- [x] Branch-Workflow: nur `main` (kein staging/feat)
- [x] README enthaelt Hinweis: GitLab-Zugang (gitlab.mdm.de) noetig fuer
      Middleware-Repos (creditcheck, emailservice, payment-service).
      Keine ausfuehrliche SSH-Doku.
