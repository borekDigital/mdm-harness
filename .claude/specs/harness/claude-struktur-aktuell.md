# Spec: Claude-Struktur aktuell — Doku-Quellen und automatischer Abgleich

Stand: 16. Oktober 2026
Quelle: Analyse der Harness-Konfiguration und Recherche in der Claude-Code-Doku, 16. Oktober 2026
Status: FREIGEGEBEN (16. Oktober 2026) — B, C, D, E IMPLEMENTIERT (16. Oktober 2026); Workflows werden auf GitHub validiert (C mit dem PR, E nach dem Merge); A offen

## Ziel

Jeder Agent stützt sich auf die offizielle Doku seines Fachgebiets, und zwar in der Version, die
im Repo wirklich läuft. Weicht die Harness-Struktur (Agenten, Skills, Rules, Hooks, Settings,
MCP) vom aktuellen Stand von Claude Code oder der angebundenen Werkzeuge ab, fällt das
automatisch auf und wird gemeldet. Was übernommen wird, entscheidet weiterhin Konrad.

## Ist-Zustand

| # | Befund | Beleg | Status |
|---|---|---|---|
| 1 | Kein Agent, Skill und keine Rule verweist auf die Claude-Code- oder Claude-API-Doku | grep nach `platform.claude`, `code.claude`, `docs.anthropic`, `claude-code-guide` in `.claude/agents`, `skills`, `rules`, `CLAUDE.md`: 0 Treffer | ✅ belegt |
| 2 | Den Shopify-Doku-Abruf (`learn_shopify_api`, `search_docs_chunks`) hat nur `liquid-implementer`. `theme-planner`, `theme-reviewer` und `security-reviewer` haben ihn nicht | `agents/liquid-implementer.md:30`; grep in den drei anderen: 0 Treffer | ✅ belegt |
| 3 | `validate_theme_codeblocks` wird verlangt, der verbundene Server bietet nur `validate` und `validate_theme` | `agents/liquid-implementer.md:64`, `settings.json` (allow-Liste); Werkzeugliste der Session vom 16. Oktober 2026 | ✅ belegt |
| 4 | Shopify Dev MCP ohne festgelegte Version, deshalb wechseln Werkzeugnamen unbemerkt | `.mcp.json`: `@shopify/dev-mcp@latest` | ✅ belegt (Ursache für #3: ⚠️ Vermutung) |
| 5 | Die Agenten für Rails und Symfony verweisen nur auf die Repo-Doku, nicht auf die offizielle Doku zu Rails, Symfony, PHP, Polaris oder Nuxt | `agents/rails-*.md`, `agents/symfony-*.md` (`<repo>/docs/`) | ✅ belegt |
| 6 | Die Hyper-Doku steht nur als URL in `CLAUDE.md`, kein Agent hat den Auftrag, sie zu lesen | `CLAUDE.md:31` | ✅ belegt |
| 7 | Das Projekt setzt `model: opus` und überschreibt damit das globale `opus[1m]`. Im Workspace gilt ohne Absicht kein 1M-Kontext | `.claude/settings.json:2`, `~/.claude/settings.json`; Reihenfolge laut code.claude.com/docs/en/settings: Projekt vor User | ✅ belegt |
| 8 | Der CLI-Stand auf dem PATH war `2.1.80`, aktuell ist laut Changelog `2.1.301` (15. Oktober 2026). Am 16. Oktober 2026 per `claude update` aktualisiert. Die einzige Installation ist npm-global unter nvm Node v22.14.0, die von `claude update` gemeldete native Installation unter `~/.local/bin` existiert nicht | `claude --version`, `which -a claude`; code.claude.com/docs/en/changelog.md | ✅ belegt (behoben); welche Version die Desktop-App bündelt: ❌ unbekannt |
| 9 | `post-implement-harness-sync.sh` prüft gegen `harness-app/data.json`. `harness-app/` (ein handgepflegtes Dashboard) wurde am 10. September 2026 bewusst stillgelegt und durch den Harness-Bauplan und `bauplan-index.py` ersetzt. Dabei blieb der Hook vergessen und prüft seither ins Leere | `hooks/post-implement-harness-sync.sh:10`; Commit `cd062e0`; `sync.sh:119` | ✅ belegt |
| 10 | `settings.json` hat keinen `$schema`, Tippfehler in Schlüsseln bleiben unbemerkt | `.claude/settings.json`; Schema laut Doku: `https://json.schemastore.org/claude-code-settings.json` | ✅ belegt |
| 11 | Unbekannte Felder im Agenten-Frontmatter ignoriert Claude Code stillschweigend. Ein Tippfehler schaltet ein Feature ab, ohne Fehlermeldung | code.claude.com/docs/en/sub-agents | ✅ belegt (Doku) |
| 12 | Vier Skills nutzen `user_invocable: true`. Claude Code kennt nur `user-invocable` (Bindestrich, Default `true`), der Schlüssel ist also wirkungslos | `skills/*/SKILL.md:4`; code.claude.com/docs/en/skills.md, Frontmatter-Referenz | ✅ belegt |
| 13 | Es gibt keinen Mechanismus, der Updates von Claude Code oder Shopify Dev MCP gegen die Harness abgleicht | Bestand `bin/`, `.github/workflows/`, `hooks/` | ✅ belegt |
| 14 | Die Deny-Regel `Write(themes/*/config/settings_data.json)` greift nie, weil Claude Code Pfadregeln nur für `Edit` und `Read` prüft. Den Schutz trugen allein `Edit(...)` und der Hook | `.claude/settings.json:26`; code.claude.com/docs/en/permissions.md; Warnung von Claude Code bei der Generalprobe von E | ✅ belegt (behoben, Prüfung H17) |

## Soll-Bild

```
                 ┌──────────────────────────── Schicht 1: Doku-Quellen ───────────────────────────┐
  Agent/Skill ──►│ Claude Code: claude-code-guide · code.claude.com/docs/llms.txt                 │
                 │ Theme:       Shopify Dev MCP (feste Version) · Hyper-Doku                      │
                 │ Connector/MW: Doku-Abruf mit Versionsangabe (Rails 8.1, Symfony 7.1, PHP 8.3/7.4)│
                 └────────────────────────────────────────────────────────────────────────────────┘

  Schicht 2: Struktur-Check (deterministisch, kostenlos)
     bin/harness-check.py ── lokal, im Stop-Hook und in der CI bei jedem Push

  Schicht 3: Versions-Wächter (deterministisch, kostenlos)
     SessionStart-Hook ── installierte Version > geprüfte Version? ── Hinweis in der Session

  Schicht 4: Wöchentlicher Abgleich (Claude, mit Budgetgrenze)
     CI-Zeitplan ── Changelog-Differenz seit geprüfter Version ── claude -p (nur lesen)
                 ── Bericht ── PR „harness-stand" ── Konrad entscheidet ── Spec ── Umsetzung
```

Schicht 4 **meldet nur**. Sie ändert keine Agenten, Skills oder Settings. Das hält den Ablauf
Spec, Freigabe, Umsetzung ein.

## Anforderungen

### A — Doku-Quellen je Bereich

- [ ] Neue Rule ohne `paths`, also immer geladen: „Doku-Quellen". Sie legt je Bereich die
      maßgebliche Quelle, die Version und das Werkzeug fest. Eine Quelle muss abgefragt werden,
      bevor eine Empfehlung oder ein Plan auf API-Wissen beruht.
- [ ] Harness-Änderungen (Agenten, Skills, Rules, Hooks, Settings, MCP): vorher Abgleich mit der
      Claude-Code-Doku über `claude-code-guide` oder die `.md`-Seiten aus `llms.txt`.
- [ ] Theme: `theme-planner`, `theme-reviewer` und `security-reviewer` erhalten den Shopify-Doku-Abruf
      in ihrem Ablauf, ebenso den Verweis auf die Hyper-Doku.
- [ ] Connector und Middleware: `rails-*` und `symfony-*` fragen die offizielle Doku mit
      Versionsangabe ab. Für `creditcheck` ist PHP 7.4 ausdrücklich verpflichtend.
- [ ] Jede Quelle ist mit Werkzeug **und** Fallback (WebFetch auf die offizielle URL) angegeben,
      damit ein fehlender Connector den Agenten nicht blind arbeiten lässt.

### B — Sofort-Befunde beheben

- [x] `validate_theme_codeblocks` in Agent und allow-Liste durch den tatsächlichen Werkzeugnamen ersetzen (#3).
- [x] `@shopify/dev-mcp` auf eine feste Version setzen (#4). Hochgestuft wird nur über Schicht 4.
- [x] `$schema` in `.claude/settings.json` eintragen (#10).
- [x] Prüfung `harness-app/data.json` aus `post-implement-harness-sync.sh` entfernen. Die Prüfung gegen
      `.claude/README.md` bleibt (#9). Den veralteten Verweis in `mdm-harness-repo.md` als überholt markieren.
- [x] Skill-Frontmatter gegen die Doku prüfen und ungültige Schlüssel korrigieren (#12).
- [x] Modell im Workspace bleibt `opus` (#7, entschieden 16. Oktober 2026). Ein Kommentar im README
      erklärt, dass das globale `opus[1m]` hier absichtlich nicht greift.

### C — Struktur-Check `bin/harness-check.py`

- [x] Agenten: Pflichtfelder vorhanden, nur bekannte Frontmatter-Felder, `model` ist ein
      gültiger Alias, eine Modell-ID oder `inherit`.
- [x] Verweise: Jedes Werkzeug, jeder Agent und jeder Skill, den eine Harness-Datei nennt, existiert.
- [x] Rules: Jeder `paths`-Glob trifft mindestens eine Datei. Das YAML lässt sich parsen.
- [x] Settings: Die Validierung gegen `$schema` läuft durch.
- [x] `claude plugin validate .claude --strict` ist eingebunden, soweit es den Bestand abdeckt.
- [x] Exit-Codes wie bei `bauplan-ci.py`: 0 = sauber, 3 = Befund, alles andere = Defekt.
- [x] Die Liste der erlaubten Felder steht in **einer** Datei, die Schicht 4 als Änderungsvorschlag
      meldet. Sie ist nicht im Code verstreut.

### D — Versions-Wächter

- [x] Datei `.claude/harness-stand.json` mit den geprüften Versionen von Claude Code und
      Shopify Dev MCP und dem Datum der letzten Prüfung.
- [x] SessionStart-Hook: Ist die installierte Version von Claude Code neuer als die geprüfte, steht
      ein Hinweis im Kontext. Er nennt Versionsspanne und Changelog-URL. Kein Netzzugriff, Laufzeit unter 1 s.

### E — Wöchentlicher Abgleich in der CI

- [x] Workflow „Harness aktuell halten", gleicher Aufbau wie `bauplan-refresh.yml` (Zeitplan und `workflow_dispatch`).
- [x] Schritt 1: `harness-check.py` (Schicht 2).
- [x] Schritt 2: Changelog-Einträge von Claude Code seit der Version in `harness-stand.json` aus
      `CHANGELOG.md` (anthropics/claude-code) ziehen, dazu die Versionen von Shopify Dev MCP vergleichen.
- [x] Schritt 3: nur bei neuen Einträgen läuft `claude -p` mit Lese-Werkzeugen und `--max-budget-usd`.
      Ergebnis ist ein Bericht: welche Neuerungen, Abkündigungen oder Änderungen die Harness betreffen,
      mit Fundstelle in der Harness, Evidenz-Label und Vorschlag.
- [x] Schritt 4: PR auf Branch `harness/stand` mit Bericht und hochgezählter `harness-stand.json`.
      Kein anderer Pfad im PR.
- [x] Ein roter Lauf zeigt seine Ursache im Log (Lehre aus `bauplan-ci-auffrischung.md`).

## Akzeptanzkriterien

- [ ] grep nach Doku-Quelle in jedem Agenten: alle 12 Agenten nennen mindestens eine Quelle mit Werkzeug.
- [x] `bin/harness-check.py` auf dem heutigen Stand meldet mindestens #3, #9 und #10 mit Exit 3.
      Nach Teil B endet er mit Exit 0.
- [x] Ein absichtlich eingebautes falsches Agenten-Feld (`modle: opus`) wird mit Datei und Zeile gemeldet.
- [x] Wird `harness-stand.json` auf eine ältere Version gesetzt, zeigt eine neue Session den Hinweis.
      Bei gleicher Version bleibt sie still. (Hook-Ausgabe belegt; wie die App `systemMessage` beim Start anzeigt: ❌ ungeprüft, siehe Umsetzung D)
- [ ] Ein manueller CI-Lauf mit älterer geprüfter Version öffnet einen PR, der nur Bericht und
      `harness-stand.json` enthält. Jeder Befund im Bericht hat eine Fundstelle.
- [ ] Ein CI-Lauf ohne neue Changelog-Einträge startet Claude nicht und endet grün.

## Constraints

- Schicht 4 schreibt nie in `agents/`, `skills/`, `rules/`, `hooks/` oder `settings*.json`.
- Kosten: Claude läuft nur bei Änderungen und mit Budgetgrenze. Schichten 2 und 3 kosten keine Tokens.
- Vorhandenes Secret `CLAUDE_CODE_OAUTH_TOKEN` weiterverwenden, kein neues Konto.
- An externe Doku-Dienste gehen nur Bibliotheksname, Version und Frage. Code oder Kundendaten gehen nie hinaus.
- Die Rules aus A werden in `templates/` gepflegt, falls `sync.sh` sie erzeugt. Sonst direkt in `.claude/rules/`.

## Entscheidungen (Konrad, 16. Oktober 2026)

1. Modell im Workspace: `opus` bleibt (#7).
2. Rhythmus von Schicht 4: wöchentlich.
3. Bericht als PR.
4. Doku-Connector im Stil von Context7 ist die Standardquelle für Rails, Symfony und PHP, mit WebFetch als Fallback.
5. `harness-app/data.json`: Vorschlag ist, die Prüfung zu entfernen, weil `harness-app/` bewusst stillgelegt wurde. Konrad bestätigt noch.

## Umsetzung

### B — 16. Oktober 2026

| Befund | Änderung | Nachweis |
|---|---|---|
| #3 | `liquid-implementer.md:64` nutzt jetzt `validate_theme`. In der allow-Liste ersetzt `validate` (GraphQL, Polaris, Functions) den toten Namen | Werkzeugliste von dev-mcp 1.16.1: `validate`, `validate_theme`, `learn_shopify_api`, `search_docs_chunks`, `feedback` |
| #4 | `.mcp.json`: `@shopify/dev-mcp@1.16.1` (am 16. Oktober 2026 auch `latest`) | `npm view @shopify/dev-mcp version` |
| #7 | `opus` bleibt, Begründung in `.claude/README.md`, Abschnitt Agents | — |
| #9 | Hook prüft nur noch gegen `.claude/README.md`; `mdm-harness-repo.md` mit Hinweis „teilweise überholt" | Positivlauf: still, Exit 0. Negativlauf mit erfundenem Agenten: Warnung, Exit 0 |
| #10 | `$schema` in `.claude/settings.json` | Validierung gegen das SchemaStore-Schema: 0 Fehler |
| #12 | `user_invocable: true` aus vier Skills entfernt (Default ist ohnehin `true`) | `claude plugin validate .claude --strict`: bestanden; alle vier Skills nach der Änderung weiter geladen |

### C — 16. Oktober 2026

| Teil | Ort |
|---|---|
| Prüfskript | `bin/harness-check.py` (nur Standardbibliothek; `jsonschema` und `claude` optional) |
| Referenz | `bin/harness-referenz.json`: Feldlisten, Modelle, 33 Hook-Events, MCP-Werkzeuge und -Version, Agenten-Rollen, externe Skills; Quellen-URLs und Stand darin |
| Tests | `bin/test_harness_check.py`, 25 Tests: je Befund-Code ein Fixture-Fall, dazu der echte Bestand |
| Stop-Hook | `.claude/hooks/harness-check.sh` (offline, async, schweigt wenn sauber) |
| CI | `.github/workflows/harness-check.yml` bei Push und PR auf Harness-Pfade |

| Code | Prüfung |
|---|---|
| H00 | Frontmatter nicht lesbar |
| H01–H03 | Agent: Pflichtfeld fehlt, unbekanntes Feld, ungültiges Modell |
| H04 | Skill: unbekanntes Feld |
| H05–H06 | Rule: unbekanntes Feld, Glob ohne Treffer (fehlendes Repo oder leeres Platzhalter-Verzeichnis: übersprungen) |
| H07–H09 | Settings: `$schema` fehlt, unbekanntes Hook-Event, Hook-Skript fehlt |
| H10 | Hook-Skript verweist auf eine Datei unter `${CLAUDE_PROJECT_DIR}`, die es nicht gibt |
| H11 | MCP-Werkzeug unbekannt (voller Name `mcp__…` oder Name in einer Zeile oder einem Abschnitt zum Dev MCP) |
| H12 | npx-MCP-Server ohne feste Version oder abweichend von der Referenz |
| H13 | Verweis auf `/skill`, den es nicht gibt |
| H14 | `claude plugin validate .claude --strict` schlägt fehl |
| H15 | `settings.json` verletzt das SchemaStore-Schema |
| H16 | Verweis auf einen Agenten (`*-planner`, `-implementer`, `-reviewer`, `-writer`, `-extractor`), den es nicht gibt |

Nachweise:
- Rückprobe auf den Stand vor Teil B (`HEAD~1` von `97c2186`): 9 Befunde, Exit 3. Darunter #3 (H11, zweimal), #4 (H12), #9 (H10), #10 (H07) und #12 (H04, viermal).
- Heutiger Stand: offline und online (mit Schema und `plugin validate`) „Harness sauber", Exit 0.
- `modle: opus`: als H02 mit `datei:4` gemeldet (Test `test_unbekanntes_agentenfeld`, `test_textausgabe_nennt_datei_und_zeile`).
- Grenze: H11 erkennt Werkzeugnamen ohne `mcp__`-Präfix nur in Zeilen oder Abschnitten, die „Dev MCP" oder „shopify-dev-mcp" nennen.

### D — 16. Oktober 2026

**Abweichung von der Spec:** Statt einer eigenen `.claude/harness-stand.json` stehen geprüfte Version
und Stand in `bin/harness-referenz.json` (`claude_code_version`, `stand`). Die Feldlisten dort
beschreiben genau diesen Doku-Stand. Zwei Dateien könnten auseinanderlaufen. Die Version von Shopify Dev MCP
stand dort schon (`mcp_server`). Überall, wo die Spec `harness-stand.json` nennt, ist die Referenzdatei gemeint.

| Teil | Ort |
|---|---|
| Skript | `bin/harness-stand.py` mit `hinweis`, `changelog`, `neueste`, `prompt` und `anheben` |
| Tests | `bin/test_harness_stand.py`, 13 Tests |
| Hook | `.claude/hooks/harness-stand.sh`, SessionStart mit Matcher `startup`, synchron, Laufzeit 0,03 s |

Nachweise:
- Gleiche Version: keine Ausgabe. Kopie mit geprüfter Version 2.1.290: JSON mit `systemMessage` und
  `additionalContext`, beide mit 2.1.301, 2.1.290 und Changelog-URL.
- Versionen werden als Zahlen verglichen: 2.1.80 ist älter als 2.1.301.
- ❌ Wie die Desktop-App `systemMessage` bei SessionStart darstellt, ist ungeprüft (die Doku legt es nicht fest).
  `additionalContext` erreicht Claude in jedem Fall.

### E — 16. Oktober 2026

| Teil | Ort |
|---|---|
| Workflow | `.github/workflows/harness-aktuell.yml`, montags 04:41 UTC, `workflow_dispatch` mit Eingabe `seit` |
| Bericht | `.claude/harness-bericht.md` (je Lauf überschrieben) |
| PR | Branch `harness/stand`, nur Bericht und `bin/harness-referenz.json` |

- `claude -p` liest den Auftrag über stdin und darf nur `Read Glob Grep WebFetch` nutzen, mit `--max-budget-usd 5`.
  Bei Fehlern werden stdout und stderr ausgegeben.
- Kein `--bare`, weil es nur `ANTHROPIC_API_KEY` liest und kein OAuth-Token (`claude --help`).
- Generalprobe lokal mit `--seit 2.1.300`: Exit 0 und ein Bericht mit 7 Befunden, jeder mit Fundstelle und
  Evidenz-Label. Ohne `seit` (nichts neu): `changelog` endet mit 0, Claude startet nicht.
- Aus der Generalprobe übernommen: #14 (H17).
- Abgelehnt: Der Bericht schlug vor, den Alias `best` in `modell_aliase` aufzunehmen. `best` ist ein
  Alias für die Sitzung (model-config.md), steht aber nicht unter den erlaubten Werten für `model`
  bei Subagenten (sub-agents.md:310). Die Referenz bleibt so. Das zeigt, warum der Lauf nur meldet.
- ❌ Zeitplan und `workflow_dispatch` greifen erst, wenn der Workflow auf `main` liegt. Die zwei
  CI-Akzeptanzkriterien werden deshalb nach dem Merge mit einem manuellen Lauf (`seit = 2.1.290`) validiert.

Außerhalb des Repos gemeldet, nicht geändert: Claude Code warnt, dass
`Bash(cd themes/* && shopify theme:*)` in der persönlichen `.claude/settings.local.json` nie greift
(`*` vor `:*` wird nicht expandiert).
