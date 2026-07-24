import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT / "lib/opendataharvest/src"))

from opendataharvest.DCAT_Harvester import Aardvark
from opendataharvest.DCAT_Harvester import AardvarkDataProcessor
from opendataharvest.DCAT_Harvester import DESCRIPTION
from opendataharvest.DCAT_Harvester import Site
from opendataharvest.DCAT_Harvester import contains_unresolved_template


class UnresolvedTemplateTest(unittest.TestCase):
    def test_detects_unresolved_arcgis_template(self):
        self.assertTrue(contains_unresolved_template("{{modified:toISO}}"))
        self.assertTrue(contains_unresolved_template("Prefix {{name}}"))
        self.assertFalse(contains_unresolved_template("2024-01-08T16:41:03.000Z"))
        self.assertFalse(contains_unresolved_template(None))

    def test_templated_date_is_treated_as_missing(self):
        record = Aardvark.__new__(Aardvark)
        record.id = "Example-placeholder"

        with self.assertNoLogs(level="WARNING"):
            self.assertIsNone(
                record._parse_index_year("{{modified:toISO}}", "modified")
            )
            self.assertIsNone(
                AardvarkDataProcessor.issue_date_parser({"issued": "{{created:toISO}}"})
            )

    def test_record_uses_safe_fallbacks_for_templated_metadata(self):
        website = Site(
            "Example",
            {
                "CreatedBy": "Example Agency",
                "Spatial": ["Wisconsin", "United States"],
                "DefaultBbox": "Wisconsin",
            },
            {},
            [],
            [],
            [],
        )
        dataset = {
            "title": "{{name}}",
            "identifier": (
                "https://www.arcgis.com/home/item.html"
                "?id=6ee1cc1bf02b4b1bbe60e0c57513b02a"
            ),
            "description": "{{description}}",
            "publisher": {"name": "{{source}}"},
            "issued": "2024-01-08T16:41:03.000Z",
            "modified": "{{modified:toISO}}",
            "keyword": ["Township", "PLSS"],
            "landingPage": "https://example.com/datasets/example",
            "spatial": "-90.0, 44.0, -89.0, 43.0",
            "distribution": [],
        }

        extracted = AardvarkDataProcessor.extract_data(dataset)
        self.assertEqual(extracted["creator"], [])
        self.assertEqual(extracted["publisher"], {})

        record = Aardvark(dataset, website)

        self.assertEqual(record.dct_title_s, "Example Agency - Untitled Dataset")
        self.assertEqual(record.dct_creator_sm, [])
        self.assertEqual(record.dct_publisher_sm, ["Example Agency"])
        self.assertEqual(record.dct_description_sm, [DESCRIPTION])
        self.assertEqual(record.dct_issued_s, "2024-01-08")
        self.assertEqual(record.dct_temporal_sm, ["Issued 2024"])
        self.assertEqual(record.gbl_indexYear_im, [2024])


if __name__ == "__main__":
    unittest.main()
