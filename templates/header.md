# MDM Workspace

## Zweck

Zentraler Workspace fuer das MDM-Oekosystem: Shopify (drei Marken-Themes, Backend-Connector,
Datalayer) und Middleware-Services (Creditcheck, Emailservice, Payment-Service).
Eigenstaendige Git-Repos, eine gemeinsame KI-Steuerungsschicht (Harness).

## Workspace-Struktur

{{WORKSPACE_TREE}}

Theme-Pfade tragen relativ zum Workspace-Root das Praefix `themes/<marke>/`
(z. B. `themes/mdm/sections/`, `themes/borek/locales/`) — `mdm`, `borek`, `imm`.
Connector-Pfade analog `connector/`. Middleware-Pfade analog `creditcheck/`,
`emailservice/`, `payment-service/`.

## Repos und Git

{{REPO_TABLE}}
