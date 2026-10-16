#!/usr/bin/env python3
"""Tests fuer bin/harness-check.py.

Jeder Test baut einen kleinen, sauberen Harness in einem Temp-Verzeichnis,
baut genau einen Fehler ein und erwartet genau diesen Befund. Das Skript wird
als Prozess aufgerufen — so wie Hook und CI es aufrufen.

Aufruf: python3 -m unittest bin/test_harness_check.py
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

BIN = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(BIN, "harness-check.py")
REFERENZ = os.path.join(BIN, "harness-referenz.json")
REPO = os.path.dirname(BIN)

AGENT = """---
name: theme-reviewer
description: "Read-only QA reviewer."
model: sonnet
---

# theme-reviewer
"""

SKILL = """---
name: mdm-block
description: "Per-Block-Workflow."
argument-hint: "[block-name]"
---

# /mdm-block
"""

RULE = """---
paths:
  - "themes/*/sections/**"
---

# Liquid
"""

HOOK = """#!/usr/bin/env bash
README="${CLAUDE_PROJECT_DIR}/.claude/README.md"
exit 0
"""


def settings(**extra):
    data = {
        "$schema": "https://json.schemastore.org/claude-code-settings.json",
        "model": "opus",
        "permissions": {"allow": ["mcp__shopify-dev-mcp__validate_theme"]},
        "hooks": {
            "Stop": [{"hooks": [{
                "type": "command",
                "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/stop-notify.sh\"",
            }]}]
        },
    }
    data.update(extra)
    return json.dumps(data, indent=2)


MCP = json.dumps({"mcpServers": {"shopify-dev-mcp": {
    "command": "npx", "args": ["-y", "@shopify/dev-mcp@1.16.1"]}}}, indent=2)


class HarnessCheckTest(unittest.TestCase):

    def setUp(self):
        self.root = tempfile.mkdtemp(prefix="harness-check-")
        self.write(".claude/agents/theme-reviewer.md", AGENT)
        self.write(".claude/skills/mdm-block/SKILL.md", SKILL)
        self.write(".claude/rules/liquid-conventions.md", RULE)
        self.write(".claude/hooks/stop-notify.sh", HOOK)
        self.write(".claude/README.md", "# Harness\n\nAufruf: `/mdm-block` und `/loop`.\n")
        self.write(".claude/settings.json", settings())
        self.write(".mcp.json", MCP)
        self.write("themes/mdm/sections/mdm-breadcrumbs.liquid", "{{ 'x' }}\n")
        with open(REFERENZ, encoding="utf-8") as fh:
            self.write("bin/harness-referenz.json", fh.read())

    def tearDown(self):
        shutil.rmtree(self.root)

    def write(self, rel, text):
        path = os.path.join(self.root, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(text)

    def run_check(self, *args):
        return subprocess.run(
            [sys.executable, SCRIPT, "--root", self.root, "--offline", "--json", *args],
            capture_output=True, text=True)

    def befunde(self):
        res = self.run_check()
        self.assertIn(res.returncode, (0, 3), res.stderr)
        return res.returncode, json.loads(res.stdout)["befunde"]

    def assert_befund(self, code, datei, zeile=None, text=None):
        rc, befunde = self.befunde()
        self.assertEqual(rc, 3, "Befund %s erwartet, Lauf war sauber" % code)
        treffer = [b for b in befunde if b["code"] == code and b["datei"] == datei]
        self.assertTrue(treffer, "kein %s in %s, gefunden: %s" % (code, datei, befunde))
        if zeile is not None:
            self.assertIn(zeile, [b["zeile"] for b in treffer])
        if text is not None:
            self.assertTrue(any(text in b["text"] for b in treffer), treffer)
        self.assertEqual({b["code"] for b in befunde}, {code}, befunde)

    # --- sauberer Stand ---------------------------------------------------

    def test_sauberer_harness_endet_mit_0(self):
        rc, befunde = self.befunde()
        self.assertEqual((rc, befunde), (0, []))

    def test_textausgabe_nennt_datei_und_zeile(self):
        self.write(".claude/agents/theme-reviewer.md", AGENT.replace("model:", "modle:"))
        res = subprocess.run([sys.executable, SCRIPT, "--root", self.root, "--offline"],
                             capture_output=True, text=True)
        self.assertEqual(res.returncode, 3)
        self.assertIn(".claude/agents/theme-reviewer.md:4", res.stdout)

    # --- Agenten ----------------------------------------------------------

    def test_unbekanntes_agentenfeld(self):
        # Akzeptanzkriterium der Spec: Tippfehler mit Datei und Zeile.
        self.write(".claude/agents/theme-reviewer.md", AGENT.replace("model:", "modle:"))
        self.assert_befund("H02", ".claude/agents/theme-reviewer.md", 4, "modle")

    def test_agent_ohne_description(self):
        self.write(".claude/agents/theme-reviewer.md",
                   AGENT.replace('description: "Read-only QA reviewer."\n', ""))
        self.assert_befund("H01", ".claude/agents/theme-reviewer.md", text="description")

    def test_ungueltiges_modell(self):
        self.write(".claude/agents/theme-reviewer.md", AGENT.replace("sonnet", "sonet"))
        self.assert_befund("H03", ".claude/agents/theme-reviewer.md", 4, "sonet")

    def test_modell_id_und_inherit_sind_gueltig(self):
        self.write(".claude/agents/a-planner.md",
                   AGENT.replace("theme-reviewer", "a-planner").replace("sonnet", "claude-opus-5-5"))
        self.write(".claude/agents/b-planner.md",
                   AGENT.replace("theme-reviewer", "b-planner").replace("sonnet", "inherit"))
        self.assertEqual(self.befunde(), (0, []))

    # --- Skills -----------------------------------------------------------

    def test_unbekanntes_skillfeld(self):
        self.write(".claude/skills/mdm-block/SKILL.md",
                   SKILL.replace("argument-hint", "user_invocable: true\nargument-hint"))
        self.assert_befund("H04", ".claude/skills/mdm-block/SKILL.md", 4, "user_invocable")

    def test_verweis_auf_fehlenden_skill(self):
        self.write(".claude/README.md", "Aufruf: `/mdm-blok`.\n")
        self.assert_befund("H13", ".claude/README.md", 1, "/mdm-blok")

    def test_verweis_auf_fehlenden_agenten(self):
        self.write(".claude/skills/mdm-block/SKILL.md",
                   SKILL + "\nDanach theme-reviewer und security-reviewer parallel starten.\n")
        self.assert_befund("H16", ".claude/skills/mdm-block/SKILL.md", 9, "security-reviewer")

    def test_codepfad_mit_slash_ist_kein_skillverweis(self):
        self.write(".claude/README.md", "In `custom_liquid`/handgeschriebenem HTML.\n")
        self.assertEqual(self.befunde(), (0, []))

    # --- Rules ------------------------------------------------------------

    def test_unbekanntes_rulefeld(self):
        self.write(".claude/rules/liquid-conventions.md", RULE.replace("paths:", "globs:"))
        self.assert_befund("H05", ".claude/rules/liquid-conventions.md", 2, "globs")

    def test_rule_glob_ohne_treffer(self):
        self.write(".claude/rules/liquid-conventions.md",
                   RULE.replace("themes/*/sections/**", "themes/*/sectons/**"))
        self.assert_befund("H06", ".claude/rules/liquid-conventions.md", 3, "sectons")

    def test_rule_glob_fuer_fehlendes_repo_ist_kein_befund(self):
        # In der CI fehlen Kind-Repos, die nicht geklont werden konnten.
        self.write(".claude/rules/connector.md", RULE.replace("themes/*/sections/**", "connector/app/**"))
        self.assertEqual(self.befunde(), (0, []))

    def test_rule_glob_auf_leeren_platzhalter_ist_kein_befund(self):
        # connector-worktrees/* ist leer, solange kein Worktree aktiv ist.
        os.makedirs(os.path.join(self.root, "connector-worktrees"))
        self.write(".claude/rules/connector.md",
                   RULE.replace("themes/*/sections/**", "connector-worktrees/*/app/**"))
        self.assertEqual(self.befunde(), (0, []))

    # --- Settings und Hooks -----------------------------------------------

    def test_settings_ohne_schema(self):
        data = json.loads(settings())
        del data["$schema"]
        self.write(".claude/settings.json", json.dumps(data, indent=2))
        self.assert_befund("H07", ".claude/settings.json", text="$schema")

    def test_pfadregel_fuer_write_greift_nie(self):
        # permissions.md: Pfadregeln prueft Claude Code nur fuer Edit und Read.
        self.write(".claude/settings.json", settings(permissions={
            "allow": [], "deny": ["Edit(themes/*/config/settings_data.json)",
                                  "Write(themes/*/config/settings_data.json)"]}))
        self.assert_befund("H17", ".claude/settings.json", text="Write(themes/*/config/settings_data.json)")

    def test_unbekanntes_hook_event(self):
        data = json.loads(settings())
        data["hooks"]["OnStop"] = data["hooks"].pop("Stop")
        self.write(".claude/settings.json", json.dumps(data, indent=2))
        self.assert_befund("H08", ".claude/settings.json", text="OnStop")

    def test_hook_skript_fehlt(self):
        os.remove(os.path.join(self.root, ".claude/hooks/stop-notify.sh"))
        self.assert_befund("H09", ".claude/settings.json", text="stop-notify.sh")

    def test_hook_prueft_gegen_fehlende_datei(self):
        # Befund #9 der Spec: harness-app/data.json war seit Wochen weg.
        self.write(".claude/hooks/stop-notify.sh",
                   HOOK + 'DATA_JSON="${CLAUDE_PROJECT_DIR}/harness-app/data.json"\n')
        self.assert_befund("H10", ".claude/hooks/stop-notify.sh", 4, "harness-app/data.json")

    # --- MCP --------------------------------------------------------------

    def test_unbekanntes_mcp_werkzeug_in_settings(self):
        # Befund #3 der Spec.
        self.write(".claude/settings.json", settings(permissions={"allow": [
            "mcp__shopify-dev-mcp__validate_theme_codeblocks"]}))
        self.assert_befund("H11", ".claude/settings.json", text="validate_theme_codeblocks")

    def test_unbekanntes_mcp_werkzeug_im_agenten(self):
        self.write(".claude/agents/theme-reviewer.md",
                   AGENT + "\n2. `validate_theme_codeblocks` (Dev MCP) on new Liquid.\n")
        self.assert_befund("H11", ".claude/agents/theme-reviewer.md", 9, "validate_theme_codeblocks")

    def test_unbekannter_server_wird_nicht_geprueft(self):
        self.write(".claude/README.md", "`mcp__claude_ai_Figma__get_screenshot`\n")
        self.assertEqual(self.befunde(), (0, []))

    def test_mcp_ohne_feste_version(self):
        # Befund #4 der Spec.
        self.write(".mcp.json", MCP.replace("@1.16.1", "@latest"))
        self.assert_befund("H12", ".mcp.json", text="@latest")

    def test_mcp_version_weicht_von_referenz_ab(self):
        self.write(".mcp.json", MCP.replace("@1.16.1", "@1.17.0"))
        self.assert_befund("H12", ".mcp.json", text="1.17.0")

    # --- Exit-Codes -------------------------------------------------------

    def test_defekt_endet_weder_mit_0_noch_3(self):
        self.write(".claude/settings.json", "{ kaputt")
        res = self.run_check()
        self.assertNotIn(res.returncode, (0, 3))
        self.assertIn("settings.json", res.stderr)


class EchterBestandTest(unittest.TestCase):

    def test_workspace_ist_sauber(self):
        # Nach Teil B der Spec muss der echte Bestand ohne Befund durchlaufen.
        res = subprocess.run([sys.executable, SCRIPT, "--root", REPO, "--offline"],
                             capture_output=True, text=True)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)


if __name__ == "__main__":
    unittest.main()
