---
name: middleware-feature
description: "End-to-End-Workflow fuer neue Features, Bugfixes und Erweiterungen an den MDM Middleware-Services (creditcheck, emailservice, payment-service). Feste Phasen mit Gates und automatischen Reviews. Nutzen bei: neues Feature, API-Aenderung, Queue-Handler, Migration, Bugfix an einem der Middleware-Services."
user_invocable: true
---

# /middleware-feature — Middleware-Feature-Workflow

End-to-End-Workflow fuer Arbeit an den MDM Middleware-Services
(`creditcheck/`, `emailservice/`, `payment-service/`).
Analog zu `/connector-feature`, angepasst an PHP/Symfony.

## Aufruf

```
/middleware-feature <repo> <ticket-id> [beschreibung]
```

`<repo>` ist einer von: `creditcheck`, `emailservice`, `payment-service`.

## Phasen

### Phase 0: Setup
- Ticket-Ordner `Tickets/In-progress/<ticket-id>/` anlegen (falls nicht vorhanden)
- Feature-Branch anlegen: `cd <repo> && git checkout -b feat/<ticket-id>-<kurzbeschreibung>`
- Repo-Docs lesen: `<repo>/docs/` und `<repo>/README.md` fuer Architektur-Kontext
- Tech-Stack pruefen: PHP-Version (7.4 bei creditcheck, 8.3 bei emailservice/payment-service)

### Phase 1: Planung + Test-Skeletons
**Agent:** `symfony-planner`

Prompt an den Agenten:
```
Ticket: <ticket-id>
Repo: <repo>
Beschreibung: <beschreibung>
Erstelle einen Implementierungsplan MIT Test-Skeletons.
Lies zuerst <repo>/docs/ und <repo>/README.md,
dann die relevanten Dateien in <repo>/www/src/, <repo>/www/config/.
Plan-Artefakt nach Tickets/In-progress/<ticket-id>/plans/.
Test-Skeletons direkt in <repo>/www/tests/.
```

Ergebnisse:
- Plan-Artefakt unter `Tickets/In-progress/<ticket-id>/plans/<ticket-id>-<name>-plan.md`
- Test-Skeletons unter `<repo>/www/tests/` (mit `markTestIncomplete`)

### GATE: Freigabe durch Konrad
**MANDATORY STOP.** Plan + Test-Skeletons werden Konrad praesentiert.
Keine Implementierung ohne explizite Freigabe.

Konrad bekommt:
- Plan-Synopsis (3-5 Punkte)
- Test-Skeleton-Uebersicht (welche Tests, wie viele Methoden)
- Offene Fragen
- Risiken

Konrad reviewed Plan UND Tests gemeinsam — die Tests SIND die Spezifikation.

Moegliche Antworten:
- "Plan passt" -> weiter zu Phase 2 (Test-Methoden-Namen sind ab jetzt eingefroren)
- Aenderungswuensche -> zurueck zu Phase 1
- Abbruch -> Ticket zurueck in Backlog

### Phase 2: Implementierung — TDD (je Phase aus dem Plan)
**Agent:** `symfony-implementer`

Jede Phase folgt dem TDD-Zyklus: **Red -> Green -> Refactor**.

Prompt an den Agenten:
```
Ticket: <ticket-id>
Plan: Tickets/In-progress/<ticket-id>/plans/<plan-datei>
Phase: <N>
Repo: <repo>
TDD-Pflicht: Erst Tests schreiben (Red), dann Implementation (Green), dann Refactor.
Setze Phase <N> des freigegebenen Plans um.
```

TDD-Schritte pro Phase (arbeitet mit eingefrorenen Test-Skeletons):
1. **Red:** `markTestIncomplete` entfernen, Assertions + Mocks schreiben. Tests muessen fehlschlagen.
2. **Green:** Minimalen Code schreiben, bis alle Tests bestehen.
3. **Refactor:** Code aufraeumen, Tests muessen weiterhin gruen sein.

Skeleton-Regeln:
- Test-Methoden-Namen aus Skeletons NICHT aendern oder loeschen.
- Zusaetzliche Tests sind erlaubt (als `// Zusatz: <Begruendung>` markieren).
- Abweichungen im Output-Report dokumentieren.

Validierung nach jeder Phase:
- PHPUnit: `cd <repo>/www && bin/phpunit` — alle Tests gruen
- PHPStan: `cd <repo>/www && vendor/bin/phpstan analyse` (emailservice, payment-service)
- PHPCS: `cd <repo>/www && vendor/bin/phpcs` (emailservice)
- Migrations: `bin/console doctrine:migrations:migrate --no-interaction` (falls anwendbar)
- Frontend (payment-service): `cd <repo>/client && yarn test:unit` (falls geaendert)

### Phase 3: Review (nach jeder Implementierungsphase)
**Agenten:** `symfony-reviewer` + `security-reviewer` — **IMMER parallel in EINER Message**

```
Ticket: <ticket-id>
Plan: <plan-datei>
Phase: <N>
Repo: <repo>
Geaenderte Dateien: <liste>
```

Ergebnisse:
- **APPROVED** -> naechste Phase oder Doku
- **NEEDS_REVISION** -> zurueck zu Phase 2 mit Handover Notes (max 3 Loops)
- **FAILED** -> Stop, Konrad entscheidet

### Phase 4: Dokumentation
**Agent:** `docs-writer`

Nur nach APPROVED fuer alle Phasen. Erstellt:
- `<repo>/docs/<ticket-id>-<kurzbeschreibung>.md` — Projekt-Doku
- `Tickets/In-progress/<ticket-id>/plans/<ticket-id>-<name>-complete.md` — Completion

### Phase 5: Uebergabe
- Commit-Message als Plain-Text-Codeblock (Conventional Commits, englisch, 50/72)
- Konrad committet und pusht selbst
- Bei Deploy-relevanten Aenderungen: Hinweis auf CI-Pipeline und Docker-Deploy
- Nach Merge: Branch loeschen

## Regeln

1. **Kein Code vor Freigabe.** Phase 2 startet erst nach Konrads explizitem OK.
2. **Test-Skeletons eingefroren.** Nach Freigabe keine Aenderung an Methoden-Namen.
3. **TDD-Pflicht.** Jede Phase: Red -> Green -> Refactor. Kein Code ohne fehlschlagenden Test.
4. **PHP-Version beachten.** creditcheck = PHP 7.4 (kein match, keine Enums, keine Attributes).
5. **Reviews immer parallel.** symfony-reviewer und security-reviewer in einer Message.
6. **Max 3 Revision-Loops.** Nach dem dritten NEEDS_REVISION: Stop, Konrad entscheidet.
7. **Evidenz-Labels.** Alle Aussagen in Artefakten: Belegt / Vermutung / Unbekannt.
8. **Statische Analyse.** PHPStan/PHPCS muessen clean sein (wo vorhanden).
9. **Secrets nur ENV.** Keine API-Keys, Tokens, Passwoerter in Code, Kommentaren oder Test-Fixtures.
10. **Keine KI-Spuren.** Weder in Code, Commits, noch Doku.

## Artefakt-Namenskonvention

```
Tickets/In-progress/<ticket-id>/
├── plans/
│   ├── <ticket-id>-<name>-plan.md        Plan
│   └── <ticket-id>-<name>-complete.md    Completion
<repo>/docs/
└── <ticket-id>-<kurzbeschreibung>.md     Projekt-Doku
```
