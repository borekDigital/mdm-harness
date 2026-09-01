---
name: mdm-notes
description: "Pflege der Apple-Notes-Notizen zum MDM-Shopify-Projekt über den Notes-Connector: Projekt-Tagebuch, Ticket-Notizen, System und Ops, Skills-Liste — Ablage im Notes-Ordner Shopify mit Unterordnern Tagebuch/Tickets. Nutzen bei: Session-Start (Kontext lesen), Ticket-Start/-Meilensteinen/-Abschluss, Session-Ende, „schreib das ins Tagebuch/in die Notizen“."
---

# /mdm-notes — Notizpflege in Apple Notes

Das Projekt führt seinen Verlauf in Apple Notes (Connector-Tools: `list_notes`,
`get_note_content`, `add_note`, `update_note_content` — **kein Delete, kein Rename**;
Verschieben zwischen Ordnern nur per AppleScript/`osascript`).
Die Pflege übernimmt der Haupt-Thread, nicht die Sub-Agents (Connector ist user-scoped).

## Ablage (Ordnerstruktur, seit 2026-08-24)

Account „Auf meinem Mac", Ordner `Shopify` mit Unterordnern:

| Ordner | Inhalt |
|---|---|
| `Shopify` | Zustands-Notizen: Index, System und Ops, Skills und Agenten |
| `Shopify/Tagebuch` | Tagebuch-Notizen (eine je Halbjahr) |
| `Shopify/Tickets` | eine Notiz je Ticket |

Neue Notizen mit `add_note` und passendem `folder`-Parameter DIREKT im Zielordner anlegen,
nie im Standard-Ordner „Notes". Ticket-Notizen → `Tickets`, Tagebuch → `Tagebuch`.

## Fester Notiz-Satz (Titel = unveränderlicher Schlüssel)

| Titel | Typ | Pflege |
|---|---|---|
| `MDM Shopify :: Index` | Verzeichnis + Konventionen | nur bei Strukturänderung |
| `MDM Shopify :: Tagebuch 2026-H2` | Log | append-only, neuester Eintrag OBEN |
| `MDM Shopify :: System und Ops` | Zustand | in place; überholtes mit „ersetzt am JJJJ-MM-TT" markieren |
| `MDM Shopify :: Skills und Agenten` | Zustand | nur Status/Datum ändern, Beschreibungen stabil |
| `MDM Shopify :: Ticket <ID>` | Status-Kopf + Timeline | Kopf in place, Timeline append-only |

Titel enthalten bewusst KEIN `&` (Connector mangelt Entities; am 2026-08-24 von
„System & Ops"/„Skills & Agenten" auf „und" umbenannt — die Titelzeile ist die erste
Body-Zeile, ein Update der ersten Zeile benennt die Notiz um: deshalb Zeile 1 nie ändern).
Keine weiteren Notizen anlegen (Delete fehlt — Wildwuchs ist permanent). Neue Notiz-Typen
nur nach Freigabe durch Konrad, dann im Index nachtragen.

## Sicheres Schreiben (Pflichtprotokoll)

`update_note_content` ersetzt den GESAMTEN Inhalt. Deshalb immer:

1. `get_note_content` lesen.
2. Sentinel `--- ENDE ---` am Fuß prüfen — **fehlt er, NICHT schreiben** (Lese-Trunkierung
   → Datenverlust), stattdessen Konrad melden.
3. Neuen Inhalt einfügen (Logs: oben anfügen; Zustand: gezielt ersetzen), Rest byte-genau erhalten.
4. Vollständigen Body inkl. Sentinel zurückschreiben.

## Format

- Nur einfaches HTML: `div`, `br`, `b`, `h2`, `ul`/`li`. **Kein Markdown** (wird nicht
  gerendert), keine Checkboxen/Tabellen. Titel nicht im Body wiederholen.
- Maschinen-Einträge mit ISO-Datum `JJJJ-MM-TT`; Sprache deutsch.
- Tagebuch-/Timeline-Eintrag: Kontext / Getan / Entscheidungen (mit Warum) / Blocker /
  Nächste Schritte — leere Punkte weglassen.
- Keine Secrets, Tokens oder Credentials.
- Notiz > ~25 KB: Rollup oben, Nachfolger-Notiz (`… Teil 2` bzw. nächstes Halbjahr) anlegen,
  Index aktualisieren.

## Ticket-Notizen

- Anlegen in Phase 0 von `/mdm-template`: Titel `MDM Shopify :: Ticket <ticketId>`.
- Status-Kopf (erste Zeilen): Status `OFFEN | IN ARBEIT | REVIEW | FERTIG | BLOCKIERT`,
  Kurzbeschreibung, nächster Schritt. `FERTIG` erst nach APPROVED beider Reviews.
- Timeline: dated Einträge bei Phasenwechseln, Entscheidungen (Mini-ADR: Kontext /
  Entscheidung / Konsequenz), Review-Ergebnissen, Blockern — mit Evidenz
  (Dateipfade, Check-Ergebnisse, Commit-Hashes).

## Wann schreiben

- **Session-Start:** Index + Tagebuch (letzter Eintrag) lesen; bei Ticket-Arbeit die Ticket-Notiz.
- **Meilensteine:** Plan-Freigabe, Phase implementiert, Reviews, Blocker → Ticket-Timeline.
- **Session-Ende / Ticket-Abschluss:** Tagebuch-Eintrag; bei Systemänderungen zusätzlich
  `System und Ops` bzw. `Skills und Agenten` aktualisieren. Unterbrechung einkalkulieren —
  Meilensteine sofort festhalten, nicht sammeln.
