# Spec: Wächter-Hooks fail-closed

Stand: 16. Oktober 2026
Quelle: Bericht „Harness-Abgleich" aus PR #17 (Befunde 1, 2 und 9), geprüft gegen code.claude.com/docs/en/hooks.md
Status: FREIGEGEBEN und IMPLEMENTIERT (16. Oktober 2026); manuelle Probe durch Konrad offen

## Ziel

Die drei Wächter-Hooks (`git-safety`, `protect-merchant-files`, `bauplan-guard`) halten eine Aktion an,
wenn sie selbst nicht sauber laufen. Heute lassen sie in diesem Fall alles durch. Ein Wächter, der nicht
prüfen kann, darf nicht „erlaubt" sagen.

## Ist-Zustand

```
Aktion ─► Wächter-Hook ─┬─ prüft, findet Verstoß ──────────► exit 2 ─► blockiert        ✅
                        ├─ prüft, alles gut ───────────────► exit 0 ─► läuft
                        ├─ Eingabe unlesbar / python3 fehlt ► exit 0 ─► läuft           ✗ fail-open
                        ├─ Skript fehlt / startet nicht ───► exit 127 ─► läuft          ✗ fail-open
                        └─ Timeout (10 s) ─────────────────► ─────────► läuft           ✗ fail-open
```

| # | Befund | Beleg | Status |
|---|---|---|---|
| 1 | Keiner der drei Wächter setzt `onFailure`. Ohne das Feld gilt `"continue"`: Wenn ein Hook nicht startet, abläuft oder mit einem anderen Code als 0 oder 2 endet, läuft die Aktion trotzdem | `.claude/settings.json:50`, `:60`, `:70`; hooks.md „Block the action when a hook fails" (ab v2.1.295), hooks.md:878 | ✅ belegt |
| 2 | `git-safety.sh` liest den Befehl per `python3`. Scheitert das (JSON kaputt, `python3` fehlt), ist `CMD` leer, und das Skript endet mit `exit 0` | `.claude/hooks/git-safety.sh:4-13` | ✅ belegt |
| 3 | `protect-merchant-files.sh`: gleiches Muster beim Dateipfad. Zusätzlich gibt `ask()` nichts aus, wenn `python3` dort scheitert, und endet trotzdem mit `exit 0`. Die Rückfrage entfällt dann still | `.claude/hooks/protect-merchant-files.sh:4-13`, `:32-37` | ✅ belegt |
| 4 | `bauplan-guard.sh` endet mit `exit 0`, wenn `bin/bauplan-guard.py` fehlt oder nicht ausführbar ist. Bei unlesbarer Eingabe wird `TOOL` leer und `FILE` `-`, und Zeile 39 lässt durch | `.claude/hooks/bauplan-guard.sh:8`, `:10-17`, `:39` | ✅ belegt |
| 5 | Die Zweige Edit und Write im `bauplan-guard` sind zufällig schon fail-closed: Eine Python-Ausnahme führt zu `exit 2` bzw. zu leerem Inhalt, den der Guard als Schrumpfen ablehnt | `.claude/hooks/bauplan-guard.sh:47-78` | ✅ belegt (Edit) / ⚠️ Vermutung (Write, Verhalten von `--check-write` bei leerem Inhalt nicht gelesen) |
| 6 | `git-safety` erkennt `git push`, `git reset` und `git clean` nur, wenn das Unterkommando direkt auf `git` folgt. `git -C <dir> push --force` und `git -c k=v push origin main` passieren | `.claude/hooks/git-safety.sh:17-30` (Muster `git push.*`, `git reset --hard`, `git clean.*`) | ✅ belegt (aus den Mustern abgeleitet, nicht ausgeführt) |
| 7 | Die Modell-Spalte in `.claude/README.md` wich bei 4 Agenten vom Frontmatter ab (`docs-writer`: `haiku` statt `sonnet`, drei Implementer: `inherit` statt `sonnet`). Mit dieser Spec korrigiert | `.claude/README.md:186`, `:194`, `:202`, `:210` gegen `agents/*.md:4` | ✅ belegt (behoben) |
| 8 | Die Wächter wirken: In der Session vom 16. Oktober 2026 hat `bauplan-guard` drei Befehle blockiert. Zwei davon waren Fehlalarme, weil sie `workspace.yaml` nur im Text erwähnten oder `docs/` in einen Stash legten | Session-Verlauf; Muster `bauplan-guard.sh:28-29` | ✅ belegt (Fehlalarme: außerhalb dieser Spec, siehe unten) |

## Soll-Bild

```
Aktion ─► Wächter-Hook ─┬─ Verstoß ─────────────────────────► exit 2 ─► blockiert
                        ├─ alles gut ───────────────────────► exit 0 ─► läuft
                        ├─ Eingabe unlesbar / python3 fehlt ► exit 2 ─► blockiert, Meldung nennt die Ursache
                        └─ Skript fehlt / Timeout ──────────► onFailure: "block" ─► blockiert
```

## Anforderungen

### A — Konfiguration

- [x] `"onFailure": "block"` an den drei Wächtern in `.claude/settings.json`. Hooks unter PostToolUse
      und Stop behalten den Standard `"continue"`: Ein Fehler beim Linter oder Bauplan-Bericht darf die Arbeit nicht stoppen.

### B — Skripte fail-closed

- [x] Ist die Hook-Eingabe nicht lesbar, endet jeder Wächter mit `exit 2`. Die Meldung auf stderr nennt
      Wächter und Ursache, zum Beispiel „git-safety: Hook-Eingabe nicht lesbar — Aktion blockiert (fail-closed)".
- [x] Fehlt `python3`, endet jeder Wächter mit `exit 2` und einer Meldung, die das sagt.
- [x] `protect-merchant-files`: Kann `ask()` die Rückfrage nicht erzeugen, endet der Hook mit `exit 2` statt `exit 0`.
- [x] `bauplan-guard`: Fehlt `bin/bauplan-guard.py`, endet der Hook mit `exit 2`, ebenso bei leerem `tool_name`.
- [x] Ein leeres Feld gilt nur dann als harmlos, wenn das Werkzeug es wirklich leer liefern kann. Bash hat
      immer `command`, Edit und Write haben immer `file_path`. Sonst gilt es als Fehler.

### C — Umgehung in `git-safety`

- [x] Globale Git-Optionen vor dem Unterkommando (`-C <dir>`, `-c <k=v>`, `--git-dir=…`, `--work-tree=…`)
      verhindern die Erkennung von `push`, `reset --hard` und `clean -f` nicht mehr.

### D — Prüfung in `harness-check`

- [x] H20: Jeder in `bin/harness-referenz.json` als Wächter geführte Hook hat in den Settings `"onFailure": "block"`.
- [x] H21: Die Modell-Spalte der Agenten-Tabellen in `.claude/README.md` stimmt mit dem `model` im Frontmatter überein.
- [x] H15 (Schema): `onFailure` wird vom SchemaStore-Schema akzeptiert. Kennt das Schema das Feld noch
      nicht, gilt das als Lücke im Schema, nicht als Befund. Die Ausnahme steht dann in der Referenz, mit Datum.

### E — Tests

- [x] `bin/test-waechter-hooks.sh` (Bash 3.2, wie `bin/test-theme-sync.sh`) ruft jeden Wächter mit
      vorbereiteten Eingaben auf. Abgedeckt sind:
      - ein Verstoß ergibt Exit 2
      - eine erlaubte Aktion ergibt Exit 0
      - kaputtes JSON ergibt Exit 2
      - leeres stdin ergibt Exit 2
      - ein PATH ohne `python3` ergibt Exit 2
      - jede Umgehung aus C ergibt Exit 2
- [x] Die Tests laufen im Workflow „Harness pruefen" mit.

## Akzeptanzkriterien

- [x] `bin/test-waechter-hooks.sh` ist grün, und jeder Fall aus E ist abgedeckt.
- [x] `harness-check` meldet H20, wenn `onFailure` an einem Wächter fehlt, und H21 bei einer Modell-Abweichung in der README.
      Auf dem Stand nach der Umsetzung meldet er „Harness sauber".
- [ ] Manuelle Probe in einer Session (Konrad): `.claude/hooks/git-safety.sh` vorübergehend unlesbar machen
      (`chmod 000`), dann `ls` ausführen lassen. Die Session blockiert mit „failed; blocking because onFailure is "block"".
      Danach `chmod 755` zurücksetzen.
- [x] Erlaubte Alltagsbefehle (`git status`, `git commit`, Edit einer `mdm-*`-Section) laufen unverändert.

## Constraints

- Keine Änderung an den Prüfregeln selbst (was blockiert oder nachfragt). Nur das Verhalten im Fehlerfall
  ändert sich, dazu kommt die Umgehung aus C.
- Voraussetzung ist Claude Code ab v2.1.295. Installiert ist 2.1.301, geprüft ist ebenfalls 2.1.301.
- Folge, die bewusst akzeptiert wird: Fehlt `python3`, sind Bash, Edit und Write in diesem Workspace blockiert.
  Die Meldung nennt die Ursache, damit die Behebung offensichtlich ist.
- Die CI-Läufe (`claude -p` in „Bauplan auffrischen" und „Harness aktuell halten") laufen mit denselben
  Hooks. Ein Fehler dort macht den Lauf rot statt ihn still durchzulassen.

## Außerhalb dieser Spec

- Fehlalarme des `bauplan-guard` (#8): Er blockiert auch Befehle, die geschützte Pfade nur im Text nennen,
  etwa ein Python-Skript mit dem Wort `workspace.yaml` und einem `>` im selben Befehl. Vorschlag: eigene Spec, die das Muster
  aus `bauplan-guard.sh:28-29` auf echte Schreibziele einengt.

## Entscheidungen (Konrad, 16. Oktober 2026)

1. Fehlt `python3`: alles blockieren.
2. Die Umgehung per `git -C` (Teil C) gehört in diese Spec.
3. Für die Fehlalarme des `bauplan-guard` gibt es eine eigene Spec: `bauplan-guard-fehlalarme.md`.

## Umsetzung (16. Oktober 2026)

| Teil | Änderung |
|---|---|
| A | `"onFailure": "block"` an den drei Wächtern in `.claude/settings.json` |
| B | Jeder Wächter prüft zuerst `python3` und endet bei unlesbarer Eingabe mit `exit 2`, die Meldung nennt den Wächter und die Ursache. `protect-merchant-files`: Die Rückfrage wird erst erzeugt und dann ausgegeben; scheitert das, wird blockiert. `bauplan-guard`: fehlendes Prüfskript, fehlender `tool_name` und Edit/Write ohne `file_path` blockieren |
| C | `git-safety` entfernt globale Git-Optionen (`-C`, `-c`, `--git-dir`, `--work-tree` u. a., auch mit Anführungszeichen) vor der Prüfung |
| D | H20 (Wächter registriert und mit `onFailure: block`), H21 (README-Modell = Frontmatter). Schema-Lücke `onFailure` in `schema_luecken` der Referenz vermerkt. `harness-check` nimmt das Feld vor der Validierung aus und meldet, sobald SchemaStore es kennt |
| E | `bin/test-waechter-hooks.sh`, 35 Fälle; läuft im Workflow „Harness pruefen" |

Nachweise:
- `bin/test-waechter-hooks.sh` vor der Änderung: 16 ok, 19 Fehler. Die 19 waren genau die Fail-open- und
  Umgehungsfälle; damit sind #2 bis #4 und #6 ausgeführt belegt. Nach der Änderung: 35 ok.
- `harness-check` vor Teil A: 3× H20. Danach online (Schema, `plugin validate`): „Harness sauber".
- Python-Tests: 58 grün (mit `jsonschema`); ohne `jsonschema` werden zwei Schema-Tests übersprungen.
- ❌ Offen: die manuelle Probe in einer Session (Akzeptanzkriterium 3). Sie greift erst, wenn der Haupt-Checkout
  auf dem neuen Stand ist.
