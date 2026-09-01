---
name: figma-to-liquid
description: "Extraktions- und Mapping-Konventionen Figma → Hyper-Liquid: MCP-Tool-Reihenfolge, Token-Mapping auf CSS-Custom-Properties, Asset-Pipeline, bekannte Grenzen des Figma MCP. Nutzen bei jeder Figma-Extraktion und wenn Design-Werte in Theme-Code übersetzt werden."
---

# figma-to-liquid — Extraktions-Konventionen

## Tool-Reihenfolge (offizieller Figma-Guide, fix)

1. `get_metadata` — Node-Baum sichten, logische Abschnitte identifizieren.
   **Immer auch auf Page-/Parent-Ebene**: alle Breakpoint-Frames (Desktop, Mobile, Tablet)
   des Designs auflisten und JEDEN extrahieren — „kein Mobile-Frame" nur mit diesem Beleg
   behaupten (Lehre MDM-RETOURE-01: Mobile-Frame 4030:273 existierte, wurde nicht extrahiert)
2. `get_screenshot` — Referenz-PNG (per curl in den Ticket-Ordner laden; URL ist kurzlebig)
3. `get_variable_defs` — Tokens der Selektion
4. `get_design_context` — **abschnittsweise** (Kind-Nodes), nie die ganze Page:
   große Selektionen liefern abgeschnittene Antworten
5. `download_assets` — Icons/Bilder, max. 20 Nodes pro Call

## Pflicht-Direktive für get_design_context

> „Target: Shopify Liquid section + vanilla CSS/JS for an Online Store 2.0 theme.
> No React, no Tailwind. Semantic HTML with CSS custom properties."

Ohne diese Direktive liefert Figma React+Tailwind — unbrauchbar fürs Theme.

## Token-Mapping

| Figma | Theme |
|---|---|
| Farb-Variable | vorhandene Hyper-CSS-Variable bevorzugen; sonst `--mdm-<name>` in der Component-CSS |
| Spacing (px) | direkt übernehmen; wiederkehrende Werte als `--mdm-space-*` |
| Typo-Styles | Hyper-Klassen bevorzugen (`font-heading`, `h1–h6`, `.rte`) — erst verifizieren, dann verwenden |
| Fonts | nur EB Garamond / Inter (self-hosted in `assets/`) — keine neuen Fonts ohne Freigabe |
| Breakpoints | aus bestehenden Hyper-CSS-Dateien ableiten (❌ noch nicht katalogisiert — bei erster Gelegenheit in figma-mapping.md nachtragen) |

## Übersetzungs-Prinzipien (Design-Werte → Hyper-Komponenten)

Diese vier Prinzipien decken die ganze Fehlerklasse ab, die beim Übersetzen von
Design-Werten in ein bestehendes Theme entsteht. Sie gelten für JEDE Komponente
(Buttons, Headings, Cards, Inputs …), nicht nur die dokumentierten Beispiele.
Immer alle vier prüfen — die Beispiele darunter sind Belege, keine abschließende Liste.

1. **Kanonisches Theme-Markup 1:1 nachbauen, nicht nur die Klasse setzen.**
   Bevor eine Komponente in `custom_liquid`/handgeschriebenem HTML nachgebaut wird, die
   Original-Markup-Struktur im Theme lesen (`sections/`, `snippets/`, `assets/theme.js`):
   Wrapper-Elemente, innere Spans, Pseudo-Elemente und z-index-Ebenen gehören zur Komponente.
   Eine nackte Klasse ohne die erwartete DOM-Struktur bricht sichtbar oder im Interaktions-State.
2. **Effektive Kaskade im Einbettungs-Kontext durchrechnen, nicht nur eigene Regeln/Variablen setzen.**
   Wird eine Komponente in einen anderen Styling-Kontext gesetzt (`.rte`, `.card`, Grid-Container),
   können dessen Selektoren die Komponentenregeln per Spezifität schlagen. Für JEDE relevante
   Eigenschaft (color, text-decoration, spacing) und JEDEN State (default/hover/focus/active) die
   tatsächlich gewinnende Regel bestimmen. Eine gesetzte CSS-Variable greift nur, wenn die
   Regel, die sie konsumiert, die Kaskade auch gewinnt — sonst explizite Deklaration mit
   ausreichender Spezifität (Scope-Selektor) nötig.
3. **Effektiven berechneten Wert prüfen, nicht die Utility-Semantik.**
   Utility-Klassen können Werte skalieren/transformieren (z. B. `.h1–.h6` via
   `calc(var(--font-heading-scale) * …)`, `text-transform`). Gibt das Design einen expliziten
   px-Wert vor, den effektiven Computed-Wert gegen die Spec prüfen und bei Abweichung explizit
   überschreiben — nie blind der Klasse vertrauen.
4. **Alle Interaktionszustände verifizieren, nicht nur den statischen Default.**
   Hover/Focus/Active/Disabled sind Render-States, die statisches Code-Lesen nicht sieht. Jeden
   vom Design definierten State durchdenken (Farbe, Slide-/Übergangs-Mechanik, Lesbarkeit) und
   bei interaktiven Komponenten Live-Sichtkontrolle im Dev-Server empfehlen.

### Verifizierte Belege (Hyper v1.3.3)

- **Prinzip 1 — Buttons brauchen `.btn__text`.** Hyper zeichnet den Hover-Slide über ein
  `::before` (z-index 0, `assets/theme.css:2225-2239`); das Label bleibt nur sichtbar in
  `<span class="btn__text">…</span>` (z-index 1, `:2240-2246`). Immer vollständig nachbauen:
  `<a class="btn btn--primary"><span class="btn__text">Label</span></a>`.
- **Prinzip 2 — `.rte` schlägt Button-Regeln.** `.rte a` (`assets/theme.css:1822`, Spezifität
  0,1,1) und `.rte a:hover` (`:1829`, 0,2,1) überstimmen `.btn--primary`/`.btn--secondary` color
  (0,1,0) und deren `:hover` (0,1,1). Folge: gesetzte `--color-button-text`-Variablen wirken
  nicht auf die Textfarbe, und `.rte a` unterstreicht den Button. Fix: `color` UND
  `text-decoration: none` explizit am Scope-Selektor
  (`.mdm-<x> .accordion-details__content .btn--primary` etc., 0,3,0) für default UND `:hover`.
- **Prinzip 3 — `.h5` skaliert.** `.h1–.h6` → `calc(var(--font-heading-scale) * var(--font-hN-size))`
  (z. B. `.h5` ≈ 25,92px ≠ 18px). Bei explizitem Design-px `font-size`/`line-height` in rem
  überschreiben.
- **Prinzip 4 — Hover-Umkehr.** Die Button-Hover-Farbumkehr liegt in `@media (hover: hover)`
  (`assets/theme.css:2429-2455`); nur im gerenderten Hover-State sichtbar → Live prüfen.

## Auto-Layout-Gap-Semantik

Figma-`gap` (itemSpacing) wirkt zwischen JEDEM benachbarten Auto-Layout-Kind — wie CSS-Flex-`gap`.
Sind Separatoren (Pipes, Icons) EIGENE Nodes, heißt „gap 12px": 12px auf JEDER Seite des
Separators (Text –12– Pipe –12– Text), NICHT 12px Gesamtabstand zwischen den Texten.
CSS-Nachbildung per Margin auf dem Separator: voller Gap-Wert je Seite (`margin: 0 1.2rem`
für gap 12px). Beleg: MDM-RETOURE-01 Runde 6, Nodes 4030:199/201.

## Asset-Pipeline

1. Download nach `Tickets/In-progress/<ticket>/assets-src/` (nie direkt nach `assets/`)
2. Übernahme ins Theme entscheidet liquid-implementer: Naming `mdm-icon-<name>.svg` / `mdm-<name>.<ext>`
3. SVG-Icons: vorhandene `assets/icon-*.svg` bevorzugen; neue SVGs ohne Scripts/Foreign Objects
4. Fotos: als Section-Setting (`image_picker`) vorsehen statt hartkodiert — Merchant tauscht Bilder im Editor

## Bekannte Grenzen (Figma MCP)

- Rate Limits: ernsthafte Arbeit braucht Dev-/Full-Seat; Calls bündeln
- Kurzlebige Asset-URLs — sofort herunterladen
- Auto-Layout-Qualität des Designfiles bestimmt die Codequalität; fehlendes Auto-Layout
  im design-spec als unknown vermerken
- Kein natives Code Connect für Liquid → Mapping über `mdm-template/figma-mapping.md` pflegen
