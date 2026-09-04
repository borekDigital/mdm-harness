# Design-Vertrag `bauplan-v1`

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

## Titel

Die These der Etappe, als Name — nicht als Zusammenfassung. Zwei bis fuenf Woerter, ohne
angehaengten Erklaerer nach Bindestrich oder Doppelpunkt. Parallelbau ueber den Satz macht
die Galerie lesbar:

> Zwei Rollen, eine Codebase · Drei Prozesse, eine App · Acht Tabellen, drei Stroeme ·
> Acht Tueren, vier Waechter · Action, API, Transformer · Achtzehn Jobs, drei
> Warteschlangen · Zwei Schemas, zwei Welten · Eine SPA im iframe · Sechs Extensions,
> zwei Images

Die Erklaerung gehoert in den `description`-Parameter beim Veroeffentlichen.

## Dunkelmodus

Der Kopf erledigt das vollstaendig, in drei Bloecken: `:root` traegt die komplette helle
Palette, `@media (prefers-color-scheme: dark)` mit
`:root:not([data-theme="light"])` definiert nur Token neu,
`:root[data-theme="dark"]` noch einmal fuer den expliziten Umschalter.

**Nie eine Farbe ausschliesslich innerhalb eines Media- oder `[data-theme]`-Blocks
definieren.** Der Standardfall ist der unmarkierte Zustand — eine Farbe, die es dort nicht
gibt, greift bei den meisten Betrachtern nie.
