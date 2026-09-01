---
name: mdm-block
description: "Per-Block-Workflow fuer einzelne Theme-Section-Overrides: ein Block = ein Branch = ein PR. Grundprinzip Theme-First — bestehende Hyper-Sections ueberschreiben, nicht neu bauen. Nutzen bei: Breadcrumbs anpassen, Multicolumn-Kacheln, Collapsible-Tabs, einzelne Section-Aenderung, /mdm-block <block-name> <ticket-id>."
argument-hint: "[block-name] [ticket-id]"
---

# /mdm-block — Einzelner Block-Override

Workflow fuer eine isolierte Theme-Section-Aenderung. **Ein Block = ein Branch = ein PR.**
Grundprinzip: bestehende Hyper-Sections ueberschreiben/erweitern, nicht neu bauen.

## Live-Kontext

- Offene Tickets: !`ls ~/MDM/Tickets/In-progress/ 2>/dev/null || echo "keine"`
- Git-Status Theme: !`git -C ~/MDM/theme status --short 2>/dev/null | head -5`

## Inputs

- `blockName` (Pflicht) — z. B. breadcrumbs, multicolumn, collapsible-tabs, rich-text
- `ticketId` (Pflicht — bei Fehlen Konrad fragen)
- `figmaNodeId` (optional) — wenn der Block aus Figma extrahiert werden muss

## Output Contract (jede Phase meldet an Konrad)

- status: OK | FAILED | NEEDS_INPUT | WORKFLOW_BLOCKED
- artifacts: erzeugte/geaenderte Dateien
- unknowns: offene Punkte

## Phasen

### Phase 0 — Kontext lesen

1. `Tickets/In-progress/<ticketId>/` pruefen — design-spec.md vorhanden?
2. Bestehende `mdm-*`-Kopie der Hyper-Section lesen (z. B. `mdm-breadcrumbs.liquid`).
   Falls keine Kopie existiert: Hyper-Original lesen, `mdm-*`-Kopie wird in Phase 2 erstellt.
3. `figma-mapping.md` konsultieren — gibt es bereits ein verifiziertes Mapping fuer diesen Block?
4. Falls `figmaNodeId` uebergeben und kein passender Abschnitt in der design-spec:
   Agent **figma-extractor** fuer diesen einzelnen Block starten (nicht die ganze Page).

### Phase 1 — Block-Plan

Agent **theme-planner** erstellt einen kompakten Block-Plan:
`Tickets/In-progress/<ticketId>/plans/<ticketId>-block-<blockName>-plan.md`

Der Plan muss enthalten:
- **Hyper-Quelle:** welche Original-Section wird ueberschrieben (mit `path:line`-Beleg)
- **Override-Strategie:** was aendert sich (CSS, Schema, Markup, Alignment)
- **Dateien:** anlegen/aendern (mit Begruendung)
- **Uebersetzungs-Keys:** neue Keys fuer en.default.json + de.json
- **Abgrenzung:** was gehoert NICHT in diesen Block-PR (Blast-Radius = null fuer andere Sections)

### MANDATORY STOP — Freigabe

Block-Plan-Synopse an Konrad. **Ohne explizite Freigabe keine Implementierung.**
Aenderungswuensche → zurueck zu Phase 1.

### Phase 2 — Implementierung

1. Agent **liquid-implementer** setzt den Block-Plan um.
2. Danach IMMER **theme-reviewer** UND **security-reviewer** — beide in EINER Message
   als zwei parallele Agent-Aufrufe.
3. APPROVED → `plans/<ticketId>-block-<blockName>-complete.md` schreiben.
4. NEEDS_REVISION → liquid-implementer automatisch mit Handover Notes neu starten (max. 3 Loops).
5. FAILED → Stop, Konrad konsultieren.

### Phase 3 — Uebergabe

1. Zusammenfassung: was entstand, wie testen (`shopify theme dev --store mdm-muenze`).
2. Commit-Message als Plain-Text-Codeblock — Konrad erstellt Branch + PR selbst.
3. Nach Konrads Abnahme: Block als erledigt im Ticket markieren.

## Regeln

1. **Ein Block = eine Section/ein Override.** Nicht mehrere Bloecke mischen.
2. **Theme-First:** bestehende Hyper-Section ueberschreiben, nicht von Grund auf neu bauen.
   Mapping-Hierarchie: (a) Hyper-Original direkt nutzbar → Template-JSON-Einbindung genuegt,
   (b) Override noetig → `mdm-*`-Kopie, (c) kein Hyper-Gegenstueck → Neubau (selten, begruenden).
3. **Alignment-Scope:** Aenderungen an einer Section duerfen andere Sections nicht beeinflussen.
   Seitenlokales CSS ueber Body-Klasse `template.suffix` (`layout/mdm-theme.liquid:109`),
   block-lokales CSS ueber Section-Selektor.
4. **Kein Push, kein Live-Deploy.** Konrad committet und pusht selbst.
5. Alle Artefakte deutsch, Evidenz-Labels, keine KI-Spuren.
6. Uebersetzungen: `en.default.json` + `de.json` immer paarig.

## Referenzen

- `.claude/skills/mdm-template/figma-mapping.md` — Figma-Komponenten ↔ Hyper-Dateien
- `.claude/skills/figma-to-liquid/SKILL.md` — Extraktions-Konventionen
- `.claude/skills/mdm-template/qa-checklist.md` — Pruefkatalog theme-reviewer
- `.claude/skills/mdm-template/security-checklist.md` — Pruefkatalog security-reviewer
