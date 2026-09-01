## Block Complete: Multicolumn Themenkacheln (Pfad A)

Die Section `mdm-multicolumn-icon.liquid` wurde um 4 Features erweitert: Stretched Links
(vollflaeching klickbare Kacheln), Responsive Layout-Flip (Desktop col/center, Mobile
row/left), Mobile-Alternativtitel und Inline-SVG-Icons via Slug-basiertem `custom_icon_asset`.
Alle Features sind per Setting abschaltbar (backwards-compatible). Das Template
`page.hilfe.json` nutzt die erweiterte Section mit 6 Themenkacheln.

**Review-Status:** APPROVED (theme-reviewer) + NEEDS_REVISION → FIXED (security-reviewer)
- Security-Fix 1: `title_mobile` Typ von `inline_richtext` auf `text` + `| escape`
- Security-Fix 2: `custom_icon_asset` Slug-Pattern statt freiem Dateinamen
  (`mdm-icon-{slug}.svg` wird hartkodiert konstruiert)

**Geaenderte Dateien:**
- `theme/sections/mdm-multicolumn-icon.liquid` — Schema + Markup
- `theme/assets/mdm-component-multicolumn-card.css` — Stretched-Link, Focus, Responsive, Gap, Padding, Border
- `theme/templates/page.hilfe.json` — Neues Template mit 6 Bloecken
- `theme/locales/en.default.schema.json` — 5 neue Keys
- `theme/locales/de.schema.json` — 5 neue Keys
- `theme/assets/mdm-icon-hilfe-*.svg` — 6 SVG-Icons (currentColor, bereinigt)

**Vorschau:** Preview-Theme 188351185277
