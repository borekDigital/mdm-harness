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
