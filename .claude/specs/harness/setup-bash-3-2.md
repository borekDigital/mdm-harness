# Spec: setup.sh auf Bash 3.2 lauffähig machen

Stand: 11. September 2026
Quelle: Review Seniorentwickler, 11. September 2026
Status: ENTWURF

## Ziel

`setup.sh` läuft mit der Bash, die macOS mitbringt. Kein Teammitglied muss eine neuere Bash
installieren, um den Workspace einzurichten.

## Ist-Zustand

`setup.sh` nutzt `local -n` (Namensreferenzen) an sieben Stellen:

| Zeile | Funktion | Variable |
|---|---|---|
| 75 | `show_menu()` | `_selected` |
| 112 | `show_menu_gum()` | `_sel` |
| 113 | `show_menu_gum()` | `_shopify` |
| 114 | `show_menu_gum()` | `_mw` |
| 159 | `show_menu_bash()` | `_sel` |
| 160 | `show_menu_bash()` | `_shopify` |
| 161 | `show_menu_bash()` | `_mw` |

`local -n` gibt es erst ab Bash 4.3. macOS liefert seit Jahren 3.2.57 — auf diesem Rechner
belegt:

```
$ /bin/bash --version
GNU bash, version 3.2.57(1)-release (arm64-apple-darwin23)
```

Das Problem betrifft damit **jedes Teammitglied mit Standard-macOS**, nicht nur ein älteres
Gerät. Die Shebang-Zeile lautet `#!/usr/bin/env bash`; wer Bash 5 per Homebrew installiert und
in `PATH` hat, merkt nichts — wer nicht, bekommt den Fehler.

### Der Fehler ist still, nicht laut

Nachgebaut mit demselben Konstrukt:

```
$ ./nref.sh
./nref.sh: line 2: local: -n: invalid option
local: usage: local name[=value] ...
OK:
$ echo $?
0
```

Bash meldet den ungültigen Schalter, **bricht aber nicht ab**. Die Zuweisung läuft ins Leere,
das Array bleibt leer, der Rückgabewert ist 0. Übertragen auf `setup.sh` heißt das: Die
Repo-Auswahl kommt leer zurück, `clone_repos "${selected[@]}"` (Zeile 451) bekommt nichts, und
das Setup meldet Erfolg, ohne ein Repo geklont zu haben.

Das ist dieselbe Fehlerform wie beim CI-Lauf ohne `CLAUDE_PROJECT_DIR`: ein grüner Lauf ohne
Wirkung. Sie ist schwerer zu finden als ein Absturz.

## Soll-Zustand

Rückgabe über die Standardausgabe statt über Namensreferenzen. Das ist in Bash 3.2 verfügbar,
braucht keine zusätzliche Abstraktion und macht die Datenrichtung im Code sichtbar.

```bash
# vorher
show_menu selected
clone_repos "${selected[@]}"

# nachher
selected=()
while IFS= read -r line; do selected+=("$line"); done < <(show_menu)
clone_repos "${selected[@]}"
```

Die drei Funktionen geben je eine Auswahl pro Zeile aus. Repo-IDs enthalten keine Leerzeichen
oder Zeilenumbrüche — geprüft gegen `workspace.yaml`: `theme`, `connector`, `datalayer`,
`creditcheck`, `emailservice`, `payment-service`. Zeilenweises Lesen ist damit sicher.

### Eingabe statt Namensreferenz

`show_menu_gum` und `show_menu_bash` bekommen die beiden Gruppenlisten heute per Referenz.
Sie erhalten sie künftig als Argumente, getrennt durch einen Marker:

```bash
show_menu_gum "${shopify_repos[@]}" -- "${middleware_repos[@]}"
```

Alternative, falls das unübersichtlich wird: Die Gruppenzuordnung wandert in die Funktion, die
sie ohnehin aus `yaml_get "$repo_id" "group"` ermittelt — dann braucht keine der beiden
Funktionen die Listen als Eingabe.

Die zweite Variante ist vorzuziehen: `show_menu()` berechnet die Gruppen heute in
Zeile 78–93, nur um sie eine Zeile später weiterzureichen.

### Trennung von Ausgabe und Anzeige

Beide Menüfunktionen schreiben heute Bildschirmtext und Ergebnis in denselben Strom. Bei
Rückgabe über die Standardausgabe muss der Bildschirmtext nach `stderr`:

```bash
echo -e "  ${BOLD}Shopify${RESET}" >&2
```

Das betrifft jede `echo`-Zeile innerhalb der drei Funktionen, nicht die im übrigen Skript.
`gum` schreibt seine Oberfläche selbst nach `stderr` und sein Ergebnis nach `stdout` — dort ist
nichts zu ändern.

## Anforderungen

- [ ] `show_menu()`, `show_menu_gum()`, `show_menu_bash()` geben die Auswahl zeilenweise auf
      `stdout` aus; kein `local -n` mehr im Skript
- [ ] Bildschirmausgabe innerhalb dieser drei Funktionen geht nach `stderr`
- [ ] Die Gruppenermittlung liegt an einer Stelle, nicht in Aufrufer und Aufgerufenem
- [ ] Aufrufstelle Zeile 451 liest die Auswahl über `while read` ein
- [ ] Das Skript prüft beim Start die Bash-Version und bricht mit Meldung ab, wenn es doch
      einmal ein Konstrukt gibt, das 3.2 nicht kann — Vorschlag: Prüfung auf
      `${BASH_VERSINFO[0]} -lt 3`

## Akzeptanzkriterien

- [ ] `grep -c 'local -n' setup.sh` liefert 0
- [ ] `/bin/bash setup.sh` läuft auf macOS mit Bash 3.2 durch und klont die ausgewählten Repos
- [ ] Abbruch mit leerer Auswahl führt zu Rückgabewert ungleich 0 und klarer Meldung — nicht zu
      „Setup erfolgreich" ohne Klon
- [ ] Der Weg mit `gum` und der Weg ohne `gum` liefern dieselbe Auswahl; geprüft durch Aufruf
      mit und ohne `gum` im `PATH`
- [ ] `bash -n setup.sh` und `shellcheck setup.sh` melden keine neuen Befunde

## Constraints

- Blast-Radius: nur `setup.sh`. Kein anderes Skript nutzt `local -n` — geprüft über `bin/`,
  `.claude/hooks/`, `sync.sh`.
- Der Seniorentwickler hat die drei Funktionen lokal bereits angepasst, um weiterzutesten.
  Vor der Umsetzung seine Fassung ansehen: Wenn sie trägt, ist sie die Vorlage.
- Die Shebang bleibt `#!/usr/bin/env bash`. Ein Wechsel auf `#!/bin/bash` würde den Fehler
  für alle erzwingen statt ihn zu beheben.

## Offene Frage

Soll `setup.sh` bei fehlendem `gum` weiterhin das Bash-Menü anbieten, oder reicht künftig ein
Hinweis mit Installationsbefehl? Das Bash-Menü ist der längere der beiden Zweige und trägt
drei der sieben Fundstellen. Die Frage gehört zum Umbau, nicht danach.
