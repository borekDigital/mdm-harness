# QA-Checkliste (theme-reviewer)

## Konventionen
- [ ] Neue Dateien tragen `mdm-`-Präfix (sections/snippets/blocks/assets), kebab-case
- [ ] Keine FoxEcom-Originaldatei verändert (git diff / Datei-Vergleich)
- [ ] Template-Naming: `page.<slug>.json` bzw. `<typ>.mdm.json`
- [ ] Umsetzung entspricht dem freigegebenen Plan (Datei-für-Datei-Abgleich)

## Liquid & Schema
- [ ] `shopify theme check -o json`: geänderte Dateien ohne error UND ohne warning
- [ ] `{% schema %}` valide, `name`/`settings`/`presets` vorhanden (Editor-Sichtbarkeit)
- [ ] JSON-Templates parsen fehlerfrei
- [ ] Keine deprecated Tags/Filter (strict parsing seit 13.01.2026)

## Accessibility (WCAG-orientiert, Shopify-Theme-Vorgaben)
- [ ] Heading-Hierarchie korrekt (eine H1 pro Seite, keine Sprünge)
- [ ] Kontrast: Text ≥ 4,5:1; großer Text/Icons/Input-Rahmen ≥ 3:1
- [ ] Touch-Targets ≥ 44×44 px
- [ ] Vollständig tastaturbedienbar, sichtbarer Fokus; Accordions/Modals: Esc + Fokus-Rückgabe
- [ ] `aria-expanded`/`aria-controls` bei Toggles; `aria-live` wo Inhalte dynamisch wechseln
- [ ] Kein Autoplay

## Performance (Shopify-Theme-Vorgaben, Lighthouse-Ziel ≥ 60)
- [ ] Bilder: `image_url` + `image_tag`, `width`/`height`, `srcset`/`sizes`
- [ ] LCP-Element nicht lazy (`fetchpriority="high"`), below-the-fold lazy
- [ ] JS deferred/Modul, erst bei Interaktion nachladen wo möglich
- [ ] Kritischer Content in Liquid gerendert, nicht per JS nachgezogen
- [ ] Keine neuen externen Ressourcen

## Übersetzungen
- [ ] Jeder neue Key in `en.default.json` UND `de.json`
- [ ] Setting-Labels in den `*.schema.json`-Pendants
- [ ] Kein hartkodierter sichtbarer Text im Liquid

## Visual Parity
- [ ] Referenz-PNG aus `Tickets/…/assets-src/` gelesen und verglichen
- [ ] Abstände/Typo/Farben entsprechen design-spec (Toleranz: gerundete Werte)
- [ ] **Jeder Spacing-/Padding-Wert der design-spec einzeln gegen die Umsetzung geprüft.**
      Die design-spec hält eine Maßtabelle mit ALLEN Padding-/Abstands-Werten (z. B. Breadcrumb-
      Bereich padding-y, Akkordeon-summary padding-y, accordion-content padding-top UND
      padding-bottom, Button-Padding, Gaps). Jeden dieser Werte gegen den effektiv gerenderten
      Wert abgleichen — nicht nur Typo/Farbe/Text. Zwei Fallen, an denen Spacing durchrutscht:
      (a) Spacing steht oft NUR im Figma-Dev-Mode (Pixel-Annotationen), nicht sichtbar in einer
      flachen Referenz-PNG → immer die design-spec-Maßtabelle als Quelle nehmen, nicht nur das PNG.
      (b) Die Hyper-Basisregel liefert häufig nur EINE Seite (z. B. `.accordion-standard
      .accordion-details__content { padding: 1.6rem 0 0 }` = nur top, bottom 0) → den effektiven
      Computed-Wert je Kante (top/right/bottom/left) prüfen, nicht die Existenz irgendeiner
      padding-Regel annehmen. Reicht ein Schema-`range` nicht bis zum Design-Wert (z. B. max 24 <
      28), muss `max` angehoben oder per CSS gelöst werden — Wert nicht stillschweigend kappen.
- [ ] Interaktionszustände aus der Spec umgesetzt (offen/geschlossen, Hover soweit definiert)
- [ ] **Jeder sichtbare String** gegen design-spec UND Referenz-PNG geprüft (Trenner-Glyph,
      Breadcrumb-/Menü-Labels, Titel). Auch Werte aus geteilten Locale-Keys (z. B.
      `general.breadcrumbs.home`) und live gerenderte Daten (`page.title` = Admin-Seitentitel)
      gegen die Spec verifizieren — nicht nur den theme-eigenen Default annehmen.
- [ ] **Bewusste Deviationen und geparkte „offene Punkte"** aus Plan/Notizen im Abschluss-Review
      erneut gegen das Design abgeglichen und explizit abgenommen (nicht stillschweigend als
      erledigt annehmen — genau hier rutschen Design-Abweichungen durch).
- [ ] **Render-Aktualität vor Screenshot-QA sichergestellt.** Vor jeder visuellen Beurteilung
      prüfen, dass die betrachtete Theme-Version die AKTUELLEN lokalen Dateien widerspiegelt
      (Dev-Server neu laden/neu starten; sicherstellen, dass nicht die published/eine gepushte
      Version betrachtet wird). Sonst erzeugt ein veralteter Render Phantom-Abweichungen und man
      „fixt" Code, der bereits korrekt ist. Bei Widerspruch Datei ↔ Screenshot IMMER zuerst die
      Datei als Wahrheit nehmen und die Render-Quelle klären, bevor Code geändert wird.
- [ ] **Content vs. Code getrennt.** H1 (`mdm-page-title.liquid`) und Breadcrumb-Endsegment
      (`mdm-breadcrumbs.liquid`) rendern `page.title` = Admin-Seitentitel. Weicht der angezeigte
      Titel vom Design ab, ist das eine Content-Lücke (Admin-Seite umbenennen), KEIN Code-Bug —
      nie per Liquid-Override „fixen". Vor QA verifizieren, dass die Admin-Seite den exakten
      Design-Titel trägt.

## Komponenten-Verifikation (prinzipienbasiert — deckt die ganze Fehlerklasse ab)
Diese vier Prüfungen gelten für JEDE eingebettete/handgeschriebene Komponente, nicht nur die
belegten Beispiele. Genauer Kontext: `.claude/skills/figma-to-liquid/SKILL.md` → „Übersetzungs-Prinzipien".
- [ ] **Kanonisches Theme-Markup vollständig?** Handgeschriebene Komponenten spiegeln die
      Original-DOM-Struktur (Wrapper-Spans, Pseudo-Element-Ebenen), nicht nur die Klasse.
      Beleg: Buttons brauchen `<span class="btn__text">` (`assets/theme.css:2225-2246`).
- [ ] **Effektive Kaskade im Einbettungs-Kontext durchgerechnet?** Für jede relevante
      Eigenschaft und jeden State die per Spezifität tatsächlich GEWINNENDE Regel bestimmt —
      nicht nur Variablen-/Regel-Präsenz geprüft. Kontext-Selektoren (`.rte a`, `.rte a:hover`,
      `assets/theme.css:1822/1829`) können Komponentenregeln schlagen; eine gesetzte CSS-Variable
      wirkt nur, wenn die konsumierende Regel gewinnt. Bei Abweichung: expliziter Override mit
      belegter Spezifität (Scope-Selektor) für default UND hover.
- [ ] **Effektiver Computed-Wert statt Utility-Semantik geprüft?** `.h1–.h6` skalieren via
      `--font-heading-scale` (z. B. `.h5` ≈ 25,92px ≠ 18px). Weicht ein expliziter Design-px-Wert
      von der Utility-Ausgabe ab, muss ein `font-size`-Override belegt sein.
- [ ] **Alle Interaktionszustände bewertet, nicht nur der statische Default?** Hover/Focus/Active/
      Disabled sind Render-States, die statisches Code-Review nicht sieht — jeden aus der Spec
      durchgerechnet (gewinnende Farbe/Regel je State, Lesbarkeit, Kontrast, Text nicht vom
      Hover-Slide verdeckt). Bei interaktiven/RTE-eingebetteten Komponenten Live-Sichtkontrolle
      im Dev-Server empfehlen; im Review-Verdict explizit vermerken, ob Live-Prüfung noch aussteht.
