# Spec: Technische Daten — Zeilen „Ausgabejahr“ und „Jahrespunze“ wiederherstellen

## Ziel

In der Gruppe „Herkunft“ der Technischen Daten auf der Produktseite erscheinen „Ausgabejahr“
und „Jahrespunze“ wieder mit Beschriftung und Wert, sobald die Variante einen Wert hat — so wie
vor Commit `a987614`.

## Grundlage

- Review von PR #19 am 13. Oktober 2026. Der PR ist geschlossen, weil `a987614` ihn ersetzt.
- `a987614` (Latori, 23. September 2026, „revert default values in tech data“) kam direkt auf
  main, ohne PR. Beim Zurückholen der Fallbacks hat der Commit im Herkunft-Block drei Zeilen
  durch eine Kopie der Auflage-Zeilen überschrieben.
- Vor dem Fehler (`ada4eb4~1`, Z. 126-128, und `ada4eb4`) waren alle drei Zuweisungen vorhanden.
  Der Verlust war also nicht beabsichtigt.
- Admin-Abfrage am 13. Oktober 2026 per `shopify store execute`: alle 3.655 aktiven Varianten.
  Jedes aktive Produkt hat genau eine Variante.

## Kontext — Ist-Stand origin/main `22dc46f`

| Fundstelle | Befund |
|---|---|
| `snippets/mdm-product-tech-data.liquid:124-126` | Label „Auflage“ und die beiden Auflage-Texte |
| `snippets/mdm-product-tech-data.liquid:140-142` | dieselben drei Zeilen ein zweites Mal, ohne Wirkung |
| `snippets/mdm-product-tech-data.liquid:143-146` | Wert Jahrespunze (`sap.jahrespunze`, Fallback `mdm.jahrespunze`) |
| — | keine Zuweisung für `hk_row_2_label`, `hk_row_2_value`, `hk_row_3_label` |
| `snippets/mdm-product-tech-data.liquid:327-333` | `render` übergibt alle vier Herkunft-Zeilen an `mdm-tech-data-group` |
| `snippets/mdm-tech-data-group.liquid:25-48` | Eine Zeile erscheint, wenn ihr Wert nicht leer ist. Das Label wird ungeprüft ausgegeben. |
| `sections/mdm-tabs-content.liquid:354, 382` | rendern das Snippet; die Section steht in `product.json`, `product.kollektion.json`, `product.mdm.json`, `product.reservierung.json` |

✅ `shopify theme check` meldet die fehlenden Zuweisungen nicht.

## Datenlage — Admin, 13. Oktober 2026

| Metafeld (Variante) | Definition | Varianten mit Wert |
|---|---|---|
| `sap.ausgabejahr` | vorhanden, `single_line_text_field` | 2.626 von 3.655 |
| `sap.jahrespunze` | **keine** | 0 |
| `mdm.jahrespunze` | **keine** | 0 |
| `sap.auflage` | vorhanden, `single_line_text_field` | 3.654 (davon 2.514 mit „0“) |
| `mdm.tech_label_*` | keine | — |

Werte von `sap.ausgabejahr`:

| Wert | Varianten | Einordnung |
|---|---|---|
| 1900-2099 | 2.410 | Jahreszahl |
| 1301-1899 | 36 | historische Jahreszahl, plausibel (34 davon 1700-1899, dazu 1301 und 1533) |
| `0000` | 176 | Platzhalter für „kein Wert“, wie „0“ bei der Auflage |
| `0999`, `0099` | 4 | Datenfehler: zum Beispiel `0099` bei „50 Pfennig 1919-1922“, `0999` bei Feingoldbarren |

Template-Suffixe der aktiven Produkte: ohne Suffix 3.539, `kollektion` 115, `reservierung` 1,
`mdm` 0.

## Folgen

- ✅ Die Zeile „Ausgabejahr“ fehlt heute bei allen 2.626 Produkten mit Wert, rund 72 Prozent
  der aktiven Produkte.
- ✅ Nach dem Fix zeigen 176 Produkte „Ausgabejahr 0000“, wenn `0000` nicht wie ein leerer Wert
  behandelt wird (E2).
- ✅ **Korrektur gegenüber dem Review:** Die Zeile „Jahrespunze“ ohne Beschriftung tritt heute
  nicht auf, weil keine Variante einen Wert hat und es keine Definition gibt. Die fehlende
  Beschriftung ist latent. R2 stellt sie vorbeugend wieder her.
- ✅ **Korrektur gegenüber dem Review:** Der Store `mdm-muenze` ist passwortgeschützt
  (`/password`). Veröffentlicht ist `shopifyFrontend_MDM/main`, aber Kunden sehen den Fehler
  erst mit dem Launch. `www.mdm.de` ist noch der alte Shop.

## Entscheidungen

### E1: Reihenfolge der Herkunft-Zeilen

| | A: wie vor dem Fehler (**empfohlen**) | B: wie im Dummy-Snippet |
|---|---|---|
| Reihenfolge | Auflage, Ausgabejahr, Jahrespunze, Ausgabeland | Auflage, Jahrespunze, Ausgabejahr, Ausgabeland |
| Quelle | `ada4eb4~1` und heutiges `render` (`:327-333`) | `snippets/mdm-product-tech-data-dummy.liquid:111-114` |
| Einordnung | stellt einen bekannten Stand her, keine Designfrage im Bugfix | Latori-Mock vom August, wird nirgends gerendert. ⚠️ Ob er Figma entspricht, ist ungeprüft. |

**Empfehlung: A.** Die Reihenfolge nach Figma ist eine eigene Frage.

**Entschieden am 13. Oktober 2026 durch Konrad: Variante A.**

### E2: Ausgabejahr `0000`

| | A: `0000` gilt als kein Wert (**empfohlen**) | B: alles unter 1000 gilt als kein Wert | C: Wert unverändert anzeigen |
|---|---|---|---|
| Wirkung | 176 Zeilen ausgeblendet | 180 Zeilen ausgeblendet | 176 × „0000“, 4 × Datenfehler sichtbar |
| Risiko | 4 Datenfehler bleiben sichtbar | blendet künftig echte antike oder mittelalterliche Jahre aus | Platzhalter im Shop |
| Vorbild | Auflage „0“ (`b06d8b6`) | — | — |

A behandelt den systematischen SAP-Platzhalter so wie bei der Auflage. Die 4 Einzelfehler
gehören in die Datenpflege, nicht in eine Theme-Regel.

**Empfehlung: A.**

**Entschieden am 13. Oktober 2026 durch Konrad: Variante A.**

## Anforderungen

- [ ] R1 Hat die Variante einen Wert in `sap.ausgabejahr`, erscheint in „Herkunft“ eine Zeile
      mit der Beschriftung „Ausgabejahr“ und diesem Wert.
- [ ] R2 Hat die Variante einen Wert für die Jahrespunze (Quellen wie heute), trägt die Zeile
      die Beschriftung „Jahrespunze“.
- [ ] R3 Beide Beschriftungen folgen derselben Kette wie alle übrigen Labels der Tabelle:
      Varianten-Metafeld `mdm.tech_label_*`, dann Produkt-Metafeld, dann fester Text.
- [ ] R4 Ohne Wert erscheint die jeweilige Zeile nicht.
- [ ] R5 Die Reihenfolge der Herkunft-Zeilen entspricht E1: Auflage, Ausgabejahr, Jahrespunze,
      Ausgabeland.
- [ ] R6 Auflage-Label und Auflage-Texte werden nur noch einmal zugewiesen. Die Auflage-Zeile
      verhält sich unverändert, auch beim Ausblenden von leer und „0“ (`b06d8b6`).
- [ ] R7 Alle anderen Gruppen und Zeilen bleiben unverändert.
- [ ] R8 Das Ausgabejahr `0000` gilt als leerer Wert (E2: A), auch mit Leerzeichen davor oder
      danach.

## Testprodukte

Aus der Admin-Abfrage, alle aktiv, verfügbar und mit genau einer Variante.

| Fall | Handle | Template | SKU | Ausgabejahr | Auflage |
|---|---|---|---|---|---|
| T1 Jahr, Auflage mit Wert | `bund-10-euro-fussball-wm-ausgabe-2003-st` | product | 103450110 | 2003 | 3550000 |
| T2 Jahr, Kollektion | `2-euro-gedenkmuenzen-kleinstaaten` | kollektion | 15994/004 | 2026 | 52000 |
| T3 Jahr, Auflage „0“ | `jahressatz-2002-pp-mit-folder` | product | 102650108 | 2002 | 0 |
| T4 ohne Jahr, Auflage leer | `bund-5-dm-fichte-vz-st-db` | product | 100010396 | — | leer |
| T5 ohne Jahr, Auflage „0“ | `bistum-salzburg-1623-1709-silber-madonna-st-rudbertus` | product | 120290176 | — | 0 |
| T6 `0000` | `dfb-pokal-silber` | product | 22102/001 | 0000 | 0 |
| T7 `0000`, Reservierung | `20-euro-goldmuenze-2026-gem-pz` | reservierung | 352119/001 | 0000 | 0 |

T4 ist das einzige aktive Produkt mit leerer Auflage. Für die Jahrespunze gibt es kein
Testprodukt.

## Akzeptanzkriterien

Gemessen auf dem Dev-Server (Store `mdm-muenze`, Port 9292), vorher auf main und nachher auf
dem Branch, mit den Testprodukten T1-T7.

| AC | Kriterium | Req |
|---|---|---|
| A1 | T1, T2, T3: Zeile „Ausgabejahr“ mit dem Wert aus der Tabelle | R1, R3 |
| A2 | Jahrespunze: kein Testprodukt vorhanden. Abnahme per Review: Die Beschriftung ist zugewiesen und wird übergeben. | R2, R3 |
| A3 | T4, T5: keine Zeile „Ausgabejahr“, Gruppe „Herkunft“ vorher = nachher | R4 |
| A4 | T1-T7: kein `.mdm-tech-data__label` ist leer, wenn das zugehörige `.mdm-tech-data__value` nicht leer ist (DOM-Abfrage) | R2, R3 |
| A5 | T1: Reihenfolge Auflage, Ausgabejahr, Ausgabeland. Position der Jahrespunze per Review. | R5 |
| A6 | Auflage auf T1 (Wert), T3 (0) und T4 (leer): vorher = nachher | R6 |
| A7 | T1-T7: alle übrigen Zeilen, Label und Wert vorher = nachher | R7 |
| A8 | T6, T7: keine Zeile „Ausgabejahr“ (E2: A) | R8 |
| A9 | Diff gegen origin/main ändert nur `snippets/mdm-product-tech-data.liquid`, nur im Herkunft-Block | R6, R7 |
| A10 | Review: Die Label-Kette der beiden Zeilen ist identisch aufgebaut wie bei den übrigen `tech_label_*`-Zeilen. Die Metafelder haben keine Definition, deshalb ist die Kette nur im Code prüfbar. | R3 |
| A11 | `shopify theme check --output json` in sauberen Worktrees, main gegen Branch: Findings identisch. Ausgangswert auf `22dc46f`: 37 Errors, 23 Warnings; vor der Umsetzung auf dem dann aktuellen main neu bestimmen. | — |
| A12 | `validate_theme` für das Snippet gültig | — |
| A13 | theme-reviewer und security-reviewer: APPROVED | — |

## Constraints

- Theme-First: Keine Hyper-Section ist betroffen. Das Snippet ist eine eigene `mdm-`-Datei, die
  `mdm-tabs-content` rendert. Es entsteht keine neue Datei.
- Blast-Radius: Tab „Technische Daten“ auf allen 3.655 aktiven Produkten (Templates ohne
  Suffix, `kollektion`, `reservierung`). Nach dem Merge sofort im veröffentlichten Theme;
  der Store ist derzeit passwortgeschützt.
- Die Wertquellen bleiben unverändert. Werte bekommen keine neuen festen Fallback-Texte
  (Platzhalter-Prinzip aus #12 und #18).
- Die Datei wurde seit dem 23. September 2026 viermal geändert (`a987614`, `3543ee3`, `b06d8b6`,
  `94c0553`). Branch von origin/main, vor dem PR erneut fetchen und vergleichen.
- Ein PR, ein Thema: Branch von origin/main, PR gegen main.
- Nur MDM-Theme.

## Nicht Teil dieser Spec

- **Borek und IMM:** ✅ Derselbe Fehler steckt auf origin/main beider Themes (borek `af01efe`,
  imm `bc33e7c`): Zuweisungen fehlen, Auflage-Block doppelt. Übertragung danach per
  `/theme-port`. ⚠️ Ob die PDP dort heute genutzt wird, ist ungeprüft.
- **Datenfehler im Ausgabejahr:** `0099` (`weimar-50-pfennig-erste-munze-der-ersten-deutschen-republik`)
  und `0999` (`usa-mercury-dime-1916-1945`, `10g-feingoldbarren-der-adler`,
  `10g-feingoldbarren-1975-jahre-koeln`). Meldung an die Fachseite bzw. SAP-Datenpflege.
- Ob die Jahrespunze überhaupt eine Datenquelle bekommt (keine Definition, keine Werte).
- Feste Auflage-Texte „Nur [value] Exemplare weltweit“ und „Nur [value] komplette Kollektionen“,
  die `a987614` zurückgeholt hat, im Verhältnis zum Platzhalter-Prinzip. Das ist eine eigene
  Entscheidung.
- Reihenfolge nach Figma
- `snippets/mdm-product-tech-data-dummy.liquid` (nicht referenziert, harte Farben) aufräumen

## Offene Punkte

- ~~O1 Testprodukte~~ — erledigt, siehe T1-T7
- ~~O2 Entscheidung E1~~ — erledigt, Variante A
- ~~O3 Entscheidung E2~~ — erledigt, Variante A

## Validierung — 13. Oktober 2026

Branch `fix/tech-data-origin-rows` auf origin/main `22dc46f`, Worktree
`themes/.worktrees/mdm-tech-data-origin`. Dev-Server `127.0.0.1:9292`, Development-Theme
`189649617277`: vorher mit dem Snippet von main (19:23 Uhr), nachher mit dem Branch-Snippet.
Gemessen im gerenderten HTML jeder Produktseite, alle Zeilen der Technischen Daten.

| AC | Ergebnis |
|---|---|
| A1 | erfüllt — T1 „Ausgabejahr: 2003“, T2 „2026“, T3 „2002“; vorher bei allen dreien keine Zeile |
| A2 | erfüllt (Review) — `hk_row_3_label` zugewiesen (Z. 146), per `render` übergeben (Z. 332) |
| A3 | erfüllt — T4 ohne Herkunft-Gruppe, T5 nur „Ausgabeland: Salzburg“, jeweils vorher = nachher |
| A4 | erfüllt — 0 leere Labels neben einem Wert auf T1-T7 |
| A5 | erfüllt für T1: Auflage, Ausgabejahr, Ausgabeland, auch sichtbar im Tab geprüft. Position der Jahrespunze: Review |
| A6 | erfüllt — T1 „Nur 3550000 Exemplare weltweit“, T3 („0“) und T4 (leer) ohne Auflage-Zeile, vorher = nachher |
| A7 | erfüllt — auf T1-T7 keine Zeile entfernt oder geändert; einzige neue Zeile ist das Ausgabejahr auf T1-T3 |
| A8 | erfüllt — T6 und T7 (`0000`) ohne Zeile „Ausgabejahr“ |
| A9 | erfüllt — 1 Datei, 7 Zeilen hinzugefügt, 3 entfernt, nur im Herkunft-Block |
| A10 | erfüllt (Review) — Kette wortgleich zu Auflage und Ausgabeland, identisch zu `ada4eb4~1` Z. 126/128 |
| A11 | erfüllt — 37 Errors / 23 Warnings auf main und Branch, keine neuen oder weggefallenen Findings |
| A12 | erfüllt — `validate_theme` gültig |
| A13 | erfüllt — theme-reviewer APPROVED (0 Findings), security-reviewer APPROVED (0 Findings im Diff) |

Nebenbefunde, vorher = nachher und nicht Teil dieser Spec:

- T1 zeigt „Gewicht 18.000“ ohne Einheit und die Auflage ohne Tausenderpunkt („3550000“).
- Security-Review: Alle Labels und die meisten Werte der Tabelle werden unescaped ausgegeben
  (`mdm-tech-data-group.liquid:27, 33, 39, 45`). Escaped sind nur `material_value`,
  `sap_feingehalt` und jetzt `hk_row_2_value`. Quellen sind Staff-Pflege und SAP-Import, kein
  Kundeninput; Risiko gering. Vorschlag für einen eigenen PR: Labels im Group-Snippet escapen,
  Werte an der Zuweisung (sonst Doppel-Escaping).

## Status

IMPLEMENTIERT — 13. Oktober 2026 (E1 A, E2 A; Smoke-Test erfüllt, beide Reviews APPROVED; Commit `c863a20`, PR #42 offen)
