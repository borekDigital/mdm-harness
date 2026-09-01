---
name: mdm-template
description: "Page-Level-Orchestrator: zerlegt ein Figma-Design in einzelne Bloecke und erstellt eine Block Map. Jeder Block wird dann als eigener PR via /mdm-block umgesetzt. Nutzen bei: neue Seite aus Figma, mehrere Sections auf einmal planen, /mdm-template <figma-url> <ticket-id>."
argument-hint: "[figma-url] [ticket-id]"
---

# /mdm-template — Page-Level-Orchestrator

Zerlegt ein Figma-Seitendesign in einzelne Bloecke und erstellt eine **Block Map**.
Jeder Block wird anschliessend als eigener PR umgesetzt (via `/mdm-block`).

## Live-Kontext

- Offene Tickets: !`ls ~/MDM/Tickets/In-progress/ 2>/dev/null || echo "keine"`
- Git-Status Theme: !`git -C ~/MDM/theme status --short 2>/dev/null | head -5`

## Inputs

- `figmaUrl` (Pflicht) — Frame-/Node-Link aus Figma
- `ticketId` (Pflicht — bei Fehlen Konrad fragen)

## Output Contract (jede Phase meldet an Konrad)

- status: OK | FAILED | NEEDS_INPUT | WORKFLOW_BLOCKED
- artifacts: erzeugte/geaenderte Dateien
- unknowns: offene Punkte

## Phasen

### Phase 0 — Setup

1. `Tickets/In-progress/<ticketId>/{plans,assets-src}` anlegen.
2. Git-Status pruefen — bei ungesicherten Aenderungen Konrad bitten zu committen.
3. Notizen (Skill `mdm-notes`): Ticket-Notiz anlegen bzw. lesen.

### Phase 1 — Extraktion (ganze Seite)

Agent **figma-extractor** (Input: figmaUrl, ticketId) → `design-spec.md`, Referenz-Screenshots, Assets.

Abnahmekriterien (wie bisher):
- Alle Breakpoint-Frames erfasst (Desktop UND Mobile/Tablet)
- Vollstaendige Masstabelle je Breakpoint
- Referenz-PNG je Breakpoint in `assets-src/`

### Phase 2 — Block Map

Agent **theme-planner** erstellt eine **Block Map** statt eines monolithischen Plans:
`Tickets/In-progress/<ticketId>/plans/<ticketId>-block-map.md`

Die Block Map listet fuer jeden visuellen Block der Seite:

```markdown
## Block Map: <Seitenname>

| # | Block (Figma) | Hyper-Section | Override-Typ | Abhaengigkeiten | Prioritaet |
|---|---|---|---|---|---|
| 1 | Breadcrumbs | breadcrumbs.liquid → mdm-breadcrumbs.liquid | Erweiterung (Alignment) | keine | hoch |
| 2 | Themenkacheln | multicolumn.liquid → mdm-multicolumn.liquid | Override (Kachel-Layout) | keine | hoch |
| 3 | FAQ-Accordion | collapsible-tabs.liquid → mdm-collapsible-tabs.liquid | Override (Styling) | keine | mittel |
| 4 | Muenzlexikon-Teaser | rich-text / image-with-text | Template-JSON | keine | niedrig |

### Block 1: Breadcrumbs
- **Figma-Nodes:** ...
- **Hyper-Quelle:** `sections/breadcrumbs.liquid` (Belegt: path:line)
- **Aenderungen:** Page-Alignment statt Content-Alignment, ...
- **Eigener PR:** ja

### Block 2: ...
```

Regeln fuer die Block Map:
1. **Theme-First:** Jeder Block MUSS auf eine bestehende Hyper-Section gemappt werden.
   Neubau nur wenn kein Hyper-Gegenstueck existiert (begruenden + Konrad fragen).
2. **Abhaengigkeiten explizit:** Wenn Block B auf Block A aufbaut, steht das in der Map.
3. **PR-Schnitt:** Jeder Block = ein PR. Abhaengige Bloecke koennen im selben PR landen,
   aber nur mit Begruendung.
4. **Prioritaet:** Konrad entscheidet die Reihenfolge.

### MANDATORY STOP — Freigabe der Block Map

Block Map an Konrad praesentieren:
- Welche Bloecke wurden identifiziert?
- Welche Hyper-Sections werden genutzt?
- Gibt es Abhaengigkeiten zwischen Bloecken?
- Vorgeschlagene Reihenfolge?

**Ohne Freigabe keine Implementierung.** Konrad kann:
- Bloecke streichen oder zurueckstellen
- Reihenfolge aendern
- Bloecke zusammenlegen oder weiter aufteilen

### Phase 3 — Block-Implementierung (je Block)

Fuer jeden freigegebenen Block: `/mdm-block <blockName> <ticketId>` ausfuehren.
Die Block Map dient als Eingabe fuer den theme-planner im Block-Workflow.

### Phase 4 — Abschluss

Wenn alle Bloecke fertig:
1. Template-JSON (`templates/page.<slug>.json`) erstellen, das die Sections zusammenfuegt.
   Das Template selbst ist ein eigener, letzter PR.
2. Agent **docs-writer** → Doku + Completion-Artefakt.
3. Notizen abschliessen.

## Regeln

1. Kein Push aufs Live-Theme; Uploads nur `--unpublished` und nur auf Anweisung.
2. `--theme-editor-sync` nie verwenden.
3. Alle Artefakte deutsch, Evidenz-Labels.
4. Reihenfolge fix; Phasen-Uebersprünge nur auf Anweisung von Konrad.
5. Extraktions-Konventionen: Skill `figma-to-liquid` beachten.
6. **Block Map vor Implementierung** — kein Code ohne freigegebene Block Map.

## Referenzen

- `.claude/skills/mdm-block/SKILL.md` — Per-Block-Workflow
- `.claude/skills/mdm-template/figma-mapping.md` — Figma ↔ Hyper Mapping
- `.claude/skills/figma-to-liquid/SKILL.md` — Extraktions-Konventionen
- `.claude/skills/mdm-template/qa-checklist.md` — Pruefkatalog theme-reviewer
- `.claude/skills/mdm-template/security-checklist.md` — Pruefkatalog security-reviewer
