## Spec-Driven Development

Jede Aenderung beginnt mit einer **Spec-Datei** (`.claude/specs/`), die Anforderungen
und Akzeptanzkriterien definiert — BEVOR Code geschrieben wird.

1. **Spec schreiben** — Anforderungen definieren (was, nicht wie)
2. **Spec reviewen** — Konrad gibt Freigabe
3. **Implementieren** — Code wird gegen die Spec gebaut
4. **Validieren** — Akzeptanzkriterien pruefen

Konventionen: `.claude/specs/README.md`. Theme-Specs: `.claude/specs/theme/`.
Connector-Specs: `.claude/specs/connector/`.
Middleware-Specs: `.claude/specs/creditcheck/`, `.claude/specs/emailservice/`, `.claude/specs/payment-service/`.
Datalayer-Specs: `.claude/specs/datalayer/`.

## Workflow — Theme

Template-Arbeit: `/mdm-template` mit festen Phasen:
Spec → Extraktion (figma-extractor) → Plan (theme-planner) → **Freigabe** →
Implementierung (liquid-implementer) → Review (theme-reviewer + security-reviewer) →
Doku (docs-writer) → Uebergabe. Systemuebersicht: `.claude/README.md`

Grundprinzip: **Theme-First** — bestehende Hyper-Sections ueberschreiben, nicht neu bauen.
So wenig wie moeglich neu entwickeln, so viel wie noetig.
Mapping und Konventionen: `.claude/specs/theme/_conventions.md`.

## Workflow — Connector

Feature-Arbeit in eigenem Git-Worktree (siehe Git Worktree):
Worktree anlegen → rails-planner → **Freigabe** → rails-implementer (TDD: Red→Green→Refactor) →
rails-reviewer + security-reviewer → Doku (docs-writer) → Uebergabe → Worktree aufraeumen.

## Notizen (Apple Notes)

Fester Notiz-Satz, Praefix `MDM Shopify ::`. Konventionen: Skill `/mdm-notes`.
Ablage im Notes-Ordner `Shopify` mit Unterordnern `Tagebuch` und `Tickets`.
Update = Vollersetzung. Kein Markdown, kein `&`, Body-Zeile 1 = Titel.

## Shopify Dev MCP

Zu Beginn einer Liquid-Session `learn_shopify_api` aufrufen; Doku ueber
`search_docs_chunks`; vor Abschluss `validate_theme` laufen lassen.
Shopify parst Liquid strikt (seit 13.01.2026).
