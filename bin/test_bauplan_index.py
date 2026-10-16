#!/usr/bin/env python3
"""Tests fuer bin/bauplan-index.py (Uebersicht nur aus versioniertem Stand).

Spec: .claude/specs/harness/bauplan-index-lokal-sauber.md, Teil A.
Aufruf: python3 -m unittest bin/test_bauplan_index.py
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

BIN = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(BIN, "bauplan-index.py")

WORKSPACE = """repos:
  alpha:
    name: "Alpha Repo"
    tech: "Rails 8.1"
    path: "alpha/"
  gamma:
    name: "Gamma Repo"
    tech: "PHP 8.3"
    path: "gamma/"
"""

STALE = """# Veraltete Blaetter — alpha

Zuletzt verdichtet: 15. October 2026

## Etappe 1 — Umfang

- `app/models/user.rb`
"""


def manifest(generated, etappen):
    return {"repo": "x", "generated": generated, "etappen": [
        {"nr": nr, "title": "Etappe %d" % nr, "url": "https://claude.ai/artifact/x%d" % nr,
         "blaetter": 4, "findings": 2, "open_questions": []}
        for nr in etappen]}


class BauplanIndexTest(unittest.TestCase):

    def setUp(self):
        self.project = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.project)
        self.write("workspace.yaml", WORKSPACE)
        self.write(".claude/skills/repo-bauplan/assets/bauplan-head.html", "<style></style>")
        self.write(".claude/bauplan/alpha.manifest.json",
                   json.dumps(manifest("2026-09-03", [1, 2])))
        # Blattsatz ohne Repo-Eintrag, wie die Harness selbst — traegt das neueste Datum.
        self.write(".claude/bauplan/harness.manifest.json",
                   json.dumps(manifest("2026-10-15", [1])))
        self.write("docs/bauplan/alpha/etappe-01.html", "<p>eins</p>")
        self.write("docs/bauplan/harness/etappe-01.html", "<p>eins</p>")
        # alpha Etappe 2 hat absichtlich keine Quelle.
        self.index = os.path.join(self.project, "docs/bauplan/index.html")

    def write(self, rel, text):
        path = os.path.join(self.project, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(text)

    def run_index(self, *args):
        env = dict(os.environ)
        env.pop("CLAUDE_PROJECT_DIR", None)
        return subprocess.run([sys.executable, SCRIPT, "--project", self.project, *args],
                              capture_output=True, text=True, env=env)

    def read_index(self):
        with open(self.index, encoding="utf-8") as fh:
            return fh.read()

    # --- deterministisch -----------------------------------------------------

    def test_stale_bericht_aendert_die_ausgabe_nicht(self):
        self.assertEqual(self.run_index().returncode, 0)
        ohne = self.read_index()
        self.write(".claude/bauplan/alpha.STALE.md", STALE)
        self.write(".claude/bauplan/alpha.staleness.jsonl", '{"etappe": 1}\n')
        self.assertEqual(self.run_index().returncode, 0)
        self.assertEqual(self.read_index(), ohne)

    def test_keine_veraltet_marker_aber_fehlt_bleibt(self):
        # „fehlt" steht nur, wenn weder HTML-Quelle noch Artefakt-Link da ist.
        m = manifest("2026-09-03", [1, 2])
        del m["etappen"][1]["url"]
        self.write(".claude/bauplan/alpha.manifest.json", json.dumps(m))
        self.write(".claude/bauplan/alpha.STALE.md", STALE)
        self.run_index()
        html = self.read_index()
        self.assertNotIn('f-alert">veraltet', html)
        self.assertNotIn("Etappen veraltet", html)
        self.assertNotIn("sw-alert", html)  # Legenden-Eintrag entfaellt
        self.assertIn('f-alert">fehlt', html)

    def test_kopf_stand_ist_neuestes_generated(self):
        self.run_index()
        self.assertIn("<dt>Stand</dt><dd>15. Oktober 2026</dd>", self.read_index())

    def test_kopf_stand_deutsche_monatsnamen(self):
        self.write(".claude/bauplan/harness.manifest.json",
                   json.dumps(manifest("2026-03-01", [1])))
        self.run_index()
        self.assertIn("<dt>Stand</dt><dd>3. September 2026</dd>", self.read_index())
        self.write(".claude/bauplan/alpha.manifest.json",
                   json.dumps(manifest("2026-03-01", [1, 2])))
        self.run_index()
        self.assertIn("<dt>Stand</dt><dd>1. März 2026</dd>", self.read_index())

    def test_option_stand_entfaellt(self):
        res = self.run_index("--stand", "16. Oktober 2026")
        self.assertEqual(res.returncode, 2)
        self.assertFalse(os.path.exists(self.index))

    # --- --check -------------------------------------------------------------

    def test_check_gleich_ergibt_0_und_schreibt_nicht(self):
        self.run_index()
        vorher = os.stat(self.index).st_mtime_ns
        res = self.run_index("--check")
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertEqual(os.stat(self.index).st_mtime_ns, vorher)

    def test_check_abweichend_ergibt_3_und_schreibt_nicht(self):
        self.run_index()
        self.write("docs/bauplan/index.html", self.read_index() + "<!-- lokal -->")
        res = self.run_index("--check")
        self.assertEqual(res.returncode, 3)
        self.assertIn("bin/bauplan-index.py", res.stdout + res.stderr)
        self.assertTrue(self.read_index().endswith("<!-- lokal -->"))

    def test_check_ohne_datei_ergibt_3(self):
        res = self.run_index("--check")
        self.assertEqual(res.returncode, 3)
        self.assertFalse(os.path.exists(self.index))

    def test_check_nach_manifest_aenderung_ergibt_3(self):
        self.run_index()
        self.write(".claude/bauplan/alpha.manifest.json",
                   json.dumps(manifest("2026-09-03", [1, 2, 3])))
        self.assertEqual(self.run_index("--check").returncode, 3)

    # --- --veraltet ----------------------------------------------------------

    def test_veraltet_listet_repo_und_etappen_ohne_zu_schreiben(self):
        self.write(".claude/bauplan/alpha.STALE.md", STALE)
        res = self.run_index("--veraltet")
        self.assertEqual(res.returncode, 0)
        self.assertIn("alpha", res.stdout)
        self.assertIn("1", res.stdout)
        self.assertIn("/repo-bauplan alpha --refresh", res.stdout)
        self.assertNotIn("harness", res.stdout)
        self.assertFalse(os.path.exists(self.index))

    def test_veraltet_ohne_bericht_bleibt_still(self):
        res = self.run_index("--veraltet")
        self.assertEqual(res.returncode, 0)
        self.assertEqual(res.stdout.strip(), "")


if __name__ == "__main__":
    unittest.main()
