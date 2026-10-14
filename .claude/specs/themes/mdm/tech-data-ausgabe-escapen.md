# Spec: Technische Daten — Ausgaben escapen

## Ziel

Die Tabelle „Technische Daten“ auf der Produktseite gibt jede Überschrift, jede Beschriftung und
jeden Wert genau einmal HTML-escaped aus, so wie es `.claude/rules/liquid-conventions.md`
verlangt. Für Kunden sieht die Tabelle danach gleich aus, mit einer Ausnahme, die E3 regelt.

## Grundlage

- Security-Review von `fix/tech-data-origin-rows` am 13. Oktober 2026, Nebenbefund in
  `tech-data-herkunft-zeilen.md` (Abschnitt „Validierung“).
- Regel: „Ausgaben von Merchant-/Kundeneingaben escapen: `{{ var | escape }}`. Ausnahme nur für
  bewusst gerenderte Rich-Text-Settings“ (`.claude/rules/liquid-conventions.md`).
- Die Daten kommen aus der Staff-Pflege (`mdm.*`) und dem SAP-Import (`sap.*`), nicht von
  Kunden. Das Risiko ist gering. Die Änderung härtet das Theme, es gibt keinen akuten Angriff.

## Kontext — Ist-Stand

Stand: origin/main `22dc46f` plus der noch **nicht committete** Fix aus `fix/tech-data-origin-rows`
(Worktree `themes/.worktrees/mdm-tech-data-origin`). Alle Zeilennummern beziehen sich auf
diesen Stand.

### Ausgabe — `snippets/mdm-tech-data-group.liquid`

| Zeile | Ausgabe | escaped |
|---|---|---|
| :23 | `{{ heading }}` | nein |
| :27, :33, :39, :45 | `{{ row_N_label }}` | nein |
| :28, :34, :40, :46 | `{{ row_N_value }}` | nein |

- ✅ Einziger Aufrufer ist `snippets/mdm-product-tech-data.liquid`: acht `render`-Aufrufe
  (:314-361). Belegt per `git grep` auf origin/main.
- ✅ **Ergänzung zum Review:** Auch die Gruppenüberschrift (:23) wird unescaped ausgegeben. Sie
  folgt derselben Kette wie die Labels: Variante `mdm.tech_heading_*`, dann Produkt, dann fester
  Text (`mdm-product-tech-data.liquid:5-12`). Vier der festen Texte enthalten `&`
  („Design & Motiv“, „Material & Qualität“, „Maße & Gewicht“, „Preis & Lieferung“).

### Zuweisung — `snippets/mdm-product-tech-data.liquid`

Alle 22 Labels (Spalte „Label“) folgen der Kette Variante `mdm.tech_label_*`, dann Produkt, dann
fester Text, und keines wird escaped.

| Gruppe | Zeile | Label | Wert | Quelle des Werts (Typ laut Admin) | heute | Soll |
|---|---|---|---|---|---|---|
| Design & Motiv | Startausgabe | :15 | :16 | `mdm.design_start` (single_line) | — | escapen |
| | Gratis Startausgabe | :17 | :18 | `mdm.design_gratis` (single_line) | — | escapen |
| Material & Qualität | Material | :21 | :25-43 | `mdm.metall_kommentar` oder Metaobjekt `sap.metall` plus `sap.feingehalt` | ✅ :28, :33, :36 | unverändert |
| | Prägequalität · Erhaltung | :44 | :45 | Metaobjekt `sap.erhaltung`, Feld `erhaltung` (single_line) | — | escapen |
| | Prägestätte | :46 | :47 | Metaobjekt `sap.praegestaette`, Feld `praegestaette` (single_line) | — | escapen |
| | Veredelung | :48 | :49 | `sap.veredelung` (single_line) | — | escapen |
| Maße & Gewicht | Maße · Durchmesser | :60 | :61-98 | `mdm.masse_kommentar`, `mdm.masse_praefix`, `mdm.masse_einheit`, `sap.durchmesser` (single_line); `mdm.masse_laenge/_breite/_hoehe` (number_decimal) | — | escapen, zusammengesetzt |
| | Gewicht | :109 | :101-119 | `mdm.gewicht_anzeige` (Fallback `mdm.gewicht_kommentar`), `mdm.gewicht_praefix`, `sap.gewicht_in_feinunzen`, `sap.gewicht` (single_line); `variant.weight` | — | escapen, zusammengesetzt |
| Herkunft | Auflage | :124 | :123-139 | Vorlage `mdm.tech_auflage_template_a/_default` (sonst fester Text) plus `sap.auflage` (single_line) | — | escapen (E2) |
| | Ausgabejahr | :141 | :142 | `sap.ausgabejahr` (single_line) | ✅ :142 | unverändert |
| | Jahrespunze | :146 | :147-150 | `sap.jahrespunze`, `mdm.jahrespunze` (ohne Definition) | — | escapen |
| | Ausgabeland | :151 | :152 | Metaobjekt `sap.ausgabeland`, Feld `country` (single_line) | — | escapen |
| Nominalwert | Nennwert | :155 | :156 | `sap.nominal` (single_line) | — | escapen |
| | Währung | :157 | :163 | Metaobjekt `sap.waehrung`, Feld `wahrung` (single_line) | — | escapen |
| Preis & Lieferung | Startpreis | :167 | :168-172 | `variant.price`, `variant.compare_at_price` über `money` | — | **nicht** escapen (R7) |
| | Folgepreis pro Lieferung | :174 | :175-185 | `mdm.folgepreis`, `mdm.streichpreis_einzelausgabe` (money) über `money` | — | **nicht** escapen (R7) |
| | Lieferzeit | :187 | :188 | Metaobjekt `custom.lieferzeit`, Feld `delivery_time_notice` (single_line) | — | escapen |
| | Lieferrhythmus | :189 | :190-196 | `mdm.lieferrhytmus` (single_line); `sap.`/`custom.lieferrhythmus` ohne Definition | — | escapen |
| Lieferumfang | Startlieferung | :199 | :200-212 | `mdm.lieferumfang` (list.single_line), baut `<ul><li>` | — | Listenpunkt escapen (:206) |
| | Folgelieferungen | :214 | :215-227 | `mdm.lieferumfang_folgelieferung` (list.single_line), baut `<ul><li>` | — | Listenpunkt escapen (:221) |
| Artikel Details | Art.-Nr. | :230 | :231 | `variant.sku` | — | escapen |
| | Serie | :232 | :233 | `mdm.serie` (single_line) | — | escapen |

- ✅ Der Material-Wert ist an `mdm-product-key-facts.liquid` (Fact 2) gekoppelt („Keep in sync“,
  :24). Dort wird ebenfalls bei der Zuweisung escaped.
- ✅ Geldformat des Shops: `{{amount_with_comma_separator}} €`, ohne HTML.

## Datenlage — Admin, 13. Oktober 2026

Lesender Scan per `shopify store execute`: alle 8.633 Varianten, davon 3.655 aktiv. Gezählt
werden nur aktive Produkte. Gesucht wurde nach `& < > " '`, nach Entities (`&amp;`, `&#39;` …)
und nach HTML-Tags.

| Quelle | aktiv mit Wert | Treffer | Befund |
|---|---|---|---|
| `mdm.gewicht_anzeige` | 849 | 1 Tag | `2022: 9,00 g <p>2023/2024: je 9,68 g` (`bund-9er-set-5-wunderwelt-insekten-st`). Heute wird daraus ein Absatz, escaped stünde `<p>` als Text da (**E3**). |
| `mdm.masse_kommentar` | 429 | 1 `&` | „31 mm & 32,5 mm“ (`set-deutsche-silbermuenzen-grosse-frauen`). Im DOM bleibt der Text gleich. |
| `mdm.metall_kommentar` | 2.267 | 1 `&`, 1 Tag | „Silber (800/1000) & (925/1000)“ sowie `<br>` bei `frankreich-kusrmuenzensatz-champs-elysees`. Der Wert wird schon heute escaped, `<br>` steht also heute als Text im Shop. |
| `mdm.lieferumfang`, `…_folgelieferung` | je 2 | 0 | Listenpunkte ohne Sonderzeichen |
| `mdm.design_start` / `_gratis` | 2 / 1 | 0 | — |
| `mdm.lieferrhytmus` | 2 | 0 | — |
| `sap.auflage`, `sap.nominal`, `sap.gewicht`, `sap.durchmesser`, `sap.feingehalt` | je 3.654 | 0 | — |
| `sap.veredelung`, `sap.gewicht_in_feinunzen`, `mdm.masse_praefix`, `mdm.masse_einheit`, `mdm.gewicht_praefix` | 243 / 489 / 365 / 3.110 / 87 | 0 | — |
| `variant.sku` | 3.655 | 0 | — |
| `mdm.serie`, `mdm.gewicht_kommentar`, `sap.`/`custom.lieferrhythmus` | 0 | — | Zeile ist nur per Review prüfbar |
| Metaobjekte: Länder (524), Währungen, Prägestätten, Erhaltung, Metall, Lieferzeit | — | 3 | „St. Christopher & Nevis“, „Turcs & Caicos“, „Tongaische Pa'anga“. `referencedBy` ist leer, keine Variante nutzt sie. |
| `mdm.tech_heading_*`, `mdm.tech_label_*`, `mdm.tech_auflage_template_*` an Produkt und Variante | 0 | — | Keine Definitionen und an keinem aktiven Produkt ein Wert (32 Keys, Produkt und Variante, per `metafields(keys:)` mit Gegenprobe). Heute erscheinen immer die festen Texte. |

- ✅ In den Daten steht keine Entity. `escape` erzeugt deshalb an keiner Stelle sichtbare
  Entities wie `&amp;amp;`.
- ✅ Bis auf E3 ändert das Escaping nur den Quelltext (`&` wird zu `&amp;`), nicht den Text, den
  der Browser anzeigt.

## Entscheidungen

### E1: Wo wird escaped?

| | A: Labels und Überschriften im Group-Snippet, Werte bei der Zuweisung (**empfohlen**, Vorschlag des Reviews) | B: alles im Group-Snippet |
|---|---|---|
| Labels, Überschriften | Group-Snippet | Group-Snippet |
| Werte | `mdm-product-tech-data.liquid`, an der Zuweisung | Group-Snippet. Das bestehende Escaping von `material_value`, `sap_feingehalt` und `hk_row_2_value` fällt weg. |
| Lieferumfang, Preise | Listenpunkte einzeln escapen, Preise bleiben unescaped | Das Group-Snippet braucht je Zeile einen Schalter für HTML. Das ist ein neuer Parameter. |
| Doppel-Escaping | Ausgeschlossen, solange jeder Wert genau einen Escape-Ort hat | Ausgeschlossen. Material weicht dann aber vom Key-Facts-Snippet ab, das bei der Zuweisung escaped. |
| Risiko | Ein vergessener Wert bleibt unescaped. Abhilfe: Review gegen die Tabelle oben. | Ein falsch gesetzter Schalter macht HTML als Text sichtbar oder lässt es ungeprüft durch. |

**Empfehlung: A.** Labels und Überschriften kommen nie vorab escaped an, Werte schon (Material,
Ausgabejahr). Bei A bleibt das bestehende Muster erhalten.

**Entschieden am 14. Oktober 2026 durch Konrad: Variante A.**

### E2: Auflage — Vorlage mitescapen?

Das Review schlägt vor, `sap_auflage` vor `replace`/`append` zu escapen. Die Vorlage („Nur [value]
Exemplare weltweit“) kann aber ebenfalls aus einem Metafeld kommen und wäre dann weiter unescaped.

| | A: Vorlage und Zahl escapen (**empfohlen**) | B: nur die Zahl (wie im Review) |
|---|---|---|
| Wirkung | Der ganze Wert ist escaped | Die Vorlage aus dem Metafeld bleibt unescaped |

`escape` ersetzt Zeichen einzeln, und `[value]` enthält kein Sonderzeichen. Ob man beide Teile vor
dem Einsetzen escaped oder den fertigen Wert einmal, ergibt deshalb dasselbe.

**Empfehlung: A.**

**Entschieden am 14. Oktober 2026 durch Konrad: Variante A.**

### E3: HTML in Staff-Textfeldern

Ein aktives Produkt hat `<p>` im Gewicht (siehe Datenlage). Heute bricht dort die Zeile um. Nach
dem Escaping stünde `2022: 9,00 g <p>2023/2024: je 9,68 g` wörtlich da.

| | A: konsequent escapen, Datenpflege korrigiert den Wert (**empfohlen**) | B: Gewicht ausnehmen | C: Tags vorher entfernen (`strip_html`) |
|---|---|---|---|
| Shop | Bis zur Korrektur ist `<p>` auf 1 Produkt sichtbar | unverändert | „2022: 9,00 g 2023/2024: je 9,68 g“, ohne Trennung |
| Sicherheit | Lücke geschlossen | Lücke bleibt im meistgepflegten Freitextfeld | geschlossen |
| Vorbild | `metall_kommentar` wird schon escaped, dort steht `<br>` heute sichtbar | — | — |
| Nebenwirkung | — | Regelverstoß bleibt | Künftige Tags verschwinden still, niemand bemerkt den Datenfehler |

**Empfehlung: A.** Ein `single_line_text_field` ist kein Rich Text. Den Wert korrigiert die
Fachseite, zum Beispiel in „2022: 9,00 g; 2023/2024: je 9,68 g“. Am besten geschieht das vor dem
Merge, dann gibt es keine sichtbare Änderung im Shop.

**Entschieden am 14. Oktober 2026 durch Konrad: Variante A.**

## Anforderungen

- [ ] R1 Alle 8 Gruppenüberschriften und alle 22 Labels werden genau einmal escaped, im
      Group-Snippet (E1).
- [ ] R2 Jeder Wert aus einem Metafeld, Metaobjekt oder der SKU ist genau einmal escaped, bevor
      er an das Group-Snippet geht (E1). Das Group-Snippet escaped keine Werte.
- [ ] R3 Material (`material_value`) und Ausgabejahr (`hk_row_2_value`) bleiben, wie sie sind.
      Sie werden nicht ein zweites Mal escaped.
- [ ] R4 Zusammengesetzte Werte (Maße, Gewicht) sind als Ganzes genau einmal escaped. Zahlen aus
      `number_decimal` erscheinen in derselben Schreibweise wie heute.
- [ ] R5 Auflage: Vorlagentext und SAP-Auflage sind escaped (E2). Die Logik für leer, „0“,
      Produkttyp `A` und `[value]` bleibt unverändert.
- [ ] R6 Lieferumfang: Jeder Listenpunkt ist escaped. `<ul>` und `<li>` bleiben Markup.
- [ ] R7 Startpreis und Folgepreis bleiben unverändert. Die Ausgabe von `money` und der feste
      Text „(statt …)“ werden nicht escaped.
- [ ] R8 Bedingungen, Reihenfolge und Sichtbarkeit von Gruppen und Zeilen bleiben unverändert.
- [ ] R9 Der Dateikopf des Group-Snippets beschreibt die Regel: `heading` und `row_N_label`
      kommen als Klartext, `row_N_value` kommt bereits escaped oder als bewusstes HTML.
- [ ] R10 E3 gilt für das Gewicht wie für alle anderen Werte. Es gibt keine Ausnahme pro Feld.

## Testprodukte

Alle aktiv, mit genau einer Variante.

| Fall | Handle | Template | SKU | Zweck |
|---|---|---|---|---|
| T1-T7 | wie in `tech-data-herkunft-zeilen.md` | product, kollektion, reservierung | — | Herkunft, Auflage leer/„0“/Wert, Ausgabejahr, `0000` |
| T8 | `set-deutsche-silbermuenzen-grosse-frauen` | product | 1631330115 | `&` in Maße (neu escaped) und in Material (schon escaped) |
| T9 | `die-banknoten-edition-das-geld-der-deutschen-3` | kollektion | 352214/007 | Typ `A`, Startausgabe, Lieferrhythmus, beide Listen, Folgepreis mit Streichpreis, Startpreis mit Vergleichspreis |
| T10 | `50-jahre-biene-maja` | kollektion | 352253/001 | Gratis Startausgabe, Veredelung, Maße mit Präfix „je“, beide Listen, Folgepreis |
| T11 | `bund-9er-set-5-wunderwelt-insekten-st` | product | 1627190119 | `<p>` im Gewicht (E3) |
| T12 | `frankreich-kusrmuenzensatz-champs-elysees` | product | 1610380107 | `<br>` im Material, heute schon escaped; Auflage 500, Gewicht mit Präfix |
| T13 | `deutschland-gold-anlage-depot-feingoldbarren` | kollektion | 25876/001 | Maße aus `number_decimal`: 4.0 × 10.6 × 10.6 mm |

Für Serie und Jahrespunze gibt es kein Testprodukt, beide sind nur per Review prüfbar (A8).

## Akzeptanzkriterien

Gemessen auf dem Dev-Server (`shopify theme dev --store mdm-muenze`, Port 9292). Den
Storefront-Passwortschutz gibt Konrad selbst ein. Gemessen wird vorher auf main (mit
`fix/tech-data-origin-rows`) und nachher auf dem Branch, mit T1-T13.

| AC | Kriterium | Req |
|---|---|---|
| A1 | T1-T10, T12, T13: Je Gruppe stimmen vorher und nachher überein: Überschrift (Text), je Zeile Label (Text), Wert (Text) und Wert (`innerHTML` im DOM), dazu Anzahl und Reihenfolge der Gruppen und Zeilen | R3-R8 |
| A2 | T11: Unterschied nur im Wert „Gewicht“, wie in E3 beschrieben. Ist der Wert vorher korrigiert, gilt A1. | R10 |
| A3 | Kein Doppel-Escaping: Im Quelltext des Blocks `.mdm-tech-data` steht kein `&amp;amp;`, `&amp;#39;`, `&amp;quot;`, `&amp;lt;` oder `&amp;gt;`. Kein angezeigter Text enthält `&amp;`, `&#39;`, `&quot;`, `&lt;` oder `&gt;`. | R2, R3 |
| A4 | Escaping wirkt: Im Quelltext steht `Preis &amp; Lieferung` (vorher `Preis & Lieferung`) und auf T8 `31 mm &amp; 32,5 mm` | R1, R2 |
| A5 | Probe mit Sonderzeichen, rot vor grün. Auf dem Dev-Server wird für jedes Escape-Muster die Quelle vorübergehend durch `<i>x</i> & "y" 'z'` ersetzt: Überschrift, Label, einfacher Wert, zusammengesetzter Wert, Auflage-Vorlage, Lieferumfang-Punkt. Vor der Umsetzung entsteht ein `<i>`-Element (rot). Danach erscheint der Text wörtlich, ohne `<i>`-Element und ohne sichtbare Entity (grün). Die Probe wird nicht committet (A9). | R1, R2, R4-R6 |
| A6 | T9, T10: Listen mit gleicher Anzahl `li` und gleichem Text. Preiszeilen im Quelltext Byte für Byte gleich. | R6, R7 |
| A7 | T13: Maße (Admin-Werte 4.0, 10.6, 10.6, Einheit mm) vorher und nachher Zeichen für Zeichen gleich | R4 |
| A8 | Review gegen die Tabelle „Zuweisung“: Jede der 30 Beschriftungen und Überschriften hat genau einen Escape-Ort. Jeder Wert hat genau einen Escape-Ort oder ist als Ausnahme aufgeführt (Preise, Listen-Markup). Serie und Jahrespunze sind enthalten. | R1-R7 |
| A9 | Der Diff gegen main ändert nur `snippets/mdm-tech-data-group.liquid` und `snippets/mdm-product-tech-data.liquid` | — |
| A10 | `shopify theme check --output json` in sauberen Worktrees, main gegen Branch: Findings identisch. Den Ausgangswert vor der Umsetzung auf dem dann aktuellen main neu bestimmen. | — |
| A11 | `validate_theme` ist für beide Snippets gültig | — |
| A12 | theme-reviewer und security-reviewer: APPROVED | — |

## Constraints

- Theme-First: Keine Hyper-Datei ist betroffen. Beide Snippets sind eigene `mdm-`-Dateien, und es
  entsteht keine neue Datei.
- Blast-Radius: Tab „Technische Daten“ auf allen 3.655 aktiven Produkten (Templates ohne Suffix,
  `kollektion`, `reservierung`). Nach dem Merge ist die Änderung sofort im veröffentlichten
  Theme. Der Store ist derzeit passwortgeschützt.
- Wertquellen, Fallback-Texte und Bedingungen bleiben unverändert. Es kommen keine neuen festen
  Texte hinzu.
- `escape`, nicht `escape_once`: `escape_once` würde ein Doppel-Escaping verdecken, statt es
  auszuschließen.
- TDD: Für Liquid gibt es kein Test-Framework. A5 ist der Nachweis rot vor grün, A1 der
  Regressionstest.
- Ein PR, ein Thema: Branch von origin/main, PR gegen main, nur das MDM-Theme.

## Nicht Teil dieser Spec

- **Borek und IMM:** ✅ Beide haben `snippets/mdm-tech-data-group.liquid` mit denselben vier
  unescapten Labels (origin/main). Übertragung danach per `/theme-port`.
- **`snippets/mdm-product-key-facts.liquid`:** ✅ Gleiches Muster. `fact_N_label` und `fact_N_value`
  werden unescaped ausgegeben (:109, :124-146), escaped wird nur Material. Das ist ein eigener Befund.
- **Datenpflege (Fachseite):** `<p>` im Gewicht von T11 (E3), `<br>` im Material von T12. Das
  `<br>` ist schon heute sichtbar.
- Hartkodierte Farben im Style-Block von `mdm-product-tech-data.liquid` (:252, :266, :273, :279)
- Nebenbefunde aus `tech-data-herkunft-zeilen.md` (Gewicht ohne Einheit, Auflage ohne
  Tausenderpunkt)
- `snippets/mdm-product-tech-data-dummy.liquid` (wird nicht gerendert)

## Offene Punkte

- ~~O1 Basis-Branch~~ — Stand 14. Oktober 2026: `fix/tech-data-origin-rows` ist als `c863a20`
  committet und gepusht, aber noch nicht gemergt. `fix/tech-data-escaping` zweigt von `c863a20`
  ab und enthält den Fix damit. Vor dem PR: nach dem Merge von origin-rows
  `git rebase --onto origin/main c863a20 fix/tech-data-escaping`.
- ~~O2 Entscheidung E1~~ — Variante A
- ~~O3 Entscheidung E2~~ — Variante A
- O4 Entscheidung E3: Variante A. Offen ist noch, wer den Gewicht-Wert von T11 korrigiert und ob
  das vor oder nach dem Merge geschieht.

## Validierung — 14. Oktober 2026

Branch `fix/tech-data-escaping` auf `c863a20` (origin-rows-Fix, noch nicht auf main), Worktree
`<Session-Worktree>/themes/.worktrees/mdm-tech-data-escaping`. Dev-Server `127.0.0.1:9292`,
Development-Theme `189649617277`. Vorher mit dem Stand `c863a20`, nachher mit dem Branch.
Gemessen im gerenderten HTML jeder Produktseite, ausgewertet per Parser: Überschrift, Label, Wert
und `innerHTML` jeder Zeile.

| AC | Ergebnis |
|---|---|
| A1 | erfüllt — T1-T10, T12, T13: alle Überschriften, Labels, Werte und Wert-`innerHTML` vorher = nachher, Gruppen und Zeilen gleich in Anzahl und Reihenfolge |
| A2 | erfüllt — T11: einziger Unterschied ist das Gewicht. Vorher Absatz, nachher steht `<p>` als Text da (E3 A) |
| A3 | erfüllt — auf T1-T13 kein doppelt escapter Eintrag im Quelltext und keine sichtbare Entity |
| A4 | erfüllt — Quelltext vorher `Preis & Lieferung`, nachher `Preis &amp; Lieferung`. T8 nachher `31 mm &amp; 32,5 mm`. Außer bei T11 ändert sich der Quelltext nur dort, wo `&` zu `&amp;` wird. |
| A5 | erfüllt — Probe `<i>x</i> & "y" 'z'` auf T1 an Überschrift, Label, SKU, Gewicht-Präfix, Auflage-Vorlage und Lieferumfang-Punkt. Auf `c863a20` 6 `<i>`-Elemente (rot), auf dem Branch 0 Elemente und 6-mal wörtlicher Text (grün). Die Probe ist entfernt. |
| A6 | erfüllt — T9, T10, T13: Startpreis, Folgepreis und beide Listen im Quelltext Byte für Byte gleich |
| A7 | erfüllt — T13 „4.0 x 10.6 x 10.6 mm“ vorher = nachher |
| A8 | erfüllt (Review) — beide Reviewer haben die Spur jeder Zeile gegen die Tabelle „Zuweisung“ geprüft |
| A9 | erfüllt — 2 Dateien, 32 Zeilen hinzugefügt, 25 entfernt |
| A10 | erfüllt — `shopify theme check` (CLI 4.9.3) auf `c863a20` und Branch: 37 Errors / 23 Warnings, identische Findings, keines in den geänderten Dateien. Nach dem Rebase auf main einmal wiederholen. |
| A11 | erfüllt — `validate_theme` gültig für beide Snippets |
| A12 | erfüllt — theme-reviewer APPROVED (Hinweis Kommentarposition umgesetzt), security-reviewer APPROVED (0 Findings, 3 Hinweise) |

Zusatzprüfungen:

- Security-Hinweis H2 (Geldzeilen mit Quellen ohne Definition): Probe mit `<i>x</i> …` als
  Folgepreis-Quelle ergibt „0,00 €“. `money` lässt kein Markup durch, die Ausnahme R7 ist
  belastbar.
- Bei der Schlussmessung wichen die Startpreise von T1 und T3 ab: 32,20 € gegen 32,18 € und
  154,05 € gegen 153,98 €. Laut Admin wurden die Preise am 14. Oktober 2026 um 09:15 Uhr
  aktualisiert, zwischen zwei Messungen. Das ist eine Datenänderung, kein Effekt des Codes.

## Status

IMPLEMENTIERT — 14. Oktober 2026 (E1 A, E2 A, E3 A; Validierung erfüllt, beide Reviews APPROVED; Commit, Rebase auf main und PR offen)
