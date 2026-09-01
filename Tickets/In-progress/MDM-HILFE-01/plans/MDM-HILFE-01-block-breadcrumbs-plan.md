## Plan: Breadcrumbs Page-Alignment (Edge-to-Edge)

Die Breadcrumb-Section `sections/mdm-breadcrumbs.liquid` wird so umgebaut, dass der
Hintergrund-/Border-Bereich den vollen Viewport nutzt (edge-to-edge), waehrend der
Breadcrumb-Text am Content-Raster (`.page-width`) ausgerichtet bleibt. Das ist eine
**shopweite Aenderung** an einer bestehenden Section — kein seitenlokaler Override.

**Phasen:** 3

---

## 0. Beleglage

### 0.1 Ist-Zustand der HTML-Struktur

Aktuell rendert `sections/mdm-breadcrumbs.liquid:57-59` eine **einzige** Wrapper-Ebene:

```
<div class="section-breadcrumb mdm-breadcrumbs-{{ section.id }}
            page-width page-width--{{ container }} section--padding">
  <nav class="breadcrumbs ..."> ... </nav>
</div>
```

`.page-width` (`assets/theme.css:159-161`) setzt `margin: 0 auto; padding-inline: var(--page-padding)`.
Das bedeutet: **alles** — Hintergrund, Border-Bottom, Padding — ist auf die Content-Breite
beschraenkt. Ein sichtbarer border-bottom (via `.mdm-breadcrumbs-{{ id }}` und `show_divider`)
endet an der Content-Kante, nicht am Viewport-Rand.

Evidenz: ✅ `sections/mdm-breadcrumbs.liquid:57-59`, ✅ `assets/theme.css:159-161`

### 0.2 Soll-Zustand (Designerin-Forderung)

Breadcrumbs muessen an der **PAGE** aligned werden, nicht am **CONTENT**:
- Hintergrund und border-bottom laufen edge-to-edge (voller Viewport)
- Der Text (nav-Element) bleibt am Content-Raster ausgerichtet

### 0.3 Etabliertes Hyper-Pattern fuer dieses Layout

Hyper nutzt ein **Zwei-Ebenen-Muster** in mehreren Sections, z. B. `sections/shop-the-feed.liquid:50-51`:

```
<div class="section section-{{ id }} section--padding ...">          <!-- KEIN page-width -->
  <div class="section__container page-width page-width--{{ c }}">    <!-- Content-Raster -->
```

Der aeussere Container hat keinen `page-width`-Constraint und spannt daher den vollen
Viewport. Background, Borders, Color-Schemes wirken auf ihn. Der innere Container uebernimmt
die Content-Beschraenkung.

Weitere Beispiele: `sections/testimonials.liquid:82`, `sections/scrolling-banner.liquid:29`,
`sections/collapsible-tabs.liquid:49`, `sections/mdm-collapsible-tabs.liquid:54`,
`sections/collection-cards.liquid:67`.

Evidenz: ✅ `sections/shop-the-feed.liquid:50-51`, ✅ `assets/theme.css:159-161,163-165`

### 0.4 Blast-Radius

`sections/mdm-breadcrumbs.liquid` wird in **7 Templates** verwendet:

| Template | container | show_divider | Sonstiges |
|---|---|---|---|
| `product.json:14` | fixed | (nicht gesetzt, Default chevron) | custom_css fuer padding-inline |
| `product.mdm.json:14` | fixed | (nicht gesetzt) | custom_css fuer padding-inline |
| `product.flatrate.json:14` | fixed | (nicht gesetzt) | custom_css fuer padding-inline |
| `collection.json:14` | fixed | (nicht gesetzt) | — |
| `collection.mdm.json:14` | fixed | (nicht gesetzt) | — |
| `page.hilfe.json:5` | fixed | false | — |
| `page.retoure.json:5` | narrow | false | `mdm-page-retoure.css` hat eigene Overrides |

Evidenz: ✅ Belegt, alle Dateien gelesen

**Abwaertskompatibilitaets-Analyse:**

1. **Visuell unveraendert bei `show_divider: false`:** Wenn kein Border und kein Hintergrund
   sichtbar ist, ist die Breite des aeusseren Wrappers irrelevant. Das betrifft alle 7
   aktuellen Templates — keines setzt `show_divider: true`. Die Umstellung ist daher
   **visuell neutral** fuer den gesamten Bestand.
   Evidenz: ✅ Belegt (alle Template-Settings gelesen)

2. **Visuell korrekt bei `show_divider: true`:** Sobald jemand kuenftig `show_divider: true`
   im Editor aktiviert, laeuft der Border edge-to-edge — das ist das gewuenschte Verhalten.

3. **`section--padding` am aeusseren Wrapper:** Padding-Block wirkt weiterhin identisch,
   da `section--padding` (`assets/theme.css:168-171`) nur `padding-block-start/end` setzt,
   keine Inline-Dimensionen. Die vertikalen Polster bleiben also unabhaengig von der
   Wrapper-Breite identisch.
   Evidenz: ✅ `assets/theme.css:168-171`

4. **`mdm-page-retoure.css`:** Setzt `.retoure .section-breadcrumb` Styles (`:10,17,22`).
   Die Klasse `section-breadcrumb` bleibt am aeusseren Wrapper erhalten — alle Selektoren
   treffen weiterhin. Der Selektor `.retoure .section-breadcrumb .breadcrumbs` (`:10`) adressiert
   die nav unabhaengig von der Verschachtelungstiefe — funktioniert mit einer Ebene dazwischen
   identisch. Die Regel `.retoure .section-breadcrumb { --page-padding: 2rem }` (`:58`)
   wandert semantisch korrekt auf den inneren page-width-Container.
   Evidenz: ✅ `assets/mdm-page-retoure.css:10,17,22,56-60`

5. **`mdm-section-breadcrumbs.css`:** Selektiert `.mdm-breadcrumbs .breadcrumbs` (`:5`).
   Die Klasse `mdm-breadcrumbs` liegt aktuell nicht im Liquid — sie wird nur als CSS-Klasse
   adressiert, aber nie gerendert. Die **tatsaechlich gerenderte** Klasse ist
   `mdm-breadcrumbs-{{ section.id }}` (dynamisch). Der CSS-Selektor `.mdm-breadcrumbs`
   matcht daher **schon heute nicht** auf die Section. Die Regeln in
   `mdm-section-breadcrumbs.css` sind **toter Code**.
   Evidenz: ✅ `sections/mdm-breadcrumbs.liquid:58` (rendert `mdm-breadcrumbs-{{ section.id }}`),
   ✅ `assets/mdm-section-breadcrumbs.css:1-29` (adressiert `.mdm-breadcrumbs`)

   **Handlungsbedarf:** Entweder die CSS-Selektoren an die tatsaechliche Klasse anpassen
   ODER eine statische Klasse `mdm-breadcrumbs` zusaetzlich ins Markup aufnehmen. Letzteres
   ist die sichere Variante (additiv, kein Rewrite der CSS-Datei noetig).

6. **Product-Templates mit `custom_css`:** Die drei Produkt-Templates enthalten
   `"custom_css": ["@media (min-width: 1280px) {.breadcrumbs {padding-inline: 5rem; }}"]`.
   Dieser Selektor adressiert `.breadcrumbs` (die nav), nicht den Wrapper — er trifft
   unabhaengig von der Verschachtelungsebene.
   Evidenz: ✅ `templates/product.json:15-17`, `product.mdm.json:15-17`, `product.flatrate.json:15-17`

**Ergebnis:** Die Umstellung ist fuer alle 7 bestehenden Templates abwaertskompatibel.
Kein Template zeigt sichtbare Aenderungen, solange `show_divider: false` bleibt (Status Quo).
Die Bereicherung wirkt erst, wenn eine kuenftige Konfiguration Border/Hintergrund aktiviert.

### 0.5 Toter Code in `mdm-section-breadcrumbs.css`

Die CSS-Datei adressiert `.mdm-breadcrumbs`, das Liquid rendert aber `mdm-breadcrumbs-{{ section.id }}`.
Diese Diskrepanz besteht bereits vor dieser Aenderung — die Regeln in der Datei (border-bottom,
gap, font-size, font-weight, mobile overrides) greifen **nicht**. Stattdessen stammen die
sichtbaren Styles aus dem `{% style %}`-Block innerhalb des Liquid (Zeilen 7-47).

Evidenz: ✅ `sections/mdm-breadcrumbs.liquid:58` vs. ✅ `assets/mdm-section-breadcrumbs.css:1`

---

## Phasen

### 1. Phase 1: HTML-Umbau auf Zwei-Ebenen-Struktur

- **Ziel:** Der aeussere Container der Breadcrumb-Section spannt den vollen Viewport;
  ein neuer innerer Container uebernimmt die Content-Beschraenkung via `page-width`.

- **Dateien:**
  - **aendern:** `sections/mdm-breadcrumbs.liquid` — Umbau des Wrapper-Markups
    (Zeilen 57-59, 139). Kein Reuse-vs-Neubau-Konflikt: Die Datei ist bereits der mdm-Override
    des Hyper-Originals `sections/breadcrumbs.liquid`. Das Original bleibt unangetastet.

- **Schritte:**
  1. Den aeusseren `<div>` (Zeile 57-59) aufteilen: Die Klassen `page-width` und
     `page-width--{{ container }}` vom aeusseren auf einen neuen inneren `<div>` verschieben.
     Am aeusseren `<div>` verbleiben: `section-breadcrumb`, `mdm-breadcrumbs-{{ section.id }}`,
     `section--padding` sowie die Inline-Styles fuer `--section-padding-top/bottom`.
  2. Zusaetzlich die **statische Klasse `mdm-breadcrumbs`** am aeusseren `<div>` ergaenzen,
     damit die Selektoren in `mdm-section-breadcrumbs.css` kuenftig korrekt matchen
     (behebt den in 0.5 dokumentierten toten Code).
  3. Das `<nav>`-Element (Zeile 61-64) wird Kind des neuen inneren `<div>`, nicht mehr
     direktes Kind des aeusseren Wrappers.
  4. Das schliessende `</div>` fuer den neuen inneren Container vor dem `</div>` des
     aeusseren einfuegen (vor Zeile 139).
  5. Das Ergebnis folgt dem Hyper-Muster aus `sections/shop-the-feed.liquid:50-51`:
     aeusserer Container ohne `page-width` (edge-to-edge), innerer mit
     `page-width page-width--{{ container }}` (content-aligned).

- **Validierung:**
  - `shopify theme check --fail-level error` (Scope: nur `sections/mdm-breadcrumbs.liquid`)
  - JSON-Parse des Schemas (unveraendert, muss weiterhin valide sein)
  - Visueller Vergleich auf allen 7 Templates: **kein sichtbarer Unterschied** erwartet,
    da kein Template `show_divider: true` nutzt
  - Shopify Theme Editor: Section laesst sich oeffnen, Settings funktionieren, Preset laedt

### 2. Phase 2: CSS-Anpassung fuer Border und Hintergrund

- **Ziel:** Der `show_divider`-Border und ein potenzieller Hintergrund (Farbe/Bild) wirken
  auf den aeusseren (edge-to-edge) Container statt auf den inneren.

- **Dateien:**
  - **aendern:** `sections/mdm-breadcrumbs.liquid` — Den `{% style %}`-Block (Zeilen 7-47)
    anpassen:
    - Der `border-bottom`-Selektor (`.mdm-breadcrumbs-{{ section.id }}`, Zeile 9-11) bleibt
      auf dem aeusseren Container und wirkt damit automatisch edge-to-edge — **keine
      Aenderung noetig**, da die Klasse `mdm-breadcrumbs-{{ section.id }}` am aeusseren
      Wrapper verbleibt.
    - Pruefen, ob Regeln fuer `.breadcrumbs`, `.breadcrumbs--sep`, `.breadcrumbs--pipe`
      (Zeilen 14-46) weiterhin korrekt ueber die zusaetzliche Verschachtelungsebene matchen
      — ja, die Selektoren verwenden Nachfahren-Kombinator (Leerzeichen), nicht Kind-Kombinator (>).
  - **aendern:** `assets/mdm-section-breadcrumbs.css` — Die Selektoren `.mdm-breadcrumbs ...`
    matchen jetzt dank der in Phase 1 ergaenzten statischen Klasse. Pruefen, ob die
    border-bottom-Regel (Zeile 2) mit dem `show_divider`-Mechanismus im `{% style %}`-Block
    kollidiert (beide setzen `border-bottom` auf denselben Selektor). Falls ja: die
    statische Regel in der CSS-Datei entfernen oder an den inneren Container binden,
    um Doppel-Border zu vermeiden.

- **Schritte:**
  1. Den `{% style %}`-Block durchgehen: Sicherstellen, dass **Border-Regeln** (Zeile 9-11)
     auf den aeusseren Container wirken, **Text-/Nav-Regeln** (Zeile 14-46) auf die nav
     innerhalb des inneren Containers.
  2. `assets/mdm-section-breadcrumbs.css` Zeile 2 (`border-bottom: 0.1rem solid #D6CAB3`)
     evaluieren: Diese Regel wuerde **immer** einen Border rendern, unabhaengig vom
     `show_divider`-Setting. Da sie bisher toter Code war, ist das bislang nicht aufgefallen.
     Entscheidung: Diese Zeile entweder **entfernen** (der `{% style %}`-Block steuert den
     Border bereits korrekt via `show_divider`) oder sie dem neuen Setting unterordnen.
     Empfehlung: **Entfernen**, da der dynamische `{% style %}`-Mechanismus die korrekte
     Steuerung bereits liefert.
  3. Pruefen, ob `mdm-section-breadcrumbs.css` Zeile 19-28 (mobile overrides fuer
     `--section-padding-top/bottom`) mit dem Inline-Style am aeusseren Wrapper kollidieren.
     Der Inline-Style setzt die Custom Properties, die CSS-Datei ueberschreibt sie im
     Mobile-Breakpoint — das funktioniert, da beide auf demselben Element (aeusserer
     Wrapper mit Klasse `mdm-breadcrumbs`) liegen.

- **Validierung:**
  - `shopify theme check --fail-level error` (Scope: `sections/mdm-breadcrumbs.liquid`,
    `assets/mdm-section-breadcrumbs.css`)
  - Theme Editor: `show_divider: true` aktivieren — Border muss edge-to-edge laufen
  - Theme Editor: `show_divider: false` — kein Border sichtbar
  - Visueller Vergleich `page.retoure` im Mobile-Breakpoint: `mdm-page-retoure.css`-Regeln
    muessen weiterhin greifen (Breadcrumbs hidden, padding-override)

### 3. Phase 3: Template-Settings und Abnahme

- **Ziel:** Die Hilfe-Einstiegsseite (`page.hilfe.json`) zeigt die Breadcrumbs gemaess
  Figma-Spec mit Page-Alignment.

- **Dateien:**
  - **aendern:** `templates/page.hilfe.json` — Breadcrumb-Settings ggf. anpassen:
    - `show_divider: false` bleibt (Figma zeigt keinen sichtbaren Border am Kopfbereich
      der Hilfe-Einstiegsseite)
    - `padding_top: 40` und `padding_bottom: 16` bleiben (bereits in Phase 1 der
      Einstiegsseite gesetzt, Figma-Soll ist 48/16 — 40 ist das Range-Maximum und
      unter der Scoping-Direktive akzeptiert)
    - `container: "fixed"` bleibt (Content-Raster)

- **Schritte:**
  1. `page.hilfe.json` oeffnen und die Breadcrumb-Settings auf Konsistenz pruefen.
     Es sind voraussichtlich **keine Aenderungen** noetig, da die strukturelle Aenderung
     in der Section liegt und die Settings nur Werte steuern, die sich nicht aendern.
  2. Alle 7 Templates im Theme Editor und via `shopify theme dev` pruefen:
     - Visueller Vergleich mit dem Stand vor dem Umbau (kein sichtbarer Unterschied
       bei `show_divider: false`)
     - Responsives Verhalten auf 390px, 768px, 1024px, 1440px und 1920px
  3. Referenz-Screenshot `reference-4030-734.png` zum Abgleich der Breadcrumb-Position
     heranziehen: Der Text muss am Content-Raster ausgerichtet sein (120px Seitenabstand
     bei 1440px Viewport = `--page-padding: 5rem` bei 1200px+).

- **Validierung:**
  - `shopify theme check --fail-level error` (gesamtes Theme)
  - `validate_theme` via Shopify Dev MCP
  - Visueller Abgleich aller 7 Templates auf Desktop und Mobile
  - Theme Editor: Section oeffnet sich, alle Settings funktionieren, Preset laedt
  - Responsive Pruefung: 390px, 768px, 1440px
  - Retoure-Seite: `mdm-page-retoure.css`-Overrides greifen weiterhin korrekt

---

## Uebersetzungs-Keys

Keine neuen Keys erforderlich. Alle bestehenden Keys unter
`sections.mdm-breadcrumbs.settings.*` bleiben unveraendert. Das Feature „Page-Alignment"
ist ein reiner Markup-/CSS-Umbau ohne neue Schema-Settings.

---

## Risiken

1. **Shopweiter Blast-Radius:** Die Aenderung betrifft 7 Templates gleichzeitig.
   Risiko-Minderung: Die Analyse in 0.4 belegt, dass alle Templates `show_divider: false`
   nutzen oder das Setting gar nicht konfigurieren (Default: `true` im Schema, aber alle
   Templates, die das Setting explizit setzen, haben `false`). Fuer Templates ohne
   explizites Setting greift der Schema-Default `true` — das betrifft collection.json,
   collection.mdm.json und die drei Produkt-Templates. Hier wuerde nach dem Umbau erstmals
   ein edge-to-edge Border sichtbar werden. **Handlungsbedarf:** In Phase 3 den
   tatsaechlichen Ist-Zustand im Store verifizieren (der Theme Editor kann vom JSON-Default
   abweichen, wenn der Haendler den Wert manuell gesetzt hat).
   Evidenz: ✅ Schema-Default `sections/mdm-breadcrumbs.liquid:209` ist `true`;
   ❌ Unbekannt: ob im Live-Theme per Editor ein anderer Wert gesetzt wurde.

2. **Toter CSS-Code wird lebendig:** Durch Ergaenzung der statischen Klasse `mdm-breadcrumbs`
   greifen die bisher toten Regeln in `mdm-section-breadcrumbs.css`. Insbesondere Zeile 2
   (`border-bottom: 0.1rem solid #D6CAB3`) wuerde **immer** einen Border rendern — auch
   wenn `show_divider: false`. Phase 2 adressiert das durch Entfernen der Zeile.

3. **`--page-padding`-Override in `mdm-page-retoure.css:56-60`:** Setzt
   `--page-padding: 2rem` auf `.retoure .section-breadcrumb`. Nach dem Umbau liegt
   `.section-breadcrumb` am aeusseren Container (ohne `page-width`), waehrend
   `--page-padding` vom inneren Container (`page-width`) konsumiert wird. CSS Custom
   Properties vererben sich von Eltern auf Kinder — der Override auf dem aeusseren
   Container wird vom inneren geerbt. **Kein Bruch** erwartet, aber in Phase 3 zu
   verifizieren.

---

## Offene Fragen

1. **`show_divider` Schema-Default vs. Live-Zustand** — Der Schema-Default ist `true`
   (`sections/mdm-breadcrumbs.liquid:209`). Die Produkt- und Collection-Templates setzen
   dieses Setting nicht explizit in ihrem JSON. Haengt der Live-Wert vom Schema-Default ab
   oder hat Konrad ihn im Editor auf `false` gesetzt?
   - Option A: Im Store pruefen und ggf. alle 5 Templates um `"show_divider": false`
     ergaenzen, bevor der Umbau live geht.
   - Option B: Den Schema-Default von `true` auf `false` aendern (Breaking Change fuer
     neue Instanzen der Section, aber sicherer fuer den Bestand).

2. **Soll die statische CSS-Klasse `mdm-breadcrumbs` am aeusseren oder am inneren
   Container sitzen?** — Am aeusseren ist konsistent mit der Namensgebung (Section-Wrapper),
   erfordert aber das Bereinigen des border-bottom in der CSS-Datei. Am inneren wuerde die
   CSS-Datei nur den Content-Bereich adressieren.
   - Empfehlung: Am aeusseren, CSS-Datei bereinigen (Phase 2).

---

## Definition of Done

- [ ] `sections/mdm-breadcrumbs.liquid` nutzt Zwei-Ebenen-Struktur: aeusserer Container
      edge-to-edge, innerer Container mit `page-width page-width--{{ container }}`
- [ ] Statische Klasse `mdm-breadcrumbs` im Markup vorhanden (toter CSS-Code behoben)
- [ ] `mdm-section-breadcrumbs.css` bereinigt: keine unkontrollierte border-bottom-Regel
- [ ] `shopify theme check --fail-level error` auf `sections/mdm-breadcrumbs.liquid` sauber
- [ ] `validate_theme` via Shopify Dev MCP bestanden
- [ ] Uebersetzungen: keine neuen Keys noetig (bestaetigt)
- [ ] Section hat Editor-Preset (unveraendert vorhanden: `sections/mdm-breadcrumbs.liquid:250-253`)
- [ ] Responsive Verhalten: 390px, 768px, 1024px, 1440px geprueft
- [ ] Visuelle Paritaet mit `reference-4030-734.png` / `reference-4030-345.png`
      (Breadcrumb-Bereich: Text am Content-Raster, Border/Hintergrund edge-to-edge)
- [ ] Alle 7 Templates visuell regressionsgetestet: kein sichtbarer Unterschied bei
      bestehenden Settings
- [ ] `page.retoure.json`: `mdm-page-retoure.css`-Overrides greifen weiterhin
      (Breadcrumbs hidden auf Mobile, Padding-Overrides)
