# mdm-harness

KI-gesteuerte Workspace-Orchestrierung fuer die MDM Shopify-Infrastruktur. Dieses Repository enthaelt die Claude Code Harness (Agenten, Skills, Hooks, Rules), ein interaktives Setup-System und ein lokales Dashboard — aber **keinen** Anwendungscode. Die 6 Arbeits-Repos werden per `setup.sh` geklont und bleiben eigenstaendige Git-Repositories.

## Schnellstart

```bash
git clone git@github.com-borek:borekDigital/mdm-harness.git MDM
cd MDM
./setup.sh
```

`setup.sh` zeigt ein interaktives Menue, klont die ausgewaehlten Repos und generiert automatisch die `CLAUDE.md`.

## Voraussetzungen

- **Git** mit SSH-Zugang zu GitHub (borekDigital)
- **GitLab-Zugang** (gitlab.mdm.de) fuer Middleware-Repos (creditcheck, emailservice, payment-service)
- **Claude Code** CLI installiert
- Optional: [gum](https://github.com/charmbracelet/gum) fuer huebschere Menues

## Repos

Das Manifest `workspace.yaml` definiert alle verfuegbaren Repos:

| Repo | Tech-Stack | Plattform | Gruppe |
|------|-----------|-----------|--------|
| **theme** | Liquid/CSS/JS (Hyper 1.3.3) | GitHub | Shopify |
| **connector** | Rails 8.1 / React 18 / Polaris | GitHub | Shopify |
| **datalayer** | JavaScript | GitHub | Shopify |
| **creditcheck** | PHP 7.4 / Symfony | GitLab | Middleware |
| **emailservice** | PHP 8.3 / Symfony 7.1 | GitLab | Middleware |
| **payment-service** | PHP 8.3 / Symfony 7.1 / Nuxt | GitLab | Middleware |

Repos werden **nicht** als Submodules eingebunden — jedes behaelt seine eigene Git-Historie.

## Verzeichnisstruktur

```
MDM/
├── .claude/                  Harness (versioniert)
│   ├── agents/               12 spezialisierte Agenten
│   ├── skills/               7 Skills (setup, figma-to-liquid, mdm-block, ...)
│   ├── hooks/                Automatische Checks (RuboCop, Theme Check, PHPStan, ...)
│   ├── rules/                Pfad-scoped Konventionen (Liquid, Rails, Middleware, ...)
│   ├── specs/                Spezifikationen
│   ├── settings.json         Shared Settings (versioniert)
│   ├── settings.local.json   Persoenliche Settings (gitignored)
│   └── agent-memory/         Lokales Agent-Gedaechtnis (gitignored)
├── harness-app/              Dashboard (HTML/JS/CSS)
├── templates/                Bausteine fuer CLAUDE.md-Generierung
├── Tickets/                  Ticket-Artefakte
├── workspace.yaml            Repo-Manifest (Single Source of Truth)
├── .workspace.local.yaml     Lokaler Klon-Status (gitignored)
├── setup.sh                  Interaktives Setup-Script
├── sync.sh                   CLAUDE.md regenerieren + Konsistenz pruefen
├── CLAUDE.md                 Generiert (nicht manuell editieren)
└── theme/, connector/, ...   Geklonte Arbeits-Repos (gitignored)
```

## Agenten

Die Harness stellt 12 spezialisierte Claude Code Agenten bereit, aufgeteilt nach Scope:

**Theme (Shopify/Liquid):** theme-planner, liquid-implementer, theme-reviewer, figma-extractor

**Connector (Rails):** rails-planner, rails-implementer, rails-reviewer

**Middleware (Symfony/PHP):** symfony-planner, symfony-implementer, symfony-reviewer

**Uebergreifend:** security-reviewer, docs-writer

### Pipeline

```
Planner → Implementer → [Reviewer ∥ Security-Reviewer] → Docs-Writer
```

Review und Security laufen immer parallel nach jeder Implementierung.

## Skills

| Skill | Beschreibung |
|-------|-------------|
| `/setup` | Interaktives Repo-Setup |
| `/figma-to-liquid` | Figma-Design in Liquid-Sections umwandeln |
| `/mdm-block` | MDM-Block-Pattern (Section + Schema) erstellen |
| `/mdm-template` | Neues Liquid-Template mit MDM-Konventionen |
| `/mdm-notes` | Apple-Notes-Integration |
| `/connector-feature` | Rails-Feature im Connector planen + umsetzen |
| `/middleware-feature` | Symfony-Feature in Middleware-Repos planen + umsetzen |

## Hooks

| Hook | Event | Funktion |
|------|-------|----------|
| git-safety | PreToolUse | Schuetzt vor destructiven Git-Operationen |
| protect-merchant-files | PreToolUse | Blockiert Edits an settings_data.json u.a. |
| post-edit-theme-check | PostToolUse | Theme Check nach Liquid-Aenderungen |
| post-edit-rubocop | PostToolUse | RuboCop nach Ruby-Aenderungen |
| post-edit-phpstan | PostToolUse | PHPStan nach PHP-Aenderungen |
| post-implement-harness-sync | Stop | Harness-Konsistenz nach Session pruefen |
| stop-notify | Stop | macOS-Benachrichtigung bei Session-Ende |

## Setup-Befehle

```bash
# Ersteinrichtung
./setup.sh

# Weitere Repos nachinstallieren
./setup.sh --add

# Neuanfang (loescht .workspace.local.yaml)
./setup.sh --reset

# CLAUDE.md manuell regenerieren
./sync.sh
```

## Dashboard

Das Dashboard zeigt Agenten, Workflows, Skills, Architektur und Rules auf einen Blick:

```bash
cd harness-app && python3 -m http.server 8042
# → http://localhost:8042
```

## Guard-Mechanismus

Drei Schichten verhindern, dass Repos oder Konfiguration versehentlich verloren gehen:

1. **Manifest-Guard** — `workspace.yaml` ist die Referenz. Kein Prozess darf Repos daraus entfernen.
2. **Local-State-Guard** — `.workspace.local.yaml` dokumentiert explizit geklonte Repos. "Nicht vorhanden" = bewusst uebersprungen.
3. **Git-Hook-Guard** — `post-merge` fuehrt `sync.sh` aus, sodass nach jedem `git pull` die CLAUDE.md aktuell bleibt.

## Technologien

- **Claude Code** — KI-Agenten-Framework (Agenten, Skills, Hooks, Rules, MCP)
- **Bash** — Setup- und Sync-Scripts
- **YAML** — Workspace-Manifest (`workspace.yaml`)
- **HTML/CSS/JS** — Dashboard (Vanilla, kein Build-Step)
- **Git** — Versionierung der Harness, eigenstaendige Repos per `.gitignore` ausgeschlossen
