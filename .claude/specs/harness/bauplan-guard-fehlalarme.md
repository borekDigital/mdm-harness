# Spec: Bauplan-Guard ohne Fehlalarme

Stand: 16. Oktober 2026
Quelle: drei blockierte Befehle in der Session vom 16. Oktober 2026; Folgespec zu `waechter-hooks-fail-closed.md`
Status: ENTWURF

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

- [ ] Blockiert wird nur, wenn ein geschützter Pfad **Ziel** einer zerstörenden Operation ist:
      - Argument von `rm`, `git rm`, `mv` (Quelle oder Ziel), `truncate`
      - Ziel einer Umleitung `>` oder `>>`
      - Ziel von `git checkout --`, `git restore` oder `git stash push --` (Entscheidung 2)
- [ ] Umleitungen auf `/dev/null` und Dateideskriptoren (`2>&1`, `>&2`) zählen nie als Ziel.
- [ ] Pfade in Strings, Heredocs und Kommentaren zählen nicht als Ziel.
- [ ] Fail-closed aus `waechter-hooks-fail-closed.md` bleibt: Lässt sich ein Befehl nicht zerlegen, wird blockiert.
- [ ] Die Prüflogik liegt in `bin/bauplan-guard.py` (wie bei `--check-write`), damit CI und Hook dieselbe Regel nutzen.

## Akzeptanzkriterien

- [ ] Die drei Befehle aus #1 bis #3 sind als Testfälle hinterlegt. #1 und #2 laufen durch, #3 je nach Entscheidung 2.
- [ ] `rm docs/bauplan/x.html`, `mv workspace.yaml w.bak`, `echo x > .claude/bauplan/theme-mdm.manifest.json`
      und `git rm -r docs/bauplan` bleiben blockiert.
- [ ] `grep -n tech workspace.yaml 2>/dev/null` und `cat docs/bauplan/index.html | head` laufen durch.
- [ ] Alle bestehenden Tests in `bin/test-waechter-hooks.sh` bleiben grün.

## Constraints

- Bash-Befehle vollständig zu zerlegen ist nicht möglich (Variablen, `eval`, Unterprozesse). Ziel sind die
  üblichen Formen. Im Zweifel blockiert der Guard (fail-closed).
- Das Memory-Fakt „Bauplan-Guard blockt Shell-Lesebefehle" wird nach der Umsetzung angepasst.

## Offene Entscheidungen (Konrad)

1. Lesebefehle, die geschützte Pfade nennen, immer durchlassen: ja (Vorschlag)?
2. Sollen `git stash push`, `git checkout --` und `git restore` auf geschützte Pfade blockiert werden? Vorschlag: ja,
   denn sie verwerfen Bestand im Arbeitsbaum, genau wie `rm`.
