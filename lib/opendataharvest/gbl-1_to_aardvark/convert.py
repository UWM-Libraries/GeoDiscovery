import json
import csv
import os
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import argparse


class LoggerConfig:
    @staticmethod
    def configure_logging(logfile: str) -> None:
        logging.basicConfig(
            filename=logfile,
            filemode="a",
            level=logging.DEBUG,
            format="%(asctime)s - %(levelname)s - %(message)s",
        )


class SchemaUpdater:
    def __init__(
        self,
        overwrite_values: Optional[Dict[str, str]] = None,
        resource_class_default: str = None,
        resource_type_default: str = None,
        place_default: Optional[str] = None,
    ):
        self.RESOURCE_CLASS_DEFAULT = resource_class_default
        self.RESOURCE_TYPE_DEFAULT = resource_type_default
        self.PLACE_DEFAULT = place_default
        self.crosswalk = self.load_crosswalk(self.CROSSWALK_PATH)
        self.overwrite_values = overwrite_values if overwrite_values else {}

    CROSSWALK_PATH = Path("lib/opendataharvest/gbl-1_to_aardvark/crosswalk.csv")

    @staticmethod
    def load_crosswalk(crosswalk_path: Path) -> Dict[str, str]:
        """Load crosswalk CSV into a dictionary."""
        crosswalk = {}
        with open(crosswalk_path, encoding="utf8") as f:
            reader = csv.reader(f)
            next(reader)  # Skip header
            for old, new in reader:
                crosswalk[old] = new
        return crosswalk

    def update_all_schemas(self, dir_old_schema: Path, dir_new_schema: Path) -> None:
        """Update schemas for all JSON files in the directory."""
        dir_new_schema.mkdir(parents=True, exist_ok=True)
        files = self.list_all_json_files(dir_old_schema)
        for file in files:
            logging.info(f"Processing {file} ...")
            self.update_schema(file, dir_new_schema)

    @staticmethod
    def list_all_json_files(rootdir: Path) -> List[Path]:
        """List all JSON files in a directory, excluding 'layers.json'."""
        return [path for path in rootdir.rglob("*.json") if path.name != "layers.json"]

    def update_schema(self, filepath: Path, dir_new_schema: Path) -> None:
        """Update the schema of a single JSON file."""
        try:
            with open(filepath, encoding="utf8") as fr:
                data = json.load(fr)

            if not isinstance(data, dict):
                return

            for old_schema, new_schema in self.crosswalk.items():
                if old_schema in data:
                    data[new_schema] = data.pop(old_schema)

            data["gbl_mdVersion_s"] = "Aardvark"
            data.pop("geoblacklight_version", None)

            # Handle class and type
            data["gbl_resourceClass_sm"], data["gbl_resourceType_sm"] = self.determine_resource_class_and_type(data)

            # Overwrite specified values
            for key, value in self.overwrite_values.items():
                data[key] = value

            self.check_required(data)

            # Add restricted display note if dc_rights_s is "restricted"
            self.add_restricted_display_notes(data)

            self.remove_deprecated(data)
            self.fix_stanford_place_issue(data)
            data = self.string2array(data)

            new_filepath = dir_new_schema / (
                filepath.name
                if filepath.name != "geoblacklight.json"
                else f"{data['id']}.json"
            )
            with open(new_filepath, "w", encoding="utf8") as fw:
                json.dump(data, fw, indent=2)
        except Exception as e:
            logging.error(f"Failed to update schema for {filepath.name}: {e}")

    @staticmethod
    def add_restricted_display_notes(data_dict: Dict) -> None:
        """Add a restricted display note if dc_rights_s is 'restricted'."""
        if data_dict.get("dct_accessRights_s") == "Restricted":
            note = "Warning: This dataset is restricted and you may not be able to access the resource. Contact the dataset provider or the AGSL for assistance."
            if "gbl_displayNote_sm" in data_dict:
                if isinstance(data_dict["gbl_displayNote_sm"], list):
                    data_dict["gbl_displayNote_sm"].append(note)
                else:
                    data_dict["gbl_displayNote_sm"] = [
                        data_dict["gbl_displayNote_sm"],
                        note,
                    ]
            else:
                data_dict["gbl_displayNote_sm"] = [note]

    def check_required(self, data_dict: Dict) -> None:
        """Check for required fields and handle missing ones."""
        requirements = [
            "dct_publisher_sm",
            "dct_spatial_sm",
            "gbl_mdVersion_s",
            "dct_title_s",
            "id",
            "gbl_mdModified_dt",
            "gbl_resourceClass_sm",
        ]

        for req in requirements:
            if req not in data_dict:
                logging.warning(f"Requirement {req} is not present...")
                self.handle_missing_field(data_dict, req)

    def handle_missing_field(self, data_dict: Dict, field: str) -> None:
        """Handle missing required fields with default values or logic."""
        assert field not in ["gbl_mdVersion_s", "gbl_resourceClass_sm", "id"]

        if field == "dct_spatial_sm":
            data_dict["dct_spatial_sm"] = (
                [self.PLACE_DEFAULT] if self.PLACE_DEFAULT else []
            )
        elif field == "gbl_mdModified_dt":
            data_dict["gbl_mdModified_dt"] = datetime.now(datetime.UTC).strftime(
                "%Y-%m-%dT%H:%M:%SZ"
            )
        elif field == "dct_publisher_sm":
            data_dict["dct_publisher_sm"] = data_dict.get("dct_creator_sm", [])

    @staticmethod
    def determine_resource_class_and_type(data_dict: Dict) -> Tuple[List[str], List[str]]:
        """Determine the resource class based on the data dictionary."""
        # Assign the main return variables if they exist already, if both exist, return them as is.
        gbl_resourceClass_sm = data_dict.get("gbl_resourceClass_sm") or []
        gbl_resourceType_sm = data_dict.get("gbl_resourceType_sm") or []

        if gbl_resourceClass_sm and gbl_resourceType_sm:
            return gbl_resourceClass_sm, gbl_resourceType_sm

        # This is a particular set of Stanford maps that I want to ensure we catch.
        # Remove if it can be caught by further analysis.
        if "stanford-ch237ht4777" in data_dict.get("dct_source_sm", "") or data_dict.get("id") == "stanford-ch237ht4777":
            gbl_resourceClass_sm = ["Maps"]
            gbl_resourceType_sm = ["Index maps"]
            return gbl_resourceClass_sm, gbl_resourceType_sm
        
        # Grab some of the info as text right away
        format = str(data_dict.get("dct_format_s", ""))
        description = str(data_dict.get("dct_description_sm", ""))
        subject = str(data_dict.get("dct_subject_sm", ""))
        publisher = str(data_dict.get("dct_publisher_sm", ""))

        if format in ["Shapefile", "ArcGrid", "GeoDatabase", "Arc/Info Binary Grid"]:
            gbl_resourceClass_sm = ["Datasets"]
            return gbl_resourceClass_sm, gbl_resourceType_sm
        
        if "sanborn" in publisher.lower():
            gbl_resourceClass_sm[0] = "Maps"
            gbl_resourceType_sm[0] = "Fire insurance maps"
            return gbl_resourceClass_sm, gbl_resourceType_sm
        
        if format in ["GeoTIFF", "TIFF"]:
            if "relief" in description.lower() or "map" in description.lower() or "maps" in subject.lower():
                gbl_resourceClass_sm[0] = "Maps"
                gbl_resourceType_sm[0] = "Fire insurance maps"
                return gbl_resourceClass_sm, gbl_resourceType_sm
            gbl_resourceClass_sm = ["Datasets"]
            return gbl_resourceClass_sm, gbl_resourceType_sm 
            
        if format == "":
            if "relief" in description.lower() or "map" in description.lower() or "maps" in subject.lower():
                gbl_resourceClass_sm[0] = "Maps"
                return gbl_resourceClass_sm, gbl_resourceType_sm
            else:
                gbl_resourceClass_sm = ["Other"]
                return gbl_resourceClass_sm, gbl_resourceType_sm

        if "relief" in description.lower() or "map" in description.lower() or "maps" in subject.lower():
            gbl_resourceClass_sm = ["Maps"]
            return gbl_resourceClass_sm, gbl_resourceType_sm

        # If all else fails:
        gbl_resourceClass_sm = [SchemaUpdater.RESOURCE_CLASS_DEFAULT]
        gbl_resourceType_sm = [SchemaUpdater.RESOURCE_TYPE_DEFAULT]
        return gbl_resourceClass_sm, gbl_resourceType_sm

    def handle_class_and_type(self, data_dict: Dict) -> None:
        data_dict["gbl_resourceClass_sm"], data_dict["gbl_resourceType_sm"] = self.determine_resource_class_and_type(data_dict)

    @staticmethod
    def remove_deprecated(data_dict: Dict) -> None:
        """Remove deprecated fields from the data dictionary."""
        deprecated_fields = [
            "dc_type_s",
            "layer_geom_type_s",
            "dct_isPartOf_sm",
            "uw_supplemental_s",
            "uw_notice_s",
            "uuid",
        ]
        for field in deprecated_fields:
            data_dict.pop(field, None)

    @staticmethod
    def fix_stanford_place_issue(data_dict: Dict) -> None:
        """Fix specific place issues related to Stanford."""
        spatial = data_dict.get("dct_spatial_sm", [])
        if "Wisconsin" in spatial and "United States" in spatial:
            data_dict["dct_spatial_sm"] = ["United States"]

    @staticmethod
    def string2array(data_dict: Dict) -> Dict:
        """Convert certain string fields to array if they should be lists."""
        for key in data_dict.keys():
            suffix = key.split("_")[-1]
            if suffix in ["sm", "im"] and not isinstance(data_dict[key], list):
                data_dict[key] = [data_dict[key]]
        return data_dict


if __name__ == "__main__":
    # fmt: off
    parser = argparse.ArgumentParser(description="Update metadata schema from GBL 1.0 to Aardvark.")
    parser.add_argument("dir_old_schema", type=Path, help="Directory of JSON files in the old schema")
    parser.add_argument("dir_new_schema", type=Path, help="Directory for the new schema JSON files")

    # Optional arguments for overwriting values
    parser.add_argument("--dct_publisher_sm", type=str, help="Overwrite dct_publisher_sm")
    parser.add_argument("--dct_spatial_sm", type=str, help="Overwrite dct_spatial_sm")
    parser.add_argument("--gbl_resourceClass_sm", type=str, help="Overwrite gbl_resourceClass_sm")
    parser.add_argument("--gbl_resourceType_sm", type=str, help="Overwrite gbl_resourceType_sm")
    parser.add_argument("--id", type=str, help="Overwrite id")
    parser.add_argument("--gbl_mdModified_dt", type=str, help="Overwrite gbl_mdModified_dt")
    parser.add_argument("--schema_provider_s", type=str, help="Overwrite schema_provider_s")
    parser.add_argument("--gbl_displayNote_sm", type=str, help="Overwrite gbl_displayNote_sm")

    # Optional arguments for setting default values
    parser.add_argument("--resource_class_default", type=str, help="Set default value for resource class")
    parser.add_argument("--resource_type_default", type=str, help="Set default value for resource type")
    parser.add_argument("--place_default", type=str, help="Set default value for place")

    args = parser.parse_args()

    overwrite_values = {
        k: v
        for k, v in vars(args).items()
        if v is not None and k not in ["dir_old_schema", "dir_new_schema", "resource_class_default", "place_default"]
    }

    LoggerConfig.configure_logging("log/gbl-1_to_aardvark.log")
    schema_updater = SchemaUpdater(overwrite_values, args.resource_class_default, args.place_default)
    schema_updater.update_all_schemas(args.dir_old_schema, args.dir_new_schema)
