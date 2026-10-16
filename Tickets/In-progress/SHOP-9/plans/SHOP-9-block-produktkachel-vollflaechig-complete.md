## Block abgeschlossen: produktkachel-vollflaechig

Ticket SHOP-9, Marke MDM, 15. Oktober 2026.
Spec: `.claude/specs/themes/mdm/produktkachel-vollflaechig-klickbar.md` (FREIGEGEBEN mit E1–E3).
Plan: `SHOP-9-block-produktkachel-vollflaechig-plan.md`.

Worktree `themes/.worktrees/mdm-card-full-click`, Branch `feat/product-card-full-click`
(ohne Upstream), Basis origin/main `762ca89`. Nicht committet.

### Ergebnis

Die Produktkachel ist an jeder sichtbaren Stelle ein Link auf die PDP. Das gilt in Kategorie,
Suchseite, Suchvorschlagslayer, den PDP-Slidern und den Startseiten-Slidern. Die Umsetzung
besteht nur aus CSS, ohne Liquid, JS oder JSON und ohne Hyper-Kerndatei.

| Datei | Inhalt |
|---|---|
| `assets/mdm-component-product-card.css` (+57/−1) | MDM-Kachel: Stretched Link am Titel (`z-index: 1`), Bildbereich `z-index: 2`, `::before` am Bildlink für den Innenabstand, Badge `pointer-events: none`, 1-px-Rahmen per `overflow-clip-margin`, Titel-Hover über die ganze Kachel |
| `assets/mdm-predictive-search.css` (+43) | Hyper-Kachel im Layer: Titel `position: static`, Stretched Link, Bildbereich und Bedienelemente `z-index: 2`, Titel-Hover |
| `assets/brand-overrides.css` (+54) | Startseite (Scope `.index-template .featured-collection:not(.featured-collection--mdm-rv)`): wie Layer, zusätzlich Badges und Flash-Sale `pointer-events: none` |

### Abweichung vom Plan (Revision 1)

- **B33 war falsch.** Der Plan nahm an, die Preis-Teile der Hyper-Kachel seien nicht
  positioniert. ✅ Tatsächlich setzt `assets/theme.css:2887-2893` `.f-price { position: relative }`.
  Ein positioniertes Element mit `z-index: auto` wird über einen Stretched Link ohne z-index
  gemalt, wenn es im DOM später kommt. Im Layer waren 12 von 42 Messpunkten tot (Preis,
  Leerraum unten).
- **Lösung, in allen drei Dateien gleich:** Die Klickfläche bekommt `z-index: 1`. Bildbereich,
  Hersteller-/Typ-Links und Swatches bekommen `z-index: 2` statt 1. Damit liegt die Fläche über
  jedem positionierten Inhalt der Kachel, und die Bedienelemente liegen weiter darüber.
- Mitgenommen aus den Reviews:
  - Security F1: „agreed with Bhavani“ aus allen Kommentaren entfernt, weil das CSS öffentlich
    ausgeliefert wird.
  - Theme-Review M1: Kommentar an `overflow-clip-margin`.
  - Theme-Review M2: doppelte Leerzeile.

### Reviews

| Review | Verdict | Findings |
|---|---|---|
| theme-reviewer (statisch) | APPROVED | 4 nits: M1, M2 umgesetzt; M3 latent (siehe Restpunkte); M4 Port-Hinweis |
| security-reviewer | APPROVED | F1 minor (Personenname im CSS), umgesetzt. Keine Clickjacking-Pfade; alle globalen Overlays liegen bei z ≥ 8 |

### Validierung

Laufzeit im Dev-Server `127.0.0.1:9293` (Worktree), Chrome. Messung per `elementFromPoint`;
ein Punkt gilt als bestanden, wenn er im PDP-Link der Kachel landet bzw. beim Quick-View-Button
im Button.

| Bereich | Viewport | Kacheln | Punkte | Ergebnis |
|---|---|---|---|---|
| Kategorie `/collections/deutschland-muenzen` | 1440 | 4 | 34 | ✅ 34/34 (Rahmen, Bildinnenabstand, Bild, Badge, Preis, MwSt., Leerraum, Lupe) |
| Kategorie | 375 | 6 | 44 | ✅ 44/44 (inkl. mobile 30-Tage-Zeile) |
| Suchseite `/search?q=maja` | 1440 | 8 | 67 | ✅ 67/67 |
| PDP „Ähnliche Produkte“ | 1440 | 4 | 32 | ✅ 32/32 |
| PDP „Zuletzt angesehen“ | 1440 | 1 | 9 | ✅ 9/9 |
| Suchvorschlagslayer (Treffer „maja“) | 1440 | 5 | 47 | ✅ 47/47 (vor Revision 30/42) |
| Startseiten-Slider (echte Hyper-Kacheln eingesetzt, s. u.) | 1440 | 4 | 39 | ✅ 39/39, alle 6 Sale-/Neu-Badges lassen durch |
| Gegenprobe: gleiche Kacheln ohne `index-template` (= Ratgeber-Seite) | 1440 | 4 | 39 | ✅ altes Verhalten: Preis, Badge und Leerraum nicht klickbar (A13) |

Weitere Prüfungen:

- ✅ Quick-View öffnet den Drawer, die URL bleibt (Implementer, Grid).
- ✅ Hover über das Bild zeigt Zweitbild und Lupe, Hover über Preis zeigt beides nicht. Gemessen
  im Grid (Implementer) und im Layer (nach Ende der Transition, Zweitbild-Opacity 1, Lupe 1).
- ✅ Titel-Hover über Preis bzw. Bild ist identisch zum direkten Titel-Hover: im Grid
  (Implementer, 6 Stellen), im Layer (`background-size: 100% 1px`).
- ✅ Slider-Zug mit der Maus navigiert nicht. Drei Züge im Slider „Ähnliche Produkte“
  (Implementer). Grund: Swiper `preventClicks`.
- ✅ Sticky-Header, Sticky-Leiste und Toolbar liegen über den Kacheln. Wo eine Kachel darunter
  liegt, trifft der Klick die Leiste (9 Messpunkte).
- ✅ Tab-Reihenfolge ist unverändert. Das ist durch Konstruktion belegt: kein Markup geändert,
  Pseudo-Elemente sind nicht fokussierbar.
- ✅ `shopify theme check`: 64 Findings vorher wie nachher, 0 in den drei Assets.
- ✅ `validate_theme`: VALID für die drei Dateien.

Testhinweise (Messartefakte, keine Befunde):

- **Suchvorschlagslayer im Dev-Server:** Die Vorschläge werden absolut von
  `mdm-muenze.myshopify.com/search/suggest` geholt, und CORS blockt das auf `127.0.0.1`. Für
  den Test wurde dieselbe URL über den Dev-Server geholt und in den Layer eingehängt.
- **Startseite:** Alle fünf `featured-collection`-Sections zeigen im Dev-Store Platzhalter-Kacheln.
  Die hinterlegten Kollektionen liefern 0 Produkte (`/collections/<handle>/products.json`). Für den
  Test wurden echte Hyper-Kacheln aus dem Layer in den Slider eingesetzt.
- **Verborgenes Browser-Pane:** `content-visibility: auto` an `.f-column` (Theme) und keine Frames
  im verborgenen Pane führen nach dem Scrollen zu veralteten Treffern. Abhilfe: Frame per
  Screenshot erzwingen, oder `content-visibility` nur im Test abschalten.

### Restpunkte

- ❌ **Safari (O4):** `overflow-clip-margin` ungeprüft. Im schlimmsten Fall ist dort die
  1-px-Rahmenlinie nicht klickbar.
- ❌ **Nicht ausgeführt:**
  - T10 Screenshot-Parität. Durch Konstruktion erwartet keine Ruhezustands-Änderung, weil keine
    sichtbaren Eigenschaften hinzukommen.
  - T4 Cmd-Klick. Echter `<a>`, das Browser-Standardverhalten greift.
  - Mobil-Wischen im Slider.
- ⚠️ **Slider-Rahmen:** Die obere und untere 1-px-Rahmenzeile wird schon heute von Swiper
  (`overflow: hidden`) abgeschnitten und ist dort weder sichtbar noch klickbar. Bestand, nicht
  Teil dieser Änderung.
- ⚠️ **Latent (M3):** Würden Warenkorb-Button und Listen-Modus der Hyper-Kachel eingeschaltet,
  lägen `.product-card__list-actions` unter der Klickfläche. Heute ist das in keinem der Scopes
  aktiv.
- ⚠️ **Nebenbefund Startseite:** Die fünf Startseiten-Slider und die Ratgeber-Seiten verweisen
  auf Kollektionen ohne Produkte im Online-Store (0 Produkte per `products.json`). Ob der Live-Shop
  dort ebenfalls Platzhalter zeigt, ist ungeprüft.

### Übergabe

- **Port Borek/IMM:**
  - `mdm-component-product-card.css` und `mdm-predictive-search.css` sind dort identisch zur
    MDM-Basis.
  - `brand-overrides.css` weicht nur um den Kopfkommentar aus PR #51 ab.
  - Die Theme-Sync-CI (`THEME_SYNC_ENABLED`) öffnet nach dem Merge den PR `sync/theme-mdm`.
    Borek/IMM-`main` sind veröffentlichte Themes: Merge = live.
- Dev-Server läuft noch (Port 9293, PID 58343). Das Entwicklungs-Theme #189649617277 im Store
  ist unveröffentlicht.
