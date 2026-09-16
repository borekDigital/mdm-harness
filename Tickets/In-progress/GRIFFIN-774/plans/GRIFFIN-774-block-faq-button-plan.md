# Block-Plan: FAQ-Item-Button (GRIFFIN-774)

**Ticket:** GRIFFIN-774 „Shopify FAQ mit Button" — Reporterin Kerstin Meyer, 16. September 2026
**Theme:** `themes/mdm/` · **Branch:** `feat/faq-item-button` (Basis `origin/main`, a71e143)
**Betroffene Seite:** https://mdm-muenze.myshopify.com/pages/faq_bestellung

---

## TL;DR

Der Button fehlt an zwei Stellen: Das Block-Schema von `sections/mdm-collapsible-tabs.liquid`
kennt kein Button-Setting, und das Template `templates/page.faq-seite.json` mappt das
Metaobjekt-Feld `button` nicht. Ein Repeater kann nur auf Settings mappen, die im Schema
existieren — deshalb ist die Section die erste Baustelle, das Template die zweite. Das
einzige echte Risiko ist der **zweistufige** Repeater-Zugriff (`block.repeater.button.value.url`),
der nirgends belegt ist; dafuer liegt ein einstufiger Fallback-Weg fertig geplant daneben.

---

## Quellenlage

### Hyper-Quelle und Namensraum

| Datei | Rolle | Status in diesem PR |
|---|---|---|
| `sections/collapsible-tabs.liquid` | FoxEcom-Original (Hyper 1.3.3) | **bleibt unberuehrt** |
| `sections/mdm-collapsible-tabs.liquid` | vorhandene mdm-Kopie | wird geaendert |

✅ **Belegt** — das Original ist eine FoxEcom-Kerndatei und wird von elf Templates referenziert,
darunter `templates/page.faq.json:180`, `:284`, `:387`, `templates/page.about.json:518` und sieben
Produkt-Templates (z. B. `templates/product.grid-mix.json:801`). Eine Aenderung dort haette einen
shopweiten Blast-Radius und verstiesse gegen die Namensraum-Regel.

✅ **Belegt** — `sections/mdm-collapsible-tabs.liquid` ist bereits die mdm-Kopie und weicht vom
Original bereits an vier Stellen ab: `custom_class`-Ableitung (Z. 35–39), bedingtes Laden von
`mdm-section-retoure-faq.css` (Z. 42–44), `| escape` auf `block.settings.heading` (Z. 138 gegen
`sections/collapsible-tabs.liquid:130`) und das zusaetzliche Schema-Setting `custom_class`
(Z. 710–718). Es entsteht also **keine neue Kopie** — Mapping-Stufe (b), gezielte Erweiterung
der bestehenden Kopie.

### Ursache 1 — Section-Schema kennt kein Button-Setting

✅ **Belegt** — der `collapsible_item`-Zweig gibt im Accordion-Inhalt genau drei Werte aus:

- `sections/mdm-collapsible-tabs.liquid:142` — oeffnendes `div.accordion-details__content`
- `:143` — `{{ block.settings.content }}`
- `:144` — `{{ block.settings.custom_liquid }}`
- `:145` — `{{ block.settings.page.content }}`

✅ **Belegt** — das Block-Schema `collapsible_item` (`:771`–`:944`) enthaelt ausschliesslich:
`icon` (`:777`), `heading` (`:913`, Typ `text`), `content` (`:919`, Typ `richtext`),
`custom_liquid` (`:925`), `page` (`:930`), `open` (`:935`), `use_subtext_color` (`:940`).
Kein `button_*`-Setting vorhanden.

### Ursache 2 — Template mappt `button` nicht

✅ **Belegt** — `templates/page.faq-seite.json` enthaelt drei Sections vom Typ
`mdm-collapsible-tabs` (`:35`, `:83`, `:131`) mit je einem Repeater-Block:

| Section-ID | Zeilen | Repeater-Quelle | gemappte Settings |
|---|---|---|---|
| `mdm_retoure_faq` | `:37`–`:44` | `hilfe_faq_lieferung` | `heading`, `content` |
| `mdm_collapsible_tabs_TjHcdW` | `:85`–`:92` | `hilfe_faq_bezahlung` | `heading`, `content` |
| `mdm_collapsible_tabs_cpbgLz` | `:133`–`:145` | `hilfe_faq_bestellung` | `icon`, `heading`, `content`, `custom_liquid`, `page`, `open`, `use_subtext_color` |

Das Feld `button` wird in keiner der drei Sections gemappt. Kerstins Formulierung „bitte den
Button dynamisch im Template ergaenzen" greift damit zu kurz — Template allein reicht nicht.

### Datenlage (uebernommen aus der Ticket-Recherche)

✅ **Belegt** (Admin-API) — drei Metaobjekt-Definitionen mit identischen Feldern:
`faq_bestellung_item` (25895502205), `faq_bezahlung_item` (25898549629),
`faq_lieferung_item` (25938952573). Felder: `question` (`single_line_text_field`),
`answer` (`rich_text_field`), `button` (**`link`**, optional).
Seiten-Metafelder (ownerType PAGE, Namespace `custom`, Typ `list.metaobject_reference`):
`hilfe_faq_bestellung`, `hilfe_faq_bezahlung`, `hilfe_faq_lieferung`.
Von 12 Eintraegen in `faq_bestellung_item` haben genau zwei einen Button gepflegt — deckungsgleich
mit Kerstins Beobachtung.

Ein `link`-Feld liefert in Liquid ein Objekt mit `text` und `url`; Rohwert im Admin:
`{"text":"Jetzt Bestellung aendern","url":"https://news.mdm.de/u/register.php?CID=110747332&f=25059"}`.

### Vorhandene Bausteine (nicht neu bauen)

✅ **Belegt** — `snippets/mdm-button.liquid` rendert Buttons hausintern. Parameter laut
LiquidDoc-Kopf (`:1`–`:18`): `button_label` (Pflicht), `button_link`, `button_style`, `button_size`,
`button_tag`, `button_icon`, `button_icon_size`, `button_icon_position`, `additional_classes`,
`additional_attributes`. Der Snippet rendert **nichts**, wenn `button_label` leer ist (`:57`) —
das ist die natuerliche „nur anzeigen wenn gepflegt"-Logik. Section-Buttons laufen bereits ueber
diesen Snippet (`snippets/mdm-section-heading.liquid:100`–`:110`, aufgerufen aus
`sections/mdm-collapsible-tabs.liquid:59`–`:69`).

✅ **Belegt und wichtig** — das Button-CSS fuer FAQ-Items **existiert bereits**:
`assets/mdm-section-retoure-faq.css:41`–`:45` definiert `.mdm-retoure-faq__buttons`
(flex, wrap, gap 1.2rem, padding-top 0.8rem), `:53`–`:58` die Button-Basis im Accordion-Inhalt,
`:60`–`:83` Primary/Secondary-Farben inklusive `.rte a`-Spezifitaets-Korrekturen,
`:104`–`:112` das mobile Verhalten (Buttons untereinander, volle Breite).
✅ **Belegt** — die Klasse `.mdm-retoure-faq__buttons` wird von **keiner** Liquid-Datei ausgegeben
(Repo-weites grep: nur die beiden CSS-Fundstellen). Sie stammt aus MDM-RETOURE-01 und war fuer
handgepflegte Buttons im Richtext gedacht. Dieser PR kann sie einloesen.

✅ **Belegt** — die Section laedt `assets/mdm-section-collapsible-tabs.css` immer (`:41`) und
`assets/mdm-section-retoure-faq.css` nur, wenn `custom_class == 'mdm-retoure-faq'` (`:42`–`:44`).
Alle drei FAQ-Sections setzen genau diese Klasse (`templates/page.faq-seite.json:75`, `:123`, `:176`)
— das Marken-CSS greift auf der Zielseite also bereits.

---

## Das offene Risiko

❌ **Unbekannt** — ob der **zweistufige** Repeater-Zugriff auf ein `link`-Feld aufloest, also
`{{ block.repeater.button.value.url }}` bzw. `{{ block.repeater.button.value.text }}`.

Kontext dazu:

- ⚠️ **Vermutung (Community-belegt, nicht Doku-belegt)** — `repeater` ist ein undokumentiertes
  Shopify-Feature fuer Section-Blocks (nicht Theme-Blocks). Die offizielle Doku kennt es nicht;
  Belege nur aus Community-Threads
  (community.shopify.com/t/how-to-iterate-over-a-metaobject-list-with-the-mysterious-repeater-function/248211,
  community.shopify.dev/t/missing-repeater-functionality-on-theme-blocks/10253).
- ✅ **Belegt** — der **einstufige** Zugriff funktioniert im Shop: `{{ block.repeater.question.value }}`
  auf ein `text`-Setting (`templates/page.faq-seite.json:41` → Schema `:913`–`:917`) und
  `{{ block.repeater.answer | metafield_tag }}` auf ein `richtext`-Setting (`:42` → Schema
  `:918`–`:923`) rendern Fragen und Antworten korrekt auf der Live-Seite.
- ❌ **Unbekannt** — Verhalten bei einer Ebene mehr (`.value.url`). Nicht aus der Doku ableitbar,
  nur per Laufzeittest zu klaeren.
- ⚠️ **Vermutung** — relevanter Nebenbefund aus der Dynamic-Sources-Kompatibilitaetsmatrix
  (shopify.dev/docs/storefronts/themes/architecture/settings/dynamic-sources): ein `link`-Metafeld
  ist als Dynamic Source kompatibel mit `richtext` und `inline_richtext`, **nicht** mit `text` und
  **nicht** mit `url`. Ob diese Matrix auch fuer handgeschriebene Repeater-Strings gilt oder nur
  fuer den „Dynamische Quelle verbinden"-Dialog im Theme-Editor, ist ❌ **unbekannt**. Sie ist aber
  ein starkes Indiz dafuer, dass Weg B (unten) der robustere ist und dass Kerstin den Button
  spaeter **nicht** per Dynamic-Source-Dialog an ein `url`-Setting haengen koennte.

### Probe vor der Implementierung (empfohlen, ca. 10 Minuten)

Das Risiko laesst sich isoliert klaeren, **bevor** Schema-Code entsteht: im lokalen Arbeitsbaum
in genau einer Section von `templates/page.faq-seite.json` temporaer das bereits funktionierende
`heading`-Mapping ersetzen durch `"heading": "{{ block.repeater.button.value.text }}"` und die
Seite unter `shopify theme dev --store mdm-muenze` oeffnen.

- Erscheint bei den letzten beiden Eintraegen der Buttontext statt der Frage → zweistufiger
  Zugriff loest auf → **Weg A**.
- Bleibt die Stelle leer → **Weg B**.

Danach die Probe zurueckrollen (`git checkout -- templates/page.faq-seite.json`).
⚠️ **Vermutung** — `theme dev` rendert Repeater identisch zum Shop, da die Section serverseitig
gerendert wird. Faellt die Probe lokal unschluessig aus, wird sie am Staging-Theme wiederholt.

---

## Loesungswege

### Weg A — zwei neue Block-Settings, Repeater mappt Teilwerte (Empfehlung, vorbehaltlich Probe)

**Schema** — in `sections/mdm-collapsible-tabs.liquid` im Block `collapsible_item` nach dem
`content`-Setting (nach `:923`, vor `custom_liquid` `:924`) einfuegen:

- `header` mit `t:general.button.header.content`
- `button_label`, Typ **`text`**, Label `t:general.button.button_label.label`,
  Info `t:general.button.button_label.info` („Leave blank to hide the button" — passt woertlich)
- `button_link`, Typ **`text`** (nicht `url`, Begruendung unten), Label `t:general.button.button_link.label`
- `button_style`, Typ `select` mit denselben vier Optionen wie die Section-Ebene
  (`:413`–`:431`: `btn--primary`, `btn--secondary`, `btn--underline`, `btn--plain`), Default `btn--primary`

Warum `text` statt `url` fuer den Link: ✅ **Belegt** ist, dass ein `text`-Setting einen
Repeater-String aufloest (`heading`, `templates/page.faq-seite.json:41` → Schema `:913`). Fuer
`url`-Settings ist das ❌ **unbekannt**, und die Dynamic-Sources-Matrix listet `link` → `url`
ausdruecklich als inkompatibel. `text` ist der belegte Pfad; der Verlust ist nur der
URL-Picker im Editor, den ein Repeater-Block ohnehin nicht nutzt.

**Markup** — in `sections/mdm-collapsible-tabs.liquid` nach `:145` (`block.settings.page.content`),
noch innerhalb von `div.accordion-details__content` (`:142`–`:146`):

- Guard `{%- if block.settings.button_label != blank -%}` (doppelt gesichert: der Snippet selbst
  rendert bei leerem Label nichts, `snippets/mdm-button.liquid:57`) — verhindert zusaetzlich einen
  leeren Wrapper-`div` bei den zehn Eintraegen ohne Button.
- Wrapper `<div class="accordion-details__buttons mdm-retoure-faq__buttons">` (Doppel-Klasse,
  siehe CSS-Abschnitt).
- `{% render 'mdm-button', button_label: …, button_link: …, button_style: … %}`
- **Escaping:** vor dem Render in einem `{%- liquid -%}`-Block `assign`s mit `| escape` bilden.
  Begruendung: `snippets/mdm-button.liquid:62` gibt das Label unescaped aus und `:19` baut
  `href="{{ button_link }}"` ohne Escaping. Werte stammen zwar aus dem Admin (merchant-controlled),
  der Escaping-Pfad ist aber Pflicht und wird vom security-reviewer geprueft. Explizite `assign`s
  statt Filter direkt im `render`-Argument, weil die Filter-Syntax in `render`-Parametern
  ⚠️ **Vermutung** ist und die `assign`-Variante eindeutig.
- Kein `button_icon` (siehe Abgrenzung).

**Template** — in allen **drei** Sections von `templates/page.faq-seite.json` je zwei Zeilen
ergaenzen (`:40`–`:43`, `:88`–`:91`, `:136`–`:144`):

- `"button_label": "{{ block.repeater.button.value.text }}"`
- `"button_link": "{{ block.repeater.button.value.url }}"`

**Vorteil:** minimalinvasiv, nutzt `mdm-button` und damit die komplette Haus-Button-Logik
(Styles, Klassen, Icon-Faehigkeit fuer spaeter), das vorhandene Retoure-CSS greift unveraendert.
**Nachteil:** haengt vollstaendig am unbelegten zweistufigen Repeater-Zugriff.

### Weg B — Fallback ohne Repeater-Verschachtelung (einstufig, `metafield_tag`)

Greift, falls die Probe zeigt, dass `.value.url` nicht aufloest.

**Schema** — statt der drei Settings aus Weg A **ein** Setting im Block `collapsible_item`:
`button`, Typ **`richtext`** (analog zum bereits funktionierenden `content`-Setting `:918`–`:923`),
Label `t:general.button.label`.

**Template** — je Section eine Zeile:
`"button": "{{ block.repeater.button | metafield_tag }}"`

Das ist **exakt dasselbe einstufige Muster**, das fuer `answer` bereits nachweislich funktioniert
(`templates/page.faq-seite.json:42` ✅ belegt), nur auf das `button`-Feld angewandt. Ein
`link`-Metafeld rendert mit `metafield_tag` einen fertigen `<a href="…">Text</a>`.
⚠️ **Vermutung** — dass `metafield_tag` auf `link` einen Anchor erzeugt (Shopify-Filter-Verhalten
je Metafeld-Typ); das ist ueber dieselbe Probe mitpruefbar. Zusaetzlich stuetzt die
Dynamic-Sources-Matrix diesen Weg: `link` → `richtext` ist ausdruecklich kompatibel.

**Markup** — gleicher Ort, gleicher Wrapper, aber Rohausgabe `{{ block.settings.button }}` statt
`mdm-button`-Render (der Filter liefert bereits fertiges HTML; ein `| escape` wuerde es zerstoeren).

**CSS-Delta fuer B** — der gerenderte Anchor traegt keine `.btn`-Klassen. In
`assets/mdm-section-collapsible-tabs.css` ergaenzen:
`.accordion-details__buttons a { … }` mit denselben Basiswerten wie
`assets/mdm-section-retoure-faq.css:53`–`:58`, damit der Link wie ein Button aussieht.

**Blast-Radius von B:**
- Nur additive Aenderungen an denselben drei Dateien wie in Weg A — **kein** neuer Section-File,
  **kein** Template-Umbau ausserhalb von `page.faq-seite.json`.
- Zusaetzlicher CSS-Selektor `.accordion-details__buttons a`, der ausschliesslich innerhalb des
  neuen Wrappers greift; bestehende Links im Accordion-Inhalt (`.rte a`,
  `assets/mdm-section-retoure-faq.css:35`–`:39`) sind nicht betroffen.
- Schlechtere Merchant-UX: im Theme-Editor sieht ein Redakteur ein freies Richtext-Feld statt
  Label/Link/Style. Fuer die drei FAQ-Sections irrelevant (Daten kommen aus Metaobjekten),
  relevant erst, falls jemand die Section spaeter manuell befuellt.
- Die `btn--*`-Style-Auswahl entfaellt; alle FAQ-Buttons sehen gleich aus. Fuer GRIFFIN-774
  ausreichend — Kerstin hat keine Style-Varianten angefordert.

**Weg B2 (nur der Vollstaendigkeit halber, nicht empfohlen):** eine eigene Section, die die
Metaobjekt-Liste selbst in Liquid iteriert (`{% for item in page.metafields.custom.<key>.value %}`)
und damit vollstaendig dokumentiertes Liquid nutzt (`item.button.value.url` ist normales
Metafeld-Liquid ✅). Blast-Radius deutlich groesser: neuer Section-File, alle drei Template-Sections
werden ersetzt, `custom_class`-gebundenes CSS und die Editor-Blockstruktur muessen nachgezogen
werden, und die drei bestehenden Sections verlieren ihre Section-IDs (Kerstins Zuordnung im
Editor geht verloren). Nur ziehen, wenn A **und** B scheitern.

### Empfehlung

**Weg A implementieren, Weg B vorbereitet danebenlegen.** Reihenfolge:

1. Probe (oben) — klaert das ❌ Unbekannte in Minuten, ohne Code.
2. Probe positiv → Weg A. Probe negativ → Weg B; Schema- und Markup-Aenderung sind an derselben
   Stelle, der Umstieg kostet wenige Zeilen.
3. Beide Wege sind **additiv** — kein bestehendes Setting wird umbenannt oder entfernt.

---

## Aenderungen im Detail (Weg A)

1. **Block-Schema erweitern** — `sections/mdm-collapsible-tabs.liquid`, Einfuegepunkt nach `:923`
   - Neue Settings: `button_label` (text), `button_link` (text), `button_style` (select, Default `btn--primary`), plus `header`-Trenner
   - Begruendung: Ein Repeater kann nur auf existierende Settings mappen — ohne Schema kein Mapping
   - Validierung: `shopify theme check` auf der Datei; Section im Theme-Editor oeffnen, neue Felder im Block sichtbar
2. **Markup ergaenzen** — `sections/mdm-collapsible-tabs.liquid`, Einfuegepunkt nach `:145`
   - Guard auf `button_label != blank`, Wrapper-`div`, `render 'mdm-button'`, escapte `assign`s
   - Begruendung: Der Button gehoert in den aufgeklappten Antwortbereich, unterhalb von Antworttext, Custom-Liquid und Page-Content
   - Validierung: Live-Seite — die zehn Eintraege ohne Button rendern unveraendert (kein leerer `div` im DOM), die letzten zwei zeigen den Button
3. **CSS anschliessen** — `assets/mdm-section-collapsible-tabs.css` (generisch) und
   `assets/mdm-section-retoure-faq.css` (Marken-Look)
   - In `mdm-section-collapsible-tabs.css`: `.accordion-details__buttons { display:flex; flex-wrap:wrap; gap:1.2rem; padding-top:0.8rem; }` als generischer Default fuer alle Nutzungen der Section ohne `custom_class`
   - In `mdm-section-retoure-faq.css`: die zwei vorhandenen Selektoren `:41` und `:106` um
     `.mdm-retoure-faq .accordion-details__buttons` erweitern — dann greift das fertige
     MDM-RETOURE-01-Styling (inkl. Mobile-Stacking) **ohne** neue Deklarationen
   - Begruendung: Das Button-Styling existiert bereits vollstaendig (`:41`–`:112`); neu zu schreiben
     waere Duplikat. Die Doppel-Klasse im Markup haelt beide Selektor-Welten bedient
   - Validierung: Desktop nebeneinander mit 12 px Gap, mobil untereinander und volle Breite;
     Primary-Textfarbe bleibt weiss (die `.rte a`-Korrektur `:63`–`:65` greift weiterhin)
4. **Template-Mapping ergaenzen** — `templates/page.faq-seite.json`, drei Stellen (`:40`, `:88`, `:136`)
   - Je zwei Zeilen `button_label` / `button_link` mit Repeater-Ausdruck
   - Begruendung: ohne Mapping bleibt das Metaobjekt-Feld `button` ungenutzt
   - Validierung: alle drei FAQ-Themen pruefen, nicht nur `hilfe_faq_bestellung`
5. **Keine Locale-Aenderung** (siehe naechster Abschnitt)

---

## Uebersetzungs-Keys

✅ **Belegt** — es sind **keine neuen Keys noetig**. Alle benoetigten Schluessel existieren paarig
in `locales/en.default.schema.json` und `locales/de.schema.json`:

| Key | en | de |
|---|---|---|
| `t:general.button.header.content` | „Button settings" | „Tasteneinstellungen" |
| `t:general.button.button_label.label` | „Button label" | „Knopfbeschriftung" |
| `t:general.button.button_label.info` | „Leave blank to hide the button" | „Lassen Sie das Feld leer, um die Schaltflaeche auszublenden" |
| `t:general.button.button_link.label` | „Button link" | „Schaltflaechenlink" |
| `t:general.button.button_style.label` + `options__1/2/4/7` | „Button style" / Primary, Secondary, Underline, Plain | „Knopfstil" / Primaertaste, Sekundaer… |
| `t:general.button.label` (nur Weg B) | „Button" | „Taste" |

Dieselben Keys nutzt bereits die Section-Ebene derselben Datei
(`sections/mdm-collapsible-tabs.liquid:402`, `:407`, `:412`, `:416`–`:428`) — die Wiederverwendung
ist damit hausintern etabliert.

**Nur falls ein FAQ-spezifischer Hinweistext gewuenscht ist** (nicht empfohlen, Scope-Zuwachs):
neues Paar `sections.mdm-collapsible-tabs.blocks.collapsible_item.settings.button_label.info` in
beiden Dateien — mdm-Namespace, analog zu den bereits vorhandenen Eintraegen
`sections.mdm-breadcrumbs`, `sections.mdm-page-title`, `sections.mdm-multicolumn-icon`
(✅ belegt in beiden Schema-Locales).

⚠️ **Hinweis** — die Schema-Locales beginnen mit einem Auto-Generated-Kommentarblock (Zeilen 1–9);
sie sind JSONC, kein reines JSON. Beim Bearbeiten den Kopf erhalten.

---

## Abgrenzung — was NICHT in diesen PR gehoert

- **`sections/collapsible-tabs.liquid` (FoxEcom-Original)** — bleibt unveraendert. Elf Templates
  haengen daran (`templates/page.faq.json:180`/`:284`/`:387`, `templates/page.about.json:518`,
  sieben Produkt-Templates). Wer dort einen Button einbaut, riskiert den halben Shop und bricht
  die Update-Sicherheit.
- **`sections/mdm-product-faq.liquid`** — eigene Section mit eigenem Accordion-Markup
  (`:42`–`:71`); teilt mit `mdm-collapsible-tabs` nur das JS (`:8`) und einige Locale-Keys.
  Kein Button-Bedarf im Ticket. Falls spaeter gewuenscht: eigener PR.
- **Locale-Namespace-Refactor** — `sections/mdm-collapsible-tabs.liquid` nutzt durchgaengig die
  Original-Keys `t:sections.collapsible-tabs.*` (`:179`, `:774`, `:937`) statt eines
  `mdm-`-Namespace. Das ist Altlast, kein Thema dieses Tickets.
- **`button_icon` fuer FAQ-Items** — die Metaobjekt-Definition hat kein Icon-Feld; ein Setting
  ohne Datenquelle waere toter Code.
- **Aenderungen an Metaobjekt-Definitionen oder Datenpflege im Admin** — Kerstins Daten sind
  korrekt gepflegt; der Fehler liegt ausschliesslich im Theme.
- **Retoure-FAQ-Umstellung** — `sections/mdm-retoure-faq`-Styling und die Retoure-Seite bleiben
  funktional unveraendert; dieser PR loest lediglich die bereits vorhandene, bisher ungenutzte
  Wrapper-Klasse ein.
- **Uebertragung nach `themes/borek/` und `themes/imm/`** — ✅ **Belegt**: beide Themes haben
  `sections/mdm-collapsible-tabs.liquid`, aber **kein** `templates/page.faq-seite.json`. Die
  Section-Aenderung ist dort additiv und harmlos, hat aber ohne FAQ-Seite keinen Nutzen.
  Follow-up nach Merge via `bin/theme-sync.sh port mdm borek,imm --commit <sha> --as-patch`
  (nur die Section- und CSS-Hunks; das Template ist markenspezifisch und wird vom Skript ohnehin
  uebersprungen). **Nicht** Teil dieses PRs.
- **Push, Staging-Deploy, Live-Deploy** — nicht Teil dieses PRs. Verifikation laeuft lokal.

### Blast-Radius der geaenderten Section

✅ **Belegt** — `mdm-collapsible-tabs` wird aktuell nur von `templates/page.faq-seite.json`
verwendet (drei Sections, `:35`, `:83`, `:131`; repo-weites grep ueber `templates/`, `sections/`,
`config/`). ⚠️ **Vermutung** — durch das Preset (`sections/mdm-collapsible-tabs.liquid:1591`–`:1606`)
kann die Section jederzeit ueber den Theme-Editor auf weiteren Seiten eingesetzt werden (Bhavani
arbeitet im Editor); solche Einsaetze sind im Repo nicht sichtbar. Beide Wege sind deshalb
**rein additiv und guarded**: ohne gepflegtes Button-Setting aendert sich am gerenderten DOM
nichts.

---

## Template-JSON: Repo oder Theme-Editor?

✅ **Belegt** — `templates/page.faq-seite.json:1`–`:9` traegt den Auto-Generated-Warnhinweis
(„This file may be updated by the Shopify admin theme editor or related systems").
✅ **Belegt** — Editor-Aenderungen laufen als `shopify[bot]`-Commits nach `main` zurueck
(Workspace-Konvention, Harness-Regel `merchant-config.md`).

**Bewertung: die Aenderung gehoert ins Repo.** Begruendung:

- Das `repeater`-Schluesselwort hat **keine** Theme-Editor-Oberflaeche. Kerstin oder Bhavani
  koennen die zwei neuen Mapping-Zeilen im Editor gar nicht setzen — nur die JSON-Datei kann das.
- Die bestehenden Repeater-Zeilen (`:39`, `:87`, `:135`) liegen bereits im Repo und haben
  Editor-Sitzungen ueberlebt — die auto-generierten Section-IDs (`mdm_collapsible_tabs_TjHcdW`,
  `mdm_collapsible_tabs_cpbgLz`) belegen, dass der Editor die Datei schon angefasst hat, waehrend
  die Repeater-Keys erhalten blieben. ⚠️ **Vermutung**: der Editor erhaelt unbekannte Keys beim
  Speichern. ❌ **Unbekannt**: ob das dauerhaft garantiert ist.

**Konsequenzen und Absicherung beim `shopify[bot]`-Sync:**

1. Merge-Reihenfolge: Section + CSS und Template im **selben** PR. Kaeme das Template zuerst,
   wuerden die neuen Settings ins Leere laufen (Repeater mappt auf nicht existierende Settings)
   — ⚠️ **Vermutung**: stillschweigend ignoriert, kein Fehler, aber auch kein Button.
2. Nach Merge und erstem Bot-Sync: `git log --oneline -- templates/page.faq-seite.json` und
   `git diff` gegen den Merge-Stand pruefen. Verschwinden die zwei Mapping-Zeilen, hat der Editor
   sie verworfen → dann ist Weg B2 oder eine Section-interne Loesung die Konsequenz.
3. Kerstin und Bhavani informieren: die drei FAQ-Sections auf `/pages/faq_bestellung` nicht
   ueber „Section duplizieren" im Editor vervielfaeltigen — die Kopie erhaelt keinen Repeater.

---

## Verifikationsschritte

Alles lokal, **kein Push, kein Staging-Push, kein Live-Deploy**.

1. **Probe zum Repeater-Risiko** (vor der Implementierung, siehe oben) — entscheidet A vs. B.
2. **Statisch:** `cd themes/mdm && shopify theme check --output json` und die Findings der
   geaenderten Dateien mit dem Stand vor der Aenderung vergleichen (Kontrolltest auf demselben
   Commit — der Exit-Code ist nicht belastbar, JSON parsen).
3. **Schema-Validierung:** `validate_theme` (Shopify Dev MCP) ueber die geaenderte Section.
4. **Laufzeit:** `shopify theme dev --store mdm-muenze`, Seite `/pages/faq_bestellung` oeffnen.
   - Die zwei Eintraege mit gepflegtem Button zeigen ihn im aufgeklappten Zustand unter der Antwort.
   - Die zehn Eintraege ohne Button rendern unveraendert; im DOM steht **kein** leerer Wrapper.
   - Buttontext und Ziel-URL stimmen mit dem Admin-Wert ueberein (inkl. Query-String
     `?CID=110747332&f=25059` — auf `&amp;`-Doppelescaping achten).
5. **Alle drei FAQ-Themen** pruefen, nicht nur Bestellung: die Sections fuer `hilfe_faq_bezahlung`
   und `hilfe_faq_lieferung` muessen dasselbe Mapping bekommen und dasselbe Verhalten zeigen.
6. **Regression der Nachbarnutzung:** Retoure-Seite und die Hyper-Seiten, die
   `sections/collapsible-tabs.liquid` nutzen (z. B. `/pages/…` mit `page.faq.json`), stichprobenartig
   oeffnen — sie duerfen sich nicht veraendern.
7. **Responsive:** Desktop und < 768 px pruefen (Mobile-Regeln
   `assets/mdm-section-retoure-faq.css:104`–`:112`).
8. **Accessibility-Stichprobe:** der Button ist ein `<a>` im aufgeklappten `<details>`; per Tastatur
   erreichbar erst nach Oeffnen des Accordions — erwartetes Verhalten, kein Fix noetig.
9. Erst nach Konrads Freigabe und gruenem Review: Commit-Message liefern, Push und
   Staging-Deploy separat abstimmen.

---

## Definition of Done

- [ ] Probe durchgefuehrt, Weg A oder B dokumentiert entschieden
- [ ] `shopify theme check` auf den geaenderten Dateien ohne neue Findings (Kontrolltest)
- [ ] `validate_theme` auf `sections/mdm-collapsible-tabs.liquid` sauber
- [ ] Uebersetzungen paarig — in diesem PR: **keine neuen Keys**, nur vorhandene `t:general.button.*` genutzt
- [ ] Section-Preset unveraendert funktionsfaehig (`:1591`–`:1606`)
- [ ] Button erscheint bei allen Eintraegen mit gepflegtem `button`-Feld, in allen drei FAQ-Themen
- [ ] Eintraege ohne Button rendern DOM-identisch zum Stand vor der Aenderung
- [ ] Bestehende Nutzungen von `sections/collapsible-tabs.liquid` unveraendert
- [ ] Escaping-Pfad fuer Label und URL belegt (security-reviewer)
- [ ] Mobile-Darstellung geprueft
- [ ] Follow-up `bin/theme-sync.sh` fuer borek/imm als Notiz im PR vermerkt, nicht ausgefuehrt
- [ ] Kein Push, kein Deploy ohne separate Freigabe

---

## Offene Fragen an Konrad

1. **Weg A oder Weg B** — soll die Probe vorab laufen (empfohlen), oder direkt Weg B als der
   robustere gebaut werden, auch wenn dabei die `btn--*`-Style-Auswahl entfaellt?
2. **`button_style` im Block-Schema** — mitnehmen (vier Optionen, kostenlos, nutzt vorhandene Keys)
   oder weglassen und alle FAQ-Buttons fest auf `btn--primary`?
3. **Template-JSON im Repo** — Einschaetzung oben ist „ja, ins Repo". Soll Kerstin/Bhavani vorab
   informiert werden, dass sie die FAQ-Sections im Editor nicht duplizieren duerfen?
4. **Rueckmeldung an Kerstin** — soll im Ticket vermerkt werden, dass „nur im Template ergaenzen"
   nicht ausreicht und die Section mitgeaendert werden muss?
