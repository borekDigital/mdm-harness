---
name: repo-bauplan
description: "Erzeugt einen visuellen Architektur-Blattsatz fuer ein Repo im Workspace — nummerierte Etappen als Artifact-Seiten mit Inline-SVG-Figuren, jede Figur mit genau einer belegten Aussage, plus Anhang mit Fundstellen. Nutzen bei: Onboarding in ein unbekanntes Repo, Architektur verstehen, Wissenstransfer, Uebergabe an Kollegen, /repo-bauplan <repo>."
user_invocable: true
---

# /repo-bauplan — Architektur-Blattsatz fuer ein Repo

Erzeugt eine Reihe von Artifact-Seiten im **Bauplan-Stil**: technische Zeichnung,
Millimeterpapier, nummerierte Blaetter, durchgaengige Farbkodierung. Jede Seite deckt
eine Etappe ab, jede Figur trifft genau eine Aussage, jede Aussage ist mit
`Datei:Zeile` belegt.

Referenz-Ergebnis: der Connector-Blattsatz vom 3. September 2026, neun Etappen.

## Aufruf

```
/repo-bauplan <repo>                    kompletter Blattsatz
/repo-bauplan <repo> --etappe <n>       nur eine Etappe (neu oder aktualisiert)
/repo-bauplan <repo> --plan             nur den Etappenplan, ohne zu bauen
/repo-bauplan <repo> --refresh          veraltete Etappen aus dem Staleness-Ledger neu bauen
```

`<repo>` ist ein Schluessel aus `workspace.yaml`: `theme`, `connector`, `datalayer`,
`creditcheck`, `emailservice`, `payment-service`.

## Grundgesetz — nicht verhandelbar

1. **Nie zeichnen, was nicht gelesen wurde.** Vor jeder Figur die Dateien vollstaendig
   lesen, die sie behauptet. Keine Annahmen ueber Dateiinhalte.
2. **Jede Aussage traegt ihren Beleg.** `Datei:Zeile` im Text der Figur oder in der
   Bildunterschrift. Bei Zeilenbereichen `Datei:12–18`.
3. **Drei Evidenzstufen, sichtbar getrennt.**
   - **Belegt** — direkt aus gelesenem Code ableitbar. Normale Darstellung.
   - **Vermutung** — plausibel, nicht bewiesen. Mit `⚠️ Vermutung:` kennzeichnen und
     sagen, was zum Beweis fehlt.
   - **Unbekannt** — nur zur Laufzeit oder mit DevOps-Zugriff pruefbar. Als offene Frage
     notieren, spaeteren Etappen zur Klaerung uebergeben.
4. **Offene Fragen werden geschlossen.** Wenn eine spaetere Etappe eine `⚠️`-Frage einer
   frueheren beantwortet, das ausdruecklich im Anhang festhalten („schliesst die offene
   Frage aus Etappe 4, Anhang 04").
5. **Deutsch.** Alle Seiten, Bildunterschriften und Anhaenge auf Deutsch, Datumsformat
   `3. September 2026`. Code, Bezeichner und Dateipfade bleiben im Original.

## Phasen

### Phase 0 — Aufklaerung

Repo-Wurzel aus `workspace.yaml` auflösen. Dann in dieser Reihenfolge:

1. Wurzel-Listing plus alle Konfig- und Manifest-Dateien
   (`README*`, `package.json`, `Gemfile`, `composer.json`, `*.toml`, `Dockerfile*`,
   `docker-compose*`, `Procfile*`, `.env.template`, CI-Definitionen)
2. Verzeichnisbaum zwei Ebenen tief, plus Dateizahlen und Zeilenzahlen je Bereich
3. Vorhandene Projektdoku (`docs/`, `README`) — **als Behauptung lesen, nicht als
   Wahrheit.** Abweichungen zum Code sind wertvolle Funde.

**Merken:** die Zeilenzahlen. Wo das Gewicht liegt, ist selbst eine Erkenntnis.

### Phase 1 — Etappenplan

Etappen **aus dem Repo ableiten**, nicht aus einer Vorlage. Reihenfolge nach dem Prinzip
*aussen nach innen, dann Zustand vor Verhalten*:

| Rang | Frage, die die Etappe beantwortet |
|---|---|
| 1 | Was ist das Ding, und welche Sprachen und Abhaengigkeiten hat es? |
| 2 | Wie kommt es hoch, welche Prozesse laufen? |
| 3 | Welche Daten haelt es? (Schema, Modelle, Zustandsmaschinen) |
| 4 | Wer kommt herein? (Routing, Einstiegspunkte, Auth) |
| 5 | Wie ist die Fachlogik geschnitten? (Muster, Schichten) |
| 6 | Was passiert asynchron? (Jobs, Queues, Cron, Events) |
| 7 | Welche Schnittstellen gibt es nach draussen? |
| 8 | Wie sieht das UI aus, falls es eines gibt? |
| 9 | Wie kommt es raus? (Build, Deploy, CI, Tests) |

Nicht jedes Repo braucht neun. Ein reines Frontend-Repo hat kein Datenmodell; ein
Datalayer-Repo hat weder Prozesse noch Deploy in diesem Sinn. **Streiche, was leer waere,
statt eine Etappe mit Fuellmaterial zu strecken.** Als Richtwert: 4–9 Etappen.

Bei `--plan` hier anhalten und den Plan als Tabelle im Chat vorlegen. Sonst weiter.

### Phase 2 — Etappe bauen

Fuer jede Etappe, eine nach der anderen:

**2a. Lesen.** Alle Dateien der Etappe, vollstaendig. Bei sehr grossen Dateien
(500+ Zeilen) den relevanten Abschnitt gezielt, aber nie nur die ersten 50 Zeilen und
dann raten. Ergaenzend `grep` einsetzen, um Verwendung zu pruefen — „ist diese Funktion
ueberhaupt aufgerufen" ist eine der ertragreichsten Fragen.

**2b. Den Befund benennen.** Eine Etappe hat **einen** Satz, der die Struktur
beschreibt, die sie zeigt. Er wird zum Seitentitel und nennt Komponente plus Zahl —
sachlich, nicht zugespitzt. `Messenger: 3 Queues, 11 Handler`, nicht „Der Versand ist ein
Fliessband". Titelmuster und Wording-Regeln: `design-system.md`.

Findest du keinen Befund, hast du noch nicht genug gelesen.

**2c. Figuren planen.** 4–6 Figuren je Etappe. Grammatik und Antimuster:
`figure-grammar.md` in diesem Skill-Ordner. Kurzfassung:

- Eine Figur = **eine** Aussage. Zwei Aussagen = zwei Figuren.
- Zeichne den **Mechanismus**, nicht seine Bezeichnung. Ein Kasten mit „Cache" sagt
  weniger als der Weg, den eine Anfrage durch ihn nimmt.
- **Kanten beschriften.** Ein unbeschrifteter Pfeil heisst „irgendwie verwandt".
  `schreibt`, `quittiert`, `alle 2 Min`, `nur ausgehend` sind Information.
- Vergleichst du zwei Varianten, **zeichne die Differenz** — nebeneinander, mit derselben
  Rasterung, damit das Auge die Abweichung findet.
- Zahlen, die du gezaehlt hast, gehoeren als Balken oder Zaehler in die Figur.
- Die Fachsprache des Projekts ist Inhalt, nicht Dekoration: `Satzart14`, `sammelgebiet`,
  `ZSD_ECOM_REST_ORDERTRANSFER_SRV`, `purchase.checkout.block.render`.

**2d. Schreiben.** Aufbau jeder Seite:

```
Titelblock       Eyebrow, These als H1 (zwei Zeilen), Anriss, Meta-Zeile
Legende          die Farbkodierung dieser Seite
Blatt 01..0n     Blattnummer, H2, Anriss, optional Code-Block, Figur, Bildunterschrift
Anhang           4–6 Beobachtungen, nummeriert, je mit Beleg und Konsequenz
Footer           Etappe n von m, Ausblick auf die naechste
```

Die **Bildunterschrift ist nicht die Wiederholung der Figur.** Sie sagt, warum die Figur
zaehlt — die Konsequenz fuer jemanden, der morgen in diesem Code arbeitet.

Der **Anhang** ist der zweitwichtigste Teil der Seite. Jede Beobachtung hat:
Titel als Aussagesatz, Beleg mit `Datei:Zeile`, Konsequenz, und wo sinnvoll den
naheliegenden Fix in einem Satz. Design-Entscheidungen (keine Fehler) gehoeren dazu und
werden als solche benannt.

**2e. Bauen, ablegen, veroeffentlichen.** Die HTML-Quelle liegt **im Repo**, nicht im
Scratchpad. Das ist die Grundlage von Historie, PDF-Export und CI — ein Blattsatz, dessen
Quelle nur als veroeffentlichte Seite existiert, ist nicht pflegbar.

1. `assets/bauplan-head.html` aus diesem Skill-Ordner als Kopf verwenden — nicht neu
   schreiben. Design-Vertrag: `design-system.md`.
2. Body im Scratchpad schreiben, dann zusammensetzen und **als Quelle ablegen**:

   ```bash
   { echo '<title>Befund</title>'; cat .claude/skills/repo-bauplan/assets/bauplan-head.html; \
     cat "$SCRATCH/body.html"; } > docs/bauplan/<repo>/etappe-NN.html
   ```

   Die Datei ist ein **Fragment**, kein vollstaendiges Dokument: kein `<!doctype>`, kein
   `<html>`, `<head>` oder `<body>`. Genau so nimmt das Artifact-Tool sie an; PDF-Export
   und Browser-Vorschau ergaenzen den Rahmen selbst.
3. Pruefen: `<text` und `</text>` muessen gleich oft vorkommen. Unbalancierte SVG-Tags
   sind der haeufigste Fehler.

   ```bash
   f=docs/bauplan/<repo>/etappe-NN.html
   echo "$(grep -o '<text[ >]' "$f" | wc -l) offen / $(grep -c '</text>' "$f") zu"
   ```
4. `Artifact` mit `file_path` auf **diese** Datei, plus `description` und Emoji-`favicon`.
   Beim erneuten Veroeffentlichen derselben Etappe: `url` aus dem Manifest mitgeben und
   **dasselbe** `favicon` erneut setzen. Das Feld ist auch beim Aktualisieren Pflicht
   (belegt am 10. September 2026: `favicon required to publish`) — weglassen geht nicht,
   aendern verwirrt, weil Betrachter die Seite am Icon wiederfinden. Deshalb steht das
   Icon im Manifest.

Eine bereits veroeffentlichte Seite, deren Quelle im Repo fehlt, holt
`bin/bauplan-import.py --repo <repo> --nr <n> --from-file <webfetch-datei>` zurueck.

### Phase 3 — Manifest schreiben

Nach jeder Etappe `.claude/bauplan/<repo>.manifest.json` fortschreiben. **Das ist der
Teil, der den Blattsatz von einem Einmal-Artefakt zu einem pflegbaren macht:**

```json
{
  "repo": "connector",
  "design_system": "bauplan-v1",
  "generated": "2026-09-03",
  "last_seen_sha": "a1b2c3d",
  "etappen": [
    {
      "nr": 1,
      "title": "Zwei Rollen, eine Codebase",
      "url": "https://claude.ai/code/artifact/7fac8e25-...",
      "favicon": "📇",
      "blaetter": 4,
      "findings": 3,
      "sources": ["README.md", "package.json", "Gemfile", "docs/overview.md"],
      "open_questions": [],
      "closes": []
    }
  ]
}
```

- `sources` — repo-relative Pfade **oder** Glob-Muster (`app/jobs/**`). Aus dieser Liste
  leitet der Staleness-Hook ab, welche Etappe eine Aenderung betrifft. Vollstaendigkeit
  hier ist wichtiger als Kuerze.
- `url` — damit `--refresh` an dieselbe Adresse veroeffentlicht statt eine zweite Seite
  anzulegen.
- `open_questions` / `closes` — die `⚠️`-Kette zwischen den Etappen.
- `last_seen_sha` — Commit des Arbeits-Repos, gegen den der Satz gebaut wurde. Die CI
  vergleicht ihn mit `HEAD` und leitet daraus ab, was veraltet ist. Nach jedem
  vollstaendigen Lauf fortschreiben:
  `git -C <repo> rev-parse HEAD`.

Schreiben ueber `bin/bauplan_lib.py` (`save_manifest`) oder direkt — in jedem Fall
**vollstaendig**: eine Etappe wird aktualisiert, niemals entfernt (siehe Bestand).

### Phase 4 — Uebergabe

Im Chat: Tabelle aller Etappen mit Links, dann **drei Abschnitte**:

1. **Was erst im Zusammenhang sichtbar wurde** — Erkenntnisse, die keine einzelne Etappe
   hergibt. Das ist der eigentliche Mehrwert gegenueber „Doku lesen".
2. **Geschlossene offene Fragen** — welche `⚠️` durch welche Etappe beantwortet wurde.
3. **Baustellen nach Wirkung sortiert** — maximal fuenf, jede mit `Datei:Zeile` und einem
   Satz zur Folge. Nicht nach Schwere der Formulierung sortieren, sondern danach, was im
   Betrieb wehtut.

Zum Abschluss: Memory-Eintrag mit den URLs anlegen (`type: reference`), Zeiger in
`MEMORY.md`.

## Auffrischen — nur das Veraltete

`--refresh` ist ein chirurgischer Eingriff. Die Versuchung, „bei der Gelegenheit" auch
andere Blaetter zu verbessern, ist der Weg zu einem Diff, den niemand mehr reviewen kann.

1. **Arbeitsliste holen.** `.claude/bauplan/<repo>.STALE.md` oder
   `bin/bauplan-stale.py --repo <repo>`. Nur die dort genannten Etappen sind im Auftrag.
2. **Zulaessige Dateien notieren.** Genau eine HTML-Quelle je veralteter Etappe, plus das
   Manifest. Mehr nicht.
3. **Je Etappe:** die geaenderten Quelldateien lesen, dann die betroffenen Blaetter
   anpassen. Blaetter derselben Etappe, deren Quellen sich nicht geaendert haben, bleiben
   Zeichen fuer Zeichen gleich.
4. **Diff pruefen**, bevor veroeffentlicht wird:

   ```bash
   git -C . diff --name-only -- docs/bauplan .claude/bauplan
   ```

   Steht dort eine Datei, die nicht auf der Liste aus Schritt 2 war, ist das ein Fehler —
   zurueckrollen, nicht nachtraeglich rechtfertigen.
5. **Nur die betroffenen Seiten neu veroeffentlichen**, mit `url` aus dem Manifest.

Faellt beim Lesen etwas auf, das nicht zur veralteten Etappe gehoert: als offene Frage in
`open_questions` der betroffenen Etappe notieren und im Chat nennen. Nicht mitfixen.

## Bestand — was nie verloren geht

Der Schadensfall: nur ein Repo ist geklont, eine Sitzung schliesst daraus, die anderen
existierten nicht, und raeumt deren Doku weg.

**Bestand wird nie aus lokaler Anwesenheit abgeleitet.** Referenz ist `workspace.yaml`
plus die Manifeste, nicht das Dateisystem. Ein Repo ohne Klon ist **uebersprungen**, nicht
abgeschafft — in der Uebersicht erscheint es als offener Posten.

Daraus folgt:

- Etappen werden aktualisiert, nie aus einem Manifest entfernt.
- Kein `rm` auf `docs/bauplan/`, kein Entfernen von Repos aus `workspace.yaml`.
- Ein Blattsatz zu einem nicht geklonten Repo bleibt liegen, auch wenn er nicht
  aufgefrischt werden kann. Fehlender Klon ist keine Aussage ueber den Bestand.

Abgesichert ist das dreifach: `hooks/bauplan-guard.sh` blockiert vorab,
`bin/bauplan-guard.py --verify` prueft nach jeder Sitzung gegen `git HEAD`, und die
Historie im `mdm-harness`-Repo ist der Rueckweg (`git checkout HEAD -- docs/bauplan`).

## Werkzeuge

| Befehl | Wirkung |
|---|---|
| `bin/bauplan-index.py` | `docs/bauplan/index.html` neu erzeugen (Uebersicht mit Inhaltsverzeichnis) |
| `bin/bauplan-pdf.py <repo>` | Ganzen Satz als ein PDF — fuer Externe ohne Claude-Zugang |
| `bin/bauplan-pdf.py <repo> --einzeln` | Ein PDF je Etappe |
| `bin/bauplan-stale.py --repo <repo>` | Veraltete Etappen ermitteln (Exit 3, wenn welche) |
| `bin/bauplan-guard.py --verify` | Bestand gegen den letzten Commit pruefen |
| `bin/bauplan-import.py` | Veroeffentlichte Seite als Quelle zurueckholen |

Nach jedem Lauf `bin/bauplan-index.py` aufrufen — die Uebersicht ist generiert, nicht
handgepflegt.

## Repo-spezifische Zuschnitte

| Repo | Etappen, die entfallen | Etappen, die dazukommen |
|---|---|---|
| `theme` | Datenmodell, Prozesse | Section/Snippet-Namensraeume, `mdm-`-Kopie-Strategie, Locale-Paare, Template-JSON-Verdrahtung |
| `datalayer` | Prozesse, Datenmodell, Deploy | Event-Katalog, Consent-Gates, Mandanten-Unterschiede |
| `creditcheck` | Frontend | Zwei Services in einem Repo, SAP via `lib.sap` |
| `emailservice` | Frontend | AMQP/Messenger-Fluss, Emarsys-Ereignistypen, Opt-out-Filter |
| `payment-service` | — | Monorepo-Grenze Backend/Nuxt, Saferpay-Zustaende, Deploy-Historie Compose → k8s → Swarm |

## Antimuster — daran erkennt man einen schlechten Blattsatz

- **Ordnerbaum als Figur.** Sagt nichts, was `ls` nicht sagt.
- **Kaesten ohne Kanten.** Eine Bestandsliste ist eine Tabelle, kein Diagramm.
- **Vollstaendigkeit statt Auswahl.** Alle 88 Dateien zu zeigen hilft niemandem; die drei
  Dateien zu zeigen, in denen 60 Prozent der Zeilen stecken, schon.
- **Doku abschreiben.** Wenn die Seite nur sagt, was `docs/overview.md` sagt, war die
  Arbeit umsonst. Der Wert liegt in den Abweichungen.
- **Anhang als Meckerliste.** Beobachtungen brauchen Beleg und Konsequenz, sonst sind sie
  Geschmack.
- **Ein Diagramm, wo ein Satz reicht.** Eine Ein-Hop-Frage ist keine Figur wert.

## Bekannte Fallstricke

- **YAML-Frontmatter:** gerade `"` innerhalb eines gleich gequoteten Strings brechen die
  Datei. Nach jedem Edit an einer `SKILL.md`:
  `ruby -Eutf-8:utf-8 -ryaml -e 'YAML.load_file(ARGV[0])' <pfad>`
- **Artifact-Watch-Grenze:** ab dem sechsten Artifact in einer Session kommt eine Meldung
  „watch limit reached". Harmlos — die Seite ist veroeffentlicht, nur die
  Live-Benachrichtigung fehlt.
- **SVG-Text laeuft aus dem Kasten:** bei Monospace 11 px etwa 6,6 px je Zeichen,
  bei 9,6 px etwa 5,7 px. Vor dem Schreiben rechnen, nicht danach korrigieren.
- **`<text>` ohne `>`** ist der Fehler, der eine ganze Figur unsichtbar macht. Immer
  zaehlen (Phase 2e, Schritt 4).
