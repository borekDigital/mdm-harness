# Spec: Harness-Blattsatz, Etappe 5 „Gesamtstruktur"

Stand: 16. September 2026
Status: UMGESETZT (16. September 2026) — siehe „Umsetzung“ am Ende

## Ziel

Der Harness-Blattsatz erklaert, wie sich die Steuerungsschicht verhaelt — aber nirgends,
**woraus der Workspace eigentlich besteht**. Wer ihn liest, weiss danach, wie CLAUDE.md
erzeugt wird und welche Hooks blockieren, aber nicht, dass acht Repos auf zwei Plattformen
liegen, dass drei davon Storefronts derselben Firma sind, oder dass die Haelfte an einem
System haengt, das im Workspace gar nicht liegt.

Etappe 5 traegt diese Landkarte nach.

## Ist-Zustand

Vier Etappen, alle ueber die Mechanik der Harness:

| Nr | Titel | Gegenstand |
|---|---|---|
| 1 | Aufbau | `.gitignore`-Grenze, CLAUDE.md-Erzeugung, 7-Tage-Check, Bestandsregel |
| 2 | Agenten | zwoelf Agenten und ihre Pipelines |
| 3 | Hooks | elf Hooks und was sie blockieren |
| 4 | Skills und Rules | Skills, Rules, Rechte |

Etappe 1 nennt `workspace.yaml` als Quelle, erklaert aber die **Erzeugung**, nicht den
**Inhalt**: welche Repos darin stehen, wie sie sich gruppieren, was sie miteinander zu tun
haben. Das ist die Luecke.

Abgrenzung zu Etappe 1: Etappe 1 zeigt die Maschine, Etappe 5 das Werkstueck. Etappe 1
beantwortet „wie entsteht CLAUDE.md", Etappe 5 „was steht drin und warum so".

## Soll-Zustand

Eine Etappe, vier Blaetter, je Figur genau eine belegte Aussage (Figuren-Grammatik).

### Blatt 01 — Acht Repos, zwei Plattformen

**Figur:** Matrix (Typ 6). Acht Repos gegen die Eigenschaften Plattform, Gruppe, Technik,
eigener Blattsatz.

**Aussage:** Die Gruppierung in `workspace.yaml` folgt der Plattform, und an derselben
Linie liegt die Team-Grenze — `shopify`/GitHub gegen `middleware`/GitLab. Die Gruppe ist
damit keine Sortierhilfe, sondern beschreibt, wen man fragen muss.

**Belege:** `workspace.yaml` (Feld `group`, `platform`, `remote`).

### Blatt 02 — Drei Themes ohne gemeinsame Historie

**Figur:** Vergleich (Typ 1). Drei Wurzel-Commits nebeneinander, dazwischen die leere
Menge der gemeinsamen Vorfahren; darunter die Deckung als Balken.

**Aussage:** Die Dateideckung ist hoch, die Historie leer. Deshalb wandert eine Aenderung
als Patch und nie als Merge.

**Zahlen (gemessen 16. September 2026):**

| Paar | gemeinsam | identisch | abweichend |
|---|---|---|---|
| mdm / borek | 685 | 620 | 65 |
| mdm / imm | 685 | 617 | 68 |
| borek / imm | 687 | 649 | 38 |

Wurzel-Commits: mdm `7dd3fa4f` (1599 Commits), borek `229fe0a9` (90), imm `73e8f435` (65).

**Belege:** `bin/theme-sync.sh`, `.claude/specs/harness/theme-sync.md`.

### Blatt 03 — Der Knoten liegt ausserhalb

**Figur:** Nachrichtenkanal (Typ 5). SAP in der Mitte, die Repos aussen herum.

**Aussage:** Vier der acht Repos reden mit SAP; untereinander reden sie fast nicht. Der
Workspace enthaelt alle Beteiligten ausser dem, das sie verbindet — SAP ist in keinem Repo
und in keinem Blattsatz.

**Belege (file:line):**

| Kante | Fundstelle |
|---|---|
| connector → SAP | `connector/app/services/sap/api/client.rb:6` |
| connector → creditcheck | `connector/app/services/credit/api/client.rb:25` |
| creditcheck → SAP | `creditcheck/www/composer.json:25` (`mdm-ecom/lib.sap`) |
| emailservice ← SAP | `emailservice/www/src/Controller/SapController.php` |
| emailservice → Emarsys | `emailservice/www/src/Preparer/Emarsys/EmarsysEventRequestPreparerService.php` |
| payment-service → Saferpay | `payment-service/www/src/Handler/PaymentLink/SaferpaySuccessHandler.php` |
| Theme → connector | `connector/config/routes.rb:35–37` (App-Proxy-GraphQL) |

**Einschraenkung:** Diese Fundstellen liegen in den Kind-Repos, nicht im Harness-Repo. Sie
koennen deshalb **nicht** ueber `sources` auf Veraltung ueberwacht werden — das Blatt
traegt seinen Stand im Text.

### Blatt 04 — Die Abdeckung ist ungleich

**Figur:** Matrix (Typ 6). Acht Repos gegen drei Arten von Abdeckung: Rules, Specs,
Blattsatz. Gefuellte Zelle heisst vorhanden, gestrichelte leere Zelle heisst fehlt.

**Aussage:** `datalayer` ist von keiner Rule, keiner Spec und keinem Blattsatz gedeckt —
als einziges Repo von acht faellt es durch jedes Raster.

**Zahlen (gezaehlt 16. September 2026):**

| Abdeckung | gedeckt | Fundstelle |
|---|---|---|
| Rules | 7 von 8 (ohne `datalayer`) | `.claude/rules/*.md`, Feld `paths` |
| Specs | 1 von 8 (`theme-mdm`, 6 Dateien) | `.claude/specs/themes/mdm/` |
| Blattsatz | 2 von 8 (`connector`, `emailservice`) | `.claude/bauplan/*.manifest.json` |

Der dritte Blattsatz (`harness`) beschreibt den Workspace selbst und zaehlt nicht zu den
acht Arbeits-Repos. Die Harness dokumentiert sich damit vollstaendiger als sechs der
Systeme, die sie steuert.

**Belege:** `workspace.yaml`, `.claude/bauplan/*.manifest.json`, `.claude/rules/*.md`,
`.claude/specs/`.

### Pruefpunkte

Am Fuss wie in den anderen Etappen, aus dem, was beim Bauen auffaellt. Mindestens:

1. `datalayer` faellt durch jedes Raster: keine Rule, keine Spec, kein Blattsatz.
   Aenderungen dort laufen ohne Konventionspruefung und ohne Veraltungsmeldung.
2. Die Laufzeit-Kanten aus Blatt 03 sind von keiner `sources`-Regel gedeckt; veraltet dort
   etwas, meldet es niemand.

## Anforderungen

- [x] `docs/bauplan/harness/etappe-05.html` angelegt, Design-Kopf aus
      `assets/bauplan-head.html` (nicht nachgebaut)
- [x] Vier Blaetter mit je einer Figur, je Figur eine Aussage
- [x] Titel ist der Etappenname: `Gesamtstruktur` — ein Wort, keine Zahlen
- [x] Meta-Zeile mit `Gelesen`, `Repos`, `Blätter`, `Stand`
- [x] Legende benennt die vier Farbrollen fuer dieses Blatt
- [x] `.claude/bauplan/harness.manifest.json` um Etappe 5 ergaenzt
      (`nr`, `title`, `blaetter`, `findings`, `sources`, `open_questions`)
- [x] Fusszeile: Etappe 4 zeigt danach auf Etappe 5, Etappe 5 schliesst den Satz ab
      (`bin/bauplan-nav.py`)
- [x] `docs/bauplan/index.html` fuehrt Etappe 5 (`./sync.sh`)

## Akzeptanzkriterien

- [x] `python3 bin/bauplan-guard.py --verify` meldet keinen Verlust und keine Luecke
- [x] `bin/bauplan-nav.py` laeuft zweimal hintereinander mit `0 Fusszeilen verlinkt`
      beim zweiten Mal (Idempotenz)
- [x] Die Uebersicht listet Etappe 5 mit HTML- und Artefakt-Spalte; die Artefakt-URL
      bleibt leer, bis veroeffentlicht wurde
- [x] Jede Zahl im Blatt ist im Anhang mit Fundstelle belegt
- [x] Kein `<script>`, `<style>` oder `<foreignObject>` in den SVG (Design-Vertrag)
- [x] Die Seite enthaelt keinen Hinweis auf KI-Nutzung

## Constraints

- **Artefakt-URL fehlt zunaechst.** Die anderen 20 Etappen tragen eine
  `claude.ai/code/artifact/…`-URL. Etappe 5 bekommt sie erst beim Veroeffentlichen.
  Bis dahin steht im Manifest kein `url`; `bauplan-index.py` und `bauplan-nav.py`
  muessen das aushalten — beide pruefen bereits auf `url`.
- **Etappe 1 ist gleichzeitig veraltet.** Der `themes/`-Umbau hat ihre Quellen
  veraendert (`harness.STALE.md`). Etappe 5 ersetzt diese Auffrischung **nicht**;
  sie bleibt ein offener Posten.
- Blast-Radius: eine neue Datei, ein Manifest-Eintrag, zwei erzeugte Dateien
  (`index.html`, Fusszeile von Etappe 4).


## Umsetzung

Gebaut am 16. September 2026, im selben Zug wie die Fusszeilen-Navigation.

### Was entstand

| Datei | Art |
|---|---|
| `docs/bauplan/harness/etappe-05.html` | neu, 4 Blaetter + Anhang, 179 KB mit Design-Kopf |
| `.claude/bauplan/harness.manifest.json` | Etappe 5 ergaenzt, mit Artefakt-URL |
| `bin/bauplan-nav.py` | neu — Fusszeilen-Navigation aus dem Manifest |

Veroeffentlicht: https://claude.ai/artifact/LJPJrDJCLe1fYAZab3n2kv

### Abweichung von der Spec

**Blatt 04 traegt eine andere Aussage als geplant.** Der Entwurf wollte zeigen, dass
„drei von acht Repos einen Blattsatz haben". Beim Zaehlen stellte sich heraus: es sind
**zwei** von acht — der dritte Blattsatz (`harness`) beschreibt den Workspace selbst und
gehoert nicht zu den acht Arbeits-Repos. Beim Nachzaehlen der uebrigen Abdeckung fiel die
schaerfere Aussage auf: `datalayer` ist von **keiner** Rule, Spec oder Blattsatz gedeckt —
als einziges Repo von acht. Das Blatt traegt jetzt diese Aussage.

### Wirkung auf den uebrigen Blattsatz

Die Aufnahme von Etappe 5 hat zwei Dinge in den vorhandenen Blaettern veraendert, beide
durch `bin/bauplan-nav.py`:

1. Etappe 4 trug „Ende des Blattsatzes“ — jetzt „Als naechstes: Gesamtstruktur“.
2. Alle fuenf Harness-Blaetter zaehlten „von 4“ — jetzt „von 5“.

Beides kommt aus dem Manifest und wird bei jedem `./sync.sh` nachgezogen. Die Zaehlung der
anderen Blattsaetze (Connector „von 9“, Emailservice „von 7“) blieb unberuehrt.

### Offene Posten

- Etappe 1 „Aufbau“ bleibt veraltet (`harness.STALE.md`): der `themes/`-Umbau hat ihre
  Quellen veraendert. Etappe 5 ersetzt diese Auffrischung nicht.
- Die beiden Fehler aus Etappe 1, Blatt 03 („Zwei Fehler im 7-Tage-Check“) sind inzwischen
  behoben — das Blatt beschreibt damit einen Zustand, den es nicht mehr gibt. Beim
  Auffrischen von Etappe 1 gehoert das Blatt umgeschrieben, nicht nur aktualisiert.
