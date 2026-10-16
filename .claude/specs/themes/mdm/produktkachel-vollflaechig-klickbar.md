# Spec: Produktkachel — vollflächig klickbar

## Ziel

Die Produktkachel öffnet die Produktdetailseite, egal wo innerhalb der Kachel geklickt wird —
auch auf Rahmen, Bildinnenabstand, Preis, MwSt.-Zeile und Leerraum unter dem Inhalt. Heute
reagieren nur Bild und Titel.

## Grundlage

- Ticket SHOP-9 „Produktkachel vollständig klickbar“ (Story, Priorität High), angelegt von
  Kerstin Meyer am 13. Oktober 2026. Referenzbilder:
  `Tickets/In-progress/SHOP-9/assets-src/reference-klickflaeche.png` (blau = gewünschte
  Klickfläche, schraffiert = Leerraum unten) und `reference-kachel.png`.
- Akzeptanzkriterien des Tickets, wörtlich zusammengefasst: ganze Kachel klickbar, auch
  außerhalb von Bild und Text; gilt für Kategorie-/Collection-Übersicht,
  Suchergebnisseite, Suchvorschlagslayer und Produktslider „wie z. B. Ähnliche Produkte,
  Zuletzt angesehene Produkte“.
- Vorgeschichte: Als C1 in `plp-card-nexvo-default.md` zurückgestellt, weil kein
  Nexvo-Default. Mit SHOP-9 ist die fachliche Entscheidung gefallen: umsetzen.

## Ist-Stand — origin/main `54b5019`

### ✅ Belegt: Klickbar sind nur Bild und Titel

`snippets/mdm-card-product.liquid` enthält zwei Links auf die PDP: den Bildlink (`:100`)
und den Titellink (`:161`). Der Bildlink sitzt absolut **innerhalb** des Bildinnenabstands
(`assets/mdm-component-product-card.css:87-91`, `inset: var(--mdm-pcard-media-padding)` =
2 rem, mobil 1,2 rem). Nicht klickbar sind damit: Innenabstand rund ums Bild, Typ-Badge,
Preiszeile, MwSt.-Zeile, 30-Tage-Preis, Innenabstand des Inhalts und der Leerraum, der
entsteht, weil die Kachel in der Grid-Zeile auf volle Höhe gestreckt wird
(`mdm-component-product-card.css:37`, `height: 100%`).

### ✅ Belegt: Zwei verschiedene Kacheln im Geltungsbereich

| Bereich laut Ticket | Section / Snippet | Kachel | CSS-Scope |
|---|---|---|---|
| Kategorie-Übersicht | `sections/mdm-main-collection-product-grid.liquid:221` | `mdm-card-product` | `.mdm-collection-grid` |
| Suchergebnisseite | `sections/mdm-main-search.liquid:168` | `mdm-card-product` | `.mdm-search-results` |
| Ähnliche Produkte | `sections/mdm-related-products.liquid:82` | `mdm-card-product` | `.featured-collection--mdm-rv` |
| Zuletzt angesehen | `sections/mdm-recently-viewed-products.liquid:68` | `mdm-card-product` | `.featured-collection--mdm-rv` |
| weitere PDP-Slider | `sections/mdm-similar-products.liquid:232`, `sections/mdm-featured-collection.liquid:232` | `mdm-card-product` | `.featured-collection--mdm-rv` |
| Suchvorschlagslayer (Header und Suchseite) | `snippets/mdm-predictive-search.liquid:108` (Empfehlungen) und `:179` (Treffer) | **`card-product` (Hyper-Original)** | `.mdm-predictive-card` |

Der Suchvorschlagslayer rendert die unveränderte Hyper-Kachel in einem Wrapper
`.mdm-predictive-card` (`assets/mdm-predictive-search.css:6-9`). Die Hyper-Kachel hat
Bildlink (`snippets/card-product.liquid:117`, `tabindex="-1"`) und Titellink (`:315-320`).

### ✅ Belegt: Interaktive Elemente in der Kachel, die erhalten bleiben müssen

- Quick-View-Button: in beiden Kacheln, global eingeschaltet
  (`config/settings_data.json:65`, `pcard_show_quickview_button: true`;
  `mdm-card-product.liquid:138-148`). Nur ab 768 px sichtbar.
- Hyper-Kachel zusätzlich, je nach Setting: Warenkorb-Button (`pcard_show_cart_button`,
  heute `false`, `settings_data.json:64`), Farb-Swatches (`pcard_enable_color_swatches`,
  heute `true`, `:69`), Hersteller- und Typ-Link (`predictive_search_show_vendor/type`,
  heute `false`, `:94-95`). Vergleichs-Checkbox nur mit Parameter
  `enable_compare_checkbox`, den der Suchvorschlagslayer nicht übergibt.

### ✅ Belegt: Hover-Verhalten hängt am Bildbereich

Zweitbild-Wechsel und Einblenden des Quick-View-Buttons lösen bei `:hover` auf dem
Bildbereich aus (`mdm-component-product-card.css:113-123`; Hyper:
`assets/theme.css:4458-4473` auf `.product-card__image-wrapper:hover`). Der Kachel-Lift
hängt an `:hover` der ganzen Kachel (`mdm-component-product-card.css:44-47`).

## Anforderungen

- [ ] R1 Ein Klick an jeder Stelle innerhalb der sichtbaren Kachelfläche öffnet die PDP des
      Produkts — einschließlich Rahmen, Bildinnenabstand, Typ-Badge, Preis, MwSt.-Zeile,
      30-Tage-Preis und Leerraum unten.
- [ ] R2 Ausnahme: Eigene Bedienelemente in der Kachel behalten ihre Funktion — vor allem der
      Quick-View-Button. Ein Klick darauf öffnet Quick-View und **nicht** die PDP. Gleiches
      gilt für Warenkorb-Button, Swatches und Hersteller-/Typ-Link, sobald sie per Setting
      eingeschaltet werden.
- [ ] R3 Die Kachel bleibt ein echter Link: Mittelklick, Cmd-/Strg-Klick und Rechtsklick
      „Link in neuem Tab öffnen“ funktionieren überall auf der Fläche. Keine
      JavaScript-Weiterleitung.
- [ ] R4 Gilt in allen sechs Bereichen der Tabelle oben, einschließlich Suchvorschlagslayer,
      und in den Produkt-Slidern der Startseite (Entscheidung E1).
- [ ] R5 Bestehendes Verhalten bleibt: Zweitbild beim Hover über das Bild (ab 768 px),
      Einblenden des Quick-View-Buttons, Kachel-Lift, Titel-Unterstreichung beim Hover.
- [ ] R6 Tastatur und Screenreader: Keine zusätzlichen Links oder Tab-Stopps pro Kachel.
      Der Fokusrahmen bleibt sichtbar.
- [ ] R7 Aussehen unverändert: keine Verschiebung von Abständen, Größen oder Farben.
- [ ] R8 Hover über eine beliebige Stelle der Kachel (auch über das Bild) zeigt dieselbe
      Titel-Hervorhebung wie heute der Hover über den Titel (Entscheidung E2). Nur auf Geräten
      mit Maus, wie bei Hyper.

## Akzeptanzkriterien

Geprüft auf dem Dev-Server (Store `mdm-muenze`), 1440 px und 375 px.

- [ ] A1 Kategorie-Seite (z. B. `/collections/deutschland-muenzen`): Klick auf Rahmen,
      Bildinnenabstand, Preis, MwSt.-Zeile und Leerraum unten öffnet jeweils die PDP. (R1)
- [ ] A2 Per `document.elementFromPoint` an fünf Punkten je Kachel (Bildrand, Badge, Preis,
      MwSt.-Zeile, Leerraum unten): das getroffene Element ist ein `<a>` mit `href` der PDP
      oder liegt in einem solchen. (R1)
- [ ] A3 Klick auf den Quick-View-Button (1440 px) öffnet das Quick-View-Modal, die Seite
      bleibt. (R2)
- [ ] A4 Cmd-Klick auf den Leerraum unten öffnet die PDP in einem neuen Tab. (R3)
- [ ] A5 A1 und A3 wiederholt auf: Suchergebnisseite (`/search?q=maja`), PDP-Slider
      „Ähnliche Produkte“ und „Zuletzt angesehen“, Suchvorschlagslayer im Header
      (Empfehlungen ohne Suchbegriff und Treffer nach Eingabe), Startseiten-Slider
      (z. B. „Unsere Gold Highlights“), dort auch Klick auf ein Sale-Badge. (R4)
- [ ] A6 Hover über das Bild zeigt das Zweitbild und den Quick-View-Button; Hover über
      Preis oder Leerraum zeigt den Kachel-Lift. (R5)
- [ ] A7 Im Slider löst ein Ziehen mit der Maus keine Navigation aus. (R4, R5)
- [ ] A8 Tab-Reihenfolge pro Kachel unverändert gegenüber origin/main (Anzahl Tab-Stopps
      gleich). (R6)
- [ ] A9 Screenshot-Vergleich je Bereich gegen origin/main: keine sichtbare Abweichung im
      Ruhezustand. (R7)
- [ ] A10 Kein Diff an Hyper-Kerndateien (`snippets/card-product.liquid`,
      `assets/theme.css`), an `templates/*.json` und an `config/settings_data.json`.
- [ ] A12 1440 px: Hover über Bild, Preis und Leerraum unten hebt jeweils den Titel hervor
      wie ein Hover direkt auf dem Titel — in allen Bereichen aus R4. (R8)
- [ ] A13 Ratgeber-Seiten mit Hyper-`featured-collection` (`page.*.json`), Mega-Menü und
      Menü-Drawer: unverändert, dort nur Bild und Titel klickbar. (Blast-Radius)
- [ ] A11 `shopify theme check --fail-level error`: keine neuen Findings gegenüber
      origin/main. `validate_theme` ohne Fehler für alle geänderten Dateien.

## Constraints

- **Theme-First:** Kein neuer Snippet-Nachbau, keine Änderung an Hyper-Originalen. Die
  Hyper-Kachel im Suchvorschlagslayer wird nur über den bestehenden MDM-Wrapper
  `.mdm-predictive-card` angepasst.
- **Blast-Radius:** Nur die sechs Bereiche oben plus die Hyper-`featured-collection` auf der
  Startseite (Scope über die Body-Klasse `index-template`, `layout/mdm-theme.liquid:115`). Die
  gleiche Section steckt in rund 20 weiteren Templates (Ratgeber-Seiten) — dort unverändert. `mdm-card-product` wird außerdem im
  Mega-Menü (`snippets/mdm-mega-menu.liquid:415`) und im Menü-Drawer
  (`snippets/mdm-menu-drawer-details.liquid:340`) gerendert — dort liegt die Kachel
  außerhalb der drei CSS-Scopes und bleibt unverändert. Ebenso unverändert: alle Stellen,
  die `card-product` ohne `.mdm-predictive-card` rendern.
- **Bhavani-Absprache:** Vollflächiger Klick ist ein bewusster Zusatz zum Nexvo-Default,
  kein Rückbau. Er wird im Code dokumentiert (Kommentar mit Ticket-ID), damit er bei
  einem späteren Rückbau auffindbar bleibt.
- Nur MDM-Theme in diesem PR. Port nach Borek/IMM über `theme-sync`, siehe Übergabe.
  `assets/brand-overrides.css` ist geteilter Code aller drei Shops — die Startseiten-Regel
  wirkt nach dem Sync auch dort.
- Keine neuen Texte, keine neuen Settings, kein JavaScript.

## Entscheidungen (Konrad, 15. Oktober 2026)

- **E1 — Startseiten-Slider: in diesem PR.** `templates/index.json` enthält fünf Sections
  `featured-collection` (Hyper-Original, z. B. „Unsere Empfehlungen für Sie“,
  „Unsere Gold Highlights“). Sie rendern `card-product`, nicht die MDM-Kachel. Umsetzung als
  Variante E1-a aus dem Block-Plan (Scope Startseite, `assets/brand-overrides.css`).
- **E2 — Titel-Hover vereinheitlicht.** Die Titel-Hervorhebung erscheint bei Hover über die
  ganze Kachel, nicht nur über den Titel (R8).
- **E3 — Kein Fokusrahmen um die ganze Kachel.** Fokus bleibt am Titellink (R6, R7).

## Nicht Teil dieser Spec

- Mega-Menü und Menü-Drawer (siehe Blast-Radius).
- Der doppelte Link pro MDM-Kachel (Bildlink ohne `tabindex="-1"`, anders als Hyper) —
  Nebenbefund, eigener Punkt.
- Weitere Rückbau-Punkte aus `plp-card-nexvo-default.md`.

## Dateien (voraussichtlich, Details im Block-Plan)

- `themes/mdm/assets/mdm-component-product-card.css`
- `themes/mdm/assets/mdm-predictive-search.css`
- `themes/mdm/assets/brand-overrides.css` (Startseite, E1)
- Block-Plan: `Tickets/In-progress/SHOP-9/plans/SHOP-9-block-produktkachel-vollflaechig-plan.md`

## Status

FREIGEGEBEN — 15. Oktober 2026 (Konrad, mit E1–E3)
IMPLEMENTIERT — 15. Oktober 2026, Branch `feat/product-card-full-click`, Nachweise in
`Tickets/In-progress/SHOP-9/plans/SHOP-9-block-produktkachel-vollflaechig-complete.md`
