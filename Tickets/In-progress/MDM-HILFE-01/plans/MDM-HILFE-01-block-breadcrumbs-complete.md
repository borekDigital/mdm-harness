## Block Complete: Breadcrumbs Page-Alignment (Edge-to-Edge)

Die Breadcrumb-Section `mdm-breadcrumbs.liquid` wurde auf eine Zwei-Ebenen-Struktur
umgebaut: aeusserer Container edge-to-edge (voller Viewport), innerer Container mit
`page-width` (Content-Raster). Der Umbau folgt dem etablierten Hyper-Pattern
(z. B. `shop-the-feed.liquid`, `collapsible-tabs.liquid`). Zusaetzlich wurde die
statische CSS-Klasse `mdm-breadcrumbs` ergaenzt (behebt toten CSS-Code) und der
`show_divider`-Default auf `false` geaendert.

**Review-Status:** APPROVED (theme-reviewer + security-reviewer, parallel)

**Geaenderte Dateien:**
- `theme/sections/mdm-breadcrumbs.liquid` — Zwei-Ebenen-Wrapper, statische Klasse, Schema-Default
- `theme/assets/mdm-section-breadcrumbs.css` — Unkontrollierte border-bottom-Regel entfernt

**Nicht geaendert:** `templates/page.hilfe.json`, Locales, FoxEcom-Original

**Abwaertskompatibilitaet:** Alle 7 Templates geprueft — visuell neutral, Selektoren in
`mdm-page-retoure.css`, Product-Template `custom_css` und `{% style %}`-Block greifen
weiterhin korrekt.

**Vorschau:** `cd theme && shopify theme dev --store mdm-muenze`
