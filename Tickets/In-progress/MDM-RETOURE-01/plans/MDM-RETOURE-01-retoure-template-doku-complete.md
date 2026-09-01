## Plan Complete: Projektdokumentation

Die deutsche Projektdokumentation für MDM-RETOURE-01 wurde verfasst. Sie dokumentiert alle implementierten Komponenten (Breadcrumbs-Erweiterung, Page-Title-Section, FAQ-Akkordeon), Architektur-Entscheidungen (custom_class-Scoping statt section.id, Hex-Hardcode-Pattern für Farben, Button-HTML via custom_liquid), Rückwärtskompatibilität und Sicherheits-Prüfungen. Alle Datei-Referenzen sind mit Zeilennummern belegt.

**Phasen abgeschlossen:** 5 von 5
1. ✅ Phase 1: Breadcrumbs-Erweiterung für mehrstufige Seitenpfade
2. ✅ Phase 2: Seitentitel-Section (mdm-page-title)
3. ✅ Phase 3: FAQ-Akkordeon-Section (Reuse mdm-collapsible-tabs)
4. ✅ Phase 4: Template-JSON und Section-Verdrahtung
5. ✅ Phase 5: Übersetzungen und Figma-Mapping-Update

**Alle Dateien angelegt/geändert:**
- docs/MDM-RETOURE-01-retoure-template.md (NEU)
- sections/mdm-breadcrumbs.liquid (GEÄNDERT, Phasen 1+4)
- sections/mdm-page-title.liquid (NEU, Phase 2)
- assets/mdm-section-page-title.css (NEU, Phase 2)
- sections/mdm-collapsible-tabs.liquid (GEÄNDERT, Phase 3)
- assets/mdm-section-retoure-faq.css (NEU, Phase 3+5)
- templates/page.retoure.json (NEU, Phase 4)
- locales/en.default.schema.json, de.schema.json, es.schema.json, fr.schema.json, it.schema.json, vi.schema.json (GEÄNDERT, Phasen 1+2+4+5)
- .claude/skills/mdm-template/figma-mapping.md (GEÄNDERT, Phase 5)

**Review-Status:** APPROVED (theme-reviewer ∥ security-reviewer)
- Phase 1: APPROVED (1 Revisions-Loop, security-reviewer forderte | escape auf parent_url, umgesetzt)
- Phase 2: APPROVED (0 Revisions-Loops)
- Phase 3: APPROVED (3 Minor-Findings, alle behoben und re-approved)
- Phase 4: APPROVED (0 Revisions-Loops)
- Phase 5: APPROVED (Phase Complete für Review-Handover, Regressions-Fix für es/fr/it/vi durchgeführt)

**Validierung:**
- `shopify theme check`: 0 Offenses auf allen Ticket-Dateien (Baseline 9E / 20W auf Altlasten, unverändert)
- Shopify Dev MCP `validate_theme`: SUCCESS auf allen 12 Ticket-Dateien
- JSON-Parse: OK (page.retoure.json ohne Banner)

**Vorschau:** shopify theme dev --store mdm-muenze
URL im Dev-Server: `http://127.0.0.1:9292/pages/retoure?view=retoure`
(Das `?view=`-Flag ist nötig, solange das Template nicht im Admin zugewiesen ist.)

**Empfohlene Commit-Message:**
```
feat(page-template): add retoure & reklamation help page

- Extend mdm-breadcrumbs with optional parent_label/parent_url settings
  for 3-level navigation breadcrumbs (resolves phase 1)
- Add mdm-page-title section for standalone H1 page titles (resolves phase 2)
- Reuse mdm-collapsible-tabs with custom_class scoping for retoure-specific
  FAQ styling and add mdm-section-retoure-faq.css asset (resolves phase 3)
- Create templates/page.retoure.json with 10 accordion items, first item
  with answer text + buttons, items 2-10 with placeholder content (phase 4)
- Add translation keys en.default.schema.json / de.schema.json and fix
  MatchingTranslations regression in es|fr|it|vi.schema.json (phase 5)
- All phases reviewed and approved by theme-reviewer & security-reviewer
```
