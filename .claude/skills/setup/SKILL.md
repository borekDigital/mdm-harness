---
name: "setup"
description: "Interaktives Setup fuer den MDM-Workspace. Klont ausgewaehlte Repos und richtet die lokale Umgebung ein."
user_invocable: true
---

# /setup — MDM Workspace Setup

Fuehrt das interaktive Setup-Script aus, das Repos aus `workspace.yaml` zum
Klonen anbietet und die lokale Umgebung einrichtet.

## Ablauf

1. Fuehre `./setup.sh` im Workspace-Root aus
2. Der User waehlt im Terminal-Menue die gewuenschten Repos
3. Ausgewaehlte Repos werden geklont
4. `.workspace.local.yaml` wird geschrieben (Guard-State)
5. `CLAUDE.md` wird via `sync.sh` regeneriert

## Varianten

- `./setup.sh` — Ersteinrichtung oder Nachinstallation (zeigt bereits geklonte Repos als ausgegraut)
- `./setup.sh --add` — Zeigt nur fehlende Repos an
- `./setup.sh --sync` — Nur CLAUDE.md regenerieren (kein Menue)
- `./setup.sh --reset` — Lokalen State zuruecksetzen (Repos bleiben erhalten)

## Anweisungen

Wenn der User `/setup` aufruft:

```bash
cd "${CLAUDE_PROJECT_DIR}" && ./setup.sh
```

Falls der User nach dem Setup fragt ob alles geklappt hat, pruefe:
- Existieren die ausgewaehlten Repo-Verzeichnisse?
- Existiert `.workspace.local.yaml`?
- Wurde `CLAUDE.md` aktualisiert?
