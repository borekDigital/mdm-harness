# Design-Vertrag `bauplan-v1`

**Geltungsbereich.** Dieser Vertrag gilt fuer die Blattsaetze unter `docs/bauplan/` und nur
fuer sie. Er regelt nichts fuer Code-Kommentare, Commit-Messages, Ticket-Artefakte, Specs
oder andere Skills. Die allgemeinen Sprachregeln des Workspace stehen in `CLAUDE.md`; dieser
Abschnitt erweitert sie fuer einen Dokumenttyp und ersetzt sie nicht.

Alle Blattsaetze im Workspace sehen gleich aus. Das ist kein Selbstzweck: wer den
Connector-Satz gelesen hat, findet sich im Theme-Satz ohne Umlernen zurecht, weil Ocker
dort dasselbe bedeutet.

**Kopf nicht neu schreiben.** `assets/bauplan-head.html` enthaelt Font-Links und das
komplette Stylesheet. Verwenden, nicht nachbauen.

## Farbkodierung — die eine Regel, die nicht gebrochen wird

Vier Rollen, vier Token. Die *Rolle* bleibt konstant, die konkrete Bedeutung wird je Seite
in der Legende benannt.

| Token | Licht | Dunkel | Rolle |
|---|---|---|---|
| `--web` | `#94620A` Ocker | `#E2AB49` | **Synchron.** Was im Request passiert. Zustand, der jetzt gilt. |
| `--worker` | `#13615C` Petrol | `#5EC0B7` | **Asynchron.** Jobs, Queues, Protokolle, Transport. |
| `--vite` | `#6B4275` Pflaume | `#C79ACF` | **Rand.** Nur lokal, nur Frontend, nur Fremdsystem-Oberflaeche. |
| `--alert` | `#98282F` Karmin | `#ED8B92` | **Aufmerksamkeit.** Pruefpunkte, toter Code, fehlende Absicherung. |

Karmin ist knapp zu halten. Wenn eine Seite ueberall rot ist, hat sie keine Aussage mehr.

Neutrale: `--paper` (Grund), `--surface`, `--surface-2` (Kastenfuellung), `--rule`,
`--rule-soft` (Linien), `--text`, `--dim`. Alle mit leichter Blaustich-Tendenz — ein
reines Mittelgrau liest sich als unbedacht.

## Typografie

| Rolle | Familie | Einsatz |
|---|---|---|
| Display | Saira Condensed 600/700 | Titel, H2, Blattnummern, Legenden-Labels — Grossbuchstaben mit Sperrung |
| Body | Archivo 400/500/600 | Anrisse, Bildunterschriften, Anhangstexte |
| Mono | JetBrains Mono 400/700 | Alles, was Code ist: Pfade, Bezeichner, Zahlen, Tabellenzellen |

Mono ist hier nicht nur fuer Code-Bloecke, sondern fuer **jeden Bezeichner** — das haelt
die Grenze zwischen Prosa und Code sichtbar.

## Seitenaufbau

- Grund: Millimeterpapier aus zwei `repeating-linear-gradient` bei 28 px, Alpha ~0.055
- Spalte: `max-width: 1060px`, zentriert
- Titelblock wie im Zeichnungssatz: Rahmen, Eyebrow, H1, Anriss, dann eine
  Meta-Zeile mit 4–5 Feldern (`Gelesen`, `Zeilen`, `Blaetter`, `Stand`)
- Blattnummerierung `Blatt 01/06` als Mono links neben dem H2 — das ist die Vernakulaere
  eines Zeichnungssatzes und gleichzeitig echte Information
- Anhang traegt die Blattnummer `Anhang`

## SVG-Regeln

- Immer `viewBox="0 0 960 H"`, Breite ueber CSS. `960` ist gesetzt, `H` folgt dem Inhalt.
- `figure svg { min-width: 660px }` — Figuren scrollen horizontal in ihrem Container,
  die Seite selbst nie.
- Struktur in `currentColor` mit `stroke-opacity`, Bedeutung in den vier Token.
  `fill="var(--web)" fill-opacity="0.1" stroke="var(--web)" stroke-width="1.5"`.
- Pfeilspitzen als `<marker>` in `<defs>`, ID je Figur eindeutig (`e6ah2`) — IDs sind
  dokumentweit, gleiche IDs auf einer Seite kollidieren.
- Textklassen: `.s-name` (12,5 Mono fett), `.s-mono` (11), `.s-tiny` (9,6),
  `.s-lbl` (Display, gesperrt, Grossbuchstaben), `.s-note` (Body 11,5).
  Farbe ueber `.f-web` / `.f-worker` / `.f-vite` / `.f-alert` / `.f-dim`.
- `role="img"` plus `aria-label`, das dieselbe Aussage traegt wie die Figur.
- Kein `<script>`, `<style>` oder `<foreignObject>` im SVG.
- Rotierte Beschriftung nur ueber `transform="rotate(-90 x y)"` und nur sparsam.

## Titel und Ueberschriften

Der Titel ist der **Name der Etappe**, nicht ihre Zusammenfassung. Ein bis drei Woerter.
Keine Zahlen, kein Doppelpunkt, kein angehaengter Erklaerer.

> Umfang · Container · Messenger · Eingang · Registrierung · Mandanten · Deploy ·
> Aufbau · Agenten · Hooks · Skills und Rules · Bedienung

Zahlen gehoeren in die Meta-Zeile und in den Anriss. Falsch waere
`Hooks: 11 Skripte, 3 Ereignisse, 17 Abbruchpfade`: die drei Zahlen stehen ohnehin in der
Meta-Zeile, sie machen den Titel unlesbar, und sie veralten. Aendert sich eine Zahl, muss
sonst der Titel nachgezogen werden — und mit ihm der Dateiname in keiner, aber der
Artifact-Titel in jeder Veroeffentlichung.

Die Einordnung uebernimmt die Eyebrow-Zeile darueber:
`MDM Emailservice · Etappe 3 · Messenger und Nachrichtenfluss`. Der Titel muss Repo und
Etappennummer deshalb nicht wiederholen.

Die Erklaerung gehoert in den `description`-Parameter beim Veroeffentlichen.

### Dieselbe Regel gilt fuer die Blatt-Ueberschriften

Ein bis drei Woerter, Substantivphrase, auch fuer jedes `<h2>` und fuer den Anhang. Die
Ueberschrift benennt den **Gegenstand** des Blattes, nicht die Aussage darueber. Die
Aussage steht im Anriss und in der Bildunterschrift — dort laesst sie sich belegen, und
dort schadet es nicht, wenn sie lang wird.

| Statt | Besser |
|---|---|
| „Die Gruppe sagt, wen man fragen muss" | `Gruppen und Plattformen` |
| „Drei Wurzel-Commits, kein gemeinsamer Vorfahr" | `Historie und Deckung` |
| „Der Knoten liegt ausserhalb des Workspace" | `Kopplung ueber SAP` |
| „Der Drift-Melder laeuft, und niemand sieht ihn" | `Drift-Meldung` |
| „Zwei Fehler im 7-Tage-Check, die sich maskieren" | `7-Tage-Check` |

Kein finites Verb, keine Frage-Form (`Was ein Hook nicht kann`), keine Zahl. Die
Begruendung ist dieselbe wie beim Etappentitel: Zahlen und Aussagen veralten, Namen nicht.
Ein Blatt, dessen Ueberschrift eine These traegt, muss beim naechsten Befund umbenannt
werden — und die Ueberschrift steht im Inhaltsverzeichnis, im PDF und in der Uebersicht.

Der Anhang traegt durchgehend `Pruefpunkte und Fundstellen`. Ohne Zahl: „Drei
Pruefpunkte" veraltet, sobald ein vierter dazukommt.

Massstab: `docs/bauplan/harness/etappe-05.html`.

### Die Eyebrow-Zeile wiederholt den Titel nicht

`MDM Harness · Etappe 5 · Repos und Kopplung` ueber `<h1>Gesamtstruktur</h1>` — die
Eyebrow traegt die Einordnung, der Titel den Namen. Wortgleich ist beides eine
verschenkte Zeile.

## Beschreibung — traegt die Unterscheidung

Kurze Titel wiederholen sich ueber Blattsaetze hinweg: `Umfang` und `Eingang` gibt es
in Connector und Emailservice. In der Artefakt-Galerie stehen die Karten nebeneinander,
und der Titel allein unterscheidet sie dann nicht mehr. Diese Last traegt die
`description` — sie ist die Untertitel-Zeile der Karte.

Aufbau, in dieser Reihenfolge:

    <Repo> · Etappe <N> — <Gegenstand>: <zwei bis drei belegte Kennzahlen>.

> MDM Emailservice · Etappe 3 — Messenger: drei Busse, sechs Stamps, 26 Klassen im Nachrichtenfluss.
> MDM Connector · Etappe 8 — Frontend: 1 991 Zeilen React, vier Seiten, acht verschachtelte Provider.

Das Repo steht **vorn**, weil die Galerie lange Beschreibungen abschneidet. Die Kennzahlen
stammen aus der Meta-Zeile des Titelblocks, nicht aus einer Schaetzung — sie sind dort
bereits belegt. Ein Satz, unter 120 Zeichen.

Bei jeder Veroeffentlichung mitgeben: laesst man `description` weg, bleibt die zuletzt
gespeicherte stehen. Das ist beim reinen Neuveroeffentlichen richtig, beim Umbenennen
einer Etappe aber falsch.

## Wording — technische Dokumentation, kein Essay

Der Blattsatz muss auch von einer Person verstanden werden, die den Autor nicht kennt und
den Zusammenhang nicht aus fruehreren Gespraechen kennt. Jede Aussage beantwortet deshalb:
**Was? Warum? Wie? Wann? Unter welchen Bedingungen?**

### Satzbau

Aufbau: **Wer oder was → macht was → womit oder worauf → unter welcher Bedingung.**

| Statt | Besser |
|---|---|
| „Die Anwendung schaut sich die Daten an." | „Die Anwendung prueft die Eingabedaten." |
| „Die Konfiguration wird vom System gespeichert." | „Das System speichert die Konfiguration." |
| „Die Verbindung wird nach einiger Zeit beendet." | „Die Verbindung wird nach 30 Sekunden beendet." |
| „Die Funktion sorgt dafuer, dass der Dienst aktiviert wird." | „Die Funktion aktiviert den Dienst." |

Kurze Saetze. Ein Sachverhalt je Satz. Aktiv statt Passiv. Praesens; Praeteritum nur fuer
abgeschlossene Vorgaenge („Die Schnittstelle wurde in Version 2.4 angepasst").

### Muss, soll, kann

Diese drei Woerter unterscheiden Anforderung von Empfehlung von Option. Sie werden nicht
gemischt und nicht abgeschwaecht.

- **muss** — zwingende Voraussetzung. „Der Server muss ueber Port 443 erreichbar sein."
- **soll** — empfohlenes Verhalten. „Die Anwendung soll nach einem Neustart automatisch starten."
- **kann** — Option. „Der Benutzer kann die Protokollierung aktivieren."

Nicht: „sollte vielleicht", „idealerweise", „am besten", „normalerweise".

### Keine Leseransprache

Der Blattsatz beschreibt das System, nicht die Lektuere. Verboten: `man`, `wer … der …`,
`du`, `dein`, `unser`, `Sie`.

| Statt | Besser |
|---|---|
| „Wer eine Aenderung plant, kann sie nicht zu Ende lesen." | „Der Ablauf ist im Workspace nicht vollstaendig lesbar." |
| „Man erwartet, dass die Repos verdrahtet sind." | „Eine einzige direkte Kante verbindet zwei Repos." |
| „Hier sieht man drei Prozesse." | „Lokal laufen drei Prozesse." |

Ausnahme: `bedienung.html` darf den Imperativ verwenden — „Blattsatz mit
`/repo-bauplan <repo>` erzeugen" —, aber keine Anrede.

### Wortliste — nicht verwenden

Unscharfe Mengen und Bedingungen:
`einfach` · `schnell` · `problemlos` · `normalerweise` · `in der Regel` · `etc.` · `usw.`
· `gegebenenfalls` · `moeglichst` · `ein bisschen` · `einige` · `entsprechend` ·
`wie gewohnt`

Wertungen und Fuellwoerter:
`bemerkenswert` · `erstaunlich` · `ueberraschend` · `absurd` · `elegant` · `durchaus` ·
`eigentlich` · `quasi` · `relativ` · `ziemlich` · `leider`

Diese Woerter ersetzen eine Zahl oder eine Bedingung durch ein Gefuehl. Wo eine konkrete
Angabe existiert, steht die Angabe: `nach 30 Sekunden`, `ab 8 Zeichen`, `bei Exit-Code 2`.
Wo keine existiert, steht das — „ohne laufende Instanz nicht entscheidbar" — und nicht
eine Haltung dazu.

### Keine Metaphern, keine Wertungen

Ein Cron ist ein Cron — kein Uhrwerk, kein Herzschlag, kein Taktgeber. Eine Queue ist eine
Queue, kein Fliessband. „Die Verarbeitung dauert maximal 5 Sekunden" statt „Die
Verarbeitung ist sehr schnell".

Verbotene Bilder ohne Fachbezug: `Herzschlag` · `Uhrwerk` · `Taktgeber` · `Fliessband` ·
`Geschwister` · `Fremde` · `Nervensystem` · `Rueckgrat` · `Ader` · `Landkarte` ·
`Werkstueck`.

**Kein Verstoss ist etabliertes Fachvokabular**, auch wenn es bildlich klingt:
`Kette` (Figurtyp 2 der Figuren-Grammatik) · `Baum`, `Wurzel`, `Zweig`, `Branch`,
`Kopf`/`HEAD` (Git) · `Knoten` und `Kante` **im Graph-Zusammenhang** · `Blatt`,
`Blattsatz` (dieses System selbst). Ein Pruefer, der diese Woerter meldet, meldet falsch.

Zu `sauber`: als Wertung verboten („sauber geschriebener Code"). Als Zustand des
Git-Arbeitsbaums ist es der Fachbegriff und bleibt — „das Ziel-Theme muss einen sauberen
Arbeitsbaum haben". Dieselbe Unterscheidung gilt fuer `unsauber`.

Auch keine erzaehlende Rahmung: nicht „Daraus folgt alles andere", nicht „Der wichtigste
Punkt ist", nicht „Das ist die eigentliche Konstruktion", nicht „Es sieht aus wie …,
tatsaechlich aber …". Die Aussage steht fuer sich.

### Begriffe konsistent halten

Ein Begriff je Sache, im ganzen Blattsatz derselbe. `Etappe`, nicht abwechselnd Etappe,
Kapitel, Seite. `Blatt`, nicht Abschnitt. `Blattsatz`, nicht Doku oder Dokumentation.
Fachbegriffe beim ersten Auftreten ausschreiben: `AMQP (Advanced Message Queuing
Protocol)`.

### Bildunterschrift

Sie nennt die Konsequenz, nicht die Bedeutung. Bewaehrte Anfaenge:
„Relevant beim Erweitern: …", „Faellt SAP aus, …", „Bei einem Rueckstau gilt: …",
„Fehlt der Zugang, …".

**Diese Anfaenge sind Beispiele, keine abschliessende Liste.** Eine Bildunterschrift, die
anders beginnt und trotzdem eine Konsequenz nennt, ist richtig. Pruefbar — und deshalb
maschinell gemeldet — ist nur die Verbotsliste:

`Das Interessante …` · `Das zeigt …` · `Das bedeutet …` · `Interessant ist …` ·
`Auffaellig ist …` · `Hier sieht man …` · `Man sieht …` · `Zu sehen ist …` ·
`Die Figur zeigt …` · `Dargestellt ist …`

Sie beschreiben die Figur, statt sie auszuwerten. Der Leser hat die Figur bereits gesehen.

## Druckfassung

Der PDF-Export (`bin/bauplan-pdf.py`) rendert dieselben Dateien mit Chrome und erzwingt
`data-theme="light"`. Fuer den Satz gilt: ein `.sheet` je Seite, `break-inside: avoid-page`
auf Blaettern, Figuren und Pruefpunkten. Wer eine Figur baut, die hoeher als eine A4-Seite
ist, erzeugt einen Seitenumbruch mitten im Bild — Figuren daher unter etwa 640 px
Hoehe halten oder in zwei Figuren teilen.

Beim Zusammenfuehren mehrerer Etappen zu einem PDF werden SVG-IDs je Etappe praefixiert.
Das ist noetig, weil IDs dokumentweit gelten — trotzdem gilt die Regel aus den SVG-Regeln
weiter, IDs je Figur eindeutig zu halten.

## Dunkelmodus

Der Kopf erledigt das vollstaendig, in drei Bloecken: `:root` traegt die komplette helle
Palette, `@media (prefers-color-scheme: dark)` mit
`:root:not([data-theme="light"])` definiert nur Token neu,
`:root[data-theme="dark"]` noch einmal fuer den expliziten Umschalter.

**Nie eine Farbe ausschliesslich innerhalb eines Media- oder `[data-theme]`-Blocks
definieren.** Der Standardfall ist der unmarkierte Zustand — eine Farbe, die es dort nicht
gibt, greift bei den meisten Betrachtern nie.
