# Spec: PLP-Produktkachel — Rueckbau auf Nexvo-Default

> Loest die fruehere Spec `product-card-full-click.md` ab. Der urspruengliche Wunsch
> "ganze Kachel anklickbar" ist darin nicht erledigt, sondern als offene Entscheidung
> C1 uebernommen — er steht jetzt hinter dem Rueckbau, nicht davor.

## Ziel

Die Produktkachel auf der PLP soll das Standardverhalten des Nexvo/Hyper-Themes erben.
Alles, was die Agentur Latori beim Nachbau der PLP am Default vorbei gebaut hat, wird
identifiziert und entfernt. Erhalten bleiben nur die bewusst bestellten Ergaenzungen und
die bereits abgestimmten Abstands- und Typografie-Aenderungen.

## Grundlage

Call mit Bhavani Govindan (UI/UX) am 15. September 2026, 07:14 Uhr, 6:54 Min.
Kernaussagen:

- "We don't want to override anything over here. [...] It's possible that in their code they
  have overridden the default behavior. So we have to look into their code and we have to
  see what have they overridden and delete that, so that it inherits the Nexvo default."
- "Aber der Card Behaviour, die Verhaeltnis, muss default sein."
- "Die Aenderungen, die wir von Latori erwartet haben, sind wirklich nur dieser Text
  inklusive gesetzliche Mehrwertsteuer und niedriger Bestpreis [...], weil das gibt es nicht
  in Nexvo. Aber sie haben alles einfach vermischt."
- Abstands- und Typografie-Aenderungen, die bereits umgesetzt sind, bleiben — inklusive
  noch zu korrigierender Fehler.
- Der Nexvo-Hover mit Vorder-/Rueckseitenwechsel des Bildes **bleibt bzw. kommt zurueck**:
  "Ja, der bleibt. Das ist auch gut, wenn der Kunde direkt hier das sehen kann."
- Die Kacheln "Weitere Ausgaben" sind reine Darstellung ohne Funktion: "Das ist ein
  statisches Bild. Da koennen wir nichts machen. [...] aber wir behalten Nexvo Default."
- Warnung gegen weitere Overrides: "But if you override everything, then we won't know
  later what has to be removed."
- Vorgehen: PLP zuerst, PDP danach, Punkt fuer Punkt gemeinsam, alle Aenderungen auf
  einmal. Erster Termin am 15. September 2026, 13:00 Uhr.

## Ausgangslage — Befund aus dem Code

### ✅ Belegt: Die mdm-Kopie ist kein Override, sondern ein Neubau

`snippets/mdm-card-product.liquid` wurde am 29. Juli 2026 von `OlawaleJoseph` mit dem
Commit `7a1a81d "duplicate mdm snippets"` angelegt. Von den Funktionen des Originals
`snippets/card-product.liquid` ist in der Kopie **keine einzige** uebrig:

| Nexvo-Funktion | Original | mdm-Kopie |
|---|---|---|
| Zweitbild-Wechsel beim Hover (`pcard_show_second_img`) | vorhanden | fehlt |
| Quick-View-Button (`pcard_show_quickview_button`) | vorhanden | fehlt |
| Quick-Add / Warenkorb (`pcard_show_cart_button`) | vorhanden | fehlt |
| Vergleichs-Checkbox (`compare-checkbox`) | vorhanden | fehlt |
| Badges (`pcard-badges`) | vorhanden | fehlt |
| Flash-Sale (`pcard-flash-sale`) | vorhanden | fehlt |
| Farb-Swatches (`pcard-color-swatch`) | vorhanden | fehlt |
| Preis ueber `snippets/price.liquid` | vorhanden | eigenes Markup |
| Titel-Zeilenbegrenzung (`pcard_title_line_limit`) | vorhanden | fehlt |
| Inhalts-Ausrichtung (`pcard_content_alignment`) | vorhanden | fehlt |
| Bildformat aus `pcard_image_ratio` | vorhanden | hart auf `240/190` |
| Kachel-Stil / Farbschema (`pcard_style`) | vorhanden | fehlt |
| Zoom-Animation (`motion-element`) | vorhanden | fehlt |
| Struktur `product-card__wrapper` | vorhanden | fehlt |

Nachweis: `snippets/mdm-card-product.liquid` Zeile 136-236 gegen
`snippets/card-product.liquid` Zeile 108-417.

### ✅ Belegt: Die Theme-Settings laufen ins Leere

`pcard_show_second_img` ist in `config/settings_data.json` nicht gesetzt und faellt damit
auf den Schema-Default `true` zurueck — der Zweitbild-Hover **soll** also an sein.
`pcard_show_quickview_button` steht explizit auf `true`. Beide Settings haben auf der PLP
keine Wirkung, weil die mdm-Kopie sie nicht ausliest. Das ist genau der Zustand, den
Bhavani im Theme-Editor vorfindet: Sie stellt etwas um, und nichts passiert.

`sections/mdm-main-collection-product-grid.liquid:225` uebergibt ausserdem
`enable_compare_checkbox: true` an ein Snippet, das den Parameter nicht kennt.

### ✅ Belegt: Konflikt um `product.images[1]`

Nexvo nutzt das zweite Produktbild fuer den Hover-Wechsel
(`card-product.liquid:42`). Latori verwendet dieselben Bilder als runde Thumbnails in
"Weitere Ausgaben" (`mdm-card-product.liquid:178`: `product.images limit: 3 offset: 1`).

**Wird der Nexvo-Hover zurueckgeholt, ohne die Thumbnails anzufassen, erscheint das
zweite Bild doppelt** — einmal als Hover-Rueckseite, einmal als erstes Thumbnail.
Das muss gemeinsam entschieden werden, siehe C2.

### ✅ Belegt: Harte deutsche Strings ausserhalb des Locale-Systems

`mdm-card-product.liquid` Zeile 70-81 und 176 enthalten fest verdrahtete Texte:
`'KOLLEKTION - Flatrate'`, `'Set'`, `'KOLLEKTION - Classic'`, `'inkl. gesetzl. MwSt.'`,
`'zzgl. MwSt.'`, `'Weitere Ausgaben:'`. Das umgeht `locales/de.json` und
`locales/en.default.json` und widerspricht der Namensraum-Regel des Workspace.

### ✅ Belegt: Der 30-Tage-Bestpreis ist eine abgebrochene Migration

Es sind nicht zwei gewollte Implementierungen, sondern ein unfertiger Umbau.

`snippets/bpi-price.liquid` enthaelt kein Liquid, sondern nur den Einhaengepunkt einer
Latori-App:

```liquid
<bpi-manager class="latori-bpi-container">
  <div id="bpi-element"></div>
</bpi-manager>
```

Die App ist als App-Embed im Shop aktiv (`config/settings_data.json:112`,
`shopify://apps/latori-best-price-indicator/blocks/bpi-price/...`, `"disabled": false`).
Sie befuellt `#bpi-element` clientseitig. Die Parameter `product:` und `hide_when_equal:`,
die alle drei Aufrufer uebergeben, werden vom Snippet **ignoriert**.

Am 2. September 2026 hat Latori mit Commit `ab237a4 "bpi update"` von der Liquid-Loesung
auf die App umgestellt — aber nur an drei von vier Stellen:

| Stelle | Nach der Migration |
|---|---|
| `mdm-card-product.liquid:133` (kompakter Zweig) | App-Snippet |
| `mdm-collection-cards-item.liquid:66` | App-Snippet |
| `mdm-product-information-blocks.liquid:129` | App-Snippet |
| `mdm-card-product.liquid:232-234` (**PLP-Grid**) | **nicht migriert**, weiter Liquid |

Der PLP-Zweig liest weiterhin `product.metafields.custom.lowest_price_30_days`
(Zeile 84-87). Der kompakte Zweig las vor der Migration ein *anderes* Metafeld,
`variant.metafields.bpi.last_known_price` — es waren also schon vorher zwei Datenquellen.

Zwei Folgeprobleme:

- **Datenstand kann auseinanderlaufen.** Die PLP zeigt den Metafeld-Wert, alle anderen
  Flaechen zeigen, was die App berechnet. Bei einer Pflichtangabe nach EU-Omnibus ist das
  ein rechtliches Risiko, kein kosmetisches.
- **`id="bpi-element"` ist eine feste ID pro Karte.** Der kompakte Zweig wird von vier
  Sections in Schleifen gerendert (`mdm-featured-collection`, `mdm-related-products`,
  `mdm-similar-products`, `mdm-recently-viewed-products`). Auf diesen Seiten existiert die
  ID mehrfach — ungueltiges HTML, und `getElementById` findet nur die erste.

❌ **Unbekannt:** ob das Metafeld `custom.lowest_price_30_days` noch gepflegt wird oder seit
der Migration veraltet. Nur im Shopify-Admin pruefbar.

Nebenbefund: Derselbe Commit hat kurzzeitig den Debug-String `jlklklklk` in den
PLP-Preistext geschrieben; behoben am selben Tag mit `626caed`.

## Klassifikation

### A — Bleibt (bestellte Ergaenzungen und abgestimmte Anpassungen)

- [ ] Zeile "inkl. gesetzl. MwSt." / mobil "zzgl. MwSt." — in Nexvo nicht vorhanden
- [ ] Zeile zum niedrigsten Preis der letzten 30 Tage (EU-Omnibus) — in Nexvo nicht vorhanden
- [ ] Abstaende zwischen Titel, Produkttext und Preis
- [ ] Marken-Typografie und Marken-Farben der Kachel
- [ ] Kachel-Lift und Schattenwechsel beim Hover (`brand-overrides.css:933-938`)

Fehler in diesen Punkten werden im gemeinsamen Termin korrigiert, nicht zurueckgebaut.

### B — Rueckbau auf Nexvo-Default

- [ ] Zweitbild-Wechsel beim Hover (Vorder-/Rueckseite) reaktivieren
- [ ] Bildformat wieder aus `pcard_image_ratio` statt hart `240/190`
- [ ] Titel-Zeilenbegrenzung wieder aus `pcard_title_line_limit`
- [ ] Inhalts-Ausrichtung wieder aus `pcard_content_alignment`
- [ ] Badges und Flash-Sale wieder ueber die Nexvo-Snippets
- [ ] Preisausgabe wieder ueber `snippets/price.liquid`
- [ ] Quick-View, Quick-Add, Vergleichs-Checkbox wieder an ihre Settings koppeln
- [ ] Harte deutsche Strings in `locales/de.json` + `locales/en.default.json` ueberfuehren
- [ ] Toten Parameter `enable_compare_checkbox` in der Section aufloesen

Grundsatz: **Verhalten wird an Theme-Settings zurueckgegeben, nicht im Code festgeschrieben.**
Jeder Punkt, der nach dem Rueckbau anders aussehen soll, wird ueber ein Setting geloest;
ein neuer Code-Override nur, wenn kein Setting existiert — und dann dokumentiert.

### C — Offen, Entscheidung im Termin

- **C1 — Ganze Kachel anklickbar.** Der urspruengliche Auftrag.
  **✅ Belegt: Das ist kein Nexvo-Default.** Auch das Original hat nur Bildlink, Titellink
  und Buttons (`card-product.liquid:115, 315-319`). Eine vollflaechige Kachel waere also in
  jedem Fall ein bewusster Zusatz, kein Rueckbau — und steht damit in Spannung zu
  "we don't want to override anything over here". Zu klaeren: ob ueberhaupt, und wenn ja,
  ob nach dem Rueckbau noch noetig. Details und Abwaegung im englischen Handout.
- **C2 — "Weitere Ausgaben"-Thumbnails.** Laut Call reine Darstellung ohne Funktion.
  Zu klaeren: Links entfernen und rein dekorativ lassen, oder ganz entfernen? Und wie
  wird die Doppelnutzung von `product.images[1]` aufgeloest (siehe oben)?
- **C3 — Typ-Badge "KOLLEKTION - Classic / Flatrate / Set".** Latori-Eigenbau, steht nicht
  auf der Liste der bestellten Ergaenzungen. Bleibt er, faellt er, oder wird er sauber
  ueber Metafelder und Locales geloest?
- **C4 — 30-Tage-Bestpreis: Migration zu Ende fuehren.** Die Latori-App ist installiert und
  aktiv, drei von vier Stellen nutzen sie bereits — nur die PLP nicht. Vorschlag: PLP auf
  `bpi-price` umstellen und den direkten Metafeld-Zugriff entfernen. Vorher klaeren, ob das
  Metafeld noch die fuehrende Quelle ist, und ob die App mit mehreren Karten pro Seite
  umgehen kann (feste ID `bpi-element`).
- **C5 — Umfang des Rueckbaus.** Punkt B stellt Quick-View, Quick-Add und Vergleich wieder
  her. Das ist eine sichtbare Veraenderung der PLP. Bestaetigen, dass das gewollt ist, oder
  einzeln per Setting abschalten.

## Anforderungen

- [ ] Vollstaendige Punkt-fuer-Punkt-Liste aller Abweichungen als Arbeitsgrundlage fuer den
      gemeinsamen Termin (diese Spec, Abschnitt Klassifikation)
- [ ] Jede Abweichung ist genau einer Kategorie A, B oder C zugeordnet
- [ ] Rueckbau erfolgt in einem Zug fuer die gesamte PLP, nicht stueckweise
      ("dann machen wir alle Aenderungen auf einmal")
- [ ] Kein neuer Code-Override ohne dokumentierte Begruendung, warum kein Setting reicht

## Akzeptanzkriterien

- [ ] Umschalten von `pcard_show_second_img` im Theme-Editor wirkt sichtbar auf der PLP
- [ ] Umschalten von `pcard_show_quickview_button` wirkt sichtbar auf der PLP
- [ ] Umschalten von `pcard_image_ratio` wirkt sichtbar auf der PLP
- [ ] Hover ueber das Produktbild zeigt die Rueckseite der Muenze
- [ ] Kein hart verdrahteter deutscher Text mehr in `mdm-card-product.liquid`
- [ ] MwSt.-Zeile und 30-Tage-Preis weiterhin vorhanden und korrekt
- [ ] 30-Tage-Preis auf PLP und Startseite zeigt fuer dasselbe Produkt denselben Wert
- [ ] Keine doppelte HTML-ID `bpi-element` auf Seiten mit mehreren Karten
- [ ] Abstaende und Typografie unveraendert gegenueber dem Stand vor dem Rueckbau
- [ ] Keine toten Parameter mehr im Aufruf aus `mdm-main-collection-product-grid.liquid`
- [ ] `shopify theme check --fail-level error` ohne neue Errors gegenueber der Baseline
- [ ] `validate_theme` ueber das Shopify Dev MCP ohne neue Findings
- [ ] Grid und Liste, Desktop und Mobile (Breakpoint 767 px) geprueft

## Constraints

- **Blast-Radius**: `snippets/mdm-card-product.liquid` enthaelt zwei Zweige. Diese Spec
  betrifft nur den Grid-Zweig (Zeile 136-236, ausschliesslich PLP). Der kompakte Zweig
  `.mdm-rv-card` (Zeile 90-134) bedient Startseite, PDP-Empfehlungen, zuletzt gesehen und
  Landingpages — er wird hier nicht angefasst, hat aber dieselbe Rueckbau-Frage offen.
- **PDP folgt spaeter**, nicht in diesem Durchgang.
- **FoxEcom-Kerndateien** (`snippets/card-product.liquid`, `assets/theme.css`) bleiben
  unveraendert. Der Rueckbau bedeutet nicht, die mdm-Kopie zu loeschen, sondern sie wieder
  an die Nexvo-Logik und deren Settings anzuschliessen.
- **Zusammenarbeit**: Bhavani arbeitet im Theme-Editor, Konrad im Code ueber Pull Requests
  gegen `main`. ⚠️ Theme-Editor-Aenderungen laufen ueber den GitHub-Sync als
  `shopify[bot]`-Commits in `main` zurueck (belegt: Commits `29dcf9b`, `8bfb6b0`, `8b393e9`
  vom 7. September 2026). Betroffen ist vor allem `config/settings_data.json`. Vor jedem
  Push `git pull` und Bot-Commits pruefen.

## Dateien

- `theme/snippets/mdm-card-product.liquid` (Grid-Zweig, Zeile 136-236)
- `theme/sections/mdm-main-collection-product-grid.liquid` (toter Parameter)
- `theme/assets/mdm-collection.css`
- `theme/locales/de.json` + `theme/locales/en.default.json` (harte Strings)
- Handout fuer die Designerin: `docs/specs/plp-card-nexvo-default-en.pdf`
- Branch: `feat/plp-card-nexvo-default`

## Status

ENTWURF — Abstimmung am 15. September 2026, 13:00 Uhr
