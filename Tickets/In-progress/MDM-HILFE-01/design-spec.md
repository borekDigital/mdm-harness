# Design-Spezifikation: MDM-HILFE-01
## Hilfe · Einstiegsseite

Erstellt: 24. August 2026
Figma-Datei: `vnEStNM7qm0qThY39RqiFL` („MDM — Templates (Internal)")
Root-Node (Figma-Seite): `4030:8` („FAQs")

---

## 0. Vorabklärung Frame-Menge (Pflicht-Check)

✅ Belegt per `get_metadata` auf Page-Ebene (`4030:8`): Die Datei hat genau zwei Seiten
(„FAQs" mit Inhalt, „Detailed Notes" — leer, 0×0). Auf der Seite „FAQs" existieren
genau **fünf** Top-Level-Frames:

| Node-ID | Name | Gehört zu |
|---|---|---|
| `4030:734` | Hilfe · Einstiegsseite · **VARIANTE FINAL** · Desktop 1441 | **dieses Ticket** |
| `4030:195` | Hilfe · Themenseite (Retoure & Reklamation) · Desktop 1440 | MDM-RETOURE-01 (bereits umgesetzt) |
| `4030:273` | Hilfe · Themenseite (Retoure & Reklamation) · Mobile 390 | MDM-RETOURE-01 (bereits umgesetzt) |
| `4030:345` | Hilfe · Einstiegsseite · Mobile 390 | **dieses Ticket** |
| `4030:428` | Hilfe · Rechtstext-Seite (Vorlage) · Desktop 1440 (`hidden="true"`) | anderes/zukünftiges Ticket, ausgeblendet |

**Ergebnis Varianten-Frage:** ✅ Belegt — es gibt für die Einstiegsseite **nur einen** Desktop-Frame
(`4030:734`, trägt den Zusatz „VARIANTE FINAL") und **nur einen** Mobile-Frame (`4030:345`,
ohne „VARIANTE FINAL"-Zusatz). Es existiert **keine** ältere/verworfene Desktop-Variante und
**keine** separate „VARIANTE FINAL"-Mobile-Variante auf dieser Seite — der Namenszusatz an
`4030:734` bezieht sich vermutlich auf einen früheren Abstimmungsstand, dessen Alternativen
in der Datei nicht mehr vorhanden sind (gelöscht oder nie in diese Datei übertragen). Da
sowohl Desktop als auch Mobile eindeutig sind (kein zweiter Kandidat pro Breakpoint), ist
die Auswahl nicht mehrdeutig — beide Frames werden als maßgeblich extrahiert.

**Ergebnis Newsletter-auf-Mobile-Frage:** ✅ Belegt — der Mobile-Frame `4030:345` endet nach
„Section · Münzlexikon" (`4030:423`, y=955, Höhe 299 → Summe 1254 = exakt die Gesamthöhe des
Frames). Es gibt **keinen** weiteren Abschnitt danach und **keinen** zweiten Mobile-Frame mit
Newsletter-Section auf der gesamten Seite. Die Newsletter-Section (`4030:789`, nur im
Desktop-Frame vorhanden) entfällt auf Mobile demnach **nicht durch ein fehlendes Artefakt**,
sondern ist im Design absichtlich weggelassen — bestätigt durch die Content-Annotation
**HUB-B4** direkt am Newsletter-Node (siehe Abschnitt 3.4): „Newsletter bewusst als **letzte**
Section." Diese Annotation bezieht sich zwar auf die Position innerhalb des Desktop-Layouts,
enthält aber keinen Hinweis auf eine Mobile-Variante — die vollständige Auslassung auf Mobile
bleibt eine ⚠️ Vermutung bzgl. der Absicht (Layoutentscheidung), auch wenn das Fehlen selbst
✅ belegt ist. **Empfehlung an den Planner:** bei Konrad rückfragen, ob Newsletter auf Mobile
unterhalb der Münzlexikon-Section ergänzt werden soll oder bewusst entfällt (z. B. weil Hyper
bereits eine globale Footer-Newsletter-Section einsetzt).

---

## 1. Überblick

| Eigenschaft | Wert | Evidenz |
|---|---|---|
| Desktop-Frame-Name | `Hilfe · Einstiegsseite · VARIANTE FINAL · Desktop 1441` | ✅ get_metadata |
| Desktop-Node-ID | `4030:734` | ✅ get_metadata |
| Desktop-Breite | 1440 px | ✅ get_metadata |
| Desktop-Höhe | 1265 px | ✅ get_metadata |
| Mobile-Frame-Name | `Hilfe · Einstiegsseite · Mobile 390` | ✅ get_metadata |
| Mobile-Node-ID | `4030:345` | ✅ get_metadata |
| Mobile-Breite | 390 px | ✅ get_metadata |
| Mobile-Höhe | 1254 px | ✅ get_metadata |
| Canvas-Position Desktop | x=100, y=100 | ✅ get_metadata |
| Canvas-Position Mobile | x=4175, y=100 | ✅ get_metadata |
| Template-Typ | `page.<slug>.json` (Hilfe-Einstiegs-/Landingpage, verlinkt vermutlich auf `page.retoure.json`-artige Themenseiten) | ⚠️ Vermutung aus Seitenstruktur |
| Desktop Layout-Breite | Content-Spalte 1200 px (Kachel-Grid), 1440 px full-bleed (übrige Sections), seitlicher Innenabstand 120 px | ✅ get_design_context |
| Mobile Layout-Breite | Content-Spalte 350 px, seitlicher Abstand je 20 px | ✅ get_metadata / get_design_context |
| Seitenaufbau (Reihenfolge, beide Breakpoints) | Kopfbereich → Themenkacheln (6 Kacheln) → Section Münzlexikon → **[nur Desktop]** Section Newsletter | ✅ get_metadata |

Referenz-Screenshots:
- Desktop: `assets-src/reference-4030-734.png` ✅ (1440×1265 px, heruntergeladen 24. August 2026)
- Mobile: `assets-src/reference-4030-345.png` ✅ (390×1254 px, heruntergeladen 24. August 2026)

---

## 2. Tokens

Alle Werte ✅ aus `get_variable_defs` (auf `4030:734` und `4030:345` — identisches Set,
Mobile ohne `Stone-5`, da die Newsletter-Section dort fehlt).

| Figma-Variablenname | Hex-Wert | Vorgeschlagene CSS Custom Property | Hyper-Äquivalent (figma-mapping.md) |
|---|---|---|---|
| `Stone-80` | `#615b4f` | `--color-stone-80` | ❌ kein Hyper-Token — MDM-Pattern = Hex-Hardcode (bereits in mdm-CSS verwendet, siehe mapping.md) |
| `Stone-100` | `#3e3a32` | `--color-stone-100` | ❌ kein Hyper-Token — MDM-Pattern = Hex-Hardcode |
| `Stone-20` | `#d6cab3` | `--color-stone-20` | ❌ **Neu in diesem Ticket** — bisher nicht in figma-mapping.md; nur als Kachel-Rahmenfarbe genutzt |
| `Stone-5` | `#f6f3ee` | `--color-stone-5` | ❌ **Neu in diesem Ticket** — bisher nicht in figma-mapping.md; nur als Newsletter-Section-Hintergrund (Desktop) genutzt |
| `Prussian` | `#002147` | `--color-prussian` | ❌ kein Hyper-Token — MDM-Pattern = Hex-Hardcode |
| `White` | `#ffffff` | `--color-white` | ⚠️ entspricht vermutlich Hyper `--color-background` (Standard weiß), ungelesen |

### Typografie — Desktop

Alle Werte ✅ aus `get_design_context`.

| Rolle | Font | Weight | Size | Line-Height | Letter-Spacing | Text-Transform | Farbe |
|---|---|---|---|---|---|---|---|
| Breadcrumbs (beide Segmente) | Inter | SemiBold (600) | 12 px | 1.4 | 1.2 px | uppercase | 1. Segment „STARTSEITE": `Stone-80`; 2. Segment „HILFE & SERVICE" (aktuelle Seite): `Prussian` |
| H1 | EB Garamond | Medium (500) | 40 px | 1.2 | keiner | keiner | `Prussian` |
| Kachel-Titel (`Bestellung` etc.) | Inter | SemiBold (600) | 19 px | 1.55 | keiner | keiner | `Prussian` |
| Kachel-Beschreibung | Inter | Regular (400) | 15 px | 1.55 | keiner | keiner | `Stone-100` |
| H2 (Münzlexikon, Newsletter) | EB Garamond | Medium (500) | 32 px | 1.2 | keiner | keiner | `Prussian` |
| Fließtext (`p`, Münzlexikon/Newsletter) | Inter | Regular (400) | 16 px | 1.7 | keiner | keiner | `Stone-100` |
| Button-Label `btn--secondary` (Münzlexikon) | Inter | Bold (700) | 16 px | 1.4 | keiner | keiner | `Prussian` |
| Button-Label `btn--primary` (Newsletter „Anmelden") | Inter | Bold (700) | 16 px | 1.4 | keiner | keiner | `White` |
| Newsletter-Input Placeholder | Inter | Regular (400) | 16 px | 1.4 | keiner | keiner | `Stone-80` |
| Newsletter-Hinweistext | Inter | Regular (400) | 14 px | 1.7 | keiner | keiner | `Stone-80` |

### Typografie — Mobile

| Rolle | Font | Weight | Size | Line-Height | Farbe | Unterschied zu Desktop |
|---|---|---|---|---|---|---|
| Breadcrumbs | Inter | SemiBold (600) | 12 px | 1.4 | wie Desktop | identisch |
| H1 | EB Garamond | Medium (500) | **28 px** | 1.2 | `Prussian` | kleiner (Desktop 40 px); **einzeiliger Fließtext statt 2-Zeilen-Hardwrap** — Text ist derselbe, aber ohne manuellen Zeilenumbruch gesetzt (Layer `4030:351` enthält den vollen Satz „Hilfe und Antworten zu häufigen Fragen" als ein Textblock) |
| Kachel-Titel | Inter | SemiBold (600) | **17 px** | 1.55 (ohne expliziten Wert im Code, `leading-[1.55]` am Text-Wrapper) | `Prussian` | kleiner (Desktop 19 px) |
| Kachel-Beschreibung | Inter | Regular (400) | **14 px** | 1.55 | `Stone-100` | kleiner (Desktop 15 px) |
| H2 (Münzlexikon) | EB Garamond | Medium (500) | **22 px** | 1.2 | `Prussian` | kleiner (Desktop 32 px) |
| Fließtext (`p`) | Inter | Regular (400) | 16 px | 1.7 | `Stone-100` | identisch |
| Button-Label `btn--secondary` | Inter | Bold (700) | 16 px | 1.4 | `Prussian` | identisch, aber Button full-width |

### Spacing / Layout — Desktop

| Element | Wert | Evidenz |
|---|---|---|
| **Kopfbereich** (`4030:735`) | Frame 1440×209 | ✅ get_metadata |
| Kopfbereich padding | top 48 px / bottom 32 px / x 120 px | ✅ get_design_context |
| Kopfbereich gap (Breadcrumbs → H1) | 16 px | ✅ get_design_context |
| Breadcrumbs-Nav gap (zwischen Items) | 12 px | ✅ get_design_context |
| Breadcrumbs-Separator | 1 px breit, 14 px hoch, Farbe `Stone-100` | ✅ get_design_context |
| **Themenkacheln-Wrapper** (`4030:741`) | Frame 1440×452, padding-x 120 px, padding-bottom 48 px, **kein expliziter padding-top** (Grid direkt am oberen Rand) | ✅ get_design_context |
| **Kachel-Grid** (`4030:742`) | 1200×404 px, `flex-wrap`, gap 24 px (Zeilen **und** Spalten, verifiziert über Metadata-Deltas: Spalten-x-Delta 408−384=24; Zeilen-y-Delta 214−190=24) | ✅ get_metadata + get_design_context |
| Kachel-Anordnung | 3 Spalten × 2 Zeilen, feste Reihenfolge (siehe Content-Annotation HUB-2, Abschnitt 3.4) | ✅ get_metadata |
| Kachel-Maße | 384×190 px (min-height; Höhe ist in dieser Instanz auch die tatsächliche Rahmenhöhe) | ✅ get_metadata |
| Kachel padding | 28 px (allseitig) | ✅ get_design_context |
| Kachel-Innenabstand (Icon→Titel→Beschreibung) | gap 12 px, `flex-col`, `items-center` (zentriert) | ✅ get_design_context |
| Kachel Border | 1 px solid `Stone-20` (#d6cab3) | ✅ get_design_context |
| Kachel Background | `White` | ✅ get_design_context |
| Kachel Border-Radius | keiner erkennbar (kein `rounded-*` in den Klassen) | ✅ get_design_context |
| Kachel Shadow | keiner | ✅ get_design_context |
| Icon-Maße | 32×32 px | ✅ get_metadata |
| Icon-Position in Kachel | zentriert oben, x=176 (bei Kachelbreite 384: (384−32)/2=176 ✅ exakt zentriert), y=28 | ✅ get_metadata (rechnerisch verifiziert) |
| **Section · Münzlexikon** (`4030:784`) | Frame 1440×268, padding: top 48 px / bottom (nicht explizit, Rest der Framehöhe) / x 120 px, gap 16 px | ✅ get_design_context |
| Münzlexikon Fließtext-Breite | 760 px (feste Breite, nicht full-width) | ✅ get_design_context |
| Button `btn--secondary` „Zum Münzlexikon" | Höhe 48 px, padding-x 24 px, Border 1 px solid `Prussian`, Background `White`, Text `Prussian`, Breite 187 px (intrinsisch) | ✅ get_design_context + get_metadata |
| **Section · Newsletter** (`4030:789`, nur Desktop) | Frame 1440×336, Background `Stone-5` (#f6f3ee), padding: top 48 px / bottom 72 px / x 120 px, gap 16 px | ✅ get_design_context |
| Newsletter Fließtext-Breite | 760 px | ✅ get_design_context |
| Newsletter-Formular gap (Input → Button) | 12 px, `items-center`, padding-top 4 px | ✅ get_design_context |
| Newsletter-Input | 420×48 px, Border 1 px solid `Stone-20`, Background `White`, padding-x 16 px, Placeholder „E-Mail-Adresse" | ✅ get_design_context |
| Newsletter-Button `btn--primary` „Anmelden" | 129×48 px (intrinsisch), padding-x 24 px, Background `Prussian`, Text `White` | ✅ get_design_context |
| Newsletter-Hinweistext-Breite | 760 px | ✅ get_design_context |

### Spacing / Layout — Mobile

| Element | Wert | Evidenz |
|---|---|---|
| **Kopfbereich** (`4030:346`) | Frame 390×153, padding: top 28 px / bottom 24 px / x 20 px, gap 16 px | ✅ get_design_context |
| **Themenkacheln-Wrapper** (`4030:352`) | Frame 390×802, padding-x 20 px, padding-bottom 48 px, gap **14 px** zwischen Kacheln (verifiziert: 128−114=14) | ✅ get_metadata + get_design_context |
| Kachel-Anordnung mobil | 1-spaltig, gestapelt, gleiche Reihenfolge wie Desktop | ✅ get_metadata |
| Kachel-Maße mobil | 350×114 px (Breite = volle Content-Spalte) | ✅ get_metadata |
| Kachel padding mobil | 20 px (allseitig lt. get_design_context: `p-[20px]`) | ✅ get_design_context — ⚠️ **Diskrepanz:** get_design_context liefert zusätzlich `min-h-[88px]` für den Text-Innenbereich; 88 px + 2×20 px Padding ergäbe 128 px Gesamthöhe, gemessen sind jedoch 114 px (Metadata). Wahrscheinlich ein Figma-Auto-Layout-Rundungs-/Konstraint-Artefakt ohne Auswirkung auf den finalen Wert — **114 px aus get_metadata als maßgeblich verwendet**, `min-h-88` als Hinweis auf einen Mindestwert, nicht als harte Vorgabe. |
| Kachel-Layout mobil | **Zeile** (`flex`, nicht `flex-col` wie Desktop), `items-center`, gap 16 px (Icon → Text-Block) | ✅ get_design_context |
| Icon-Position mobil | links, x=20 relativ zur Kachel (linksbündig, **nicht zentriert** wie Desktop) | ✅ get_metadata (bestätigt wie in Ticket-Vorgabe vermutet) |
| Text-Block mobil | `flex-col`, gap 4 px (Titel → Beschreibung), linksbündig (`items-start`, kein `text-center`) | ✅ get_design_context |
| **Section · Münzlexikon mobil** (`4030:423`) | Frame 390×299, padding: top 48 px / bottom 56 px / x 20 px, gap **20 px** (vs. 16 px Desktop) | ✅ get_design_context |
| Münzlexikon Button mobil | **full-width** (350 px, `w-full`), Text zentriert, sonst identisch zu Desktop-Button | ✅ get_design_context |
| Section Newsletter mobil | **nicht vorhanden** — siehe Abschnitt 0 | ✅ get_metadata |

**Wesentliche Unterschiede Desktop vs. Mobile:**

| Eigenschaft | Desktop | Mobile |
|---|---|---|
| H1-Größe | 40 px, 2-zeilig hart umbrochen | 28 px, ein Fließtextblock ohne Hardwrap |
| Kachel-Titel-Größe | 19 px | 17 px |
| Kachel-Beschreibung-Größe | 15 px | 14 px |
| Kachel-Layout | Spalte, zentriert, Icon oben mittig | Zeile, linksbündig, Icon links |
| Kachel-Grid-Anordnung | 3×2 Grid, gap 24 px | 1-spaltig gestapelt, gap 14 px |
| H2-Größe (Münzlexikon) | 32 px | 22 px |
| Münzlexikon-Section-gap | 16 px | 20 px |
| Münzlexikon-Button-Breite | intrinsisch (187 px) | full-width (350 px) |
| Newsletter-Section | vorhanden (letzte Section) | **nicht vorhanden** |
| Seitlicher Padding | 120 px | 20 px |

---

## 3. Komponenten

### 3.1 Abschnitt: Kopfbereich

#### Desktop (`4030:735`)

**Figma-Layer:** `Kopfbereich`
**Entsprechung im Theme:** `sections/mdm-breadcrumbs.liquid` ⚠️ (für Breadcrumbs) + eigene H1-Section/-Snippet für den Titel

```html
<div class="kopfbereich">
  <nav aria-label="Breadcrumb">                          <!-- 4030:736 -->
    <a href="/">STARTSEITE</a>                            <!-- 4030:737, Stone-80 -->
    <span aria-hidden="true">|</span>                      <!-- 4030:738, 1×14px -->
    <span aria-current="page">HILFE & SERVICE</span>       <!-- 4030:739, Prussian -->
  </nav>
  <h1>Hilfe und Antworten<br>zu häufigen Fragen</h1>        <!-- 4030:740 -->
</div>
```

**Detailmaße:**
- Frame: 1440×209 px, padding top 48 / bottom 32 / x 120 px, gap 16 px (flex-col) ✅
- Breadcrumbs: nur **2 Segmente** (Startseite + „Hilfe & Service" als aktuelle Seite — im
  Gegensatz zur Retoure-Themenseite mit 3 Segmenten). Da diese Seite selbst die
  Hilfe-Einstiegsseite ist, ist „HILFE & SERVICE" das letzte/aktuelle, nicht verlinkte Item. ✅
- H1: EB Garamond Medium 40 px, line-height 1.2, `Prussian`, zwei Textzeilen als **hartes
  Umbruch-Layout** (`<p>` mit `mb-0` + zweiter `<p>` im Figma-Code — Hardwrap ist Design-Entscheidung,
  keine automatische Zeilenumbruch-Folge einer festen Breite) ✅

**Interaktionen:** Hover-Zustand für Breadcrumb-Link nicht im Design definiert. ⚠️

#### Mobile (`4030:346`)

```html
<div class="kopfbereich">
  <nav aria-label="Breadcrumb">
    <a href="/">STARTSEITE</a>
    <span aria-hidden="true">|</span>
    <span aria-current="page">HILFE & SERVICE</span>
  </nav>
  <h1>Hilfe und Antworten zu häufigen Fragen</h1>
</div>
```

- Frame: 390×153 px, padding top 28 / bottom 24 / x 20 px, gap 16 px ✅
- H1: 28 px, **ein Fließtext** ohne Hardwrap (Zeilenumbruch ergibt sich responsiv aus der
  350 px breiten Spalte) ✅

---

### 3.2 Abschnitt: Themenkacheln (6 Kacheln)

#### Desktop (`4030:741` / Grid `4030:742`)

**Figma-Layer:** `Themenkacheln` (Wrapper) → `Kachel-Grid` → 6× `Themenkachel · <Name>`
**Entsprechung im Theme:** ⚠️ kein direkter Treffer in `figma-mapping.md` — vermutlich neue
Section/Snippet (Card-Grid), evtl. wiederverwendbar mit vorhandenen Hyper-Card-Komponenten
(ungelesen, vom Planner zu prüfen).

```html
<div class="themenkacheln">
  <ul class="kachel-grid" role="list">
    <li>
      <a class="themenkachel" href="<Ziel-URL fehlt>">
        <span class="themenkachel__icon" aria-hidden="true"><!-- SVG --></span>
        <span class="themenkachel__titel">Bestellung</span>
        <span class="themenkachel__text">Rund um Ihre Bestellung in unserem Onlineshop.</span>
      </a>
    </li>
    <!-- ×6, siehe Tabelle in 3.4 für alle Texte -->
  </ul>
</div>
```

**Wichtiger Hinweis aus Figma-Content-Annotation (HUB-2, am Node `4030:742`):**
> „Sechs Kacheln, feste Reihenfolge, 3 × 2 auf Desktop / 1-spaltig auf Mobile. Kacheltexte aus
> der Vorlage B übernommen; „Information zu Rücksendungen" → „Informationen" korrigiert,
> Kundendaten-Text aus der Frageform in eine Aussage überführt (Kacheln sind Wegweiser, keine
> Fragen). Icons = Platzhalter, final aus dem Nexvo-Icon-Set; jedes Icon ist dekorativ
> (aria-hidden), die Kachel trägt den zugänglichen Namen."

✅ Belegt (wörtliches Zitat aus get_design_context-Annotation). Das bedeutet:
1. Die Icons sind **explizit Platzhalter** — finale Icons kommen aus einem „Nexvo-Icon-Set" (⚠️
   unklar, ob dieses Set bereits im Theme vorliegt — vom Planner zu klären, siehe Unknowns).
2. Icons sind dekorativ → `aria-hidden="true"`, der zugängliche Name muss über die Kachel
   (z. B. den umschließenden Link/`aria-label`) kommen, nicht über Alt-Text am Icon.
3. Reihenfolge ist fest: Bestellung, Bezahlung, Versand & Lieferung, Retoure & Reklamation,
   Kundendaten, Kollektion & Sammeln.

**Detailmaße:** siehe Tabelle „Spacing / Layout — Desktop" oben.

#### Mobile (`4030:352`)

Gleiche Kachel-Reihenfolge, aber:
- Layout pro Kachel: **Zeile statt Spalte**, Icon links (32×32, x=20), Text-Block rechts
  (`flex-[1_0_0]`, linksbündig) ✅
- Kachel-Titel „Kollektion & Sammeln" wird zu **„Kollektion"** gekürzt — siehe 3.4 unten. ✅

---

### 3.3 Abschnitt: Section · Münzlexikon

#### Desktop (`4030:784`)

```html
<section class="section-muenzlexikon">
  <h2>Münzlexikon A–Z</h2>
  <p>Von Abnutzung bis Werterhaltung: die Begriffe der Numismatik in alphabetischer Reihenfolge, verständlich erklärt.</p>
  <a href="<Ziel-URL fehlt>" class="btn btn--secondary"><span class="btn__text">Zum Münzlexikon</span></a>
</section>
```

- Frame 1440×268, padding top 48 / x 120, gap 16 ✅
- H2: EB Garamond Medium 32 px, `Prussian` ✅
- p: Inter Regular 16 px, line-height 1.7, `Stone-100`, Breite 760 px ✅
- Button: `btn--secondary`, Höhe 48 px, Border 1 px solid `Prussian`, Text `Prussian` ✅

#### Mobile (`4030:423`)

```html
<section class="section-muenzlexikon">
  <h2>Münzlexikon A–Z</h2>
  <p>Von Abnutzung bis Werterhaltung: die Begriffe der Numismatik in alphabetischer Reihenfolge, verständlich erklärt.</p>
  <a href="<Ziel-URL fehlt>" class="btn btn--secondary btn--full-width"><span class="btn__text">Zum Münzlexikon</span></a>
</section>
```

- Frame 390×299, padding top 48 / bottom 56 / x 20, gap 20 (abweichend von Desktop 16) ✅
- H2: 22 px ✅
- Button: full-width (350 px), Text zentriert ✅

---

### 3.4 Abschnitt: Section · Newsletter (nur Desktop)

**Node:** `4030:789`
**Entsprechung im Theme:** `sections/newsletter.liquid` bzw. `snippets/mdm-newsletter-form.liquid`
existieren bereits im Theme ✅ (verifiziert per Dateisuche: `sections/newsletter.liquid`,
`snippets/newsletter-form.liquid`, `snippets/mdm-newsletter-form.liquid`,
`assets/section-newsletter.css`) — Planner sollte prüfen, ob eine dieser Sections direkt
wiederverwendbar ist, statt neu zu bauen.

**Wichtiger Hinweis aus Figma-Accessibility-Annotation (HUB-B4, am Node `4030:789`):**
> „Newsletter bewusst als **letzte** Section. Pflichten: Double-Opt-in (§ 7 UWG),
> Datenschutzhinweis vor dem Absenden, Abmeldehinweis. Feld braucht ein sichtbares `<label>` —
> Platzhaltertext allein genügt WCAG 3.3.2 nicht. Nexvo-Section `newsletter` verwenden, nicht
> neu bauen."

✅ Belegt (wörtliches Zitat). Konsequenzen für Planung/Implementierung:
1. **Rechtlich:** Double-Opt-in ist Pflicht (§ 7 UWG) — falls die vorhandene
   `sections/newsletter.liquid` das nicht bereits über die Shopify-Customer/Klaviyo-Anbindung
   sicherstellt, muss das geprüft werden. ⚠️ ungelesen, ob Hyper-Newsletter-Flow das abdeckt.
2. **Barrierefreiheit:** Das E-Mail-Feld braucht ein sichtbares `<label>`, nicht nur den im
   Design gezeigten Placeholder „E-Mail-Adresse" — WCAG 3.3.2 fordert ein sichtbares Label.
   Das Design selbst zeigt nur den Placeholder; **Label muss beim Bauen ergänzt werden**
   (visuell ggf. per `.visually-hidden` wenn ein sichtbares Label das Design stört, aber im
   DOM vorhanden). ⚠️ Umsetzungsdetail für liquid-implementer.
3. **Ausdrücklich:** „Nexvo-Section `newsletter` verwenden, nicht neu bauen" — direkte
   Bauanweisung aus dem Figma-Design an die Implementierung; deckt sich mit dem Fund, dass
   `sections/newsletter.liquid` im Theme bereits existiert.

```html
<section class="section-newsletter" style="background: var(--color-stone-5)">
  <h2>MDM-Newsletter</h2>
  <p>Neuheiten, Sammlerwissen und Angebote per E-Mail. Die Abmeldung ist jederzeit über den Link in jeder E-Mail möglich.</p>
  <form>
    <label for="newsletter-email" class="visually-hidden">E-Mail-Adresse</label>
    <input id="newsletter-email" type="email" placeholder="E-Mail-Adresse" required>
    <button type="submit" class="btn btn--primary"><span class="btn__text">Anmelden</span></button>
  </form>
  <p class="hinweis">Mit der Anmeldung bestätigen Sie, dass Sie unsere Datenschutzerklärung zur Kenntnis genommen haben.</p>
</section>
```

- Frame 1440×336, Background `Stone-5` (#f6f3ee) — einzige Section mit farbigem Hintergrund
  auf dieser Seite ✅
- padding top 48 / bottom 72 / x 120, gap 16 ✅
- Input 420×48, Border `Stone-20`, Button `btn--primary` 129×48 (Prussian/White) ✅
- Hinweistext 14 px, `Stone-80`, Breite 760 px — Text erwähnt Datenschutzerklärung, aber
  **kein Link** auf die Datenschutzerklärung im Design (reiner Fließtext ohne `<a>`). ⚠️

---

### 3.5 Vollständige Kachel-Texte (Desktop vs. Mobile, wörtlich)

| # | Node Desktop | Node Mobile | Titel Desktop | Titel Mobile | Beschreibung (identisch auf beiden Breakpoints) |
|---|---|---|---|---|---|
| 1 | `4030:743` | `4030:353` | Bestellung | Bestellung | Rund um Ihre Bestellung in unserem Onlineshop. |
| 2 | `4030:749` | `4030:360` | Bezahlung | Bezahlung | Antworten zu unseren Zahlungsarten und Rechnungen. |
| 3 | `4030:755` | `4030:367` | Versand & Lieferung | Versand & Lieferung | Alles zu Versandkosten, Lieferzeit und Sendungsverfolgung. |
| 4 | `4030:763` | `4030:376` | Retoure & Reklamation | Retoure & Reklamation | Informationen zu Rücksendungen und Hilfe bei fehlerhaften Lieferungen. |
| 5 | `4030:771` | `4030:385` | Kundendaten | Kundendaten | Fragen zu Ihren Kundendaten und wie Sie diese anpassen. |
| 6 | `4030:777` | `4030:392` | **Kollektion & Sammeln** | **Kollektion** | Infos zu unseren Kollektionen, Folgelieferungen und Einstellungen. |

**Abweichung Titel Kachel 6 ist ✅ belegt** (Desktop-Node `4030:782` = „Kollektion & Sammeln";
Mobile-Node `4030:398` = „Kollektion"). Alle anderen Titel sind auf beiden Breakpoints identisch.

---

## 4. Figma-Mapping-Abgleich

| Figma-Layer/Muster | Treffer in figma-mapping.md | Notiz |
|---|---|---|
| `breadcrumbs (nav)` | ✅ `sections/mdm-breadcrumbs.liquid` | Hier nur 2 Segmente (Startseite + aktuelle Seite), kein 3-Ebenen-Pfad |
| `btn--primary` / `btn--secondary` | ✅ Hyper-Button-Klassen (siehe mapping.md, Buttons brauchen `.btn__text`) | Gilt für Newsletter-„Anmelden" (primary) und „Zum Münzlexikon" (secondary) |
| Serifen-Headline (EB Garamond) | ✅ `assets/eb-garamond-variable.ttf` | Font liegt im Theme |
| Fließtext (Inter) | ✅ `assets/inter-variable.ttf` | Font liegt im Theme |
| `Stone-80`, `Stone-100`, `Prussian`, `White` | ✅ bereits in mapping.md dokumentiert | Hex-Hardcode-Pattern übernehmbar |
| `Stone-20`, `Stone-5` | ❌ **neu, noch nicht in mapping.md** | Sollten nach Umsetzung ergänzt werden (Kachel-Border bzw. Newsletter-Hintergrund) |
| `Themenkachel · <Name>` (Card-Grid) | ❌ kein Treffer | Neue Komponente — Planner sollte prüfen, ob Hyper generische Card-Snippets besitzt |
| Newsletter-Formular | ⚠️ `sections/newsletter.liquid`, `snippets/mdm-newsletter-form.liquid`, `snippets/newsletter-form.liquid` existieren bereits im Theme (per Dateisuche gefunden, Inhalt ungelesen) | Figma-Annotation HUB-B4 fordert explizit Wiederverwendung („Nexvo-Section `newsletter` verwenden, nicht neu bauen") |

---

## 5. Assets

| Datei | Pfad | Quelle | Verwendung |
|---|---|---|---|
| `reference-4030-734.png` | `assets-src/reference-4030-734.png` | Figma Screenshot (1440×1265 px, 1:1) | Visuelles Referenz-Bild Desktop |
| `reference-4030-345.png` | `assets-src/reference-4030-345.png` | Figma Screenshot (390×1254 px, 1:1) | Visuelles Referenz-Bild Mobile |
| `icon-bestellung.svg` | `assets-src/icon-bestellung.svg` | Figma `download_assets`/Vektor-Export (Node `4030:744`, Desktop-Instanz) | Platzhalter-Icon Kachel „Bestellung" |
| `icon-bezahlung.svg` | `assets-src/icon-bezahlung.svg` | Figma-Export (Node `4030:750`) | Platzhalter-Icon Kachel „Bezahlung" |
| `icon-versand-lieferung.svg` | `assets-src/icon-versand-lieferung.svg` | Figma-Export (Node `4030:756`) | Platzhalter-Icon Kachel „Versand & Lieferung" |
| `icon-retoure-reklamation.svg` | `assets-src/icon-retoure-reklamation.svg` | Figma-Export (Node `4030:764`) | Platzhalter-Icon Kachel „Retoure & Reklamation" |
| `icon-kundendaten.svg` | `assets-src/icon-kundendaten.svg` | Figma-Export (Node `4030:772`) | Platzhalter-Icon Kachel „Kundendaten" |
| `icon-kollektion.svg` | `assets-src/icon-kollektion.svg` | Figma-Export (Node `4030:778`) | Platzhalter-Icon Kachel „Kollektion & Sammeln" |

**Icon-Export-Weg (Abnahmekriterium 5):** ✅ Alle 6 Icons sind als eigenständige SVG-Vektor-Layer
im Figma-Design vorhanden und wurden erfolgreich als SVG exportiert (`get_design_context`
liefert für jede Icon-Instanz eine eigene `.svg`-Asset-URL, direkt per `curl` heruntergeladen).
Separate Desktop- und Mobile-Instanzen der Icons liefern **unterschiedliche Asset-URLs**
(unterschiedliche Node-IDs pro Icon-Instanz), aber **visuell identische Icons** — es wurde nur
je ein Satz (aus dem Desktop-Kachel-Grid) heruntergeladen, da laut Content-Annotation HUB-2
ohnehin alle Platzhalter sind und final durch das „Nexvo-Icon-Set" ersetzt werden.

**Wichtig:** Laut Annotation HUB-2 sind diese 6 SVGs **explizit Platzhalter**, keine finalen
Assets — vor der Theme-Übernahme mit Konrad klären, ob das „Nexvo-Icon-Set" bereits im Theme
vorliegt (z. B. unter `assets/icon-*.svg`) oder ob die Platzhalter vorerst verwendet werden
sollen. ⚠️

---

## 6. Offene Punkte / Unknowns

### Inhalt
1. **Ziel-Links der 6 Themenkacheln sind im Design nicht definiert.** Figma liefert keine
   Link-Targets. Für „Retoure & Reklamation" ist `page.retoure.json` (bereits im Theme
   vorhanden) ein plausibler Kandidat — für die übrigen 5 Kacheln (Bestellung, Bezahlung,
   Versand & Lieferung, Kundendaten, Kollektion & Sammeln) müssen die Ziel-Slugs von Konrad
   geliefert werden, da im Theme (Stand dieser Extraktion) nicht geprüft wurde, ob
   entsprechende Themenseiten bereits existieren. ⚠️/❌
2. **Ziel-URL des Buttons „Zum Münzlexikon"** nicht im Design definiert. ⚠️
3. **Newsletter-Formular-Action/-Endpoint** nicht im Design definiert — hängt von der
   gewählten Hyper-/Shopify-Customer-Newsletter-Integration ab. ❌

### Icons
4. **„Nexvo-Icon-Set"** wird in der Figma-Annotation als finale Icon-Quelle genannt — ob dieses
   Set im MDM-Theme bereits vorliegt (z. B. `assets/icon-*.svg`), ist ungeprüft. ❌
5. Die 6 heruntergeladenen SVGs sind Platzhalter (siehe Abschnitt 5) — Ersatz durch finale
   Icons ist eine spätere Aufgabe, sollte aber im Plan als offener Punkt vermerkt werden. ⚠️

### Layout / Responsiveness
6. **Newsletter auf Mobile fehlt vollständig** — siehe ausführliche Analyse in Abschnitt 0.
   Muss mit Konrad geklärt werden: bewusste Design-Entscheidung oder soll ergänzt werden? ❌
7. **Tablet-Breakpoint** (768–1024 px) — kein Frame vorhanden, Übergangsverhalten des
   3×2-Kachel-Grids zu 1-spaltig nicht spezifiziert. ⚠️
8. **Kachel-Diskrepanz min-height mobil** (88 px lt. Design-Context vs. 114 px lt. Metadata,
   siehe Tabelle „Spacing/Layout — Mobile") — vermutlich irrelevant, aber nicht abschließend
   geklärt. ⚠️
9. Der Grund für den Namenszusatz „VARIANTE FINAL" am Desktop-Frame — ob es frühere Varianten
   in einer anderen Figma-Datei/Version gab — ist aus dieser Datei nicht rekonstruierbar. ❌

### Interaktionen
10. **Hover-/Focus-Zustände** für Kacheln (gesamte Kachel als Link?), Breadcrumb-Links,
    Buttons und Newsletter-Input nicht im Design definiert. ⚠️
11. **Fehlerzustände des Newsletter-Formulars** (ungültige E-Mail, bereits angemeldet,
    Erfolgsmeldung) nicht im Design definiert. ⚠️

### Theme-Integration
12. **Seitentemplate-Typ:** Wahrscheinlich `page.<slug>.json` mit 3–4 Custom Sections
    (Kopfbereich+Kacheln als eine oder zwei Sections, Münzlexikon, Newsletter). Muss vom
    Planner entschieden werden. ⚠️
13. **Card-Grid-Komponente:** Kein bestehender Treffer in `figma-mapping.md` — Planner sollte
    prüfen, ob Hyper eine generische Card-/Grid-Section besitzt, die sich eignet, bevor eine
    komplett neue Section gebaut wird. ❌
14. **Newsletter-Wiederverwendung:** Figma fordert ausdrücklich, die vorhandene Newsletter-Section
    zu nutzen (siehe 3.4) — die drei gefundenen Dateien (`sections/newsletter.liquid`,
    `snippets/newsletter-form.liquid`, `snippets/mdm-newsletter-form.liquid`) wurden nur per
    Dateisuche identifiziert, ihr Inhalt/API wurde nicht gelesen. Planner muss prüfen, welche
    davon zum Design passt (Hintergrundfarbe `Stone-5`, Label-Pflicht WCAG 3.3.2, Double-Opt-in). ❌
15. **Double-Opt-in-Konformität (§ 7 UWG):** ob die bestehende Newsletter-Integration das
    bereits sicherstellt, ist ungeprüft. ❌
16. **Token-Mapping `Stone-20`/`Stone-5` zu Hyper-CSS:** neu in diesem Ticket, noch nicht in
    `figma-mapping.md` — nach Umsetzung dort nachtragen. ⚠️
