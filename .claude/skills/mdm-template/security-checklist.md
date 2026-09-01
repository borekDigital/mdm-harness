# Security-Checkliste (security-reviewer)

## Output-Escaping (XSS)
- [ ] Jede Ausgabe von Settings/Kundeneingaben/URL-Parametern/Metafeldern: `| escape`
- [ ] `richtext`-Ausgaben nur bewusst und im `.rte`-Wrapper (als accepted-by-design markieren)
- [ ] Keine Nutzerdaten in Inline-`<script>` ohne `| json`
- [ ] `content_for_header` unverändert
- [ ] Keine `javascript:`-URLs, keine dynamischen Attribut-Injektionen ohne Escaping

## Externe Ressourcen (DSGVO + Supply Chain)
- [ ] Keine neuen externen Scripts/Fonts/iframes/Pixel/CDN-Referenzen
- [ ] Fonts bleiben self-hosted in `assets/`
- [ ] Jede Ausnahme ist im Plan dokumentiert und von Konrad freigegeben

## Secrets & Daten
- [ ] Keine API-Keys/Tokens/Store-Interna in Code, Schema-Defaults oder Kommentaren
- [ ] Keine Kundendaten in Query-Strings
- [ ] Keine KI-Spuren in Code/Kommentaren

## Formulare & Links
- [ ] Shopify `{% form %}`-Tags (CSRF-Schutz), keine handgebauten POST-Endpoints
- [ ] `target="_blank"` immer mit `rel="noopener"`

## JavaScript
- [ ] Kein `eval`/`new Function`; `innerHTML` nur mit statischem/escaptem Inhalt
- [ ] Kein fetch zu Nicht-Shopify-Origins
- [ ] Event-Handler interpolieren keine rohen Nutzerdaten

## Merchant-Dateien
- [ ] `config/settings_data.json` unangetastet
- [ ] `settings_schema.json` nur additiv erweitert
