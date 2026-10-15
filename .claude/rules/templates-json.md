---
paths:
  - "themes/*/templates/**"
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
- Geteilte Templates: `collection.json`, `collection.mdm.json`, `product.json` und
  `product.mdm.json` sind in allen drei Themes gleich, Vorlage ist MDM. Änderungen daran
  zuerst in `themes/mdm/`, dann mit `bin/theme-sync.sh port mdm borek,imm <pfad>`
  übertragen — das Skript setzt den `layout`-Schlüssel auf die Zielmarke. Alle übrigen
  Templates bleiben markenspezifisch, bis sie mit Bhavani abgestimmt sind.
- Abschlusstest: Datei nach Entfernen eines etwaigen `/* */`-Banners mit einem
  JSON-Parser validieren.
