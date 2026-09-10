#!/bin/bash
# Bettet die Schriften des Design-Vertrags als data:-URI in den Kopf ein.
#
# Warum eingebettet: die Artifact-CSP blockiert externe Hosts, und beim
# PDF-Export laedt ein CDN unzuverlaessig. Eine ausgefallene Schrift verschiebt
# jede SVG-Beschriftung — die Zeichenbreiten in figure-grammar.md sind auf
# diese Schnitte gerechnet.
#
# Warum STATISCHE Schnitte und nicht die Variable Fonts von Google:
# Chromes print-to-PDF bettet Variable Fonts nicht ein, sondern ersetzt sie
# (belegt am 10. September 2026 — JetBrains Mono wurde zu Menlo). Fontsource
# liefert je Gewicht eine eigene Datei.
#
# Danach: bin/bauplan-restyle.py, um bestehende Seiten nachzuziehen.
set -e
PROJECT="${CLAUDE_PROJECT_DIR:-$HOME/MDM}"
HEAD="$PROJECT/.claude/skills/repo-bauplan/assets/bauplan-head.html"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

BASE="https://cdn.jsdelivr.net/npm/@fontsource"
declare -a FILES=(
  "archivo@5/files/archivo-latin-400-normal.woff2|Archivo|400"
  "archivo@5/files/archivo-latin-600-normal.woff2|Archivo|600"
  "jetbrains-mono@5/files/jetbrains-mono-latin-400-normal.woff2|JetBrains Mono|400"
  "jetbrains-mono@5/files/jetbrains-mono-latin-700-normal.woff2|JetBrains Mono|700"
  "saira-condensed@5/files/saira-condensed-latin-600-normal.woff2|Saira Condensed|600"
  "saira-condensed@5/files/saira-condensed-latin-700-normal.woff2|Saira Condensed|700"
)

echo "Schriften holen:"
for entry in "${FILES[@]}"; do
  path="${entry%%|*}"; rest="${entry#*|}"; fam="${rest%%|*}"; w="${rest##*|}"
  out="$TMP/$(echo "$fam" | tr ' ' '_')-$w.woff2"
  curl -sfL -o "$out" "$BASE/$path"
  # Signatur pruefen: eine HTML-Fehlerseite wuerde sonst als Schrift eingebettet
  if [ "$(head -c 4 "$out")" != "wOF2" ]; then
    echo "  FEHLER: $path liefert kein woff2" >&2; exit 1
  fi
  printf "  %-22s %6.1f KB\n" "$fam $w" "$(echo "scale=1; $(wc -c < "$out")/1024" | bc)"
done

python3 - "$TMP" "$HEAD" <<'PY'
import base64, os, re, sys
tmp, head_path = sys.argv[1], sys.argv[2]

faces = []
for name in sorted(os.listdir(tmp)):
    fam, w = name[:-len(".woff2")].rsplit("-", 1)
    fam = fam.replace("_", " ")
    with open(os.path.join(tmp, name), "rb") as fh:
        data = base64.b64encode(fh.read()).decode("ascii")
    faces.append(
        "  @font-face {\n"
        "    font-family: '%s';\n"
        "    font-style: normal;\n"
        "    font-weight: %s;\n"
        "    font-display: swap;\n"
        "    src: url(data:font/woff2;base64,%s) format('woff2');\n"
        "  }" % (fam, w, data)
    )

s = open(head_path, encoding="utf-8").read()
s = re.sub(r'<link rel="preconnect"[^>]*>\n', "", s)
s = re.sub(r'<link rel="stylesheet" href="https://fonts\.googleapis\.com[^>]*>\n', "", s)
s = re.sub(r"  /\* Schriften eingebettet.*?\*/\n", "", s, flags=re.S)
s = re.sub(r"  @font-face \{.*?\n  \}\n*", "", s, flags=re.S)

kommentar = (
    "  /* Schriften als data:-URI eingebettet, statische Einzelgewichte.\n"
    "     Die Artifact-CSP blockiert externe Hosts; Chromes print-to-PDF\n"
    "     bettet Variable Fonts nicht ein. Erneuern: bin/bauplan-fonts.sh */\n"
)
s = s.replace("<style>\n", "<style>\n" + kommentar + "\n".join(faces) + "\n\n", 1)
open(head_path, "w", encoding="utf-8").write(s)
print("Kopf: %.1f KB, %d Schnitte, %d externe Verweise"
      % (len(s) / 1024, s.count("@font-face"), s.count("fonts.googleapis.com")))
PY
