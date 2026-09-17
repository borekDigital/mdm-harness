# MDM Workspace

Zentraler Workspace fuer das MDM-Oekosystem: drei Shopify-Marken-Themes, Connector,
Datalayer und drei Middleware-Services — acht eigenstaendige Git-Repos unter einer
gemeinsamen KI-Steuerungsschicht. `~/MDM/` ist selbst ein Repo (`mdm-harness`), die
Kind-Repos sind darin gitignored.

Diese Datei wird von `sync.sh` aus `templates/` erzeugt — **Aenderungen dort, nicht hier.**

## Repos

{{REPO_TABLE}}

Zugriff auf die GitHub-Repos **nur** ueber den SSH-Alias `github.com-borek`
(Zweit-Account `Konrad-Thiemann`, Key `~/.ssh/id_ed25519_borek`) — kanonisches
`git@github.com:` schlaegt bei der Org `borekDigital` fehl. Middleware liegt auf
`gitlab.mdm.de` (Standard-Key) und folgt `master` statt `main`.
