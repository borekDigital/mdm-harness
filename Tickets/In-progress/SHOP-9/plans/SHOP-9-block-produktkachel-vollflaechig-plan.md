## Block-Plan: produktkachel-vollflaechig

Die Produktkachel wird an jeder Stelle klickbar, ohne neues Markup und ohne JavaScript. Der
Titellink bekommt ein unsichtbares `::after`, das die ganze Kachel überdeckt („Stretched Link“).
Der Bildbereich liegt per `z-index` darüber, damit Zweitbild-Hover und Quick-View weiter
funktionieren. Sein Innenabstand wird über ein `::before` am Bildlink klickbar. Der Typ-Badge
lässt Klicks durch. Für die Hyper-Kachel im Suchvorschlagslayer gilt dasselbe Muster im
Wrapper `.mdm-predictive-card`. Zusammen sind das zehn CSS-Regeln in zwei MDM-Dateien.

Grundlage: Spec `.claude/specs/themes/mdm/produktkachel-vollflaechig-klickbar.md` (ENTWURF,
15. Oktober 2026), Ticket SHOP-9. Code-Stand: origin/main `54b5019` im Repo `themes/mdm`
(gelesen per `git show origin/main:<pfad>`; der lokale Checkout steht auf
`fix/collection-read-more-color` und ist nicht maßgeblich).

**Hyper-Quelle:** `snippets/card-product.liquid:117` (Bildlink), `:314-321` (Titel),
`assets/theme.css:4220-4228` (`.product-card__wrapper`, `.product-card__title`), `:4458-4473`
(Hover am Bildbereich)
**mdm-Kopie:** `snippets/mdm-card-product.liquid` (existiert, bleibt unverändert), CSS-Ziele
`assets/mdm-component-product-card.css` und `assets/mdm-predictive-search.css` (existieren)
**Mapping-Stufe:** (b) Override in bestehenden mdm-Dateien, nur CSS. Kein Liquid, kein JS.

### Befundlage

#### MDM-Kachel (`mdm-card-product`)

| # | Aussage | Label |
|---|---|---|
| B1 | Zwei Links pro Kachel: Bildlink `.mdm-product-card__media-link` und Titellink `.reversed-link block text-limit-*` | ✅ `snippets/mdm-card-product.liquid:100`, `:161` |
| B2 | Badge sitzt im Bildbereich vor dem Bildlink, Quick-View-Button danach, beide Geschwister des Bildlinks | ✅ `:97-99`, `:138-148` |
| B3 | Das Quick-View-Modal wird in der Kachel gerendert, beim Öffnen aber an `<body>` umgehängt (außer im Theme-Editor in der Overlay-Gruppe) | ✅ `mdm-card-product.liquid:195-197`; `assets/theme.js:716-720`; `assets/quick-view.js:16-18` (geladen in `layout/mdm-theme.liquid:155`) |
| B4 | Bildlink absolut mit `inset: var(--mdm-pcard-media-padding)` (2rem, mobil 1,2rem). Der Innenabstand gehört zu `.mdm-product-card__media` und ist kein Link | ✅ `assets/mdm-component-product-card.css:87-91`, `:15`, `:256` |
| B5 | `.mdm-product-card__media` ist `position: relative` ohne `z-index`, also kein Stapelkontext | ✅ `:52-57` |
| B6 | Badge: `position: absolute; z-index: 2`, keine `pointer-events`-Regel | ✅ `:62-67` |
| B7 | Zweitbild und Quick-View-Einblendung hängen an `.mdm-product-card__media(--has-second):hover`, ab 768 px | ✅ `:113-123` |
| B8 | Kachel-Lift per `transform` an `.mdm-product-card:hover` | ✅ `:44-47` |
| B9 | Kachel: `height: 100%`, Rahmen `1px solid`, `overflow: clip` | ✅ `:37-38`, `:245-248` |
| B10 | `.mdm-product-card` hat nirgends `position`; `.product-card` hat in `theme.css` keine Basis-Regel mit `position` | ✅ Suche in `mdm-component-product-card.css` und `theme.css` (nur Modifier-Klassen ab `:4323`) |
| B11 | Das Zweitbild hat `inset-full` und `position: absolute`. Es richtet sich am Bildlink aus (nächster positionierter Vorfahre) | ✅ `mdm-card-product.liquid:116`; `theme.css:4243-4248`, `:5513-5518` |
| B12 | `.media-wrapper` ist `position: relative; overflow: hidden` | ✅ `theme.css:1275-1280` |
| B13 | `.reversed-link` ist nicht positioniert. `[class*=text-limit-]` setzt `overflow: hidden; display: -webkit-box` | ✅ `theme.css:5242-5244`, `:5430-5435` |
| B14 | Ein absolut positionierter Nachfahre wird von `overflow` nur abgeschnitten, wenn das Overflow-Element sein Containing Block ist oder zwischen ihm und dem Containing Block liegt. Weil der Titellink nicht positioniert ist, ist der Containing Block des `::after` die Kachel → `text-limit-*` schneidet die Fläche nicht ab | ✅ CSS 2.1 §11.1.1 in Verbindung mit B13; Laufzeitprobe T2 |
| B15 | `overflow: clip` schneidet an der Padding-Box ab. Ein `::after` mit `inset: -1px` wird ohne `overflow-clip-margin` am Rahmen abgeschnitten, der 1-px-Rahmen bleibt dann tot | ⚠️ Vermutung (Spezifikation `overflow-clip-margin`, Default `padding-box`) → T2 |
| B16 | Titel-Hover: Unterstreichung und Farbwechsel an `.reversed-link:hover .reversed-link__text`, nur bei `(hover: hover) and (pointer: fine)` | ✅ `theme.css:6480-6491` |
| B17 | Fokusring global `*:focus-visible`, `outline 0.2rem`, `outline-offset 0.3rem` | ✅ `theme.css:1122-1125` |
| B18 | Quick-View-Button: `position: absolute; z-index: 2 !important`, ab 768 px `opacity: 0` bis Hover; unter 768 px `display: none` | ✅ `theme.css:4304-4309`, `:4439-4444`, `:4480-4482` |
| B19 | Listenansicht im Kategorie-Grid: Kachel als Zeile | ✅ `assets/mdm-collection.css:663-665` |
| B20 | Keine weitere CSS-Datei greift auf `.mdm-product-card*` zu (außer B19) | ✅ `git grep` über `assets/` |
| B21 | `assets/mdm-global-overrides.css` existiert auf origin/main nicht; global geladen wird `brand-overrides.css` | ✅ `git ls-tree`, `layout/mdm-theme.liquid:64` |

#### Hyper-Kachel im Suchvorschlagslayer (`card-product` in `.mdm-predictive-card`)

| # | Aussage | Label |
|---|---|---|
| B22 | Der Layer rendert `card-product` in `.mdm-predictive-card` (Empfehlungen und Treffer). Der MDM-Badge liegt außerhalb der Kachel | ✅ `snippets/mdm-predictive-search.liquid:104-119`, `:175-189` |
| B23 | Der Layer wird im Header und auf der Suchseite gerendert, das Stylesheet lädt das Snippet selbst | ✅ `sections/mdm-header.liquid:159`, `sections/mdm-main-search.liquid:52`, `mdm-predictive-search.liquid:6` |
| B24 | `.mdm-predictive-card` ist `position: relative`; der MDM-Badge hat schon `z-index: 2; pointer-events: none`; Hyper-Badges und Flash-Sale sind ausgeblendet | ✅ `assets/mdm-predictive-search.css:6-9`, `:24-45`, `:49-52` |
| B25 | `.product-card__wrapper` (`relative`, `h-full`) umschließt Bildbereich und Info, `.product-card__title` ist `position: relative` | ✅ `card-product.liquid:115`; `theme.css:4220-4228` |
| B26 | `.product-card__image-wrapper`: `relative`, `overflow: hidden`, ohne Innenabstand; Bildlink `tabindex="-1"` mit `motion-element.block` darin | ✅ `theme.css:4249-4254`, `:4327-4329`; `card-product.liquid:116-118` |
| B27 | Der Bildlink deckt den Bildbereich vollständig ab (inline `<a>` mit Block-Kind) | ⚠️ Vermutung → T9 (`elementFromPoint` in den Ecken) |
| B28 | Bedienelemente im Bildbereich: Quick-View `z-index: 2 !important`, Warenkorb-Leiste `.product-card__main-actions` `z-index: 3` | ✅ `theme.css:4304-4318`; `card-product.liquid:177-270` |
| B29 | Bedienelemente im Info-Bereich: Hersteller-/Typ-Link (`p > a.reversed-link`), Swatches `ul.product-card__swatches > li[data-tooltip]` mit Links, `li.swatch-more > a` | ✅ `card-product.liquid:292-313`, `:325-333`; `snippets/pcard-color-swatch.liquid:29-92` |
| B30 | `[data-tooltip]` ist `position: relative` → `.swatch-item` braucht nur `z-index`; `.swatch-more` hat kein `data-tooltip` | ✅ `theme.css:3590-3592`; `pcard-color-swatch.liquid:54`, `:80` |
| B31 | Settings heute: Warenkorb-Button aus, Quick-View an, Swatches an, Hersteller/Typ im Layer aus, Kartenstil `card`, Swatch-Trigger `Variant` | ✅ `config/settings_data.json:57`, `:64-65`, `:69`, `:78`, `:94-95` |
| B32 | Ob MDM-Produkte eine Option „Variant“ führen und damit Swatches rendern | ❌ Unbekannt → T9 |
| B33 | Preis-Snippet enthält keine Links oder Buttons; ob `.f-price`-Teile positioniert sind, wurde nicht vollständig geprüft. `visually-hidden`-Spans sind 1 px groß | ⚠️ Vermutung: keine toten Flecken → T9 |
| B34 | Kartenstil `card`: Info-Padding `1.2rem`, ab 768 px `1.2rem 2rem 2rem`; kein sichtbarer Rahmen | ✅ `theme.css:4330-4337`; Rahmen-Token transparent (theme-planner-Memory, ⚠️ nicht erneut gelesen) |

#### Slider

| # | Aussage | Label |
|---|---|---|
| B35 | „Ähnliche Produkte“/„Zuletzt angesehen“ nutzen `product-slider` (Swiper), unter Mobile-Breakpoint wird der Slider abgebaut | ✅ `assets/mdm-product-slider.js:51-63`, `:71-105` |
| B36 | `mdm-similar-products` und `mdm-featured-collection` nutzen `mdm-featured-collection` (Swiper) | ✅ `sections/mdm-featured-collection.liquid:186-197`, `:293`; `assets/mdm-featured-collection.js:91` |
| B37 | Swiper-Defaults `preventClicks: true`, `preventClicksPropagation: true`; der Click-Handler ruft nach einem Zug `preventDefault()` auf. Keine MDM-Option überschreibt das | ✅ `assets/vendor.js:4` (minifiziert, Funktion mit `if(!t.allowClick){if(t.params.preventClicks)e.preventDefault()…`); Optionen `mdm-product-slider.js:71-96`, Suche in `mdm-featured-collection.js` ohne Treffer |
| B38 | Heute verhält sich ein Zug auf dem Bild schon so (Bildlink im Slide). Die Änderung dehnt dieses Verhalten auf die ganze Kachel aus | ⚠️ Vermutung (aus B37 abgeleitet) → T7 |
| B39 | Mobil (`swipe-mobile`) ist natives Scrollen; ein Wisch löst keinen Klick aus | ⚠️ Vermutung (Plattformverhalten) → T7 |

### Gewählte Technik und Begründung

```
.mdm-product-card  (position: relative, NEU)               ← Containing Block der Overlay-Fläche
├── .mdm-product-card__media  (relative, z-index: 1 NEU)   ← liegt ÜBER der Overlay-Fläche
│   ├── badge (z 2, pointer-events: none NEU)               ← Klick fällt durch
│   ├── a.media-link (abs, inset = Padding)
│   │   └── ::before (abs, inset = −Padding, NEU)           ← macht den Innenabstand zum Bildlink
│   └── button.quickview (z 2 !important)                   ← bleibt bedienbar
└── .mdm-product-card__content
    └── h3 > a.reversed-link
        └── ::after (abs, inset: −1px, NEU)                  ← Overlay über die ganze Kachel
```

- **Warum das Overlay am Titellink:** Er trägt den Produktnamen als zugänglichen Namen, ist
  schon Tab-Stopp und echter Link. Mittelklick, Cmd-Klick und Kontextmenü wirken auf ihn (R3).
  Kein neues Element, kein neuer Tab-Stopp (R6).
- **Warum `z-index: 1` am Bildbereich:** Ohne ihn malt der Browser das `::after` (positioniert,
  `z-index: auto`, später im Baum) über den Bildbereich. Dann trifft der Zeiger den Titellink,
  `.mdm-product-card__media:hover` greift nicht mehr, und Zweitbild und Quick-View-Einblendung
  brechen (R5). Ein negativer `z-index` am Overlay scheidet aus, weil der nicht positionierte
  Inhaltsbereich (mit Hintergrund, `:133`) sonst darüber läge und alle Klicks im Textteil schluckte.
- **Warum `::before` am Bildlink statt Padding am Bildlink:** Bekäme der Bildlink `inset: 0`
  plus Innenabstand, würde sich das Zweitbild (`inset-full`, absolut am Bildlink, B11) über den
  ganzen Innenabstand legen und größer als das Hauptbild werden. Das Pseudo-Element vergrößert
  nur die Trefferfläche, die Geometrie des Links bleibt. Klicks und Hover auf dem Pseudo-Element
  zählen als Klicks und Hover auf dem Bildlink und damit auf `.mdm-product-card__media`.
- **Rahmen (R1):** `inset: -1px` plus `overflow-clip-margin: 1px` an der Kachel. Kein Kind reicht
  heute bis an den Rahmen, die Clip-Erweiterung ändert also nichts Sichtbares (⚠️ → T10).
  Browser ohne `overflow-clip-margin` (❌ Unbekannt: Safari-Stand) schneiden an der Padding-Box ab;
  dann bleibt nur die 1-px-Linie tot. Degradation, keine Regression.

### Änderungen

1. **MDM-Kachel: Overlay, Stapelreihenfolge, Badge** — `assets/mdm-component-product-card.css`,
   ein neuer Block am Dateiende (nach `:276`), alle Selektoren im bestehenden Scope
   `:is(.mdm-collection-grid, .featured-collection--mdm-rv, .mdm-search-results)`. Fünf Regeln:

   | # | Selektor (Scope weggelassen) | Deklarationen |
   |---|---|---|
   | 1a | `.mdm-product-card.product-card` | `position: relative; overflow-clip-margin: 1px;` |
   | 1b | `.mdm-product-card__title a::after` | `content: ""; position: absolute; inset: -1px;` (−1px = Rahmenbreite `:38`) |
   | 1c | `.mdm-product-card__media` | `z-index: 1;` |
   | 1d | `.mdm-product-card__media-link::before` | `content: ""; position: absolute; inset: calc(-1 * var(--mdm-pcard-media-padding));` |
   | 1e | `.mdm-product-card__type-badge` | `pointer-events: none;` |

   - Kommentar über dem Block, Englisch wie der Rest der Datei, sinngemäß:
     `/* SHOP-9: whole card clickable. Deliberate addition to the Nexvo default (agreed with Bhavani), not a rollback. Title link stretched over the card; image area stacked above it so second image and quick view keep their hover. */`
   - 1a wählt den Selektor `.mdm-product-card.product-card` wie `:245`, damit `overflow-clip-margin`
     an derselben Regelstelle wie `overflow: clip` hängt.
   - Die Kopfzeile der Datei (`:1-9`) bekommt einen Satz Verweis auf SHOP-9.
   - Validierung: T1 bis T8, T10.

2. **Hyper-Kachel im Suchvorschlagslayer** — `assets/mdm-predictive-search.css`, neuer Block
   am Dateiende (nach `:52`), Scope `.mdm-predictive-card`. Fünf Regeln:

   | # | Selektor | Deklarationen | Grund |
   |---|---|---|---|
   | 2a | `.mdm-predictive-card .product-card__title` | `position: static;` | hebt `theme.css:4226-4228` auf; sonst endet das Overlay an der Überschrift |
   | 2b | `.mdm-predictive-card .product-card__title a::after` | `content: ""; position: absolute; inset: 0;` | Containing Block ist `.product-card__wrapper` (B25) |
   | 2c | `.mdm-predictive-card .product-card__image-wrapper` | `z-index: 1;` | Hover auf dem Bild (`theme.css:4458-4473`) und Quick-View/Warenkorb bleiben oben (B28) |
   | 2d | `.mdm-predictive-card :is(.product-card__vendor, .product-card__type) a` | `position: relative; z-index: 1;` | R2, sobald eingeschaltet (heute aus, B31) |
   | 2e | `.mdm-predictive-card .product-card__swatches > li` | `position: relative; z-index: 1;` | Swatches und „+N“ bleiben bedienbar (B29, B30) |

   - Gleicher Kommentar mit SHOP-9 und „deliberate addition to the Nexvo default“.
   - 2d zielt auf das `<a>`, nicht auf das `<p>`: Ein angehobenes `<p>` würde die ganze Zeile neben
     dem Link zum toten Fleck machen. 2e zielt aus demselben Grund auf `li`, nicht auf `ul`.
   - Der MDM-Badge (B24) braucht nichts: `z-index: 2` hält ihn über dem Bildbereich (`z-index: 1`),
     `pointer-events: none` lässt Klicks auf den Bildlink fallen.
   - Keine Änderung an `snippets/card-product.liquid` oder `assets/theme.css` (A10).
   - Validierung: T9.

Zusammen: 10 Regeln, 2 Dateien, 0 Zeilen Liquid/JS/JSON. Keine Farben, Abstände, Größen oder
Typografie (Direktiv-Probe T12).

### Bekannte Folgen (bewusst, zur Abnahme)

- **F1 Titel-Hover breiter:** Das Overlay gehört zum Titellink. Hover über Preis, MwSt.-Zeile,
  Leerraum oder Rahmen löst darum Unterstreichung und Farbwechsel des Titels aus (B16). Über
  dem Bild nicht, weil der Bildbereich darüber liegt. Siehe O2.
- **F2 Text nicht mehr markierbar:** Preis und MwSt.-Zeile lassen sich mit der Maus nicht mehr
  markieren (Klick landet auf dem Link). Übliche Folge eines Stretched Links.
- **F3 Zug im Slider:** Ein Zug, der auf dem Textteil beginnt, verhält sich wie heute ein Zug auf
  dem Bild (B37, B38).
- **F4 Rahmen in Safari:** siehe Technik, Abschnitt Rahmen.

### Übersetzungs-Keys

Keine. Keine neuen Texte, kein Schema-Setting.

### Abgrenzung

- Mega-Menü (`snippets/mdm-mega-menu.liquid:415`) und Menü-Drawer
  (`snippets/mdm-menu-drawer-details.liquid:340`): rendern `mdm-card-product` außerhalb der drei
  Scopes, bleiben unverändert. Alle `card-product`-Aufrufe ohne `.mdm-predictive-card` ebenso.
- Doppelter Link pro MDM-Kachel (Bildlink ohne `tabindex="-1"`, `mdm-card-product.liquid:100`
  gegenüber Hyper `card-product.liquid:117`): Nebenbefund, eigener Punkt, nicht hier (A8 verlangt
  unveränderte Tab-Reihenfolge).
- Kein Fokusrahmen um die ganze Kachel. Ginge ohne Markup über
  `.mdm-product-card:has(.mdm-product-card__title a:focus-visible)`, wäre aber eine sichtbare
  Neuerung gegen R7 und die Vererbungs-Direktive. Option O3.
- Keine Änderung an `templates/*.json`, `config/settings_data.json`, `layout/`, Hyper-Kerndateien.
- Startseite: nicht in diesem PR, siehe E1.
- Borek/IMM: kein Port in diesem PR. Nach dem Merge mit `/theme-port` bzw.
  `bin/theme-sync.sh drift assets/mdm-component-product-card.css assets/mdm-predictive-search.css`
  prüfen und übertragen (beide Dateien sind geteilter Code, ⚠️ Vermutung: in Borek/IMM gleich).

### Option E1: Startseiten-Slider (separat, nicht Teil der Kernänderungen)

Befund: `templates/index.json` enthält fünf Sections vom Typ `featured-collection`
(Hyper-Original, `:107`, `:178`, `:433`, `:504`, `:575`). Sie rendern `card-product` ohne
MDM-Wrapper (`sections/featured-collection.liquid:268`, Root-Klasse `featured-collection` `:66`).
Dieselbe Section steckt in 24 Templates, darunter rund 20 Ratgeber-Seiten (`page.*.json`). Die
Startseite nutzt Layout `mdm-theme` (`index.json:11`), der Body trägt `index-template`
(`layout/mdm-theme.liquid:115`).

| Variante | Vorgehen | Blast-Radius | Aufwand | Risiko |
|---|---|---|---|---|
| E1-a | Regeln 2a–2e zusätzlich auf `.index-template .featured-collection .product-card` anwenden, in einer Datei, die auf der Startseite lädt (`brand-overrides.css`, global, `layout/mdm-theme.liquid:64`) | nur Startseite; geteilte Datei mit Borek/IMM | klein (5 Selektoren erweitern) | mittel: Body-Klasse als Scope ist fragil, `brand-overrides.css` ist geteilter Code |
| E1-b | wie E1-a, aber Scope `.featured-collection:not(.featured-collection--mdm-rv)` ohne Body-Klasse | Startseite plus 24 Templates mit Hyper-`featured-collection` | klein | hoch: unbeabsichtigt auf allen Ratgeber-Seiten |
| E1-c | Startseiten-Sections im Editor auf `mdm-featured-collection` umstellen (rendert schon `mdm-card-product`) | nur Startseite | Template-Änderung durch Bhavani | hoch für R7: andere Kachel-Optik auf der Startseite |

Empfehlung: E1 als eigenes Ticket. Falls gewünscht, E1-a. Der Hyper-Slider der Startseite
(`featured-collection.js`) nutzt ⚠️ vermutlich dieselben Swiper-Defaults (B37), das wäre dort mit T7
zu prüfen.

### Worktree

```bash
cd /Users/konrad.thiemann/MDM/themes/mdm
git fetch origin
git worktree add ../.worktrees/mdm-card-full-click -b feat/product-card-full-click origin/main
```

Dev-Server im Worktree: `shopify theme dev --store mdm-muenze`.

Commit-Vorschlag (Konrad committet selbst):

```
feat(product-card): make the whole card clickable

Stretch the title link over the card and stack the image area above
it, so second image and quick view keep their hover. Same pattern for
the stock card in the predictive search via .mdm-predictive-card.
```

### Testschritte (Dev-Server dieses Worktrees, 1440 px und 375 px)

Hilfsfunktion für die Konsole (A2):

```js
const hit = (x, y) => { const el = document.elementFromPoint(x, y); const a = el && el.closest('a[href]'); return { el, href: a && a.getAttribute('href') }; };
// Punkte je Kachel aus getBoundingClientRect(): Bildrand (media.left + 4, media.top + media.height/2),
// Badge-Mitte, Preis-Mitte, MwSt.-Mitte, Leerraum unten (card.left + card.width/2, card.bottom - 3),
// Rahmen (card.left + 0.5, card.top + card.height/2)
```

| Schritt | Akzeptanz | Vorgehen | Erwartung |
|---|---|---|---|
| T0 | Voraussetzung | Worktree auf `54b5019`, `git diff --stat origin/main` nach der Umsetzung | nur die zwei CSS-Dateien |
| T1 | A1 | `/collections/deutschland-muenzen`: Klick auf Rahmen, Bildinnenabstand, Badge, Preis, MwSt.-Zeile, Leerraum unten | jeweils PDP |
| T2 | A2, B14, B15 | `hit()` an den sechs Punkten für drei Kacheln, davon eine mit dreizeiligem Titel (`text-limit-3-lines`) und eine mit Badge | `href` = `product.url` in allen Fällen; am Rahmen in Chrome ebenfalls (Safari: siehe F4, Ergebnis notieren) |
| T3 | A3 | 1440 px: Hover über Bild, Klick auf Lupe | Quick-View-Drawer öffnet, URL bleibt |
| T4 | A4 | Cmd-Klick auf Leerraum unten und auf Bildinnenabstand | PDP in neuem Tab, aktuelle Seite bleibt |
| T5 | A5 | T1–T4 auf `/search?q=maja`, PDP „Ähnliche Produkte“, „Zuletzt angesehen“ (vorher zwei PDPs besuchen), PDP-Slider `mdm-similar-products`/`mdm-featured-collection`, sofern auf der PDP vorhanden | wie T1–T4 |
| T6 | A6 | 1440 px: Hover über Bild, über Bildinnenabstand, über Badge | Zweitbild und Lupe erscheinen in allen drei Fällen (Kachel mit Zweitbild wählen). Hover über Preis/Leerraum: Kachel-Lift, kein Zweitbild |
| T7 | A7, B38, B39 | 1440 px im Slider „Ähnliche Produkte“ mit der Maus ziehen, Start auf Preis, Leerraum und Bild; 375 px wischen | keine Navigation, Slider bewegt sich; kein Link-Ghostbild beim Ziehen. Falls doch Navigation: Befund melden, nicht im Plan improvisieren |
| T8 | A8 | Tab durch drei Kacheln, auf origin/main und im Worktree; Fokusring am Titel sichtbar | gleiche Anzahl Tab-Stopps (heute zwei pro MDM-Kachel), Fokusring unverändert |
| T9 | A5 (Layer), B27, B32, B33 | Header-Suche öffnen: Empfehlungen ohne Begriff, dann `maja` tippen. `hit()` an Bildecken, Bildmitte, MDM-Badge, Titel, Preis, Leerraum unten. Lupe klicken (1440 px). Prüfen, ob Swatches erscheinen (`.product-card__swatches`); falls ja, Swatch-Klick und Hover. Zusätzlich auf `/search` im Layer der Seite | PDP überall außer Lupe/Swatches; Lupe öffnet Quick-View; Bild-Hover zeigt Zweitbild. Swatches: Ergebnis zu B32 notieren |
| T10 | A9, R7, B15 | Screenshots je Bereich (Grid, Suche, beide Slider, Layer) im Ruhezustand gegen origin/main, 1440 und 375 px; Listenansicht des Grids (B19) einmal mitnehmen | keine sichtbare Abweichung |
| T11 | Stapelung, ⚠️ | Kategorie-Seite scrollen, sodass Kacheln unter den Sticky-Header laufen; Filter-Drawer und Mega-Menü öffnen | Kacheln (Bildbereich `z-index: 1`) liegen nie über Header, Drawer oder Menü |
| T12 | A10, Direktive | `git diff --name-only origin/main`; `git diff origin/main \| grep -E "font-\|color\|padding\|margin\|#[0-9A-Fa-f]{3,6}"` | nur die zwei CSS-Dateien; Grep ohne Treffer in neuen Zeilen |
| T13 | A11 | `shopify theme check --fail-level error` im Worktree und als Kontrolllauf auf `54b5019` | keine neuen Findings |
| T14 | A11 | `validate_theme` für die zwei Dateien | ohne Fehler. ❌ Unbekannt, ob reine CSS-Assets geprüft werden; dann im Ergebnis vermerken |
| T15 | Blast-Radius | Mega-Menü mit Produktkachel öffnen, Menü-Drawer mobil; eine Ratgeber-Seite mit Hyper-`featured-collection` | unverändert: dort nur Bild und Titel klickbar |

### Definition of Done

- [ ] T0 bis T15 erfüllt, Messwerte (T2, T9) ins Complete-Artefakt
- [ ] theme check clean, keine neuen Findings gegenüber `54b5019`
- [ ] Übersetzungen: keine nötig (bestätigt)
- [ ] Editor-Preset: nicht nötig (keine neue Section)
- [ ] Visual Parity gegen origin/main (T10) und Klickfläche gegen `assets-src/reference-klickflaeche.png`
- [ ] Kommentar mit SHOP-9 und „deliberate addition to the Nexvo default“ in beiden Dateien
- [ ] Spec-Status von ENTWURF auf FREIGEGEBEN durch Konrad, vor der Umsetzung

### Freigabe und Entscheidungen (Konrad, 15. Oktober 2026)

Plan freigegeben mit drei Entscheidungen. Sie erweitern die Änderungen 1 und 2 um 3 und 4.

- **O1 → E1 Startseite: in diesem PR, Variante E1-a.**
- **O2 → E2 Titel-Hover vereinheitlicht** (Spec R8): Hervorhebung bei Hover über die ganze Kachel.
- **O3 → E3 kein Fokusrahmen** um die ganze Kachel.

Ergänzende Befunde zur Startseite (origin/main `54b5019`):

| # | Aussage | Label |
|---|---|---|
| B40 | Body-Klasse `{{ request.page_type }}-template` → `index-template` auf der Startseite | ✅ `layout/mdm-theme.liquid:115` |
| B41 | `mdm-featured-collection` trägt **auch** die Klasse `featured-collection` (plus `featured-collection--mdm-rv`). Ein Scope `.featured-collection` allein träfe also auch die MDM-Kachel | ✅ `sections/mdm-featured-collection.liquid:69` |
| B42 | Hyper-Kachel rendert Badges und Flash-Sale im Bildbereich, als Geschwister des Bildlinks, ohne `pointer-events`-Regel. Auf der Startseite sind sie sichtbar (im Layer ausgeblendet, B24) | ✅ `snippets/card-product.liquid:175-176`; `snippets/pcard-badges.liquid` (`.product-card__badge`); `config/settings_data.json:67` `pcard_show_sale_badge: true` |
| B43 | Titel-Hover von Hyper: `background-size: 100% var(--reversed-link-gap)`, `background-position-x: var(--transform-origin-start)`, `color: rgb(var(--color-foreground))` an `.reversed-link__text`, nur in `@media (prefers-reduced-motion: no-preference) and (hover: hover) and (pointer: fine)` | ✅ `assets/theme.css:6480-6491` |
| B44 | `brand-overrides.css` pinnt die Titelfarbe der Hyper-Kachel auch im Hover auf `#1E1C17` | ✅ `assets/brand-overrides.css:252-257` |
| B45 | `brand-overrides.css` ist global geladen und geteilter Code aller drei Shops | ✅ `layout/mdm-theme.liquid:64`; Dateikopf `:11-12` |

3. **Startseite (E1-a)** — `assets/brand-overrides.css`, neuer Block am Dateiende, Scope
   `.index-template .featured-collection:not(.featured-collection--mdm-rv)` (B40, B41).
   Dieselben Regeln wie 2a–2e für die Hyper-Kachel, plus:
   - 3f `… :is(.product-card__badge, .product-card__flash-sale)` → `pointer-events: none;` (B42)
   - Kommentar wie bei 1 und 2, mit Verweis auf das gleiche Muster in `mdm-predictive-search.css`.
   - Validierung: T16.

4. **Titel-Hover über die ganze Kachel (E2)** — je Datei ein Zusatz im jeweiligen Scope, im
   selben Media-Query wie Hyper (B43):
   - MDM-Kachel (`mdm-component-product-card.css`):
     `.mdm-product-card:hover .mdm-product-card__title .reversed-link__text` → Hyper-Hover-Werte
     aus B43 (Unterstreichung und Farbe), damit Hover auf Bild, Preis oder Leerraum genauso aussieht
     wie Hover auf dem Titel.
   - Hyper-Kachel (Layer und Startseite): `.product-card:hover .product-card__title .reversed-link__text`
     → nur Unterstreichung (`background-size`, `background-position-x`); die Farbe bleibt durch B44
     ohnehin `#1E1C17`.
   - Spezifität so wählen, dass die Regel die heutige Ruhe-Regel sicher schlägt; im Complete-Artefakt
     belegen.
   - Validierung: T17.

Zusätzliche Testschritte:

| Schritt | Akzeptanz | Vorgehen | Erwartung |
|---|---|---|---|
| T16 | A5 (Startseite), A13 | Startseite, Slider „Unsere Gold Highlights“: `hit()` an Bildecke, Sale-Badge, Titel, Preis, Leerraum unten; Lupe klicken; mit der Maus ziehen. Danach eine Ratgeber-Seite mit Hyper-`featured-collection` | Startseite: PDP überall außer Lupe; Zug navigiert nicht. Ratgeber-Seite: unverändert |
| T17 | A12 | 1440 px, je Bereich: Hover über Bild, Preis, Leerraum unten | Titel jeweils hervorgehoben wie bei Hover direkt auf dem Titel; bei `prefers-reduced-motion: reduce` wie Hyper (keine Animation) |

T0 und T12 erweitern sich auf drei Dateien (`brand-overrides.css` kommt dazu).

### Offene Punkte

- O1–O3: entschieden, siehe oben.
- O4 ❌ Unbekannt: Safari-Unterstützung für `overflow-clip-margin` (F4). Ergebnis aus T2 entscheidet,
  ob der 1-px-Rahmen in Safari als Restabweichung akzeptiert wird.
- O5 ❌ Unbekannt: ob im Layer überhaupt Swatches erscheinen (B32). Regel 2e bleibt trotzdem drin,
  weil das Setting an ist.
- O6 Hinweis zur Referenz: `reference-kachel.png` zeigt noch die Spalte „Weitere Ausgaben“, die
  seit CO-15 entfernt ist (`mdm-card-product.liquid:150`). Für die Klickfläche ohne Belang.
