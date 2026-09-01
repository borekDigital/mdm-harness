---
paths:
  - "theme/templates/**"
---
# JSON-Templates

- JSON-Templates sind reine Wrapper: `sections`-Objekt + `order`-Array, keine Logik.
- Bestehende Templates tragen einen auto-generierten `/* … */`-Kommentar-Banner und werden
  vom Theme-Editor mitverwaltet — Änderungen daran vorher mit Konrad abstimmen
  (der PreToolUse-Hook fragt automatisch nach).
- Neue Templates: reines JSON ohne Banner. Naming: `page.<slug>.json` für Landingpages,
  `<typ>.mdm.json` für MDM-Varianten von product/collection.
- Section-IDs im Template sprechend wählen (`mdm-breadcrumbs`, `mdm-faq`), Reihenfolge
  über `order` steuern.
- Abschlusstest: Datei nach Entfernen eines etwaigen `/* */`-Banners mit einem
  JSON-Parser validieren.
