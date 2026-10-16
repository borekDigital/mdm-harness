#!/usr/bin/env python3
"""harness-check.py — prueft die Claude-Struktur gegen den dokumentierten Stand.

Spec: .claude/specs/harness/claude-struktur-aktuell.md, Teil C.

Was erlaubt ist (Frontmatter-Felder, Modelle, Hook-Events, MCP-Werkzeuge),
steht nur in bin/harness-referenz.json. Aendert sich Claude Code, wird diese
Datei angepasst, nicht dieses Skript.

Exit-Codes wie bin/bauplan-ci.py:
  0  sauber
  3  mindestens ein Befund
  2  Defekt (kaputtes JSON, fehlende Referenz) — kein gueltiger Befund

Verwendung:
  python3 bin/harness-check.py              alles, inkl. Schema und plugin validate
  python3 bin/harness-check.py --offline    ohne Netz und ohne claude-CLI
  python3 bin/harness-check.py --json       maschinenlesbar (CI)
"""

import argparse
import glob
import json
import os
import re
import shutil
import subprocess
import sys

BEFUND, DEFEKT = 3, 2


class Defekt(Exception):
    pass


class Pruefung:

    def __init__(self, root, offline, schema_datei=None):
        self.root = root
        self.offline = offline
        self.schema_datei = schema_datei
        self.befunde = []
        self.uebersprungen = []
        self.ref = self.lade_json("bin/harness-referenz.json")
        self.skills = set()
        self.agenten_namen = set()

    # --- Hilfen -----------------------------------------------------------

    def pfad(self, rel):
        return os.path.join(self.root, rel)

    def lade_json(self, rel):
        try:
            with open(self.pfad(rel), encoding="utf-8") as fh:
                return json.load(fh)
        except FileNotFoundError:
            raise Defekt("%s fehlt" % rel)
        except json.JSONDecodeError as e:
            raise Defekt("%s ist kein gueltiges JSON: %s" % (rel, e))

    def lies(self, rel):
        with open(self.pfad(rel), encoding="utf-8") as fh:
            return fh.read().splitlines()

    def melde(self, code, datei, zeile, text):
        self.befunde.append({"code": code, "datei": datei, "zeile": zeile, "text": text})

    def dateien(self, muster):
        treffer = glob.glob(muster, root_dir=self.root, recursive=True)
        return sorted(t for t in treffer if os.path.isfile(self.pfad(t)))

    def frontmatter(self, rel):
        """Liefert {feld: (zeile, wert)}. wert ist str oder Liste.

        Bewusst minimal statt PyYAML: der Runner soll ohne Pakete auskommen,
        und die Harness nutzt nur Schluessel, Strings und einfache Listen.
        """
        zeilen = self.lies(rel)
        if not zeilen or zeilen[0].strip() != "---":
            return {}
        felder, aktuell = {}, None
        for nr, zeile in enumerate(zeilen[1:], start=2):
            if zeile.strip() == "---":
                return felder
            if not zeile.strip() or zeile.lstrip().startswith("#"):
                continue
            m = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*):(.*)$", zeile)
            if m:
                aktuell = m.group(1)
                wert = m.group(2).strip().strip('"').strip("'")
                felder[aktuell] = (nr, wert if wert else [])
                continue
            m = re.match(r"^\s+-\s+(.*)$", zeile)
            if m and aktuell and isinstance(felder[aktuell][1], list):
                felder[aktuell][1].append(m.group(1).strip().strip('"').strip("'"))
                continue
            if zeile.startswith((" ", "\t")):
                continue  # verschachtelter Wert (hooks, mcpServers, metadata)
            self.melde("H00", rel, nr, "Frontmatter-Zeile nicht lesbar: %s" % zeile.strip())
        self.melde("H00", rel, 1, "Frontmatter ohne schliessendes ---")
        return felder

    # --- Agenten, Skills, Rules -------------------------------------------

    def agenten(self):
        erlaubt = set(self.ref["agent_felder"])
        aliase = set(self.ref["modell_aliase"])
        muster = re.compile(self.ref["modell_id_muster"])
        for rel in self.dateien(".claude/agents/*.md"):
            felder = self.frontmatter(rel)
            self.agenten_namen.add(os.path.basename(rel)[:-3])
            if "name" in felder and felder["name"][1]:
                self.agenten_namen.add(felder["name"][1])
            for pflicht in self.ref["agent_pflichtfelder"]:
                if pflicht not in felder:
                    self.melde("H01", rel, 1, "Pflichtfeld `%s` fehlt" % pflicht)
            zeilen = [z.strip() for z in self.lies(rel)]
            for abschnitt in self.ref["agent_pflichtabschnitte"]:
                if abschnitt not in zeilen:
                    self.melde("H18", rel, 1, "Abschnitt `%s` fehlt — Spec Teil A" % abschnitt)
            for feld, (nr, wert) in felder.items():
                if feld not in erlaubt:
                    self.melde("H02", rel, nr, "unbekanntes Agenten-Feld `%s` — wird still ignoriert" % feld)
                elif feld == "model" and wert not in aliase and not muster.match(str(wert)):
                    self.melde("H03", rel, nr, "ungueltiges Modell `%s`" % wert)

    def skills_pruefen(self):
        erlaubt = set(self.ref["skill_felder"])
        for rel in self.dateien(".claude/skills/*/SKILL.md"):
            self.skills.add(rel.split("/")[2])
            felder = self.frontmatter(rel)
            if "name" in felder and felder["name"][1]:
                self.skills.add(felder["name"][1])
            for feld, (nr, _) in felder.items():
                if feld not in erlaubt:
                    self.melde("H04", rel, nr, "unbekanntes Skill-Feld `%s` — wird still ignoriert" % feld)

    def rules(self):
        erlaubt = set(self.ref["rule_felder"])
        for rel in self.dateien(".claude/rules/**/*.md"):
            felder = self.frontmatter(rel)
            for feld, (nr, wert) in felder.items():
                if feld not in erlaubt:
                    self.melde("H05", rel, nr, "unbekanntes Rule-Feld `%s` — nur `paths` wird gelesen" % feld)
            if "paths" not in felder:
                continue
            nr, wert = felder["paths"]
            globs = wert if isinstance(wert, list) else [g.strip() for g in wert.split(",")]
            zeilen = self.lies(rel)
            for g in globs:
                zeile = next((i for i, z in enumerate(zeilen, 1) if g in z), nr)
                kopf = re.split(r"[*?\[]", g)[0].split("/")[0]
                if kopf and not os.path.isdir(self.pfad(kopf)):
                    self.uebersprungen.append("%s: `%s` — Verzeichnis %s/ fehlt" % (rel, g, kopf))
                    continue
                # Erstes Segment mit Platzhalter ohne jeden Treffer: das Verzeichnis
                # ist leer (z. B. connector-worktrees/ ohne aktiven Worktree).
                teile = g.split("/")
                erstes = next((i for i, t in enumerate(teile) if re.search(r"[*?\[]", t)), None)
                if erstes is not None and "**" not in teile[erstes]:
                    stamm = "/".join(teile[:erstes + 1])
                    if not glob.glob(stamm, root_dir=self.root):
                        self.uebersprungen.append("%s: `%s` — %s ist leer" % (rel, g, stamm))
                        continue
                treffer = glob.iglob(g, root_dir=self.root, recursive=True)
                if next(treffer, None) is None:
                    self.melde("H06", rel, zeile, "Glob `%s` trifft keine Datei" % g)

    # --- Versionen gegen Lockfiles ----------------------------------------

    def versionen(self):
        """Tabellen mit Spalten `Version` und `Beleg` in den Rules gegen die Lockfiles pruefen.

        Beleg-Zelle: `datei` · `paket`. Die Version in der Tabelle gilt als Praefix:
        „7.1“ passt zu 7.1.11, nicht zu 7.2.2.
        """
        for rel in self.dateien(".claude/rules/**/*.md"):
            spalten = None
            for nr, zeile in enumerate(self.lies(rel), 1):
                if not zeile.startswith("|"):
                    spalten = None
                    continue
                zellen = [z.strip() for z in zeile.strip().strip("|").split("|")]
                if spalten is None:
                    if "Version" in zellen and "Beleg" in zellen:
                        spalten = (zellen.index("Bibliothek") if "Bibliothek" in zellen else 0,
                                   zellen.index("Version"), zellen.index("Beleg"))
                    continue
                if set(zeile) <= set("|-: "):
                    continue
                name, soll, beleg = (zellen[i] if i < len(zellen) else "" for i in spalten)
                teile = re.findall(r"`([^`]+)`", beleg)
                if len(teile) < 2 or not re.match(r"^\d", soll):
                    continue
                datei, paket = teile[0], teile[1]
                if not os.path.isfile(self.pfad(datei)):
                    self.uebersprungen.append("%s: %s — %s fehlt" % (rel, name, datei))
                    continue
                ist = self.installiert(datei, paket)
                if ist is None:
                    self.melde("H19", rel, nr, "%s: Paket `%s` in `%s` nicht gefunden" % (name, paket, datei))
                elif not (ist == soll or ist.startswith(soll + ".") or ist.startswith(soll + "-")):
                    self.melde("H19", rel, nr, "%s steht hier auf %s, `%s` auf %s" % (name, soll, datei, ist))

    def installiert(self, datei, paket):
        text = open(self.pfad(datei), encoding="utf-8").read()
        if datei.endswith("composer.lock"):
            daten = json.loads(text)
            for p in daten.get("packages", []) + daten.get("packages-dev", []):
                if p.get("name") == paket:
                    return p.get("version", "").lstrip("v")
            return None
        if datei.endswith("Gemfile.lock"):
            m = re.search(r"^ {4}%s \(([^)]+)\)" % re.escape(paket), text, re.M)
            return m.group(1) if m else None
        # Generisch: JSON/TOML/Ruby-Zuweisung (`"nuxt": "2.15.8"`, `api_version = "2026-04"`)
        # und .ruby-version (`ruby-4.0.2`).
        m = re.search(r"(?<![\w@/.-])[\"']?%s[\"']?\s*[=:-]\s*[\"']?[\^~>=<v ]*(\d[\w.-]*)" % re.escape(paket), text)
        return m.group(1) if m else None

    # --- Settings, Hooks, MCP ---------------------------------------------

    def settings(self):
        rel = ".claude/settings.json"
        if not os.path.isfile(self.pfad(rel)):
            return
        data = self.lade_json(rel)
        if "$schema" not in data:
            self.melde("H07", rel, 1, "`$schema` fehlt — Tippfehler in Schluesseln bleiben unbemerkt")
        events = set(self.ref["hook_events"])
        zeilen = self.lies(rel)
        ohne_pfad = tuple("%s(" % w for w in self.ref["werkzeuge_ohne_pfadregel"])
        for liste in ("allow", "ask", "deny"):
            for regel in (data.get("permissions") or {}).get(liste, []):
                if regel.startswith(ohne_pfad) and not regel.endswith("()"):
                    nr = next((i for i, z in enumerate(zeilen, 1) if regel in z), 1)
                    self.melde("H17", rel, nr, "Regel `%s` (%s) wird nie geprueft — Pfadregeln nur fuer Edit und Read"
                               % (regel, liste))
        for event, gruppen in (data.get("hooks") or {}).items():
            if event not in events:
                nr = next((i for i, z in enumerate(zeilen, 1) if '"%s"' % event in z), 1)
                self.melde("H08", rel, nr, "unbekanntes Hook-Event `%s`" % event)
            for gruppe in gruppen or []:
                for hook in gruppe.get("hooks", []):
                    for skript in re.findall(r"\.claude/hooks/[\w.-]+", hook.get("command", "")):
                        if not os.path.isfile(self.pfad(skript)):
                            nr = next((i for i, z in enumerate(zeilen, 1) if skript in z), 1)
                            self.melde("H09", rel, nr, "Hook-Skript `%s` fehlt" % skript)

    def waechter(self):
        """Jeder vorhandene Waechter-Hook ist registriert und blockiert, wenn er scheitert (H20)."""
        rel = ".claude/settings.json"
        if not os.path.isfile(self.pfad(rel)):
            return
        data = self.lade_json(rel)
        zeilen = self.lies(rel)
        eintraege = [h for gruppen in (data.get("hooks") or {}).values() for g in gruppen or []
                     for h in g.get("hooks", [])]
        for skript in self.ref["waechter_hooks"]:
            if not os.path.isfile(self.pfad(".claude/hooks/" + skript)):
                continue
            treffer = [h for h in eintraege if skript in h.get("command", "")]
            if not treffer:
                self.melde("H20", rel, 1, "Waechter `%s` existiert, ist aber nicht registriert" % skript)
            for h in treffer:
                if h.get("onFailure") != "block":
                    nr = next((i for i, z in enumerate(zeilen, 1) if skript in z), 1)
                    self.melde("H20", rel, nr, "Waechter `%s` ohne `\"onFailure\": \"block\"` (ist: %s) — "
                               "scheitert er, laeuft die Aktion durch" % (skript, h.get("onFailure", "continue")))

    def readme_modelle(self):
        """Modell-Spalte der Agenten-Tabellen in .claude/README.md gegen das Frontmatter (H21)."""
        rel = ".claude/README.md"
        if not os.path.isfile(self.pfad(rel)):
            return
        modelle = {}
        for agent in self.dateien(".claude/agents/*.md"):
            felder = self.frontmatter(agent)
            if "model" in felder:
                modelle[os.path.basename(agent)[:-3]] = felder["model"][1]
        for nr, zeile in enumerate(self.lies(rel), 1):
            m = re.match(r"^\|\s*([a-z][a-z0-9-]*)\s*\|\s*([^|]+?)\s*\|", zeile)
            if m and m.group(1) in modelle and m.group(2) != modelle[m.group(1)]:
                self.melde("H21", rel, nr, "%s steht hier als `%s`, im Frontmatter als `%s`"
                           % (m.group(1), m.group(2), modelle[m.group(1)]))

    def hook_skripte(self):
        for rel in self.dateien(".claude/hooks/*.sh"):
            for nr, zeile in enumerate(self.lies(rel), 1):
                for ziel in re.findall(r"\$\{?CLAUDE_PROJECT_DIR\}?/([A-Za-z0-9_./-]+)", zeile):
                    ziel = ziel.rstrip("./")
                    if ziel and not os.path.exists(self.pfad(ziel)):
                        self.melde("H10", rel, nr, "verweist auf `%s`, das es nicht gibt" % ziel)

    def mcp_json(self):
        rel = ".mcp.json"
        if not os.path.isfile(self.pfad(rel)):
            return
        data = self.lade_json(rel)
        bekannt = {s["paket"]: s["version"] for s in self.ref["mcp_server"].values()}
        zeilen = self.lies(rel)
        for name, server in (data.get("mcpServers") or {}).items():
            if server.get("command") != "npx":
                continue
            paket = next((a for a in server.get("args", []) if not a.startswith("-")), None)
            if not paket:
                continue
            nr = next((i for i, z in enumerate(zeilen, 1) if paket in z), 1)
            m = re.match(r"^(@?[^@]+)(?:@(.+))?$", paket)
            basis, version = m.group(1), m.group(2)
            if not version or version in ("latest", "next"):
                self.melde("H12", rel, nr, "`%s` ohne feste Version (%s) — Werkzeugnamen wechseln unbemerkt"
                           % (name, "@" + version if version else "keine Angabe"))
            elif basis in bekannt and version != bekannt[basis]:
                self.melde("H12", rel, nr, "`%s` steht auf %s, die Referenz auf %s — beide gemeinsam anheben"
                           % (name, version, bekannt[basis]))

    # --- Verweise in Texten -----------------------------------------------

    def textdateien(self):
        muster = [".claude/agents/*.md", ".claude/skills/**/*.md", ".claude/rules/**/*.md",
                  ".claude/README.md", "templates/*.md", ".claude/settings.json",
                  ".claude/settings.local.json"]
        return sorted({d for m in muster for d in self.dateien(m)})

    def verweise(self):
        server = self.ref["mcp_server"]
        stichworte = {w: s for s, cfg in server.items() for w in cfg["stichworte"]}
        extern = set(self.ref["externe_skills"])
        voll = re.compile(r"mcp__([A-Za-z0-9_-]+?)__([A-Za-z0-9_]+)")
        nackt = re.compile(r"`([a-z]+(?:_[a-z]+)+)`")
        agent = re.compile(r"\b([a-z]+(?:-[a-z]+)*-(?:%s))\b" % "|".join(self.ref["agent_rollen"]))
        slash = re.compile(r"(?:^|[\s(|\[\"„])`/([a-z][a-z0-9-]*(?::[a-z0-9-]+)?)(?=[`\s])")
        for rel in self.textdateien():
            abschnitt = ""
            for nr, zeile in enumerate(self.lies(rel), 1):
                if zeile.startswith("#"):
                    abschnitt = zeile
                for srv, werkzeug in voll.findall(zeile):
                    if srv in server and werkzeug not in server[srv]["werkzeuge"]:
                        self.melde("H11", rel, nr, "MCP-Werkzeug `%s` gibt es bei %s@%s nicht"
                                   % (werkzeug, srv, server[srv]["version"]))
                kontext = next((s for w, s in stichworte.items() if w in zeile or w in abschnitt), None)
                if kontext and "mcp__" not in zeile:
                    # Nur werkzeugartige Namen (Muster aus der Referenz), sonst waere
                    # jeder Konfig-Schluessel wie `api_version` ein Befund.
                    muster = re.compile(server[kontext]["werkzeug_muster"])
                    for werkzeug in nackt.findall(zeile):
                        if muster.match(werkzeug) and werkzeug not in server[kontext]["werkzeuge"]:
                            self.melde("H11", rel, nr, "MCP-Werkzeug `%s` gibt es bei %s@%s nicht"
                                       % (werkzeug, kontext, server[kontext]["version"]))
                for name in sorted(set(agent.findall(zeile))):
                    if name not in self.agenten_namen and name not in self.ref["externe_agenten"]:
                        self.melde("H16", rel, nr, "Verweis auf Agent `%s` — gibt es nicht" % name)
                for name in slash.findall(zeile):
                    if ":" not in name and name not in self.skills and name not in extern:
                        self.melde("H13", rel, nr, "Verweis auf `/%s` — kein solcher Skill" % name)

    # --- Online-Pruefungen ------------------------------------------------

    def online(self):
        if self.schema_datei:
            self.schema()  # lokales Schema braucht kein Netz
        if self.offline:
            self.uebersprungen.append("plugin validate%s (--offline)"
                                      % ("" if self.schema_datei else " und Schema-Validierung"))
            return
        if not self.schema_datei:
            self.schema()
        self.plugin_validate()

    def schema(self):
        rel = ".claude/settings.json"
        try:
            import jsonschema
        except ImportError:
            self.uebersprungen.append("Schema-Validierung: Paket jsonschema fehlt")
            return
        import urllib.request
        url = self.ref["quellen"]["settings_schema"]
        if self.schema_datei:
            with open(self.schema_datei, encoding="utf-8") as fh:
                self.validiere(json.load(fh), jsonschema)
            return
        try:
            with urllib.request.urlopen(url, timeout=15) as resp:
                schema = json.load(resp)
        except Exception as e:
            # macOS-Pythons ohne Zertifikatsspeicher scheitern an TLS — curl nutzt
            # den System-Speicher. Bleibt auch das erfolglos: Netz ist kein Befund.
            res = subprocess.run(["curl", "-sfL", "--max-time", "15", url],
                                 capture_output=True, text=True) if shutil.which("curl") else None
            if not res or res.returncode != 0:
                self.uebersprungen.append("Schema-Validierung: %s nicht ladbar (%s)" % (url, e))
                return
            schema = json.loads(res.stdout)
        self.validiere(schema, jsonschema)

    def validiere(self, schema, jsonschema):
        """settings.json gegen das Schema — ohne Felder, die das Schema nachweislich noch nicht kennt.

        SchemaStore hinkt Claude Code hinterher (z. B. `onFailure`, seit 2.1.295). Solche Felder stehen
        mit Version und Datum in `schema_luecken` der Referenz und werden vor der Pruefung entfernt.
        """
        rel = ".claude/settings.json"
        data = self.lade_json(rel)
        validator = jsonschema.validators.validator_for(schema)(schema)
        luecken = {l["feld"]: l for l in self.ref.get("schema_luecken", [])}

        def ohne(wert):
            if isinstance(wert, dict):
                return {k: ohne(v) for k, v in wert.items() if k not in luecken}
            if isinstance(wert, list):
                return [ohne(v) for v in wert]
            return wert

        if luecken:
            if not list(validator.iter_errors(data)):
                for feld in luecken:
                    self.uebersprungen.append("Schema-Luecke `%s` ist geschlossen — Eintrag aus "
                                              "schema_luecken entfernen" % feld)
            else:
                for feld, l in luecken.items():
                    self.uebersprungen.append("Schema kennt `%s` noch nicht (Claude Code %s, vermerkt %s) — "
                                              "vor der Validierung ausgenommen" % (feld, l["seit"], l["vermerkt"]))
            data = ohne(data)
        for fehler in validator.iter_errors(data):
            ort = "/".join(str(p) for p in fehler.path) or "(Wurzel)"
            self.melde("H15", rel, 1, "Schema: %s — %s" % (ort, fehler.message[:200]))

    def plugin_validate(self):
        claude = shutil.which("claude")
        if not claude:
            self.uebersprungen.append("plugin validate: claude-CLI nicht im PATH")
            return
        res = subprocess.run([claude, "plugin", "validate", self.pfad(".claude"), "--strict"],
                             capture_output=True, text=True, timeout=120)
        if res.returncode == 1:
            ausgabe = (res.stdout + res.stderr).strip().splitlines()
            self.melde("H14", ".claude", 0, "claude plugin validate --strict: " + " | ".join(ausgabe[-5:]))
        elif res.returncode != 0:
            self.uebersprungen.append("plugin validate: Validator-Fehler (Exit %d)" % res.returncode)

    # --- Ablauf -----------------------------------------------------------

    def lauf(self):
        self.skills_pruefen()  # zuerst: verweise() braucht Skill- und Agenten-Namen
        self.agenten()
        self.rules()
        self.versionen()
        self.settings()
        self.waechter()
        self.readme_modelle()
        self.hook_skripte()
        self.mcp_json()
        self.verweise()
        self.online()
        self.befunde.sort(key=lambda b: (b["datei"], b["zeile"], b["code"]))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    ap.add_argument("--offline", action="store_true", help="ohne Netz und ohne claude-CLI")
    ap.add_argument("--json", action="store_true", help="Ausgabe als JSON")
    ap.add_argument("--schema", help="Settings-Schema aus lokaler Datei statt SchemaStore (Tests)")
    args = ap.parse_args()

    try:
        p = Pruefung(os.path.abspath(args.root), args.offline, args.schema)
        p.lauf()
    except Defekt as e:
        print("harness-check: %s" % e, file=sys.stderr)
        return DEFEKT

    if args.json:
        print(json.dumps({"befunde": p.befunde, "uebersprungen": p.uebersprungen},
                         ensure_ascii=False, indent=2))
    else:
        for b in p.befunde:
            print("%s %s:%d — %s" % (b["code"], b["datei"], b["zeile"], b["text"]))
        for u in p.uebersprungen:
            print("   uebersprungen: %s" % u)
        print("%d Befund(e)" % len(p.befunde) if p.befunde else "Harness sauber")
    return BEFUND if p.befunde else 0


if __name__ == "__main__":
    sys.exit(main())
