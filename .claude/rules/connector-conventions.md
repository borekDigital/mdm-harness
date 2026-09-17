---
paths:
  - "connector/app/**"
  - "connector/config/**"
  - "connector/db/**"
  - "connector/lib/**"
  - "connector/spec/**"
  - "connector-worktrees/*/app/**"
  - "connector-worktrees/*/config/**"
  - "connector-worktrees/*/db/**"
  - "connector-worktrees/*/lib/**"
  - "connector-worktrees/*/spec/**"
---
# Connector-Konventionen (Rails 8.1 / Shopify-App)

- RuboCop mit Shopify-Preset: einfache Anfuehrungszeichen, `ruby19_no_mixed_keys` Hash-Syntax,
  `def_self` fuer Klassenmethoden. Vor Abgabe `bundle exec rubocop` clean.
- Jobs: Namespaces `Shopify::` (Webhook-Handler, Sync) und `Sap::` (SAP-Integration).
  Idempotent designen, Retry-safe. Queue-Zuweisung: `critical`, `high`, `default`.
- GraphQL: Private Schema (embedded Admin, Session-Auth) vs. Public Schema (App-Proxy,
  Signatur-Verifikation). Keine Queries/Mutations am falschen Schema exponieren.
- Models: Validierungen, Assoziationen, Enums dokumentiert. Foreign-Key-Indizes pflegen.
- Migrations: reversibel, explizite Spaltentypen, Indizes fuer haeufige Queries.
- Extensions: TOML-Config valide, API-Version 2026-04, Lokalisierung vorhanden.
- Frontend (React/Polaris): Polaris-Komponenten bevorzugen, Apollo Client fuer GraphQL,
  keine direkte DOM-Manipulation.
- Secrets: nur ueber `ENV['KEY']` — nie in Code, Defaults, Config oder Kommentaren.
  Template: `.env.template`.
- Keine externen Abhaengigkeiten ohne Abstimmung — Sicherheit per `brakeman` pruefen.
- **TDD-Pflicht:** Jede Aenderung beginnt mit einem fehlschlagenden Test (Red → Green → Refactor).
  Kein Feature-Code ohne Test, kein Bugfix ohne Regression-Test.
  Framework: RSpec + FactoryBot. Externe APIs mocken (WebMock/VCR).
  Validierung: `bundle exec rspec` muss gruen sein vor Commit.
