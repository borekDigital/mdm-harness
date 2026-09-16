# Spec: Wording-Regeln schaerfen und den Blattsatz-Bestand nachziehen

Stand: 16. September 2026
Quelle: Review Konrad, 16. September 2026, an Etappe 5 des Harness-Blattsatzes
Status: UMGESETZT (16. September 2026)

## Ziel

Alle Blattseiten unter `docs/bauplan/` folgen demselben Wording. Die Regeln dafuer stehen
mechanisch pruefbar in `design-system.md`, und ein Skript meldet Abweichungen, statt sie
dem Blick zu ueberlassen.

Massstab ist `docs/bauplan/harness/etappe-05.html` (Fassung vom 16. September 2026). Sie
ist am Review entstanden und erfuellt die Regeln als einziges Blatt vollstaendig.

## Ist-Zustand

### Was der Vertrag schon regelt

`design-system.md` hat einen Abschnitt „Wording — technische Dokumentation, kein Essay".
Er regelt Satzbau, „muss/soll/kann", eine Wortliste, Metaphern-Verbot und
Begriffskonsistenz. Diese Regeln sind richtig und bleiben.

### Was fehlt

Vier Luecken, alle am Review von Etappe 5 aufgefallen:

| Luecke | Wirkung im Bestand |
|---|---|
| Die 1–3-Wort-Regel gilt nur fuer den Etappentitel (H1), nicht fuer Blatt-Ueberschriften (H2) | 83 von 105 H2 sind laenger, viele sind Thesen statt Namen |
| Leseransprache ist nicht verboten | `man` und `wer` in 18 von 22 Blaettern |
| Die Wortliste kennt Wertungen wie `bemerkenswert` nicht | 10 Fundstellen in 8 Blaettern |
| Die Metaphern-Regel nennt keine Ausnahmen | etabliertes Vokabular wird mitgetroffen (siehe unten) |

### Bestandsaufnahme (gemessen 16. September 2026)

22 Blattseiten: 20 Etappen aus drei Blattsaetzen, dazu `bedienung.html` und
`harness/etappe-05.html`. `index.html` ist erzeugt und faellt nicht darunter.

| Befund | Umfang |
|---|---|
| H2 laenger als drei Woerter | **83 von 105 (79 %)** |
| Blaetter mit Leseransprache (`man`, `wer`, `dein`, `unser`) | **18 von 22** |
| Blaetter mit Wortlisten-Treffer | 8 von 22 |
| Blaetter mit Metapher | 5 von 22 |
| H1 laenger als drei Woerter | 2 von 22 |
| Bildunterschrift mit verbotenem Anfang | **0 von 78** |
| Blaetter ohne Befund | **1 von 22** (`harness/etappe-05.html`) |

Je Blattsatz:

| Blattsatz | Blaetter | H2 zu lang | Ansprache | Wortliste | Metapher |
|---|---|---|---|---|---|
| connector | 9 | 38 | 7 Blaetter | 5 | 3 |
| emailservice | 7 | 27 | 6 Blaetter | 0 | 2 |
| harness | 5 | 16 | 4 Blaetter | 5 | 2 |
| bedienung.html | 1 | 2 | 1 Blatt | 0 | 0 |

Wortlisten-Fundstellen im Detail: `sollte` (4), `bemerkenswert` (2), `erstaunlich`,
`elegant`, `absurd`, `durchaus` (je 1).
Metaphern: `Knoten` (2), `Tor`, `Herzschlag`, `Uhrwerk`, `Geschwister`, `Fremde` (je 1).
H1 zu lang: `connector/etappe-03` („Acht Tabellen, zwei Ströme"),
`connector/etappe-09` („Sieben Extensions, zwei Images").

### Zwei Korrekturen an der ersten Messung

Ein erster Messlauf meldete 65 fehlerhafte Bildunterschriften und `Kette` als Metapher in
fuenf Blaettern. Beides war falsch gemessen:

1. **Bildunterschriften.** `design-system.md` nennt zulaessige Anfaenge als **Beispiele**
   („Relevant beim Erweitern: …", „Faellt SAP aus, …"), nicht als abschliessende Liste.
   Als Whitelist gelesen schlaegt die Pruefung bei jeder korrekten Bildunterschrift an, die
   anders beginnt. Gegen die im Vertrag genannten **verbotenen** Anfaenge gemessen:
   null Treffer. Die Bildunterschriften im Bestand sind in Ordnung.
2. **`Kette` und `sauber`.** `figure-grammar.md` fuehrt „Kette mit Rueckkanal" als
   Figurtyp 2; „sauberer Arbeitsbaum" ist der Git-Begriff. Beides ist etabliertes
   Vokabular, keine Metapher.

Daraus folgt eine Regel fuer das Werkzeug: **Eine Pruefung, die nicht entscheidbar ist,
wird nicht als Verstoss gemeldet.** Sie gehoert in eine getrennte Liste zur Durchsicht.

## Soll-Zustand

### A. Regelaenderungen in `design-system.md`

**A1 — Ueberschriften: ein bis drei Woerter, Substantivphrase.**
Die Regel, die heute im Abschnitt „Titel" fuer den H1 steht, gilt auch fuer die H2 der
Blaetter und fuer die Anhang-Ueberschrift. Begruendung wie beim H1: die Ueberschrift
benennt den **Gegenstand**, nicht die Aussage. Aussagen und Zahlen veralten, Namen nicht.
Die Aussage steht im Anriss und in der Bildunterschrift, wo sie belegt werden kann.

| Statt | Besser |
|---|---|
| „Die Gruppe sagt, wen man fragen muss" | „Gruppen und Plattformen" |
| „Drei Wurzel-Commits, kein gemeinsamer Vorfahr" | „Historie und Deckung" |
| „Der Knoten liegt ausserhalb des Workspace" | „Kopplung über SAP" |
| „Der Drift-Melder laeuft, und niemand sieht ihn" | „Drift-Meldung" |

Keine Frage-Form („Was ein Hook nicht kann"), kein Satz mit finitem Verb, keine Zahl.

**A2 — Keine Leseransprache.**
Verboten: `man`, `wer … der …`, `du`, `dein`, `unser`, `Sie`. Der Blattsatz beschreibt das
System, nicht die Lektuere. Statt „Wer eine Aenderung plant, kann sie nicht zu Ende lesen"
steht „Der Ablauf ist im Workspace nicht vollstaendig lesbar".

Ausnahme: Die Bedienungsanleitung (`bedienung.html`) darf den Imperativ verwenden
(„Blattsatz mit `/repo-bauplan <repo>` erzeugen"), aber keine Anrede.

**A3 — Wortliste um Wertungen erweitern.**
Zusaetzlich verboten: `bemerkenswert` · `erstaunlich` · `ueberraschend` · `absurd` ·
`elegant` · `durchaus` · `eigentlich` · `quasi` · `relativ` · `ziemlich` · `leider`.
Begruendung wie bisher: sie ersetzen eine Zahl oder eine Bedingung durch eine Haltung.

**A4 — Metaphern-Verbot mit Ausnahmeliste.**
Der Abschnitt nennt kuenftig ausdruecklich, was **kein** Verstoss ist, weil es Fachbegriff
oder Figurtyp ist: `Kette` (Figurtyp 2), `sauber`/`unsauber` (Git-Zustand des
Arbeitsbaums), `Baum` (Git), `Wurzel` (Git), `Zweig`/`Branch`, `Knoten` **nur** in
Graph-Zusammenhang.
Verboten bleiben Bilder ohne Fachbezug: `Herzschlag`, `Uhrwerk`, `Taktgeber`,
`Fliessband`, `Geschwister`, `Fremde`, `Nervensystem`, `Rueckgrat`, `Ader`, `Landkarte`.

**A5 — Bildunterschrift: Regel als Verbotsliste.**
Die heutige Formulierung nennt zulaessige Anfaenge. Sie wird ergaenzt um: „Diese Anfaenge
sind Beispiele, keine abschliessende Liste. Pruefbar ist die Verbotsliste." Verboten:
`Das Interessante …`, `Das zeigt …`, `Interessant ist …`, `Auffaellig ist …`,
`Hier sieht man …`, `Die Figur zeigt …`, `Dargestellt ist …`.

**A6 — Eyebrow wiederholt den H1 nicht wortgleich.**
Der H1 traegt den Namen, die Eyebrow-Zeile die Einordnung:
`MDM Harness · Etappe 5 · Repos und Kopplung` zu `<h1>Gesamtstruktur</h1>`.

### B. Werkzeug `bin/bauplan-wording.py`

Ein Pruefer, zwei Ausgabeklassen — die Trennung ist der Kern:

**Verstoesse** (mechanisch entscheidbar, Exit 3):
H1/H2 laenger als drei Woerter · H2 mit finitem Verb oder Fragezeichen · Wortliste ·
Leseransprache · verbotener Bildunterschriften-Anfang · Eyebrow gleich H1.

**Zur Durchsicht** (nicht entscheidbar, Exit 0):
Metaphern-Kandidaten · Bildunterschriften ohne erkennbare Konsequenz · Saetze ueber
25 Woerter · Passivkonstruktionen.

Aufrufe:

```
bin/bauplan-wording.py                     alle Blattseiten
bin/bauplan-wording.py --repo harness      ein Blattsatz
bin/bauplan-wording.py --datei <pfad>      eine Seite
bin/bauplan-wording.py --json              maschinenlesbar, fuer CI
```

**Einbindung:** kein blockierender Hook. Prosa laesst sich nicht wie ein Linter behandeln,
und ein blockierter Write mitten im Schreiben eines Blattes kostet mehr, als er bringt.
Stattdessen:

- `./sync.sh` ruft den Pruefer und meldet die Summe je Blattsatz als Warnung.
- `/repo-bauplan <repo>` laeuft vor der Uebergabe gegen den erzeugten Satz, Exit 3
  verhindert den Abschluss.
- Die CI (`.github/workflows/bauplan-refresh.yml`) meldet Verstoesse, ohne rot zu werden —
  wie der Staleness-Lauf.

### C. Rueckbau des Bestands

Reihenfolge nach aufsteigendem Umfang, damit die Regel am kleinsten Satz erprobt wird:

| Schritt | Gegenstand | H2 zu lang | Aufwand |
|---|---|---|---|
| 1 | `harness/` (Etappen 1–4; 5 ist Massstab) | 16 | klein |
| 2 | `bedienung.html` | 2 | klein |
| 3 | `emailservice/` (7 Etappen) | 27 | mittel |
| 4 | `connector/` (9 Etappen) | 38 | gross |

Je Blatt:

1. `bin/bauplan-wording.py --datei <pfad>` — Befunde lesen.
2. H2 auf ein bis drei Woerter kuerzen. Die bisherige Aussage geht **nicht verloren**: sie
   wandert in den Anriss, falls sie dort nicht ohnehin steht.
3. Leseransprache aufloesen, Wortliste und Metaphern ersetzen.
4. Erneut pruefen, bis der Pruefer null Verstoesse meldet.
5. Blatt neu veroeffentlichen — **dieselbe Artefakt-URL**, nicht eine neue.

**Fakten bleiben unberuehrt.** Dieser Rueckbau aendert Formulierungen, keine Aussagen.
Faellt dabei ein sachlicher Fehler auf, wird er als eigener Befund notiert und getrennt
behandelt — nicht stillschweigend mit umgeschrieben. Beim Haerten von Etappe 5 traten zwei
solche Fehler auf; das ist die erwartete Groessenordnung je Blattsatz, nicht je Blatt.

## Anforderungen

- [x] `design-system.md`: A1 bis A6 eingearbeitet, jeweils mit Begruendung und
      Gegenbeispiel aus dem Bestand
- [x] `figure-grammar.md`: Verweis auf die Ausnahmeliste aus A4, damit „Kette" dort nicht
      gegen den Wording-Abschnitt steht
- [x] `bin/bauplan-wording.py` angelegt, mit der Trennung Verstoss / zur Durchsicht
- [x] `sync.sh` ruft den Pruefer und warnt; `repo-bauplan/SKILL.md` nennt ihn in der
      Werkzeug-Tabelle und im Abschluss-Schritt
- [x] Rueckbau Schritt 1–4 durchgefuehrt
- [x] Jedes geaenderte Blatt neu veroeffentlicht, Artefakt-URL unveraendert
- [x] `.claude/bauplan/*.manifest.json`: `title` nachgezogen, wo ein H1 gekuerzt wurde
      (`connector` Etappe 3 und 9)

## Akzeptanzkriterien

- [x] `bin/bauplan-wording.py` meldet ueber alle 22 Blattseiten **null Verstoesse**
- [x] `bin/bauplan-wording.py --json` liefert gueltiges JSON mit je Blatt einer Liste
      `verstoesse` und einer Liste `durchsicht`
- [x] Kein H1 und kein H2 im Bestand ist laenger als drei Woerter
- [x] `grep -riE '\b(man|wer)\b'` ueber `docs/bauplan/*/etappe-*.html` liefert keinen
      Treffer in Prosa (Code-Beispiele ausgenommen)
- [x] Die Zahl der Blaetter, Figuren und Pruefpunkte je Etappe ist unveraendert —
      der Rueckbau kuerzt Formulierungen, nicht Inhalt
- [x] `python3 bin/bauplan-guard.py --verify` meldet keinen Verlust
- [x] Jede Artefakt-URL aus den Manifesten laedt weiterhin; keine neue URL entstanden
- [x] `bin/bauplan-pdf.py <repo>` erzeugt alle drei Saetze fehlerfrei

## Constraints

- **21 Artefakte muessen neu veroeffentlicht werden.** Die URLs stehen in den Manifesten
  und sind an Kollegen weitergegeben. Ein Blatt bekommt beim Neuveroeffentlichen
  **dieselbe** URL, sonst laufen geteilte Links ins Leere. Aus einer Sitzung, die das
  Artefakt nicht selbst angelegt hat, geht das nur ueber den `url`-Parameter.
- **Die `description` beim Veroeffentlichen mitgeben.** Laesst man sie weg, bleibt die
  zuletzt gespeicherte stehen — bei geaendertem Titel ist sie dann falsch
  (`design-system.md`, Abschnitt Beschreibung).
- **Der Rueckbau macht jedes Blatt „veraltet" im Sinne des Staleness-Mechanismus nicht** —
  er beruehrt keine `sources`. Die Blaetter aendern sich, ihre Quellen nicht. Der
  Guard-Verify laeuft trotzdem mit, weil Dateien geschrieben werden.
- **Zwei Blattsaetze beschreiben Repos, deren Blattsatz veraltet ist.** `harness` Etappe 1
  steht in `harness.STALE.md`. Der Wording-Rueckbau ersetzt diese Auffrischung nicht; er
  laeuft davor oder danach, nicht statt ihrer.
- Blast-Radius: 22 HTML-Dateien, 2 Manifest-Felder, `design-system.md`,
  `figure-grammar.md`, `SKILL.md`, `sync.sh`, eine neue Datei unter `bin/`.

## Nebenbefund — eigener Commit, eigene Spec

Beim Pruefen der CI-Behauptungen dieser Spec fielen zwei Defekte auf, die mit Wording
nichts zu tun haben: die Aufloesung des Repo-Pfads aus einem Manifest ist an zwei von vier
Stellen falsch, und der Warntext der CI nennt einen Repo-Schluessel, den es nicht mehr
gibt. Beides ist heute wirkungslos und bricht, sobald ein Theme-Blattsatz entsteht.

Aufgenommen in `.claude/specs/harness/bauplan-repo-pfad.md`. **Eigener Commit**, getrennt
von den Wording-Commits — andere Dateien, andere Begruendung.

## Offene Entscheidung

**Wie streng ist die 1–3-Wort-Regel fuer den Anhang?** Die Anhang-Ueberschriften lauten
heute „Drei Pruefpunkte, nicht belegt" (connector/02) oder „Pruefpunkte und Fundstellen"
(harness/05). Die erste traegt eine Zahl, die veraltet, sobald ein Pruefpunkt dazukommt —
genau der Grund, aus dem der Vertrag Zahlen aus Titeln verbannt. Vorschlag: `Anhang`
traegt immer „Pruefpunkte und Fundstellen", ohne Zahl. Zu entscheiden vor Schritt 1.


## Fortschritt

### Erledigt am 16. September 2026

**Regeln (A1–A6)** in `design-system.md` eingearbeitet. Der Abschnitt „Titel" heisst jetzt
„Titel und Ueberschriften" und traegt die 1–3-Wort-Regel fuer H1 **und** H2, dazu die
Eyebrow-Regel. Neu: „Keine Leseransprache". Die Wortliste ist in zwei Gruppen geteilt
(unscharfe Mengen, Wertungen). Das Metaphern-Verbot hat eine Ausnahmeliste fuer
Fachvokabular und unterscheidet `sauber` als Wertung von `sauberer Arbeitsbaum` als
Git-Zustand. Die Bildunterschriften-Regel ist als Verbotsliste formuliert.
`figure-grammar.md` verweist bei Figurtyp 2 auf die Ausnahmeliste, damit „Kette" dort
nicht gegen den Wording-Abschnitt steht.

**Werkzeug** `bin/bauplan-wording.py` angelegt, eingebunden in `sync.sh` (nicht
blockierend) und in `repo-bauplan/SKILL.md` (Gate vor der Uebergabe).

Zwei Dinge fielen beim Bauen des Werkzeugs auf und sind behoben:

1. Die Satzlaengen-Pruefung mass anfangs SVG-Beschriftungen und Tabellenzellen als Saetze
   und meldete Wortketten von 93 Woertern. Sie laeuft jetzt nur ueber `<p>` und
   `<figcaption>`. Die uebrigen Pruefungen lesen weiterhin alles — eine Leseransprache in
   einer SVG-Beschriftung ist genauso ein Verstoss.
2. `sync.sh` brach still ab, weil der Pruefer Exit 3 liefert und `set -e` die
   Kommandosubstitution mitriss. Exit 3 heisst „Verstoesse gefunden", nicht „Lauf kaputt".

**Rueckbau Schritt 1** — `harness/` Etappen 1 bis 4, 32 Stellen:

| Blatt | Ueberschriften vorher → nachher |
|---|---|
| 01 | „Die Grenze verlaeuft durch die .gitignore" → `.gitignore als Grenze` · „CLAUDE.md wird erzeugt, nicht geschrieben" → `Erzeugung der CLAUDE.md` · „Zwei Fehler im 7-Tage-Check, die sich maskieren" → `7-Tage-Check` · „Bestand kommt aus dem Manifest, nicht vom Dateisystem" → `Bestand und Manifest` |
| 02 | „Die Kette hat ein Tor in der Mitte" → `Pipeline und Freigabe` · „Vier Rollen, dreimal ausgefuehrt" → `Rollen und Bereiche` · „Modell und Denkaufwand folgen der Rolle" → `Modell und Denkaufwand` · „Schreibrechte: vier gesperrt, acht auf Zuruf" → `Schreibrechte` |
| 03 | „Drei Ereignisse, drei Wirkungsarten" → `Ereignisse und Wirkung` · „Was technisch unmoeglich ist" → `Abbruchpfade` · „Der Drift-Melder laeuft, und niemand sieht ihn" → `Drift-Meldung` · „Was ein Hook nicht kann" → `Grenzen eines Hooks` |
| 04 | „Die Drift geht in beide Richtungen" → `Skills und README` · „Wo Rules greifen, und wo nicht" → `Geltung der Rules` · „17 Rechte erlaubt, 2 verboten" → `Rechte in settings.json` · „Spec-Driven: 17 Dateien, 7 Bereiche" → `Spec-Bestand` |

Stand: **22 Blattseiten, 5 ohne Verstoss, 100 Verstoesse** (vorher 125).

### Sachliche Altlasten — getrennt behandeln, nicht mit umgeschrieben

Beim Rueckbau aufgefallen, aber nach der Regel dieser Spec nicht angefasst:

1. **`harness/etappe-01`, Blatt 03** beschreibt zwei Fehler im 7-Tage-Check als bestehend.
   Beide sind am 16. September 2026 behoben (`sync.sh`: gieriges `sed`, und die
   Reihenfolge von `update_local_timestamps` gegenueber `check_consistency`). Das Blatt
   beschreibt einen Zustand, den es nicht mehr gibt, und gehoert beim Auffrischen
   **umgeschrieben**, nicht aktualisiert.
2. **`harness/etappe-04`, Blatt 03** nennt `*/theme/config/settings_data.json`. Seit dem
   `themes/`-Umbau lautet das Muster `*/themes/*/config/settings_data.json`.
3. **`harness/etappe-01`** spricht durchgehend von „sechs Repos". Seit dem `themes/`-Umbau
   sind es acht.

Alle drei gehoeren zur Auffrischung von Etappe 1 und 4, die in `harness.STALE.md` ohnehin
ansteht.

### Offen

- Rueckbau Schritt 2 (`bedienung.html`), 3 (`emailservice/`), 4 (`connector/`)
- Neuveroeffentlichung der geaenderten Blaetter auf **dieselbe** Artefakt-URL. Fuer die
  vier Blaetter aus Schritt 1 noch nicht ausgefuehrt — bewusst, damit der Stand lokal
  begutachtet werden kann, bevor 21 Artefakte wandern.


## Abschluss

Rueckbau vollstaendig am 16. September 2026. `bin/bauplan-wording.py` meldet ueber alle
22 Blattseiten **null Verstoesse**.

| Schritt | Gegenstand | Stellen | Commit |
|---|---|---|---|
| 1 | `harness/` Etappen 1–4 | 32 | Teil von `7c89692` |
| — | Altlasten in Etappe 1 und 4 | 17 | `6071439` |
| 2+3 | `bedienung.html`, `emailservice/` | 51 | `b42161f` |
| 4 | `connector/` | 51 | `10e9f25` |

Gesamt 151 Stellen. 125 Verstoesse zu Beginn, 0 am Ende.

### Beim Rueckbau zusaetzlich gefunden

1. **Zwei H1 wichen vom Manifest ab.** `connector/etappe-03` hiess im Blatt
   „Acht Tabellen, zwei Stroeme", im Manifest `Datenmodell`; Etappe 9 entsprechend
   „Sieben Extensions, zwei Images" gegen `Deploy`. Die Manifeste trugen also bereits die
   richtigen Namen — die Blaetter waren abgewichen. Das Kuerzen hat sie zusammengefuehrt,
   kein Manifest musste geaendert werden.
2. **Zwei Eyebrow-Zeilen wurden erst durch das Kuerzen zu Duplikaten.** Wird ein H1 auf den
   Manifest-Namen gekuerzt, kann die Eyebrow-Zeile ihn wortgleich wiederholen. Bei
   `connector/etappe-03` trat das auf und wurde zu „Tabellen und Modelle" geaendert.
   Die Regel A6 faengt das, weil der Pruefer beides vergleicht.
3. **Drei Wertungen in Bildunterschriften**, die keine Ueberschrift betrafen:
   `erstaunlich klein`, `Elegant und riskant`, `bemerkenswert`. Alle durch die Zahl oder
   die Eigenschaft ersetzt, die daneben ohnehin stand.
4. **Eine Tabellenspalte hiess „Wer".** Im Fliesstext faellt Leseransprache auf, in einem
   `<th>` nicht. Der Pruefer liest den gesamten Blattkoerper und hat sie gemeldet —
   Beleg dafuer, dass die Pruefung nicht auf `<p>` beschraenkt sein darf.

### Was offen bleibt

- **Neuveroeffentlichung.** Alle 22 Blattseiten sind lokal geaendert, aber nur
  `harness/etappe-05` ist veroeffentlicht. Die uebrigen 21 tragen im Artefakt noch die
  alten Ueberschriften. Jede geht auf **dieselbe** URL zurueck, sonst laufen geteilte
  Links ins Leere.
- 28 Hinweise „zur Durchsicht" (lange Saetze, Metaphern-Kandidaten). Sie sind keine
  Verstoesse und werden bei der naechsten Auffrischung der jeweiligen Etappe entschieden.
