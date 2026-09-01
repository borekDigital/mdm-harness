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
