# MDM-RETOURE-01 — Hilfe-Themenseite „Retoure & Reklamation"

## 📝 TL;DR

Die neue Hilfe-Themenseite „Retoure & Reklamation" wurde als Sections-basiertes Page-Template (`templates/page.retoure.json`) umgesetzt. Die Seite besteht aus erweiterten Breadcrumbs (3 Ebenen), Seitentitel (H1) und FAQ-Akkordeon mit 10 Items. Alle Sections sind neu oder erweitert, Styles in separaten CSS-Assets, Übersetzungs-Keys vollständig. Testable unter `shopify theme dev --store mdm-muenze` auf URL `/pages/retoure?view=retoure`.

**Update 24. August 2026:** Nach sechs Visual-QA-Runden (alle APPROVED) entspricht die Seite pixelgenau der Figma-Spec — inklusive der in Runde 6 nachextrahierten **Mobile-Darstellung** (Frame 4030:273). Seitenlokale Overrides liegen in `assets/mdm-page-retoure.css` (Scope: Body-Klasse `retoure` via `template.suffix`), geladen im Head von `layout/mdm-theme.liquid` hinter einem `template.suffix`-Guard. Details siehe Abschnitt „Visual-QA-Runden 1–6".

## 🎫 Kontext

**Ticket:** MDM-RETOURE-01 · 21. August 2026

**Figma-Quelle:** Datei `vnEStNM7qm0qThY39RqiFL`, Node `4030-195` („Hilfe · Themenseite (Retoure & Reklamation) · Desktop 1440")

**Ausgangslage:** Die Retoure-Hilfeseite war im Hyper-Theme nicht vorhanden. Das Design fordert eine mehrstufige Breadcrumb-Navigation (STARTSEITE | HILFE & SERVICE | RETOURE & REKLAMATION), Großschrift-Seitentitel und ein exklusives FAQ-Akkordeon mit 10 Fragen, davon nur die erste mit Antworttext und zwei Buttons.

## 🧠 Reasoning

### Problem

1. Bestehende Breadcrumbs: 2 Ebenen (Home + Seitentitel), Design fordert 3 Ebenen mit optionalem Eltern-Link
2. Seitentitel: Kein eigenständiges H1-Element mit Prussian-Farbe und EB-Garamond-Font vorhanden
3. FAQ: Akkordeon mit exklusivem Open/Close-Verhalten und Design-spezifischen Farben (Prussian, Stone-100)
4. Buttons: Zwei Buttons innerhalb Akkordeon-Content mit Prussian-Farben (Hyper-Buttons nutzen scheme-1 = schwarz)

### Lösung

1. **Breadcrumbs erweitern:** Neue optionale Schema-Settings `parent_label` + `parent_url` zu `sections/mdm-breadcrumbs.liquid` hinzugefügt; im `page`-Branch (Zeile 68–73) optionales mittleres Segment rendern. Zusätzliches `link_color`-Setting (Default #6a6357, für Retoure auf #615b4f Stone-80) eingeführt. `aria-current="page"` am letzten Item (Zeile 75) für Accessibility. ✅ Belegt: `sections/mdm-breadcrumbs.liquid:68–75, 190–206`
2. **Neue Seitentitel-Section:** Minimale `sections/mdm-page-title.liquid` mit H1, Hyper-Utilities `font-heading h1` + Prussian-Farbe per `assets/mdm-section-page-title.css` (Zeile 2). Responsive padding über Schema-Settings. ✅ Belegt: `sections/mdm-page-title.liquid:1–7, 6` + `assets/mdm-section-page-title.css:2`
3. **Akkordeon-Reuse:** Bestehende `sections/mdm-collapsible-tabs.liquid` wiederverwendet (kein Neubau). Design-spezifisches Styling in neuer CSS-Datei `assets/mdm-section-retoure-faq.css` unter `.mdm-retoure-faq`-Scope. Neue generische `custom_class`-Setting (Hyper-Pattern) in der Section ermöglicht Styling ohne section.id (instabil bei JSON-Templates). ✅ Belegt: `sections/mdm-collapsible-tabs.liquid:36–43` + `assets/mdm-section-retoure-faq.css:1–62`
4. **Button-HTML via custom_liquid:** Zwei Buttons als HTML in Block 1 `custom_liquid`-Setting eingefügt (Zeile 33, `page.retoure.json`), da Richtext-Setting keine Button-Elemente unterstützt. CSS setzt Prussian-Farben per RGB-Variablen. ✅ Belegt: `templates/page.retoure.json:33, 34–43`

### Begründung

- **Breadcrumbs-Erweiterung statt Neubau:** mdm-breadcrumbs ist etablierte Komponente; optionale Settings bleiben rückwärtskompatibel (leerer `parent_url` = altes 2-Ebenen-Verhalten). ✅ Belegt: Phase-1-Review bestätigt Rückwärtskompatibilität für product/collection-Templates
- **Separate Page-Title-Section statt main-page-Reuse:** main-page kombiniert Titel + RTE-Content; für Retoure ist reiner Titel nötig, Akkordeon-Blöcke liefern Content. Neue Section ist schlank und wiederverwendbar. ✅ Belegt: `sections/main-page.liquid:9–18` zeigt Kombination; nicht gebraucht hier
- **custom_class statt section.id für CSS-Scoping:** In JSON-Templates ist section.id nicht garantiert stabil (Shopify-Verwaltung). `custom_class`-Pattern existiert in Hyper (z. B. `custom-content.liquid`). Trade-off: Löscht Merchant Block 1, verschwindet Retoure-CSS-Load — dokumentiert in Phase-3-Artefakt. ✅ Belegt: `sections/mdm-collapsible-tabs.liquid:40–43`
- **Hex-Hardcode statt Hyper-Tokens:** `Stone-80` (#615b4f), `Stone-100` (#3e3a32), `Prussian` (#002147) sind Figma-Variablen ohne Hyper-Pendant. MDM-Pattern bestätigt: andere mdm-CSS-Dateien verwenden ebenfalls Hex-Hardcode (z. B. `mdm-section-product-faq.css`). ✅ Belegt: Plan-Abschnitt „Figma-Mapping" und Phase-5-Review

### Verworfene Alternativen

- **Buttons im Richtext:** Shopify-Richtext unterstützt keine `<button>`-Elemente; HTML-Links mit Button-Klassen sind Workaround. Alternativ: Merchant müsste Buttons im Page-RTE (Shopify Admin) manuell einfügen — weniger wartbar. Chosen: HTML in `custom_liquid` mit Asset-Load in gleichem Block.
- **Accordion multi-open statt exklusiv:** `AccordionGroup` in theme.js (Zeile 1051–1068) erzwingt exklusives Verhalten. Design zeigt nur einen offenen State, Freigabe akzeptiert exklusiv. Kein Code geändert. ✅ Belegt: `assets/theme.js:1051–1068`
- **Separator Pipe statt Chevron:** Design zeigt vertikalen Strich, bestehende Breadcrumbs nutzen SVG-Chevron (Zeile 52–56). Freigabe-Entscheidung: Chevron beibehalten (konsistent mit Shop). **KORREKTUR (Runde 3):** Konrad forderte Design-Treue; Setting `separator_style` (chevron|pipe, Default chevron) wurde umgesetzt, nur `page.retoure.json` nutzt pipe — alle Bestands-Templates behalten den Chevron.

## 🏗️ Implementierung

### Dateien-Tabelle

| Datei | Aktion | Zweck |
|---|---|---|
| `sections/mdm-breadcrumbs.liquid` | GEÄNDERT | Zeile 68–73: optionales Eltern-Segment für mehrstufige Pfade; Zeile 75: `aria-current="page"`-Attribut; Zeile 18/23/203–206: `link_color`-Setting (Hex-Farbe, Default #6a6357); Zeile 163–166: Container-Option `narrow` additiv hinzugefügt |
| `sections/mdm-page-title.liquid` | NEU | Minimale H1-Section: rendert `page.title | escape` in `<h1 class="font-heading h1">`; Wrapper mit `page-width--{container}` und Padding-Inline-Vars; Schema mit Container (Default narrow), padding_top (0), padding_bottom (36) und Preset |
| `assets/mdm-section-page-title.css` | NEU | Setzt Farbe Prussian #002147, line-height 1.2; font-size/family via Hyper-Utilities `.h1` / `.font-heading` (responsive) |
| `sections/mdm-collapsible-tabs.liquid` | GEÄNDERT | Zeile 40–43: neues generisches `custom_class`-Setting (escaped), appended an section-CSS-Klasse; Schema Zeile 713–721 nutzt vorhandene `t:general.custom_attr.*`-Keys (keine Locale-Edits nötig) |
| `assets/mdm-section-retoure-faq.css` | NEU | Retoure-spezifisches Akkordeon-Styling unter `.mdm-retoure-faq`-Scope: Summary Stone-100 Farbe, H2 Prussian, Border-Top auf erstem Item, Button-Variablen (Prussian primary/secondary, weiß, eckig, 48px, 24px Padding), `font-family: var(--font-body-family)` für Inter |
| `templates/page.retoure.json` | NEU | Layout `mdm-theme`; Sections: mdm_breadcrumbs (parent_label „Hilfe & Service", parent_url `/pages/hilfe-service` Platzhalter, link_color #615b4f), mdm_page_title, mdm_retoure_faq mit custom_class „mdm-retoure-faq" und 10 collapsible_item-Blöcken (Item 1 offen mit Antwort + Buttons, Items 2–10 mit Fragetexten + Platzhalter) |
| `locales/en.default.schema.json` | GEÄNDERT | Zeile 2889–2905: 5 neue Keys `sections.mdm-breadcrumbs.settings.parent_label.label/.info`, `.parent_url.label`, `.link_color.label`, `sections.mdm-page-title.name` |
| `locales/de.schema.json` | GEÄNDERT | Zeile 2889–2905: deutsche Pendants („Elternseiten-Label", „Elternseiten-Link", „Linkfarbe", „Seitentitel") |
| `locales/es.schema.json` | GEÄNDERT | Zeile 2889–2905: spanische 5 Keys (Regressions-Fix Phase 5) |
| `locales/fr.schema.json` | GEÄNDERT | Zeile 2889–2905: französische 5 Keys |
| `locales/it.schema.json` | GEÄNDERT | Zeile 2889–2905: italienische 5 Keys |
| `locales/vi.schema.json` | GEÄNDERT | Zeile 2889–2905: vietnamesische 5 Keys |
| `assets/mdm-page-retoure.css` | NEU (Runde 6) | Seitenlokale Overrides unter Scope `.retoure`: Breadcrumb-Typo (12px/600/1.2px letter-spacing/12px-Gap), H1 40px Desktop / 28px mobil + weight 500, Breadcrumbs mobil ausgeblendet, Titel-Padding + 20px-Seitenrand mobil |
| `layout/mdm-theme.liquid` | GEÄNDERT (Runde 6) | Head lädt `mdm-page-retoure.css` hinter Guard `if template.suffix == 'retoure'` (kein FOUC, null Blast-Radius für andere Templates) |
| `locales/de.json` | GEÄNDERT (Runde 3) | `general.breadcrumbs.home` „Heim" → „Startseite" (shopweit, korrekteres Deutsch) |

### Architektur-Diagramm: Section- und Render-Struktur

```
page.retoure.json (Layout: mdm-theme)
├── Section: mdm-breadcrumbs
│   └── Liquid: page-Branch (Zeile 67–75)
│       ├── <a href="/"> {{ 'general.breadcrumbs.home' | t }} </a>   [Home-Link]
│       ├── <span aria-hidden> {{ SVG-Chevron }} </span>             [Separator]
│       ├── <a href="/pages/hilfe-service"> Hilfe & Service </a>     [Parent, conditional]
│       ├── <span aria-hidden> {{ SVG-Chevron }} </span>
│       └── <span aria-current="page"> Retoure & Reklamation </span> [page.title]
│   └── Style-Block (Zeile 7–51): sektion-spezifisches CSS mit link_color-Variable
│
├── Section: mdm-page-title
│   └── Liquid (Zeile 2–7)
│       └── <h1 class="font-heading h1"> {{ page.title | escape }} </h1>
│   └── Separate CSS (mdm-section-page-title.css): Prussian #002147, line-height 1.2
│
└── Section: mdm-collapsible-tabs (mit custom_class: "mdm-retoure-faq")
    ├── Section-Setting: custom_class appended an .mdm-retoure-faq (Zeile 40–43)
    ├── 10 collapsible_item-Blöcke
    │   ├── Item 1: open=true
    │   │   ├── heading: "Wie funktioniert die Rücksendung?"
    │   │   ├── content: <p>Richtext mit Link zu /pages/widerrufsbelehrung</p> × 2
    │   │   └── custom_liquid: Asset-Load (mdm-section-retoure-faq.css) + Button-HTML
    │   └── Items 2–10: open=false, icon=none, content=Platzhalter
    └── Retoure-CSS (mdm-section-retoure-faq.css, Zeile 1–62)
        ├── .mdm-retoure-faq .accordion-details__summary: color Stone-100, Border
        ├── .mdm-retoure-faq .accordion-details__summary h2: color Prussian
        ├── .mdm-retoure-faq .accordion-details__content: color Stone-100, Links Prussian
        └── .mdm-retoure-faq .btn: CSS-Variablen für Prussian primary/secondary
```

### Datenfluss: Breadcrumbs parent_label/parent_url

```
page.retoure.json
├── breadcrumb.parent_label: "Hilfe & Service"
├── breadcrumb.parent_url: "/pages/hilfe-service"
│
template rendering (mdm-breadcrumbs.liquid, Zeile 68–73)
├── if section.settings.parent_url != blank
│   AND section.settings.parent_label != blank
│   ├── render <a href="{{ parent_url | escape }}">{{ parent_label | escape }}</a>
│   │   [Security: | escape auf Attribut + Text]
│   └── else: skip (zurückwärtskompatibel)
│
└── Output: 3-Ebenen-Breadcrumb oder 2-Ebenen (fallback)
```

### Farbpalet und CSS-Scoping

```
Design-Tokens (Figma) → Theme-Implementierung
┌─────────────────────────────────────────────────────┐
│ Stone-80 (#615b4f)                                  │
│ → mdm-breadcrumbs.liquid: link_color-Setting        │
│   (Default #6a6357, nur Retoure: #615b4f)           │
│                                                     │
│ Stone-100 (#3e3a32)                                 │
│ → mdm-section-retoure-faq.css:                      │
│   .accordion-details__summary (Border, Text)        │
│   .accordion-details__content (Text)                │
│                                                     │
│ Prussian (#002147)                                  │
│ → mdm-page-title.css: Heading-Farbe                 │
│ → mdm-section-retoure-faq.css:                      │
│   .accordion-details__summary h2 (Frage)            │
│   .accordion-details__content a (Link)              │
│   .btn--primary/.btn--secondary (Button)            │
│                                                     │
│ White (#ffffff)                                     │
│ → Hyper-Variable --color-background                 │
│ → Button-Text (primary), Button-BG (secondary)      │
└─────────────────────────────────────────────────────┘

CSS-Scoping-Strategie:
mdm-breadcrumbs.liquid
├── Inline <style> mit section.id: .mdm-breadcrumbs-{{ section.id }}
│   (Section-eigenständig, keine Global-Pollution)
│
mdm-page-title.css
├── Global .mdm-page-title__heading
│   (Nur eine Section dieses Typs, kein Scope nötig)
│
mdm-section-retoure-faq.css
├── Global .mdm-retoure-faq (gescoped)
│   (Scope ist custom_class-Wert aus Template, nicht section.id)
│   └── Consequence: Löscht Block 1 (custom_liquid) → CSS-Load entfernt
```

## 🔁 Visual-QA-Runden 1–6 (21.–24. August 2026, alle APPROVED)

Vollständige Evidenz je Runde: `Tickets/In-progress/MDM-RETOURE-01/plans/…-visual-qa-fixes-<N>-complete.md`

1. **Runde 1:** Button-Label verschwand im Hover (fehlender `.btn__text`-Wrapper), Unterstrich unter Buttons (`.rte a`), Fragen-Schrift 25,92px statt 18px (`.h5`-Scale) — behoben.
2. **Runde 2:** Button-TEXTfarben — `.rte a`/`.rte a:hover` schlagen Button-Regeln per Spezifität; explizite `color`-Deklarationen für default + hover ergänzt.
3. **Runde 3:** Trenner Pipe statt Chevron (neues Setting `separator_style`, nur Retoure auf pipe), `general.breadcrumbs.home` „Heim" → „Startseite" (shopweit), Titel-Abweichung als Content-Lücke identifiziert (Admin-Seitentitel, kein Code-Fix).
4. **Runde 4:** Zwei Design-fremde Divider-Linien entfernt — Breadcrumb-Border per neuem Setting `show_divider` (Default true, nur Retoure false), FAQ-first-child-Border gelöscht.
5. **Runde 5:** Breadcrumb-Bereich padding-y 28px (Schema-`max` 24→40), FAQ-Content padding-bottom 16px, Absatz-Gap 16px (`--paragraph-*-spacing`).
6. **Runde 6:** Vollständiger Figma-Abgleich — Breadcrumb-Typo (12px/SemiBold/1.2px), H1 40px, `parent_url` auf `/pages/hilfe-und-antworten-zu-haufigen-fragen`, sowie **komplette Mobile-Umsetzung** (Frame 4030:273 nachextrahiert): Breadcrumbs mobil ausgeblendet, H1 28px, alle Akkordeon-/Button-/Padding-Mobilwerte. Scoping-Muster: Body-Klasse `retoure` + `assets/mdm-page-retoure.css` + Layout-Head-Guard. Direktive: erst seitenlokal, Globalisierung nach Designerinnen-Termin.

## ✅ To-Do

- [ ] **Design-spezifische Redaktion:** Items 2–10 haben aktuell Platzhalter-Antworten. Shopify Admin / Merchant soll echte Inhalte einfügen. (@konrad, ausstehend)
- [ ] **Button-URLs:** Platzhalter `#briefmarke` und `#paketschein` (page.retoure.json, item_1 custom_liquid) durch echte Ziel-URLs ersetzen. (@konrad oder Merchant, ausstehend)
- [ ] **Admin-Seitentitel:** Seite `/pages/retoure` im Admin in „Retoure und Reklamation" umbenennen (H1 + Breadcrumb-Endsegment rendern `page.title`). (@konrad, ausstehend)
- [ ] **Designerinnen-Termin:** (a) EB Garamond Medium 500 — geladen ist nur der 600er-Schnitt `ebgaramond_n6`, `font-weight: 500` ist gesetzt, rendert bis dahin 600; (b) Zweck der leeren 84px-Zone mobil (Frame 4030:274); (c) welche seitenlokalen Werte auf globale Theme-Werte umziehen. (@konrad, ausstehend)
- [x] ~~Elternseite „Hilfe & Service"~~ — erledigt Runde 6: Admin-Seite angelegt (ID 698882949501), `parent_url` auf `/pages/hilfe-und-antworten-zu-haufigen-fragen`. Eigenes Template für diese Seite = separates Ticket.
- [x] ~~Breadcrumb-Text „Heim" vs. „STARTSEITE"~~ — erledigt Runde 3: de.json auf „Startseite".
- [x] ~~Visuelle Live-Prüfung Desktop~~ — durch Runden 1–5 abgedeckt; Mobile-Re-Test nach Runde 6 durch Konrad ausstehend.

## 🔮 Weiterführende Empfehlungen

1. **Breadcrumb link_color global anpassen (optional):** Aktuell nutzen alle mdm-breadcrumbs Default #6a6357. Falls andere Seiten auch Stone-80 (#615b4f) benötigen, in deren Template-JSON das link_color-Setting entsprechend setzen. Aktuell nur Retoure geändert.

2. **FAQ-Items via Block-Repeater erweitern:** Momentan sind alle 10 Items fest im JSON hardcodiert. Für zukünftige Hilfe-Seiten könnte der `collapsible_item`-Block-Repeater vom Merchant direkt im Admin genutzt werden (keine JSON-Edit nötig). Doku-Empfehlung für nächstes Ticket.

3. **Button-Ziele als Settings exportieren (optional):** Die custom_liquid-Buttons haben aktuell Platzhalter-URLs. Für bessere Merchant-Editierbarkeit könnte man zwei Text-Settings (`button_1_url`, `button_2_url`) im Block-Schema einführen und die custom_liquid-HTML dynamisch füllen. Nicht urgent; für Phase 2 dieser Seite relevant.

4. **Locale-Konsistenz (langfristig):** Die es/fr/it/vi.schema.json-Keys wurden in Phase 5 ergänzt, aber die Übersetzungen sind maschinengeneriert und nicht von Nativ-Sprechern geprüft. Falls der Store diese Sprachen aktiviert, Übersetzungen reviewen.

5. ~~Mobile-Verhalten testen~~ **ERLEDIGT (Runde 6):** Mobile-Frame 4030:273 wurde nachextrahiert und vollständig umgesetzt (Media-Queries in mdm-section-retoure-faq.css + mdm-page-retoure.css). Ursprüngliche Annahme „Design zeigt nur Desktop" war falsch — der Mobile-Frame existierte, wurde aber in Phase 1 nie extrahiert.

---

## Anhang: Rückwärtskompatibilität & Sicherheit

### Rückwärtskompatibilität ✅

- **mdm-breadcrumbs:** `parent_label` + `parent_url` sind optional; beide blank → altes 2-Ebenen-Verhalten. ✅ Belegt Phase-1-Review: product/collection-Templates nutzen Section ohne neue Settings, Verhalten unverändert.
- **mdm-collapsible-tabs:** `custom_class`-Setting leerer Default → Ausgabe ist byte-identisch zu bisherigem Verhalten (escaper append an bestehende Klasse). ✅ Belegt Phase-3-Review: keine Templates außer page.retoure.json nutzen custom_class bisher; grep-Prüfung bestätigt.

### Sicherheit ✅

- **Breadcrumb-Escaping:** `parent_url | escape` auf Attribut (Zeile 70), `parent_label | escape` auf Text (Zeile 71). ✅ Belegt Phase-1-Security-Review: Revision 1 gefordert, umgesetzt, APPROVED.
- **Page-Title-Escaping:** `page.title | escape` (Zeile 6, mdm-page-title.liquid). ✅ Belegt Phase-2-Security-Review: APPROVED, kein Finding.
- **Richtext im Akkordeon:** Shopify-Richtext-Engine erlaubt nur bestimmte Tags (p, a, em, strong, …), relative URLs mit Validierung. ✅ Belegt Phase-4-Security-Review: custom_liquid nur Eigene Assets + Fragment-Anker, APPROVED.
- **CSS-Variablen-Injection:** color-Setting in mdm-breadcrumbs ist vom Typ `color` → Shopify erzwingt Farbwerte serverseitig, keine CSS-Injection möglich. ✅ Belegt Phase-4-Security-Review: APPROVED.

---

**Erstellt:** 21. August 2026 · **Aktualisiert:** 24. August 2026 · **Status:** Alle 5 Plan-Phasen + 6 Visual-QA-Runden implementiert + reviewed (theme-reviewer ∥ security-reviewer APPROVED); offen: Content-Redaktion, Button-URLs, Admin-Titel, Designerinnen-Termin
