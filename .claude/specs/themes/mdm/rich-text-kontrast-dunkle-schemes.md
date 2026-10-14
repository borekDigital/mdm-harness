# Spec: Rich-Text-Fließtext auf dunklen Farbschemata lesbar

## Ziel

Fließtext in `.rich-text__text` übernimmt die Subtext-Farbe des Farbschemas, in dem er steht.
Auf dunklen Schemes wird er lesbar (mindestens 4,5:1). Auf `scheme-1` bleibt jede berechnete
Farbe exakt gleich.

## Grundlage

- Befund aus der Validierung von `trust-section-footer-group.md` vom 13. Oktober 2026
- Ausgangsstand: origin/main `dc86009`. Statische Analyse und Laufzeitmessung am
  13. Oktober 2026 (Dev-Server, Store `mdm-muenze`, 1440 px)
- Regel eingeführt mit PR #8, Commit `f110f8a` vom 9. September 2026

## Kontext: Ist-Stand

| Fundstelle | Befund |
|---|---|
| `assets/brand-overrides.css:612-620` | `.rich-text__text, .rich-text__text.text-subtext` setzt `color: #3E3A32`, unabhängig vom Scheme. Kommentar: „defeat .text-subtext so paragraph colour wins“ |
| `assets/brand-overrides.css:621-624` | `.rich-text__text p { color: inherit }`. Absätze übernehmen die Farbe des Wrappers. |
| `assets/theme.css:5384-5386` | `.text-subtext` = `rgba(var(--color-subtext), var(--color-subtext-alpha, 1))`. Wird von 612-620 überstimmt (Spezifität 0,2,0 gegen 0,1,0). |
| `snippets/css-variables.liquid:178-244` | Jedes Scheme setzt `--color-subtext` auf `.color-<scheme>`. Das erste Scheme (`scheme-1`) gilt zusätzlich auf `:root`. |
| `assets/brand-overrides.css:1151-1161` | Kommentar: `#3E3A32` ist der Subtext von scheme-1. Token `--mdm-color-text` ist auf `:root` deklariert. |
| `layout/mdm-theme.liquid:64` | lädt `brand-overrides.css`; `layout/theme.liquid` und `layout/password.liquid` laden die Datei nicht |

### Farbschemata (`config/settings_data.json`)

| Scheme | Hintergrund | Subtext | `#3E3A32` heute | Subtext des Schemes |
|---|---|---|---|---|
| `scheme-1` | `#ffffff` | `#3e3a32` | 11,31:1 | 11,31:1, identisch |
| `scheme-3` | `#d6cab3` | `#3e3a32` | 6,98:1 | 6,98:1, identisch |
| `scheme-info` | `#f6f3ee` | `#615b4f` | 10,22:1 | 6,09:1, **andere Farbe** |
| `scheme-inverse` | `#002147` | `#d6cab3` | **1,42:1** | 9,90:1 |
| `scheme-2` | `#82212e` | `#edd8a4` | **1,19:1** | 6,78:1 |

Kontrast nach WCAG 2.x, berechnet aus den Hex-Werten. Subtext-Alpha zur Laufzeit `1.0`.

## Blast Radius

### Statisch

- ✅ 58 Fundstellen von `rich-text__text` in 54 Liquid-Dateien (`sections/`, `snippets/`),
  davon 17 `mdm-`-Dateien. In `blocks/` und `layout/` gibt es keine.
- ✅ Die 9 Fundstellen in `templates/*.json` stehen im `custom_css` und setzen nur `max-width`.
- ✅ Wirksam auf 76 von 79 Templates (Layout `mdm-theme`). Nicht betroffen sind
  `password.json`, `page.Forms - Hilfeservice.json` (Layout `theme`) und `gift_card.liquid`.
- ✅ Die Regel trifft auch Elemente **ohne** `.text-subtext`, zum Beispiel Slideshow-, Video-
  und Overlay-Beschreibungen, `section-heading` mit `text_color`, `promotion-banner` mit
  `base-text` und `main-order`. Sie alle sind heute auf `#3E3A32` fixiert.
- ✅ Die Regel trifft auch Überschriften in `.rich-text__text`.
  `theme.css:228` setzt sie auf `currentColor` (Spezifität 0,3,0), sie folgen also dem Wrapper.

### Laufzeit auf main `dc86009`

| Seite | Section | Scheme | Anzahl | Farbe heute | Kontrast |
|---|---|---|---|---|---|
| `/` | `rich_text_8c6q4N` | scheme-1 | 1 | `rgb(62,58,50)` | 11,31 |
| `/` | `multicolumn_icon_kqg3wM` (Trust) | scheme-inverse | 4 | `rgb(62,58,50)` | **1,42** |
| `/` | `popup` (overlay-group) | scheme-1 | 1 | `rgb(62,58,50)` | 11,31 |
| `/pages/hilfe` | `mdm_topic_cards`, `mdm_muenzlexikon` | scheme-1 | 7 | `rgb(62,58,50)` | 11,31 |
| `/pages/hilfe` | `mdm_newsletter` | **scheme-info** | 2 | `rgb(62,58,50)` | 10,22 |
| `/pages/uber-mdm` | `mdm_rich_text_*` | scheme-1 | 5 | `rgb(62,58,50)` | 11,31 |
| `/pages/uber-mdm` | `newsletter_n4mQBM` | **scheme-info** | 2 | `rgb(62,58,50)` | 10,22 |
| `/blogs/news` | `rich_text_cnm7jG` | scheme-1 | 1 | `rgb(62,58,50)` | 11,31 |
| `/collections` | `promotion_banner_BJJVBA` | **scheme-2** | 1 | `rgb(62,58,50)` | **1,19** |
| `/collections` | Banner-Tabs, Rich Text, 2× Multicolumn-Icon | scheme-1 | 13 | `rgb(62,58,50)` | 11,31 |
| `/collections/deutschland-muenzen`, `/collections/neuheiten?view=mdm` | — | — | **0** | — | — |
| Produkt, `/search?q=euro`, `/cart` | — | — | 0 | — | — |

- ✅ Der Header (Mega-Menü-Promos mit `scheme-inverse`) rendert auf keiner gemessenen Seite ein
  `.rich-text__text`.
- ✅ Die Trust-Texte enthalten nur `<p>`, kein `<a>`, `<strong>` oder Listen
  (`templates/index.json`, Blöcke von `multicolumn_icon_kqg3wM`).
- ⚠️ Weitere dunkle oder `scheme-info`-Instanzen stehen in Templates mit Nexvo-Demo-Inhalt:
  `product.coming-soon`, `.flash-sale`, `.grid-2-columns`, `.grid-mix`,
  `.horizontal-thumbnails`, `.out-of-stock` und `.product-image-swatch` (Promotion-Banner auf
  scheme-inverse, Image-with-Feature auf scheme-info), außerdem `collection.banner-top-with-cards`
  (Bildkarten auf scheme-inverse) und `page.unternehmen.json` (Newsletter auf scheme-info).
- ❌ Ob diese Templates im Store zugewiesen sind, lässt sich nur im Admin prüfen.

### Probe

Die Zielregel wurde als Style in die Seiten injiziert, ohne Code-Änderung. Ergebnis:
Trust `rgb(214,202,179)`, `/collections`-Banner `rgb(237,216,164)`, alle scheme-1-Elemente
unverändert `rgb(62,58,50)`, Newsletter auf scheme-info `rgb(97,91,79)`.

## Entscheidung E1: scheme-info

Kein Theme-Wert liefert auf scheme-1 **und** auf scheme-info `#3E3A32`. Auf scheme-1 ist
`#3E3A32` der Subtext (Text ist `#1e1c17`), auf scheme-info ist es der Text (Subtext ist
`#615b4f`). Beides zugleich geht nur mit Scheme-IDs im Selektor.

| | Variante A: Subtext für alle Schemes (**empfohlen**) | Variante B: nur dunkle Schemes |
|---|---|---|
| scheme-1, scheme-3 | unverändert | unverändert |
| scheme-inverse, scheme-2 | lesbar (9,90 / 6,78) | lesbar (9,90 / 6,78) |
| scheme-info | `#3E3A32` → `#615B4F`, 10,22 → 6,09:1. Live: 4 Elemente, Newsletter auf `/pages/hilfe` und `/pages/uber-mdm` | unverändert |
| Scheme-IDs im CSS | keine | `scheme-inverse` und `scheme-2`, je auch mit `desktop-`/`mobile-`-Präfix |
| neues dunkles Scheme | greift automatisch | muss nachgetragen werden |

Für A spricht: Die Farbe kommt aus dem Theme-Editor statt aus dem CSS, entspricht der Regel
„keine hartcodierten Farben“ und bleibt bei AA. B entspricht dem Muster der Überschriften-Regel
`brand-overrides.css:658-686`.

**Entschieden am 13. Oktober 2026 durch Konrad: Variante A.**

## Anforderungen

- [x] R1 Der Text eines `.rich-text__text`-Elements und seiner Absätze hat die Subtext-Farbe des
      nächstgelegenen Farbschemas, auf allen Schemes (E1: Variante A).
- [x] R2 Auf scheme-1 und scheme-3 bleibt die berechnete Farbe jedes `.rich-text__text`-Elements
      und seiner Absätze `rgb(62, 58, 50)`.
- [x] R3 Auf scheme-inverse und scheme-2 hat Fließtext in `.rich-text__text` mindestens
      4,5:1 Kontrast zum Hintergrund.
- [x] R4 Auf scheme-info hat der Text die Subtext-Farbe des Schemes (`#615B4F`) mit mindestens
      4,5:1 Kontrast (E1: Variante A).
- [x] R5 Schriftfamilie, -gewicht, -größe und Zeilenhöhe bleiben unverändert. Nur die Farbe
      ändert sich.
- [x] R6 Die geänderte Deklaration enthält keinen Farbwert. Die Farbe kommt aus einer
      Theme-Variable, die am Element selbst aufgelöst wird.
- [x] R7 Der Kommentar über der Regel beschreibt das neue Verhalten. Die Begründung „defeat
      .text-subtext“ entfällt oder wird ersetzt.

## Akzeptanzkriterien

### Messverfahren

Dev-Server `shopify theme dev --store=mdm-muenze.myshopify.com --port=9292`, vorher auf main
und nachher auf dem Branch, auf demselben Dev-Theme, bei 1440 px und 375 px.
Ein Messskript erfasst für jedes `.rich-text__text`:

- Section-ID und nächste `color-scheme-*`-Klasse
- berechnete Farbe des Elements und seines ersten `<p>`
- ersten deckenden Hintergrund der Vorfahren
- Kontrast nach WCAG 2.x

| AC | Kriterium | Erwartet | Req |
|---|---|---|---|
| A1 | `/`: die 4 Trust-Elemente und ihre `<p>` haben mindestens 4,5:1 auf `rgb(0,33,71)`, bei 1440 und 375 px | `rgb(214,202,179)`, 9,90:1 | R1, R3 |
| A2 | `/collections`: `promotion_banner_BJJVBA` hat mindestens 4,5:1 auf `rgb(130,33,46)` | `rgb(237,216,164)`, 6,78:1 | R1, R3 |
| A3 | alle scheme-1-Elemente aus der Laufzeittabelle (`/`, `/pages/hilfe`, `/pages/uber-mdm`, `/blogs/news`, `/collections`): Element und `<p>` vorher und nachher gleich, Anzahl je Seite gleich | `rgb(62,58,50)` | R2 |
| A4 | `/collections/deutschland-muenzen`, `/collections/neuheiten?view=mdm`, Produkt, Suche, Warenkorb: Anzahl `.rich-text__text` vorher = nachher | 0. Ist `feat/trust-section-footer-group` bereits gemergt, kommen genau die 4 Trust-Elemente hinzu und erfüllen A1. | R2 |
| A5 | Newsletter auf `/pages/hilfe` und `/pages/uber-mdm` (je 2 Elemente) | `rgb(97,91,79)`, 6,09:1 | R4 |
| A6 | auf keiner gemessenen Seite liegt ein `.rich-text__text` unter 4,5:1 | — | R3 |
| A7 | `font-family`, `font-weight`, `font-size`, `line-height` aller gemessenen Elemente vorher = nachher | — | R5 |
| A8 | Diff gegen origin/main ändert nur `assets/brand-overrides.css`. Hinzugefügte Deklarationen enthalten kein Farbliteral (Hex, `rgb(` mit Zahl, Farbname). | — | R6 |
| A9 | Code-Review: Kommentar und Regel stimmen überein | — | R7 |
| A10 | `shopify theme check --output json` in sauberen Worktrees, main gegen Branch: Findings nach Datei, Check und Zeile identisch | 37 Errors / 22 Warnings (✅ geprüft auf `dc86009`), keines in `brand-overrides.css` | — |
| A11 | `validate_theme` (Shopify Dev MCP) für `assets/brand-overrides.css` | gültig | — |

## Constraints

- Theme-First: Es ändert sich keine Nexvo-Datei. `brand-overrides.css` ist die MDM-Override-Datei
  (`brand-overrides.css:8-9`). Keine Liquid-Änderung, also keine `mdm-`-Kopie nötig.
- Keine hartcodierten Farben (`liquid-conventions.md`). Die Farbe muss am Element aufgelöst
  werden, zum Beispiel `rgba(var(--color-subtext), var(--color-subtext-alpha, 1))`.
  ✅ `--mdm-color-text` (`brand-overrides.css:1158`) eignet sich nicht. Es ist auf `:root`
  deklariert und erbt deshalb überall den scheme-1-Wert.
- `settings_data.json` bleibt unverändert. Den Subtext von scheme-info anzupassen würde alle
  anderen `.text-subtext` auf diesem Scheme mitändern.
- Blast Radius: shopweit, 76 Templates. Nach dem Merge sofort live, weil main per
  GitHub-Integration synchron ist.
- Ein PR, ein Thema: Branch von origin/main, PR gegen main.
- ✅ Unabhängig von `feat/trust-section-footer-group`, die beiden Branches ändern keine
  gemeinsame Datei.
- ⚠️ Empfehlung: diesen Fix vor oder zusammen mit dem Trust-Branch mergen. Sonst steht die
  unlesbare Trust-Section auf allen Seiten.
  - **Überholt am 13. Oktober 2026:** Der Trust-Branch ist als PR #41 gemergt (`9d8f3d2`).
    Der Fix ist damit dringend. Der Fix-Branch wurde per Fast-Forward auf origin/main
    `292d777` gebracht, die Änderung bleibt uncommittet. Die Trust-Texte im Footer messen mit
    Fix 9,90:1.
- Nur MDM-Theme.
- ✅ Borek und IMM haben auf ihrem lokalen origin/main-Stand keine `.rich-text__text`-Regel in
  `brand-overrides.css`.

## Nicht Teil dieser Spec

- **F1** Harte Farben für `.rte`-Kindelemente in `brand-overrides.css`, die auf dunklen Schemes
  ebenfalls unlesbar wären:
  - `strong` `#1E1C17` (460-463), etwa 1,1:1 auf `#002147`
  - `a` `#002147` und `#2C4767` (470-481), 1:1 auf `#002147`
  - `ul`/`ol` `#3E3A32` (484-491)
  - `li::marker` (497-499)
  - `blockquote` (502-511)
  - `td` (546-552)
  - ~~`h5`/`h6` `#615B4F` (413-421)~~ Korrektur: Auf dunklen Schemes sind sie durch
    `:658-686` weiß.

  Heute gibt es keine Instanz dieser Elemente auf einem dunklen Scheme. Sie entstehen aber,
  sobald jemand im Editor einen Link oder Fettdruck in den Trust-Text setzt.
  → Eigene Spec: `rte-inhalte-dunkle-schemes.md`. Sie umfasst auch `.rte p` (`:454`).
- Weitere harte `#3E3A32`-Werte außerhalb von `.rich-text__text` (`brand-overrides.css:836`,
  `871`)
- Nexvo-Demo-Inhalte in `list-collections.json` (`/collections`, englische Texte)
- Verwaiste Scheme-Referenzen (`scheme-9` bis `scheme-12`)

## Offene Punkte

- ~~O1 Entscheidung E1 (Variante A oder B) durch Konrad~~ — erledigt, Variante A
- O2 Sind die Produkt-Demo-Templates, `collection.banner-top-with-cards` und
  `page.unternehmen.json` im Store zugewiesen? Ändert nichts an der Spec, aber an der
  Zahl betroffener Live-Seiten.

## Validierung — 13. Oktober 2026

Branch `fix/rich-text-dark-scheme-contrast` auf origin/main `dc86009`, eine Datei geändert
(`assets/brand-overrides.css`, +5/−2). Dev-Server vorher (Branch ohne Änderung, also gleich
main) und nachher auf demselben Dev-Theme. 10 Seiten bei 1440 und 375 px, also 20
Messpunkte, jedes `.rich-text__text` einzeln verglichen.

| AC | Ergebnis |
|---|---|
| A1 | erfüllt: Trust `#3e3a32` → `#d6cab3`, Element und `<p>`, 1,42 → 9,90:1, bei 1440 und 375 px |
| A2 | erfüllt: `promotion_banner_BJJVBA` `#3e3a32` → `#edd8a4`, 1,19 → 6,78:1 |
| A3 | erfüllt: alle 28 scheme-1-Elemente vorher und nachher `#3e3a32`, Anzahl je Seite gleich |
| A4 | erfüllt: Kollektionen, Produkt, Suche, Warenkorb vorher und nachher 0 Elemente |
| A5 | erfüllt: Newsletter `/pages/hilfe` und `/pages/uber-mdm` `#3e3a32` → `#615b4f`, 6,09:1 |
| A6 | erfüllt: niedrigster Wert nachher 6,09:1 (vorher 1,19:1) |
| A7 | erfüllt: Schriftfamilie, -gewicht, -größe und Zeilenhöhe von Element und `<p>` auf allen 20 Messpunkten gleich |
| A8 | erfüllt: nur `brand-overrides.css` geändert, kein Farbliteral in Deklarationen |
| A9 | erfüllt: theme-reviewer und security-reviewer APPROVED, keine Findings |
| A10 | erfüllt: 37 Errors / 22 Warnings auf main und Branch, Findings nach Datei, Check und Zeile identisch |
| A11 | erfüllt: `validate_theme` gültig |

Der Vorher/Nachher-Vergleich zeigt außer A1, A2 und A5 keine Abweichung, weder bei Scheme
noch bei Hintergrund oder Typografie.

Hinweise aus den Reviews, nicht blockierend:

- Der Selektor `.rich-text__text.text-subtext` ist jetzt wertgleich mit `.text-subtext`. Er
  bleibt stehen, weil Entfernen über die Spec hinausginge.
- Die Subtext-Transparenz kommt aus dem Scheme, heute 1,0. Das verhält sich wie
  `.text-subtext` und `.rich-text__subheading`.
- Kein Fallback-Wert in `var()`. `:root` trägt immer die scheme-1-Variablen
  (`css-variables.liquid:180-182`); verwaiste Schemes erben deshalb den scheme-1-Wert.
- Text über Bildern ohne `.text-subtext` (Slideshow, Overlay) folgt jetzt dem
  Section-Scheme. Auf scheme-1 ist das identisch.

## Status

VALIDIERT — 13. Oktober 2026 (Variante A, Reviews APPROVED). Nicht committet.
