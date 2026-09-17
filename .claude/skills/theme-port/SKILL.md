---
name: theme-port
description: "Uebertraegt eine fertige Aenderung von einem Marken-Theme in die anderen (mdm, borek, imm) per bin/theme-sync.sh — Modus-Wahl Kopie gegen --as-patch, Sicherungen, Exit-Codes, Nachkontrolle. Nutzen bei: gleiche Aenderung in mehrere Themes, Drift zwischen Marken pruefen, Settings-Werte vergleichen, „port das nach borek und imm“."
---

# /theme-port — Aenderung in mehrere Marken-Themes uebertragen

Die drei Themes teilen **keine** Git-Historie (drei getrennte Wurzel-Commits), deshalb
scheidet `git merge` aus. Eine Aenderung wandert von Arbeitsbaum zu Arbeitsbaum.

**Es gibt keine Automatik.** Nichts erzeugt von selbst einen Commit, einen Push oder
einen PR in den anderen Themes. Jede Uebertragung wird angestossen.

Voraussetzung: im Quell-Theme ist die Arbeit committet und gemergt. Der Commit-SHA
aus dem Quell-Theme ist der Schluessel.

## Ablauf

### 1. Sehen, wo die Themes stehen

```bash
bin/theme-sync.sh list
bin/theme-sync.sh drift assets/          # was laeuft auseinander?
bin/theme-sync.sh settings page_width    # haben die Marken dieselbe Grundlage?
```

Dieser Schritt gehoert dazu, er ist nicht optional. `settings <schluessel>` vergleicht
einen Wert aus `config/settings_data.json` ueber alle Themes. `page_width` ist in allen
drei `1700`, `type_header_font` dagegen nicht — MDM fuehrt `ebgaramond_n5`, Borek und IMM
`archivo_n7`. Eine CSS-Regel, die an der Hausschrift haengt, wirkt dort anders.

`drift` vergleicht den **Arbeitsbaum**, nicht den Remote.

### 2. Modus waehlen

| Lage | Kommando | Wirkung |
|---|---|---|
| Datei in Quelle und Ziel sonst identisch | `port <q> <ziele> <pfad>` | kopiert die ganze Datei |
| Quelle laeuft in derselben Datei voraus | `port <q> <ziele> --commit <sha> --as-patch` | wendet nur die Hunks des Commits an |

Der Normalfall ist `--as-patch`, weil MDM den beiden anderen vorauslaeuft. Ohne
`--as-patch` wuerde die Ganzdatei-Kopie die abweichende Zielarbeit ueberschreiben.

### 3. Uebertragen

```bash
bin/theme-sync.sh port mdm borek,imm --commit <sha> --as-patch
```

### 4. Je Ziel-Theme pruefen und committen

```bash
git -C themes/borek diff
git -C themes/borek commit -am "…"       # gleiche Message wie in der Quelle
git -C themes/borek push -u origin sync/mdm-<datum>
```

### 5. PR je Ziel-Theme von Hand

## Sicherungen

- Ziel mit unsauberem Arbeitsbaum wird uebersprungen, nicht ueberschrieben.
- Mit `--as-patch`: passt der Patch nicht, wird das Ziel uebersprungen, **bevor** der
  Branch angelegt wird. Ausweg: `git -C themes/<ziel> apply --3way --reject`.
- Markenspezifische Pfade (`locales/`, `templates/`, `config/settings_*.json`, `layout/`,
  `sections/*-group.json`) werden uebersprungen. `--allow-brand` gibt alle frei,
  `--allow-brand=<pfad>[,<pfad>]` nur die genannten — fuer den Fall, dass ein einzelner
  Uebersetzungsschluessel fuer alle Marken gilt.
- Das Skript committet nie und pusht nie.

## Exit-Codes von `port`

| Code | Bedeutung |
|---|---|
| 0 | alle Ziele geschrieben |
| 1 | Abbruch vor der Ziel-Schleife — kein Ziel beruehrt |
| 2 | teilweise — mindestens ein Ziel geschrieben, mindestens eines uebersprungen |
| 3 | kein Ziel geschrieben, alle uebersprungen |

Code 2 und 3 unterscheiden sich fuer ein Skript, das `port` aufruft: bei 2 stehen
Aenderungen in Arbeitsbaeumen, bei 3 nicht.

## Was das Skript nicht pruefen kann

Ob die Aenderung **inhaltlich** in die andere Marke passt. Hart verdrahtete Layout-Zahlen
aus einem Marken-Figma (Spaltenbreiten, Verhaeltnisse, Breakpoints) laufen sauber durch
den Patch und sind im Zielshop trotzdem falsch. Nach jeder Uebertragung im Ziel-Theme
visuell gegenpruefen:

```bash
cd themes/<ziel> && shopify theme check --output json   # JSON parsen, nicht Exit-Code
cd themes/<ziel> && shopify theme dev --store <handle>
```
