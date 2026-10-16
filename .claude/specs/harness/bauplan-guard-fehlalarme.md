# Spec: Bauplan-Guard ohne Fehlalarme

Stand: 16. Oktober 2026
Quelle: drei blockierte Befehle in der Session vom 16. Oktober 2026; Folgespec zu `waechter-hooks-fail-closed.md`
Status: FREIGEGEBEN und IMPLEMENTIERT (16. Oktober 2026)

## Ziel

Der `bauplan-guard` blockiert Shell-Befehle nur noch dann, wenn sie Bauplan-Bestand wirklich löschen,
verschieben oder überschreiben. Befehle, die geschützte Pfade nur erwähnen, laufen durch.

## Ist-Zustand

Die Regel in `.claude/hooks/bauplan-guard.sh:28-29` besteht aus zwei unabhängigen Teilen:

```
Befehl enthält irgendwo  rm | git rm | mv | truncate | ">"
          UND irgendwo   docs/bauplan | .claude/bauplan/*.manifest.json | workspace.yaml
          ─► blockiert
```

Beide Teile müssen sich nicht aufeinander beziehen. Deshalb reicht ein `2>&1` oder `2>/dev/null` an einer
Stelle und das Wort `workspace.yaml` an einer anderen.

| # | Befund | Beleg | Status |
|---|---|---|---|
| 1 | Ein `grep` auf `workspace.yaml` in einem Befehl, der an anderer Stelle `2>/dev/null` enthält, wird blockiert | Session 16. Oktober 2026: Befehl mit `git pull -q 2>/dev/null` und `grep -n 'tech: "PHP' workspace.yaml` | ✅ belegt |
| 2 | Ein Python-Skript, das nur die Spec ändert und `workspace.yaml` im Spec-Text erwähnt, wird blockiert | Session 16. Oktober 2026: Inline-Python mit `open(p, "w")`; ausgewichen über ein Skript im Scratchpad | ✅ belegt |
| 3 | `git stash push -- docs` wird blockiert. Das ist in der Sache richtig, denn der Stash nimmt `docs/bauplan/index.html` aus dem Arbeitsbaum, ist aber kein `rm`/`mv`. Auslöser war das `2>&1` im selben Befehl | Session 16. Oktober 2026 | ✅ belegt (Auslöser) / ⚠️ ob ein Stash blockiert werden soll, entscheidet Konrad |
| 4 | Ausweichen ist leicht und unauffällig: dasselbe Skript als Datei im Scratchpad läuft durch. Der Guard schützt also nur gegen die offensichtliche Form | Session 16. Oktober 2026, Teil A | ✅ belegt |
| 6 | Gleiches Muster in `git-safety`: Ein `git commit` mit einer Commit-Message, die den Text „git push --force" enthält, wird als Force-Push blockiert. Ausweg war eine Message-Datei per `-F` | Session 16. Oktober 2026, Commit `2fe7ba9`; `.claude/hooks/git-safety.sh` (Muster `git push.*(--force\|-f)`) | ✅ belegt — Vorschlag: im Umfang dieser Spec mitlösen (Text in Strings und Heredocs ist kein Befehl) |
| 5 | Der Workaround steht schon im Agent-Memory („Bauplan-Guard blockt Shell-Lesebefehle") — die Fehlalarme sind wiederkehrend | `memory/bauplan-guard-blockt-shell.md` | ✅ belegt |

## Anforderungen

- [x] Blockiert wird nur, wenn ein geschützter Pfad **Ziel** einer zerstörenden Operation ist:
      - Argument von `rm`, `git rm`, `mv` (Quelle oder Ziel), `truncate`
      - Ziel einer Umleitung `>` oder `>>`
      - Ziel von `git checkout --`, `git restore` oder `git stash push --` (Entscheidung 2)
- [x] Umleitungen auf `/dev/null` und Dateideskriptoren (`2>&1`, `>&2`) zählen nie als Ziel.
- [x] Pfade in Strings, Heredocs und Kommentaren zählen nicht als Ziel.
- [x] Fail-closed aus `waechter-hooks-fail-closed.md` bleibt: Lässt sich ein Befehl nicht zerlegen, wird blockiert.
- [x] Die Prüflogik liegt in `bin/bauplan-guard.py` (wie bei `--check-write`), damit CI und Hook dieselbe Regel nutzen.

## Akzeptanzkriterien

- [x] Die drei Befehle aus #1 bis #3 sind als Testfälle hinterlegt. #1 und #2 laufen durch, #3 je nach Entscheidung 2.
- [x] `rm docs/bauplan/x.html`, `mv workspace.yaml w.bak`, `echo x > .claude/bauplan/theme-mdm.manifest.json`
      und `git rm -r docs/bauplan` bleiben blockiert.
- [x] `grep -n tech workspace.yaml 2>/dev/null` und `cat docs/bauplan/index.html | head` laufen durch.
- [x] Alle bestehenden Tests in `bin/test-waechter-hooks.sh` bleiben grün.

## Constraints

- Bash-Befehle vollständig zu zerlegen ist nicht möglich (Variablen, `eval`, Unterprozesse). Ziel sind die
  üblichen Formen. Im Zweifel blockiert der Guard (fail-closed).
- Das Memory-Fakt „Bauplan-Guard blockt Shell-Lesebefehle" wird nach der Umsetzung angepasst.

## Entscheidungen (Konrad, 16. Oktober 2026)

1. Lesebefehle, die geschützte Pfade nur nennen, laufen immer durch.
2. `git stash push`, `git checkout --` und `git restore` auf geschützte Pfade werden blockiert.
3. Der gleiche Fehlalarm in `git-safety` (#6) wird in dieser Spec mitgelöst.

## Umsetzung (16. Oktober 2026)

| Teil | Ort |
|---|---|
| Parser | `bin/befehl.py`: zerlegt in einfache Befehle mit Wörtern, Ausgabe-Umleitungen und `cd`-Verzeichnis. Heredoc-Inhalte sind Daten (ungequotet: `$(...)` darin wird mitgeprüft). `$(...)`, Backticks, `bash -c` und `eval` werden mitzerlegt. Wrapper wie `sudo`, `env`, `npx` und Variablen-Zuweisungen werden abgestreift |
| bauplan-guard | `bin/bauplan-guard.py --check-bash`. Ziele sind Argumente von rm/unlink/rmdir/shred/truncate/mv, das Ziel von cp/install, tee ohne `-a`, git rm, find mit `-delete` oder `-exec rm`, xargs rm in einer Pipeline, die Bestand nennt, und Ausgabe-Umleitungen. Ein Pfad trifft Bestand auch als Glob (`docs/*`) oder Vorfahre (`docs`, `.`, Projektpfad). stash/checkout/restore blockieren nur, wenn `git status` lokale Änderungen an Bestand zeigt, die die Pathspec erfasst |
| git-safety | Regeln von `.claude/hooks/git-safety.sh` nach `bin/git-safety.py` umgezogen, gleiche Meldungen. Geprüft werden Wörter: `git commit -m "git push --force"` läuft durch, `bash -c "git push --force"` nicht |
| Fail-closed | Nicht zerlegbar und Bestand bzw. `git`/`shopify` im Text: blockiert. `git status` scheitert: blockiert. Prüfskript fehlt oder endet mit einem anderen Code als 0 oder 2: blockiert |

Nachweise:
- `bin/test_befehl.py` (Parser, Bestand mit Wegwerf-Git-Repo, git-safety), 20 Tests mit Unterfällen, grün.
- `bin/test-waechter-hooks.sh`: 7 neue Fälle vor dem Umbau rot. Darunter die Session-Befehle #1 und #6 und
  `rm -rf docs` (ging bisher durch, weil die alte Regel Vorfahren nicht kannte). Danach 47 ok.
- Bestehende Suiten grün: `test_harness_check.py`, `test_harness_stand.py`, `test-theme-sync.sh` (50), `bauplan-guard.py --verify`.

Grenze ⚠️: `sed -i` auf geschützte Dateien bleibt erlaubt (wie bisher). Variablen in Pfaden (`rm $X`) werden nicht aufgelöst.
