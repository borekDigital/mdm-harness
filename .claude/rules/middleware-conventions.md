---
paths:
  - "creditcheck/**"
  - "emailservice/**"
  - "payment-service/**"
---
# Middleware-Konventionen (PHP/Symfony)

- Alle drei Services sind Docker-basiert. Dev-Umgebung via `docker compose up -d`.
- App-Code liegt unter `<repo>/www/src/`, Config unter `<repo>/www/config/`, Tests unter `<repo>/www/tests/`.
- Secrets NUR in `.env`-Dateien (Root und www/) — nie committen, nie in Code/Config hardcoden.
- GitLab CI (`<repo>/.gitlab-ci.yml`) definiert die Pipeline. Jenkins fuer Doku-Generierung (VuePress).
- Team Middleware (ecom-middleware@mdm.de) ist Ansprechpartner fuer alle drei Services.

## creditcheck (PHP 7.4)
- Doctrine Annotations (nicht Attributes), JMS Serializer-Bundle.
- Zwei logische Services (Creditcheck + CustomerInformation) — geplante Trennung beachten.
- SAP-Anbindung via `mdm-ecom/lib.sap`, Redis fuer Caching.
- Tests: `www/tests/`, PHPUnit (`phpunit.xml.dist`).
- Keine statische Analyse konfiguriert (PHPStan/PHPCS fehlen).

## emailservice (PHP 8.3, Symfony 7.1)
- PHP 8 Attributes, Symfony Messenger (AMQP) fuer asynchrone Verarbeitung.
- Emarsys-Integration fuer E-Mail-Versand, SAP-Anbindung fuer Kundendaten.
- Mock-Services unter `src/Services/Mock/` fuer lokale Entwicklung.
- Templates unter `www/templates/`, Uebersetzungen unter `www/translations/`.
- Statische Analyse: PHPStan (`phpstan.neon`) + PHPCS (`phpcs.xml.dist`).
- Tests: `www/tests/`, PHPUnit (`phpunit.xml.dist`).

## payment-service (PHP 8.3, Symfony 7.1 + Nuxt)
- Monorepo: Symfony-Backend (`www/`) + Nuxt-Frontend (`client/`).
- Saferpay JSON API (`ticketpark/saferpay-json-api`) fuer Zahlungsabwicklung.
- Doctrine ORM mit Migrations unter `www/migrations/`.
- Frontend: Nuxt/Vue.js mit Jest-Tests, i18n, Vuex Store.
- Deploy historisch von Docker Compose → k8s → Docker Swarm migriert.
- Tests Backend: `www/tests/`, PHPUnit. Tests Frontend: `client/`, Jest.

## Allgemeine Regeln
- PHP-Version beachten: creditcheck = 7.4 (kein `match`, keine Enums, keine Attributes), Rest = 8.3.
- Bestehende Patterns im jeweiligen Repo lesen, bevor neue Code-Strukturen eingefuehrt werden.
- Symfony-Services via DI (services.yaml), kein Service-Locator-Anti-Pattern.
- Doctrine-Entities: validierte Mappings, Repositories fuer komplexe Queries.
- Bei externen APIs (SAP, Emarsys, Saferpay): Timeout-Handling, Fehler-Logging, Retry-Strategie.
