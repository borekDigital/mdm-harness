#!/usr/bin/env python3
"""Tests fuer bin/harness-stand.py (Versions-Waechter und Changelog-Abgleich).

Aufruf: python3 -m unittest bin/test_harness_stand.py
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

BIN = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(BIN, "harness-stand.py")

CHANGELOG = """# Changelog

## 2.1.303

- Added `newField` to subagent frontmatter

## 2.1.302

- Removed the `oldHook` event

## 2.1.301

- Fixed something old
"""

REFERENZ = {
    "stand": "16. Oktober 2026",
    "claude_code_version": "2.1.301",
    "quellen": {"changelog": "https://code.claude.com/docs/en/changelog.md"},
    "agent_felder": ["name"],
}


class HarnessStandTest(unittest.TestCase):

    def setUp(self):
        self.root = tempfile.mkdtemp(prefix="harness-stand-")
        os.makedirs(os.path.join(self.root, "bin"))
        self.referenz = os.path.join(self.root, "bin", "harness-referenz.json")
        with open(self.referenz, "w", encoding="utf-8") as fh:
            json.dump(REFERENZ, fh, indent=2)
        self.changelog = os.path.join(self.root, "CHANGELOG.md")
        with open(self.changelog, "w", encoding="utf-8") as fh:
            fh.write(CHANGELOG)

    def tearDown(self):
        shutil.rmtree(self.root)

    def run_stand(self, *args):
        return subprocess.run([sys.executable, SCRIPT, "--root", self.root, *args],
                              capture_output=True, text=True)

    # --- Versions-Waechter (SessionStart) ---------------------------------

    def test_hinweis_bei_neuerer_version(self):
        res = self.run_stand("hinweis", "--installiert", "2.1.303")
        self.assertEqual(res.returncode, 0, res.stderr)
        out = json.loads(res.stdout)
        text = out["systemMessage"]
        self.assertIn("2.1.301", text)
        self.assertIn("2.1.303", text)
        self.assertIn("https://code.claude.com/docs/en/changelog.md", text)
        ctx = out["hookSpecificOutput"]
        self.assertEqual(ctx["hookEventName"], "SessionStart")
        self.assertIn("2.1.303", ctx["additionalContext"])

    def test_still_bei_gleicher_version(self):
        res = self.run_stand("hinweis", "--installiert", "2.1.301")
        self.assertEqual((res.returncode, res.stdout), (0, ""))

    def test_still_bei_aelterer_version(self):
        res = self.run_stand("hinweis", "--installiert", "2.1.80")
        self.assertEqual((res.returncode, res.stdout), (0, ""))

    def test_versionen_werden_numerisch_verglichen(self):
        # 2.1.80 ist aelter als 2.1.301, obwohl "80" > "301" als Text.
        res = self.run_stand("hinweis", "--installiert", "2.1.1000")
        self.assertIn("2.1.1000", res.stdout)

    def test_unlesbare_version_bleibt_still(self):
        # Der Hook darf eine Sitzung nie stoeren.
        res = self.run_stand("hinweis", "--installiert", "unbekannt")
        self.assertEqual((res.returncode, res.stdout), (0, ""))

    # --- Changelog --------------------------------------------------------

    def test_changelog_seit_gepruefter_version(self):
        res = self.run_stand("changelog", "--datei", self.changelog)
        self.assertEqual(res.returncode, 3, res.stderr)
        self.assertIn("## 2.1.303", res.stdout)
        self.assertIn("## 2.1.302", res.stdout)
        self.assertNotIn("2.1.301", res.stdout)

    def test_changelog_seit_explizit(self):
        res = self.run_stand("changelog", "--datei", self.changelog, "--seit", "2.1.302")
        self.assertEqual(res.returncode, 3)
        self.assertIn("## 2.1.303", res.stdout)
        self.assertNotIn("## 2.1.302", res.stdout)

    def test_changelog_ohne_neue_eintraege(self):
        res = self.run_stand("changelog", "--datei", self.changelog, "--seit", "2.1.303")
        self.assertEqual((res.returncode, res.stdout), (0, ""))

    def test_neueste_version(self):
        res = self.run_stand("neueste", "--datei", self.changelog)
        self.assertEqual((res.returncode, res.stdout.strip()), (0, "2.1.303"))

    def test_changelog_ohne_versionen_ist_defekt(self):
        with open(self.changelog, "w", encoding="utf-8") as fh:
            fh.write("<html>Rate limit</html>\n")
        res = self.run_stand("changelog", "--datei", self.changelog)
        self.assertNotIn(res.returncode, (0, 3))
        self.assertIn("keine Versionen", res.stderr)

    # --- Anheben ----------------------------------------------------------

    def test_anheben_setzt_version_und_datum(self):
        res = self.run_stand("anheben", "--version", "2.1.303", "--datum", "23. Oktober 2026")
        self.assertEqual(res.returncode, 0, res.stderr)
        with open(self.referenz, encoding="utf-8") as fh:
            ref = json.load(fh)
        self.assertEqual(ref["claude_code_version"], "2.1.303")
        self.assertEqual(ref["stand"], "23. Oktober 2026")
        self.assertEqual(ref["agent_felder"], ["name"])  # Rest unveraendert

    def test_anheben_aendert_nur_version_und_stand(self):
        # Lauf 38873502082: json.dump zerlegte jede Liste — +130/-25 Zeilen fuer zwei Werte.
        text = (
            '{\n'
            '  "stand": "16. Oktober 2026",\n'
            '  "claude_code_version": "2.1.301",\n'
            '  "quellen": {"changelog": "https://code.claude.com/docs/en/changelog.md"},\n'
            '  "agent_felder": ["name", "description",\n'
            '    "tools"]\n'
            '}\n')
        with open(self.referenz, "w", encoding="utf-8") as fh:
            fh.write(text)
        res = self.run_stand("anheben", "--version", "2.1.303", "--datum", "23. Oktober 2026")
        self.assertEqual(res.returncode, 0, res.stderr)
        with open(self.referenz, encoding="utf-8") as fh:
            neu = fh.read()
        self.assertEqual(neu, text.replace("16. Oktober 2026", "23. Oktober 2026")
                                  .replace('"2.1.301"', '"2.1.303"'))

    def test_anheben_nie_rueckwaerts(self):
        res = self.run_stand("anheben", "--version", "2.1.80")
        self.assertNotEqual(res.returncode, 0)
        with open(self.referenz, encoding="utf-8") as fh:
            self.assertEqual(json.load(fh)["claude_code_version"], "2.1.301")

    # --- Prompt fuer den Abgleich -----------------------------------------

    def test_prompt_enthaelt_changelog_und_befunde(self):
        befunde = os.path.join(self.root, "check.txt")
        with open(befunde, "w", encoding="utf-8") as fh:
            fh.write("H02 .claude/agents/x.md:4 — unbekanntes Agenten-Feld\n")
        res = self.run_stand("prompt", "--datei", self.changelog, "--check", befunde)
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertIn("Added `newField`", res.stdout)
        self.assertIn("H02 .claude/agents/x.md:4", res.stdout)
        self.assertIn("2.1.301", res.stdout)
        self.assertIn("bin/harness-referenz.json", res.stdout)


if __name__ == "__main__":
    unittest.main()
