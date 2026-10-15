# Spec: Templates angleichen — MDM als Vorlage für Borek und IMM (PLP, PDP)

## Ziel

Borek und IMM nutzen auf Kollektions- und Produktseiten exakt dieselben JSON-Templates wie
MDM: dieselben Sections, in derselben Reihenfolge, mit denselben IDs und Namen. Nur der
`layout`-Schlüssel bleibt markenspezifisch. Damit greifen CSS-Overrides, die für eine
`mdm-`Section geschrieben werden, in allen drei Shops.

## Grundlage

- Call Konrad Thiemann / Bhavani Govindan (UI/UX) am 15. Oktober 2026, 14 Minuten.
  Zusammenfassung und bereinigtes Transkript im Artefakt „Templates angleichen“.
- Freigabe: Auftrag von Konrad im Chat am 15. Oktober 2026 („daraus einen Plan / eine Spec
  erstellen und die Aufgaben umsetzen“). Commits und Merges macht Konrad.

### Entscheidungen aus dem Call

| Nr. | Entscheidung |
|---|---|
| E1 | Templates aller drei Shops werden identisch — gleiche Sections, gleiche Reihenfolge, gleiche Benennung. Vorlage ist MDM. |
| E2 | Ausgenommen sind markenspezifische Werte: Footer (Adresse, Telefon, Logos) und Ähnliches. Sie liegen in `sections/footer-group.json` / `header-group.json` und werden nicht angefasst. |
| E3 | Reihenfolge: erst PLP, dann PDP, dann die übrigen Seiten (FAQ, Content-Seiten). |
| E4 | Vor dem Kopieren muss das MDM-Template sauber sein: leere „Vertrauens-Box“ raus, „Mehr anzeigen“ in Subtext-Farbe. |
| E5 | „Mehr anzeigen“ bekommt die **Subtext-Farbe** des Farbschemas (nicht Textfarbe, nicht `#002147`). Kein eigener Hover-Farbwechsel — die Unterstreichungs-Animation ist das Feedback. |
| E6 | Code verwendet die Farbvariablen der Theme-Settings (Text, Subtext) statt fester Hex-Werte. |
| E7 | Theme-CSS (FoxEcom-Kern) bleibt unverändert; Änderungen nur per Override oder in `mdm-`Liquid. |

## Kontext — Ist-Stand

Stand: MDM origin/main `a1f767d`, Borek origin/main `2d86563`, IMM origin/main `8f9f541`.

### Code ist gleich, Templates nicht

- ✅ 640 gemeinsame Dateien in `assets/ sections/ snippets/ blocks/ layout/`, abweichend nur
  `assets/mdm-collection.css` (PR #45) und `assets/mdm-section-collection-hero.css` (PR #46),
  beide heute in MDM gemergt und noch nicht portiert. Dazu markenspezifisch
  `config/settings_schema.json` (`page_width` Text gegen Range) und die Gruppen-Dateien.
- ✅ `layout/borek-theme.liquid` und `layout/imm-theme.liquid` sind identisch;
  `layout/mdm-theme.liquid` hat zusätzlich nur die Retoure-CSS (4 Zeilen).

### PLP — `templates/collection.json`

| Section-ID | MDM | IMM | Borek |
|---|---|---|---|
| `breadcrumbs_Gxg9wp` | `mdm-breadcrumbs` | `mdm-breadcrumbs` | **`breadcrumbs`** (Nexvo) |
| Intro | `mdm_main_collection_banner_gbjBJD` „Kategorie-Intro“ | dieselbe ID, Name „MDM collection banner“ | **`banner`: `main-collection-banner`** (Nexvo) |
| `collection_list_slider_6qbNfj` | `mdm-collection-list-slider` | gleich | **`collection-list-slider`**, deaktiviert |
| `product-grid` | `mdm-main-collection-product-grid` | gleich | gleich, plus Promo-Block |
| `banner` | „Verwandte Kategorien“ | mit Demo-Text „Seit 2006 prägen …“ | — |
| `mdm_bottom_sections_r4WkDz` | „Vertrauens-Box“, leer | — | — |
| weitere | — | — | `rich-text` „About Nexvo“, `buttons-with-icon`, 2 × `multicolumn-icon` (Nexvo-Demo, Elektronik, Adresse Miami) |

- ✅ Borek nutzt die Nexvo-Sections; Overrides für `mdm-breadcrumbs` und
  `mdm-main-collection-banner` landen dort nicht. Bhavanis Befund ist damit belegt.
- ✅ Boreks Zusatz-Sections sind unveränderte Nexvo-Demo-Inhalte — es geht kein Borek-Inhalt
  verloren.
- ✅ Shared CSS adressiert Sections über Klassen (`.mdm-collection-hero` …), keine Section-IDs
  (`git grep` auf `shopify-section-template`/`[id$=` in `brand-overrides.css` und
  `mdm-*.css`: 0 Treffer). Die Klassen entstehen nur, wenn das Template die `mdm-`Section nutzt.

### PDP — `templates/product.json`

- ✅ Borek und IMM nutzen schon dieselben `mdm-`Sections wie MDM. Unterschiede: eine
  zusätzliche deaktivierte Section `mdm_featured_collection_XwhTU7`, abweichendes
  `custom_css`, abweichende Werte (`media_size`, Abstände, `heading_size`, leere Tooltip-Texte,
  „3 bis 5 Tage“ statt „Werktage“). IMM weicht von Borek nur in `show_gift_card_recipient` ab.

### Welche Templates die Shops nutzen

- ✅ MDM (Admin-Abfrage 15. Oktober 2026): alle 306 Kollektionen ohne Suffix →
  `collection.json`. Produkte: 7.318 ohne Suffix → `product.json`, 1.314 `kollektion`,
  1 `reservierung`. `collection.mdm.json` und `product.mdm.json` nutzt kein Datensatz.
- ❌ Borek und IMM: unbekannt, kein Store-Zugang in dieser Session.

### Fehlerhafte Layout-Verweise in Borek und IMM

- ✅ In Borek (33) und IMM (34) tragen Templates `"layout": "mdm-theme"` (u. a. `collection.mdm.json`,
  `product.mdm.json`, alle `page.muenz*`/`page.euro*`-Inhaltsseiten; IMM zusätzlich
  `product.flatrate.json`). `layout/mdm-theme.liquid` existiert dort nicht.
- ❌ Unbekannt, wie Shopify das rendert (Fehler oder Rückfall auf `theme.liquid`). Die Doku
  nennt nur `theme.liquid` als Standard, wenn der Schlüssel fehlt.

## Anforderungen

### Phase 0 — MDM bereinigen (Voraussetzung)

- [ ] R0.1 „Mehr anzeigen“/„Weniger anzeigen“ im Kollektions-Intro nutzt
      `rgb(var(--color-subtext))` — Text und Unterstreichung (`currentColor`). Ersetzt den
      festen Wert `#002147` aus PR #46. Details: `mdm/kollektion-mehr-anzeigen-farbe.md`.
- [ ] R0.2 Beim Hover ändert sich die Farbe nicht; Feedback ist die vorhandene
      Unterstreichungs-Animation (`text-underlined`, `theme.css`).
- [ ] R0.3 Die leere Section `mdm_bottom_sections_r4WkDz` („Vertrauens-Box“) ist aus
      `templates/collection.json` entfernt (Section und `order`-Eintrag). Die sichtbare
      Vertrauens-Box kommt weiter aus der Footer-Gruppe.

### Phase 1 — PLP nach Borek und IMM

- [ ] R1.1 `templates/collection.json` und `templates/collection.mdm.json` sind in Borek und IMM
      inhaltsgleich mit MDM (nach Phase 0). Einzige Abweichung: `layout` = `borek-theme` bzw.
      `imm-theme`.
- [ ] R1.2 `assets/mdm-collection.css` und `assets/mdm-section-collection-hero.css` sind
      identisch mit MDM (nach Phase 0).
- [ ] R1.3 Nicht angefasst: `sections/*-group.json`, `config/*`, `locales/*`, `layout/*`, alle
      anderen Templates.

### Phase 2 — PDP nach Borek und IMM

- [ ] R2.1 `templates/product.json` und `templates/product.mdm.json` sind in Borek und IMM
      inhaltsgleich mit MDM. Einzige Abweichung: `layout`.
- [ ] R2.2 Nicht übertragen: `product.kollektion.json`, `product.reservierung.json`
      (MDM-only, App-Block), `product.flatrate.json` (Borek/IMM-only).
- [ ] R2.3 Merge erst, wenn Phase 1 in Borek/IMM abgenommen ist (E3).

### Phase 3 — übrige Seiten (nur Bestandsaufnahme)

- [ ] R3.1 Liste aller übrigen Templates mit Status je Marke (gleich / nur Layout / Werte /
      Struktur / fehlt) als Gesprächsgrundlage mit Bhavani. Keine Änderung in dieser Spec.

## Akzeptanzkriterien

- [ ] A1 MDM-Dev-Server, `/collections/kollektionen`: `.read-more__toggle` und `::after` haben
      `rgb(62, 58, 50)` (= Subtext `#3e3a32` in `scheme-1`), auch nach Klick und beim Hover.
      Viewport 1440 px und 375 px. (R0.1, R0.2)
- [ ] A2 MDM-Dev-Server: Überschriften, Kollektionstext, Filter-„Mehr anzeigen“ unverändert.
- [ ] A3 MDM `collection.json`: geparster Inhalt gleich origin/main minus
      `mdm_bottom_sections_r4WkDz`; Seite rendert ohne leere Section. (R0.3)
- [ ] A4 Strukturvergleich per Skript: Borek/IMM `collection.json`, `collection.mdm.json`,
      `product.json`, `product.mdm.json` gleich MDM, abgesehen von `layout`. (R1.1, R2.1)
- [ ] A5 Alle Section-Typen der neuen Templates existieren in `sections/` der Zielmarke.
- [ ] A6 `git diff --stat` je Ziel-Branch enthält nur die in R1/R2 genannten Dateien. (R1.3)
- [ ] A7 `shopify theme check` je Theme: keine neuen Findings gegenüber origin/main desselben
      Repos (Kontrolltest auf demselben Commit).
- [ ] A8 `validate_theme` ohne Fehler für alle geänderten Dateien.
- [ ] A9 (nach Push als unveröffentlichtes Theme oder nach Merge, durch Konrad/Bhavani)
      Borek und IMM: Kollektionsseite zeigt Kategorie-Intro, Chips „Verwandte Kategorien“,
      Vertrauens-Box aus dem Footer; keine Nexvo-Demo-Inhalte.

## Constraints

- Templates tragen den Banner „auto-generated“ und werden vom Theme-Editor mitverwaltet.
  Vor jedem Push `git pull` auf Bot-Commits prüfen. Nach dem Merge den Theme-Editor neu laden —
  eine offene, alte Editor-Sitzung kann die Vertrauens-Box wieder eintragen (so geschehen
  am 13. Oktober 2026, `d40ba64`).
- Die Ganzdatei-Kopie ist hier richtig: Ziel ist Identität, nicht ein Patch.
  `bin/theme-sync.sh` blockt `templates/*` (Blockliste) und würde den `layout`-Schlüssel nicht
  anpassen — deshalb Kopie mit gezieltem Ersetzen der `layout`-Zeile.
- Widerspruch zu bestehenden Regeln: `CLAUDE.md` („templates/ … nie zwischen Themes
  übertragen“) und die Blockliste in `bin/theme-sync.sh` gelten für PLP/PDP nicht mehr.
  Anpassung der Regel ist eine eigene Entscheidung (offener Punkt O1).
- Blast-Radius: alle Kollektions- und Produktseiten in Borek und IMM (sofern sie die
  Standard-Templates nutzen, siehe ❌ oben). MDM: alle Kollektionsseiten (Toggle-Farbe).

## Offene Punkte

- O1 ✅ Erledigt am 15. Oktober 2026 (Auftrag Konrad): PLP/PDP-Templates gelten als
  geteilt, `layout` bleibt markenspezifisch — in `templates/repo-themes.md` und damit
  `CLAUDE.md`, `.claude/rules/templates-json.md`, Skill `theme-port` und
  `bin/theme-sync.sh` (`SHARED_TEMPLATES`, Layout-Umsetzung, Tests). Dabei behoben: Die
  Blockliste griff aus dem Workspace-Root nie für `templates/*` (Glob-Expansion), siehe
  `../harness/theme-sync.md`.
- O2 Inhaltswerte im PDP-Template sind MDM-Texte und gehen mit: Tooltip „Bei
  Classic-Kollektionen …“, Tooltip 30-Tage-Bestpreis, „Lieferdauer: 3 bis 5 Werktage“,
  Eyebrow „STARTPREIS: 2 FÜR 1“ (nur bei Suffix `kollektion` sichtbar). Gelten sie für Borek
  und IMM (Österreich: Lieferzeit)?
- O3 Fehlerhafte `layout: mdm-theme`-Verweise in 33 (Borek) bzw. 34 (IMM) Templates: im Store prüfen,
  wie die Seiten rendern; Korrektur in Phase 3.
- O4 Welche Templates nutzen die Kollektionen und Produkte in Borek und IMM? Nur mit
  Store-Zugang prüfbar.
- O5 `product.kollektion.json` und `product.reservierung.json` auch nach Borek/IMM? Die
  Reservierung braucht die App „EasySell COD Form“.
- O6 Brand-Overrides mit festem `#002147` (Überschriften) widersprechen E6 — separates Thema.

## Validierung — 15. Oktober 2026

Sechs Branches, je ein Worktree unter `themes/.worktrees/`, alle auf origin/main des Repos,
nicht committet:

| Repo | Branch | Worktree | Dateien |
|---|---|---|---|
| MDM | `fix/collection-read-more-subtext` | `mdm-read-more-subtext` | `assets/mdm-section-collection-hero.css` |
| MDM | `chore/collection-remove-trust-placeholder` | `mdm-collection-trust-placeholder` | `templates/collection.json` |
| Borek | `sync/plp-templates-from-mdm` | `borek-plp-templates` | `collection.json`, `collection.mdm.json`, 2 × CSS |
| IMM | `sync/plp-templates-from-mdm` | `imm-plp-templates` | `collection.json`, `collection.mdm.json`, 2 × CSS |
| Borek | `sync/pdp-templates-from-mdm` | `borek-pdp-templates` | `product.json`, `product.mdm.json` |
| IMM | `sync/pdp-templates-from-mdm` | `imm-pdp-templates` | `product.json`, `product.mdm.json` |

| AC | Ergebnis |
|---|---|
| A1 | erfüllt — Dev-Server Port 9295: Toggle und `::after` `rgb(62, 58, 50)` bei 1024, 1440 und 375 px; nach Klick („Weniger anzeigen“) gleich; Hover: Farbe gleich, Animation `text-underlined` läuft |
| A2 | erfüllt — Titel `rgb(0, 33, 71)`, Überschriften im Text `rgb(0, 33, 71)`, Filter-„Mehr anzeigen“ `rgb(0, 33, 71)`, Fließtext `rgb(62, 58, 50)` — unverändert |
| A3 | erfüllt — Port 9296: Section `mdm_bottom_sections_r4WkDz` (vorher Höhe 0) fehlt; Abstände unverändert: Chips → Vertrauens-Box 60 px (`deutschland-muenzen`), Paginierung → Vertrauens-Box 60 px (`deutschland-muenzen-euro-goldmuenzen`), 1440 px |
| A4 | erfüllt — Skriptvergleich: alle 8 Ziel-Templates gleich MDM ohne `layout`; `layout` = `borek-theme` / `imm-theme` |
| A5 | erfüllt — alle Section-Typen in `sections/` der Zielmarke vorhanden |
| A6 | erfüllt — `git status` je Worktree nur die genannten Dateien |
| A7 | erfüllt — Befundliste identisch mit origin/main: MDM 41/23, Borek 41/25, IMM 41/245 (Errors/Warnings) |
| A8 | erfüllt — `validate_theme` VALID für alle 12 geänderten Dateien |
| A9 | offen — Borek/IMM nur mit Store-Zugang prüfbar (Konrad/Bhavani) |

Merge-Reihenfolge: MDM (beide) → Borek/IMM PLP → Abnahme → Borek/IMM PDP.

## Status

IMPLEMENTIERT — 15. Oktober 2026 (A9 und Commits offen)
