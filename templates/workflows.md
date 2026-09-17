## Spec-Driven Development

Jede Aenderung beginnt mit einer **Spec** unter `.claude/specs/` (Anforderungen und
Akzeptanzkriterien, *was* — nicht *wie*), dann Freigabe durch Konrad, dann Implementierung
gegen die Spec, dann Validierung der Akzeptanzkriterien.
Ablage und Konventionen: `.claude/specs/README.md`.

## Workflow — Theme

Gilt fuer alle drei Marken-Themes; ohne Angabe ist `themes/mdm/` gemeint.

Grundprinzip **Theme-First**: bestehende Hyper-Sections ueberschreiben statt neu bauen —
so wenig Neuentwicklung wie moeglich. Mapping: `.claude/specs/themes/_conventions.md`.

- Ganze Seite aus Figma → Skill `/mdm-template` (zerlegt in eine Block Map)
- Einzelner Block → Skill `/mdm-block` (ein Block = ein Branch = ein PR)

## Workflow — Connector und Middleware

Feature-Arbeit im eigenen Worktree: Plan → **Freigabe** → Implementierung (TDD) →
Review-Paar (fachlicher Reviewer + security-reviewer) → Doku → Uebergabe.
Skills: `/connector-feature`, `/middleware-feature`.

## Shopify Dev MCP

Zu Beginn einer Liquid-Session `learn_shopify_api` aufrufen, Doku ueber
`search_docs_chunks`, vor Abschluss `validate_theme` laufen lassen.
Shopify parst Liquid strikt (seit 13.01.2026).
