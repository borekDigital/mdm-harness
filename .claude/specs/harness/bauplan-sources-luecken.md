# Spec: Bauplan — Lücken in den `sources` schließen

Stand: 16. Oktober 2026
Quelle: Auffrischungslauf 38866856457 (16. Oktober 2026), Claudes Antwort im Log, nachgeprüft
Status: IMPLEMENTIERT — 16. Oktober 2026 (freigegeben von Konrad im Chat: „Setze den Vorschlag zu Punkt 2 um“); offen ist nur das Veröffentlichen nach dem Merge

## Ziel

Die Blattsätze `harness` und `theme-mdm` geben jederzeit den Stand von `main` wieder, egal
wer ihn geändert hat (Entscheidung Konrad, 16. Oktober 2026). Ändert sich eine Datei, auf die
sich eine Aussage stützt, meldet die Staleness-Erkennung die Etappe als veraltet.

## Kontext

Die Erkennung (`bin/bauplan_lib.py`, `affected_etappen()`) meldet eine Etappe nur, wenn eine
geänderte Datei auf ein Muster in ihren `sources` passt. Was dort fehlt, veraltet still. Der
CI-Lauf frischt nur das auf, was die Erkennung meldet, und darin nur die Aussagen zu den
auslösenden Dateien.

| # | Befund | Beleg | Status |
|---|---|---|---|
| 1 | Harness-Etappe 1 zählt Skills, Specs und `bin/`-Werkzeuge und nennt die Länge von `sync.sh`. Ihre `sources` enthalten aus `.claude/` nichts und aus `bin/` nur `bauplan-guard.py`. Die Zahlen sind überholt. Der CI-Lauf hat Etappe 1 als veraltet gemeldet, aber nicht geändert | `harness.manifest.json`, Etappe 1; Lauf 38866856457 | ✅ belegt |
| 2 | Harness-Etappe 5 zeigt `theme-mdm` mit 6 Specs und ohne Blattsatz. Ihre `sources` enthalten keine Specs | `harness.manifest.json`, Etappe 5; Lauf 38866856457 | ✅ belegt (sources), ⚠️ Blattinhalt laut Claude |
| 3 | `.github/workflows/theme-sync.yml` im Theme-Repo (seit `de15b0a`) ist von keiner `sources`-Regel des Theme-Blattsatzes gedeckt | `theme-mdm.manifest.json`, Etappe 9 | ✅ belegt |
| 4 | Theme-Etappe 8 wurde als veraltet gemeldet (`config/settings_data.json`), aber nicht geändert. Der Grund steht nicht im Log, die Antwort ist abgeschnitten. **Nachgeprüft:** Zwischen `b3467e8` und `c6b7afd` ändert sich in der Datei nur `enable_product_compare` (false → true); die App-Embeds an `:122` und `:127`, auf die sich das Blatt stützt, sind unverändert. Das Blatt ist richtig | Lauf 38866856457, `bin/bauplan-ci.py:138` (1500 Zeichen); `git diff b3467e8 c6b7afd -- config/settings_data.json` | ✅ belegt |
| 5 | Manifeste können keine Quelle sein: `is_ignored()` schließt `/.claude/bauplan/` und `/docs/bauplan/` aus, sonst löste jede Auffrischung die nächste aus | `bin/bauplan_lib.py:186–201` | ✅ belegt, Design-Entscheidung |
| 6 | Ein Harness-Blatt kann keine Datei aus einem Theme-Repo als Quelle führen. `sources` gelten relativ zur Wurzel `.`, `themes/` ist dort gitignored | `.gitignore:2`, `bauplan_lib.py:132–140` | ✅ belegt |
| 7 | Im CI-Lauf pflegt Claude Funde und offene Fragen nicht im Manifest | `bauplan-ci-auffrischung.md`, „Nicht im Umfang“ | ✅ bekannt |

## Anforderungen

### A. `sources` ergänzen

- [x] A1: Jede Menge, die ein Blatt zählt oder benennt, ist durch ein Muster in den
      `sources` seiner Etappe gedeckt. Geprüft wird das für Harness-Etappe 1 und 5 und für
      Theme-Etappe 9.
- [x] A2: Theme-Etappe 9 deckt `.github/**` ab.
- [x] A3: Was sich nicht als Quelle führen lässt (Befunde 5 und 6), steht als offene Frage
      im Manifest der betroffenen Etappe, damit es beim nächsten Auffrischen von Hand
      geprüft wird.
- [x] A4: Keine Etappe verliert ein bestehendes Muster.

### B. Einmal von Hand auffrischen

- [x] B1: Harness-Etappe 1 und 5 sowie Theme-Etappe 8 und 9 nach dem Abschnitt
      „Auffrischen — nur das Veraltete“ im Skill: nur die betroffenen Aussagen, per Edit,
      andere Blätter bleiben Zeichen für Zeichen gleich. Theme-Etappe 8 brauchte keine
      Änderung (Befund 4).
- [x] B2: Für Theme-Etappe 8 steht im Chat, ob `settings_data.json` seit `b3467e8` eine
      Aussage des Blatts berührt, und wenn ja, welche.

### C. Manifeste pflegen

- [x] C1: `findings`, `open_questions` und `closes` der aufgefrischten Etappen stimmen mit
      den Blättern überein.
- [x] C2: Die offenen Fragen aus der Antwort des Laufs 38866856457, die nach dieser Spec
      noch gelten, stehen im Manifest. Eine überholte Zeilenangabe in `closes` ist korrigiert.
- [x] C3: `last_seen_sha` bleibt, wie der Lauf es gesetzt hat. Der Stand der Quellen ist
      derselbe (`421a6eb` für den Harness ohne diese Spec, `c6b7afd` für das Theme).

## Akzeptanzkriterien

- [x] `bin/bauplan-wording.py --repo harness` und `--repo theme-mdm`: 0 Verstöße.
- [x] `<text` und `</text>` gleich oft in jedem geänderten Blatt.
- [x] `bin/bauplan-guard.py --verify`: Exit 0.
- [x] Der Diff enthält nur: diese Spec, die zwei Manifeste, höchstens die vier Blätter aus
      B1 und `docs/bauplan/index.html`.
- [x] Mit den neuen `sources` gegen `b3467e8..c6b7afd` meldet `affected_etappen()` Theme-Etappe 9
      wegen `.github/workflows/theme-sync.yml`.
- [ ] Nach dem Merge: die geänderten Seiten und das Übersichts-Artefakt neu veröffentlicht.

## Constraints

- Kein Code in `bin/`. Die Ausschlussregel aus Befund 5 bleibt, sonst droht eine
  Auffrischungsschleife.
- Folge, die Konrad am 16. Oktober 2026 so gewollt hat: Mit `.claude/specs/**` in den
  `sources` von Etappe 1 und 5 macht jede neue Spec drei Harness-Etappen veraltet (1, 4, 5),
  also auch diese Spec selbst beim nächsten Lauf.
- Arbeit im Worktree `.claude/worktrees/bauplan-sources` (Branch `fix/bauplan-sources`), weil
  in `~/MDM` parallel eine andere Sitzung arbeitet.

## Nicht im Umfang

| Thema | Warum |
|---|---|
| Manifest-Pflege im CI (Befund 7) | eigener Fix an Prompt oder Rechten |
| Wortprüfung im CI für theme-mdm blockiert | eigener Fix an `allowed_tools()` |
| Abgeschnittene Claude-Antwort im Log (Befund 4) | eigener Fix an `bauplan-ci.py:138` |
| `harness.STALE.md` verschachtelt bei jedem Lauf eine Ebene tiefer | eigener Fix am Staleness-Hook |
| Fußzeile des letzten Blatts verlinkt `../index.html`, das in der Einzelseite ins Leere führt | eigener Fix an `bin/bauplan-nav.py` |
| Übersicht zeigt beim Harness „Stand 2026-09-17“ aus dem Manifest-Feld `generated` | eigener Fix an `bin/bauplan-index.py` |

## Umsetzung

Durchgeführt am 16. Oktober 2026 im Worktree `.claude/worktrees/bauplan-sources`, Branch
`fix/bauplan-sources`, abgezweigt von `origin/main` (`7b02be1`).

| Datei | Änderung |
|---|---|
| `.claude/bauplan/harness.manifest.json` | Etappe 1: `sources` um `bin/**` und `.claude/{agents,skills,hooks,rules,specs}/**`, zwei offene Fragen zu Commit `97c2186`. Etappe 4: eine offene Frage (Anhang gegen Blätter). Etappe 5: `sources` um `.claude/specs/**`, `.claude/rules/**`, offene Frage zu Befund 5. Etappe 6: `blaetter` 5 → 6 und `findings` 6 → 7 (vom Lauf ergänzt, im Manifest nicht nachgezogen), drei offene Fragen |
| `.claude/bauplan/theme-mdm.manifest.json` | Etappe 5: offene Frage (aria-label 15 gegen 17, „1 Dateien“). Etappe 6: `closes` auf `brand-overrides.css:565`. Etappe 9: `sources` um `.github/**`, offene Frage zu Zählungen ohne Datei |
| `docs/bauplan/harness/etappe-01.html` | 10 statt 8 Skills, `sync.sh` 253 statt 325 Zeilen, Rules 192 statt 156 Zeilen, 35 statt 17 Specs, `bin/` 13 Dateien, Beschreibungstext ohne die entfernte Dashboard-App, Prüfpunkt 02 „vier der zehn“ |
| `docs/bauplan/harness/etappe-05.html` | Blatt 04: theme-mdm mit 15 Specs und Blattsatz (9 Etappen), drei statt zwei Blattsätze für Arbeits-Repos, Fundstellen-Tabelle |
| `docs/bauplan/theme-mdm/etappe-09.html` | `theme-sync.yml` als einziger Workflow ohne Prüfschritt: Titelblock, Blatt 01, Blatt 04, Prüfpunkt 04 neu, zwei Fundstellen |
| `docs/bauplan/index.html` | neu erzeugt (`bin/bauplan-index.py --stand "16. Oktober 2026"`) |

### Nachweis

```
check_sources theme-mdm b3467e8..c6b7afd   -> Etappe 9: .github/workflows/theme-sync.yml
check_sources harness 224f96d..421a6eb     -> Etappe 1 und 5 jetzt auch über Agents, Rules, Specs
bauplan-wording.py --repo harness          -> 0 Verstöße, 9 zur Durchsicht (vorbestehend)
bauplan-wording.py --repo theme-mdm        -> 0 Verstöße
<text>-Balance etappe-01/05 (harness), 09  -> ausgeglichen
bauplan-guard.py --verify                  -> Exit 0
Manifeste json.load                        -> ok
```

Gezählt am Stand `7b02be1`, die Spec selbst mitgezählt (35 Dateien unter `.claude/specs/`).
`THEME_SYNC_ENABLED` steht laut `gh variable list` seit dem 15. Oktober 2026 auf `true`;
`gh run list` zeigt den Workflow nach Bot-Commits (`c6b7afd`, `eda3a36`, …).
