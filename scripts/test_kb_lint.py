import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LINT = ROOT / "scripts/kb-lint"
CATALOG = """| id | name | aliases | verifiability |
|---|---|---|---|
| flutter | Flutter | flutter | file |
"""
BODY = "Atom hướng dẫn lập trình viên chứng minh skill. " * 30


def write_doc(folder, name, meta, body=BODY):
    path = folder / name
    path.write_text(f"---\n{meta}\n---\n{body}\n", encoding="utf-8")
    return path


class KbLintTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.catalog = self.root / "catalog.md"
        self.catalog.write_text(CATALOG, encoding="utf-8")
        self.kb = self.root / "knowledge"
        self.docs = self.kb / "app-guide"
        self.docs.mkdir(parents=True)

    def tearDown(self):
        self.tmp.cleanup()

    def run_lint(self):
        return subprocess.run(
            ["python3", str(LINT), "--root", str(self.kb), "--catalog", str(self.catalog)],
            check=False,
            capture_output=True,
            text=True,
        )

    def meta(self, doc_id="atom-la-gi", extra=""):
        return (
            f"id: {doc_id}\ntitle: Atom\ntype: app-guide\nskills:\n  - Flutter\n"
            f"updated: 2026-10-30\nsources:\n  - name: SPEC\n    url: https://example.com/spec\n"
            f"status: reviewed\n{extra}"
        )

    def test_rule_1_missing_metadata(self):
        write_doc(self.docs, "atom-la-gi.md", "id: atom-la-gi\n")
        result = self.run_lint()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ERROR missing-metadata", result.stdout)

    def test_rule_2_unknown_skill(self):
        write_doc(self.docs, "atom-la-gi.md", self.meta().replace("  - Flutter", "  - KhongCoSkillNay"))
        result = self.run_lint()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ERROR unknown-skill", result.stdout)

    def test_rule_3_short_doc_warns(self):
        write_doc(self.docs, "atom-la-gi.md", self.meta(), body="Ngắn.")
        result = self.run_lint()
        self.assertEqual(result.returncode, 0)
        self.assertIn("WARN length", result.stdout)

    def test_rule_4_email_is_blocked(self):
        write_doc(self.docs, "atom-la-gi.md", self.meta(), body=BODY + " Liên hệ a@b.com.")
        result = self.run_lint()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ERROR secret", result.stdout)

    def test_rule_5_old_date_warns(self):
        write_doc(self.docs, "atom-la-gi.md", self.meta().replace("2026-10-30", "2020-01-01"))
        result = self.run_lint()
        self.assertEqual(result.returncode, 0)
        self.assertIn("WARN stale", result.stdout)

    def test_rule_6_copied_sentence_warns(self):
        sentence = "Câu này đủ dài để bị coi là trích nguyên văn giữa hai tài liệu khác nhau trong kho tri thức. "
        other = self.kb / "faq"
        other.mkdir()
        write_doc(self.docs, "atom-la-gi.md", self.meta(), body=BODY + sentence)
        write_doc(other, "cau-hoi.md", self.meta("cau-hoi").replace("type: app-guide", "type: faq"), body=BODY + sentence)
        result = self.run_lint()
        self.assertEqual(result.returncode, 0)
        self.assertIn("WARN duplicate-sentence", result.stdout)

    def test_rule_7_evidenced_threshold_is_blocked(self):
        write_doc(self.docs, "atom-la-gi.md", self.meta(), body=BODY + " Cần 5 commit để có bằng chứng.")
        result = self.run_lint()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ERROR threshold", result.stdout)


if __name__ == "__main__":
    unittest.main()
