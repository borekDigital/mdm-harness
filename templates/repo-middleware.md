## Middleware (creditcheck/, emailservice/, payment-service/)

Drei PHP/Symfony-Services auf GitLab, Ansprechpartner Team Middleware
(ecom-middleware@mdm.de). Alle Docker-basiert, VuePress-Doku unter `<repo>/docs/`.

| Service | Aufgabe | Besonderheit |
|---|---|---|
| `creditcheck/` | Bonitaetspruefung + CustomerInformation | zwei Services in einem Repo, Trennung geplant |
| `emailservice/` | E-Mail-Versand via Emarsys | AMQP/Messenger, SAP-Anreicherung, Opt-out-Filter |
| `payment-service/` | Zahlungsabwicklung via Saferpay | Monorepo mit Nuxt-Frontend in `client/` |

- Dev: `docker compose up -d` — Tests: `docker compose exec app bin/phpunit`
- ⚠️ `creditcheck` laeuft auf **PHP 7.4**: kein `match`, keine Enums, keine Attributes.
  Die beiden anderen auf PHP 8.3 / Symfony 7.1.
- Secrets in `.env` (Root und `www/`) — nie committen.

Konventionen und Details je Service: `.claude/rules/middleware-conventions.md`
