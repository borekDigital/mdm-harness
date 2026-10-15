# Spec: Theme-Sync per CI — MDM main als PR nach Borek und IMM

## Ziel

Jeder neue Stand von MDM `main` erscheint ohne Handarbeit als Pull Request in Borek und IMM,
Titel `sync/theme-mdm: …`, mit einer Beschreibung, die sagt, was mitkommt, was nicht, und was
dabei im Ziel überschrieben wird. Gemergt wird weiter von Hand — ein Merge auf `main` ist ein
Deploy.

## Grundlage

- Frage von Konrad am 15. Oktober 2026 („Theme-/Template-Sync in der MDM-CI auf main, der einen
  PR für IMM und Borek erstellt“). Vorgabe dazu: keine Sperre der Gegenrichtung, aber jede
  Gegenrichtung bzw. jedes Überschreiben von Ziel-Änderungen ausdrücklich melden.
- Baut auf `theme-sync.md` (Skript) und `../themes/templates-angleichen-plp-pdp.md` (geteilte
  Templates) auf.

## Ist-Stand

| Befund | Beleg |
|---|---|
| ✅ Keines der drei Theme-Repos hat eine CI | `git ls-tree origin/main -- .github` leer in mdm, borek, imm (15.10.2026) |
| ✅ Ein `.github/`-Ordner im MDM-Theme stört den Store nicht | Shopify: „Folders in the repository that don't match the default theme structure are ignored.“ |
| ✅ Die Sync-Logik liegt im Harness, nicht im Theme | `borekDigital/mdm-harness`, `bin/theme-sync.sh` |
| ✅ Borek- und IMM-`main` sind an einen Store gekoppelt | Bot-Commits „Update from Shopify for theme shopifyFrontend_Borek/main“; seit 15.09.: Borek 74, IMM 83 |
| ✅ Der Bot schreibt im Ziel auch geteilte Templates | Borek 2× `collection.json`; IMM 4× `collection.json`, 2× `product.json`; zuletzt IMM 15.10., 07:45–07:55 UTC |
| ✅ `GITHUB_TOKEN` reicht nicht für PRs in anderen Repos | create-pull-request, „Creating pull requests in a remote repository“ |
| ✅ PRs mit `GITHUB_TOKEN` lösen keine Workflows aus; App-Token schon | create-pull-request, concepts-guidelines |
| ❌ Ist Borek-/IMM-`main` das veröffentlichte Theme (Merge = live)? | nur im Store-Admin prüfbar |
| ❌ Wer ist Owner der Organisation `borekDigital` (für eine GitHub App)? | GitHub-Org-Einstellungen |
| ❌ Branch-Protection in Borek und IMM | GitHub-Repo-Einstellungen |

## Lösung

```
push auf MDM main ─► Workflow im MDM-Theme (Matrix: borek, imm)
   1. App-Token holen (Zugriff: Ziel-Repo schreiben, Harness lesen)
   2. auschecken: MDM (volle Historie), Ziel (main), Harness
   3. theme-sync.sh align mdm <ziel>  → Arbeitsbaum des Ziels auf MDM-Stand, Bericht als Markdown
   4. kein Unterschied?  → offenen Sync-PR schließen, fertig
   5. sonst: Commit auf rollenden Branch sync/theme-mdm, force-push
   6. PR anlegen oder Titel/Beschreibung aktualisieren (gh)
   7. Merge von Hand
```

### Zustand statt Commit

| | Commit-basiert (`port --as-patch` je Push) | Zustandsbasiert (`align`, Vorschlag) |
|---|---|---|
| Was wandert | nur die Hunks des gepushten Commits | alles, worin das Ziel vom MDM-Stand abweicht |
| Ziel hat eigene Änderung | Patch passt oft nicht → Ziel übersprungen, Änderung kommt nie an | wird überschrieben **und gemeldet** (W1) |
| Verpasster Lauf, Konflikt mit Bot-Commit | Lücke bleibt | nächster Lauf holt alles nach |
| Shopify-Bot-Commits auf MDM-`main` | je einer ein eigener Patch | landen im nächsten Stand |
| Ziel „gleicher Stand in allen drei Shops“ (Call 15.10.) | nur näherungsweise | genau das |

### Rollender Branch, ein PR je Ziel

- Branch `sync/theme-mdm` in Borek und IMM, bei jedem Lauf neu von Ziel-`main` aus gebaut und
  force-gepusht. Es gibt höchstens einen offenen Sync-PR je Ziel; jeder MDM-Push aktualisiert ihn.
- Titel: `sync/theme-mdm: MDM main @ <sha7> (<TT.MM.JJJJ>)`.
- Commit im Ziel: `chore(sync): align with mdm main <sha7>`. Der letzte übernommene MDM-Stand wird
  aus der Ziel-Historie gelesen (Titel- bzw. Commit-Muster), daraus „MDM-PRs seit dem letzten Sync“.
- Der Branch wird nie gelöscht. So kann er als Vorschau-Theme im Store gekoppelt bleiben (O2).

### PR-Beschreibung (Vorlage)

```markdown
Übernimmt den Stand von MDM main @ a1f767d (15. Oktober 2026).

## Enthalten
MDM-PRs seit dem letzten Sync: #45, #46, #47
| Datei | Änderung |
|---|---|
| assets/mdm-collection.css | geändert |
| templates/collection.json | geändert, Layout borek-theme |

## ⚠️ Prüfen: Änderungen im Ziel, die dieser Sync überschreibt
| Datei | letzte Änderung in Borek | von |
|---|---|---|
| templates/collection.json | 15.10.2026, 07:55 | Theme-Editor (bhavani govindan) |
Gewollt (Borek folgt MDM) oder Fehler (Änderung gehört erst nach MDM)?

## Nicht übertragen (markenspezifisch)
- locales/de.json: 3 neue Schlüssel in MDM fehlen in Borek: mdm.key_facts.weight, …
- layout/mdm-theme.liquid seit dem letzten Sync geändert

## Nur in Borek vorhanden
- blocks/ai_gen_block_3b58b63.liquid

## Vor dem Merge
- [ ] Vorschau im Store geprüft
- [ ] Merge ist ein Deploy auf das an main gekoppelte Theme
```

### Warnungen (Gegenrichtung melden, nicht sperren)

| Nr. | Fall | Erkennung |
|---|---|---|
| W1 | Das Ziel hat eine eigene Änderung, die der Sync überschreibt (Ziel-PR oder Theme-Editor) | Ziel-Blob kommt in der MDM-Historie derselben Datei nicht vor (`git log --raw`); geteilte Templates mit neutralisiertem `layout`. Angabe: letzter Ziel-Commit, Autor bzw. „Theme last edited by“ |
| W2 | Geteiltes Template wurde in MDM im Theme-Editor geändert | Bot-Commits in MDM seit dem letzten Sync, die geteilte Templates berühren |
| W3 | MDM hat markenspezifische Dateien geändert, die nicht mitgehen | `locales/*` (Schlüssel-Abgleich, fehlende Schlüssel einzeln), `config/settings_schema.json`, `layout/*`, `sections/*-group.json` |
| W4 | Dateien nur im Ziel (z. B. in MDM gelöscht) | Abgleich der Dateilisten; nichts wird gelöscht |
| W5 | Lokal: Port mit Quelle `borek`/`imm` | Hinweis in der Ausgabe von `port` (später, nicht Teil dieser CI) |

## Anforderungen

- [ ] R1 `bin/theme-sync.sh align <quelle> <ziel[,ziel]>` bringt den Arbeitsbaum des Ziels für alle
      gemeinsamen, nicht markenspezifischen Dateien und die geteilten Templates auf den Stand der
      Quelle (Templates mit Ziel-Layout), legt neue Quelldateien an und löscht nichts.
- [ ] R2 `align --report <datei>` schreibt die PR-Beschreibung nach obiger Vorlage, inklusive W1–W4.
      Keine Erwähnung von KI-Werkzeugen.
- [ ] R3 Workflow `.github/workflows/theme-sync.yml` im MDM-Theme: Auslöser Push auf `main` und
      `workflow_dispatch`; ein Lauf zur Zeit (`concurrency`); Matrix borek, imm, unabhängig voneinander.
- [ ] R4 Je Ziel genau ein offener PR auf `sync/theme-mdm`; Titel und Beschreibung bei jedem Lauf
      aktuell; ohne Unterschied wird ein offener Sync-PR geschlossen.
- [ ] R5 Kein Push auf Ziel-`main`, kein Auto-Merge, kein Approve.
- [ ] R6 Token über eine GitHub App mit `contents: write` und `pull-requests: write` auf genau den
      Ziel-Repos, `contents: read` auf `mdm-harness`. Private Key nur als Secret.
- [ ] R7 `bin/test-theme-sync.sh` deckt `align` und die Warnungen W1–W4 ab.

## Akzeptanzkriterien

- [ ] A1 Testlauf per `workflow_dispatch`: je ein PR in Borek und IMM, Titel nach Muster, Basis `main`.
- [ ] A2 Zweiter Lauf nach einem weiteren MDM-Commit: derselbe PR, neuer Titel-SHA, neue
      Beschreibung, kein zweiter PR.
- [ ] A3 Lauf ohne Unterschied: kein neuer PR; ein offener Sync-PR wird geschlossen.
- [ ] A4 W1 nachgestellt (Editor-Änderung an `collection.json` im Ziel): Datei steht im
      Warnabschnitt mit Autor; der PR wird trotzdem erstellt.
- [ ] A5 W3 nachgestellt (neuer Locale-Schlüssel in MDM): Schlüssel steht unter „Nicht übertragen“.
- [ ] A6 Weder Workflow-Log noch PR enthalten den Private Key oder das Token.
- [ ] A7 Ziel-`main` bleibt unberührt, bis Konrad mergt.

## Constraints

- Sperre der Gegenrichtung ausdrücklich **nicht** einbauen (Konrad, 15.10.2026) — nur melden.
- Keine KI-Spuren in Workflow, Skript, Commits, PR-Texten.
- Skript bleibt Bash-3.2-tauglich (lokal macOS), CI läuft auf `ubuntu-latest`.
- Versionen der Actions bei der Umsetzung festnageln; recherchiert am 15.10.2026:
  `actions/create-github-app-token@v3`, `peter-evans/create-pull-request@v8` (Alternative zu `gh`).
- Vor dem Start der CI die heute vorbereiteten Branches (PLP, PDP) von Hand mergen; sonst
  enthält der erste Sync-PR dieselben Änderungen noch einmal.

## Offene Punkte

- O1 GitHub App (empfohlen: feine Rechte, Bot als Autor, löst PR-Checks aus) oder Fine-grained
  PAT von Konrad (schneller, aber persönlich, läuft ab, PR-Autor = Konrad). App braucht einen
  Org-Owner von `borekDigital`.
- O2 Vorschau: Branch `sync/theme-mdm` je Store als unveröffentlichtes Theme koppeln
  (GitHub-Integration). Jeder Lauf aktualisiert die Vorschau. Shopify: Eine getrennte Kopplung
  lässt sich nicht wiederherstellen, deshalb den Branch nie löschen. Editor-Änderungen an diesem
  Vorschau-Theme überschreibt der nächste Lauf.
- O3 Auslöser jeder Push (inkl. Bot-Commits, mehrmals täglich) oder nur gemergte PRs? Vorschlag:
  jeder Push — der rollende PR fängt das ab.
- O4 Sprache der PR-Beschreibung — Vorschlag Deutsch.
- O5 Reviewer: Konrad; Bhavani zusätzlich?
- O6 In MDM gelöschte Dateien: nur melden (Vorschlag) oder im Ziel löschen?
- O7 `shopify theme check` im Ziel-Branch als zusätzlicher Schritt (Node + Shopify CLI) — Phase 2.

## Skizze des Workflows (nicht final)

```yaml
name: Theme-Sync nach Borek und IMM
on:
  push:
    branches: [main]
  workflow_dispatch:
concurrency:
  group: theme-sync
  cancel-in-progress: false
permissions:
  contents: read
jobs:
  sync:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        include:
          - { brand: borek, repo: shopifyFrontend_Borek }
          - { brand: imm, repo: shopifyFrontend_IMM }
    steps:
      - uses: actions/create-github-app-token@v3
        id: app
        with:
          client-id: ${{ vars.THEME_SYNC_APP_CLIENT_ID }}
          private-key: ${{ secrets.THEME_SYNC_APP_PRIVATE_KEY }}
          owner: borekDigital
          repositories: |
            ${{ matrix.repo }}
            mdm-harness
          permission-contents: write
          permission-pull-requests: write
      - uses: actions/checkout@v5
        with: { path: themes/mdm, fetch-depth: 0 }
      - uses: actions/checkout@v5
        with:
          repository: borekDigital/${{ matrix.repo }}
          path: themes/${{ matrix.brand }}
          token: ${{ steps.app.outputs.token }}
          fetch-depth: 0
      - uses: actions/checkout@v5
        with:
          repository: borekDigital/mdm-harness
          path: harness
          token: ${{ steps.app.outputs.token }}
      - name: Stand abgleichen
        env:
          THEME_SYNC_THEMES_DIR: ${{ github.workspace }}/themes
        run: harness/bin/theme-sync.sh align mdm ${{ matrix.brand }} --report "$RUNNER_TEMP/body.md"
      - name: PR anlegen oder aktualisieren
        working-directory: themes/${{ matrix.brand }}
        env:
          GH_TOKEN: ${{ steps.app.outputs.token }}
        run: |
          # Commit auf sync/theme-mdm, force-push, dann gh pr create bzw. gh pr edit
          # mit --title "sync/theme-mdm: MDM main @ ${GITHUB_SHA::7} (…)" --body-file "$RUNNER_TEMP/body.md"
```

## Aufwand (Schätzung)

| Teil | Wer | Umfang |
|---|---|---|
| `align` + Bericht + Tests im Harness | Umsetzung | etwa ein Tag |
| Workflow im MDM-Theme | Umsetzung | etwa ein halber Tag |
| GitHub App anlegen, auf drei Repos installieren, Secret/Variable setzen | Org-Owner | etwa 15 Minuten |
| Vorschau-Themes koppeln (O2) | Store-Admin Borek, IMM | je etwa 5 Minuten |

## Quellen

- Shopify GitHub-Integration: https://shopify.dev/docs/storefronts/themes/tools/github
- create-pull-request (v8, Remote-Repo, Token-Arten): https://github.com/peter-evans/create-pull-request
- create-github-app-token (v3, `owner` + `repositories`, `permission-*`): https://github.com/actions/create-github-app-token

## Entscheidungen bei der Freigabe — 15. Oktober 2026

- Spec freigegeben. Zugang über **Fine-grained PAT** von Konrad (O1), nicht über eine GitHub App.
- ✅ Borek- und IMM-`main` sind die veröffentlichten Themes: ein Merge geht live.
- Konrad ist Owner der Organisation `borekDigital` (kann den PAT für die Org freigeben).

## Umsetzung — 15. Oktober 2026

| Repo | Branch / Ort | Datei | Inhalt |
|---|---|---|---|
| mdm-harness | Arbeitsbaum `~/MDM` | `bin/theme-sync.sh` | Kommando `align` mit `--branch`, `--report`; Warnungen W1–W4; `config/markets.json` markenspezifisch |
| mdm-harness | Arbeitsbaum `~/MDM` | `bin/test-theme-sync.sh` | 36 neue Prüfungen für `align`, insgesamt 50 |
| MDM | `ci/theme-sync`, Worktree `themes/.worktrees/mdm-theme-sync-ci` | `.github/workflows/theme-sync.yml` | Workflow nach der Skizze, mit `gh` statt `create-pull-request` |
| MDM | dito | `.shopifyignore` | `.github/` ergänzt |

Abweichungen von der Skizze:

- **Schalter `THEME_SYNC_ENABLED`** (Repo-Variable): Der Push-Auslöser läuft erst, wenn sie `true`
  ist; von Hand (`workflow_dispatch`) immer. Grund: Der Merge des Workflows selbst ist ein Push
  auf MDM-`main` und hätte sonst sofort PRs in beiden Shops geöffnet.
- `actions/checkout@v7` (aktuell v7.0.1, 20. Juli 2026); kein App-Token-Schritt.
- PR anlegen, ändern, schließen über `gh` — Titel und Beschreibung werden bei jedem Lauf sicher
  überschrieben (bei `create-pull-request` nicht belegt).
- Zeiten im Bericht in Ortszeit (`TZ=Europe/Berlin`), sonst stünden Bot-Commits in UTC da.
- `blocks/ai_gen_block_*` werden **mit** übertragen: MDM-Seiten-Templates verweisen auf
  `ai_gen_block_96dbfd1`, dieselben Templates liegen in Borek/IMM ohne die Block-Datei.
- Commit-Autor im Ziel `github-actions[bot]`, PR-Autor ist der PAT-Inhaber (Konrad). Kein Reviewer
  gesetzt: Den eigenen Account kann GitHub nicht als Reviewer eintragen (O5 bleibt offen).

## Validierung — 15. Oktober 2026

| AC | Ergebnis |
|---|---|
| R1, R2, R7 | erfüllt — `bin/test-theme-sync.sh` 50/50 grün (Bash 3.2) |
| A1–A3 | lokal nachgestellt — Sandbox mit Kopien der echten Repos (`origin/main`), Bare-Repo als `origin`, `gh` als Stub: Lauf 1 `gh pr create`, Lauf 2 `gh pr edit 21` + force-push, Lauf 3 ohne Unterschied `gh pr close 21`. Auf GitHub offen bis zum ersten `workflow_dispatch` |
| A4 | erfüllt im Probelauf — Borek: 4 geteilte Templates als eigene Änderung gemeldet, u. a. `collection.json` „Theme-Editor (E-Business IT)“ 15.10.2026 09:45; IMM: `collection.json` „Theme-Editor (bhavani govindan)“ 09:55 |
| A5 | erfüllt im Test (`mdm.neu` gemeldet, `shopify.*` ausgenommen) |
| A6 | erfüllt laut Aufbau — Token nur über `secrets`, nie ausgegeben; Prüfung im ersten echten Lauf |
| A7 | erfüllt laut Aufbau — Push nur auf `refs/heads/sync/theme-mdm`, kein Merge-Befehl |

Probelauf des ersten PRs (Sandbox, MDM inklusive der beiden vorbereiteten MDM-Branches): je Ziel
7 Dateien — 2 CSS, `ai_gen_block_96dbfd1`, 4 geteilte Templates; „Nur in IMM“: `assets/base.css`.

## Inbetriebnahme (Konrad)

1. Harness-Änderungen committen und nach `mdm-harness/main` bringen — der Workflow checkt dessen
   Standard-Branch aus.
2. Fine-grained PAT anlegen (Resource owner `borekDigital`; Repos `shopifyFrontend_Borek`,
   `shopifyFrontend_IMM`, `mdm-harness`; Contents und Pull requests: Read and write). Hinweis: Die
   Rechte gelten für alle drei Repos, also auch Schreibrecht auf `mdm-harness`.
3. Secret setzen: `pbpaste | tr -d '\n\r ' | gh secret set THEME_SYNC_TOKEN -R borekDigital/shopifyFrontend_MDM`.
4. MDM `ci/theme-sync` mergen (Variable noch nicht gesetzt → der Push-Lauf wird übersprungen).
5. Reihenfolge PLP → PDP (E3): erst die vorbereiteten PLP-Branches in Borek/IMM mergen und abnehmen
   — oder den ersten Sync-PR bewusst PLP und PDP zusammen bringen lassen.
6. Testlauf: `gh workflow run theme-sync.yml -R borekDigital/shopifyFrontend_MDM`.
7. Danach `gh variable set THEME_SYNC_ENABLED --body true -R borekDigital/shopifyFrontend_MDM`.

## Status

IMPLEMENTIERT — 15. Oktober 2026 (Commits, Secret und erster Lauf auf GitHub offen)
