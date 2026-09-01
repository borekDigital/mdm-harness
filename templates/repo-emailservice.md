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
