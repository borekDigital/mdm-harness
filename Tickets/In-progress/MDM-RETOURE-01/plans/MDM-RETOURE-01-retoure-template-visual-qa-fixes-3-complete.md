# Visual-QA-Nachbesserung Runde 3 abgeschlossen — Breadcrumb-Bereich

Ticket: MDM-RETOURE-01 · Datum: 24. August 2026

## Ergebnis

- Status: APPROVED (theme-reviewer ∥ security-reviewer, 0 Revisions-Loops, 0 Findings)
- Auslöser: Live-Test durch Konrad — der Breadcrumb-Bereich wich vom Figma ab.

## Abweichungen und Ursachen (Fakten)

Die design-spec.md hatte alle Soll-Werte korrekt erfasst (Extraktion war fehlerfrei):
- Zeile 79: Home-Label „STARTSEITE"
- Zeile 80/82: Trenner = Pipe „|" (1px×14px, Stone-80), letzter Trenner Stone-100
- Zeile 83/104: „RETOURE & REKLAMATION" als aktuelles Segment und H1

Die Abweichungen entstanden NACH der Extraktion:

1. **Trenner Pipe → Chevron.** Bewusste, in Plan/Notizen dokumentierte Deviation
   („Shop-Konsistenz vor Design-Detail"). Kein Versehen, sondern eine damals getroffene
   Entscheidung. Jetzt auf Figma-Parität zurückgeführt — aber scoped.
2. **Home „STARTSEITE" → „Heim".** Impl nutzte den geteilten Key `general.breadcrumbs.home`
   (= „Heim"). Der design-spec-Wert „STARTSEITE" wurde als offener shopweiter Punkt geparkt
   und nie aufgelöst → durchgerutscht.
3. **Titel „Retoure & Reklamation" → „Retoure".** H1 und Breadcrumb-Endsegment rendern
   korrekt `page.title`; der Admin-Seitentitel ist „Retoure". KEIN Code-Bug — Datenlücke.

## Umgesetzt (Code)

- `sections/mdm-breadcrumbs.liquid`: neues Setting `separator_style` (select chevron|pipe,
  **default chevron**). Der Trenner-Capture verzweigt intern; alle Template-Zweige nutzen ihn.
  Pipe = `<span class="breadcrumbs--pipe" aria-hidden="true">` (0.1rem×1.4rem, #615b4f);
  letzter Trenner im page-Zweig `.breadcrumbs--sep-last .breadcrumbs--pipe` = #3e3a32 (Stone-100).
- `templates/page.retoure.json`: `separator_style: "pipe"`.
- `locales/*.schema.json` (alle 6): Labels für das neue Setting.
- `locales/de.json`: `general.breadcrumbs.home` „Heim" → „Startseite".

### Scoping / Blast-Radius

`mdm-breadcrumbs` wird shopweit genutzt (product.json, collection.json, product.mdm.json,
collection.mdm.json, product.flatrate.json). Der Pipe ist **nur** auf der Retoure-Seite aktiv;
alle anderen Templates behalten durch `default: 'chevron'` byteidentisch den Chevron
(vom Reviewer bestätigt). Der Home-Label-Wechsel wirkt dagegen shopweit (geteilter t:-Key) —
„Startseite" ist zugleich die korrektere deutsche Bezeichnung als „Heim".

## Nicht per Code gelöst (bewusst)

Titel „Retoure & Reklamation": **Konrad benennt die Admin-Seite** (Online Store → Seiten →
„Retoure") in „Retoure & Reklamation" um. Der URL-Handle `/pages/retoure` bleibt. Danach
zeigen H1 und Breadcrumb-Endsegment automatisch den vollen Titel. Kein Code-Override gebaut,
um keine zweite Quelle der Wahrheit zu schaffen.

## Validierung

- `shopify theme check -o json` (9 geänderte Dateien): 0 Errors / 0 Warnings
- Dev-MCP `validate_theme`: VALID (strict-parse-sauber)
- Rückwärtskompatibilität Chevron: vom Reviewer als byteidentisch belegt
- Visual Parity gegen assets-src/reference-4030-195.png: Pipe, STARTSEITE, letzter Trenner
  Stone-100, fettes Prussian-Endsegment — bestätigt
- security-reviewer: `separator_style` nur als if-Operand, kein unescaped Output; keine neuen
  externen Ressourcen/Secrets

## Root-Cause-Lehre (warum es durchrutschte)

Alle drei Punkte lagen in der design-spec vor — keiner war eine Extraktionslücke:
- (1) war eine bewusste Deviation ohne Rück-Abgleich gegen die Referenz-PNG im finalen Review.
- (2) war ein geparkter „offener Punkt", der nie als harter Visual-Parity-Fail behandelt wurde.
- (3) war eine Content/Daten-Lücke: der Admin-Seitentitel wurde nie gegen die design-spec-H1
  verifiziert.
→ Prävention: siehe Ergänzung in qa-checklist.md (Visual-Parity muss gegen die design-spec
  UND die Referenz-PNG jeden sichtbaren String prüfen; bewusste Deviationen und geparkte
  offene Punkte müssen im Abschluss-Review erneut gegen das Design abgeglichen und explizit
  abgenommen werden; live gerenderte Daten wie page.title gegen die Spec verifizieren).
