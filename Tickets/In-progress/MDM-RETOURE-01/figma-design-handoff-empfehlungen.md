# Figma-Handoff-Empfehlungen für die Designerin (Shopify / Hyper-Theme)

Entstanden aus MDM-RETOURE-01 · Datum: 24. August 2026

Zweck: Diese Punkte machen Design-Übergaben so eindeutig, dass Umsetzung und Review
weniger Interpretationsspielraum haben. Auslöser waren zwei Abweichungen, die durch das
Review rutschten (Button-Textfarbe im Default/Hover) — beide, weil ein Interaktionszustand
und ein effektiver Wert im Design nicht explizit genug definiert waren.

## Die zwei konkreten Lehren aus diesem Ticket

1. **Interaktionszustände sichtbar mitliefern.** Der Button-Hover war im Frame nur „gedacht",
   nicht als eigener sichtbarer State im File. Dadurch war für Umsetzung und Review nicht
   verbindlich, welche Textfarbe im Hover gilt → durchgerutscht.
2. **Feste px-Werte statt „sieht so aus".** Die Fragen-Schrift war als Style gesetzt, dessen
   effektive Größe im Theme (Skalierung) von der Design-Absicht abwich (25,9px statt 18px).
   Ein explizit annotierter px-Wert hätte die Abweichung sofort sichtbar gemacht.

## Empfehlungen (nach Wirkung sortiert)

### 1. Jeden interaktiven Zustand als eigenen, sichtbaren Frame/Variant designen
Für jedes klickbare Element: **Default, Hover, Focus, Active, Disabled** (und wo relevant
Loading/Error/Empty). Ein Button ohne diese States ist eine unvollständige Spezifikation.
Konkret für unsere Buttons: pro Variante (primary/secondary) Default UND Hover als eigene
Component-Variant, damit Füllfarbe, Textfarbe und Rahmen je State ablesbar sind — nicht nur
der Ruhezustand. Das ist der Punkt, der uns hier zweimal getroffen hat.

### 2. Variant-/Layer-Namen an die Theme-Terminologie angleichen
Wir nutzen im Theme `btn--primary` und `btn--secondary`. Wenn die Figma-Varianten genauso
heißen (`primary`, `secondary`), ist die Zuordnung Design ↔ Code eindeutig. Gleiches für
Zustände: eine Variant-Property `state = default | hover | focus | disabled`.

### 3. Figma-Variablen (Tokens) statt roher Hex-/px-Werte verwenden
Farben und Abstände als **benannte Variablen** vergeben (z. B. `color/prussian = #002147`,
`color/stone-100 = #3e3a32`) statt als lose Hex-Werte. In Dev Mode sieht die Umsetzung dann
den Token-Namen statt eines nackten Werts — das reduziert Rückfragen und Fehlgriffe. Ideal:
ein fester Token-Satz, der 1:1 zu unseren Theme-Variablen passt.

### 4. Typografie mit explizitem px + line-height annotieren
Für jeden Text: font-family, **exakte px-Größe**, line-height, font-weight. Wenn ein Wert
bewusst von einem Standard-Textstyle abweicht, das im Frame vermerken. So fällt jede
Theme-Skalierung sofort auf, statt erst im Live-Test.

### 5. Zustände von Farb-Paaren immer als Vorder-/Hintergrund-Paar angeben
Statt nur „Text weiß": „Text weiß auf Hintergrund Prussian" — für Default UND Hover. Das macht
auch den Kontrast prüfbar (WCAG AA ≥ 4,5:1) und verhindert, dass eine Farbe je State
undefiniert bleibt.

### 6. Auto-Layout konsequent nutzen
Padding, Gap und Ausrichtung aus Auto-Layout mappen direkt auf CSS-Flexbox. Frames ohne
Auto-Layout zwingen die Umsetzung zum Raten der Abstände.

### 7. Mobile-Frames mitliefern
Desktop UND mindestens einen Mobile-Breakpoint je Template — sonst ist responsives Verhalten
Interpretation.

## Was auf unserer (Umsetzungs-)Seite dauerhaft verbessert wurde

Damit solche Lücken auch ohne perfektes Design auffallen, wurde der Umsetzungs-/Review-Prozess
prinzipienbasiert geschärft (in den internen Arbeitsanweisungen):
- Effektive CSS-Kaskade im Einbettungs-Kontext wird je Eigenschaft UND je Zustand
  durchgerechnet (nicht nur „Variable gesetzt = fertig").
- Effektiver Computed-Wert wird gegen die Spec geprüft, nicht die Utility-Klasse.
- Alle Interaktionszustände werden bewertet; bei interaktiven Komponenten ist eine
  Live-Sichtkontrolle im Dev-Server ausdrücklich empfohlen, weil ein Standbild-Review
  Hover-/Focus-Bugs prinzipbedingt nicht sieht.

## Quellen (Best Practice 2026)
- Figma to Code: The Complete Design Handoff Guide (2026) — webdesigndev.com
- 7 Figma Design System Best Practices for 2026: Tokens, Sync & Scale — atomize.tools
- Design Tokens: How to Sync Design and Code in Figma — figma.com
