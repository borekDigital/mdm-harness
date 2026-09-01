# Visual-QA-Nachbesserung Runde 6 abgeschlossen — vollständiger Figma-Abgleich (Desktop-Typo + Mobile)

Ticket: MDM-RETOURE-01 · Datum: 24. August 2026

## Ergebnis

- Status: APPROVED (theme-reviewer ∥ security-reviewer; 1 Finding nach Re-Verifikation mit
  Spec-Evidenz zurückgezogen, security 0 Findings)
- Auslöser: Konrad meldete Breadcrumb-Font-Size 12 px und fragte, warum Figma-Werte nicht
  umgesetzt wurden — insbesondere die komplette Mobile-Darstellung. Neue Direktive:
  **alle Typografie-/Spacing-Werte jetzt umsetzen, aber strikt seitenlokal**; Globalisierung
  einzelner Werte erst nach dem Termin mit der Designerin.

## Scoping-Ansatz

`layout/mdm-theme.liquid:109` rendert `template.suffix` als Body-Klasse → auf der
Retoure-Seite trägt `<body>` die Klasse `retoure`. Alle Overrides liegen in der neuen,
rein seitenlokalen Datei `assets/mdm-page-retoure.css` unter dem Scope `.retoure` —
später leicht auf globale Werte umziehbar. Geladen wird sie im Head von
`layout/mdm-theme.liquid` hinter dem Guard `if template.suffix == 'retoure'`
(kein FOUC, null Blast-Radius für die ~60 anderen Templates dieses Layouts).

## Umgesetzte Abweichungen (alle in design-spec.md belegt)

### Desktop
1. Breadcrumbs font-size 10 → **12 px**, font-weight Links 400 → **600**,
   letztes Segment 700 → **600**, letter-spacing 0.08em → **1.2 px** (0.12rem)
2. Breadcrumb-Item-Gap: Separator-Margin 0.8 → **1.2 rem** (= Figma-Auto-Layout-Gap 12 px
   je Seite des Pipes, siehe Review-Klärung unten)
3. H1 ~48 px (heading_scale 120 % × 4rem) → **40 px**, font-weight **500**,
   letter-spacing normal
4. `parent_url` Platzhalter `/pages/hilfe-service` → **`/pages/hilfe-und-antworten-zu-haufigen-fragen`**
   (Admin-Seite von Konrad angelegt, ID 698882949501)

### Mobile (Frame 4030:273 — in Runde 6 erstmals umgesetzt)
5. Breadcrumbs ausgeblendet (im Figma-Mobile nicht vorhanden)
6. H1 ~33.6 px → **28 px**
7. Titel padding-bottom 36 → **24 px** (`.retoure .mdm-page-title.section--padding`,
   Spezifität 0,3,0 schlägt die var-basierte `.section--padding`-Mobilformel)
8. FAQ-Frage 18 px → **16 px / lh 1.62**; zusätzlich font-weight **500** (Desktop + Mobile)
9. Akkordeon-summary padding-y 16 → **12 px**
10. Akkordeon-Inhalt padding-bottom 16 → **8 px**
11. Buttons untereinander (`flex-direction: column`) + volle Breite (`width: 100%`;
    Text bleibt zentriert, `.btn` ist inline-flex + justify-center)
12. Seitlicher Rand 16 → **20 px** via `--page-padding: 2rem` — nur auf den drei
    Seiten-Sektionen, Header/Footer unberührt

## Geänderte Dateien

- `assets/mdm-page-retoure.css` — NEU, alle seitenlokalen Overrides (Scope `.retoure`)
- `assets/mdm-section-retoure-faq.css` — font-weight 500 der Frage + Mobile-Media-Query
- `templates/page.retoure.json` — parent_url auf neue Hilfe-Übersichtsseite
- `layout/mdm-theme.liquid` — guarded stylesheet_tag im Head (nur template.suffix 'retoure')

## Validierung

- `shopify theme check -o json`: 0 Offenses für alle 4 Dateien; JSON valide
- theme-reviewer: alle Kaskaden je Kante/Breakpoint durchgerechnet (0,3,0-Overrides
  gewinnen gegen {% style %}-Regeln der Breadcrumb-Section und gegen h1/.h1 bzw.
  .section--padding); Visual Parity gegen beide Referenz-PNGs (Desktop 4030-195,
  Mobile 4030-273) bestätigt
- security-reviewer: parent_url wird mit `| escape` ausgegeben (mdm-breadcrumbs.liquid:87),
  keine neuen externen Ressourcen, keine Secrets, Layout-Guard ohne Ausgabepfade für
  andere Templates

## Review-Klärung: Figma-Gap-Semantik

Der theme-reviewer meldete zunächst als Major-Finding, `margin: 0 1.2rem` erzeuge ~25 px
Abstand statt 12 px. Re-Verifikation an der Spec (HTML-Skizze: Pipe-Separatoren sind EIGENE
Flex-Items mit eigenen Figma-Nodes 4030:199/201; „gap zwischen Items: 12 px (flex)") und am
Referenz-PNG (Nav-Breite ≈ 430 px = Spec-Angabe) ergab: Der Auto-Layout-Gap gilt je
Item-Zwischenraum, also 12 px auf JEDER Seite des Pipes — die Umsetzung ist spec-konform,
Finding zurückgezogen, Verdict APPROVED. Lehre in der Agent-Memory des theme-reviewers
festgehalten (Gap nie als Text-zu-Text-Gesamtabstand lesen, wenn Separatoren eigene Nodes sind).

## Offene Punkte für den Termin mit der Designerin

1. **EB Garamond Medium 500**: Geladen ist nur der 600er-Schnitt (`ebgaramond_n6`).
   `font-weight: 500` ist spec-konform gesetzt, der Browser rendert bis auf Weiteres den
   600er-Schnitt. Klären: Medium-Schnitt laden oder 600 akzeptieren?
2. **Leere 84-px-Zone mobil** (Frame 4030:274): Zweck unklar (Leerraum? mobiler
   Zurück-Link?). Aktuell bleiben die Section-Paddings der ausgeblendeten Breadcrumbs
   als Abstandszone (~33.6 px) stehen.
3. **Globalisierung**: Welche der seitenlokalen Werte (Breadcrumb-Typo, H1-Größen,
   Akkordeon-Mobilwerte, 20-px-Seitenrand) auf globale Theme-Werte umziehen.

## Weiterhin offen (Content)

- Button-Ziel-URLs `#briefmarke` / `#paketschein` sind Platzhalter
- FAQ-Antworttexte Items 2–10 sind Platzhalter
