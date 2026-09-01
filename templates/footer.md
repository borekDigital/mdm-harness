## Sprache und Commits

- Dokumentation und Artefakte: Deutsch, Datumsformat 21. August 2026.
- Commit-Messages: Englisch, Conventional Commits, 50/72, imperativ, kleingeschrieben.
  Scope nie eine Ticket-ID. Konrad committet selbst — Claude liefert die Message.
- Keine KI-Hinweise in Commits, Doku oder Code-Kommentaren.

## Test-Driven Development (TDD)

TDD ist Pflicht fuer alle Code-Aenderungen in diesem Workspace. Reihenfolge:

1. **Red** — Test schreiben, der das gewuenschte Verhalten beschreibt. Test muss fehlschlagen.
2. **Green** — Minimalen Code schreiben, damit der Test besteht.
3. **Refactor** — Code aufraeumen, Tests muessen weiterhin bestehen.

### Connector (Rails)

- Framework: RSpec (wird beim ersten Feature eingerichtet, falls noch nicht vorhanden)
- Tests unter `connector/spec/`
- Factories mit FactoryBot, Fakes mit WebMock/VCR fuer externe APIs (SAP, Shopify, OpenIBAN)
- `bundle exec rspec` — Test-Suite ausfuehren
- Vor jedem Commit muessen alle Tests gruen sein

### Theme (Liquid)

- Kein Unit-Test-Framework (Shopify-Liquid hat keins). Stattdessen:
  - `shopify theme check` als statische Analyse
  - Manueller Smoke-Test via `shopify theme dev`

### Middleware (PHP/Symfony)

- Framework: PHPUnit (in allen drei Repos vorhanden)
- Tests unter `<repo>/www/tests/`
- `docker compose exec app bin/phpunit` — Test-Suite ausfuehren
- Statische Analyse: PHPStan (emailservice, payment-service), PHPCS (emailservice)
- Vor jedem Commit muessen alle Tests gruen sein

### Regeln

- Kein Feature-Code ohne vorherigen Test.
- Bei Bugfixes: erst Regression-Test, dann Fix.
- Test-Dateien gehoeren zum gleichen Commit wie der Feature-Code.
- CI-Mindestanforderung Connector: `bundle exec rspec` + `bundle exec rubocop` + `bundle exec brakeman`.
- CI-Mindestanforderung Middleware: `bin/phpunit` (+ `phpstan` / `phpcs` wo vorhanden).

## Git Worktree

Fuer parallele Feature-Arbeit nutzen wir `git worktree`. Jedes Feature bekommt
einen eigenen Worktree, sodass mehrere Branches gleichzeitig ausgecheckt sein koennen.

### Konvention

```
connector/                    Haupt-Worktree (main)
connector-worktrees/          Worktree-Verzeichnis (gitignored)
├── <branch-name>/            Ein Worktree pro Feature-Branch
```

### Befehle

- `cd connector && git worktree add ../connector-worktrees/<branch> -b <branch>` — Neuer Worktree
- `cd connector && git worktree list` — Alle Worktrees anzeigen
- `cd connector && git worktree remove ../connector-worktrees/<branch>` — Worktree entfernen

### Regeln

- Worktrees leben unter `connector-worktrees/` (Workspace-Root-Ebene), nicht innerhalb von `connector/`.
- Nach Merge: Worktree entfernen und Branch loeschen.
- Haupt-Worktree (`connector/`) bleibt immer auf `main`.
- Jeder Worktree hat seine eigene `.env` (aus `.env.template` kopieren).

## Analyse-Qualitaet

1. Alle betroffenen Dateien lesen, bevor Empfehlungen gegeben werden
2. Aussagen kategorisieren: Belegt / Vermutung / Unbekannt
3. Korrekturen offen kommunizieren
