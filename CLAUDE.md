# MDM Workspace

## Zweck

Zentraler Workspace fuer das MDM-Oekosystem: Shopify (drei Marken-Themes, Backend-Connector,
Datalayer) und Middleware-Services (Creditcheck, Emailservice, Payment-Service).
Eigenstaendige Git-Repos, eine gemeinsame KI-Steuerungsschicht (Harness).

## Workspace-Struktur

```
~/MDM/                        Workspace-Root (Harness-Repo)
├── themes/mdm/               Shopify Theme MDM
├── themes/borek/             Shopify Theme Borek
├── themes/imm/               Shopify Theme IMM
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

Theme-Pfade tragen relativ zum Workspace-Root das Praefix `themes/<marke>/`
(z. B. `themes/mdm/sections/`, `themes/borek/locales/`) — `mdm`, `borek`, `imm`.
Connector-Pfade analog `connector/`. Middleware-Pfade analog `creditcheck/`,
`emailservice/`, `payment-service/`.

## Repos und Git

8 unabhaengige Git-Repos auf zwei Plattformen:

**Shopify-Repos** — GitHub via SSH-Alias `github.com-borek`
(Key `~/.ssh/id_ed25519_borek`, GitHub-Account `Konrad-Thiemann`, Org `borekDigital`):

| Repo | Pfad | Remote |
|---|---|---|
| Shopify Theme MDM | `themes/mdm/` | `git@github.com-borek:borekDigital/shopifyFrontend_MDM.git` |
| Shopify Theme Borek | `themes/borek/` | `git@github.com-borek:borekDigital/shopifyFrontend_Borek.git` |
| Shopify Theme IMM | `themes/imm/` | `git@github.com-borek:borekDigital/shopifyFrontend_IMM.git` |
| Shopify Connector | `connector/` | `git@github.com-borek:borekDigital/shopifyConnector.git` |
| GTM Datalayer | `datalayer/` | `git@github.com-borek:borekDigital/shopifyDatalayer.git` |

**Middleware-Repos** — GitLab (gitlab.mdm.de).
Zugang zu gitlab.mdm.de erforderlich fuer diese Repos.

| Repo | Pfad | Remote |
|---|---|---|
| Creditcheck + CustomerInfo | `creditcheck/` | `git@gitlab.mdm.de:middleware/creditcheck.git` |
| Emailservice | `emailservice/` | `git@gitlab.mdm.de:middleware/emailservice.git` |
| Payment-Service | `payment-service/` | `git@gitlab.mdm.de:middleware/payment-service.git` |

## Themes (themes/)

Drei Shopify-Themes, ein Aufbau — je Marke ein eigenes Repo unter `themes/`:

| Marke | Pfad | Store-Handle |
|---|---|---|
| MDM | `themes/mdm/` | `mdm-muenze` |
| Borek | `themes/borek/` | — |
| IMM | `themes/imm/` | — |

Basis aller drei: kommerzielles Theme Hyper v1.3.3 von FoxEcom
(Online Store 2.0, Doku: docs.foxecom.com/hyper-theme).

Die drei Repos teilen **keine** Git-Historie (drei getrennte Wurzel-Commits), aber
rund 90 Prozent identische Dateien. MDM ist der aktive Zweig und laeuft den beiden
anderen voraus; Borek und IMM sind untereinander nahezu deckungsgleich.
Perspektivisch sollen alle drei Shops auf **einem** Theme laufen — bis dahin gilt
der Patch-Weg unten.

### Befehle (ausfuehren im jeweiligen Theme-Verzeichnis)

- `shopify theme check --fail-level error` — Linter (Baseline MDM: 9 Errors + 20 Warnings in Altlasten)
- `shopify theme dev --store mdm-muenze` — Dev-Server mit Hot-Reload
- `shopify theme pull --store mdm-muenze --theme <id>` — Stand vom Store holen
- `shopify theme push --unpublished --store mdm-muenze` — Upload als unveroeffent. Theme
- Kein `--theme-editor-sync` (CLI-Bug, community.shopify.dev/t/28292 — Hook blockiert)

Der Store-Handle gehoert zur Marke — `--store mdm-muenze` gilt nur fuer `themes/mdm/`.

### Namensraum

- Das Praefix `mdm-` ist die **Haus-Konvention aller drei Themes**, nicht die Marke MDM.
  Auch `themes/borek/` und `themes/imm/` fuehren `mdm-breadcrumbs.liquid`,
  `mdm-card-product.liquid` usw.
- FoxEcom-Kerndateien NIEMALS direkt bearbeiten. Jede Section, die in einem
  Template referenziert wird, MUSS als `mdm-`-Kopie existieren (update-sicher).
- Templates: `product.mdm.json`, `collection.mdm.json`; Landingpages `page.<slug>.json`.
- Locales: `en.default.json` (Default) + `de.json` (Shop-Sprache) — paarig pflegen.
- Markenspezifisch und nie zwischen Themes uebertragen: `config/settings_data.json`,
  `config/settings_schema.json`, `locales/`, `templates/`, `sections/*-group.json`,
  `layout/` (MDM hat `mdm-theme.liquid`, Borek `borek-theme.liquid`).
- Bereichs-Details: `.claude/rules/`

### Gleiche Aenderung in mehrere Themes (bin/theme-sync.sh)

Die drei Themes teilen keine Git-Historie, deshalb scheidet `git merge` aus. Eine
Aenderung wandert von Arbeitsbaum zu Arbeitsbaum.

**Es gibt keine Automatik.** Nichts erzeugt von selbst einen Commit, einen Push
oder einen PR in den anderen Themes. Jede Uebertragung wird angestossen.

#### Ablauf

```bash
# 1. Im Quell-Theme fertig: committet und gemergt.
#    Der Commit-SHA aus dem Quell-Theme ist der Schluessel.

# 2. Sehen, wo die Themes stehen
bin/theme-sync.sh list
bin/theme-sync.sh drift assets/          # optional: was laeuft auseinander?

# 3. Uebertragen — Modus nach Lage waehlen (siehe Tabelle)
bin/theme-sync.sh port mdm borek,imm --commit <sha> --as-patch

# 4. Je Ziel-Theme pruefen und committen
git -C themes/borek diff
git -C themes/borek commit -am "…"       # gleiche Message wie in der Quelle
git -C themes/borek push -u origin sync/mdm-<datum>

# 5. PR je Ziel-Theme von Hand
```

#### Welcher Modus?

| Lage | Kommando | Wirkung |
|---|---|---|
| Datei in Quelle und Ziel sonst identisch | `port <q> <ziele> <pfad>` | kopiert die ganze Datei |
| Quelle laeuft in derselben Datei voraus | `port <q> <ziele> --commit <sha> --as-patch` | wendet nur die Hunks des Commits an |

Der Normalfall ist `--as-patch`, weil MDM den beiden anderen vorauslaeuft. Ohne
`--as-patch` wuerde die Ganzdatei-Kopie die abweichende Zielarbeit ueberschreiben.

#### Sicherungen

- Ziel mit unsauberem Arbeitsbaum wird uebersprungen, nicht ueberschrieben.
- Mit `--as-patch`: passt der Patch nicht, wird das Ziel uebersprungen, **bevor**
  der Branch angelegt wird. Ausweg: `git -C themes/<ziel> apply --3way --reject`.
- Markenspezifische Pfade (`locales/`, `templates/`, `config/settings_*.json`,
  `layout/`, `sections/*-group.json`) werden uebersprungen; `--allow-brand` erzwingt.
- Das Skript committet nie und pusht nie.

#### Was das Skript nicht pruefen kann

Ob die Aenderung **inhaltlich** in die andere Marke passt. Hart verdrahtete
Layout-Zahlen aus einem Marken-Figma (Spaltenbreiten, Verhaeltnisse, Breakpoints)
laufen sauber durch den Patch und sind im Zielshop trotzdem falsch. Nach jeder
Uebertragung im Ziel-Theme visuell gegenpruefen:

```bash
cd themes/<ziel> && shopify theme check --output json   # JSON parsen, nicht Exit-Code
cd themes/<ziel> && shopify theme dev --store <handle>
```

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

Konventionen: `.claude/specs/README.md`. Theme-Specs: `.claude/specs/themes/` (gemeinsam) und `.claude/specs/themes/<marke>/`.
Connector-Specs: `.claude/specs/connector/`.
Middleware-Specs: `.claude/specs/creditcheck/`, `.claude/specs/emailservice/`, `.claude/specs/payment-service/`.
Datalayer-Specs: `.claude/specs/datalayer/`.

## Workflow — Theme

Gilt fuer alle drei Marken-Themes. Das Ziel-Theme (`themes/mdm/`, `themes/borek/`,
`themes/imm/`) wird zu Beginn festgelegt; ohne Angabe ist `themes/mdm/` gemeint.

Template-Arbeit: `/mdm-template` mit festen Phasen:
Spec → Extraktion (figma-extractor) → Plan (theme-planner) → **Freigabe** →
Implementierung (liquid-implementer) → Review (theme-reviewer + security-reviewer) →
Doku (docs-writer) → Uebergabe. Systemuebersicht: `.claude/README.md`

Grundprinzip: **Theme-First** — bestehende Hyper-Sections ueberschreiben, nicht neu bauen.
So wenig wie moeglich neu entwickeln, so viel wie noetig.
Mapping und Konventionen: `.claude/specs/themes/_conventions.md`.

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
