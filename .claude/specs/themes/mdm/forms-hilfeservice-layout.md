# Spec: Hilfeservice-Template — Layout mdm-theme

## Ziel

Die Hilfe-Seiten mit dem Template `page.Forms - Hilfeservice` rendern über
`layout/mdm-theme.liquid` und laden damit den Consent-Manager, `brand-overrides.css` und das
Werbecode-Skript wie alle übrigen Seiten.

## Grundlage

- Bauplan theme-mdm, Etappe 2 (Seitenaufbau), Prüfpunkt 01, und Etappe 4, Prüfpunkt 01
  (15. Oktober 2026).
- Freigabe: Auftrag von Konrad im Chat am 15. Oktober 2026 („Fix den Layout-Schlüssel im
  Hilfeservice-Template“).

## Kontext — Ist-Stand

Stand: origin/main `50dd9bc`.

- ✅ `templates/page.Forms - Hilfeservice.json` trägt keinen `"layout"`-Schlüssel. Shopify
  rendert das Template deshalb über `layout/theme.liquid`.
- ✅ `layout/theme.liquid` rendert seit `1752efc` (11. Juni 2026) keinen Consent-Manager; nur
  `layout/mdm-theme.liquid:24` tut es.
- ✅ 76 von 78 JSON-Templates setzen `"layout": "mdm-theme"`, als ersten Schlüssel nach dem
  Kommentar-Banner (z. B. `templates/customers/login.json:11`). Ausnahmen: dieses Template und
  `password.json` (Layout `password`).
- ✅ Lesende Admin-Abfrage am 15. Oktober 2026: 13 veröffentlichte Seiten nutzen das Template
  (u. a. `hilfe_bestellwiderruf`, `hilfe_kundendatenaenderung`, `hilfe_reklamation`).
- ✅ Der Theme-Editor behält einen nachgetragenen Schlüssel: `page.Forms - Lieferstatus.json`
  trug ihn nach `c59c90b` (28. August 2026) auch in den Bot-Commits `12d1fed`, `b0973b5`,
  `abce2f5` bis zur Löschung am 13. Oktober 2026.
- ⚠️ Vermutung: die Shopify-App „Forms“ legt Templates ohne den Schlüssel an. Ein neues
  Forms-Template braucht den Fix dann erneut. Beweis fehlt (Ereignisprotokoll im Admin).

## Anforderungen

- [ ] `templates/page.Forms - Hilfeservice.json` setzt `"layout": "mdm-theme"`.
- [ ] Sonst ändert sich am Template nichts.

## Akzeptanzkriterien

- [x] A1: Der Diff gegen origin/main besteht aus genau einer hinzugefügten Zeile
  `"layout": "mdm-theme",` an Position 11, direkt nach dem Banner.
- [x] A2: Die Datei ist nach Entfernen des `/* … */`-Banners gültiges JSON; Sections, Blocks
  und `order` sind unverändert (Vergleich der geparsten Objekte ohne `layout`).
- [x] A3: `shopify theme check` meldet für die Datei keinen Befund (CLI 4.9.3; Theme gesamt
  unverändert 64 Befunde aus dem Bestand).
- [x] A4: Kein JSON-Template außer `password.json` ist ohne `"layout"`-Schlüssel — geprüft:
  alle 78 tragen einen, `password.json` mit `password`.
- [ ] A5 (nach dem Merge, im Shop): Der Quelltext einer Hilfe-Seite, z. B.
  `/pages/hilfe_reklamation`, enthält `cdn.consentmanager.net` vor `content_for_header`.

## Constraints

- Template-Datei wird vom Theme-Editor mitverwaltet; keine weiteren Änderungen daran.
- Keine Änderung an `layout/theme.liquid` (Hyper-Original).
- Blast-Radius: die 13 Seiten mit diesem Template. Sie erhalten zusätzlich
  `brand-overrides.css` und das Werbecode-Skript; die Darstellung kann sich dadurch ändern.
- Markenspezifisch: Templates werden nicht nach Borek oder IMM übertragen.

## Status

IMPLEMENTIERT — A1 bis A4 werden im Branch `fix/forms-hilfeservice-layout` geprüft, A5 nach
dem Merge.
