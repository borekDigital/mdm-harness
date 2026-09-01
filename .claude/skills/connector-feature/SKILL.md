---
name: connector-feature
description: "End-to-End-Workflow fuer neue Features, Bugfixes und Extensions am MDM Shopify Connector (Rails 8.1 Backend). Feste Phasen mit Gates und automatischen Reviews. Nutzen bei: neues Backend-Feature, neue Extension, API-Erweiterung, Job-Aenderung, Bugfix am Connector."
user_invocable: true
---

# /connector-feature — Connector-Feature-Workflow

End-to-End-Workflow fuer Arbeit am MDM Shopify Connector (`connector/`).
Analog zu `/mdm-template` fuer das Theme, mit angepassten Phasen fuer Rails/React/Extensions.

## Aufruf

```
/connector-feature <ticket-id> [beschreibung]
```

## Phasen

### Phase 0: Setup
- Ticket-Ordner `Tickets/In-progress/<ticket-id>/` anlegen (falls nicht vorhanden)
- Git-Worktree anlegen: `cd connector && git worktree add ../connector-worktrees/<branch> -b feat/<ticket-id>-<kurzbeschreibung>`
- Ab hier alle Arbeit im Worktree-Pfad `connector-worktrees/<branch>/`
- `.env` aus `.env.template` kopieren
- Connector-Docs lesen: `connector/docs/overview.md` fuer Architektur-Kontext

### Phase 1: Planung + Spec-Skeletons
**Agent:** `rails-planner`

Prompt an den Agenten:
```
Ticket: <ticket-id>
Beschreibung: <beschreibung>
Worktree: connector-worktrees/<branch>/
Erstelle einen Implementierungsplan MIT Spec-Skeletons.
Lies zuerst connector/docs/overview.md,
dann die relevanten Dateien in connector/app/, connector/config/, connector/extensions/.
Plan-Artefakt nach Tickets/In-progress/<ticket-id>/plans/.
Spec-Skeletons direkt in den Worktree unter spec/.
```

Ergebnisse:
- Plan-Artefakt unter `Tickets/In-progress/<ticket-id>/plans/<ticket-id>-<name>-plan.md`
- Spec-Skeletons unter `connector-worktrees/<branch>/spec/` (mit `pending`)

### GATE: Freigabe durch Konrad
**MANDATORY STOP.** Plan + Spec-Skeletons werden Konrad praesentiert.
Keine Implementierung ohne explizite Freigabe.

Konrad bekommt:
- Plan-Synopsis (3-5 Punkte)
- Spec-Skeleton-Uebersicht (welche Specs, wie viele `it`-Bloecke)
- Offene Fragen
- Risiken

Konrad reviewed Plan UND Specs gemeinsam — die Specs SIND die Spezifikation.

Moegliche Antworten:
- „Plan passt" → weiter zu Phase 2 (Spec-Beschreibungen sind ab jetzt eingefroren)
- Aenderungswuensche → zurueck zu Phase 1
- Abbruch → Ticket zurueck in Backlog

### Phase 2: Implementierung — TDD (je Phase aus dem Plan)
**Agent:** `rails-implementer`

Jede Phase folgt dem TDD-Zyklus: **Red → Green → Refactor**.

Prompt an den Agenten:
```
Ticket: <ticket-id>
Plan: Tickets/In-progress/<ticket-id>/plans/<plan-datei>
Phase: <N>
Worktree: connector-worktrees/<branch>/
TDD-Pflicht: Erst Tests schreiben (Red), dann Implementation (Green), dann Refactor.
Setze Phase <N> des freigegebenen Plans um.
```

TDD-Schritte pro Phase (arbeitet mit eingefrorenen Spec-Skeletons):
1. **Red:** `pending` aus Skeletons entfernen, Assertions + Factories + Mocks schreiben. `bundle exec rspec` — Tests muessen fehlschlagen.
2. **Green:** Minimalen Code schreiben, bis alle Tests bestehen.
3. **Refactor:** Code aufraeumen, Tests muessen weiterhin gruen sein.

Skeleton-Regeln:
- `describe`/`it`-Beschreibungen aus Skeletons NICHT aendern oder loeschen.
- Zusaetzliche Specs sind erlaubt (als `# Zusatz: <Begruendung>` markieren).
- Abweichungen im Output-Report dokumentieren.

Validierung nach jeder Phase:
- `bundle exec rspec` — alle Tests gruen
- `bundle exec rubocop --format simple` — geaenderte Dateien clean
- `bundle exec brakeman -q` — keine neuen Warnings
- Migrations: `bin/rails db:migrate` (falls anwendbar)
- Extension-Configs: TOML valide

### Phase 3: Review (nach jeder Implementierungsphase)
**Agenten:** `rails-reviewer` + `security-reviewer` — **IMMER parallel in EINER Message**

```
Ticket: <ticket-id>
Plan: <plan-datei>
Phase: <N>
Geaenderte Dateien: <liste>
```

Ergebnisse:
- **APPROVED** → naechste Phase oder Doku
- **NEEDS_REVISION** → zurueck zu Phase 2 mit Handover Notes (max 3 Loops)
- **FAILED** → Stop, Konrad entscheidet

### Phase 4: Dokumentation
**Agent:** `docs-writer`

Nur nach APPROVED fuer alle Phasen. Erstellt:
- `connector/docs/<ticket-id>-<kurzbeschreibung>.md` — Projekt-Doku
- `Tickets/In-progress/<ticket-id>/plans/<ticket-id>-<name>-complete.md` — Completion

### Phase 5: Uebergabe + Worktree-Cleanup
- Commit-Message als Plain-Text-Codeblock (Conventional Commits, englisch, 50/72)
- Konrad committet und pusht selbst
- Bei Deploy-relevanten Aenderungen: Hinweis auf `./deploy.sh --staging` fuer Staging-Test
- Nach Merge: `cd connector && git worktree remove ../connector-worktrees/<branch>` + Branch loeschen

## Regeln

1. **Kein Code vor Freigabe.** Phase 2 startet erst nach Konrads explizitem OK.
2. **Spec-Skeletons eingefroren.** Nach Freigabe keine Aenderung an describe/it-Beschreibungen.
3. **TDD-Pflicht.** Jede Phase: Red → Green → Refactor. Kein Code ohne fehlschlagenden Test.
4. **Worktree-Isolation.** Alle Arbeit im Worktree, main bleibt sauber.
5. **Reviews immer parallel.** rails-reviewer und security-reviewer in einer Message.
6. **Max 3 Revision-Loops.** Nach dem dritten NEEDS_REVISION: Stop, Konrad entscheidet.
7. **Evidenz-Labels.** Alle Aussagen in Artefakten: ✅ Belegt / ⚠️ Vermutung / ❌ Unbekannt.
8. **RuboCop Shopify-Preset.** Geaenderte Dateien muessen clean sein.
9. **Secrets nur ENV.** Keine API-Keys, Tokens, Passwoerter in Code, Kommentaren oder Test-Fixtures.
10. **Keine KI-Spuren.** Weder in Code, Commits, noch Doku.

## Artefakt-Namenskonvention

```
Tickets/In-progress/<ticket-id>/
├── plans/
│   ├── <ticket-id>-<name>-plan.md        Plan
│   └── <ticket-id>-<name>-complete.md    Completion
connector/docs/
└── <ticket-id>-<kurzbeschreibung>.md     Projekt-Doku
```
