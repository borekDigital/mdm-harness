## Block abgeschlossen: collection-grid-spacing

15. Oktober 2026 — Ticket SHOP-2, Rückmeldung Kerstin Meyer vom selben Tag.

**Spec:** `.claude/specs/themes/mdm/kollektion-abstand-ohne-verwandte-kategorien.md` (IMPLEMENTIERT)
**Plan:** `SHOP-2-block-collection-grid-spacing-plan.md`
**Worktree:** `themes/.worktrees/mdm-collection-spacing`, Branch `fix/collection-grid-bottom-spacing`
auf origin/main `b3467e8`, nicht committet

### Ergebnis

Ohne verwandte Kategorien stand die Vertrauens-Box mit 0 px direkt unter Paginierung bzw.
Filterleiste. Jetzt hat das Produkt-Grid unten mindestens 60 px (ab 768 px) bzw. 40 px Abstand.
Das ist derselbe Abstand wie zwischen den Chips und der Vertrauens-Box. Die Regel greift nur, wenn
nach dem Grid keine Section mit eigenem Abstand folgt (verwandte Kategorien, Kollektionstext).

### Geänderte Dateien

- `assets/mdm-collection.css` — neuer Block nach Z. 398 (+18 Zeilen, nur `padding-block-end`)

### Abweichung vom Plan

Der Selektor schließt zusätzlich `.mdm-collection-hero` aus. In `collection.mdm.json` folgt unter
dem Grid ein Kollektionstext-Block mit eigenem Abstand. Ohne den Ausschluss kämen dort 60 px dazu.

### Messwerte (Dev-Server, Toleranz 1 px)

| Fall | 1440 | 1024 | 375 |
|---|---|---|---|
| `deutschland-muenzen-euro-goldmuenzen`, Paginierung → Vertrauens-Box | 60 | 60 | 40 |
| dieselbe Seite gefiltert, Filterleiste → Vertrauens-Box | 60 | — | — |
| `deutschland-muenzen` (12 Chips), Paginierung → Titel / Chips → Box | 60 / 60 | 60 / 60 | 32 / 40 |
| `?view=mdm`, Grid unten | 0 | — | 0 |
| Editor-Wert 80 (nur lokal) | 80 | 60 | 40 |

### Reviews

- theme-reviewer: APPROVED. Von den 2 minor-Hinweisen ist der Kommentarumbruch umgesetzt. Den dreifachen Selektor lassen wir bewusst so.
- security-reviewer: APPROVED, keine Findings.
- theme check: identisch zum Kontrolllauf auf `b3467e8`. validate_theme: VALID.

### Offen

- Abnahme durch Kerstin auf `deutschland-muenzen-euro-goldmuenzen`, nach Merge.
- Port nach IMM (gleicher Fehler) und Borek (Layout-Änderung vor `rich-text`). Das entscheidet Konrad.
- Die leere Section `mdm_bottom_sections_r4WkDz` in `collection.json` im Theme-Editor entfernen.
