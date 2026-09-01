# MDM Workspace

## Zweck

Zentraler Workspace fuer das MDM-Oekosystem: Shopify (Theme, Backend-Connector, Datalayer)
und Middleware-Services (Creditcheck, Emailservice, Payment-Service).
Sechs eigenstaendige Git-Repos, eine gemeinsame KI-Steuerungsschicht (Harness).

## Workspace-Struktur

{{WORKSPACE_TREE}}

Alle Theme-Pfade relativ zum Workspace-Root tragen das Praefix `theme/`
(z. B. `theme/sections/`, `theme/locales/`). Connector-Pfade analog `connector/`.
Middleware-Pfade analog `creditcheck/`, `emailservice/`, `payment-service/`.

## Repos und Git

{{REPO_TABLE}}
