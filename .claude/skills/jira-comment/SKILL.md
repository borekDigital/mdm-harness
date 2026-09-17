---
name: jira-comment
description: "Schreibkonventionen fuer Jira-Ticket-Kommentare: Aufbau, Inhalt, Abschluss mit Handlungsaufforderung, ADF-Mentions mit accountId. Nutzen bei: Kommentar an ein Ticket schreiben, Statuswechsel dokumentieren, Rueckfrage an eine Fachabteilung stellen, Ticket abschliessen."
---

# /jira-comment — Ticket-Kommentare schreiben

Kommentare werden von Fachabteilungen gelesen, nicht nur von Entwicklern.
Sie sind zum **Scannen** gebaut, nicht zum Lesen.

## Aufbau

- **Kernaussage im ersten Satz** — Status oder Ergebnis, nicht die Vorgeschichte.
  Kernentitaeten, Statuswechsel und kritische Kennzahlen fett.
- Abschnitte mit `###`, Listen als Bullets.
- **Bullets** beginnen mit dem fett gesetzten Namen des Elements, danach hoechstens
  ein kurzer Satz.
- **Nummerierte Listen nur fuer Abfolgen** — alles andere sind Bullets.
- Aktiv formulieren, kurze Saetze.

## Inhalt

- Sachlich, neutral, loesungsorientiert. Keine Ich-Perspektive.
- Nur Fakten aus Ticket und Umsetzung — nichts hinzuerfinden.
- Nicht wiederholen, was im Ticketverlauf bereits steht.
- Begleitet der Kommentar einen Workflow-Wechsel: alten und neuen Status nennen.

## Abschluss

- Endet mit einer **fett markierten Handlungsaufforderung** an eine benannte Rolle,
  sofern eine Aktion noetig ist.
- `@`-Mention der zustaendigen Person, wenn eine Antwort erwartet wird.
  Technisch: ADF-`mention`-Node mit der `accountId` (`contentFormat: "adf"`).
  In Markdown geschriebene Mentions werden nicht verlinkt und benachrichtigen niemanden.
  Die `accountId` ueber `lookupJiraAccountId` aufloesen.
- Verwandte Ticket-IDs im Fliesstext nennen (`GRIFFIN-123`) — Jira verlinkt sie selbst.

## Nie

- Wall of Text, Begruessung, Verabschiedung.
- Emojis in technischen Tickets oder Bug-Tickets.
- Hinweise auf KI-Nutzung.
