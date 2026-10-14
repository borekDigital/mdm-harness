# Spec: Bauplan-CI — Auffrischung lauffaehig und Fehler sichtbar

Stand: 14. Oktober 2026
Quelle: Analyse der roten Laeufe von „Bauplan auffrischen", 14. Oktober 2026
Status: IMPLEMENTIERT (14. Oktober 2026), Validierung durch den manuellen Lauf steht aus — siehe „Umsetzung" am Ende

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
| 3 | Ursache des Exit 1: ein abgelehntes `CLAUDE_CODE_OAUTH_TOKEN`. Das 401-Bild stimmt mit dem Runner ueberein (Exit 1, ~5 s, stderr nur Warnungen). Das Secret wurde am 14. Oktober 2026 erneuert | Gegenprobe lokal mit gueltiger Anmeldung im frischen Klon: Exit 0 | ⚠️ Vermutung |
| 4 | Claude fehlen im CI-Lauf die Shell-Rechte. Gestartet wird nur mit `--permission-mode acceptEdits`. Der Refresh-Abschnitt braucht `bin/bauplan-stale.py`, `bin/bauplan-wording.py` und `git -C . diff`. Keiner dieser Befehle steht in der Allow-Liste, und der Runner ignoriert die Allow-Liste ohnehin („Ignoring 17 permissions.allow entries … not trusted") | `bin/bauplan-ci.py:81`; `SKILL.md:132`, `:274`, `:283`; `.claude/settings.json:4–19`; Runner-Log | ✅ fehlende Rechte belegt, ⚠️ Wirkung auf den Lauf vermutet |
| 5 | Der Guard blockiert den Schreibweg des Skills. Phase 2e legt Blaetter per Shell-Umleitung `> docs/bauplan/…` ab, und `bauplan-guard.sh` blockiert jeden Bash-Befehl, der `>` und `docs/bauplan` enthaelt | `SKILL.md:165–168`; `.claude/hooks/bauplan-guard.sh:28–29`; am 14. Oktober 2026 live ausgeloest | ✅ belegt |
| 6 | Ob das `Artifact`-Werkzeug im Headless-Lauf auf dem Runner verfuegbar ist (Schritt 5 im Refresh-Abschnitt: veroeffentlichen) | — | ❌ unbekannt, klaert der Pruef-Lauf |

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

## Akzeptanzkriterien

- [x] Lokal: `CLAUDE_CODE_OAUTH_TOKEN=ungueltig python3 bin/bauplan-ci.py --regenerate --repo harness`
      endet mit Exit 1, und die Ausgabe enthaelt `authentication_error`. Seiteneffekte gibt
      es keine, denn `CI-BERICHT.json` ist gitignored (`.gitignore:24`).
- [x] `grep -n '"Bash"' bin/bauplan-ci.py` liefert keinen Treffer. Es gibt also keine
      Freigabe ohne Muster.
- [x] `grep -n "per Edit" .claude/skills/repo-bauplan/SKILL.md` trifft im Refresh-Abschnitt.
- [ ] Manueller Lauf mit `regenerate = true`: Der Schritt „Betroffene Etappen neu bauen" ist
      entweder gruen, oder er ist rot und das Log nennt die Ursache im Klartext.
- [ ] Ist der Lauf gruen: Der PR „docs: refresh stale bauplan sheets" enthaelt nur Dateien
      unter `docs/bauplan/` und `.claude/bauplan/*.manifest.json`.

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

## Offene Fragen

- ❌ Ist `Artifact` im Headless-Lauf verfuegbar? Wenn nicht, ist das HTML im Repo aktuell,
  waehrend die veroeffentlichten Seiten auf claude.ai alt bleiben. Klaert der Pruef-Lauf.

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
