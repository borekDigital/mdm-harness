# Spec: Harness ohne lokale Einrichtung

Stand: 16. Oktober 2026
Quelle: Frage von Konrad am 16. Oktober 2026 — „gibt es keine Lösung, ohne dass sich das jeder installieren
muss?"; Teil F aus `bauplan-index-lokal-sauber.md` (Befund 12)
Status: IMPLEMENTIERT (16. Oktober 2026; freigegeben mit dem Auftrag „Spec schreiben und bis zum PR umsetzen")

## Ziel

Die Harness funktioniert nach `git clone` und `git pull` ohne einen Schritt, den jeder Rechner einzeln
einrichten muss. Versionierte Dateien hängen nicht vom lokalen Zustand ab. Wer Claude nutzt, erfährt beim
Sitzungsstart, was lokal fehlt oder nicht zum Stand passt. Wer ohne Claude arbeitet, verliert nichts, und
die CI sagt bei Abweichungen, was zu tun ist.

## Ist-Zustand

```
git pull ─┬─ mit post-merge ─► sync.sh schreibt CLAUDE.md ─► Warnungen
          │                     └─ nicht alle Repos geklont: „(nicht installiert)" in CLAUDE.md ─► git status schmutzig
          └─ ohne post-merge ─► keine Warnungen, nirgends ein Hinweis auf den Hook
```

| # | Befund | Beleg | Status |
|---|---|---|---|
| 1 | `sync.sh` wird an drei Stellen ausgelöst: von Hand, durch `git-hooks/post-merge` und durch `setup.sh`. Kein Hook in `.claude/hooks/` ruft es auf | `git-hooks/post-merge:9-13`; `setup.sh:417`, `:436`, `:444`, `:460`; `grep sync.sh .claude/hooks/` leer | ✅ belegt |
| 2 | Git überträgt Hooks nicht beim Klonen. Im Repo setzt nichts `core.hooksPath`, `setup.sh` installiert den Hook nicht. Die Kopie in `~/MDM/.git/hooks/` ist von Hand angelegt | `grep hooksPath` im Repo leer; `diff` der Kopie mit `git-hooks/post-merge` leer | ✅ belegt |
| 3 | Nirgends steht, dass der Hook einzurichten ist. `README.md:162` beschreibt nur, was er tut | `grep post-merge` in README, `.claude/README.md`, Bedienungsanleitung, Setup-Skill | ✅ belegt |
| 4 | `CLAUDE.md` ist versioniert. Ein Pull bringt immer die committete Fassung, auch ohne Hook | `git ls-files CLAUDE.md` | ✅ belegt |
| 5 | Dass die committete `CLAUDE.md` zu `templates/` und `workspace.yaml` passt, prüft die CI nur nebenbei: `test-sync-sauber.sh` scheitert, wenn `sync.sh` eine andere Datei erzeugt. Die Meldung nennt dann nur `FEHL git status sauber`, nicht den Befehl zur Behebung | `.github/workflows/harness-check.yml:29`, `:55`, `:89-90`; `bin/test-sync-sauber.sh:59` | ✅ belegt |
| 6 | Die Repo-Tabelle in `CLAUDE.md` markiert Repos, die nicht in `.workspace.local.yaml` stehen, als „_(nicht installiert)_". Ein Rechner mit unvollständigem Klon bekommt nach `sync.sh` eine geänderte versionierte Datei | `sync.sh:47-50`, `:76` | ✅ belegt (Code) / ⚠️ nicht ausgeführt, wird mit Fall 5 des Tests belegt |
| 7 | Ohne Claude bringt der Hook wenig: `CLAUDE.md` liest nur Claude, die STALE-Berichte schreiben nur Claude-Hooks, die Bauplan-Prüfung macht die CI. Übrig bleiben zwei Setup-Warnungen (`sync.sh:155-161`, `:164-182`) | `sync.sh`; `.claude/hooks/bauplan-staleness.sh`, `bauplan-report.sh` | ✅ belegt |
| 8 | Die 7-Tage-Prüfung misst den letzten Lauf von `sync.sh` im Schreibmodus (`update_local_timestamps`), nicht den letzten Pull der Kind-Repos | `sync.sh:164-182`, `:189-205`, `:245-247` | ✅ belegt |
| 9 | Ein SessionStart-Hook gibt es schon (`harness-stand.sh`). Er antwortet mit JSON aus `systemMessage` und `hookSpecificOutput.additionalContext` | `.claude/settings.json:32-43`; `bin/harness-stand.py:107-114` | ✅ belegt |

## Soll-Bild

```
git pull ─┬─ mit post-merge ─► sync.sh (wie bisher) ─► CLAUDE.md byte-gleich, git status sauber, Warnungen
          └─ ohne post-merge ─► nichts nötig: CLAUDE.md aus dem Repo, von der CI geprüft
Claude-Start ─► SessionStart: sync.sh --check ─► nicht geklonte Repos, Abweichungen, veraltete Etappen
                                              ─► Hinweis an Nutzer und Kontext; schreibt nichts
PR ─► CI: sync.sh --check ─► Exit 3 mit „./sync.sh ausführen und mitcommitten"
```

## Anforderungen

### A — `CLAUDE.md` ohne lokalen Zustand

- [x] Die Repo-Tabelle listet alle Repos aus `workspace.yaml` ohne Markierung. `is_installed` beeinflusst
      die erzeugte Datei nicht mehr.
- [x] Welche Repos nicht geklont sind, meldet `sync.sh` in der Konsole, in beiden Modi, auch mit `--quiet`:
      „Nicht geklont (übersprungen, nicht abgeschafft): …".

### B — Prüfmodus `sync.sh --check`

- [x] Erzeugt `CLAUDE.md` nur im Speicher und vergleicht mit der Datei. Weicht sie ab: Warnung mit
      „`./sync.sh` ausführen und mit dem PR committen".
- [x] Prüft Übersicht und Fußzeilen (`bauplan-index.py --check`, `bauplan-nav.py --check`), meldet veraltete
      Etappen und nicht geklonte Repos und führt die Konsistenzprüfung aus.
- [x] Schreibt nichts, auch nicht `.workspace.local.yaml`: keine Zeitstempel, keine `CLAUDE.md`.
- [x] Exit 3, wenn eine versionierte Datei abweicht (`CLAUDE.md`, Übersicht, Fußzeilen), sonst 0. Lokale
      Hinweise (nicht geklont, Konsistenz, veraltet) ändern den Exit-Code nicht.
- [x] `--check` und `--quiet` sind kombinierbar. Ohne `--check` verhält sich `sync.sh` wie bisher.

### C — SessionStart-Hook

- [x] Neuer Hook `.claude/hooks/harness-sync-check.sh`, eingetragen in `.claude/settings.json` unter
      SessionStart. Er ruft `sync.sh --check --quiet` im Projektverzeichnis auf.
- [x] Gibt es Meldungen, antwortet er mit JSON: `systemMessage` (kurz, für den Nutzer) und
      `hookSpecificOutput.additionalContext` (vollständig, für Claude, mit dem Satz „Nicht geklont heißt
      übersprungen, nicht abgeschafft"). Ohne Meldungen schweigt er.
- [x] Endet immer mit Exit 0. Kein Wächter, blockiert nichts. Fehlt `sync.sh`, schweigt er.
- [x] Format, Matcher und Timeout folgen der Claude-Code-Doku (geprüft per `claude-code-guide`, Rule
      `doku-quellen`) und dem Muster von `harness-stand.sh`.

### D — CI

- [x] `harness-check.yml`: Schritt „Generierte Dateien passen zum Stand" ruft `./sync.sh --check` auf und
      ersetzt den bisherigen Schritt für die Bauplan-Übersicht. Bei Exit 3 steht die Ursache mit Befehl im Log.

### E — Doku

- [x] `README.md`: Der post-merge-Hook ist optional; Installationsbefehl dabei. Abschnitt „Ohne Claude":
      nichts einzurichten; Setup-Warnungen per `./sync.sh`. Guard-Mechanismus Punkt 3 angepasst.
- [x] `.claude/README.md`: Zeile für `harness-sync-check.sh` in der Hook-Tabelle.
- [x] `git-hooks/post-merge`: Kommentar, dass der Hook optional ist.

## Tests (TDD)

`bin/test-sync-sauber.sh`, neue Fälle:

- Fall 5: nur ein Repo in `.workspace.local.yaml` → post-merge → `git status` sauber, Ausgabe nennt die
  nicht geklonten Repos.
- Fall 6: ohne `.workspace.local.yaml` → post-merge → `git status` sauber.
- Fall 7: `templates/` geändert und committet, `CLAUDE.md` nicht → `sync.sh --check` endet mit 3, nennt
  `./sync.sh`, schreibt nichts.
- Fall 8: sauberer Stand → `sync.sh --check` endet mit 0; `CLAUDE.md` und `.workspace.local.yaml`
  unverändert (Inhalt und Änderungszeit).
- Fall 9: SessionStart-Hook bei fehlenden Repos → gültiges JSON mit `systemMessage` und `additionalContext`,
  Exit 0. Bei sauberem, vollständigem Stand → keine Ausgabe. Ohne `sync.sh` → keine Ausgabe, Exit 0.

## Akzeptanzkriterien

- [x] **AK1** Ein Klon mit nur einem Repo bleibt nach `git pull` plus post-merge sauber (Fall 5).
- [ ] **AK2** Ohne post-merge-Hook geht nichts verloren: `CLAUDE.md` kommt aus dem Repo, die CI prüft sie
      ausdrücklich (Teil D), und Claude-Nutzer bekommen die Hinweise beim Sitzungsstart (Fall 9).
- [x] **AK3** Eine vergessene Regeneration von `CLAUDE.md` macht die CI rot, und das Log nennt `./sync.sh`
      (Fall 7).
- [x] **AK4** `sync.sh --check` schreibt nichts (Fall 8).
- [x] **AK5** Für Konrad ändert sich nichts: Der installierte Hook läuft unverändert, `CLAUDE.md` bleibt
      byte-gleich.
- [x] **AK6** Alle Tests und `harness-check.py` grün.

## Constraints

- `git-hooks/post-merge` behält seine Funktion (Schreibmodus). Die installierte Kopie muss nicht erneuert
  werden. So bleibt die 7-Tage-Prüfung (Befund 8) für Rechner mit Hook unverändert.
- Der SessionStart-Hook schreibt nichts und blockiert nichts.
- Keine Änderung an Wächtern, Bauplan-Guard und Bauplan-Werkzeugen.
- `setup.sh` bleibt unverändert. `core.hooksPath` setzt es weiterhin nicht (bewusst: nicht nötig).

## Umsetzung (16. Oktober 2026)

- Doku geprüft per `claude-code-guide` (code.claude.com/docs/en/hooks, Abschnitt SessionStart): JSON mit
  `systemMessage` und `additionalContext`, Ausgabe höchstens 10 000 Zeichen, SessionStart blockiert nie, ohne
  Matcher für alle Sitzungsarten, synchron, damit der Kontext vor der ersten Antwort ankommt. ⚠️ Ob die
  Desktop-App `systemMessage` beim Sitzungsstart anzeigt, ist nicht dokumentiert.
- `bin/test-sync-sauber.sh`: Fälle 5 bis 9 vor dem Code rot (11 Fehler), danach 19 von 19 grün, auch unter
  `/bin/bash` 3.2.
- `CLAUDE.md` ist byte-gleich geblieben, weil die committete Fassung schon ohne Markierung erzeugt war.

## Nicht Teil dieser Spec

- Die 7-Tage-Prüfung misst etwas anderes, als ihr Name sagt (Befund 8). Bleibt, wie sie ist.
- STALE-Berichte werden nie geleert (`bauplan-index-lokal-sauber.md`, Befund 8).
