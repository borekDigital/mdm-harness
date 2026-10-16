#!/usr/bin/env python3
"""Tests fuer bin/befehl.py und die Bash-Regeln von bauplan-guard und git-safety.

Spec: .claude/specs/harness/bauplan-guard-fehlalarme.md
Aufruf: python3 -m unittest bin/test_befehl.py
"""

import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

BIN = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BIN)
import befehl  # noqa: E402


def lade(name, datei):
    spec = importlib.util.spec_from_file_location(name, os.path.join(BIN, datei))
    modul = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modul)
    return modul


guard = lade("bauplan_guard", "bauplan-guard.py")
safety = lade("git_safety", "git-safety.py")


def woerter(cmd):
    return [b.woerter for b in befehl.zerlege(cmd)]


class ParserTest(unittest.TestCase):

    def test_trennzeichen(self):
        self.assertEqual(woerter("a x; b && c || d | e & f"),
                         [["a", "x"], ["b"], ["c"], ["d"], ["e"], ["f"]])

    def test_zeilenumbruch_trennt(self):
        self.assertEqual(woerter("a\nb"), [["a"], ["b"]])

    def test_zeilenfortsetzung(self):
        self.assertEqual(woerter("rm \\\n  datei"), [["rm", "datei"]])

    def test_string_bleibt_ein_wort(self):
        self.assertEqual(woerter('git commit -m "git push --force"'),
                         [["git", "commit", "-m", "git push --force"]])

    def test_heredoc_ist_kein_befehl(self):
        cmd = "cat <<'EOF' > f.txt\nrm docs/bauplan/x\nEOF\nls"
        self.assertEqual(woerter(cmd), [["cat"], ["ls"]])
        self.assertEqual(befehl.zerlege(cmd)[0].umleitungen, [(">", "f.txt")])

    def test_heredoc_mit_bindestrich_und_ohne_anfuehrung(self):
        self.assertEqual(woerter("python3 - <<-PY\n\topen('workspace.yaml')\n\tPY\necho ok"),
                         [["python3", "-"], ["echo", "ok"]])

    def test_umleitungen(self):
        b = befehl.zerlege("grep x workspace.yaml 2>/dev/null >> log.txt 2>&1")[0]
        self.assertEqual(b.woerter, ["grep", "x", "workspace.yaml"])
        self.assertEqual(b.umleitungen, [(">>", "log.txt")])  # /dev/null und 2>&1 zaehlen nicht

    def test_befehlsersetzung_wird_mitgeprueft(self):
        self.assertIn(["rm", "-rf", "docs/bauplan"], woerter("echo $(rm -rf docs/bauplan)"))
        self.assertIn(["rm", "x"], woerter("echo `rm x`"))

    def test_bash_c_und_eval_werden_mitgeprueft(self):
        self.assertIn(["rm", "docs/bauplan/x"], woerter('bash -c "rm docs/bauplan/x"'))
        self.assertIn(["rm", "y"], woerter("eval 'rm y'"))

    def test_cd_wird_verfolgt(self):
        b = befehl.zerlege("cd docs && rm -rf bauplan")[1]
        self.assertEqual((b.woerter, b.cwd), (["rm", "-rf", "bauplan"], "docs"))

    def test_umgebung_und_wrapper_entfernt(self):
        self.assertEqual(woerter("FOO=1 sudo env -i nice rm x"), [["rm", "x"]])

    def test_offenes_anfuehrungszeichen(self):
        with self.assertRaises(ValueError):
            befehl.zerlege('rm "docs/bauplan')


class BauplanGuardTest(unittest.TestCase):

    def setUp(self):
        # Wegwerf-Projekt mit Git, damit stash/checkout/restore pruefbar sind.
        self.p = tempfile.mkdtemp(prefix="guard-")
        for rel in ("docs/bauplan/index.html", ".claude/bauplan/theme-mdm.manifest.json", "workspace.yaml",
                    "README.md"):
            os.makedirs(os.path.join(self.p, os.path.dirname(rel) or "."), exist_ok=True)
            with open(os.path.join(self.p, rel), "w") as fh:
                fh.write("x\n")
        g = ["git", "-C", self.p, "-c", "user.email=t@e", "-c", "user.name=t"]
        subprocess.run(g[:3] + ["init", "-q"], check=True)
        subprocess.run(g + ["add", "-A"], check=True)
        subprocess.run(g + ["commit", "-qm", "init"], check=True)

    def tearDown(self):
        shutil.rmtree(self.p)

    def aendere(self, rel):
        with open(os.path.join(self.p, rel), "a") as fh:
            fh.write("lokal\n")

    def blockiert(self, cmd):
        return bool(guard.check_bash(self.p, cmd))

    def test_muss_blockieren(self):
        for cmd in ["rm docs/bauplan/x.html", "mv workspace.yaml w.bak", "mv a.txt workspace.yaml",
                    "echo x > .claude/bauplan/theme-mdm.manifest.json", "git rm -r docs/bauplan",
                    "rm -rf docs", "rm -rf .", "rm -rf .claude", "cd docs && rm -rf bauplan",
                    "truncate -s0 workspace.yaml", "echo $(rm docs/bauplan/x)",
                    'bash -c "rm -rf docs/bauplan"', "find docs/bauplan -delete",
                    "find docs -name '*.html' -exec rm {} \\;", "ls docs/bauplan | xargs rm",
                    "rm docs/bauplan/*.html", "rm " + os.path.join(self.p, "workspace.yaml")]:
            with self.subTest(cmd=cmd):
                self.assertTrue(self.blockiert(cmd))

    def test_darf_nicht_blockieren(self):
        for cmd in ["grep -n tech workspace.yaml 2>/dev/null", "cat docs/bauplan/index.html | head",
                    "git pull -q 2>/dev/null; grep -n 'tech: \"PHP' workspace.yaml",
                    "python3 - <<'PY'\nopen('x.txt', 'w').write('workspace.yaml')\nPY",
                    'git commit -m "rm docs/bauplan, workspace.yaml > x"', "rm -rf /tmp/x",
                    "rm build/out.txt", "echo hi > /tmp/notes.txt 2>&1", "ls docs/bauplan",
                    "git diff --stat docs/bauplan/index.html"]:
            with self.subTest(cmd=cmd):
                self.assertFalse(self.blockiert(cmd))

    def test_stash_checkout_restore_nur_bei_lokalen_aenderungen(self):
        for cmd in ["git stash", "git stash push -- docs", "git checkout -- docs/bauplan",
                    "git restore docs", "git checkout .", "git restore --staged --worktree ."]:
            with self.subTest(sauber=cmd):
                self.assertFalse(self.blockiert(cmd))
        self.aendere("docs/bauplan/index.html")
        for cmd in ["git stash", "git stash push -u -m x -- docs", "git checkout -- docs/bauplan",
                    "git restore docs", "git checkout .", "git restore --worktree ."]:
            with self.subTest(geaendert=cmd):
                self.assertTrue(self.blockiert(cmd))
        for cmd in ["git stash push -- README.md", "git restore README.md", "git checkout main"]:
            with self.subTest(fremd=cmd):
                self.assertFalse(self.blockiert(cmd))

    def test_nicht_zerlegbar_mit_bestand_blockiert(self):
        self.assertTrue(self.blockiert('rm "docs/bauplan'))

    def test_nicht_zerlegbar_ohne_bestand_laeuft(self):
        self.assertFalse(self.blockiert('echo "offen'))


class GitSafetyTest(unittest.TestCase):

    def test_muss_blockieren(self):
        for cmd in ["git push --force origin x", "git push -f", "git push --force-with-lease",
                    "git push origin main", "git push origin HEAD:main", "git push origin master",
                    "git reset --hard HEAD~1", "git clean -fd", "git clean --force",
                    "git push latori x", "git -C d push --force", "git -c a=b push origin main",
                    "git --git-dir=.git --work-tree=. clean -fd", 'git -C "a b" reset --hard',
                    "shopify theme publish --theme 1", "shopify theme delete -t 2",
                    "shopify theme push --live", "shopify theme push -l", "shopify theme push --allow-live",
                    "shopify theme dev --theme-editor-sync", "cd themes/mdm && shopify theme push --live",
                    'bash -c "git push --force"', "npx shopify theme publish"]:
            with self.subTest(cmd=cmd):
                self.assertIsNotNone(safety.pruefe(cmd))

    def test_darf_nicht_blockieren(self):
        for cmd in ["git status", 'git commit -m "git push --force"', "git commit -F msg.txt",
                    "git push -u origin harness/x", "git push origin feature/main-menu",
                    'echo "git reset --hard"', "git log --grep=main", "git checkout main",
                    "shopify theme push --unpublished", "gh pr edit 1 --body-file b.md",
                    "cat <<'EOF'\ngit push --force\nEOF", "git -C connector status"]:
            with self.subTest(cmd=cmd):
                self.assertIsNone(safety.pruefe(cmd))

    def test_nicht_zerlegbar_blockiert(self):
        self.assertIsNotNone(safety.pruefe('git push "origin'))


if __name__ == "__main__":
    unittest.main()
