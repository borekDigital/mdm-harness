# MDM Workspace

## Zweck

Zentraler Workspace fuer das MDM-Oekosystem: Shopify (Theme, Backend-Connector, Datalayer)
und Middleware-Services (Creditcheck, Emailservice, Payment-Service).
Sechs eigenstaendige Git-Repos, eine gemeinsame KI-Steuerungsschicht (Harness).

## Workspace-Struktur

```
~/MDM/                        Workspace-Root (Harness-Repo)
├── theme/                    Shopify Theme
├── connector/                Shopify Connector
├── datalayer/                GTM Datalayer
├── creditcheck/              Creditcheck + CustomerInfo
├── emailservice/             Emailservice
├── payment-service/          Payment-Service
├── Tickets/                  Ticket-Artefakte (planuebergreifend)
├── .claude/                  Harness: Agenten, Skills, Hooks, Rules
├── .mcp.json                 MCP-Server
└── CLAUDE.md                 diese Datei (generiert durch sync.sh)
```

Alle Theme-Pfade relativ zum Workspace-Root tragen das Praefix `theme/`
(z. B. `theme/sections/`, `theme/locales/`). Connector-Pfade analog `connector/`.
Middleware-Pfade analog `creditcheck/`, `emailservice/`, `payment-service/`.

## Repos und Git

Sechs unabhaengige Git-Repos auf zwei Plattformen:

**Shopify-Repos** — GitHub via SSH-Alias `github.com-borek`
(Key `~/.ssh/id_ed25519_borek`, GitHub-Account `Konrad-Thiemann`, Org `borekDigital`):

| Repo | Pfad | Remote |
|---|---|---|
| Shopify Theme | `theme/` | `git@github.com-borek:borekDigital/shopifyFrontend_MDM.git` |
| Shopify Connector | `connector/` | `git@github.com-borek:borekDigital/shopifyConnector.git` |
| GTM Datalayer | `datalayer/` | `git@github.com-borek:borekDigital/shopifyDatalayer.git` |

**Middleware-Repos** — GitLab (gitlab.mdm.de).
Zugang zu gitlab.mdm.de erforderlich fuer diese Repos.

| Repo | Pfad | Remote |
|---|---|---|
| Creditcheck + CustomerInfo | `creditcheck/` | `git@gitlab.mdm.de:middleware/creditcheck.git` |
| Emailservice | `emailservice/` | `git@gitlab.mdm.de:middleware/emailservice.git` |
| Payment-Service | `payment-service/` | `git@gitlab.mdm.de:middleware/payment-service.git` |

## Theme (theme/)

Shopify-Theme des MDM-Muenzshops (Store-Handle `mdm-muenze`). Basis: kommerzielles
Theme Hyper v1.3.3 von FoxEcom (Online Store 2.0, Doku: docs.foxecom.com/hyper-theme).

### Befehle (ausfuehren in `theme/`)

- `shopify theme check --fail-level error` — Linter (Baseline: 9 Errors + 20 Warnings in Altlasten)
- `shopify theme dev --store mdm-muenze` — Dev-Server mit Hot-Reload
- `shopify theme pull --store mdm-muenze --theme <id>` — Stand vom Store holen
- `shopify theme push --unpublished --store mdm-muenze` — Upload als unveroeffent. Theme
- Kein `--theme-editor-sync` (CLI-Bug, community.shopify.dev/t/28292 — Hook blockiert)

### Namensraum

- FoxEcom-Kerndateien NIEMALS direkt bearbeiten. Jede Section, die in einem
  MDM-Template referenziert wird, MUSS als `mdm-`-Kopie existieren (update-sicher).
- Templates: `product.mdm.json`, `collection.mdm.json`; Landingpages `page.<slug>.json`.
- Locales: `en.default.json` (Default) + `de.json` (Shop-Sprache) — paarig pflegen.
- Bereichs-Details: `.claude/rules/`

## Connector (connector/)

Rails 8.1 + React 18/Polaris Backend. Bidirektionaler Shopify↔SAP-Sync
(mdm-muenze/mdm-staging), Sidekiq-Worker, GraphQL (privat + public/App-Proxy),
REST-API v1, 5 Shopify-Extensions.

### Tech-Stack

- Ruby 4.0.2, Rails 8.1.3, PostgreSQL, Sidekiq + sidekiq-scheduler, Redis
- Frontend: React 18 + Vite 6 + Apollo Client + Polaris 13
- Extensions: credit-check, sepa-iban (Checkout UI), payment-customization (Function),
  order-credit-check-block, order-sap-status-block (Admin Blocks)
- RuboCop mit Shopify-Preset; Brakeman fuer Security-Analyse
- Deploy: Docker (web + worker) → registry.mdm.de → GitLab-Pipeline (`deploy.sh`)

### Befehle (ausfuehren in `connector/`)

- `bundle exec rubocop` — Linter
- `bundle exec brakeman` — Security-Scan
- `bin/dev` — Dev-Server (Rails + Sidekiq + Vite)
- `./deploy.sh --staging` / `./deploy.sh --production` — Deploy

### Secrets

Nur in `.env` (nie committen). Template: `.env.template`.
Keys: SHOPIFY_API_KEY/SECRET, SAP_API_URL/USERNAME/PASSWORD, CREDIT_API_*, OPENIBAN_API_*,
GITLAB_URL/TOKEN, ROLLBAR_ACCESS_TOKEN, SIDEKIQ_USERNAME/PASSWORD.

## Datalayer (datalayer/)

GTM-Datalayer fuer 3 Mandanten-Shops. Enthaelt Consent-Manager-Integration,
GTM-Pixel-Logik und Uebergabe-Dokumentation.

## Creditcheck (creditcheck/)

PHP/Symfony-Microservice (PHP 7.4). Zwei Services in einem Repo:
- **Creditcheck** — Bonitaetspruefung von Kunden
- **CustomerInformation** — Kundendaten aus SAP abrufen

### Tech-Stack

- PHP 7.4, Symfony (aeltere Version), Docker, Redis
- SAP-Integration via `mdm-ecom/lib.sap`
- CI/CD: GitLab CI + Jenkins, VuePress-Doku
- Team: Middleware (ecom-middleware@mdm.de)

### Befehle (ausfuehren in `creditcheck/`)

- `docker compose up -d` — Dev-Umgebung starten
- `docker compose exec app bin/phpunit` — Tests ausfuehren
- Doku: `docs/`

### Secrets

`.env` im Root und `www/.env` — nie committen.

## Emailservice (emailservice/)

PHP/Symfony-Microservice (PHP 8.3, Symfony 7.1) fuer E-Mail-Versand via Emarsys.
Empfaengt Anfragen vom SAP-System, reichert sie mit Kundendaten an und filtert
E-Mails bei Opt-out.

### Tech-Stack

- PHP 8.3, Symfony 7.1, Docker, AMQP/Messenger, Doctrine ORM
- Emarsys-Integration, SAP-Anbindung
- PHPStan + PHPCS fuer statische Analyse
- CI/CD: GitLab CI + Jenkins, VuePress-Doku
- Team: Middleware (ecom-middleware@mdm.de)

### Befehle (ausfuehren in `emailservice/`)

- `docker compose up -d` — Dev-Umgebung starten
- `docker compose exec app bin/phpunit` — Tests ausfuehren
- `docker compose exec app vendor/bin/phpstan analyse` — Statische Analyse
- `docker compose exec app vendor/bin/phpcs` — Code-Style
- Doku: `docs/`

### Secrets

`.env` im Root und `www/.env` — nie committen.

## Payment-Service (payment-service/)

Monorepo: PHP/Symfony-Backend (PHP 8.3, Symfony 7.1) + Nuxt-Frontend.
Zahlungsabwicklung ueber Saferpay. Historisch von Docker Compose ueber k8s
zu Docker Swarm migriert.

### Tech-Stack

- Backend: PHP 8.3, Symfony 7.1, Doctrine ORM, Saferpay JSON API
- Frontend: Nuxt (Vue.js), Jest fuer Unit-Tests
- Docker (nginx + php + nuxt), Migrations
- CI/CD: GitLab CI + Jenkins, VuePress-Doku
- Team: Middleware (ecom-middleware@mdm.de)

### Befehle (ausfuehren in `payment-service/`)

- `docker compose up -d` — Dev-Umgebung starten
- `docker compose exec app bin/phpunit` — Backend-Tests
- `cd client && yarn test:unit` — Frontend-Tests
- Doku: `docs/`

### Secrets

`.env` im Root und `www/.env` — nie committen.

## Spec-Driven Development

Jede Aenderung beginnt mit einer **Spec-Datei** (`.claude/specs/`), die Anforderungen
und Akzeptanzkriterien definiert — BEVOR Code geschrieben wird.

1. **Spec schreiben** — Anforderungen definieren (was, nicht wie)
2. **Spec reviewen** — Konrad gibt Freigabe
3. **Implementieren** — Code wird gegen die Spec gebaut
4. **Validieren** — Akzeptanzkriterien pruefen

Konventionen: `.claude/specs/README.md`. Theme-Specs: `.claude/specs/theme/`.
Connector-Specs: `.claude/specs/connector/`.
Middleware-Specs: `.claude/specs/creditcheck/`, `.claude/specs/emailservice/`, `.claude/specs/payment-service/`.
Datalayer-Specs: `.claude/specs/datalayer/`.

## Workflow — Theme

Template-Arbeit: `/mdm-template` mit festen Phasen:
Spec → Extraktion (figma-extractor) → Plan (theme-planner) → **Freigabe** →
Implementierung (liquid-implementer) → Review (theme-reviewer + security-reviewer) →
Doku (docs-writer) → Uebergabe. Systemuebersicht: `.claude/README.md`

Grundprinzip: **Theme-First** — bestehende Hyper-Sections ueberschreiben, nicht neu bauen.
So wenig wie moeglich neu entwickeln, so viel wie noetig.
Mapping und Konventionen: `.claude/specs/theme/_conventions.md`.

## Workflow — Connector

Feature-Arbeit in eigenem Git-Worktree (siehe Git Worktree):
Worktree anlegen → rails-planner → **Freigabe** → rails-implementer (TDD: Red→Green→Refactor) →
rails-reviewer + security-reviewer → Doku (docs-writer) → Uebergabe → Worktree aufraeumen.

## Notizen (Apple Notes)

Fester Notiz-Satz, Praefix `MDM Shopify ::`. Konventionen: Skill `/mdm-notes`.
Ablage im Notes-Ordner `Shopify` mit Unterordnern `Tagebuch` und `Tickets`.
Update = Vollersetzung. Kein Markdown, kein `&`, Body-Zeile 1 = Titel.

## Shopify Dev MCP

Zu Beginn einer Liquid-Session `learn_shopify_api` aufrufen; Doku ueber
`search_docs_chunks`; vor Abschluss `validate_theme` laufen lassen.
Shopify parst Liquid strikt (seit 13.01.2026).

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
