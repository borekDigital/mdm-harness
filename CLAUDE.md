# MDM Workspace

Zentraler Workspace fuer das MDM-Oekosystem: drei Shopify-Marken-Themes, Connector,
Datalayer und drei Middleware-Services — acht eigenstaendige Git-Repos unter einer
gemeinsamen KI-Steuerungsschicht. `~/MDM/` ist selbst ein Repo (`mdm-harness`), die
Kind-Repos sind darin gitignored.

Diese Datei wird von `sync.sh` aus `templates/` erzeugt — **Aenderungen dort, nicht hier.**

## Repos

| Repo | Pfad | Stack | Branch |
|---|---|---|---|
| Shopify Theme MDM | `themes/mdm/` | Liquid/CSS/JS (Hyper 1.3.3) | `main` |
| Shopify Theme Borek | `themes/borek/` | Liquid/CSS/JS (Hyper 1.3.3) | `main` |
| Shopify Theme IMM | `themes/imm/` | Liquid/CSS/JS (Hyper 1.3.3) | `main` |
| Shopify Connector | `connector/` | Rails 8.1 / React 18 / Polaris | `main` |
| GTM Datalayer | `datalayer/` | JavaScript | `main` |
| Creditcheck + CustomerInfo | `creditcheck/` | PHP 7.4 / Symfony 5.4 | `master` |
| Emailservice | `emailservice/` | PHP 8.3 / Symfony 7.1 | `master` |
| Payment-Service | `payment-service/` | PHP 8.3 / Symfony 7.2 / Nuxt 2 | `master` |

Zugriff auf die GitHub-Repos **nur** ueber den SSH-Alias `github.com-borek`
(Zweit-Account `Konrad-Thiemann`, Key `~/.ssh/id_ed25519_borek`) — kanonisches
`git@github.com:` schlaegt bei der Org `borekDigital` fehl. Middleware liegt auf
`gitlab.mdm.de` (Standard-Key) und folgt `master` statt `main`.

## Themes (themes/)

Drei Marken-Themes, ein Aufbau. Basis aller drei: kommerzielles Theme **Hyper v1.3.3**
von FoxEcom (Online Store 2.0, Doku: docs.foxecom.com/hyper-theme).

| Marke | Pfad | Store-Handle |
|---|---|---|
| MDM | `themes/mdm/` | `mdm-muenze` |
| Borek | `themes/borek/` | — |
| IMM | `themes/imm/` | — |

Die drei Repos teilen **keine** Git-Historie, aber rund 90 Prozent identische Dateien.
MDM ist der aktive Zweig und laeuft den beiden anderen voraus; Borek und IMM sind
untereinander nahezu deckungsgleich. Perspektivisch sollen alle drei Shops auf **einem**
Theme laufen. Uebertragung zwischen den Marken: Skill `/theme-port`. Automatisch: der
Workflow `theme-sync.yml` im MDM-Theme oeffnet je Push auf `main` den PR `sync/theme-mdm`
in Borek und IMM (`bin/theme-sync.sh align`), sobald die Repo-Variable `THEME_SYNC_ENABLED`
auf `true` steht; gemergt wird von Hand.

### Befehle (im jeweiligen Theme-Verzeichnis, nicht im Workspace-Root)

- `shopify theme check --fail-level error` — Linter
- `shopify theme dev --store mdm-muenze` — Dev-Server mit Hot-Reload
- Upload nur als unveroeffentlichtes Theme (`--unpublished`), nie aufs Live-Theme
- Kein `--theme-editor-sync` (CLI-Bug, community.shopify.dev/t/28292 — Hook blockiert)

Der Store-Handle gehoert zur Marke — `--store mdm-muenze` gilt nur fuer `themes/mdm/`.

### Namensraum

- Das Praefix `mdm-` ist die **Haus-Konvention aller drei Themes**, nicht die Marke MDM.
  Auch `themes/borek/` und `themes/imm/` fuehren `mdm-breadcrumbs.liquid` usw.
- FoxEcom-Kerndateien NIEMALS direkt bearbeiten. Jede Section, die in einem Template
  referenziert wird, MUSS als `mdm-`-Kopie existieren (update-sicher).
- Markenspezifisch, nie zwischen Themes uebertragen: `config/settings_data.json`,
  `config/settings_schema.json`, `locales/`, `sections/*-group.json`, `layout/` sowie
  alle Templates ausser den geteilten.
- Geteilte Templates (seit 15. Oktober 2026): `collection.json`, `collection.mdm.json`,
  `product.json`, `product.mdm.json` sind in allen drei Themes gleich — gleiche Sections,
  Reihenfolge, IDs und Namen. Vorlage ist MDM; nur der `layout`-Schluessel bleibt
  markenspezifisch (`mdm-theme`, `borek-theme`, `imm-theme`). Weitere Templates kommen
  erst nach Abstimmung mit Bhavani dazu. Spec: `.claude/specs/themes/templates-angleichen-plp-pdp.md`.
- Details je Bereich: `.claude/rules/` (liquid-, templates-json-, merchant-config-)

## Connector (connector/)

Rails-Backend mit React/Polaris-Frontend. Bidirektionaler Shopify↔SAP-Sync
(`mdm-muenze`/`mdm-staging`), Sidekiq-Worker, GraphQL (privates Schema fuer den
embedded Admin, oeffentliches fuer den App-Proxy), REST-API v1, fuenf Shopify-Extensions.

### Befehle (in `connector/`)

- `bin/dev` — Dev-Server (Rails + Sidekiq + Vite)
- `bundle exec rspec` / `rubocop` / `brakeman` — Tests, Linter, Security-Scan
- `./deploy.sh --staging` / `--production` — Deploy (Docker → registry.mdm.de → GitLab)

### Secrets

Nur in `.env`, nie committen. Template: `.env.template` listet alle benoetigten Keys
(Shopify, SAP, Credit-API, OpenIBAN, GitLab, Rollbar, Sidekiq).

Konventionen: `.claude/rules/connector-conventions.md`

## Datalayer (datalayer/)

GTM-Datalayer fuer 3 Mandanten-Shops. Enthaelt Consent-Manager-Integration,
GTM-Pixel-Logik und Uebergabe-Dokumentation.

## Middleware (creditcheck/, emailservice/, payment-service/)

Drei PHP/Symfony-Services auf GitLab, Ansprechpartner Team Middleware
(ecom-middleware@mdm.de). Alle Docker-basiert, VuePress-Doku unter `<repo>/docs/`.

| Service | Aufgabe | Besonderheit |
|---|---|---|
| `creditcheck/` | Bonitaetspruefung + CustomerInformation | zwei Services in einem Repo, Trennung geplant |
| `emailservice/` | E-Mail-Versand via Emarsys | AMQP/Messenger, SAP-Anreicherung, Opt-out-Filter |
| `payment-service/` | Zahlungsabwicklung via Saferpay | Monorepo mit Nuxt-2-Frontend in `client/` |

- Dev: `docker compose up -d` — Tests: `docker compose exec app bin/phpunit`
- ⚠️ `creditcheck` laeuft auf **PHP 7.4**: kein `match`, keine Enums, keine Attributes.
  Symfony 5.4. Die beiden anderen auf PHP 8.3 — emailservice Symfony 7.1, payment-service
  Symfony 7.2 mit Nuxt-2-Frontend. Versionen und Doku-Quellen: Rule `doku-quellen`.
- Secrets in `.env` (Root und `www/`) — nie committen.

Konventionen und Details je Service: `.claude/rules/middleware-conventions.md`

## Spec-Driven Development

Jede Aenderung beginnt mit einer **Spec** unter `.claude/specs/` (Anforderungen und
Akzeptanzkriterien, *was* — nicht *wie*), dann Freigabe durch Konrad, dann Implementierung
gegen die Spec, dann Validierung der Akzeptanzkriterien.
Ablage und Konventionen: `.claude/specs/README.md`.

## Workflow — Theme

Gilt fuer alle drei Marken-Themes; ohne Angabe ist `themes/mdm/` gemeint.

Grundprinzip **Theme-First**: bestehende Hyper-Sections ueberschreiben statt neu bauen —
so wenig Neuentwicklung wie moeglich. Mapping: `.claude/specs/themes/_conventions.md`.

- Ganze Seite aus Figma → Skill `/mdm-template` (zerlegt in eine Block Map)
- Einzelner Block → Skill `/mdm-block` (ein Block = ein Branch = ein PR)

## Workflow — Connector und Middleware

Feature-Arbeit im eigenen Worktree: Plan → **Freigabe** → Implementierung (TDD) →
Review-Paar (fachlicher Reviewer + security-reviewer) → Doku → Uebergabe.
Skills: `/connector-feature`, `/middleware-feature`.

## Shopify Dev MCP

Zu Beginn einer Liquid-Session `learn_shopify_api` aufrufen, Doku ueber
`search_docs_chunks`, vor Abschluss `validate_theme` laufen lassen.
Shopify parst Liquid strikt (seit 13.01.2026).

## Test-Driven Development

TDD ist Pflicht fuer alle Code-Aenderungen: **Red → Green → Refactor.** Kein Feature-Code
ohne vorherigen Test, kein Bugfix ohne Regression-Test. Test und Feature-Code gehoeren in
denselben Commit. Vor jedem Commit muss die Suite gruen sein.

| Bereich | Framework | Kommando |
|---|---|---|
| Connector | RSpec + FactoryBot, WebMock/VCR | `bundle exec rspec` |
| Middleware | PHPUnit | `docker compose exec app bin/phpunit` |
| Theme | keins — Liquid hat kein Unit-Test-Framework | `shopify theme check` + Smoke-Test |

Details je Stack: `.claude/rules/`

## Git Worktree

Parallele Feature-Arbeit laeuft in eigenen Worktrees unter `connector-worktrees/<branch>/`
(Workspace-Root-Ebene, gitignored) — nicht innerhalb von `connector/`. Der Haupt-Worktree
`connector/` bleibt immer auf `main`. Jeder Worktree braucht seine eigene `.env` (aus
`.env.template`). Nach dem Merge: Worktree entfernen und Branch loeschen.

```bash
cd connector && git worktree add ../connector-worktrees/<branch> -b <branch>
```

## Sprache und Commits

Deutsch fuer Doku und Artefakte, Englisch fuer Commits (Conventional Commits, 50/72,
imperativ, kleingeschrieben). **Der Scope ist nie eine Ticket-ID.** Weitere Vorgaben
stehen in der globalen `~/.claude/CLAUDE.md` und gelten hier unveraendert.

## Konventionen anderswo

| Thema | Ort |
|---|---|
| Jira-Ticket-Kommentare | Skill `/jira-comment` |
| Aenderung in mehrere Themes portieren | Skill `/theme-port` |
| Apple-Notes-Pflege | Skill `/mdm-notes` |
| Bereichs-Konventionen (Liquid, Rails, Symfony) | `.claude/rules/` |
| Systemuebersicht Agenten/Skills/Hooks | `.claude/README.md` |
