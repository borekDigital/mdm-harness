## Plan: Hilfe-Einstiegsseite als page.hilfe-Template

Erstellt am: 24. August 2026 · Revision 4 (24. August 2026) — Scoping-Direktive „maximal vererben",
Branch-Vorgabe „nur die Abschnitte der Hilfe-Seite bearbeiten", Deviation-Basis nach Globalisierung (E-11).
Phase 1 ist umgesetzt.

Die Hilfe-Einstiegsseite entsteht als neues Template `templates/page.hilfe.json` (Layout
`mdm-theme`) aus vier Sections: Breadcrumbs (2-stufig), Seitentitel, Themenkachel-Grid
(6 Kacheln, neu) und Münzlexikon-Teaser. Wiederverwendet werden `mdm-breadcrumbs`,
`mdm-page-title` und `rich-text`; einzig neu gebaut wird die Kachel-Section, weil kein
bestehendes Hyper-/mdm-Muster eine vollflächig klickbare Kachel mit eigenen SVG-Icons und
gegenläufigem Desktop-/Mobile-Layout liefert. **Typografie, Farben und Innenabstände werden
durchgehend aus den Theme-Tokens geerbt** — es gibt kein seitenlokales CSS. Deklariert wird
ausschließlich, was strukturell neu ist und im Theme keinen Wert zum Erben hat. **Keine
einzige bestehende `.liquid`-Datei wird geändert** — der Branch fasst nur neue Dateien plus zwei
rein additive Locale-Kataloge an. Die Newsletter-Section ist als Phase 4 vorbereitet, aber
**blockiert**.

**Phasen:** 6 (davon Phase 4 blockiert und nicht zur Implementierung freigegeben)

---

## 0. Scoping-Direktive dieser Revision

Konrad, 24. August 2026, wörtlich: „die css spezifikationen [sollen] eigentlich soweit wie
möglich vererbt werden […] typography, paddings etc erstmal nicht angefasst werden sollen,
außer es ist jetzt was neues wo es festgelegt werden muss." Auf die Rückfrage zur Grauzone
„neue Section" hat er **„Maximal vererben"** gewählt.

**Der Scoping-Default dieses Workflows ist damit umgekehrt.** Bis Revision 1 galt: jede
Abweichung vom Hyper-Default wird seitenlokal erzwungen. Ab dieser Revision gilt:

> **Der Theme-Wert gewinnt. Deklariert wird nur, wozu es gar keinen erbbaren Wert gibt.**

Das gilt auch innerhalb der neuen Themenkachel-Section: dort wird **nur Struktur** festgelegt
(Grid, Spaltenzahl, Gaps, Border, Icon-Maß und -Position, Link-Mechanik). Typografie, Farben
und Innenabstände kommen aus Theme-Tokens beziehungsweise aus Section-Settings, die
Theme-Tokens auswählen.

**Konsequenz für die Abnahme:** Die Maßtabellen der Design-Spec sind für geerbte
Eigenschaften **kein Abnahmekriterium mehr**. Jede Phase führt deshalb zwei getrennte Listen:

1. **Verbindlich** — die strukturell neu festgelegten Werte. Müssen exakt stimmen, werden abgehakt.
2. **Deviation-Liste** — `Eigenschaft | Figma-Soll | Theme-Ist (geerbt, mit Beleg) | Delta`.
   Diese Liste ist **Ergebnis, nicht Fehler**. Sie ist Konrads Arbeitsgrundlage für den
   Designerinnen-Termin und die späteren Globalisierungs-Entscheidungen (O-14). Der
   theme-reviewer darf Zeilen dieser Liste **nicht** als Findings melden.

Konrad hat ausdrücklich akzeptiert, dass Kacheltitel/-text, Paddings, Container-Breiten und
Button-Farben damit sichtbar von den Figma-Maßen abweichen.

### Zweite Direktive: Branch-Abgrenzung (Revision 3)

Konrad, wörtlich: „es sollen auf dem branch nur die abschnitte Hilfe und Antworten zu häufigen
Fragen bearbeitet werden."

> **Keine bestehende `.liquid`-Datei wird angefasst.** Erlaubt sind ausschließlich neue Dateien
> plus rein additive Ergänzungen in `locales/en.default.schema.json` und `locales/de.schema.json`
> unter dem neuen Namensraum `sections.mdm-help-topic-cards.*`.

Damit entfällt das in Revision 2 geplante Setting `current_label` an
`sections/mdm-breadcrumbs.liquid` **ersatzlos**. Konrad hat dafür „Abweichung akzeptieren"
gewählt: das Breadcrumb-Endsegment rendert `page.title`. Siehe die hervorgehobene Zeile in der
Deviation-Liste von Phase 1.

---

## 1. Beleglage und Vorklärungen

### 1.1 Auflösung „Nexvo" (in Revision 1 noch als Risiko geführt)

- ✅ Belegt: `config/settings_schema.json` → `theme_name: "Hyper"`, `theme_version: "1.3.3"`,
  `theme_author: "FoxEcom"`.
- ✅ Belegt: „Nexvo" kommt in 13 Dateien vor, ausschließlich als Demo-Inhalt/Demo-Domain
  (`sections/overlay-group.json`, `config/settings_data.json`, `templates/product.grid-mix.json`,
  `templates/collection.banner-left.json`, `templates/list-collections.json` u. a.) — alles
  unangetastete Hyper-Demo-Artefakte.
- ⚠️ Vermutung (gut gestützt): „Nexvo" ist der Demo-Store-Markenname der Hyper-Demo. Die
  Annotationen „Nexvo-Section `newsletter` verwenden, nicht neu bauen" und „Icons final aus dem
  Nexvo-Icon-Set" meinen die Komponenten **genau dieses Themes**.
- **Kein Risiko** „Design gegen ein fremdes Theme entworfen".

### 1.2 Template-Suffix und Zielseite

- ✅ Belegt: `templates/page.hilfe.json` existiert nicht (Dateiliste `templates/`, 24. August 2026).
- ✅ Belegt: Zielseite ist die bestehende Live-Seite **Handle
  `hilfe-und-antworten-zu-haufigen-fragen`, Admin-ID `698882949501`** — dieselbe Seite, die
  `templates/page.retoure.json:12` als Breadcrumb-Parent führt.
- ❌ Unbekannt: welchen `template_suffix` diese Seite im Admin aktuell trägt. Das Template
  entsteht deshalb unter dem neuen, unbenutzten Suffix `hilfe`; die Umschaltung macht Konrad
  selbst (Phase 6). Kein Live-Template wird überschrieben, das alte bleibt als Rollback-Pfad.
- ✅ Belegt: `templates/page.faq.json` ist unangetasteter Hyper-Demo-Content (englische Kacheln
  „Shipping", „Returns & Refunds", `:38,51`) — kein Referenzstand.

### 1.3 Was das rohe Hyper-Theme liefert (Stand `3d97a3d`, ohne Globalisierung)

Alle Werte direkt aus dem Theme gelesen, keine Schätzungen. ⚠️ **Achtung:** Diese Tabelle
dokumentiert den **unveränderten Hyper-Stand** und ist damit *nicht* mehr die Deviation-Basis.
Was `assets/mdm-global-overrides.css` davon verschiebt, steht in **1.4** — und nur der Stand
nach 1.4 ist gemäß E-11 maßgeblich.

| Theme-Größe | Wert | Beleg |
|---|---|---|
| `--font-heading-scale` | 1.2 (`heading_scale: 120`) | `snippets/css-variables.liquid:276` |
| `--font-heading-mobile-scale` | 0.84 (`120 × 0.7 / 100`) | `snippets/css-variables.liquid:277`, `settings.heading_mobile_scale: 70` |
| `--font-h1-size` | `1.2 × 4rem` = **48 px** | `snippets/css-variables.liquid:314` |
| `--font-h2-size` | `1.2 × 3.2rem` = **38,4 px** | `snippets/css-variables.liquid:315` |
| `--font-heading-weight` | **600** (`type_header_font: ebgaramond_n6`) | `assets/theme.css:970-973`, `config/settings_data.json` |
| `--font-body-size` | **16 px** (`body_font_size: 16`) | `snippets/css-variables.liquid:268` |
| `--font-body-line-height` | **1.625** (`1.625 + (16−16)×0.025`) | `snippets/css-variables.liquid:19-20,269` |
| `--buttons-height` | **4 rem = 40 px** (`buttons_height: 40`) | `snippets/css-variables.liquid:295` |
| `--buttons-padding` | **3,2 rem = 32 px** | `assets/theme.css:2175` |
| `--buttons-radius` | **0** (hart gesetzt, überschreibt `buttons_corner_radius: round`) | `snippets/css-variables.liquid:335` |
| `--buttons-transform` | `capitalize` | `snippets/css-variables.liquid:294` |
| `--font-button-weight` | **700** | `snippets/css-variables.liquid:293`, `buttons_font_weight: 700` |
| `--page-padding` | 1,6 rem Basis · 5 rem ab 1200 px · 5 rem ab 1280 px · `max(13.5rem, 50vw − scrollbar/2 − 1700px/2)` ab 1536 px | `assets/theme.css:173-175,193-196,198-201,207-211`; `--page-width: 1700px` aus `snippets/css-variables.liquid:346` (`page_width: "1700"`) |
| `.page-width` / `.page-width--fixed` | **keine `max-width`** — `container: fixed` = Viewport minus `--page-padding` | `assets/theme.css:159-162`; keine globale `.page-width--fixed`-Regel (nur collection-scoped in `assets/mdm-collection-layout.css:2,7`) |
| `.page-width--small` | `max-width: 120rem` (= 1200 px) ab 1024 px — trifft das Design, ist aber in den Schemas der genutzten Sections **nicht** als Option angeboten | `assets/theme.css:188-191`; Optionen in `sections/mdm-breadcrumbs.liquid:168-186`, `sections/mdm-page-title.liquid:18-36`, `sections/rich-text.liquid:118-131` |
| `.section--padding` | Mobil `min(4rem, v×0.6)`, Tablet `max(min(v,6rem), v×0.75)`, exakt erst ab 1280 px; honoriert `--section-padding-*-mobile` | `assets/theme.css:168-171,178-181,202-205` |
| `--color-foreground` / `--color-text-heading` | scheme-1 `text` = **#000000** | `snippets/css-variables.liquid:196-197`; Headings erben `color: rgb(var(--color-foreground))` (`assets/theme.css:881`) |
| `--color-subtext` | scheme-1 `subtext` = **#000000** (`.text-subtext`) | `snippets/css-variables.liquid:198`, `assets/theme.css:5389-5391` |
| `--color-border` | **`rgba(0,0,0,0)` — vollständig transparent, in ALLEN 15 Color-Schemes; auch von der Globalisierung NICHT gesetzt** | `config/settings_data.json` (alle Schemes geprüft), emittiert `snippets/css-variables.liquid:200-201` |
| `btn--secondary` in scheme-1 | Hintergrund **#eeecec**, Border **#eeecec**, Text **#000000** | `assets/theme.css:2268-2272`; Werte `config/settings_data.json` scheme-1 (`secondary_button`, `secondary_button_border`, `secondary_button_label`) |
| `.icon--extra-large` | `--icon-size: 3,2 rem` = **32 px**; `.icon` setzt `width/height: var(--icon-size)` | `assets/theme.css:5335`, `.icon` ebenda |
| Globaler Fokusring | `*:focus-visible { outline: 0.2rem solid rgb(var(--color-keyboard-focus)) }` | `assets/theme.css:1122-1123` |
| Theme-Card-Padding (Konvention) | `2,4 rem 2 rem` Desktop, `2,4 rem 1,6 rem` mobil | `assets/mdm-component-multicolumn-card.css:1-10` |
| MDM-Token-Muster (section-scoped) | `--mdm-color-border: #d6cab3`, `--mdm-color-soft-bg: #f6f3ee`, `--mdm-color-title: #002147` … | `assets/mdm-section-main-product.css:58-69` |
| Stone-20 `#d6cab3` / Stone-5 `#f6f3ee` | **Kein Hyper-Token, kein Color-Scheme.** Etablierter MDM-Hardcode in 6+ CSS-Dateien | `assets/mdm-section-breadcrumbs.css:2`, `assets/mdm-collection.css:47,417,945`, `assets/mdm-section-featured-collection.css:126-127`, `assets/mdm-section-product-faq.css:46-51` |

**Befund für Konrad (Hyper-Eigenart, nicht von uns verursacht) — Zahlen im rohen Hyper-Stand;
die nach der Globalisierung gültigen stehen in 1.4:** Die `.h1`-Größe ist über die
Breakpoints **nicht monoton**. Unter 768 px gilt `--font-heading-mobile-scale × --font-h1-size`
= 0,84 × 48 px = **40,32 px** (`assets/theme.css:901-904`), zwischen 768 und 1023 px dagegen
`--font-h1-size × 0.7` = **33,6 px** (`:1004-1007`), ab 1024 px **48 px** (`:1038-1041`). Die
Mobile-H1 ist damit größer als die Tablet-H1. Gleiches Muster bei `.h2`. Relevant für die
Globalisierungs-Entscheidungen (O-14).

### 1.4 Deviation-Basis: Theme-Stand **inkl.** `assets/mdm-global-overrides.css` (E-11)

Parallel zu diesem Ticket lief eine zweite Session an der Globalisierung der Retoure-Styles —
also genau das, was hier als O-14 zurückgestellt war. Sie hat `assets/mdm-global-overrides.css`
angelegt und `layout/mdm-theme.liquid:64` so geändert, dass die Datei **unbedingt für alle
Templates** geladen wird, `page.hilfe` eingeschlossen.

> **Konrads Entscheidung (E-11): Alle Deviation-Listen messen gegen den Stand NACH der
> Globalisierung**, nicht gegen Commit `3d97a3d`. Begründung: das ist die Realität, die im
> Designerinnen-Termin auf dem Schirm ist.

⚠️ **Vorbehalt — Evidenz-Grad.** Zum Zeitpunkt dieser Revision ist die Override-Datei
**uncommitteter Fremdcode** (`git status`: `?? assets/mdm-global-overrides.css`,
` M layout/mdm-theme.liquid`, ` M assets/mdm-section-page-title.css`). Alle daraus abgeleiteten
Ist-Werte sind deshalb **⚠️ Vermutung, nicht ✅ Belegt** — sie sind aus der gelesenen Datei
korrekt hergeleitet, aber der Stand kann sich bis zum Commit noch ändern. Sobald der
Retoure-Branch committet ist, sind die Werte **zu verifizieren**; die Messreihe in Phase 5 ist
der dafür vorgesehene Ort.

Was die Override-Datei ändert (gelesen am 24. August 2026):

| Theme-Größe | vorher | nachher | Beleg |
|---|---|---|---|
| Heading-Farbe (`h1`–`h6`, `.h1`–`.h6`) | `--color-foreground` = #000000 | **#002147** (Prussian) | `assets/mdm-global-overrides.css:10-13` |
| `--color-foreground` (scheme-1) | 0,0,0 | **62,58,50** = #3e3a32 (Stone-100) | `assets/mdm-global-overrides.css:18-19` |
| `--color-subtext` (scheme-1) | 0,0,0 | **62,58,50** = #3e3a32 | `assets/mdm-global-overrides.css:20` |
| `--color-secondary-button` / `-text` / `-border` | #eeecec / #000000 / #eeecec | **#ffffff / #002147 / #002147** | `assets/mdm-global-overrides.css:25-27` |
| `--color-button` / `-text` | #000000 / #ffffff | **#002147 / #ffffff** | `assets/mdm-global-overrides.css:23-24` |
| `--buttons-transform` | `capitalize` | **`none`** | `assets/mdm-global-overrides.css:37` |
| `--font-heading-scale` | 1.2 | **1** | `assets/mdm-global-overrides.css:45` |
| `--font-h1-size` | 48 px | **40 px** | `assets/mdm-global-overrides.css:46` |
| `--font-h2-size` | 38,4 px | **32 px** | `assets/mdm-global-overrides.css:47` |
| H1-Farbe aus `assets/mdm-section-page-title.css` | dort gesetzt | **Zeile entfernt** — Farbe kommt jetzt aus der Override-Datei | `git diff assets/mdm-section-page-title.css` |

**Nicht** überschrieben und damit unverändert gültig: `--color-border` (weiterhin in allen
Schemes transparent → die Kachel-Border bleibt strukturell zu deklarieren), `--buttons-height`
(40 px), `--buttons-padding` (32 px), `--font-heading-weight` (600),
`--font-heading-mobile-scale` (0,84 — wird in Liquid aus den Settings berechnet und von der
CSS-Datei nicht erreicht), `--font-body-line-height` (1,625), Container-Breiten,
Section-Paddings.

**Korrektur zum „Befund Nicht-Monotonie" aus 1.3:** Er bleibt bestehen, nur mit neuen Zahlen.
`.h1` ist nach der Globalisierung <768 px = 0,84 × 40 = **33,6 px**, 768–1023 px = 40 × 0,7 =
**28 px**, ≥1024 px = **40 px**. Die Mobile-H1 ist weiterhin größer als die Tablet-H1, weil
`--font-heading-mobile-scale` weiter mit dem alten Faktor 1,2 gebildet wird. Für den
Designerinnen-Termin relevant.

---

## 2. Wiederverwendungs-Entscheidungen

| Design-Baustein | Entscheidung | Begründung (mit Beleg) |
|---|---|---|
| Breadcrumbs (2-stufig) | **Reuse** `sections/mdm-breadcrumbs.liquid` **völlig unverändert** — nur Template-Settings | Die Section rendert für `page`-Templates Home + `page.title` und kann ein optionales Elternsegment einschieben (`:84-92`). Für die Einstiegsseite bleibt `parent_*` leer → genau 2 Segmente ✅. Das Design fordert „HILFE & SERVICE" als Endsegment, Zeile 92 gibt aber `page.title` aus. Revision 2 hätte das über ein neues Setting `current_label` gelöst; unter der Branch-Direktive (E-7) entfällt das ersatzlos — die Textabweichung wird akzeptiert und dokumentiert. |
| H1-Seitentitel | **Reuse** `sections/mdm-page-title.liquid` unverändert, ohne jeden Override | `:6` rendert `page.title` als `h1.font-heading.h1`; Farbe #002147 und `line-height: 1.2` kommen aus `assets/mdm-section-page-title.css:1-4` und sind **bereits designkonform**. Größe und Schriftschnitt werden geerbt. |
| 6 Themenkacheln | **Neubau** `sections/mdm-help-topic-cards.liquid` (Belege aus Revision 1 gelten unverändert) | `sections/mdm-multicolumn-icon.liquid` vollständig gelesen; vier per Settings **nicht** lösbare Struktur-Defizite: (1) kein die Karte umschließender Link — nur ein optionaler Button je Block (`:141-150`), Kartenmarkup `:84-152`; (2) Icons nur aus 31 festen Phosphor-Werten (`:786-920`, `snippets/mdm-icons.liquid`) oder `image_picker` (`:921-922`) — keine eigenen Theme-SVGs; (3) `image_position` ist ein Section-Setting und legt Zeile/Spalte für alle Breakpoints gleich fest (`:90`) — Desktop-Spalte + Mobile-Zeile unerreichbar; (4) Gap-Tokens liefern 30/12 px, nicht 24/14 px (`assets/theme.css:357-383`). Ein Liquid-Eingriff wäre also ohnehin nötig; dann ist eine schlanke eigene Section den 1263 Zeilen Fremd-Schema vorzuziehen. MDM-Präzedenzfall für ein maßgeschneidertes Karten-Grid: `sections/mdm-product-related-categories.liquid:27-91`. |
| Münzlexikon-Teaser | **Reuse** `sections/rich-text.liquid` (FoxEcom-Original, unverändert) | Liefert genau die drei Blocktypen `heading` (h2 mit `heading_size`, `:25-42`), `text` (richtext, `:43-77`) und `button` (`:78-90`), dazu `container`, `content_alignment: left`, `content_spacing`, Padding (`:114-217`); Preset enthält heading+text+button (`:642-655`). Kein Liquid-Bedarf, kein `mdm-`-Klon. |
| Newsletter | **Reuse** `sections/newsletter.liquid` — **Phase blockiert** | Vollständig gelesen, Details in Phase 4. |
| Icons | **Neu als Theme-Assets** `assets/mdm-icon-hilfe-*.svg` + `inline_asset_content` | Muster im Theme etabliert: `snippets/mdm-button.liquid:65`, `sections/announcement-bar.liquid:64,69,71`. Der späte Austausch ist damit ein reiner **Dateitausch in `assets/`** ohne Code-Änderung (Konrads Anforderung E-3). Gegenüber `<img src=asset_url>`: inline heißt `currentColor` funktioniert und `aria-hidden` sitzt am Wrapper. |
| ❌ Verworfen | `sections/mdm-product-related-categories.liquid` (durch `{% if product.collections.size > 0 %}` auf Produktseiten begrenzt, `:1`; zusätzlich in `product.json`, `product.mdm.json`, `product.flatrate.json` live). `sections/buttons-with-icon.liquid` (Icon + Label, kein Beschreibungstext, `:34-80`). `sections/collection-list*` (bildbasiert). | |
| ❌ Entfällt in dieser Revision | `assets/mdm-page-hilfe.css` und der `template.suffix == 'hilfe'`-Zweig in `layout/mdm-theme.liquid` | Siehe 2.2 — nach Streichung aller Typo-, Padding- und Container-Overrides bleibt keine einzige Regel übrig. |

### 2.1 Blast-Radius-Bewertung

| Datei | Verwendung | Konsequenz |
|---|---|---|
| `sections/mdm-breadcrumbs.liquid` | ✅ Belegt shopweit: `templates/product.json`, `product.mdm.json`, `product.flatrate.json`, `collection.json`, `collection.mdm.json`, `page.retoure.json` | **Wird nicht verändert** (E-7). Nur Template-Settings in `page.hilfe.json`. Kein Blast-Radius. |
| `sections/rich-text.liquid` | ✅ Belegt: in **37** Templates live (u. a. `index.json`, `page.muenzwelt.json`, `page.numismatik.json`, alle `page.muenzausgabeprogramm-*`) | Wird **nicht** verändert. Nur Template-Settings. |
| `layout/mdm-theme.liquid` | Layout aller mdm-Templates | **Wird in dieser Revision nicht verändert.** |
| `sections/newsletter.liquid`, `snippets/newsletter-form.liquid` | ✅ Belegt: `newsletter-form` auch aus `sections/footer.liquid:217`, `sections/popup.liquid:143`, `sections/main-password.liquid:10` | Werden nicht verändert. Textabweichungen sind globale Locale-Keys → O-9. |
| `sections/mdm-multicolumn-icon.liquid` | ✅ Belegt: **in keinem** Template referenziert (Volltextsuche über `templates/`, `config/`, `sections/`, `snippets/`, `layout/` → 0 Treffer); live ist nur das FoxEcom-Original `multicolumn-icon` (13 Templates) | Wird nicht angefasst. |

**Gesamt-Blast-Radius dieses Tickets: null.** Geändert werden ausschließlich
`locales/en.default.schema.json` und `locales/de.schema.json`, rein additiv im neuen Namensraum
`sections.mdm-help-topic-cards.*` — keine bestehende Übersetzung wird berührt. Alles Übrige sind
neue Dateien. **Keine einzige bestehende `.liquid`-Datei**, kein Eingriff in `layout/`, `config/`,
`assets/theme.css`, bestehendes mdm-CSS oder ein anderes Template.

### 2.2 Entfällt `assets/mdm-page-hilfe.css` samt Layout-Hook? — Ja, ersatzlos

Geprüft, Regel für Regel aus Revision 1:

| Regel aus Revision 1 | Verbleib |
|---|---|
| Breadcrumbs-Typo (`font-size`, `font-weight`, `letter-spacing`, Item-Gap, Endsegment-Weight) | **gestrichen** — geerbt aus dem `{% style %}`-Block der Section (`sections/mdm-breadcrumbs.liquid:14-63`) |
| `--section-padding-top: 48px` zur Umgehung des Range-Limits 40 | **gestrichen** — 40 px werden akzeptiert |
| H1-Overrides (`font-size`, `font-weight`, `letter-spacing`) | **gestrichen** — geerbt; Farbe und `line-height` liefert `assets/mdm-section-page-title.css` ohnehin designkonform |
| Container-Geometrie (`max-width: 120rem`, `--page-padding`) | **gestrichen** — `container: fixed` ist ein vom Theme gelieferter Container (Viewport minus `--page-padding`) und wird geerbt |
| Münzlexikon-Typo, Textbreite 760 px, Blockabstände, Buttonmaße und -farben | **gestrichen** — geerbt; Abstände über das Setting `content_spacing` |
| Mobile-Paddings via `--section-padding-*-mobile` | **gestrichen** — die Skalierung von `.section--padding` wird geerbt |
| Mobile-Full-Width-Button | **gestrichen** — kein Theme-Utility vorhanden (`btn--full*` existiert nicht), Button bleibt intrinsisch |

**Ergebnis:** keine verbleibende Regel. `assets/mdm-page-hilfe.css` wird **nicht angelegt**, der
`template.suffix == 'hilfe'`-Zweig in `layout/mdm-theme.liquid` **nicht eingebaut**. Das
strukturell Notwendige der neuen Section lebt in ihrem eigenen
`assets/mdm-section-help-topic-cards.css`, das die Section selbst per `stylesheet_tag` lädt
(Muster: `sections/mdm-multicolumn-icon.liquid:1`, `sections/mdm-page-title.liquid:1`).

### 2.3 Soll-Zustand der Dateiliste (Branch-Direktive E-7)

**NEU:**
- `templates/page.hilfe.json`
- `sections/mdm-help-topic-cards.liquid`
- `assets/mdm-section-help-topic-cards.css`
- `assets/mdm-icon-hilfe-bestellung.svg`, `-bezahlung.svg`, `-versand-lieferung.svg`,
  `-retoure-reklamation.svg`, `-kundendaten.svg`, `-kollektion.svg`

**ÄNDERN — ausschließlich diese zwei, rein additiv im neuen Namensraum
`sections.mdm-help-topic-cards.*`:**
- `locales/en.default.schema.json`
- `locales/de.schema.json`

**NICHT ANGEFASST:** `sections/mdm-breadcrumbs.liquid` · `sections/mdm-page-title.liquid` ·
`sections/rich-text.liquid` · `sections/newsletter.liquid` · `snippets/newsletter-form.liquid` ·
`layout/mdm-theme.liquid` · `config/` · `assets/theme.css` · jedes bestehende `assets/mdm-*.css` ·
jedes andere Template. **Keine bestehende `.liquid`-Datei.**

⚠️ **Vorbehalt Phase 4:** Wird die Newsletter-Section später entblockt, braucht ihr
Stone-5-Hintergrund entweder ein neues Color-Scheme (globale Änderung in `config/`, nur mit
Konrads Freigabe) oder doch eine seitenlokale Datei. Diese Entscheidung fällt **mit** Phase 4,
nicht vorher.

---

## 3. Phase 1: Grundgerüst — Template und Kopfbereich

> **Status: UMGESETZT** (24. August 2026). `templates/page.hilfe.json` angelegt (28 Zeilen),
> `shopify theme check` null Findings zu der Datei, Dev-MCP `validate_theme` VALID,
> Verbindlich-Liste vollständig abgehakt. Das Review-Paar läuft erst nach dem Branch-Wechsel,
> gemeinsam mit Phase 2. Zwei Deviation-Zeilen wurden dabei belegt korrigiert (Mobile-Padding,
> s. Kasten), und die Deviation-Basis hat sich durch E-11 verschoben.

- **Ziel:** `templates/page.hilfe.json` existiert, ist im Theme-Editor ladbar und rendert den
  Kopfbereich (Breadcrumbs „STARTSEITE | HILFE & SERVICE" + H1) mit **vollständig geerbter**
  Typografie und Geometrie.

- **Dateien:**
  - NEU `templates/page.hilfe.json` — Layout `mdm-theme`, zunächst zwei Sections
    (`mdm-breadcrumbs`, `mdm-page-title`) plus `order`. Kein Auto-Generated-Banner. Muster:
    `templates/page.retoure.json:1-25` ✅.
  - **KEINE Änderung an bestehenden Dateien.** Insbesondere bleibt
    `sections/mdm-breadcrumbs.liquid` unangetastet (E-7): kein `current_label`, kein Eingriff in
    den `{% style %}`-Block, keine Schema-Erweiterung. Auch **kein** `assets/mdm-page-hilfe.css`
    und **keine** Layout-Änderung.
  - In dieser Phase entstehen **keine** neuen Locale-Keys — die Schema-Keys der Phase 2 sind die
    einzigen des ganzen Tickets.

- **Template-Settings (alles Settings, keine CSS-Overrides):**
  - `mdm-breadcrumbs`: `container: fixed`, `text_alignment: start`, `separator_style: pipe`
    (Design zeigt Pipe), `show_divider: false`, `parent_label: ""`, `parent_url: ""`,
    `link_color: "#615b4f"`, `padding_top: 40`, `padding_bottom: 16`.
    - `link_color` ist ein **Section-Setting**, keine CSS-Überschreibung; der Wert ist
      designkonform (Stone-80) und deckungsgleich mit der Schwesterseite
      (`templates/page.retoure.json:13`).
    - `padding_top: 40` ist das Maximum des Ranges (`sections/mdm-breadcrumbs.liquid:247-255`).
      Das Range wird **nicht** erweitert; 40 statt 48 px ist eine Deviation.
  - `mdm-page-title`: `container: fixed`, `padding_top: 0`, `padding_bottom: 32`.

- **Validierung:**
  - `shopify theme check --fail-level error` dateibezogen auf `templates/page.hilfe.json`.
  - Dev-MCP `validate_theme` (Strict-Parse seit 13.01.2026).
  - `python3 -c "import json;json.load(open('templates/page.hilfe.json'))"` → JSON parst.
  - Editor-Test: Template auswählbar, beide Sections konfigurierbar.
  - **Branch-Probe:** `git status --short` zeigt in dieser Phase **nur** die neue
    Template-Datei — keine geänderte bestehende Datei. Ein Regressionstest auf Produkt-,
    Kollektions- oder Retoure-Seite entfällt, weil keine geteilte Datei angefasst wird.
  - **Grep-Probe:** kein `font-size`, `font-weight`, `letter-spacing`, `padding`, `max-width`
    zu dieser Seite außerhalb von Section-Settings.

- **Verbindlich (muss exakt stimmen):**
  - [ ] `templates/page.hilfe.json` mit Layout `mdm-theme`, Sections in der Reihenfolge
        `mdm-breadcrumbs` → `mdm-page-title`
  - [ ] Genau 2 Breadcrumb-Segmente (kein Elternsegment)
  - [ ] Segment 1 „STARTSEITE" verlinkt auf `routes.root_url`
  - [ ] Segment 2 mit `aria-current="page"`, nicht verlinkt, Text = `page.title`
        (die Textabweichung zum Design ist akzeptiert, s. Deviation-Liste)
  - [ ] Separator-Stil Pipe, keine Trennlinie unter den Breadcrumbs
  - [ ] Breadcrumbs auch auf Mobile sichtbar (Unterschied zu `page.retoure`)
  - [ ] H1 rendert `page.title`, keine Größen-/Schnitt-Deklaration im Repo
  - [ ] `padding_bottom` Breadcrumbs 16 + `padding_top` Titel 0 ⇒ Gap 16 px ab 1280 px
  - [ ] Kein `assets/mdm-page-hilfe.css`, keine Änderung in `layout/mdm-theme.liquid`
  - [ ] `sections/mdm-breadcrumbs.liquid` unverändert (Diff leer)

- **Deviation-Liste Phase 1** (Ergebnis, kein Fehler).
  **Basis: Theme-Stand inkl. `assets/mdm-global-overrides.css` (E-11).** Werte, die aus dieser
  noch uncommitteten Datei stammen, sind ⚠️ Vermutung und in Phase 5 zu verifizieren.

  | Eigenschaft | Figma-Soll | Theme-Ist (geerbt) | Beleg | Delta |
  |---|---|---|---|---|
  | **Breadcrumb-Endsegment (Text)** | **„HILFE & SERVICE"** | **„Hilfe und Antworten zu häufigen Fragen"** (= `page.title`) | `sections/mdm-breadcrumbs.liquid:92` | **Textabweichung — s. Kasten unter der Tabelle** |
  | Content-Breite @1440 | 1200 px | 1340 px | `assets/theme.css:159-162,198-201` (kein `max-width`, `--page-padding: 5rem`) | +140 px |
  | Seitlicher Abstand @1440 | 120 px | 50 px | dito | −70 px |
  | Content-Breite @390 | 350 px | 358 px | `assets/theme.css:173-175` (`--page-padding: 1.6rem`) | +8 px |
  | Seitlicher Abstand @390 | 20 px | 16 px | dito | −4 px |
  | Breadcrumbs font-size Desktop | 12 px | 10 px | `sections/mdm-breadcrumbs.liquid:17` | −2 px |
  | Breadcrumbs font-size Mobile | 12 px | 14 px | `sections/mdm-breadcrumbs.liquid:56` | +2 px |
  | Breadcrumbs letter-spacing Desktop | 1,2 px | 0,8 px (`0.08em` @10 px) | `sections/mdm-breadcrumbs.liquid:19` | −0,4 px |
  | Breadcrumbs letter-spacing Mobile | 1,2 px | 0,56 px (`0.04em` @14 px) | `sections/mdm-breadcrumbs.liquid:57` | −0,64 px |
  | Breadcrumbs line-height | 1,4 | 1,4 | `sections/mdm-breadcrumbs.liquid:18` | 0 ✓ |
  | Breadcrumbs uppercase | ja | ja | `sections/mdm-breadcrumbs.liquid:21` | 0 ✓ |
  | Breadcrumb-Link font-weight | 600 | 400 (`--font-body-weight`, nicht gesetzt) | `snippets/css-variables.liquid:266` | −200 |
  | Endsegment font-weight | 600 | 700 | `sections/mdm-breadcrumbs.liquid:51` | +100 |
  | Item-Gap Desktop | 12 px | 8 px (`margin: 0 0.8rem`) | `sections/mdm-breadcrumbs.liquid:35` | −4 px |
  | Item-Gap Mobile | 12 px | 6 px (`margin: 0 0.6rem`) | `sections/mdm-breadcrumbs.liquid:61` | −6 px |
  | Separator 1×14 px, Stone-80 / letzter Stone-100 | wie Soll | identisch | `sections/mdm-breadcrumbs.liquid:38-47` | 0 ✓ |
  | Endsegment-Farbe Prussian | #002147 | #002147 | `sections/mdm-breadcrumbs.liquid:50` | 0 ✓ |
  | Link-Farbe Stone-80 | #615b4f | #615b4f (per Setting) | `sections/mdm-breadcrumbs.liquid:20,241-245` | 0 ✓ |
  | H1 font-size ≥1024 | 40 px | **40 px** (`--font-h1-size` global auf 4 rem) | ⚠️ `assets/mdm-global-overrides.css:45-46` + `assets/theme.css:1038-1041` | **0 ✓** |
  | H1 font-size 768–1023 | — (kein Frame) | 28 px (`40 × 0.7`) | ⚠️ dito + `assets/theme.css:1004-1007` | ⚠️ kein Soll |
  | H1 font-size <768 | 28 px | 33,6 px (`0.84 × 40`) | ⚠️ dito + `assets/theme.css:901-904` | +5,6 px |
  | H1 font-weight | 500 | 600 | `assets/theme.css:970-973`, `type_header_font: ebgaramond_n6` | +100 |
  | H1 line-height | 1,2 | 1,2 | `assets/mdm-section-page-title.css:2` | 0 ✓ |
  | H1 Farbe Prussian | #002147 | #002147 — Quelle gewechselt: nicht mehr `mdm-section-page-title.css`, sondern der globale Heading-Override | ⚠️ `assets/mdm-global-overrides.css:10-13` | 0 ✓ |
  | Kopfbereich padding-top ≥1280 | 48 px | 40 px (Range-Maximum) | `sections/mdm-breadcrumbs.liquid:247-255`, `assets/theme.css:202-205` | −8 px |
  | Kopfbereich padding-top <768 | 28 px | **12 px — fest, Settings greifen nicht** (s. Kasten) | `assets/theme.css:7618-7621` | **−16 px** |
  | Gap Breadcrumbs → H1 ≥1280 | 16 px | 16 px | Settings 16 + 0 | 0 ✓ |
  | Gap Breadcrumbs → H1 <768 | 16 px | **12 px** (fixes Breadcrumb-`padding-block` + Titel-`padding_top` 0) | `assets/theme.css:7618-7621` | **−4 px** |
  | Kopfbereich padding-bottom ≥1280 | 32 px | 32 px | Setting | 0 ✓ |
  | Kopfbereich padding-bottom <768 | 24 px | 19,2 px (`min(4rem, 32×0.6)`) | `assets/theme.css:170` | −4,8 px |
  | Kopfbereich-Gesamthöhe Desktop | 209 px | ❌ Unbekannt (Summe geerbter Werte, Messreihe Phase 5) | — | — |
  | H1-Zeilenumbruch (2 Zeilen Desktop) | 2 | ❌ Unbekannt (Folge von 48 px bei 1340 px Breite) | — | Messreihe Phase 5 |

  **Zur ersten Zeile — das Breadcrumb-Endsegment.** `sections/mdm-breadcrumbs.liquid:92` gibt im
  `page`-Zweig unbedingt `page.title` aus; ein Override ist ohne Änderung dieser shopweit
  genutzten Section nicht möglich, und die Branch-Direktive (E-7) verbietet sie. Das Endsegment
  zeigt deshalb „Hilfe und Antworten zu häufigen Fragen".

  **Ein Admin-Rename der Seite löst das nicht.** Das Design setzt die beiden Texte *bewusst*
  unterschiedlich: H1 = „Hilfe und Antworten zu häufigen Fragen" (design-spec Zeile 197 Desktop,
  Zeile 221 Mobile), Breadcrumb-Endsegment = „HILFE & SERVICE". Beide Elemente speisen sich aus
  derselben Quelle `page.title` (`sections/mdm-page-title.liquid:6`,
  `sections/mdm-breadcrumbs.liquid:92`) — ein kürzerer Seitentitel würde also den H1
  mitverkürzen und die Design-Vorgabe dort brechen. Es gibt keine Einstellung, die beide
  gleichzeitig erfüllt.

  **Auflösung nur über den Designerinnen-Termin**, zwei Wege:
  - **A:** Breadcrumb-Text im Design an den Seitentitel angleichen (dann ist die Abweichung
    erledigt, ohne jede Code-Änderung) — Empfehlung, weil kostenlos.
  - **B:** eigenes Folgeticket für ein `current_label`-Setting an `mdm-breadcrumbs`, mit dann
    bewusst akzeptiertem shopweitem Blast-Radius (6 Templates). Als **O-22** geführt.

  **Korrektur gegenüber Revision 3 — Mobile-Padding der Breadcrumb-Section.** Der Plan lag
  falsch: `assets/theme.css:7618-7621` setzt unter 767,98 px `.section-breadcrumb
  { padding-block: 1.2rem; }`. Die Regel hat dieselbe Spezifitätsklasse wie `.section--padding`
  (`assets/theme.css:167-170`, beide 0,1,0), steht aber rund 7450 Zeilen später und **gewinnt
  damit in der Kaskade** — Shorthand gegen Longhand spielt dafür keine Rolle, nur die
  Quellreihenfolge. Auf Mobile hat die Breadcrumb-Section deshalb **fest 12 px oben und unten**;
  die Settings `padding_top`/`padding_bottom` greifen dort **nicht**. Die in Revision 2/3
  angesetzten Werte (24 px bzw. 9,6 px aus `min(4rem, v×0.6)`) waren falsch und sind oben
  ersetzt. ✅ Statisch aus der Kaskade belegt; visuelle Bestätigung in Phase 5.
  Nebenbefund: `assets/mdm-section-breadcrumbs.css` greift für diese Section überhaupt nicht —
  die Datei selektiert `.mdm-breadcrumbs`, gerendert wird `mdm-breadcrumbs-{{ section.id }}`
  (`sections/mdm-breadcrumbs.liquid:75`). Bestandsfehler, nicht Teil dieses Branches → **O-23**.

- **Schritte:**
  1. `templates/page.hilfe.json` mit den zwei Sections und den oben genannten Settings anlegen.
  2. Validierung inklusive Branch- und Grep-Probe fahren, „Verbindlich" abhaken,
     Deviation-Liste mit gemessenen Ist-Werten füllen.
  3. Review-Paar (theme-reviewer ∥ security-reviewer) starten — mit dem Hinweis, dass die
     Breadcrumb-Textabweichung eine akzeptierte Deviation ist, kein Finding.

---

## 4. Phase 2: Themenkacheln (neue Section + 6 Icon-Assets)

- **Ziel:** Sechs Themenkacheln in fester Reihenfolge, Desktop 3×2 mit Icon oben zentriert,
  Mobile 1-spaltig mit Icon links. Ziel-URLs als Settings mit leerem Default; ohne URL rendert
  die Kachel nicht-klickbar. **Nur Struktur wird deklariert** — Typografie, Farben und
  Innenabstände kommen aus Theme-Tokens oder aus Settings, die Theme-Tokens auswählen.

- **Dateien:**
  - NEU `sections/mdm-help-topic-cards.liquid` — `topic_card`-Blocks, Preset mit 6 Blocks.
  - NEU `assets/mdm-section-help-topic-cards.css` — **ausschließlich Struktur**: Grid,
    Kachel-Box (Border, Position, `min-height` weggelassen), Icon-Box, Layoutwechsel
    Spalte/Zeile, Fokus-Platzierung. Kein `font-size`, kein `font-weight`, kein
    `letter-spacing`, kein `line-height`, keine Farben außer der Border.
  - NEU 6× `assets/mdm-icon-hilfe-<slug>.svg` (`bestellung`, `bezahlung`, `versand-lieferung`,
    `retoure-reklamation`, `kundendaten`, `kollektion`) — normalisierte Kopien aus
    `Tickets/In-progress/MDM-HILFE-01/assets-src/icon-*.svg`.
  - ÄNDERN `templates/page.hilfe.json` (neue Datei aus Phase 1).
  - ÄNDERN `locales/en.default.schema.json`, `locales/de.schema.json` — **rein additiv** unter
    dem neuen Namensraum `sections.mdm-help-topic-cards.*`; keine bestehende Übersetzung wird
    berührt (E-8). Das sind die **einzigen** Bestandsdateien, die dieses Ticket anfasst.

- **Was deklariert wird (strukturell neu, kein erbbarer Wert vorhanden):**
  1. **Grid** — 3 Spalten ≥1024 px, 2 Spalten 768–1023 px, 1 Spalte <768 px, gesteuert über die
     Settings `columns_desktop`/`columns_tablet`. Eigenes CSS-Grid statt Hyper-`f-grid`, weil
     die Gap-Tokens 30/12 px liefern (`assets/theme.css:357-383`), nicht 24/14 px.
  2. **Gaps** — 24 px (beide Achsen) ab 768 px, 14 px unter 768 px.
  3. **Layoutwechsel** — ≥768 px `flex-direction: column` mit `align-items: center`, <768 px
     `flex-direction: row` mit `align-items: center` und Icon-zu-Text-Gap 16 px. Dieser
     breakpointabhängige Wechsel existiert im Theme nicht.
  4. **Kachel-Border 1 px** — es gibt **keinen erbbaren sichtbaren Border**: `--color-border` ist
     in **allen 15** Color-Schemes `rgba(0,0,0,0)` (`config/settings_data.json`, emittiert
     `snippets/css-variables.liquid:200-201`). Deshalb als section-scoped MDM-Token nach dem
     etablierten Muster von `assets/mdm-section-main-product.css:58-69`:
     `--mdm-color-border: #d6cab3`. Stone-20 ist im Theme bereits als Rahmenfarbe in Gebrauch
     (`assets/mdm-section-breadcrumbs.css:2`, `assets/mdm-collection.css:945`,
     `assets/mdm-section-featured-collection.css:126`).
  5. **Icon-Maß und -Position** — 32 px werden **geerbt** über die Theme-Klassen
     `icon icon--extra-large` am Wrapper (`.icon--extra-large { --icon-size: 3.2rem }`,
     `assets/theme.css:5335`; `.icon` setzt `width/height: var(--icon-size)`). Deklariert wird
     nur `svg { width: 100%; height: 100% }` (weil das inline eingebundene SVG eigene
     `width`/`height`-Attribute trägt) sowie die Position im Kachel-Layout.
  6. **Stretched-Link-Mechanik** — Kachel `position: relative`, Titel-Link mit
     `::after { position: absolute; inset: 0 }`. Bei leerem `link` entfällt sowohl der `<a>` als
     auch das Overlay.
  7. **Fokus-Platzierung** — der Fokusring selbst wird geerbt
     (`*:focus-visible { outline: 0.2rem solid rgb(var(--color-keyboard-focus)) }`,
     `assets/theme.css:1122-1123`). Deklariert wird nur, dass er die **Kachel** umschließt
     (`:has(a:focus-visible)`), unter Wiederverwendung von Breite und Token der globalen Regel.
  8. **`border-radius: 0`** ist **nicht** zu deklarieren: die Kachel erhält keine
     `blocks-radius`-Klasse, damit greift `--blocks-radius` (`blocks_corner_radius: slightly`)
     gar nicht. Ebenso entfällt der Hover-Shadow, der nur an `.multicolumn-card-wrapper` hängt
     (`assets/mdm-component-multicolumn-card.css:11-17`).

- **Was geerbt wird (keine Deklaration):**
  - **Kachel-Innenpadding** — es gibt keinen globalen Spacing-Token, aber eine
    Theme-Card-Konvention: `2,4 rem 2 rem` Desktop / `2,4 rem 1,6 rem` mobil
    (`assets/mdm-component-multicolumn-card.css:1-10`). Diese Werte werden **übernommen**, nicht
    die Figma-Werte 28/20 px. Damit wird keine neue Zahl erfunden.
  - **Titel-Typografie** — über die Settings `title_font` (`heading`/`body`, Default `body`) und
    `title_size` (Theme-Token-Auswahl `text-sm`/`text-base`/`text-lg`/`h6`/`h5`, Default
    `text-base`), gerendert als Theme-Utility-Klassen. **Kein `font-size` im CSS.** Konrad kann
    im Editor nachjustieren, ohne dass eine Zeile CSS entsteht.
  - **Beschreibungs-Typografie** — Klassen `rte text-subtext` plus Setting `text_size`
    (Default `text-base`). Farbe aus `--color-subtext`.
  - **Icon-Farbe** — `currentColor`; optionales Setting `icon_color` (leerer Default ⇒ erbt die
    Textfarbe der Kachel), Muster wie `sections/mdm-multicolumn-icon.liquid:59`.
  - **Titel-Element** — `<h3>` mit Utility-Klassen; das Element-Styling von `h3`
    (`assets/theme.css:912-916`) wird durch die Utility-Klasse überschrieben, damit die
    38,4-px-Heading-Skala nicht greift.
  - **Section-Padding** — Settings `padding_top: 0`, `padding_bottom: 48`, Skalierung von
    `.section--padding` geerbt.

- **Section-Aufbau (ohne Code):**
  - Wrapper `div.section.section-<id>.section--padding.mdm-help-topics` mit
    `page-width page-width--{{ container }}` und `--section-padding-*` aus Settings — Muster
    `sections/mdm-multicolumn-icon.liquid:51-64`.
  - `<ul role="list">` mit `<li>` je Block (Listensemantik, Spec 3.2).
  - Tag-Wechsel für den Link nach dem Muster `sections/buttons-with-icon.liquid:37-42`.
    ⚠️ Wichtig: `snippets/button.liquid:46` und `snippets/mdm-button.liquid:46` prüfen `!= nil`
    statt `!= blank` — ein leeres URL-Setting erzeugt dort `href=""`. Die neue Section verwendet
    deshalb **nicht** `render 'mdm-button'`, sondern prüft explizit auf `!= blank`.
  - Icon: `<span class="icon icon--extra-large mdm-help-card__icon" aria-hidden="true">` mit
    `{{ 'mdm-icon-hilfe-<slug>.svg' | inline_asset_content }}`; Slug aus einem `select` mit den
    sechs Werten plus `none` (bei `none` kein Wrapper).
  - Zugänglicher Name = Kacheltitel (Beschreibung liegt außerhalb des Linktexts, damit
    Screenreader-Linklisten kurz bleiben). Icons dekorativ — Annotation HUB-2 erfüllt.
  - Section-Settings: `container` (full/fixed, Default fixed), `color_scheme`, `heading`
    (leer erlaubt), `columns_desktop` (2–4, Default 3), `columns_tablet` (1–3, Default 2),
    `title_font`, `title_size`, `text_size`, `icon_color`, `padding_top` (0), `padding_bottom` (48).
  - Block-Settings `topic_card`: `icon` (select, 6 + none), `title` (text), `title_mobile`
    (text, optional — **Entscheidung E-5**, ein DOM-Textknoten), `text` (inline_richtext),
    `link` (url, kein Default).
  - `presets` mit 6 `topic_card`-Blocks in Design-Reihenfolge (Editor-Preset ist DoD).

- **SVG-Vertrag für die Icon-Assets (Anforderung E-3: Austausch = reiner Dateitausch).**
  Als Kommentar in `assets/mdm-section-help-topic-cards.css` zu dokumentieren:
  - `viewBox="0 0 32 32"` beibehalten.
  - `stroke="#002147"` → `stroke="currentColor"`, damit die Farbe per Token steuerbar bleibt.
    ✅ Belegt: alle sechs Exporte tragen `stroke="#002147"`, z. B.
    `assets-src/icon-versand-lieferung.svg` (2 Pfade, 2 Kreise).
  - `preserveAspectRatio="none"`, `overflow="visible"`, `style="display: block;"` entfernen
    (Figma-Artefakte, verzerren bei abweichendem Seitenverhältnis).
  - `<g id="Icon &#194;&#183; …">`-Wrapper mit den mangelten Entities entfernen; `id`-Attribute
    an Pfaden entfernen (kollidieren beim Inlinen mehrerer Icons auf einer Seite).
  - `focusable="false"` ergänzen; `aria-hidden` sitzt am Wrapper.
  - Dateiname ist der Vertragsanker: ein finales Icon ersetzt die Datei unter identischem
    Namen — kein Liquid-, Schema- oder Template-Eingriff.

- **Validierung:**
  - `shopify theme check --fail-level error` auf Section, CSS, Template, Schema-Locales.
  - Dev-MCP `validate_theme_codeblocks` auf `sections/mdm-help-topic-cards.liquid`.
  - Editor-Preset-Test: Section einfügbar, liefert 6 Blocks.
  - **Direktiv-Probe:** `assets/mdm-section-help-topic-cards.css` enthält **kein** `font-size`,
    `font-weight`, `letter-spacing`, `line-height` und keine Farbe außer `--mdm-color-border`
    (Grep-Nachweis im Review).
  - Link-Probe: Block ohne `link` rendert kein `<a>` und kein `href`; Block mit `link` ist auf
    der gesamten Kachelfläche klickbar.
  - Tastatur-Probe: Tab-Stopps nur für Kacheln mit URL, Fokusring umschließt die Kachel.
  - Screenreader-Probe (VoiceOver): Linkname = Kacheltitel, Icons werden nicht angesagt.
  - `title_mobile`-Probe: nur **ein** Textknoten im DOM.

- **Verbindlich (muss exakt stimmen):**
  - [ ] 3 Spalten ≥1024 px, 2 Spalten 768–1023 px, 1 Spalte <768 px
  - [ ] Grid-Gap 24 px in beiden Achsen ≥768 px
  - [ ] Grid-Gap 14 px <768 px
  - [ ] ≥768 px: Kachel `flex-direction: column`, `align-items: center`, Icon oben, Text zentriert
  - [ ] <768 px: Kachel `flex-direction: row`, `align-items: center`, Icon links, Text linksbündig
  - [ ] Icon-zu-Text-Gap <768 px = 16 px
  - [ ] Textblock-Gap Titel → Beschreibung <768 px = 4 px
  - [ ] Kachel-Border 1 px solid `#d6cab3` über section-scoped `--mdm-color-border`
  - [ ] Kachel-Hintergrund White (aus `color_scheme`, keine Deklaration)
  - [ ] Kein `border-radius`, kein Box-Shadow (durch Nicht-Verwendung der Hyper-Klassen)
  - [ ] Icon 32×32 px über die geerbten Klassen `icon icon--extra-large`
  - [ ] `<ul role="list">` mit 6 `<li>`
  - [ ] Reihenfolge: Bestellung, Bezahlung, Versand & Lieferung, Retoure & Reklamation,
        Kundendaten, Kollektion & Sammeln
  - [ ] Kacheltexte wörtlich gemäß Spec 3.5
  - [ ] Kachel 6: `title` = „Kollektion & Sammeln", `title_mobile` = „Kollektion", ein DOM-Textknoten
  - [ ] Kacheln ohne `link`: kein `<a>`, kein `href`, kein Overlay
  - [ ] Alle 6 `link`-Settings leer ausgeliefert (auch Retoure — O-3 offen)
  - [ ] Fokusring aus `--color-keyboard-focus`, 0,2 rem, umschließt die Kachel
  - [ ] Editor-Preset mit 6 Blocks vorhanden
  - [ ] 6 normalisierte SVGs in `assets/`, alle mit `stroke="currentColor"` und ohne
        Figma-Artefakte

- **Deviation-Liste Phase 2** (Ergebnis, kein Fehler).
  **Basis: Theme-Stand inkl. `assets/mdm-global-overrides.css` (E-11)**; daraus abgeleitete
  Werte sind ⚠️ Vermutung und in Phase 5 zu verifizieren.

  | Eigenschaft | Figma-Soll | Theme-Ist (geerbt) | Beleg | Delta |
  |---|---|---|---|---|
  | Kachel-Padding ≥768 px | 28 px allseitig | 24 px oben/unten, 20 px seitlich | `assets/mdm-component-multicolumn-card.css:1-5` (Theme-Card-Konvention) | −4 / −8 px |
  | Kachel-Padding <768 px | 20 px allseitig | 24 px oben/unten, 16 px seitlich | `assets/mdm-component-multicolumn-card.css:6-10` | +4 / −4 px |
  | Kachel-Breite @1440 | 384 px | ❌ Unbekannt — Folge der Container-Breite 1340 px bei 3 Spalten und 24 px Gap; rechnerisch ≈ 430 px | Messreihe Phase 5 | ≈ +46 px |
  | Kachel-Höhe ≥1024 px | 190 px (`min-height`) | inhaltsgetrieben, kein `min-height` deklariert | Direktive: keine erfundene Zahl | ❌ Unbekannt |
  | Kachel-Höhe <768 px | 114 px | inhaltsgetrieben | dito | ❌ Unbekannt |
  | Titel font-size ≥1024 px | 19 px | 16 px (`.text-base` → `--font-body-size`) | `assets/theme.css:5675-5678`, `snippets/css-variables.liquid:268` | −3 px |
  | Titel font-size <768 px | 17 px | 16 px | dito | −1 px |
  | Titel line-height | 1,55 | 1,625 (`--font-body-line-height`) | `snippets/css-variables.liquid:19-20,269` | +0,075 |
  | Titel font-weight | 600 | 400 (`title_font: body` ⇒ `--font-body-weight`) | `snippets/css-variables.liquid:266` | −200 |
  | Titel-Farbe | Prussian #002147 | **#002147** — der Titel ist ein `<h3>` und trifft den globalen Heading-Override | ⚠️ `assets/mdm-global-overrides.css:10-13` | **0 ✓** |
  | Beschreibung font-size ≥1024 px | 15 px | 16 px (`.text-base`) | `assets/theme.css:5675-5678` | +1 px |
  | Beschreibung font-size <768 px | 14 px | 16 px | dito | +2 px |
  | Beschreibung line-height | 1,55 | 1,625 | `snippets/css-variables.liquid:269` | +0,075 |
  | Beschreibung Farbe | Stone-100 #3e3a32 | **#3e3a32** (`--color-subtext` global auf 62,58,50) | ⚠️ `assets/mdm-global-overrides.css:20` | **0 ✓** |
  | Icon-Farbe | Prussian #002147 | `currentColor` ⇒ #3e3a32 (Stone-100; per Setting `icon_color` auf Prussian stellbar) | ⚠️ `assets/mdm-global-overrides.css:18-19` | Farbe |
  | Innen-Gap ≥768 px (Icon→Titel→Text) | 12 px | ❌ Unbekannt — nicht deklariert, ergibt sich aus geerbten Element-Margins | Messreihe Phase 5 | — |
  | Section padding-bottom ≥1280 px | 48 px | 48 px (Setting) | `assets/theme.css:202-205` | 0 ✓ |
  | Section padding-bottom <768 px | 48 px | 28,8 px (`min(4rem, 48×0.6)`) | `assets/theme.css:170` | −19,2 px |
  | Wrapper-Höhe Desktop | 452 px | ❌ Unbekannt | Messreihe Phase 5 | — |
  | Wrapper-Höhe Mobile | 802 px | ❌ Unbekannt | Messreihe Phase 5 | — |
  | Icon-Maß | 32×32 px | 32×32 px | `assets/theme.css:5335` (`.icon--extra-large`) | 0 ✓ |
  | Kachel-Border | 1 px Stone-20 | 1 px Stone-20 (deklariert, weil nicht erbbar) | `config/settings_data.json` (alle Schemes `border: rgba(0,0,0,0)`) | 0 ✓ |
  | Kachel-Radius | 0 | 0 | Nicht-Verwendung von `blocks-radius` | 0 ✓ |
  | Kachel-Shadow | keiner | keiner | Nicht-Verwendung von `.multicolumn-card-wrapper` | 0 ✓ |
  | Fokusring-Umfang | im Design nicht definiert | Kachel-umschließend, Theme-Token | `assets/theme.css:1122-1123` | ⚠️ kein Soll |

- **Schritte:**
  1. Sechs SVGs gemäß Vertrag normalisieren, als `assets/mdm-icon-hilfe-*.svg` ablegen
     (Originale in `assets-src/` bleiben als Herkunftsnachweis).
  2. `sections/mdm-help-topic-cards.liquid` anlegen: Wrapper, `<ul>/<li>`, Tag-Wechsel,
     Icon-Inlining, Schema mit Token-auswählenden Settings, Preset mit 6 Blocks.
  3. `assets/mdm-section-help-topic-cards.css` anlegen — nur die acht unter „Was deklariert
     wird" genannten Punkte, plus Kopfkommentar mit SVG-Vertrag und dem Hinweis, dass
     Typografie bewusst geerbt wird.
  4. Template um die Section erweitern, alle sechs `link`-Settings leer.
  5. Tablet-Band als bewusste Setzung dokumentieren (kein Figma-Frame; über `columns_tablet`
     ohne Code-Änderung korrigierbar).
  6. Validierung inklusive Direktiv-Grep fahren, „Verbindlich" abhaken, Deviation-Liste mit
     gemessenen Werten füllen, Review-Paar starten.

---

## 5. Phase 3: Section Münzlexikon (Reuse rich-text, ohne jeden Override)

- **Ziel:** H2 „Münzlexikon A–Z", Fließtext und Button „Zum Münzlexikon" — vollständig aus
  `rich-text` mit Theme-Typografie. Ohne gepflegte URL wird kein Button gerendert.

- **Dateien:** ÄNDERN `templates/page.hilfe.json`. **Sonst nichts** — keine neue Section, kein
  `mdm-`-Klon, kein CSS.

- **Template-Settings:** `container: fixed`, `color_scheme: scheme-1`,
  `use_color_scheme_in_container: false`, `content_alignment: left`, `content_spacing: tight`,
  `padding_top: 48`, `padding_bottom: 48`; Blocks: `heading` mit `heading_size: h2`, `text` mit
  `text_size: text-base` und `text_line_limit: none`, `button` mit
  `button_style: btn--secondary`, `button_icon: none`, `button_label: ""`, `button_link: ""`.

  `content_spacing: tight` ist der Theme-Token, der den Design-Abständen am nächsten kommt:
  `tight` = 20/12 px (`assets/theme.css:5219-5223`), `fitted` = 24/16 px (`:5214-5218`), Basis
  = 32/12 px (`:5154-5156`). ⚠️ Die Wahl `tight` statt `fitted` ist eine begründete Setzung —
  `fitted` läge beim H2→Text-Abstand exakt auf 16 px, beim Text→Button-Abstand aber 8 px daneben;
  `tight` verteilt die Abweichung symmetrisch (±4 px). Konrad kann im Editor umschalten.

- **Umsetzung von E-4 („ohne URL nicht rendern"):**
  ✅ Belegt: `sections/rich-text.liquid:79` rendert den Button-Block nur bei
  `block.settings.button_label != blank`. Das Template liefert Label **und** Link leer aus →
  kein Button im DOM, kein toter Link. Sobald die URL vorliegt, werden beide gemeinsam gesetzt.
  ⚠️ Restrisiko: setzt jemand im Editor nur ein Label ohne Link, erzeugt
  `snippets/button.liquid:46` (`!= nil` statt `!= blank`) ein `href=""`. Eigenschaft des
  FoxEcom-Originals; **Entscheidung E-6: keine Härtung** (kein `mdm-rich-text`-Klon).

- **Validierung:**
  - `shopify theme check` auf `templates/page.hilfe.json`; JSON-Parse.
  - DOM-Probe: kein `<a>` mit leerem `href` in der Section.
  - Editor-Probe: die drei Blocks sichtbar und editierbar.
  - **Direktiv-Probe:** kein CSS-Artefakt zu dieser Section im Repo.

- **Verbindlich (muss exakt stimmen):**
  - [ ] Section-Typ `rich-text`, Blocks in der Reihenfolge `heading` → `text` → `button`
  - [ ] `heading_size: h2`, Heading-Text „Münzlexikon A–Z"
  - [ ] Fließtext wörtlich gemäß Spec 3.3
  - [ ] `content_alignment: left`
  - [ ] `button_label` und `button_link` leer ⇒ kein Button im DOM
  - [ ] `button_style: btn--secondary` vorbelegt für den Moment, in dem die URL kommt
  - [ ] `sections/rich-text.liquid` unverändert (Diff leer)
  - [ ] Kein seitenlokales CSS für diese Section

- **Deviation-Liste Phase 3** (Ergebnis, kein Fehler).
  **Basis: Theme-Stand inkl. `assets/mdm-global-overrides.css` (E-11)**; daraus abgeleitete
  Werte sind ⚠️ Vermutung und in Phase 5 zu verifizieren.

  | Eigenschaft | Figma-Soll | Theme-Ist (geerbt) | Beleg | Delta |
  |---|---|---|---|---|
  | H2 font-size ≥1024 px | 32 px | **32 px** (`--font-h2-size` global auf 3,2 rem) | ⚠️ `assets/mdm-global-overrides.css:47` + `assets/theme.css:1042-1046` | **0 ✓** |
  | H2 font-size 768–1023 px | — | 22,4 px (`32 × 0.7`) | ⚠️ dito + `assets/theme.css:1008-1011` | ⚠️ kein Soll |
  | H2 font-size <768 px | 22 px | 26,88 px (`0.84 × 32`) | ⚠️ dito + `assets/theme.css:906-910` | +4,88 px |
  | H2 line-height ≥1024 px | 1,2 | 1,3125 (`1 + 0.3125/1`, Scale jetzt 1) | ⚠️ `assets/mdm-global-overrides.css:45` + `assets/theme.css:1045` | +0,11 |
  | H2 line-height <768 px | 1,2 | 1,201 (`1 + 0.201/1`) | ⚠️ dito + `assets/theme.css:909` | +0,001 ✓ |
  | H2 font-weight | 500 | 600 | `assets/theme.css:878`, `type_header_font: ebgaramond_n6` | +100 |
  | H2 Farbe | Prussian #002147 | **#002147** (globaler Heading-Override) | ⚠️ `assets/mdm-global-overrides.css:10-13` | **0 ✓** |
  | Fließtext font-size | 16 px | 16 px | `assets/theme.css:5675-5678` | 0 ✓ |
  | Fließtext line-height | 1,7 | 1,625 | `snippets/css-variables.liquid:19-20,269` | −0,075 |
  | Fließtext Farbe | Stone-100 #3e3a32 | **#3e3a32** (`--color-subtext` global) | ⚠️ `assets/mdm-global-overrides.css:20` | **0 ✓** |
  | Fließtext-Breite @1440 | 760 px | 1340 px (keine `max-width` in `rich-text`) | `sections/rich-text.liquid:6-10`, `assets/theme.css:159-162` | +580 px |
  | Gap H2 → Text ≥768 px | 16 px | 12 px (`--text-margin-top`, `tight`) | `assets/theme.css:5221` | −4 px |
  | Gap Text → Button ≥768 px | 16 px | 20 px (`--child-margin-top`, `tight`) | `assets/theme.css:5220` | +4 px |
  | Gap H2 → Text <768 px | 20 px | 12 px (`:has(.h2)`-Regel) | `assets/theme.css:5234-5235` | −8 px |
  | Gap Text → Button <768 px | 20 px | 12 px | `assets/theme.css:5230` | −8 px |
  | Button-Höhe | 48 px | 40 px (`--buttons-height`) | `snippets/css-variables.liquid:295`, `buttons_height: 40` | −8 px |
  | Button padding-x | 24 px | 32 px (`--buttons-padding`) | `assets/theme.css:2175` | +8 px |
  | Button-Radius | 0 | 0 | `snippets/css-variables.liquid:335` | 0 ✓ |
  | Button font-weight | 700 | 700 | `snippets/css-variables.liquid:293` | 0 ✓ |
  | Button font-size | 16 px | 16 px (`font-size: 100%`) | `assets/theme.css:2176` | 0 ✓ |
  | Button text-transform | keiner | **`none`** (global überschrieben) | ⚠️ `assets/mdm-global-overrides.css:37` | **0 ✓** |
  | Button-Hintergrund | White #ffffff | **#ffffff** | ⚠️ `assets/mdm-global-overrides.css:25` | **0 ✓** |
  | Button-Border | 1 px Prussian #002147 | 1 px **#002147** | ⚠️ `assets/mdm-global-overrides.css:27` | **0 ✓** |
  | Button-Textfarbe | Prussian #002147 | **#002147** | ⚠️ `assets/mdm-global-overrides.css:26` | **0 ✓** |
  | Button-Breite Desktop | intrinsisch ≈187 px | intrinsisch | `assets/theme.css:2178` | ≈ 0 ✓ |
  | Button-Breite <768 px | full-width 350 px | intrinsisch — **kein `btn--full*`-Utility im Theme** | Volltextsuche `assets/theme.css` → 0 Treffer | Breite |
  | Section padding-top ≥1280 px | 48 px | 48 px (Setting) | `assets/theme.css:202-205` | 0 ✓ |
  | Section padding-top <768 px | 48 px | 28,8 px (`min(4rem, 48×0.6)`) | `assets/theme.css:169` | −19,2 px |
  | Section padding-bottom <768 px | 56 px | 28,8 px | `assets/theme.css:170` | −27,2 px |
  | Section-Höhe Desktop | 268 px | ❌ Unbekannt | Messreihe Phase 5 | — |

  **Erledigt durch die Globalisierung:** Die in Revision 2/3 als auffälligste Abweichung der
  Seite markierten drei Button-Farbzeilen (hellgrau gefüllt, grauer Rahmen, schwarzer Text aus
  scheme-1) sind mit `assets/mdm-global-overrides.css:25-27` designkonform geworden — weißer
  Button, Prussian-Rahmen, Prussian-Text. Ebenso H2-Größe und -Farbe sowie die Textfarbe. Übrig
  bleiben an diesem Button nur noch Höhe (40 statt 48 px), Padding-x (32 statt 24 px) und die
  fehlende Mobile-Full-Width — `--buttons-height` und `--buttons-padding` sind von der
  Globalisierung nicht erfasst.

- **Schritte:**
  1. `rich-text`-Section mit den drei Blocks ins Template einhängen (Button mit leerem
     Label/Link).
  2. Validierung inklusive Direktiv-Probe fahren, „Verbindlich" abhaken, Deviation-Liste mit
     gemessenen Werten füllen, Review-Paar starten.

---

## 6. Phase 4: Section Newsletter — **BLOCKIERT, nicht implementieren**

> **Status: BLOCKIERT — wartet auf Designerin-Entscheidung (E-1).** Konrad klärt, ob die
> Newsletter-Section auf Mobile bewusst fehlt (Spec Abschnitt 0: im Mobile-Frame `4030:345`
> nachweislich nicht vorhanden ✅; die Absicht ist ⚠️ Vermutung). Diese Phase wird **nicht**
> umgesetzt, bis die Antwort vorliegt. Die Phasen 1–3, 5 und 6 sind ohne sie vollständig
> lauffähig und abnahmefähig; die Section wird später als vierter Eintrag in `sections` und
> `order` ergänzt, ohne die vorhandenen zu berühren.

**Vorarbeit (damit die Phase ohne neue Analyse startklar ist):**

- **Wiederverwendung steht fest:** `sections/newsletter.liquid` mit `type: "newsletter"`
  einhängen. Vollständig gelesen; die benötigten Bausteine sind vorhanden:
  `heading` + `heading_size` (`:111-128,277-312`), `description` (`:129-138,313-318`), Formular
  über `snippets/newsletter-form.liquid` (`:147-151`), `newsletter_term` als
  Datenschutz-/Abmeldehinweis direkt unter dem Formular (`:152-156,413-418`), `alignment: left`,
  `container: fixed`, `layout: vertical`, `width_settings: custom`, `form_width` 450–800 px
  (`:404-412`), `padding_top`/`padding_bottom` (`:567-586`).
- **Label-/WCAG-Anforderung ist bereits erfüllt:** `snippets/newsletter-form.liquid:14-16`
  rendert `<label class="form-label visually-hidden" for="NewsletterForm-…">` mit dem Key
  `newsletter.label` („E-Mail" in `locales/de.json`). Ein Label ist im DOM vorhanden; offen ist
  nur, ob es **sichtbar** sein soll (O-8).
- **Double-Opt-in (§ 7 UWG):** ❌ Unbekannt aus dem Theme heraus. Das Formular ist ein
  `{% form 'customer' %}` mit `contact[tags]=newsletter`
  (`snippets/newsletter-form.liquid:10-11`) — die Bestätigungsmail ist eine Admin-/Marketing-Tool-
  Einstellung, kein Theme-Task. Vor Livegang von Konrad zu verifizieren (O-12).
- **Textabweichungen (globale Locale-Keys, nicht stillschweigend ändern):** Design-Placeholder
  „E-Mail-Adresse" vs. `newsletter.placeholder` = „Geben Sie Ihre E-Mail-Adresse ein";
  Design-Button „Anmelden" vs. `newsletter.button_label` = „Melden Sie sich an" (beide
  `locales/de.json`). Auch genutzt von `sections/footer.liquid:217`, `sections/popup.liquid:143`,
  `sections/main-password.liquid:10` → globaler Blast-Radius. Entscheidung O-9.
- **Der einzige offene Struktur-Punkt dieser Phase:** Der Stone-5-Hintergrund
  (`#f6f3ee`) ist **nicht erbbar** — kein Color-Scheme trifft ihn (nächste Werte `#ebe5de` in
  `scheme-info`, `#f5f5f5` in `scheme-11`). Zwei Wege, beide brauchen Konrads Freigabe:
  Option A ein neues Color-Scheme in `config/settings_data.json` (global, im Editor überall
  wählbar), Option B eine seitenlokale CSS-Datei plus Layout-Hook (die in dieser Revision
  bewusst entfallen sind). Entscheidung fällt **mit** dieser Phase.
- **Verbindlich (vorbereitet):** Section-Typ `newsletter` als letzte Section; `heading`
  „MDM-Newsletter" mit `heading_size: h2`; Beschreibungstext und `newsletter_term` wörtlich
  gemäß Spec 3.4; `alignment: left`; `width_settings: custom`, `form_width: 560`
  (= 420 + 12 + 129, Schritt 5 des Ranges); `padding_top: 48`, `padding_bottom: 72`;
  Label im DOM mit `for`/`id` verknüpft.
- **Deviation-Liste (vorbereitet, Desktop-only, Node 4030:789):** Hintergrund Stone-5 (nicht
  erbbar, s. o.); Input-Höhe Soll 48 px vs. geerbt 40 px (`.form-control` `line-height` aus
  `--buttons-height`, `assets/theme.css:2540-2558`); Input padding-x Soll 16 px vs. geerbt 20 px
  (`:2549`); Input-Border Soll 1 px Stone-20 vs. geerbt `--color-border` = transparent;
  Formular-Gap Soll 12 px vs. geerbt 8 px (`assets/theme.css:4214-4218`); Button-Maße wie in
  Phase 3; Hinweistext Soll 14 px/Stone-80 vs. geerbt 16 px/#000000; Textbreite Soll 760 px vs.
  geerbte Containerbreite. Mobile: entfällt oder wird ergänzt — abhängig von E-1.
- ⚠️ Der Hinweistext nennt die Datenschutzerklärung, enthält im Design aber **keinen Link**
  (reiner Fließtext) — rechtlich zu prüfen (O-10). `newsletter_term` ist Richtext, ein Link ist
  ohne Code-Änderung ergänzbar.

---

## 7. Phase 5: Messreihe und Gesamtbild

- **Ziel:** Die geerbten Ist-Werte werden an fünf Viewportbreiten **gemessen** und in die
  Deviation-Listen eingetragen. Ziel ist nicht Maßtreue, sondern eine belastbare
  Entscheidungsgrundlage für den Designerinnen-Termin.

- **Zusatzauftrag aus E-11:** Alle mit ⚠️ markierten Ist-Werte stammen aus dem zum Planungszeitpunkt
  **uncommitteten** `assets/mdm-global-overrides.css`. Sie sind hier gegen den dann gültigen,
  committeten Stand zu **verifizieren** und auf ✅ Belegt zu heben — oder zu korrigieren, falls die
  Globalisierung anders landet. Besonders zu prüfen: H1 40/28/33,6 px, H2 32/22,4/26,88 px,
  Heading-Farbe Prussian, `--color-foreground`/`--color-subtext` = Stone-100, die drei
  `btn--secondary`-Farben und `--buttons-transform: none`. Ebenso visuell zu bestätigen: die
  festen 12 px Mobile-Padding der Breadcrumb-Section (`assets/theme.css:7618-7621`).

- **Dateien:** in der Regel **keine**. Nur wenn die Messreihe einen echten Struktur-Fehler
  zeigt (umbrechendes Grid, horizontale Scrollbar, überlappende Elemente, unlesbarer Kontrast),
  wird `assets/mdm-section-help-topic-cards.css` strukturell nachgezogen — nicht, um Figma-Maße
  zu treffen.

- **Breakpoint-Bänder (bewusste Setzung, nur zwei Figma-Frames vorhanden):**
  | Band | Container (geerbt) | Kachel-Grid (deklariert) | Kachel-Layout (deklariert) | Typo |
  |---|---|---|---|---|
  | ≥1536 px | `max(13,5rem, 50vw − 850px)` | 3 Spalten, Gap 24 px | Spalte, Icon oben | geerbt |
  | 1280–1535 px | `--page-padding: 5rem` | 3 Spalten, Gap 24 px | Spalte, Icon oben | geerbt |
  | 1024–1279 px | `--page-padding: 5rem` (ab 1200) / `1,6rem` (1024–1199) | 3 Spalten, Gap 24 px | Spalte, Icon oben | geerbt |
  | 768–1023 px | `--page-padding: 1,6rem` | 2 Spalten, Gap 24 px | Spalte, Icon oben | geerbt ⚠️ kein Frame |
  | <768 px | `--page-padding: 1,6rem` | 1 Spalte, Gap 14 px | Zeile, Icon links | geerbt |

- **Validierung:**
  - `shopify theme check --fail-level error` auf alle im Ticket berührten Dateien.
  - Dev-MCP `validate_theme`.
  - Messung bei 1440, 1280, 1024, 768 und 390 px gegen
    `assets-src/reference-4030-734.png` und `assets-src/reference-4030-345.png` — als
    **Delta-Erhebung**, nicht als Pass/Fail.
  - **Direktiv-Gesamtprobe:** `git diff --stat` zeigt **keine einzige geänderte bestehende
    `.liquid`-Datei** und keine Änderung an `layout/`, `config/`, `assets/theme.css` oder
    bestehenden `assets/mdm-*.css`. Die einzigen geänderten Bestandsdateien sind
    `locales/en.default.schema.json` und `locales/de.schema.json`, und dort ausschließlich
    additiv unter `sections.mdm-help-topic-cards.*`. Kein `assets/mdm-page-hilfe.css` im Repo.

- **Verbindlich (muss exakt stimmen):**
  - [ ] Sektionsreihenfolge Kopfbereich → Themenkacheln → Münzlexikon
  - [ ] Keine horizontale Scrollbar bei 390, 768, 1024, 1280, 1440 px
  - [ ] Kachel-Grid bricht in keinem Band ungewollt um (3/2/1 wie deklariert)
  - [ ] Kein Text-Overflow, keine Überlappung, kein abgeschnittenes Icon
  - [ ] Kein Swipe-/Slider-Verhalten am Kachel-Grid
  - [ ] Tastaturnavigation vollständig, Fokusring auf allen interaktiven Elementen sichtbar
  - [ ] Kein Element mit `href=""` oder `href="#"` auf der Seite
  - [ ] Kontrast aller geerbten Textfarben gegen Weiß ≥ 4,5:1 (bei #000000 unkritisch)

- **Deviation-Liste Phase 5 — Gesamtmaße** (in der Messreihe zu füllen):

  | Eigenschaft | Figma-Soll | Theme-Ist | Delta |
  |---|---|---|---|
  | Seitenhöhe Desktop @1440 (ohne Newsletter) | 929 px (1265 − 336) | ❌ zu messen | — |
  | Seitenhöhe Mobile @390 | 1254 px | ❌ zu messen | — |
  | Content-Breite @1440 | 1200 px | 1340 px (`assets/theme.css:198-201`) | +140 px |
  | Content-Breite @390 | 350 px | 358 px (`assets/theme.css:173-175`) | +8 px |
  | Farbpalette Prussian/Stone-100/Stone-80 im Text | wie Spec 2 | #000000 überall außer Breadcrumbs und H1 | Farbe |

- **Schritte:**
  1. Tablet-Band dokumentieren (Setzung ohne Frame).
  2. Messreihe an fünf Breiten, Ist-Werte in die Deviation-Listen der Phasen 1–3 eintragen und
     die ❌-Unbekannt-Zeilen auflösen.
  3. Struktur-Fehler (nicht Maßabweichungen) beheben.
  4. Review-Paar starten — mit dem ausdrücklichen Hinweis, dass die Deviation-Listen kein
     Prüfmaßstab sind.

---

## 8. Phase 6: Übersetzungen, Mapping-Update, Übergabe

- **Ziel:** Alle Schema-Labels paarig lokalisiert, `figma-mapping.md` aktualisiert, Übergabe an
  Konrad.

- **Dateien:**
  - ÄNDERN `locales/en.default.schema.json`, `locales/de.schema.json` — Konsolidierung der in
    Phase 2 ergänzten Keys (alle unter `sections.mdm-help-topic-cards.*`),
    Vollständigkeitsprüfung. Rein additiv, keine bestehende Übersetzung wird berührt (E-8).
  - VORSCHLAG (nicht selbst editieren) `.claude/skills/mdm-template/figma-mapping.md` — s. 10.
  - Keine Frontend-Locale-Keys nötig: `locales/en.default.json` / `locales/de.json` enthalten
    heute **keine** `sections.mdm-*`-Keys (geprüft); alle Texte kommen aus Settings bzw.
    `page.title`. Käme doch ein fester String hinzu, wird er in **beiden** Frontend-Locales
    angelegt.

- **Validierung:** `shopify theme check` auf die Locale-Dateien; Diff-Prüfung auf identische
  ergänzte Key-Menge (MatchingTranslations); Theme-Editor zeigt deutsche Labels.

- **Übergabe-Punkte an Konrad (nicht von Claude ausführbar):**
  1. **Branch-Lage vor Phase 2 in Ordnung bringen — Voraussetzung für E-11.** `feat/help-hub-page`
     existiert, war während Phase 1 aber nicht ausgecheckt; gearbeitet wurde faktisch im Baum von
     `feat/retoure-global-styles` (`git branch --show-current`). `templates/page.hilfe.json` ist
     untracked und damit branch-agnostisch — die Arbeit ist nicht verloren. Konrad committet
     zuerst die Globalisierung, wechselt dann auf `feat/help-hub-page`. **Dieser Branch muss vor
     Phase 2 auf den Stand des Retoure-Branches gebracht werden (Merge oder Rebase)** — sonst
     lädt die Hilfe-Seite `assets/mdm-global-overrides.css` nicht, misst gegen ein Theme ohne die
     Overrides, und E-11 wäre nicht erfüllbar.
  2. **Admin-Umschaltung:** Seite **Handle `hilfe-und-antworten-zu-haufigen-fragen`, Admin-ID
     `698882949501`** — Vorlage `page.hilfe` zuweisen, bewusst und erst nach Abnahme. Das alte
     Template bleibt unangetastet und ist der Rollback-Pfad.
  3. **Der eine redaktionelle Nacharbeitspunkt:** Alle sechs Kachel-Ziel-Links und der
     Münzlexikon-Link werden mit leerem Default ausgeliefert — **inklusive der Retoure-Kachel**,
     weil der Retoure-Handle weiter unbekannt ist (O-3). Konrad pflegt sie im Theme-Editor nach;
     beim Münzlexikon Label **und** URL gemeinsam setzen.
  4. **Deviation-Listen mit in den Designerinnen-Termin nehmen** — sie sind die
     Entscheidungsgrundlage für O-14 (Globalisierung).
  5. **Double-Opt-in prüfen** (erst relevant, wenn Phase 4 entblockt wird).
  6. **Kein Push aufs Live-Theme** — Ablage als unveröffentlichtes Theme.

---

## 9. Übersetzungs-Keys

**`locales/en.default.schema.json` / `locales/de.schema.json`:**

| Key | en.default | de |
|---|---|---|
| `sections.mdm-help-topic-cards.name` | Help topic cards | Hilfe-Themenkacheln |
| `sections.mdm-help-topic-cards.settings.columns_desktop.label` | Columns on desktop | Spalten auf Desktop |
| `sections.mdm-help-topic-cards.settings.columns_tablet.label` | Columns on tablet | Spalten auf Tablet |
| `sections.mdm-help-topic-cards.settings.title_font.label` | Title font | Titel-Schrift |
| `sections.mdm-help-topic-cards.settings.title_size.label` | Title size | Titel-Größe |
| `sections.mdm-help-topic-cards.settings.title_size.info` | Uses the theme's text sizes. | Nutzt die Textgrößen des Themes. |
| `sections.mdm-help-topic-cards.settings.text_size.label` | Description size | Größe der Beschreibung |
| `sections.mdm-help-topic-cards.settings.icon_color.label` | Icon color | Symbolfarbe |
| `sections.mdm-help-topic-cards.settings.icon_color.info` | Empty = inherits the text color. | Leer = erbt die Textfarbe. |
| `sections.mdm-help-topic-cards.blocks.topic_card.name` | Topic card | Themenkachel |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.icon.label` | Icon | Symbol |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.icon.options__none.label` | None | Kein Symbol |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.icon.options__bestellung.label` | Order | Bestellung |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.icon.options__bezahlung.label` | Payment | Bezahlung |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.icon.options__versand_lieferung.label` | Shipping | Versand und Lieferung |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.icon.options__retoure_reklamation.label` | Returns | Retoure und Reklamation |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.icon.options__kundendaten.label` | Customer data | Kundendaten |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.icon.options__kollektion.label` | Collecting | Kollektion und Sammeln |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.title.label` | Title | Titel |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.title_mobile.label` | Title on mobile | Titel auf Mobile |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.title_mobile.info` | Optional short form. Empty = same as title. | Optionale Kurzform. Leer = wie Titel. |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.text.label` | Description | Beschreibung |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.link.label` | Link | Link |
| `sections.mdm-help-topic-cards.blocks.topic_card.settings.link.info` | Empty = card is not clickable. | Leer = Kachel ist nicht klickbar. |

Für `container`, `color_scheme`, `heading`, `padding_top`, `padding_bottom` werden die
vorhandenen generischen `t:general.*`-Keys genutzt — keine neuen Keys.

**Alle** neuen Keys liegen unter dem einen neuen Namensraum
`sections.mdm-help-topic-cards.*`. Es wird keine bestehende Übersetzung geändert oder gelöscht;
die Ergänzung ist rein additiv (E-8, Projektkonvention aus CLAUDE.md gewahrt).

---

## 10. Figma-Mapping-Vorschläge (verifiziert, zur Ergänzung in `figma-mapping.md`)

| Figma-Layer/Muster | Theme-Gegenstück | Status / Beleg |
|---|---|---|
| `breadcrumbs (nav)` (2 Ebenen) | `sections/mdm-breadcrumbs.liquid`, `parent_*` leer. **Das Endsegment ist im `page`-Zweig fest `page.title`** — ein abweichender Breadcrumb-Text ist ohne Änderung dieser shopweit genutzten Section nicht möglich | ✅ Verifiziert (MDM-HILFE-01): `sections/mdm-breadcrumbs.liquid:84-92` |
| `Themenkachel · <Name>` / Kachel-Grid | `sections/mdm-help-topic-cards.liquid` (neu) — Stretched-Link, Icons als `assets/mdm-icon-hilfe-*.svg` via `inline_asset_content`, Typografie geerbt über Token-Settings | ✅ Verifiziert (MDM-HILFE-01) |
| ❌ verworfen für Kachel-Grid | `sections/mdm-multicolumn-icon.liquid` — kein Karten-Link (`:84-152`), Icon-Auswahl fest (`:786-922`), `image_position` nur section-weit (`:90`), Gap-Tokens 30/12 px statt 24/14 px (`assets/theme.css:357-383`) | ❌ verworfen: vier Struktur-Defizite, nicht per Settings lösbar |
| ❌ verworfen für Kachel-Grid | `sections/mdm-product-related-categories.liquid` — durch `{% if product.collections.size > 0 %}` auf Produktseiten begrenzt (`:1`) | ❌ verworfen: nicht auf Page-Templates einsetzbar |
| Section mit H2 + Fließtext + Button | `sections/rich-text.liquid` (Original, Blocks `heading`/`text`/`button`) | ✅ Verifiziert (MDM-HILFE-01): `:25-90`, Preset `:642-655` |
| Newsletter-Formular-Section | `sections/newsletter.liquid` + `snippets/newsletter-form.liquid`; Label bereits `visually-hidden` im DOM | ✅ Verifiziert (MDM-HILFE-01): `sections/newsletter.liquid:147-156`, `snippets/newsletter-form.liquid:14-16` |
| Eigene SVG-Icons | `assets/<name>.svg` + `{{ '<name>.svg' \| inline_asset_content }}` | ✅ Verifiziert: `snippets/mdm-button.liquid:65`, `sections/announcement-bar.liquid:64,69,71` |
| Icon 32×32 px | Theme-Klassen `icon icon--extra-large` (`--icon-size: 3,2rem`) — nicht hart deklarieren | ✅ Verifiziert (MDM-HILFE-01): `assets/theme.css:5335` |
| Sichtbarer Rahmen an Karten/Boxen | **Kein erbbarer Wert** — `--color-border` ist in ALLEN 15 Color-Schemes `rgba(0,0,0,0)`. Rahmen müssen als section-scoped MDM-Token deklariert werden | ✅ Verifiziert (MDM-HILFE-01): `config/settings_data.json` (alle Schemes), `snippets/css-variables.liquid:200-201` |
| MDM-Token-Muster für section-lokale Farben | `--mdm-color-border`, `--mdm-color-soft-bg`, `--mdm-color-title` … am Section-Root | ✅ Verifiziert: `assets/mdm-section-main-product.css:58-69` |
| `Stone-20` (#d6cab3) | Kein Hyper-Token, kein Scheme; etablierter MDM-Hardcode als Rahmenfarbe | ✅ Verifiziert (MDM-HILFE-01): `assets/mdm-section-breadcrumbs.css:2`, `assets/mdm-collection.css:945`, `assets/mdm-section-featured-collection.css:126` |
| `Stone-5` (#f6f3ee) | Kein Hyper-Token, kein Scheme (nächste Werte `#ebe5de`, `#f5f5f5`); MDM-Hardcode als Flächenfarbe | ✅ Verifiziert (MDM-HILFE-01): `assets/mdm-collection.css:417`, `assets/mdm-section-featured-collection.css:127` |
| Heading-Skala | `.h1`/`.h2` sind über die Breakpoints **nicht monoton**: <768 px `0,84 × Basis`, 768–1023 px `0,7 × Basis`, ≥1024 px Basis — Mobile-Heading größer als Tablet-Heading. Bleibt auch nach der Globalisierung so, weil `--font-heading-mobile-scale` in Liquid aus den Settings gebildet wird und von CSS-Overrides nicht erreichbar ist | ✅ Verifiziert (MDM-HILFE-01): `assets/theme.css:901-910,1004-1011,1038-1046`; `snippets/css-variables.liquid:277` |
| Button-Höhe/-Padding | `--buttons-height` = 40 px aus `settings.buttons_height`, `--buttons-padding` = 32 px; `--buttons-radius` hart 0 | ✅ Verifiziert: `snippets/css-variables.liquid:295,335`, `assets/theme.css:2175` |
| `btn--secondary` in scheme-1 | Im rohen Hyper: Hintergrund #eeecec, Border #eeecec, Text #000000 — nicht Weiß/Prussian. **Seit `assets/mdm-global-overrides.css:25-27` auf Weiß/Prussian/Prussian korrigiert** | ✅ Verifiziert (MDM-HILFE-01): `assets/theme.css:2268-2272`, `config/settings_data.json` scheme-1; Override ⚠️ `assets/mdm-global-overrides.css:25-27` |
| Full-Width-Button | **Kein `btn--full*`-Utility im Theme** — Full-Width ist nicht erbbar | ✅ Verifiziert (MDM-HILFE-01): Volltextsuche `assets/theme.css` |
| Container `fixed` | **Keine `max-width`** — Viewport minus `--page-padding` (5 rem ab 1200 px). `page-width--small` (1200 px) trifft das MDM-Design, ist aber in den mdm-Schemas nicht als Option angeboten | ✅ Verifiziert (MDM-HILFE-01): `assets/theme.css:159-162,188-201`; Optionen in `sections/mdm-breadcrumbs.liquid:168-186`, `sections/mdm-page-title.liquid:18-36`, `sections/rich-text.liquid:118-131` |
| Mobile-Sektionspadding | `.section--padding` skaliert mobil `min(4rem, v×0.6)`; `--section-padding-*-mobile` würde es überschreiben (in diesem Ticket bewusst nicht genutzt) | ✅ Verifiziert: `assets/theme.css:168-171` |
| Globaler Fokusring | `*:focus-visible { outline: 0.2rem solid rgb(var(--color-keyboard-focus)) }` — immer erben, nie neu bauen | ✅ Verifiziert (MDM-HILFE-01): `assets/theme.css:1122-1123` |
| Theme-Card-Padding-Konvention | `2,4rem 2rem` Desktop / `2,4rem 1,6rem` mobil — Referenz für neue Karten-Komponenten | ✅ Verifiziert (MDM-HILFE-01): `assets/mdm-component-multicolumn-card.css:1-10` |
| Leeres URL-Setting an Hyper-Buttons | `snippets/button.liquid:46` / `snippets/mdm-button.liquid:46` prüfen `!= nil`, nicht `!= blank` ⇒ leeres Setting erzeugt `href=""` | ✅ Verifiziert (MDM-HILFE-01) — eigene Sections müssen selbst auf `!= blank` prüfen |
| „Nexvo" in Annotationen | Demo-Store-Markenname der Hyper-Demo, **kein** Fremd-Theme | ⚠️ Vermutung, gut gestützt: 13 Demo-Dateien; `config/settings_schema.json` (`theme_name: Hyper`) |

---

## 11. Risiken

1. **Sichtbare Design-Abweichung ist beabsichtigt.** Unter „maximal vererben" weichen
   Container-Breite (+140 px), H1 (+8/+12,3 px), H2 (+6,4/+10,3 px), Kachel-Typo (−3/−1 px),
   Textfarben (#000000 statt Stone-100/Prussian) und die `btn--secondary`-Farben sichtbar von
   Figma ab. Von Konrad ausdrücklich akzeptiert und in den Deviation-Listen dokumentiert. ✅
2. **Der theme-reviewer muss die Direktive kennen.** Ohne den Hinweis meldet er jede
   Deviation-Zeile als Finding. Beim Start des Review-Paars ist explizit mitzugeben: geerbte
   Werte sind kein Prüfmaßstab, geprüft wird ausschließlich die „Verbindlich"-Liste plus die
   Direktiv-Probe (kein Typo-/Padding-CSS im Repo). ⚠️
3. **Kachel-Höhe ist inhaltsgetrieben.** Ohne `min-height` können ungleich lange
   Beschreibungstexte unterschiedlich hohe Kacheln erzeugen. Das CSS-Grid gleicht Zeilen aus,
   ein Rest-Effekt bleiber möglich. In der Messreihe zu prüfen; ein `min-height` wäre eine neue
   erfundene Zahl und wird bewusst nicht gesetzt. ⚠️
4. **Innen-Gap der Kachel ist nicht deklariert** und ergibt sich aus geerbten Element-Margins.
   Sollte die Messreihe null Abstand zeigen, ist der Gap ein struktureller Mangel und wird als
   Struktur (nicht als Figma-Maß) nachgezogen. ⚠️
5. **Kein Tablet-Frame.** 2 Spalten zwischen 768 und 1023 px sind eine Setzung; über
   `columns_tablet` ohne Code-Änderung korrigierbar. ⚠️
6. **Icons sind Platzhalter.** Austausch ist per SVG-Vertrag als Dateitausch vorbereitet; folgt
   ein finales Icon dem Vertrag nicht, ist eine Nachbearbeitung nötig. ⚠️
7. **Stretched-Link blockiert Textauswahl** in der Kachel (bekannte Eigenschaft). Bewusste
   Abwägung zugunsten kurzer Screenreader-Linknamen. ⚠️
8. **Newsletter-Locale-Keys sind global.** Eine Anpassung würde Footer, Popup und Passwortseite
   mitverändern → erst nach O-9. ✅ Belegt.
9. **Breadcrumb-Text weicht sichtbar ab.** Das Endsegment zeigt „Hilfe und Antworten zu häufigen
   Fragen" statt „HILFE & SERVICE" — bei 10 px Schriftgröße und uppercase ein auffällig langer
   Pfad. Von Konrad akzeptiert (E-7); Auflösung über O-22. ⚠️
10. **Aufgelöst, kein Risiko mehr:** „Design gegen ein fremdes Theme (Nexvo) entworfen" (s. 1.1).
11. **Entfallen:** das Risiko „Blast-Radius Breadcrumbs" aus Revision 1/2 existiert nicht mehr,
    weil die Section nicht angefasst wird.
12. **Deviation-Basis ruht auf uncommittetem Fremdcode.** Alle ⚠️-Ist-Werte stammen aus
    `assets/mdm-global-overrides.css`, das zum Planungszeitpunkt untracked ist. Ändert sich die
    Globalisierung bis zum Commit, verschieben sich die Deltas — insbesondere H1/H2-Größen und
    die vier Button-/Textfarb-Zeilen, die derzeit auf Delta 0 stehen. Verifikation ist als
    Zusatzauftrag in Phase 5 verankert (E-11). ⚠️
13. **Branch-Falle.** Wird `feat/help-hub-page` ohne den Retoure-Stand ausgecheckt, lädt die
    Hilfe-Seite die Override-Datei nicht und rendert mit den alten Hyper-Werten (H1 48 px,
    schwarze Texte, grauer Sekundär-Button). Das sähe wie ein Umsetzungsfehler aus, wäre aber
    nur ein fehlender Merge. Als Übergabe-Punkt 1 in Phase 6 verankert. ⚠️

---

## 12. Offene Punkte

### 12.1 Von Konrad entschieden (24. August 2026)

| # | Entscheidung |
|---|---|
| E-0 | **Maximal vererben** — Theme-Wert gewinnt, deklariert wird nur strukturell Neues. Kehrt den bisherigen Scoping-Default um. Abweichungen werden dokumentiert, nicht korrigiert. |
| E-1 | Newsletter-Section zurückgestellt → Phase 4 BLOCKIERT; Template ohne sie abnahmefähig |
| E-2 | Template-Suffix `hilfe`; Zielseite Handle `hilfe-und-antworten-zu-haufigen-fragen`, Admin-ID `698882949501`, bleibt unangetastet; Umschaltung durch Konrad |
| E-3 | Platzhalter-Icons werden eingebaut; späterer Austausch muss reiner Dateitausch sein → Assets + `inline_asset_content` + SVG-Vertrag |
| E-4 | Ziel-Links als Settings mit leerem Default; ohne URL kein `<a>`, kein `href="#"` |
| E-5 | O-11 wie empfohlen: eigenes Setting `title_mobile`, ein DOM-Textknoten |
| E-6 | O-7 wie empfohlen: keine Härtung, `sections/rich-text.liquid` im Original wiederverwenden |
| E-7 | **Branch-Abgrenzung:** nur die Abschnitte der Hilfe-Seite bearbeiten ⇒ `sections/mdm-breadcrumbs.liquid` bleibt unangetastet, `current_label` entfällt ersatzlos, die Breadcrumb-Textabweichung wird akzeptiert (Folgeticket-Option O-22) |
| E-8 | Locale-Schema-Keys bleiben wie geplant — rein additiv unter `sections.mdm-help-topic-cards.*` in `en.default.schema.json` und `de.schema.json`; keine bestehende Übersetzung wird berührt |
| E-9 | O-19: `content_spacing: tight` für die Münzlexikon-Section (im Editor umschaltbar) |
| E-10 | O-20: `columns_desktop` / `columns_tablet` bleiben Settings, nicht fest verdrahtet |
| E-11 | **Deviation-Basis ist der Theme-Stand NACH der Globalisierung** (`assets/mdm-global-overrides.css`, global geladen über `layout/mdm-theme.liquid:64`), nicht Commit `3d97a3d`. Begründung: das ist die Realität im Designerinnen-Termin. Vorbehalt: derzeit uncommitteter Fremdcode ⇒ ⚠️ Vermutung, Verifikation in Phase 5. Voraussetzung: `feat/help-hub-page` muss vor Phase 2 den Retoure-Stand enthalten. |

### 12.2 Nicht blockierend, aber vor der Abnahme zu klären

| # | Frage | Empfehlung | Blockierend? |
|---|---|---|---|
| O-1 | Münzlexikon-URL | Leer ausliefern, Konrad pflegt Label + Link gemeinsam nach | Nein |
| O-2 | Ziel-Slugs der 5 Kacheln (Bestellung, Bezahlung, Versand & Lieferung, Kundendaten, Kollektion & Sammeln) | Leer ausliefern, nicht-klickbar, redaktionell nachpflegen | Nein |
| O-3 | **Retoure-Handle weiter unbekannt** | Auch die Retoure-Kachel mit leerem Default ausliefern. **Das ist der eine redaktionelle Nacharbeitspunkt nach der Umsetzung** (Phase 6, Übergabe-Punkt 2) | Nein |

### 12.3 Blockierend nur für Phase 4 (Newsletter)

| # | Frage | Status |
|---|---|---|
| O-4 | Fehlt die Newsletter-Section auf Mobile bewusst oder soll sie ergänzt werden? | ❌ Unbekannt — Konrad klärt mit der Designerin. **Blockiert Phase 4.** |
| O-8 | E-Mail-Feld: `visually-hidden`-Label (Design-Parität, bereits vorhanden) oder sichtbares Label (Annotation-Wortlaut)? | ⚠️ Empfehlung: `visually-hidden` beibehalten |
| O-9 | `newsletter.placeholder` / `newsletter.button_label` global ändern (wirkt auf Footer, Popup, Passwortseite) oder mdm-Kopie mit eigenen Settings? | ⚠️ Empfehlung: mdm-Weg (`sections/mdm-newsletter.liquid` + optionale Settings, leer ⇒ Locale-Fallback) — namensraumkonform, ohne Blast-Radius |
| O-10 | Hinweistext ohne Link auf die Datenschutzerklärung — rechtlich ausreichend? | ❌ Unbekannt (kein Theme-Thema); `newsletter_term` ist Richtext, Link ohne Code-Änderung ergänzbar |
| O-12 | Double-Opt-in (§ 7 UWG) im Admin/Marketing-Tool aktiv? | ❌ Unbekannt — Store-Admin-Prüfung durch Konrad vor Livegang |
| O-21 | Stone-5-Hintergrund: neues Color-Scheme in `config/settings_data.json` (global) oder seitenlokale CSS-Datei plus Layout-Hook (in dieser Revision entfallen)? | ⚠️ Entscheidung fällt **mit** Phase 4, nicht vorher |

### 12.4 Reine Folgeaufgaben

| # | Punkt |
|---|---|
| O-5 | Austausch der 6 Platzhalter-Icons. **Vorgehen:** zuerst prüfen, ob `snippets/mdm-icons.liquid` (31 Phosphor-Icons) oder die vorhandenen `snippets/mdm-icon-*.liquid` ein passendes Motiv liefern — das ist die wahrscheinliche Bedeutung von „Nexvo-Icon-Set" (s. 1.1). Erst danach neue SVGs anfordern. Austausch = Dateitausch in `assets/`. |
| O-6 | Hover-Zustände sind im Design nicht definiert. In diesem Ticket wird **kein** Hover-Effekt deklariert (Direktive); der Fokusring kommt aus dem Theme. Designerin-Abstimmung ist Folgeaufgabe. |
| O-13 | Fehler-/Erfolgszustände des Newsletter-Formulars sind im Design nicht spezifiziert; Hyper liefert sie über `basic-modal` (`snippets/newsletter-form.liquid:50-91`). |
| O-14 | **Globalisierungs-Runde** — **teilweise erledigt** durch `assets/mdm-global-overrides.css` (E-11): `btn--secondary`-Farben, `--color-foreground`/`--color-subtext`, Heading-Farbe, `--buttons-transform` und die Heading-Skala sind gesetzt. **Offen bleiben:** `--color-border` (Stone-20 statt transparent), `buttons_height` 40 → 48, `buttons_padding` 32 → 24, Container `page-width--small` als Schema-Option, `--font-heading-mobile-scale` (erzeugt weiter die Nicht-Monotonie, s. 1.4), `--font-heading-weight` 600 → 500 (Medium-Schnitt fehlt im Theme), `body_line_height` 1,625 → 1,7, Breadcrumb-Basisgrößen (10 px Desktop / 14 px Mobile, Item-Gap 8 px), das feste Mobile-`padding-block` der Breadcrumb-Section, ein `btn--full`-Utility. Grundlage sind die Deviation-Listen dieses Plans. Eigenes Ticket. |
| O-23 | **`assets/mdm-section-breadcrumbs.css` ist vollständig wirkungslos.** Die Datei selektiert durchgängig `.mdm-breadcrumbs`, die Section rendert aber `mdm-breadcrumbs-{{ section.id }}` (`sections/mdm-breadcrumbs.liquid:75`) — kein Match, einschließlich des dort definierten `border-bottom: #D6CAB3`. Bestandsfehler, in diesem Branch bewusst nicht angefasst. Eigenes Ticket: entweder Selektoren angleichen oder die Datei entfernen (vorher prüfen, ob eine andere Section die Klasse doch setzt). |
| O-24 | **theme-check-Baseline liegt bei 13 Errors, nicht bei 9.** Die vier zusätzlichen sind committet und stammen aus MDM-RETOURE-01: `sections.mdm-breadcrumbs.settings.show_divider.label` fehlt in `locales/es.schema.json`, `fr.schema.json`, `it.schema.json`, `vi.schema.json` — nur `en.default` und `de` wurden nachgezogen (verifiziert per Key-Zählung: en.default/de = 3 Treffer, es/fr/it/vi = 2). Nachzuziehen sind die vier Kataloge **und** die Baseline-Angabe in `CLAUDE.md`. Eigenes Ticket. |
| O-15 | `min-height`-Diskrepanz der Mobile-Kachel (88 vs. 114 px) — gegenstandslos, da kein `min-height` gesetzt wird. |
| O-16 | Herkunft von „VARIANTE FINAL" — nicht rekonstruierbar, ohne Auswirkung. |
| O-17 | `templates/page.faq.json` enthält weiterhin englischen Hyper-Demo-Content — eigenes Ticket. |
| O-22 | **Breadcrumb-Endsegment „HILFE & SERVICE".** Nur nach dem Designerinnen-Termin: entweder der Design-Text wird an `page.title` angeglichen (kostenlos, Empfehlung) oder es entsteht ein eigenes Ticket für ein `current_label`-Setting an `sections/mdm-breadcrumbs.liquid` mit bewusst akzeptiertem shopweitem Blast-Radius (6 Templates). Details im Kasten unter der Deviation-Liste von Phase 1. |
| O-18 | `page.hilfe.json` und `page.retoure.json` verlinken einander. Nach der Admin-Umschaltung prüfen, dass `templates/page.retoure.json:12` weiterhin auf den korrekten Handle zeigt. |

---

## 13. Definition of Done

- [ ] `shopify theme check --fail-level error` dateibezogen fehlerfrei auf allen neuen und
      geänderten Dateien: `templates/page.hilfe.json`, `sections/mdm-help-topic-cards.liquid`,
      `assets/mdm-section-help-topic-cards.css`, die 6 `assets/mdm-icon-hilfe-*.svg`,
      `locales/en.default.schema.json`, `locales/de.schema.json`
- [ ] Shopify Dev MCP `validate_theme` / `validate_theme_codeblocks` bestanden, Liquid
      strict-parse-sauber
- [ ] `templates/page.hilfe.json` parst als JSON, kein Auto-Generated-Banner
- [ ] Übersetzungen vollständig und paarig in `en.default.schema.json` **und** `de.schema.json`
      (identische Key-Menge); Frontend-Locales nur falls ein fester String hinzukommt, dann in
      `en.default.json` **und** `de.json`
- [ ] `sections/mdm-help-topic-cards.liquid` hat ein Editor-Preset mit 6 Blocks und ist im
      Editor konfigurierbar
- [ ] **Direktiv-Nachweis:** `assets/mdm-section-help-topic-cards.css` enthält kein `font-size`,
      `font-weight`, `letter-spacing`, `line-height` und keine Farbe außer `--mdm-color-border`
- [ ] **Branch-Nachweis (`git diff --stat`):** **keine einzige bestehende `.liquid`-Datei**
      geändert; die einzigen geänderten Bestandsdateien sind `locales/en.default.schema.json` und
      `locales/de.schema.json`, dort ausschließlich additiv unter
      `sections.mdm-help-topic-cards.*`. Keine Änderung an `layout/mdm-theme.liquid`, `config/`,
      `assets/theme.css`, bestehenden `assets/mdm-*.css` oder einem anderen Template; kein
      `assets/mdm-page-hilfe.css` im Repo
- [ ] `sections/mdm-breadcrumbs.liquid`, `sections/rich-text.liquid`, `sections/mdm-page-title.liquid`
      und `sections/newsletter.liquid` haben einen leeren Diff
- [ ] Alle „Verbindlich"-Listen der Phasen 1, 2, 3 und 5 abgehakt
- [ ] Alle Deviation-Listen der Phasen 1, 2, 3 und 5 mit **gemessenen** Ist-Werten gefüllt; keine
      ❌-Unbekannt-Zeile mehr offen, außer sie ist ausdrücklich als laufzeitabhängig markiert
- [ ] **E-11:** Deviation-Basis ist der Theme-Stand inkl. `assets/mdm-global-overrides.css`; alle
      ⚠️-Werte gegen den committeten Stand verifiziert und auf ✅ Belegt gehoben
- [ ] `feat/help-hub-page` enthält den Stand von `feat/retoure-global-styles` (Merge oder Rebase),
      `assets/mdm-global-overrides.css` wird auf `page.hilfe` geladen
- [ ] Breadcrumbs zeigen genau 2 Segmente; das zweite trägt `aria-current="page"`, ist nicht
      verlinkt und rendert `page.title` (Textabweichung zum Design akzeptiert, E-7 / O-22)
- [ ] Icons dekorativ (`aria-hidden="true"`), zugänglicher Name der Kachel = Kacheltitel
- [ ] Kacheln ohne URL rendern ohne `<a>` und ohne `href`; nirgends auf der Seite `href=""`
      oder `href="#"`
- [ ] Tastaturnavigation vollständig, geerbter Fokusring auf allen interaktiven Elementen
      sichtbar
- [ ] Keine horizontale Scrollbar und kein Layout-Bruch bei 390, 768, 1024, 1280, 1440 px
- [ ] Phase 4 (Newsletter) dokumentiert blockiert und **nicht** implementiert
- [ ] Review-Paar (theme-reviewer ∥ security-reviewer) nach jeder implementierten Phase
      APPROVED — mit dem Hinweis, dass Deviation-Listen kein Prüfmaßstab sind
- [ ] Kein Push aufs Live-Theme; Admin-Umschaltung auf `page.hilfe` (Handle
      `hilfe-und-antworten-zu-haufigen-fragen`, ID `698882949501`) ausschließlich durch Konrad
- [ ] Deviation-Listen als Termin-Grundlage an Konrad übergeben (O-14)
- [ ] Aktualisierungsvorschlag für `figma-mapping.md` im Plan dokumentiert (Abschnitt 10)
