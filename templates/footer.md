## Test-Driven Development

TDD ist Pflicht fuer alle Code-Aenderungen: **Red → Green → Refactor.** Kein Feature-Code
ohne vorherigen Test, kein Bugfix ohne Regression-Test. Test und Feature-Code gehoeren in
denselben Commit. Vor jedem Commit muss die Suite gruen sein.

| Bereich | Framework | Kommando |
|---|---|---|
| Connector | RSpec + FactoryBot, WebMock/VCR | `bundle exec rspec` |
| Middleware | PHPUnit | `docker compose exec app bin/phpunit` |
| Theme | keins — Liquid hat kein Unit-Test-Framework | `shopify theme check` + Smoke-Test |

Details je Stack: `.claude/rules/`

## Git Worktree

Parallele Feature-Arbeit laeuft in eigenen Worktrees unter `connector-worktrees/<branch>/`
(Workspace-Root-Ebene, gitignored) — nicht innerhalb von `connector/`. Der Haupt-Worktree
`connector/` bleibt immer auf `main`. Jeder Worktree braucht seine eigene `.env` (aus
`.env.template`). Nach dem Merge: Worktree entfernen und Branch loeschen.

```bash
cd connector && git worktree add ../connector-worktrees/<branch> -b <branch>
```

## Sprache und Commits

Deutsch fuer Doku und Artefakte, Englisch fuer Commits (Conventional Commits, 50/72,
imperativ, kleingeschrieben). **Der Scope ist nie eine Ticket-ID.** Weitere Vorgaben
stehen in der globalen `~/.claude/CLAUDE.md` und gelten hier unveraendert.

## Konventionen anderswo

| Thema | Ort |
|---|---|
| Jira-Ticket-Kommentare | Skill `/jira-comment` |
| Aenderung in mehrere Themes portieren | Skill `/theme-port` |
| Apple-Notes-Pflege | Skill `/mdm-notes` |
| Bereichs-Konventionen (Liquid, Rails, Symfony) | `.claude/rules/` |
| Systemuebersicht Agenten/Skills/Hooks | `.claude/README.md` |
