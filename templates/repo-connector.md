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
