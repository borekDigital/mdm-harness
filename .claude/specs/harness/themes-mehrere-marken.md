# Spec: themes/ für mehrere Marken

Stand: 16. September 2026
Quelle: Review Seniorentwickler, 11. September 2026
Status: UMGESETZT (16. September 2026) — siehe Abschnitt „Umsetzung“ am Ende

## Ziel

Der Workspace trägt mehrere Shopify-Themes nebeneinander — MDM, Borek, IMM — statt eines
einzelnen Verzeichnisses `theme/`, das implizit für MDM steht.

## Ist-Zustand

Ein Verzeichnis, ein Theme:

```yaml
# workspace.yaml:11-19
theme:
  name: "Shopify Theme"
  path: "theme/"
  remote: "git@github.com-borek:borekDigital/shopifyFrontend_MDM.git"
```

Der Pfad `theme/` ist an elf weiteren Stellen verdrahtet:

| Datei | Zeile | Verwendung |
|---|---|---|
| `.gitignore` | 2 | `/theme/` |
| `.claude/rules/liquid-conventions.md` | 3–6 | `theme/sections/**`, `snippets/**`, `blocks/**`, `layout/**` |
| `.claude/rules/templates-json.md` | 3 | `theme/templates/**` |
| `.claude/rules/merchant-config.md` | 3–4 | `theme/config/**`, `theme/locales/**` |
| `.claude/hooks/post-edit-theme-check.sh` | 16, 17 | Mustervergleich `*/theme/*.liquid` usw. |
| `.claude/hooks/post-edit-theme-check.sh` | 26 | `cd "$PROJECT/theme"` |
| `.claude/hooks/protect-merchant-files.sh` | 17 | `*/theme/config/settings_data.json` |
| `.claude/hooks/protect-merchant-files.sh` | 27 | `*/theme/blocks/ai_gen_block_*` |
| `CLAUDE.md` | 25 | „Alle Theme-Pfade … tragen das Praefix `theme/`" |
| `.claude/specs/theme/` | — | Verzeichnis mit sechs Theme-Specs |

Zeile 26 des Theme-Check-Hooks ist die schwierigste Stelle: Sie wechselt fest in ein
Verzeichnis. Bei mehreren Themes muss sie aus dem Pfad der bearbeiteten Datei herleiten,
welches Theme gemeint ist.

## Soll-Zustand

### Verzeichnisaufbau

```
<workspace>/
├── themes/
│   ├── mdm/            shopifyFrontend_MDM
│   ├── borek/          <Repo folgt>
│   └── imm/            <Repo folgt>
├── connector/
└── …
```

Eine Ebene, nicht zwei. Der Vorschlag im Review nennt „Unterordner für MDM/Borek/IMM und den
jeweiligen Themes". Solange je Marke genau ein Theme geführt wird, reicht
`themes/<marke>/`. Kommt ein zweites Theme je Marke dazu — etwa ein Entwicklungs-Theme —
wird daraus `themes/<marke>/<theme>/`.

**Zu entscheiden vor der Umsetzung:** Welche der beiden Tiefen gilt? Die Muster in Rules und
Hooks unterscheiden sich:

| Tiefe | Rule-Glob | Hook-Muster |
|---|---|---|
| `themes/<marke>/` | `themes/*/sections/**` | `*/themes/*/*.liquid` |
| `themes/<marke>/<theme>/` | `themes/*/*/sections/**` | `*/themes/*/*/*.liquid` |

Ein späterer Wechsel von eins auf zwei Ebenen betrifft alle elf Stellen erneut. Die
Entscheidung gehört deshalb an den Anfang, nicht in eine zweite Runde.

### workspace.yaml

Ein Eintrag je Theme, gemeinsame Gruppe:

```yaml
  theme-mdm:
    name: "Shopify Theme MDM"
    path: "themes/mdm/"
    remote: "git@github.com:borekDigital/shopifyFrontend_MDM.git"
    platform: "github"
    tech: "Liquid/CSS/JS (Hyper 1.3.3)"
    group: "shopify"
    default: true
    branch: "main"

  theme-borek:
    name: "Shopify Theme Borek"
    path: "themes/borek/"
    …
    default: false
```

Der Repo-Name bleibt im `remote` ablesbar — die Zuordnung „welches Projekt" geht nicht
verloren, obwohl das Verzeichnis vereinheitlicht ist. Das entspricht der Vorgabe aus dem
Review.

`default: true` nur für MDM: Ein Setup-Lauf klont sonst drei Themes, von denen zwei niemand
braucht.

### Rules

Die drei Theme-Rules greifen künftig für alle Marken:

```yaml
paths:
  - "themes/*/sections/**"
  - "themes/*/snippets/**"
  - "themes/*/blocks/**"
  - "themes/*/layout/**"
```

Inhaltlich bleiben sie unverändert — bis feststeht, ob Borek und IMM dasselbe Basis-Theme
nutzen. `liquid-conventions.md` beschreibt heute durchgehend Hyper und das `mdm-`-Präfix.
Gilt für Borek ein anderes Präfix, teilt sich die Rule in einen gemeinsamen und einen
markenspezifischen Teil. **Das ist nicht Teil dieser Spec** — hier geht es um Pfade.

### Hooks

`post-edit-theme-check.sh` leitet das Theme-Verzeichnis aus dem Dateipfad ab, statt es zu
setzen:

```bash
# statt: cd "$PROJECT/theme"
THEME_DIR="${FILE%%/themes/*}/themes/${FILE#*/themes/}"
THEME_DIR="${THEME_DIR%%/*}"     # erste Ebene unter themes/
cd "$PROJECT/themes/$THEME_DIR" || exit 0
```

Die genaue Zerlegung hängt an der oben zu entscheidenden Tiefe. Der Hook muss außerdem
still aussteigen, wenn die Datei zwar unter `themes/` liegt, das Verzeichnis aber kein
Shopify-Theme ist — Prüfung auf `.theme-check.yml` oder `config/settings_schema.json`.

`protect-merchant-files.sh` braucht nur neue Muster, keine neue Logik.

### Specs

`.claude/specs/theme/` wird zu `.claude/specs/themes/mdm/`. Die sechs vorhandenen Specs
(`_conventions.md`, `breadcrumbs.md`, `global-brand-overrides.md`, `hilfe-hub.md`,
`hilfe-template.md`, `page-title.md`) beschreiben MDM-Arbeit und gehören unter `mdm/`. Gemeinsames wandert bei Bedarf nach
`.claude/specs/themes/_gemeinsam/`.

`.claude/specs/README.md` nennt den Aufbau in der Dateistruktur — dort nachziehen.

## Anforderungen

- [x] Tiefe entschieden: `themes/<marke>/` oder `themes/<marke>/<theme>/`
- [x] `workspace.yaml`: `theme` durch `theme-mdm` ersetzt, `theme-borek` und `theme-imm`
      ergänzt, sobald die Remotes bekannt sind
- [x] `.gitignore:2`: `/theme/` → `/themes/`
- [x] Drei Rules auf `themes/*/…` umgestellt
- [x] `post-edit-theme-check.sh`: Theme-Verzeichnis aus dem Dateipfad hergeleitet, Muster
      angepasst, stiller Ausstieg bei Nicht-Theme-Verzeichnissen
- [x] `protect-merchant-files.sh`: Muster angepasst
- [x] `.claude/specs/theme/` nach `.claude/specs/themes/mdm/` verschoben, README nachgezogen
- [x] `sync.sh` erzeugt `CLAUDE.md` mit dem neuen Aufbau — Zeile 25 der Vorlage anpassen

## Akzeptanzkriterien

- [ ] `grep -rn '"theme/\|/theme/\|theme/\*\*' .claude/ .gitignore sync.sh` liefert außerhalb
      von `.claude/specs/` und `docs/bauplan/` keinen Treffer
- [ ] Eine Bearbeitung in `themes/mdm/sections/x.liquid` löst den Theme-Check im Verzeichnis
      `themes/mdm/` aus — nachweisbar über die Hook-Ausgabe
- [ ] Eine Bearbeitung in `themes/borek/sections/x.liquid` löst ihn in `themes/borek/` aus
- [ ] Eine Bearbeitung in `themes/README.md` löst keinen Theme-Check aus
- [ ] `protect-merchant-files.sh` blockiert `themes/mdm/config/settings_data.json` weiterhin
- [ ] `./setup.sh` klont bei Vorgabe nur `themes/mdm/`

## Constraints

- **Der bestehende Klon muss umziehen.** `theme/` ist ein eigenständiges Git-Repo. Der Umzug
  ist ein `git mv` auf Verzeichnisebene außerhalb des Repos — also schlicht `mv theme themes/mdm`,
  nachdem `themes/` existiert. Vor dem Verschieben prüfen, dass dort nichts uncommittet liegt.
- Blast-Radius: 11 Stellen plus der Umzug. Die Theme-Arbeit selbst ist danach unverändert —
  es ändert sich kein Liquid.
- Für Borek und IMM fehlen die Remotes. Die Einträge in `workspace.yaml` können erst entstehen,
  wenn die Repos benannt sind. Bis dahin ist die Umstellung auf `themes/mdm/` allein sinnvoll
  und vollständig — sie schafft die Struktur, ohne auf Zulieferung zu warten.
- Für `theme` existiert noch kein Blattsatz unter `docs/bauplan/`. Es ist also keine
  Dokumentation nachzuziehen — der Umbau geschieht vor der Dokumentation, nicht danach.

## Reihenfolge

1. Tiefe entscheiden
2. `themes/` anlegen, `theme/` verschieben
3. `workspace.yaml`, `.gitignore`
4. Rules und Hooks
5. Specs verschieben
6. `./sync.sh` — erzeugt `CLAUDE.md` neu
7. Erst danach: Borek- und IMM-Einträge ergänzen


## Umsetzung

Durchgefuehrt am 16. September 2026. Die Remotes fuer Borek und IMM lagen vor,
deshalb wurde die Struktur in einem Zug vollstaendig aufgebaut statt in zwei Runden.

### Entscheidungen

| Offener Punkt der Spec | Entscheidung |
|---|---|
| Tiefe | Eine Ebene: `themes/<marke>/` — `mdm`, `borek`, `imm` |
| Repo-Schluessel | `theme-mdm`, `theme-borek`, `theme-imm` (symmetrisch, wie vorgeschlagen) |
| `default:` | Alle drei `true` — der Workspace fuehrt jetzt alle drei Marken |

### Abweichungen von der Spec

1. **Remotes mit SSH-Alias, nicht kanonisch.** Die Spec-Vorlage zeigt
   `git@github.com:borekDigital/…`. Geprueft am 16. September 2026:
   `git ls-remote git@github.com:borekDigital/shopifyFrontend_IMM.git` antwortet
   `ERROR: Repository not found` — der Standard-Account hat keinen Zugriff.
   Ueber `git@github.com-borek:` funktionieren alle drei. Die Eintraege nutzen
   deshalb weiter den Alias. Die Umstellung gehoert zu `git-remotes-neutral.md`
   und bleibt dort offen.

2. **Ein Template statt drei.** `templates/repo-theme.md` wurde zu
   `templates/repo-themes.md` — ein gemeinsamer Abschnitt fuer alle drei Marken,
   weil sie sich in der Marke unterscheiden, nicht in den Konventionen.
   `sync.sh` behandelt `themes` als Pseudo-Schluessel (nicht als Repo-ID) und
   setzt den Hinweis „nicht installiert“ je fehlendem Theme davor.

3. **Bauplan-Guard erweitert.** `bin/bauplan-guard.py` wertete jede verschwundene
   Repo-ID als Verlust und haette die Umbenennung von `theme` blockiert. Er
   vergleicht jetzt ueber das **Remote**: ein Schluessel darf wechseln, solange
   sein Remote in der Datei bleibt. Eine echte Loeschung wird weiterhin
   blockiert (geprueft).

4. **Zusaetzlich behoben (Altlast, nicht Teil der Spec).** `sync.sh` und
   `setup.sh` lasen Zeitstempel mit `sed 's/.*: *//'`. Der gierige Ausdruck
   schnitt bis zum letzten Doppelpunkt — aus `"2026-09-16T09:09:12Z"` wurde
   `12Z`, die Datumspruefung schlug fehl und meldete fuer jedes Repo
   „letzter Sync vor 20712 Tagen“. Jetzt `sed 's/^[^:]*: *//'`.

### Befund zur Codebasis (in der Spec nicht vorhergesehen)

Die drei Repos teilen **keine** Git-Historie — drei getrennte Wurzel-Commits,
`git merge-base` liefert fuer jedes Paar nichts. Gleichzeitig sind rund
90 Prozent der Dateien byte-identisch:

| Paar | gemeinsame Dateien | identisch | abweichend |
|---|---|---|---|
| mdm / borek | 685 | 620 | 65 |
| mdm / imm | 685 | 617 | 68 |
| borek / imm | 687 | 649 | 38 |

MDM ist der aktive Zweig (1599 Commits gegen 90 und 65); Borek und IMM sind
untereinander nahezu deckungsgleich. Das Praefix `mdm-` ist die Haus-Konvention
**aller drei** Themes, keine Marken-Kennzeichnung — `themes/borek/sections/`
enthaelt ebenfalls `mdm-breadcrumbs.liquid`.

Daraus folgt der Uebertragungsweg: **Patch, nicht Merge**. Umgesetzt in
`bin/theme-sync.sh` (`drift`, `port`, `list`) mit Blockliste fuer
markenspezifische Pfade. Details: `.claude/specs/harness/theme-sync.md`.
