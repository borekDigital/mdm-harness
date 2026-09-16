# Spec-Driven Development — Konventionen

## Prinzip

Jede Aenderung beginnt mit einer **Spec-Datei**, die Anforderungen, Akzeptanzkriterien
und Constraints definiert — BEVOR Code geschrieben wird.

## Ablauf

1. **Spec schreiben** — Anforderungen klar definieren (was, nicht wie)
2. **Spec reviewen** — Konrad gibt Freigabe
3. **Implementieren** — Code wird gegen die Spec gebaut
4. **Validieren** — Akzeptanzkriterien pruefen

## Dateistruktur

```
.claude/specs/
├── README.md              Diese Datei
├── harness/               Harness-Specs (Workspace, Setup, Werkzeuge)
├── themes/                Theme-Specs
│   ├── _conventions.md    markenuebergreifend (Mapping, Namensraeume)
│   ├── mdm/               nur MDM (Sections, Templates, Globales)
│   ├── borek/             nur Borek
│   └── imm/               nur IMM
│   ├── _conventions.md    Theme-First-Regeln und Patterns
│   ├── breadcrumbs.md     Section-Override-Spec
│   ├── page-title.md      Section-Spec
│   └── hilfe-template.md  Template-Spec (Blaupause fuer Unterseiten)
├── connector/             Connector-Specs (Features, APIs, Jobs)
├── creditcheck/           Creditcheck-Specs (Bonitaetspruefung, CustomerInfo)
├── emailservice/          Emailservice-Specs (Emarsys-Events, SAP-Enrichment)
├── payment-service/       Payment-Service-Specs (Saferpay-Flows, Frontend)
└── datalayer/             Datalayer-Specs (GTM, Consent, Pixel)
```

## Spec-Format

```markdown
# Spec: <Name>

## Ziel
Was soll erreicht werden? (1-2 Saetze)

## Kontext
Welche bestehenden Komponenten werden genutzt/ueberschrieben?

## Anforderungen
- [ ] Funktionale Anforderung 1
- [ ] Funktionale Anforderung 2

## Akzeptanzkriterien
- [ ] Kriterium 1 (pruefbar)
- [ ] Kriterium 2 (pruefbar)

## Constraints
- Theme-First: welche Hyper-Section wird ueberschrieben?
- Keine neuen Sections, wenn bestehende anpassbar sind
- Blast-Radius: welche Seiten sind betroffen?

## Status
ENTWURF | FREIGEGEBEN | IMPLEMENTIERT | VALIDIERT
```

## Regeln

- Kein Feature-Code ohne freigegebene Spec.
- Specs sind lebende Dokumente — werden bei Aenderungen aktualisiert.
- Akzeptanzkriterien muessen pruefbar sein (kein "sieht gut aus").
- Theme-Specs referenzieren immer die Hyper-Basis-Section, die ueberschrieben wird.
- Connector-Specs definieren API-Kontrakte und Testfaelle (TDD).
- Middleware-Specs (creditcheck, emailservice, payment-service) definieren Service-Kontrakte,
  externe API-Interaktionen (SAP, Emarsys, Saferpay) und PHPUnit-Testfaelle.
- Datalayer-Specs definieren GTM-Events, Consent-Logik und Pixel-Verhalten.
