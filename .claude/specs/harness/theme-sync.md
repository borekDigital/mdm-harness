# Spec: Gleiche Aenderungen zwischen den Marken-Themes

Stand: 16. September 2026
Status: UMGESETZT — `bin/theme-sync.sh`

## Ziel

Eine Aenderung, die in mehr als einem der drei Marken-Themes gelten soll, wandert
nachvollziehbar dorthin — ohne sie zwei- oder dreimal von Hand zu bauen und ohne
dabei markenspezifische Dateien zu ueberschreiben.

Das ist eine **Uebergangsloesung**. Ziel bleibt, dass die drei Shops mit einem
Theme arbeiten. Bis dahin muessen drei Codebasen nebeneinander gepflegt werden.

## Ausgangslage (gemessen am 16. September 2026)

### Keine gemeinsame Historie

```
git merge-base <mdm>/main <borek>/main   -> leer
git merge-base <mdm>/main <imm>/main     -> leer
git merge-base <borek>/main <imm>/main   -> leer
```

Drei getrennte Wurzel-Commits:

| Theme | Wurzel-Commit | Commits |
|---|---|---|
| mdm | `7dd3fa4f` | 1599 |
| borek | `229fe0a9` | 90 |
| imm | `73e8f435` | 65 |

**Folge:** `git merge` scheidet aus. Es braeuchte `--allow-unrelated-histories`
und wuerde zwei fremde Baeume verschmelzen statt eine Aenderung zu uebertragen.

### Aber fast identische Dateien

| Paar | gemeinsame Dateien | identisch | abweichend |
|---|---|---|---|
| mdm / borek | 685 | 620 | 65 |
| mdm / imm | 685 | 617 | 68 |
| borek / imm | 687 | 649 | 38 |

MDM laeuft voraus, Borek und IMM sind untereinander nahezu deckungsgleich. Im
Drift-Bericht erscheint deshalb fast durchgaengig das Muster `borek=imm | mdm`.

**Folge:** Eine Datei aus einem Theme passt in aller Regel unveraendert in ein
anderes. Der Weg ist der **Patch**, nicht der Merge.

### Das Praefix `mdm-` ist die Haus-Konvention

Auch `themes/borek/` und `themes/imm/` fuehren `mdm-breadcrumbs.liquid`,
`mdm-card-product.liquid` usw. Das Praefix kennzeichnet „nicht FoxEcom“, nicht
die Marke MDM. Es wird beim Uebertragen **nicht** umbenannt.

## Soll-Zustand

`bin/theme-sync.sh` mit drei Kommandos:

```bash
bin/theme-sync.sh list                      # Themes, Branch, sauber/unsauber
bin/theme-sync.sh drift [pfad-praefix]      # was laeuft auseinander?
bin/theme-sync.sh port <quelle> <ziele> <pfade...>
bin/theme-sync.sh port <quelle> <ziele> --commit <sha>
```

### drift

Vergleicht den **Arbeitsbaum** (nicht HEAD) aller geklonten Themes und zeigt je
Datei, welche Themes uebereinstimmen:

```
sections/mdm-breadcrumbs.liquid          borek=imm | mdm
assets/header.js                         borek | imm | mdm
```

Dateien, die in nur einem Theme existieren, und markenspezifische Pfade werden
gezaehlt, aber nicht gelistet — sie sind kein Drift, sondern Absicht.

### port

Legt im Ziel-Theme den Branch `sync/<quelle>-<datum>` an und kopiert die Dateien
hinein. **Kein Commit, kein Push.** Pruefen und committen bleibt Handarbeit.

Sicherungen:

- Ziel mit unsauberem Arbeitsbaum wird uebersprungen, nicht ueberschrieben.
- Quelle gleich Ziel wird abgelehnt.
- Dateien, die in der Quelle fehlen, werden gemeldet und uebersprungen.
- Bereits identische Dateien werden gezaehlt, nicht angefasst.
- Der vorherige Branch wird in der Ausgabe genannt, damit der Schritt
  rueckgaengig zu machen ist.

### Blockliste markenspezifischer Pfade

Diese Dateien gehoeren der Marke, nicht der Codebasis. `port` ueberspringt sie
und meldet das; `--allow-brand` uebertraegt sie bewusst:

```
config/settings_data.json      Live-Einstellungen des Theme-Editors
config/settings_schema.json    Marken-Defaults
locales/*                      Uebersetzungen
templates/*                    Seitenaufbau je Shop
sections/*-group.json          header-, footer-, overlay-group
layout/*                       mdm-theme.liquid vs. borek-theme.liquid
.shopifyignore, .gitignore, README.md, temp/*
```

## Akzeptanzkriterien

- [x] `drift` zeigt fuer `sections/` genau die Dateien, die auseinanderlaufen
      (gemessen: 6 von 9 gemeinsamen Sections)
- [x] `drift` ueberspringt markenspezifische Pfade und zaehlt sie getrennt
- [x] `port` mit gemischten Pfaden uebertraegt nur die nicht-markenspezifischen
      und benennt die uebersprungenen
- [x] `port` verweigert ein Ziel mit unsauberem Arbeitsbaum
- [x] `port --commit <sha>` leitet die Pfade aus dem Commit ab
- [x] `port` committet nicht und pusht nicht
- [x] Ein nicht geklontes Theme wird still uebersprungen, nicht als Fehler

## Grenzen

- `port` uebertraegt **ganze Dateien**, nicht einzelne Hunks. Wenn Quelle und
  Ziel in derselben Datei unterschiedliche gewollte Staende haben, ist das der
  falsche Weg — dann von Hand patchen.
- `--commit` nimmt den **aktuellen** Stand der im Commit beruehrten Dateien,
  nicht den Stand zum Zeitpunkt des Commits. Fuer einen alten Commit auf einem
  seither weitergelaufenen Zweig ist das nicht dasselbe.
- Der Drift-Bericht sagt, **dass** etwas auseinanderlaeuft, nicht **ob** das
  richtig ist. Manche Abweichung ist gewollt.

## Verhaeltnis zum Zielbild

Sobald die drei Shops auf einem Theme laufen, entfaellt dieses Skript ersatzlos.
Bis dahin ersetzt es die Alternative „dieselbe Aenderung dreimal von Hand bauen“.
Siehe `themes-mehrere-marken.md` und `theme-multi-brand-vorhaben`.
