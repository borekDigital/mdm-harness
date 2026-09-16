# Figuren-Grammatik

Eine Figur verdient ihren Platz, wenn ein Leser damit einen Mechanismus **sieht**, den er
sonst aus Prosa zusammensetzen muesste. Sagt ein Satz es schneller, schreib den Satz.

## Die sieben Figurtypen, die tragen

### 1. Vergleich zweier Varianten
Dieselbe Rasterung, nebeneinander, damit das Auge die Abweichung findet. Das Fehlende
gehoert mit ins Bild — als gestrichelter Platzhalter, nicht als Luecke.

> Connector, Etappe 2, Blatt 01: lokal drei Prozesse unter foreman, auf dem Server zwei
> plus ein gestrichelter Kasten „kein vite — Assets sind vorgebaut".

### 2. Kette mit Rueckkanal
Vertikale Abfolge, wenn die Ausfuehrungsreihenfolge der Leserichtung widerspricht. Der
Rueckweg als gestrichelte Kurve mit rotierter Beschriftung.

`Kette` ist hier Fachbegriff dieses Systems, keine Metapher — siehe die Ausnahmeliste in
`design-system.md`, Abschnitt „Keine Metaphern, keine Wertungen".

> Etappe 2, Blatt 02: `require` laeuft abwaerts, wirksam wird es aufwaerts — genau der
> Punkt, an dem Leser von Rails-Configs stolpern.

### 3. Zeitachse
Wenn Takt oder Frequenz die Aussage ist. Dichte Wiederholung als SVG-`<pattern>`,
Einzelereignisse als Marker, Laufzahl je Zeile rechts.

> Etappe 2, Blatt 05: 720× / 96× / 1× / 1× am Tag. Die Balkendichte *ist* die Erkenntnis.

### 4. Zustandsmaschine
Zustaende als Kaesten, Uebergaenge beschriftet, Wiedereinstiege gestrichelt. Der Auslöser
gehoert dazu.

> Etappe 3, Blatt 03: `pending → completed | failed`, plus der 2-Minuten-Cron, der
> `scope :unprocessed` liest, plus der Retry-Pfad ueber die GraphQL-Mutation.

### 5. Nachrichtenkanal
Wenn Komponenten nicht direkt reden, sondern ueber geteilten Zustand. Der Zustand in die
Mitte, Schreiber links, Leser rechts.

> Etappe 9, Blatt 02: der Warenkorb als Kanal zwischen zwei Extensions, einer Function und
> dem Backend — keine davon kennt die andere.

### 6. Matrix
Eigenschaft gegen Variante. Gefuellte Zelle heisst vorhanden, gestrichelte leere Zelle
heisst fehlt. Fuer Vergleiche mit mehr als drei Spalten immer besser als Kaesten.

> Etappe 4, Blatt 04: vier Auth-Verfahren gegen fuenf Eigenschaften.

### 7. Gewichtsverteilung
Gezaehlte Zahlen als Balken. Nur wenn die Verteilung selbst etwas erzaehlt.

> Etappe 5, Blatt 05: bei Shopify liegt das Gewicht in `api/`, bei SAP in
> `transformer/` — und bei `credit` und `openiban` sind 7 von 9 Dateien Geruest.

## Antimuster

| Antimuster | Warum es nicht traegt | Was stattdessen |
|---|---|---|
| Ordnerbaum | Sagt nichts, was `ls` nicht sagt | Zeige den Pfad einer Anfrage durch die Ordner |
| Kaesten ohne Kanten | Eine Bestandsliste ist eine Tabelle | HTML-Tabelle nehmen, kein SVG |
| Unbeschriftete Pfeile | „irgendwie verwandt" | `schreibt`, `quittiert`, `alle 2 Min` |
| Zwei Aussagen in einer Figur | Der Leser weiss nicht, wohin schauen | Zwei Figuren |
| Optionen nebeneinander ohne Verbindung | Ist kein Vergleich, sondern eine Aufzaehlung | Die eine Kante zeichnen, die sich unterscheidet |
| Alles zeigen | 88 Kaesten helfen niemandem | Die drei zeigen, in denen 60 % der Zeilen stecken |
| Nummerierung als Zierde | `01 / 02 / 03` behauptet eine Reihenfolge | Nur nummerieren, wo Reihenfolge Information ist |
| Emoji als Abschnittsmarke | Liest sich generiert | Blattnummer plus Display-Schrift |

## Bildunterschrift

Nicht die Wiederholung der Figur. Sie beantwortet: **Warum zaehlt das fuer jemanden, der
morgen in diesem Code arbeitet?**

Gute Muster:

- „Der Unterschied ist das Interessante." — und dann der Unterschied
- „Warum das eine Design-Entscheidung mit Folgen ist" — und dann die Folge
- „Die Antwort auf die offene Frage aus Etappe 3" — Kette schliessen
- „Zwei Stellen, an denen man sich beim Erweitern verletzt" — konkret werden

Erste Woerter fett setzen, damit die Aussage beim Ueberfliegen haengt.

## Anhang

Vier bis sechs Beobachtungen. Jede:

1. **Titel als Aussagesatz.** Nicht „CORS", sondern „CORS ist vollstaendig offen".
2. **Beleg.** `Datei:Zeile`, und wenn moeglich das Codefragment.
3. **Konsequenz.** Was passiert, wenn es schiefgeht — konkret, nicht „koennte
   problematisch sein".
4. **Der Fix in einem Satz**, wo er offensichtlich ist.

Mischen ist erwuenscht: Fehler, Design-Entscheidungen und **gute Nachrichten** nebeneinander.
Eine geschlossene offene Frage aus einer frueheren Etappe ist ein vollwertiger
Anhangspunkt — sie zeigt, dass der Satz als Ganzes gelesen wurde.

Was **nicht** in den Anhang gehoert: Geschmacksfragen ohne Konsequenz, Stilkritik,
alles ohne Beleg.

## Belegen heisst nachsehen, nicht erinnern

Zwei Fehlerarten haben sich beim Connector- und Harness-Satz als die haeufigsten erwiesen.
Beide entstehen aus Bequemlichkeit und beide sind in Sekunden vermeidbar.

### Zahlen und Zeilennummern nie schaetzen

Jede `Datei:Zeile` und jede Zahl in einer Figur wird vor dem Schreiben abgefragt, nicht
nach dem Schreiben geprueft. Bei der ersten Fassung von Harness-Etappe 1 waren sieben von
sieben Zeilenangaben falsch und `sync.sh` mit 262 statt 309 Zeilen angegeben — geschaetzt
aus dem Leseeindruck.

```bash
grep -n "muster" datei                 # Zeilennummer holen
wc -l < datei                          # Zeilenzahl holen
awk 'NR>=31 && /^}/ {print NR; exit}'  # Ende eines Blocks finden
```

Am Ende jeder Seite gegenpruefen: jede Zahl, die auf dem Blatt steht, einmal gegen den
Bestand rechnen. Das ist ein Zehnzeiler und findet zuverlaessig, was beim Schreiben
verrutscht ist.

### Ausfuehrbare Behauptungen ausfuehren

Das Grundgesetz sagt „nie zeichnen, was nicht gelesen wurde". Lesen genuegt nicht, wenn
die Aussage ein **Verhalten** betrifft. Ein Skript liest sich anders, als es laeuft.

Beispiel aus Harness-Etappe 1: Aus der Aufrufreihenfolge in `sync.sh` liess sich
schluessig ableiten, dass der 7-Tage-Check nie ausloest — der Zeitstempel wird vier Zeilen
vor der Pruefung neu gesetzt. Ein einziger Aufruf von `./sync.sh` zeigte das Gegenteil: die
Warnung feuert bei **jedem** Lauf fuer alle sechs Repos, weil eine greedy
`sed`-Ersetzung den Zeitstempel vorher zerstoert. Die Ableitung war korrekt und die
Schlussfolgerung falsch, weil ein zweiter Fehler den ersten maskiert.

Also: bevor eine Figur behauptet, etwas laufe nicht, greife nicht oder sei toter Code —

- **Skript?** Aufrufen. `./sync.sh`, `bash hook.sh < nutzlast.json`, `--dry-run`.
- **Funktion ohne Aufrufer?** `grep -rn` nach dem Namen, und den Treffer ansehen: ein
  auskommentierter Aufrufer ist etwas anderes als kein Aufrufer.
- **Konfiguration?** Den Wert ausrechnen lassen, nicht ableiten — `python3 -c`,
  `date -j -f`, `git check-ignore -v`.
- **Zwei Fehler koennen sich aufheben.** Ein Symptom, das der Ableitung widerspricht,
  ist ein Hinweis auf eine zweite Ursache, nicht auf einen Denkfehler.

Was sich nicht ausfuehren laesst — Laufzeitverhalten im Betrieb, Fremdsystem-Antworten —
bleibt `⚠️ Vermutung` mit dem Satz, was zum Beweis fehlt.

## Zeichenbreiten

Vor dem Schreiben rechnen, nicht danach korrigieren.

| Klasse | Groesse | px je Zeichen | Zeichen in 200 px Kasten (–32 Rand) |
|---|---|---|---|
| `.s-name` | 12,5 Mono fett | ~7,5 | 22 |
| `.s-mono` | 11 Mono | ~6,6 | 25 |
| `.s-tiny` | 9,6 Mono | ~5,7 | 29 |
| `.s-note` | 11,5 Body | ~5,5 | 30 |

Bei zentriertem Text `text-anchor="middle"` die halbe Breite zu beiden Seiten pruefen —
das ist der haeufigste Ueberlauf.
