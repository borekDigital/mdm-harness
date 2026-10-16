# Doku-Quellen

Gilt fuer die Hauptsitzung und alle Agenten. Spec: `.claude/specs/harness/claude-struktur-aktuell.md`, Teil A.

**Grundsatz:** Beruht eine Empfehlung, ein Plan oder Code auf API- oder Framework-Wissen, wird vorher
die Quelle unten abgefragt — **in der Version, die im Repo laeuft**, nicht in der neuesten. Trainingswissen
allein gilt als ⚠️ Vermutung. Was aus einer Quelle stammt, wird mit Quelle belegt.

## Versionen und Quellen

Stand 16. Oktober 2026. Die Spalte `Version` prueft `bin/harness-check.py` (H19) gegen den `Beleg` —
weicht ein Lockfile ab, erst diese Tabelle und die Quellen anpassen, dann weiterarbeiten.

| Bereich | Bibliothek | Version | Beleg | Quelle (Werkzeug) | Fallback (WebFetch) |
|---|---|---|---|---|---|
| Harness | Claude Code | 2.1 | `bin/harness-referenz.json` · `claude_code_version` | Agent `claude-code-guide`; `.md`-Seiten aus dem Index | https://code.claude.com/docs/llms.txt |
| Harness | Claude API, Modelle | — | — | Skill `claude-api` | https://platform.claude.com/llms.txt |
| Theme | Hyper (FoxEcom) | 1.3.3 | `themes/mdm/config/settings_schema.json` · `theme_version` | WebFetch (kein Connector) | https://docs.foxecom.com/hyper-theme |
| Theme | Liquid, Theme-Architektur | — | — | Shopify Dev MCP: `learn_shopify_api` (api `liquid`), `search_docs_chunks`, `validate_theme` | https://shopify.dev/docs/storefronts/themes |
| Connector | Ruby | 4.0 | `connector/.ruby-version` · `ruby` | WebFetch | https://docs.ruby-lang.org/en/4.0/ |
| Connector | Rails | 8.1 | `connector/Gemfile.lock` · `rails` | Context7 `/websites/api_rubyonrails_v8_1_3` (API), `/websites/guides_rubyonrails` (Guides) | https://guides.rubyonrails.org/v8.1/ |
| Connector | graphql-ruby | 2.6 | `connector/Gemfile.lock` · `graphql` | Context7 `/rmosolgo/graphql-ruby` | https://graphql-ruby.org/ |
| Connector | Sidekiq | 8.1 | `connector/Gemfile.lock` · `sidekiq` | Context7 `/sidekiq/sidekiq` | https://github.com/sidekiq/sidekiq/wiki |
| Connector | shopify_app | 23.0 | `connector/Gemfile.lock` · `shopify_app` | WebFetch | https://github.com/Shopify/shopify_app |
| Connector | shopify_api | 16.2 | `connector/Gemfile.lock` · `shopify_api` | WebFetch | https://github.com/Shopify/shopify-api-ruby |
| Connector | Shopify Admin API | 2026-04 | `connector/shopify.app.production.toml` · `api_version` | Shopify Dev MCP: `learn_shopify_api` (api `admin`, version `2026-04`), `validate` | https://shopify.dev/docs/api/admin-graphql/2026-04 |
| Connector | Polaris React | 13.9 | `connector/package.json` · `@shopify/polaris` | Context7 `/shopify/polaris-react-archive` | https://github.com/Shopify/polaris-react |
| Connector | App Bridge React | 3.7 | `connector/package.json` · `@shopify/app-bridge-react` | WebFetch | https://shopify.dev/docs/api/app-bridge |
| Connector | React | 18.3 | `connector/package.json` · `react` | Context7 per `resolve-library-id` mit Version 18 | https://18.react.dev/ |
| Middleware | PHP (creditcheck) | 7.4 | `creditcheck/www/composer.json` · `php` | Context7 `/websites/php_net_manual_en` | https://www.php.net/manual/en/migration80.php |
| Middleware | PHP (emailservice) | 8.3 | `emailservice/www/composer.json` · `php` | Context7 `/websites/php_net_manual_en` | https://www.php.net/manual/en/ |
| Middleware | PHP (payment-service) | 8.3 | `payment-service/www/composer.json` · `php` | Context7 `/websites/php_net_manual_en` | https://www.php.net/manual/en/ |
| Middleware | Symfony (creditcheck) | 5.4 | `creditcheck/www/composer.lock` · `symfony/framework-bundle` | Context7 `/websites/symfony_doc_5_x` | https://symfony.com/doc/5.4/ |
| Middleware | Symfony (emailservice) | 7.1 | `emailservice/www/composer.lock` · `symfony/framework-bundle` | Context7 `/websites/symfony_doc_7_4` | https://symfony.com/doc/7.1/ |
| Middleware | Symfony (payment-service) | 7.2 | `payment-service/www/composer.lock` · `symfony/framework-bundle` | Context7 `/websites/symfony_doc_7_4` | https://symfony.com/doc/7.2/ |
| Middleware | Doctrine ORM (emailservice) | 3.5 | `emailservice/www/composer.lock` · `doctrine/orm` | Context7 `/doctrine/orm` | https://www.doctrine-project.org/projects/doctrine-orm/en/3.6/ |
| Middleware | Doctrine ORM (payment-service) | 2.19 | `payment-service/www/composer.lock` · `doctrine/orm` | Context7 `/doctrine/orm/2.20.5` | https://www.doctrine-project.org/projects/doctrine-orm/en/2.19/ |
| Middleware | PHPUnit (emailservice) | 11.5 | `emailservice/www/composer.lock` · `phpunit/phpunit` | Context7 `/websites/phpunit_de_en_11_5` | https://docs.phpunit.de/en/11.5/ |
| Middleware | Nuxt (payment-service) | 2.15 | `payment-service/client/package.json` · `nuxt` | Context7 `/websites/v2_nuxt` | https://v2.nuxt.com/docs/ |
| Datalayer | GTM dataLayer | — | — | WebFetch | https://developers.google.com/tag-platform/tag-manager/datalayer |
| Design | Figma MCP | — | — | Skill `figma-to-liquid`, Skill figma-use des Figma-MCP-Servers | https://developers.figma.com/docs/figma-mcp-server/ |

## Fallstricke (✅ belegt am 16. Oktober 2026)

- **Polaris:** Der Shopify Dev MCP dokumentiert Polaris **Web Components** (`polaris-app-home`). Der Connector
  nutzt **Polaris React 13** — dafuer nur `/shopify/polaris-react-archive`, nie die Dev-MCP-Polaris-Doku.
- **App Bridge:** Der Connector nutzt App Bridge React 3.7; shopify.dev beschreibt die aktuelle Generation.
  Aussagen dort gegen die Version 3 pruefen.
- **Nuxt:** `payment-service/client` ist **Nuxt 2** (Vue 2, Vuex). Nuxt-3/4-Doku (`useFetch`, `server/`,
  Composition API) gilt dort nicht.
- **Symfony:** Context7 hat keine Doku fuer 7.1 oder 7.2 — `/websites/symfony_doc_7_4` ist neuer. Jede dort
  gefundene Funktion gegen den Hinweis „added in 7.x“ pruefen, im Zweifel den versionierten Fallback lesen.
  creditcheck ist **Symfony 5.4** auf **PHP 7.4**: keine Attribute fuer Routing/DI, kein `match`, keine Enums,
  keine Constructor Promotion.
- **PHP-Manual:** beschreibt PHP 8.x. Fuer creditcheck jede Funktion gegen die Migrationsseiten pruefen.
- **Doctrine:** emailservice 3.x, payment-service 2.19 — Mapping und API unterscheiden sich.

## Ablauf

1. Bibliothek in der Tabelle suchen. Fehlt sie: Version aus dem Lockfile lesen, mit `resolve-library-id`
   eine Context7-ID suchen — und die Zeile hier ergaenzen.
2. Context7: `query-docs` mit der ID aus der Tabelle, eine Frage je Aufruf. Die ID ist bekannt,
   `resolve-library-id` entfaellt.
3. Shopify: zuerst `learn_shopify_api` (liefert die `conversationId`), dann `search_docs_chunks`.
4. Liefert das Werkzeug nichts oder fehlt der Connector: Fallback-URL per WebFetch, versioniert.
5. Harness-Aenderungen (Agenten, Skills, Rules, Hooks, Settings, MCP): vorher `claude-code-guide`
   oder die `.md`-Seite aus `llms.txt` lesen.

An Context7 und andere Doku-Dienste gehen nur Bibliotheksname, Version und Frage — nie Code,
Kundendaten, Zugangsdaten oder interne Namen.
