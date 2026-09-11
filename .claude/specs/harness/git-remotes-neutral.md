# Spec: Git-Remotes ohne persönliche Konfiguration

Stand: 11. September 2026
Quelle: Review Seniorentwickler, 11. September 2026
Status: ENTWURF

## Ziel

`workspace.yaml` und die erzeugte Dokumentation nennen die Remotes, wie GitHub und GitLab sie
ausgeben. Wessen SSH-Schlüssel dabei greift, entscheidet jeder auf seinem Rechner.

## Ist-Zustand

### Der Alias steht im Repo

Alle drei GitHub-Remotes nutzen einen SSH-Alias, der nur auf einem Rechner existiert:

| Datei | Zeile | Inhalt |
|---|---|---|
| `workspace.yaml` | 14 | `git@github.com-borek:borekDigital/shopifyFrontend_MDM.git` |
| `workspace.yaml` | 24 | `git@github.com-borek:borekDigital/shopifyConnector.git` |
| `workspace.yaml` | 34 | `git@github.com-borek:borekDigital/shopifyDatalayer.git` |
| `README.md` | 8 | `git clone git@github.com-borek:borekDigital/mdm-harness.git MDM` |
| `CLAUDE.md` | 38–40 | dieselben drei Remotes in der Repo-Tabelle |
| `.github/workflows/bauplan-refresh.yml` | 88 | `insteadOf "git@github.com-borek:"` |

`github.com-borek` ist ein `Host`-Eintrag in `~/.ssh/config`. Wer ihn nicht hat, bekommt beim
Klonen `Could not resolve hostname github.com-borek`. Die GitLab-Remotes sind davon nicht
betroffen — sie lauten bereits `git@gitlab.mdm.de:`.

### Der Schlüssel steht in der erzeugten Doku

`sync.sh` schreibt die Zugangsinformationen in die generierte `CLAUDE.md`:

```
sync.sh:95  **Shopify-Repos** — GitHub via SSH-Alias `github.com-borek`
sync.sh:96  (Key `~/.ssh/id_ed25519_borek`, GitHub-Account `Konrad-Thiemann`, Org `borekDigital`):
```

Damit steht in einer versionierten, für alle erzeugten Datei der Dateiname eines privaten
Schlüssels und ein persönlicher GitHub-Benutzername. Für Kollegen ist beides falsch; als
Anleitung führt es in die Irre.

### Warum der Alias existiert

Der Alias ist kein Versehen. Der Haupt-GitHub-Account hat keinen Zugriff auf die Organisation
`borekDigital`; ein Zweit-Account mit eigenem Schlüssel hat ihn. Ein `Host`-Alias ist der
übliche Weg, pro Ziel einen anderen Schlüssel zu wählen.

Falsch ist nicht der Alias, sondern **wo er steht**: in der geteilten Konfiguration statt in
der lokalen.

## Soll-Zustand

### Kanonische Remotes im Repo

```yaml
remote: "git@github.com:borekDigital/shopifyFrontend_MDM.git"
remote: "git@github.com:borekDigital/shopifyConnector.git"
remote: "git@github.com:borekDigital/shopifyDatalayer.git"
```

Das ist die Adresse, die GitHub auf der Repo-Seite anzeigt. Sie funktioniert für jeden, dessen
Standardschlüssel Zugriff hat — ohne weitere Einrichtung.

### Abweichende Schlüssel lokal abbilden

Wer einen anderen Schlüssel braucht, hinterlegt das auf seinem Rechner. Zwei Wege, beide ohne
Änderung am Repo:

**Weg A — `~/.ssh/config`, schlüsselbasiert statt aliasbasiert:**

```
Host github.com
  IdentityFile ~/.ssh/id_ed25519_borek
  IdentitiesOnly yes
```

Passt, wenn alle GitHub-Arbeit über denselben Zweit-Account läuft.

**Weg B — `git config`, wenn beide Accounts parallel gebraucht werden:**

```bash
git config --global url."git@github.com-zweitaccount:".insteadOf "git@github.com:"
```

Der Alias bleibt in `~/.ssh/config` bestehen, wird aber lokal davorgeschaltet. Das Repo sieht
weiterhin die kanonische Adresse.

Weg B ist genau das Verfahren, das der CI-Lauf bereits nutzt
(`.github/workflows/bauplan-refresh.yml:86–88`) — dort in die andere Richtung, von SSH auf
HTTPS mit Token. Das Muster ist also schon im Einsatz und erprobt.

### Die erzeugte Doku beschreibt das Verfahren, nicht die Person

`sync.sh:95–96` wird ersetzt durch eine Beschreibung ohne persönliche Angaben:

```
**Shopify-Repos** — GitHub, Organisation `borekDigital`.
Zugriff über den SSH-Schlüssel des eigenen GitHub-Accounts. Wer für diese Organisation
einen abweichenden Schlüssel nutzt, hinterlegt ihn lokal in `~/.ssh/config` oder über
`git config url.…insteadOf` — siehe .claude/specs/harness/git-remotes-neutral.md.
```

### Der CI-Lauf zieht mit

`.github/workflows/bauplan-refresh.yml:88` schreibt heute `git@github.com-borek:` auf HTTPS um.
Nach der Umstellung muss dort `git@github.com:` stehen. **Diese Änderung ist nicht optional:**
Bleibt die alte Zeile stehen, greift die Umschreibung nicht mehr, der Klon scheitert, und der
Lauf bricht mit „Kein einziges Repo … konnte geklont werden" ab (Zeile 166–168).

## Anforderungen

- [ ] `workspace.yaml` Zeilen 14, 24, 34: Remote auf `git@github.com:` umgestellt
- [ ] `README.md:8`: kanonisches Remote, kein vorgegebenes Zielverzeichnis
      (siehe `portabler-workspace.md`)
- [ ] `sync.sh:95–96`: Text ohne Schlüsseldateinamen und ohne persönlichen Account
- [ ] `.github/workflows/bauplan-refresh.yml:88`: `insteadOf "git@github.com:"`
- [ ] `README.md` Abschnitt „Voraussetzungen": Hinweis auf Weg A und Weg B für abweichende
      Schlüssel
- [ ] `CLAUDE.md` wird durch `sync.sh` neu erzeugt — keine Handarbeit

## Akzeptanzkriterien

- [ ] `grep -rn 'github.com-borek' --include='*.yaml' --include='*.sh' --include='*.md' .`
      liefert außerhalb von `.claude/specs/` und `docs/bauplan/` keinen Treffer
- [ ] `grep -rn 'id_ed25519\|Konrad-Thiemann' sync.sh CLAUDE.md` liefert keinen Treffer
- [ ] Ein Kollege ohne Alias in `~/.ssh/config` klont mit `./setup.sh` alle drei GitHub-Repos
- [ ] Konrad klont nach Einrichtung von Weg B weiterhin erfolgreich — geprüft an einem
      Klon nach `/tmp`
- [ ] Der CI-Lauf meldet weiterhin `geklont: 2 von 3` oder mehr; ein Lauf mit der alten
      `insteadOf`-Zeile schlägt nachweislich fehl

## Constraints

- Blast-Radius: `workspace.yaml`, `README.md`, `sync.sh`, `.github/workflows/bauplan-refresh.yml`.
  Bestehende Klone in `theme/`, `connector/`, `datalayer/` behalten ihr altes Remote in
  `.git/config` — sie funktionieren weiter, bis jemand `git remote set-url` ausführt.
- Die Umstellung des CI-Laufs und die von `workspace.yaml` gehören in **denselben** Commit.
  Getrennt gemergt bricht der nächste geplante Lauf.
- `docs/bauplan/` nennt den Alias an mehreren Stellen als Ist-Beschreibung. Diese Blattsätze
  werden durch den Staleness-Lauf ohnehin als veraltet gemeldet, sobald `workspace.yaml`
  sich ändert — dort nichts von Hand anfassen.

## Hinweis zur Reihenfolge

Vor der Umstellung prüfen, ob der **Standard**-GitHub-Account Zugriff auf `borekDigital` hat.
Falls nicht, muss Weg A oder Weg B eingerichtet sein, **bevor** `workspace.yaml` umgestellt
wird — sonst ist der eigene Workspace vorübergehend nicht klonbar.

```bash
ssh -T git@github.com          # zeigt, als wer man sich anmeldet
git ls-remote git@github.com:borekDigital/shopifyConnector.git >/dev/null && echo Zugriff
```
