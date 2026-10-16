# Spec: Kollektion — Abstand zur Vertrauens-Box ohne verwandte Kategorien

## Ziel

Auf Kollektionsseiten ohne verwandte Kategorien steht zwischen Produktliste (Paginierung,
Filterleiste) und Vertrauens-Box derselbe Abstand wie zwischen den Chips der verwandten
Kategorien und der Vertrauens-Box. Seiten mit verwandten Kategorien bleiben unverändert.

## Grundlage

- Ticket SHOP-2, Kommentar von Kerstin Meyer am 15. Oktober 2026: Abnahme von PR #34 und
  PR #41 bestanden, eine Verbesserung offen — ohne gepflegte verwandte Kategorien „klebt“ das
  nachfolgende Modul an der Paginierung und/oder den Filtern. Beispiel:
  `/collections/deutschland-muenzen-euro-goldmuenzen`.
- Vorarbeit: PR #34 (`2d3f27c`), PR #41 (`9d8f3d2`), Spec `trust-section-footer-group.md`.

## Ursache — Ist-Stand origin/main `b3467e8`

| Fundstelle | Befund |
|---|---|
| `templates/collection.json:123`, `templates/collection.mdm.json:116` | Produkt-Grid `padding_bottom: 0` |
| `sections/mdm-main-collection-banner.liquid:236-238` | Verwandte Kategorien rendern nur bei `related_count > 0`, sonst kein Markup |
| `assets/mdm-section-collection-hero.css:139-142, 258-261` | Den Abstand nach der Produktliste liefert allein `.mdm-related-categories` (6 rem / mobil 3,2 rem oben, 6 rem / mobil 4 rem unten) |
| `sections/footer-group.json:14, 333` | Vertrauens-Box ist die erste Section der Footer-Gruppe, Scheme `scheme-inverse` (navy), Abstand innen oben 32 px |

Fällt die Section „Verwandte Kategorien“ weg, folgt auf das Grid mit 0 px direkt die navy
Vertrauens-Box.

✅ Belegt im Dev-Server (Port 9293, Branch = origin/main) am 15. Oktober 2026:

| Seite | Viewport | Paginierung unten → nächstes Element |
|---|---|---|
| `deutschland-muenzen-euro-goldmuenzen` (keine Chips) | 1440 px | 1652 → Vertrauens-Box 1652 = **0 px** |
| `deutschland-muenzen` (12 Chips) | 1440 px | 2021 → Überschrift 2081 = 60 px; Chips unten 2216 → Vertrauens-Box 2276 = **60 px** |
| `deutschland-muenzen` (12 Chips) | 375 px | 3191 → Überschrift 3223 = 32 px; Chips unten 3357 → Vertrauens-Box 3397 = **40 px** |

## Anforderungen

- [ ] R1 Ohne verwandte Kategorien liegt zwischen Unterkante Produkt-Grid-Inhalt
      (Paginierung bzw. Filterleiste, je nachdem was tiefer reicht) und Oberkante
      Vertrauens-Box ein Abstand von 60 px (Desktop, ab 768 px) bzw. 40 px (mobil).
      Das entspricht dem heutigen Abstand Chips → Vertrauens-Box.
- [ ] R2 Mit verwandten Kategorien ändert sich nichts — weder Abstände noch Aussehen.
- [ ] R3 Setzt jemand im Theme-Editor für das Produkt-Grid einen größeren Abstand unten als
      R1, gilt der größere Wert. Die Einstellung bleibt wirksam.
- [ ] R4 Gilt für beide Templates mit `mdm-main-collection-product-grid`: `collection.json`
      und `collection.mdm.json`. Folgt auf das Grid ein Kollektionstext-Block
      (`.mdm-collection-hero`, so in `collection.mdm.json`), bringt dieser seinen Abstand
      selbst mit — dort bleibt der Zustand unverändert.

## Akzeptanzkriterien

Gemessen auf dem Dev-Server (Store `mdm-muenze`), 1440 px und 375 px, per
`getBoundingClientRect`, Toleranz 1 px. Referenzwerte siehe Tabelle oben.

- [ ] A1 `/collections/deutschland-muenzen-euro-goldmuenzen`: Paginierung unten →
      Vertrauens-Box oben = 60 px (1440) bzw. 40 px (375). (R1)
- [ ] A2 Dieselbe Seite mit Filter, der die Produktliste auf eine Zeile kürzt (Filterleiste
      tiefer als Grid): Unterkante Filterleiste → Vertrauens-Box ≥ 60 px bzw. 40 px. (R1)
- [ ] A3 `/collections/deutschland-muenzen`: alle drei Referenzwerte der Tabelle unverändert,
      12 Chips. (R2)
- [ ] A4 `?view=mdm` auf beiden Seiten: Abstände wie auf origin/main (Grid unten 0 px, der
      Kollektionstext folgt mit eigenem Abstand). (R4)
- [ ] A5 Grid-Setting `padding_bottom` testweise auf 80 (nur lokal, nicht committen):
      Abstand ohne Chips 80 px (Desktop). (R3)
- [ ] A6 Kein Diff an `templates/*.json` und `sections/*-group.json`.
- [ ] A7 `shopify theme check` im Worktree: keine neuen Findings gegenüber origin/main.
- [ ] A8 `validate_theme` ohne Fehler für alle geänderten Dateien.
- [ ] A9 Keine neuen hartcodierten Farbwerte, keine neuen Texte, kein JS.

## Constraints

- Theme-First: keine neue Section, keine Template- oder Footer-Gruppen-Änderung — beide
  Dateien schreibt auch der shopify[bot].
- Nur MDM-Theme in diesem PR. Port nach Borek/IMM siehe Abschnitt Validierung.
- Blast-Radius: nur Seiten mit `.mdm-collection-grid` (einzig in
  `sections/mdm-main-collection-product-grid.liquid`). Suche, Startseite, andere
  Kollektions-Templates (Nexvo-Originale) sind nicht betroffen.

## Nicht Teil dieser Spec

- Die leere Section `mdm_bottom_sections_r4WkDz` „Vertrauens-Box“ in `templates/collection.json`.
  PR #41 hatte sie entfernt (`2c37aa5`), der shopify[bot] hat sie am 13. Oktober 2026 per
  Theme-Editor-Sync wieder eingetragen (`b639091`/`d40ba64`). Sie rendert kein sichtbares
  Markup, ist im Editor aber irreführend. Aufräumen im Theme-Editor, nicht per PR.
- Abstände anderer Kollektions-Templates (`collection.banner-*.json`, Nexvo-Originale).

## Offene Punkte

- O1 Kerstins Screenshot (Anhang `image-20261015-050626.png`) ist per API nicht lesbar. Die
  Nachstellung deckt ihre Beschreibung ab; ⚠️ Vermutung: der Screenshot zeigt denselben Fall.

## Validierung — 15. Oktober 2026

Branch `fix/collection-grid-bottom-spacing` auf origin/main `b3467e8`, Dev-Server Port 9293.
Änderung: nur `assets/mdm-collection.css` (+18 Zeilen). Selektor gegenüber Plan erweitert um
`.mdm-collection-hero` (siehe R4).

| AC | Ergebnis |
|---|---|
| A1 | erfüllt — 60 px (1440 und 1024), 40 px (375) |
| A2 | erfüllt — `?filter.v.m.sap.nominal=120.00`, Filterleiste tiefer als Grid: 60 px |
| A3 | erfüllt — 60/60 (1440, 1024), 32/40 (375), 12 Chips, Grid unten 0 px |
| A4 | erfüllt — `?view=mdm`: Grid unten 0 px wie origin/main |
| A5 | erfüllt — Editor-Wert 80: 80 px (1440), 60 px (1024), 40 px (375, Hyper-Deckel) |
| A6, A9 | erfüllt — kein Diff außer der CSS-Datei |
| A7 | erfüllt — 41 Errors / 23 Warnings auf Branch und `b3467e8`, identische Liste |
| A8 | erfüllt — `validate_theme` VALID |

Reviews: theme-reviewer APPROVED (2 minor, Kommentar umbrochen), security-reviewer APPROVED.

Korrektur zur Constraint „Nur MDM“: ✅ Borek und IMM führen dieselbe Section und eine
identische `assets/mdm-collection.css` (gleich origin/main MDM).
- IMM: Template gleich aufgebaut (Grid → Verwandte Kategorien, Vertrauens-Box in der
  Footer-Gruppe) — derselbe Fehler, ⚠️ Vermutung, nicht im Browser geprüft. Port sinnvoll.
- Borek: Template ohne Verwandte Kategorien, auf das Grid folgt `rich-text` mit
  `padding_bottom: 0`. Mit dem Port bekäme das Grid dort 60 px Abstand unten — Layout-Änderung,
  Entscheidung Konrad.

## Status

IMPLEMENTIERT — 15. Oktober 2026 (Abnahme durch Kerstin Meyer offen)
