# Spec: Bauplan-Übersicht lokal sauber

Stand: 16. Oktober 2026
Quelle: Vorfall vom 16. Oktober 2026 — `docs/bauplan/index.html` nach `git pull` auf `acf54f7` lokal geändert,
versehentlich committet, `main` per Reset repariert
Status: VALIDIERT (16. Oktober 2026; freigegeben und umgesetzt am selben Tag — Frage 1 und 2 wie empfohlen, Teil F als eigene Spec)

## Ziel

`docs/bauplan/index.html` hängt nur noch vom versionierten Stand ab. Lokaler Zustand (Ledger, STALE-Berichte,
Tagesdatum) landet nicht mehr in der Datei. Nach `git pull` plus post-merge-Hook ist `git status` sauber, und
CI und lokaler Lauf erzeugen aus demselben Commit dieselbe Datei.

## Ist-Zustand

```
git pull ─► .git/hooks/post-merge ─► sync.sh --quiet ─► update_index()
                                                            │
                     ┌──────────────────────────────────────┤
                     ▼                                      ▼
        bin/bauplan-index.py --stand <heute>      bin/bauplan-nav.py
                     │                                      │
   Eingaben:         │                                      ▼
   workspace.yaml  ──┤ versioniert            schreibt docs/bauplan/<repo>/etappe-NN.html
   *.manifest.json ──┤ versioniert
   etappe-NN.html  ──┤ versioniert (nur: vorhanden?)
   *.STALE.md      ──┤ LOKAL, gitignored    ─► „veraltet"-Marker
   date            ──┘ LOKAL, Uhr           ─► Kopfzeile „Stand"
                     │
                     ▼
   docs/bauplan/index.html (versioniert) ─► M im git status ─► nächster Pull scheitert
                                                              oder Datei wird mitcommittet
```

Die CI erzeugt dieselbe Datei ohne STALE-Berichte und mit ihrem eigenen Tagesdatum. Lokal und CI schreiben
also verschiedene Fassungen in dieselbe versionierte Datei.

## Befunde

| # | Befund | Beleg | Status |
|---|---|---|---|
| 1 | Der post-merge-Hook ruft nach jedem `git pull`/`git merge` `sync.sh --quiet` auf | `git-hooks/post-merge:9-12` | ✅ belegt |
| 2 | Der Hook ist von Hand installiert, nicht durch `setup.sh`. Die Kopie in `~/MDM/.git/hooks/post-merge` (Stand 1. September 2026) ist identisch mit `git-hooks/post-merge`. Kein Skript im Repo setzt `core.hooksPath` oder kopiert den Hook | `diff` beider Dateien leer; `grep hooksPath\|git-hooks` im Repo trifft nur `README.md:159` und Specs | ✅ belegt |
| 3 | Worktrees teilen die Hooks des Haupt-Checkouts, der Hook läuft also auch dort | Git-Standardverhalten (`$GIT_COMMON_DIR/hooks`), nicht ausgeführt | ⚠️ Vermutung |
| 4 | `sync.sh` erzeugt die Übersicht bei jedem Lauf neu und übergibt das Tagesdatum als `--stand`. Fehler und Ausgabe werden verschluckt | `sync.sh:122-126`, Aufruf `sync.sh:224-228` | ✅ belegt |
| 5 | `bauplan-index.py` liest `<repo>.STALE.md` und schreibt daraus `<span class="f-alert">veraltet</span>` in die Zeile sowie „**N Etappen veraltet** — auffrischen mit …" in den Lead-Absatz | `bin/bauplan-index.py:48-55`, `:83`, `:115-116`, `:143`, `:151` | ✅ belegt |
| 6 | `*.STALE.md` und das Ledger sind gitignored. Geschrieben werden sie nur von zwei lokalen Claude-Hooks: `bauplan-staleness.sh` (PostToolUse, Ledger) und `bauplan-report.sh` (Stop, verdichtet zu STALE.md) | `.gitignore:19-20`; `.claude/hooks/bauplan-staleness.sh:44-53`; `.claude/hooks/bauplan-report.sh:43-75` | ✅ belegt |
| 7 | In der CI gibt es keine STALE.md. Die CI-Fassung der Übersicht trägt nie „veraltet"-Marker. PR #23 ändert in `index.html` nur die Tech-Zeilen aus Befund 10 | `bin/bauplan-ci.py:146` (Kommentar); `git diff HEAD...origin/bauplan/auffrischung -- docs/bauplan/index.html` (2 Zeilen, kein `f-alert`) | ✅ belegt |
| 8 | Kein Code löscht oder leert eine STALE.md. `bauplan-report.sh` schreibt sie nur neu, wenn das Ledger Einträge hat. Frischt die CI eine Etappe auf, bleibt der lokale Marker stehen. Nach dem Merge von PR #23 zeigt die lokale Übersicht `harness` Etappe 1 also weiter als „veraltet" | `.claude/hooks/bauplan-report.sh:22-23`, `:35-36`; `~/MDM/.claude/bauplan/harness.STALE.md` vorhanden | ✅ belegt (Code) / ⚠️ Vermutung (Wirkung nach Merge, nicht ausgeführt) |
| 9 | Das Kopfdatum „Stand" ist die Uhrzeit des Laufs: lokal der Tag des Pulls, in der CI der Tag des Laufs. An jedem anderen Tag als dem CI-Tag weicht es ab. Heute stimmt es zufällig überein (beide „16. Oktober 2026") | `bin/bauplan-index.py:124`, `:175`, `:219`; `sync.sh:125`; `.github/workflows/bauplan-refresh.yml:221-222`; `index.html:411` in HEAD und Arbeitsbaum gleich | ✅ belegt |
| 10 | Dritte Ursache: PR #16 hat `workspace.yaml` geändert (Symfony 5.4, Nuxt 2), ohne die Übersicht neu zu erzeugen. Der lokale Lauf zieht das nach — auch ohne STALE.md wäre die Datei geändert. Kein CI-Schritt vergleicht die committete Übersicht mit ihren Eingaben | `git log -- workspace.yaml` (`e09cbf2`); lokaler Diff Zeilen 495-527; `.github/workflows/harness-check.yml:11-42` (Pfade ohne `workspace.yaml`, `docs/bauplan/**`, `bin/bauplan-index.py`) | ✅ belegt |
| 11 | `bauplan-nav.py` schreibt im selben Lauf versionierte Blattseiten. Seine einzige Eingabe ist das Manifest, gleiche Drift-Gefahr wie Befund 10. Heute erzeugt es keinen Diff. `--dry-run` endet immer mit Exit 0 und taugt so nicht als Prüfung | `sync.sh:127-130`; `bin/bauplan-nav.py:139`, `:179`; `git diff --stat` in `~/MDM` nur `index.html` | ✅ belegt |
| 12 | Gleiches Muster bei `CLAUDE.md`: versioniert, aber die Repo-Tabelle markiert Repos aus dem lokalen `.workspace.local.yaml` als „_(nicht installiert)_". Ein Checkout ohne diese Datei (etwa dieser Worktree) bekäme nach `sync.sh` alle acht Zeilen markiert | `sync.sh:47-50`, `:76`; `git ls-files CLAUDE.md`; Worktree ohne `.workspace.local.yaml` | ✅ belegt (Code) / ⚠️ Vermutung (nicht ausgeführt) |
| 13 | Der Bauplan-Guard blockiert `git stash`/`checkout`/`restore`, sobald sie lokal geänderten Bauplan-Bestand verwerfen würden. Da `index.html` praktisch immer geändert ist, trifft das jeden pfadlosen Stash im Haupt-Checkout | `bin/bauplan-guard.py:178-183`, `:227-231`, `:306-316` | ✅ belegt |
| 14 | Ein Pull, der `index.html` mitbringt, bricht bei lokaler Änderung ab („local changes would be overwritten") | Konrads Beobachtung am 16. Oktober 2026; Git-Standardverhalten | ✅ belegt (beobachtet) |
| 15 | Die Doku verspricht die Marker in der Übersicht und den Neubau durch `sync.sh` | `docs/bauplan/bedienung.html:466-469`, `:721`; `README.md:142-143`, `:159`; `.claude/skills/repo-bauplan/SKILL.md:330-332`; Legende `bin/bauplan-index.py:182` | ✅ belegt |
| 16 | `sync.sh` ruft Generator und Navigation ohne `--project` auf. `bauplan_lib.project_root()` fällt dann auf `CLAUDE_PROJECT_DIR` oder `~/MDM` zurück. Ein `sync.sh` im Worktree (post-merge ohne Claude-Sitzung) schreibt also in den Haupt-Checkout | `sync.sh:126`, `:130`; `bin/bauplan_lib.py:19-21`; im Worktree ist `CLAUDE_PROJECT_DIR` in der Shell leer; `bin/test-sync-sauber.sh` Fall 4 war vor dem Fix rot | ✅ belegt (ausgeführt) |

## Was gehört wohin

Grundsatz: **Eine versionierte Datei ist eine reine Funktion des versionierten Baums.** Was nur lokal gilt,
geht in die Konsole oder in gitignorierte Dateien.

| Teil der Übersicht | Quelle | versioniert | Soll |
|---|---|---|---|
| Repos, Name, Tech | `workspace.yaml` | ja | `index.html` |
| Etappen, Titel, Blätter, Funde, Offen, Artefakt-Link | `*.manifest.json` | ja | `index.html` |
| HTML-Link oder „fehlt" | Existenz von `docs/bauplan/<repo>/etappe-NN.html` | ja | `index.html` |
| „Stand" je Repo | `manifest.generated` | ja | `index.html` (unverändert) |
| „Stand" im Kopf | Uhr | nein | aus den Manifesten ableiten (Frage 1) |
| „veraltet"-Marker, Lead-Hinweis | `*.STALE.md` | nein | Konsole von `sync.sh` |

Daraus folgt für CI und lokal: Beide **dürfen** die Übersicht erzeugen, weil beide aus demselben Commit
dieselbe Datei erhalten. Geschrieben wird sie dort, wo ihre Eingaben sich ändern: im PR, der ein Manifest,
`workspace.yaml` oder eine Blattseite ändert — lokal per Skill, in der CI im Auffrischungslauf. Der
post-merge-Hook ändert keine Eingabe und schreibt deshalb nichts.

## Lösungsoptionen

| Option | Inhalt | Akzeptanzkriterium „sauber nach Pull" | Bewertung |
|---|---|---|---|
| **A** Deterministischer Generator | `bauplan-index.py` liest keine STALE.md und keine Uhr mehr. Marker gehen in die Konsole | erfüllt, solange die committete Datei zu ihren Eingaben passt | Behebt Befund 5 und 9 an der Wurzel. Befund 10 bleibt ohne Prüfung möglich |
| **B** Marker in Begleitdatei | Marker in gitignorierte Datei, z. B. `docs/bauplan/veraltet.js`, von `index.html` per `<script>` nachgeladen | erfüllt wie A | Lokale Ansicht behält die Marker. Aber: zusätzlicher Mechanismus, `file://`-Verhalten und Artefakt-Fassung ungeprüft (❌), dazu Befund 8 — die Marker sind lokal oft falsch. STALE.md ist bereits die gitignorierte Liste |
| **C** Index nur in der CI | lokal nie erzeugen | erfüllt | Bricht das Anlegen neuer Etappen: Die CI erzeugt die Übersicht nur bei veralteten Etappen (`bauplan-refresh.yml:217`). Eine neue Etappe stünde bis zum nächsten Auffrischungslauf nicht in der Übersicht |
| **D** post-merge ohne Index-Neubau | Hook bzw. `sync.sh` prüft nur | erfüllt | Allein nur Symptombehandlung: Ein manuelles `./sync.sh` oder der Skill schreibt weiter lokale Marker in die versionierte Datei, das versehentliche Committen bleibt möglich |
| **E** Drift-Prüfung in der CI | PR-Check: committete Übersicht und Navigation gleich dem Neubau? | — | Fängt Befund 10 und 11 im PR ab, bevor sie lokal aufschlagen |

**Empfehlung: A + D + E.** A macht die Datei deterministisch. D sorgt dafür, dass `sync.sh` nie schreibt, auch
wenn upstream jemand das Neuerzeugen vergessen hat. E verhindert genau diesen Fall im PR. B entfällt, weil
`*.STALE.md` die lokale Liste schon ist. C entfällt wegen des Anlegens neuer Etappen.

## Soll-Bild

```
git pull ─► post-merge ─► sync.sh ─┬─ CLAUDE.md erzeugen
                                   ├─ bauplan-index.py --check ─► Exit 3? ─► Warnung „Übersicht weicht ab"
                                   ├─ bauplan-nav.py --check   ─► Exit 3? ─► Warnung „Navigation weicht ab"
                                   └─ bauplan-index.py --veraltet ─► Konsole: „theme-mdm: Etappen 3, 5, 6
                                                                    veraltet → /repo-bauplan theme-mdm --refresh"
                                   (schreibt nichts unter docs/bauplan/)

/repo-bauplan … ─► bauplan-index.py (schreibt) ─► im selben PR committet
CI-Auffrischung ─► bauplan-index.py (schreibt) ─► Bot-PR
PR mit Manifest-/workspace.yaml-Änderung ─► CI: --check ─► rot, wenn nicht neu erzeugt
```

## Anforderungen

### A — Generator deterministisch (`bin/bauplan-index.py`)

- [x] Liest weder `*.STALE.md` noch `*.staleness.jsonl`. `stale_etappen()` wird aus dem HTML-Pfad entfernt.
- [x] Kein Uhr-Datum. Die Option `--stand` entfällt. Das Kopffeld „Stand" zeigt das neueste `generated`
      aller Manifeste im Format „16. Oktober 2026" (Frage 1: entschieden).
- [x] Die Legende verliert den Eintrag „veraltet". Der Marker „fehlt" für eine fehlende HTML-Quelle bleibt —
      er hängt am versionierten Baum.
- [x] Neue Option `--check`: schreibt nicht. Exit 0, wenn `index.html` byte-gleich mit dem Neubau ist,
      Exit 3, wenn nicht (gleiche Konvention wie `bauplan-stale.py`). Die Meldung nennt den Befehl zum Neuerzeugen.
- [x] Neue Option `--veraltet`: gibt je Repo mit STALE.md eine Zeile auf stdout aus (Repo, Etappennummern,
      Refresh-Befehl). Schreibt nichts.
- [x] Zwei Läufe auf demselben Baum liefern byte-gleiche Dateien, unabhängig von Datum, STALE.md und
      Arbeitsverzeichnis.

### B — Navigation prüfbar (`bin/bauplan-nav.py`)

- [x] Neue Option `--check`: Exit 3, wenn ein Lauf etwas ändern würde, sonst 0. Schreibt nicht.
      `--dry-run` bleibt wie bisher.

### C — `sync.sh` und post-merge schreiben nichts unter `docs/bauplan/`

- [x] `sync.sh` übergibt allen `bin/bauplan-*`-Aufrufen `--project "$SCRIPT_DIR"` (Befund 16).
- [x] `update_index()` ruft `bauplan-index.py --check` und `bauplan-nav.py --check` statt der schreibenden
      Aufrufe (Frage 2: immer nur prüfen). Bei Exit 3: Warnung mit Befehl zum Neuerzeugen und dem Hinweis, das Ergebnis mit dem
      auslösenden PR zu committen. Andere Exit-Codes: Warnung „fehlgeschlagen" wie bisher.
- [x] `sync.sh` gibt die Zeilen aus `bauplan-index.py --veraltet` aus, auch mit `--quiet`, damit sie nach
      einem Pull sichtbar sind.
- [x] Die Log-Zeile „docs/bauplan/index.html aktualisiert" (`sync.sh:227`) entfällt oder meldet das Prüfergebnis.
- [x] `git-hooks/post-merge` bleibt funktional gleich. Nur die Kommentare und die Abschlussmeldung
      (`:4`, `:12`) werden korrigiert. Ändert sich die Datei, muss Konrad die installierte Kopie in
      `~/MDM/.git/hooks/` von Hand nachziehen (Befund 2).

### D — CI

- [x] `.github/workflows/bauplan-refresh.yml`, Schritt „Uebersicht neu erzeugen": `--stand` und die
      Monatsübersetzung entfallen (`:219-222`). Muss im **selben** PR wie Teil A landen, sonst endet der
      CI-Lauf mit einem argparse-Fehler.
- [x] Drift-Prüfung bei Push und PR: `python3 bin/bauplan-index.py --check` und
      `python3 bin/bauplan-nav.py --check`. Auslöser: `workspace.yaml`, `.claude/bauplan/*.manifest.json`,
      `docs/bauplan/**`, `bin/bauplan-index.py`, `bin/bauplan-nav.py`, `bin/bauplan_lib.py`,
      `.claude/skills/repo-bauplan/assets/bauplan-head.html`. Ort: neuer Job in `harness-check.yml` oder
      eigener Workflow — entscheidet die Umsetzung, die Spec verlangt nur den Check.
- [x] Die neuen Tests laufen in `harness-check.yml` mit (`:64`).

### E — Doku

- [x] `docs/bauplan/bedienung.html:466-469` und `:721`: Übersicht ohne Marker, `sync.sh` prüft statt schreibt,
      veraltete Etappen stehen in der Konsole und in `.claude/bauplan/<repo>.STALE.md`.
- [x] `README.md:142-143`, `:159`: dito.
- [x] `.claude/skills/repo-bauplan/SKILL.md:330-332`: Nach jedem Lauf `bin/bauplan-index.py` (und
      `bin/bauplan-nav.py`) ausführen und mitcommitten. `./sync.sh` erzeugt sie nicht mehr.
- [x] `bin/bauplan-index.py`, Werkzeug-Tabelle (`:199-205`): `--check` ergänzen.

### F — `CLAUDE.md`

Nicht Teil dieser Spec (Frage 3: eigene Spec). Bis dahin legt `bin/test-sync-sauber.sh` ein
`.workspace.local.yaml` mit allen Repos an, damit Befund 12 den Test nicht verfälscht.

## Tests (TDD, vor dem Code)

- `bin/test_bauplan_index.py` (unittest, temporäres Projekt mit Fixture-Manifesten, Stil wie
  `bin/test_harness_stand.py`):
  - Ausgabe mit und ohne `harness.STALE.md` byte-gleich.
  - Kein `f-alert">veraltet` in der Ausgabe, „fehlt" bei fehlender Quelle weiter vorhanden.
  - Kopf-„Stand" = neuestes `generated`, deutsches Format.
  - `--check`: Exit 0 bei gleicher, Exit 3 bei abweichender Datei. Die Datei bleibt unverändert (mtime und Inhalt).
  - `--veraltet`: listet Repo und Etappen aus STALE.md, schreibt nichts.
- `bin/test_bauplan_nav.py` oder Erweiterung: `--check` Exit 0/3, schreibt nicht.
- `bin/test-sync-sauber.sh`: klont den aktuellen Commit in ein Temp-Verzeichnis, legt eine STALE.md und ein
  Ledger an, führt `git-hooks/post-merge` aus, erwartet leeres `git status --porcelain`. Zweiter Fall:
  manipuliertes Manifest ohne Neubau → `sync.sh` warnt, schreibt aber nicht.

## Akzeptanzkriterien

- [x] **AK1** In einem Checkout mit vorhandenen `*.STALE.md` ist nach `git pull` plus post-merge-Hook
      `git status --porcelain` leer (`bin/test-sync-sauber.sh` grün am 16. Oktober 2026; real in `~/MDM` belegt: Pull `0ff4af8..eb23344`
      mit post-merge, danach `git status --porcelain` leer).
- [x] **AK2** Nach einem manuellen `./sync.sh` gilt dasselbe.
- [x] **AK3** `bin/bauplan-index.py` erzeugt auf demselben Commit lokal und in der CI byte-gleiche Dateien:
      Der CI-Check `--check` ist grün auf einem Commit, dessen Übersicht lokal erzeugt wurde.
- [x] **AK4** `grep -c 'f-alert">veraltet' docs/bauplan/index.html` ergibt 0. Veraltete Etappen erscheinen
      in der Konsolenausgabe von `sync.sh`, auch mit `--quiet`.
- [x] **AK5** Ein PR, der `workspace.yaml` oder ein Manifest ändert, ohne die Übersicht neu zu erzeugen,
      wird von der CI rot gemeldet. Mit neu erzeugter Übersicht ist er grün.
- [x] **AK6** Der Bauplan-Guard ist unverändert: `git diff main -- bin/bauplan-guard.py .claude/hooks/bauplan-guard.sh`
      ist leer, `bin/test-waechter-hooks.sh` ist grün.
- [x] **AK7** Der nächste geplante Lauf von `bauplan-refresh.yml` nach dem Merge endet ohne Fehler im
      Schritt „Uebersicht neu erzeugen". Belegt mit dem manuellen Lauf 38889258534 (`regenerate = true`,
      grün). Bot-PR #27 bestand lokal `--check` für Übersicht und Navigation.
- [x] **AK8** Alle Tests in `harness-check.yml` sind grün. Die Doku-Stellen aus Teil E sind angepasst.

## Constraints

- Der Bauplan-Guard wird nicht angefasst, weder `bin/bauplan-guard.py` noch `.claude/hooks/bauplan-guard.sh`.
  Die Lösung entfernt die Ursache der lokalen Änderung, nicht den Schutz davor.
- Die Auffrischungslogik der CI (`bauplan-ci.py`, Bedingungen in `bauplan-refresh.yml`) bleibt unverändert.
  Einzige Änderung dort: der Aufruf ohne `--stand`.
- Nur Python-Standardbibliothek, wie die übrigen `bin/bauplan-*`.
- Aufbau der Übersicht bleibt: gleiche Sections, Tabellen, Links. Es entfallen nur die Marker, der
  Legenden-Eintrag und das Uhr-Datum.
- Blast-Radius: `bin/bauplan-index.py`, `bin/bauplan-nav.py`, `sync.sh`, `git-hooks/post-merge` (Kommentare),
  zwei Workflows, Doku aus Teil E und einmalig `docs/bauplan/index.html` (Neubau).

## Zusammenspiel mit PR #23 und Reihenfolge

1. **PR #23 zuerst mergen.** Er bringt die Tech-Zeilen aus Befund 10 und die aufgefrischten Harness-Etappen.
   Vor dem Pull muss Konrad die lokale `index.html` **selbst** verwerfen
   (`git checkout -- docs/bauplan/index.html` im Haupt-Checkout). Der Guard blockiert das für Claude zu Recht.
   Bis der Fix gemergt ist, macht der post-merge-Hook die Datei nach jedem Pull wieder schmutzig.
2. **Fix-PR auf dem dann aktuellen `main`.** Er erzeugt `index.html` einmal neu: Kopf-„Stand" aus den
   Manifesten, ohne Legenden-Eintrag „veraltet". Workflow-Änderung und Generator im selben PR (Teil D).
3. Ein danach noch offener Bot-PR auf `bauplan/auffrischung` wird beim nächsten CI-Lauf mit dem neuen
   Generator neu gebaut ⚠️ Vermutung (Verhalten von `peter-evans/create-pull-request@v6` bei bestehendem
   Branch nicht geprüft).
4. Nach dem Merge zeigt die Konsole für `harness` Etappe 1 weiter „veraltet", obwohl PR #23 sie aufgefrischt
   hat (Befund 8). Das ist ein Folgeproblem der STALE.md, kein Fehler dieser Spec (Frage 4).

## Umsetzung (16. Oktober 2026)

- AK1 erst per Test, dann real in `~/MDM` belegt. Der erste Pull bringt die neue
  `sync.sh` mit; die installierte Hook-Kopie ruft nur `sync.sh` auf und muss nicht ersetzt werden.
  Nur ihre Kommentare und die Abschlussmeldung sind dann älter als `git-hooks/post-merge`.
- Harness-Etappe 1 belegt `sync.sh`, `git-hooks/**` und `bin/**` und beschreibt den alten Ablauf
  (`docs/bauplan/harness/etappe-01.html:557`, `:749`). Sie wird damit veraltet und läuft über
  `/repo-bauplan harness --refresh` oder die CI, nicht über diesen PR.

- Bot-PRs aus `bauplan-refresh.yml` lösen keine weiteren Workflows aus, der Drift-Check läuft dort also
  nicht ⚠️ Vermutung (GitHub-Verhalten bei PRs mit dem Workflow-Token, nicht in der Doku nachgelesen;
  beobachtet: #27 ohne Checks). Der Check läuft beim Push auf `main` nach dem Merge ✅ belegt
  (`harness-check.yml` auf `0271964` grün).

## Entscheidungen (16. Oktober 2026)

1. **Kopf-„Stand":** neuestes `generated` der Manifeste.
2. **`sync.sh`:** prüft immer nur, schreibt nie unter `docs/bauplan/`. Geschrieben wird explizit per
   `bin/bauplan-index.py` und `bin/bauplan-nav.py` (Skill, CI).
3. **`CLAUDE.md` (Befund 12):** eigene Spec.
4. **STALE.md wird nie geleert (Befund 8):** offen, nicht Teil dieser Umsetzung.
5. **Hook-Installation per `setup.sh` (Befund 2):** offen, nicht Teil dieser Umsetzung.
