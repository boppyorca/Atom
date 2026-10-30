import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EVAL = ROOT / "scripts/eval-chat"


class EvalChatTest(unittest.TestCase):
    def test_dry_accepts_the_repo_set(self):
        result = subprocess.run(["python3", str(EVAL), "--dry"], check=False, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("dry ok", result.stdout)

    def test_dry_rejects_a_generic_required_phrase(self):
        with tempfile.TemporaryDirectory() as tmp:
            cases = Path(tmp) / "chat.jsonl"
            empty = Path(tmp) / "independent.jsonl"
            knowledge = Path(tmp) / "knowledge"
            knowledge.mkdir()
            empty.write_text("", encoding="utf-8")
            cases.write_text(
                '{"id":"Z-1","group":"offtopic","question":"x","expected_sources":[],'
                '"must_contain_all":["không"],"must_contain_any":[],"must_not_contain":[],'
                '"expect_refusal":true,"refusal_kind":"offtopic","notes":""}\n',
                encoding="utf-8",
            )
            result = subprocess.run(
                ["python3", str(EVAL), "--dry", "--cases", str(cases), "--independent", str(empty), "--knowledge", str(knowledge)],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("quá chung", result.stdout)

    def test_independent_file_has_no_agent_questions(self):
        text = (ROOT / "eval/independent.jsonl").read_text(encoding="utf-8")
        self.assertEqual([line for line in text.splitlines() if line.strip()], [])


if __name__ == "__main__":
    unittest.main()
