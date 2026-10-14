# Spec: Bauplan-CI — Auffrischung lauffaehig und Fehler sichtbar

Stand: 14. Oktober 2026
Quelle: Analyse der roten Laeufe von „Bauplan auffrischen", 14. Oktober 2026
Status: A–E VALIDIERT (14. Oktober 2026) — A–D mit PR #4, E mit PR #5, erster gruener Lauf 38550625855, Auffrischungs-PR #6 gemergt; F IMPLEMENTIERT, Validierung durch den naechsten Auffrischungslauf — siehe „Umsetzung" am Ende

## Ziel

Der Workflow „Bauplan auffrischen" baut veraltete Etappen tatsaechlich neu. Scheitert der
Neubau, steht die Ursache im Log, und niemand muss sie raten.

## Ist-Zustand

```
Zeitplan ─► Bericht (rc=3) ─► claude -p ─► Exit 1 nach ~5 s ─► Job rot
                                   │
                                   └─ Fehlermeldung auf stdout ─► vom Skript verworfen
```

Der Schritt „Betroffene Etappen neu bauen" hat **noch nie** funktioniert. Gruen waren nur
Laeufe, in denen nichts veraltet war — dann startet der Schritt gar nicht.

| # | Befund | Beleg | Status |
|---|---|---|---|
| 1 | Alle 18 roten Zeitplan-Laeufe seit dem 11. September 2026 scheitern im Schritt „Betroffene Etappen neu bauen" | `gh run view <id> --json jobs` fuer jeden roten Lauf | ✅ belegt |
| 2 | Die Fehlermeldung von Claude fehlt im Log. Das Skript gibt bei Fehlern nur stderr aus, `claude -p` schreibt Fehler auf stdout | `bin/bauplan-ci.py:93`; lokal nachgestellt: ungueltiges Token → Exit 1, „401 authentication_error" nur auf stdout, stderr leer | ✅ belegt |
| 3 | Ursache des Exit 1: Bei Claude kommt kein verwertbares Token an. Nach dem Fix aus Teil A meldet das Log „Not logged in". Diese Meldung erzeugt CLI 2.1.299 (die Runner-Version) nur bei fehlendem, leerem oder nur aus Leerraum bestehendem Token. Ein falsches Token ergibt dagegen 401. **Korrektur:** Die erste Annahme „abgelehntes Token (401)" war falsch. Seit das Secret am 14. Oktober 2026 um 10:40 Uhr ueber die Zwischenablage gesetzt wurde (geprueft: Laenge 108, lokaler Test „OK"), meldet sich Claude auf dem Runner erfolgreich an | Lauf 38536107837 („Not logged in"); lokale Proben mit 2.1.299; Lauf 38536814197 (Claude zweimal Exit 0) | ✅ belegt fuer 14. Oktober 2026, ⚠️ fuer die Laeufe davor vermutet (ohne Teil A war die Meldung nicht sichtbar) |
| 4 | Claude fehlen im CI-Lauf die Shell-Rechte. Gestartet wird nur mit `--permission-mode acceptEdits`. Der Refresh-Abschnitt braucht `bin/bauplan-stale.py`, `bin/bauplan-wording.py` und `git -C . diff`. Keiner dieser Befehle steht in der Allow-Liste, und der Runner ignoriert die Allow-Liste ohnehin („Ignoring 17 permissions.allow entries … not trusted") | `bin/bauplan-ci.py:81`; `SKILL.md:132`, `:274`, `:283`; `.claude/settings.json:4–19`; Runner-Log | ✅ fehlende Rechte belegt, ⚠️ Wirkung auf den Lauf vermutet |
| 5 | Der Guard blockiert den Schreibweg des Skills. Phase 2e legt Blaetter per Shell-Umleitung `> docs/bauplan/…` ab, und `bauplan-guard.sh` blockiert jeden Bash-Befehl, der `>` und `docs/bauplan` enthaelt | `SKILL.md:165–168`; `.claude/hooks/bauplan-guard.sh:28–29`; am 14. Oktober 2026 live ausgeloest | ✅ belegt |
| 6 | Das `Artifact`-Werkzeug ist im Headless-Lauf auf dem Runner **nicht** verfuegbar. Das HTML im Repo wird aktuell, die Seiten auf claude.ai muessen nach dem Merge des Auffrischungs-PRs von Hand neu veroeffentlicht werden | Claudes Antwort in Lauf 38546913702 (dank D2): „Das `Artifact`-Werkzeug ist in dieser Sitzung nicht verfuegbar" | ✅ belegt |
| 7 | Die Pruefung „nur Erlaubtes geaendert" vergleicht immer kumuliert mit `HEAD`. Beim zweiten Repo gelten deshalb die Aenderungen des ersten als „ausserhalb des Auftrags", und der Lauf bricht ab. Der Connector-Teil hatte genau seine vier veralteten Blaetter geaendert | `bin/bauplan-ci.py:131–136`, Schleife ab `:178`; Laeufe 38536814197 und 38543367343, beide mit ABBRUCH beim harness-Teil, gelistet waren nur Connector-Dateien | ✅ belegt |
| 8 | Dieselbe Pruefung sieht neu angelegte Dateien nicht, denn `git diff --name-only` listet keine untracked Dateien | `bin/bauplan-ci.py:133` | ✅ belegt |
| 9 | Nach **erfolgreichem** Neubau endet `bauplan-ci.py --regenerate` mit Exit 3, denn `main()` gibt 3 zurueck, sobald es Veraltetes gab. Der Workflow-Schritt wertet jeden Exit-Code ungleich 0 als Fehler, deshalb werden „Uebersicht neu erzeugen" und „Pull Request oeffnen" uebersprungen und die Arbeit des Laufs geht verloren | `bin/bauplan-ci.py:262`; `bauplan-refresh.yml:204–207`; Laeufe 38546913702 und 38547251030: beide Repos aufgefrischt, dann „exit code 3" | ✅ belegt |

## Anforderungen

### A. Fehler sichtbar machen

- [x] Endet `claude -p` mit einem Exit-Code ungleich 0, gibt `bauplan-ci.py` das Ende
      **beider** Ausgaben (stdout und stderr) im Log aus, jeweils laengenbegrenzt.
- [x] Zeitueberschreitung und fehlende CLI werden weiterhin gesondert gemeldet (wie heute).

### B. Rechte fuer den Refresh

- [x] Der CI-Aufruf von Claude erlaubt ausdruecklich die Befehle, die der Refresh-Abschnitt
      verlangt: `bin/bauplan-stale.py`, `bin/bauplan-wording.py` und lesende Git-Befehle
      (`diff`, `log`, `show`, `rev-parse`).
- [x] Keine pauschale Bash-Freigabe, kein `bypassPermissions`, kein
      `--dangerously-skip-permissions`.

### C. Schreibweg im Refresh

- [x] Der Abschnitt „Auffrischen — nur das Veraltete" in `SKILL.md` legt fest: Eine
      bestehende Etappe wird per Edit an ihrer HTML-Datei angepasst, nicht ueber Phase 2e
      neu zusammengesetzt.
- [x] Die Regel des Guards bleibt unveraendert.

### D. Pruefung je Repo und Antwort im Log

Ergaenzt am 14. Oktober 2026 nach dem ersten Lauf mit gueltigem Token (Befunde 6–8).

- [x] D1: Die Pruefung je Repo zaehlt nur Dateien, die der Claude-Lauf **dieses** Repos
      geaendert, angelegt oder geloescht hat. Aenderungen frueherer Repos im selben Lauf
      zaehlen nicht. Aendert ein spaeterer Lauf eine schon geaenderte Datei erneut, zaehlt
      das sehr wohl.
- [x] D1: Neu angelegte Dateien unter `docs/bauplan` und `.claude/bauplan` werden erfasst,
      gitignorierte (`CI-BERICHT.json`, `*.STALE.md`) nicht.
- [x] D2: Auch bei Erfolg steht das Ende von Claudes Antwort im Log, laengenbegrenzt.

### E. Exit-Code nach dem Neubau

Ergaenzt am 14. Oktober 2026 nach dem ersten Lauf auf `main` (Befund 9).

- [x] E1: `bauplan-ci.py --regenerate` endet mit 0, wenn alle veralteten Etappen
      erfolgreich neu gebaut wurden, und mit 1, wenn ein Repo scheitert oder der
      Bestand-Check anschlaegt.
- [x] E1: `--report` bleibt unveraendert: 0 heisst aktuell, 3 heisst veraltet. Der Schritt
      „Veraltete Etappen ermitteln" haengt daran.
- [x] E1: Der Kopfkommentar des Skripts beschreibt beide Faelle.

### F. Deutscher Monatsname in der Uebersicht

Ergaenzt am 14. Oktober 2026 nach PR #6: Die Uebersicht trug „14. October 2026".

- [x] F1: Der Schritt „Uebersicht neu erzeugen" uebersetzt den Monatsnamen ins Deutsche.
- [x] F1: Die Uebersetzung ist wortgleich mit `sync.sh:125`. Sonst erzeugen der lokale Lauf
      und der CI-Lauf verschiedene Uebersichten, und jeder aendert die Datei des anderen.

## Akzeptanzkriterien

- [x] Lokal: `CLAUDE_CODE_OAUTH_TOKEN=ungueltig python3 bin/bauplan-ci.py --regenerate --repo harness`
      endet mit Exit 1, und die Ausgabe enthaelt `authentication_error`. Seiteneffekte gibt
      es keine, denn `CI-BERICHT.json` ist gitignored (`.gitignore:24`).
- [x] `grep -n '"Bash"' bin/bauplan-ci.py` liefert keinen Treffer. Es gibt also keine
      Freigabe ohne Muster.
- [x] `grep -n "per Edit" .claude/skills/repo-bauplan/SKILL.md` trifft im Refresh-Abschnitt.
- [x] Manueller Lauf mit `regenerate = true`: Der Schritt „Betroffene Etappen neu bauen" ist
      entweder gruen, oder er ist rot und das Log nennt die Ursache im Klartext. Erfuellt
      durch die Laeufe 38536107837 („Not logged in") und 38536814197 (ABBRUCH mit Dateiliste).
- [x] D1 im Wegwerf-Repo: Eine **vor** dem Lauf geaenderte Datei wird nicht gemeldet. Eine im
      Lauf geaenderte Datei wird gemeldet. Eine im Lauf neu angelegte Datei wird gemeldet,
      und zwar als ausserhalb, wenn sie nicht erlaubt ist. Eine vorher geaenderte und im Lauf
      erneut geaenderte Datei wird gemeldet. Eine gitignorierte Datei wird nicht gemeldet.
- [x] D2 im Lauf auf `main` (38546913702): Das Log zeigt fuer jedes Repo das Ende von
      Claudes Antwort.
- [x] E1 nachgestellt mit Ersatz-`claude`: Ein erfolgreicher Neubau fuer zwei Repos ergibt
      Exit 0 (heute 3). Ein Uebergriff ergibt Exit 1. `--report` mit Veraltetem ergibt
      weiterhin Exit 3. Ein ungueltiges Token ergibt weiterhin Exit 1.
- [x] Manueller Lauf auf `main` nach dem Merge von E: Der Schritt „Betroffene Etappen neu
      bauen" ist gruen, und der Workflow oeffnet den Auffrischungs-PR. Erfuellt durch Lauf
      38550625855: alle Schritte gruen, PR #6 von `github-actions` angelegt.
- [x] Der PR „docs: refresh stale bauplan sheets" enthaelt nur Dateien unter `docs/bauplan/`
      und `.claude/bauplan/*.manifest.json`. Erfuellt durch PR #6: zehn Dateien, keine
      ausserhalb, Wortpruefung 0 Verstoesse, SVG-Tags ausgeglichen.
- [x] F1: Die `sed`-Anweisung im Workflow-Schritt ist zeichengleich mit der aus `sync.sh`
      und macht aus allen zwoelf englischen Monatsnamen die deutschen.
- [ ] F1: Der naechste Auffrischungslauf schreibt den Stand mit deutschem Monatsnamen.

## Constraints

- **Eigener Branch und eigener Commit**, nicht auf `docs/liquid-conventions-update`.
- **Kein Testframework in der Harness.** Der Nachweis laeuft wie in
  `bauplan-repo-pfad.md` ueber direkte Aufrufe, und die Ergebnisse stehen unter „Umsetzung".
- **Die Schutzschichten bleiben**: `bauplan-guard.sh`, `diff_within()` in `bauplan-ci.py`
  und `bauplan-guard.py --verify` werden nicht gelockert.
- Der CI-Lauf laesst sich lokal nicht vollstaendig pruefen. Lokal pruefbar sind Teil A
  (Fehlerausgabe) und Teil B (Aufrufzeile). Die Teile B und C in Wirkung zeigt erst der
  manuelle Lauf.

## Nicht im Umfang

| Thema | Beleg | Warum spaeter |
|---|---|---|
| Laufzeit: zwei Repos mit je bis zu 3600 s gegen 90 Minuten Job-Timeout | `bin/bauplan-ci.py:27`, `bauplan-refresh.yml:60` | ⚠️ greift erst, wenn der Neubau ueberhaupt laeuft |
| Phase 2e kollidiert auch lokal mit dem Guard (Neuanlage) | Befund 5 | betrifft nicht den Refresh |
| `actions/checkout@v4` und `upload-artifact@v4` laufen noch auf Node 20 | Runner-Annotation | Warnung, kein Fehler |
| `ubuntu-latest` wechselt ab dem 19. Oktober 2026 auf Ubuntu 26 | Runner-Annotation | beobachten |
| Cron 04:17 UTC, tatsaechlicher Start 09:00–12:00 UTC | `gh run list` | GitHub-Verzoegerung, kein Defekt |
| Deny-Regel `Write(themes/*/config/settings_data.json)` wirkungslos | `.claude/settings.json:25`, Runner-Warnung | rein kosmetisch |
| Den `<text>`-Zaehlbefehl aus Phase 2e, Schritt 3, blockiert ebenfalls der Guard, denn das Muster `'<text[ >]'` enthaelt `>` und der Befehl nennt `docs/bauplan` | `SKILL.md:184–187`; Claudes Antwort in Lauf 38546913702 | gleiche Ursache wie Befund 5, eigener Fix am Skill |
| Offene Fragen landen im CI-Lauf nicht im Manifest. Claude kuendigt den Eintrag „nach deiner Freigabe" an, im Headless-Lauf kommt aber keine Freigabe. `last_seen_sha` setzt das Skript selbst, das ist nicht betroffen | Claudes Antwort in Lauf 38546913702 | Prompt oder Skill-Abschnitt fuer den CI-Fall anpassen |
| Seiten auf claude.ai nach dem Merge neu veroeffentlichen, einzeln und im Uebersichts-Artefakt | Befund 6 | Handarbeit, bis es einen Weg ohne `Artifact`-Werkzeug gibt |
| Laut Claudes Antwort in Lauf 38550625855 lehnt Claude Code im CI-Lauf das Bearbeiten der Manifeste unter `.claude/` als geschuetzte Datei ab. Befundzahlen und offene Fragen bleiben deshalb im Manifest alt, `last_seen_sha` setzt das Skript | Claudes Antwort im Log | ⚠️ Ursache nicht selbst geprueft; Manifest-Pflege fuer den CI-Fall klaeren |
| Im Uebersichts-Artefakt laufen die Blaetter ohne `<!doctype html>` im Quirks-Modus, weil Unterseiten dort ohne Dokumentrahmen ausgeliefert werden | Warnung beim Veroeffentlichen, 14. Oktober 2026 | besteht seit der ersten Fassung vom 16. September 2026 |

## Offene Fragen

- ✅ Beantwortet: `Artifact` ist im Headless-Lauf nicht verfuegbar (Befund 6).

## Umsetzung

Durchgefuehrt am 14. Oktober 2026 auf dem Branch `fix/bauplan-ci-refresh`, abgezweigt von
`origin/main`.

| Datei | Aenderung |
|---|---|
| `bin/bauplan-ci.py` | A: Bei Fehler Exit-Code sowie das Ende von stdout und stderr ausgeben. B: `allowed_tools()` erzeugt die Freigaben je Repo, uebergeben per `--allowedTools` |
| `bin/bauplan-ci.py` | Zusaetzlich, im Dienst von A: stdout zeilengepuffert, damit Fortschritt und Fehler im Log in der richtigen Reihenfolge stehen. stdin abgehaengt, damit die Warnung „no stdin data received" nicht im Fehler-Log landet |
| `.claude/skills/repo-bauplan/SKILL.md` | C: Der Refresh-Abschnitt, Schritt 3, legt Edit als Schreibweg fest und begruendet das mit Guard und CI |

Die Freigaben fuer `connector`:
`python3 bin/…` und `bin/…` fuer `bauplan-stale.py` und `bauplan-wording.py`, dazu
`git diff|log|show|rev-parse`, jeweils ohne `-C`, mit `-C .` und mit `-C connector`.
Fuer `harness` faellt `-C connector` weg, denn das Repo ist der Workspace selbst.

### Nachweis

```
py_compile bin/bauplan-ci.py                         -> ok
SKILL.md Frontmatter (ruby YAML.load_file)           -> ok
CLAUDE_CODE_OAUTH_TOKEN=ungueltig … --regenerate     -> Exit 1, Log enthaelt
    --repo harness                                      "401 … authentication_error"
bauplan-ci.py --report                               -> Exit 3 (unveraendert)
bauplan-guard.py --verify                            -> Exit 0
grep '"Bash"' bin/bauplan-ci.py                      -> kein Treffer
grep "per Edit" SKILL.md                             -> Zeile 281
Freigaben im frischen, nicht vertrauten Klon,        -> bauplan-stale.py: ausgefuehrt
  claude -p mit --allowedTools aus allowed_tools()      git -C . log: ausgefuehrt
                                                        bauplan-index.py: abgelehnt
```

### Nicht geprueft

- Der Lauf auf dem Runner. Lokal lief CLI 2.1.80, der Runner installiert die neueste
  Version.
- Ob das neue Secret vollstaendig ist. Das Token wurde direkt in die Eingabeaufforderung
  von `gh secret set` eingefuegt, wo ein Zeilenumbruch den Wert abschneiden kann.
- Offene Frage 6 (`Artifact` im Headless-Lauf).

Diese drei Punkte und die beiden offenen Akzeptanzkriterien beantwortet der manuelle Lauf
mit `regenerate = true`.

Ergebnis der manuellen Laeufe auf dem Branch, 14. Oktober 2026: Das Secret von 10:15 Uhr
kam als leer an („Not logged in"). Das von 10:40 Uhr wirkt. Der Lauf brach danach an
Befund 7 ab, daraus wurde Teil D.

### Nachtrag D (14. Oktober 2026)

| Datei | Aenderung |
|---|---|
| `bin/bauplan-ci.py` | D1: `bauplan_stand()` haelt vor jedem Claude-Lauf den Inhalt aller abweichenden Bestandsdateien fest (`git ls-files --modified --deleted --others --exclude-standard`, Inhalt als SHA-1). `diff_within()` vergleicht danach mit diesem Stand statt mit `HEAD` |
| `bin/bauplan-ci.py` | D2: Bei Erfolg kommt das Ende von Claudes Antwort ins Log (1500 Zeichen) |

#### Nachweis D

Test zuerst, im Wegwerf-Repo (`test_diff_within.py`, im Scratchpad, nicht committet):
gegen den alten Code rot, denn `bauplan_stand` fehlt. Gegen den neuen Code gruen:

```
nur dieser Lauf, neue Datei erfasst          -> etappe-02 (geaendert), etappe-03 (neu)
neue, nicht erlaubte Datei ist ausserhalb    -> etappe-03
erneut geaenderte und geloeschte Datei       -> etappe-01, x.manifest.json
gitignorierte CI-BERICHT.json                -> nicht gemeldet
keine Aenderung                              -> leer
```

Zwei-Repo-Fall nachgestellt: Wegwerf-Klon des Branches, `connector` verlinkt und kuenstlich
veraltet, `claude` durch ein Ersatz-Skript ersetzt, das nur die aufgetragenen Blaetter
aendert:

```
alter Code (729b505)               -> ABBRUCH beim harness-Teil, gelistet die
                                      Connector-Dateien (wie in Lauf 38536814197)
neuer Code                         -> connector 7 Blaetter, harness 3 Blaetter, Exit 3,
                                      Claudes Antwort je Repo im Log
                                      (Korrektur: Exit 3 ist hier kein Erfolg, siehe
                                      Befund 9 und Teil E)
neuer Code, harness greift auf ein -> ABBRUCH, gelistet nur
  emailservice-Blatt uebergreifend    docs/bauplan/emailservice/etappe-01.html
```

Wiederholt: ungueltiges Token, also Exit 1 mit `authentication_error`. `--report` ergibt
Exit 3, `bauplan-guard.py --verify` Exit 0, und `grep '"Bash"'` findet keinen Treffer.

#### Ergebnis auf `main`

A–D wurden mit PR #4 gemergt (`eb700e1`). Lauf 38546913702 hat beide Repos aufgefrischt:
Connector 4 Blaetter, harness 2 Blaetter, die Wortpruefung lief, und Claudes Antwort
stand im Log. Danach endete der Schritt mit Exit 3, das ist Befund 9. Lauf 38547251030
zeigt dasselbe Bild.

### Nachtrag E (14. Oktober 2026)

Branch `fix/bauplan-ci-exit-code`, abgezweigt von `origin/main` (`eb700e1`).

| Datei | Aenderung |
|---|---|
| `bin/bauplan-ci.py` | E1: `main()` gibt nach `--regenerate` ohne Fehler 0 zurueck statt 3. Der Kopfkommentar beschreibt die Exit-Codes beider Modi |

#### Nachweis E

Test zuerst (`test_exit_e.sh`, im Scratchpad, nicht committet). Gegen `eb700e1` rot:

```
Neubau zwei Repos erfolgreich   -> Exit 3, soll 0      FAIL
Uebergriff im harness-Lauf      -> Exit 1              OK
Bericht mit Veraltetem          -> Exit 3              OK
Neubau mit ungueltigem Token    -> Exit 1              OK
```

Mit dem Fix gruen, alle vier Faelle OK. Wiederholt: Der D1-Test ist gruen,
`bauplan-guard.py --verify` ergibt Exit 0.

Vorab geprueft: Das Repo erlaubt Actions, PRs anzulegen
(`default_workflow_permissions: write`, `can_approve_pull_request_reviews: true`). Die
Org-Einstellung ist ohne Org-Adminrechte nicht lesbar ⚠️.

#### Ergebnis E auf `main`

PR #5 gemergt (`72da68b`). Lauf 38550625855: alle Schritte gruen, der Neubau dauerte
knapp 12 Minuten. Der Workflow oeffnete PR #6 „docs: refresh stale bauplan sheets" mit
Connector-Etappe 3, 5, 7, 9, Harness-Etappe 2, 3, 4, beiden Manifesten und der Uebersicht.
Vor dem Merge geprueft: keine Datei ausserhalb der erlaubten Pfade, Wortpruefung ohne
Verstoss, `bauplan-guard.py --verify` Exit 0, `<text>`-Tags in allen sieben Blaettern
ausgeglichen. PR #6 gemergt (`3667f53`).

### Veroeffentlichung (14. Oktober 2026)

Die sieben aufgefrischten Blaetter sind an ihre bestehenden Adressen neu veroeffentlicht.
Vorher wurde jede Live-Seite mit der Repo-Historie verglichen: Alle entsprachen exakt einem
frueheren Repo-Stand, in der Oberflaeche war also nichts geaendert worden.

Im Uebersichts-Artefakt (`MkGXGcmet5Zcixi9UceYMj`) waren ausserdem Harness-Etappe 1 und 5
seit dem 18. September 2026 veraltet, und Harness-Etappe 6 fehlte ganz. Version 2 enthaelt
die neue Uebersicht und alle zehn betroffenen Blaetter, insgesamt 24 Dateien.

### Nachtrag F (14. Oktober 2026)

| Datei | Aenderung |
|---|---|
| `.github/workflows/bauplan-refresh.yml` | Der Schritt „Uebersicht neu erzeugen" uebersetzt den Monatsnamen mit derselben `sed`-Anweisung wie `sync.sh:125`, der `run`-Wert ist jetzt ein Block-Skalar |

#### Nachweis F

Test zuerst (`test_monat_f.py`, im Scratchpad, nicht committet). Gegen den alten Workflow
rot, weil der Schritt keine `sed`-Uebersetzung enthielt. Mit dem Fix gruen: Die
`sed`-Anweisung ist zeichengleich mit `sync.sh`, und alle zwoelf Monate werden
uebersetzt. Das YAML ist gueltig (Ruby `YAML.load_file`), und der Schritt liefert unter
`LC_ALL=C` „14. Oktober 2026".

Die Schreibweise „Maerz" stammt aus `sync.sh` und ist bewusst uebernommen.

#### Noch offen

- F im naechsten Auffrischungslauf bestaetigen: Der Stand der Uebersicht ist deutsch.
- Nach jedem kuenftigen Auffrischungs-PR die geaenderten Seiten und das
  Uebersichts-Artefakt von Hand neu veroeffentlichen.
