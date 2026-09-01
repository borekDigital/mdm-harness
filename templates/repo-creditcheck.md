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
