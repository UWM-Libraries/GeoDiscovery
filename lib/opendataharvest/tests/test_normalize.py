import subprocess
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT / "lib/opendataharvest/src"))
sys.path.insert(0, str(REPO_ROOT / "lib/opendataharvest/src/opendataharvest"))

from opendataharvest.normalize import TitleTransliterationNormalizer


class TitleTransliterationNormalizerTest(unittest.TestCase):
    def setUp(self):
        TitleTransliterationNormalizer._cache = {}
        TitleTransliterationNormalizer._disabled = False

    def test_transient_uconv_failure_does_not_disable_later_transliteration(self):
        title = "北京市城区街道图"

        with patch(
            "opendataharvest.normalize.subprocess.run",
            side_effect=[
                subprocess.SubprocessError("temporary uconv failure"),
                SimpleNamespace(stdout="Bei Jing Shi Cheng Qu Jie Dao Tu\n"),
            ],
        ):
            # A transient subprocess failure should not disable future attempts.
            self.assertIsNone(TitleTransliterationNormalizer.transliterate(title))
            self.assertFalse(TitleTransliterationNormalizer._disabled)

            self.assertEqual(
                TitleTransliterationNormalizer.transliterate(title),
                "Bei Jing Shi Cheng Qu Jie Dao Tu",
            )


if __name__ == "__main__":
    unittest.main()
