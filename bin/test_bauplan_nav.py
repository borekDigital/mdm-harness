#!/usr/bin/env python3
"""Tests fuer bin/bauplan-nav.py --check (Fusszeilen-Navigation pruefen, ohne zu schreiben).

Spec: .claude/specs/harness/bauplan-index-lokal-sauber.md, Teil B.
Aufruf: python3 -m unittest bin/test_bauplan_nav.py
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

BIN = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(BIN, "bauplan-nav.py")

BLATT = """<div class="sheet">
  <footer>
    <span>Etappe %d von 2</span>
    %s
  </footer>
</div>
"""


class BauplanNavCheckTest(unittest.TestCase):

    def setUp(self):
        self.project = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.project)
        self.write(".claude/bauplan/alpha.manifest.json", json.dumps({"etappen": [
            {"nr": 1, "title": "Umfang", "url": "https://claude.ai/artifact/a1"},
            {"nr": 2, "title": "Aufbau", "url": "https://claude.ai/artifact/a2"},
        ]}))
        self.write("docs/bauplan/alpha/etappe-01.html",
                   BLATT % (1, "<span>Als nächstes: Aufbau</span>"))
        self.write("docs/bauplan/alpha/etappe-02.html",
                   BLATT % (2, "<span>Ende des Blattsatzes</span>"))

    def write(self, rel, text):
        path = os.path.join(self.project, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(text)

    def blaetter(self):
        out = {}
        for nr in (1, 2):
            with open(os.path.join(self.project, "docs/bauplan/alpha/etappe-%02d.html" % nr),
                      encoding="utf-8") as fh:
                out[nr] = fh.read()
        return out

    def run_nav(self, *args):
        env = dict(os.environ)
        env.pop("CLAUDE_PROJECT_DIR", None)
        return subprocess.run([sys.executable, SCRIPT, "--project", self.project, *args],
                              capture_output=True, text=True, env=env)

    def test_check_unverlinkt_ergibt_3_und_schreibt_nicht(self):
        vorher = self.blaetter()
        res = self.run_nav("--check")
        self.assertEqual(res.returncode, 3, res.stdout + res.stderr)
        self.assertIn("bin/bauplan-nav.py", res.stdout + res.stderr)
        self.assertEqual(self.blaetter(), vorher)

    def test_check_nach_lauf_ergibt_0(self):
        self.assertEqual(self.run_nav().returncode, 0)
        nachher = self.blaetter()
        res = self.run_nav("--check")
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertEqual(self.blaetter(), nachher)

    def test_dry_run_bleibt_exit_0(self):
        self.assertEqual(self.run_nav("--dry-run").returncode, 0)


if __name__ == "__main__":
    unittest.main()
