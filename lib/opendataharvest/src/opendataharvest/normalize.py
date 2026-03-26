import argparse
import json
import logging
import os
from pathlib import Path
from typing import Dict, List

import yaml

# Load configuration from YAML file
with open("config/opendataharvest.yaml", "r") as file:
    config = yaml.safe_load(file)


class StanfordSpatialNormalizer:
    @staticmethod
    def normalize(data_dict: Dict) -> None:
        """Collapse a known bad Stanford place combination to a broader place."""
        spatial = data_dict.get("dct_spatial_sm", [])
        if "Wisconsin" in spatial and "New Mexico" in spatial:
            data_dict["dct_spatial_sm"] = ["United States"]


class WiscoProviderNormalizer:
    @staticmethod
    def normalize(data_dict: Dict) -> None:
        """Normalize select Wisconsin provider names and prepend provenance text."""
        provider = data_dict.get("schema_provider_s", "")
        if provider not in config["wisco_providers"]:
            return

        logging.debug(f"Wisco provider identified: {provider}")
        data_dict["schema_provider_s"] = ["University of Wisconsin-Madison"]

        description = data_dict.get("dct_description_sm", [])
        if not isinstance(description, list):
            description = [description] if description else []

        provenance_note = f"Resource provided by {provider}."
        if provenance_note not in description:
            description.insert(0, provenance_note)

        data_dict["dct_description_sm"] = description
        logging.debug(f"Wisco Description now reads: {description}")


class MetadataNormalizer:
    @staticmethod
    def normalize_document(data_dict: Dict) -> None:
        StanfordSpatialNormalizer.normalize(data_dict)
        WiscoProviderNormalizer.normalize(data_dict)


def iter_json_files(rootdir: Path) -> List[Path]:
    return [path for path in rootdir.rglob("*.json") if path.name != "layers.json"]


def normalize_directory(rootdir: Path, schema_version: str = "Aardvark") -> int:
    updated = 0

    for path in iter_json_files(rootdir):
        try:
            with open(path, encoding="utf8") as file:
                data = json.load(file)
        except FileNotFoundError:
            logging.error(f"File not found: {path}")
            continue
        except json.JSONDecodeError:
            logging.error(f"Error decoding JSON in file: {path}")
            continue

        records = data if isinstance(data, list) else [data]
        changed = False

        for record in records:
            if not isinstance(record, dict):
                continue

            record_schema = record.get("gbl_mdVersion_s") or record.get("geoblacklight_version")
            if record_schema != schema_version:
                continue

            before = json.dumps(record, sort_keys=True)
            MetadataNormalizer.normalize_document(record)
            after = json.dumps(record, sort_keys=True)
            changed = changed or before != after

        if changed:
            with open(path, "w", encoding="utf8") as file:
                json.dump(data, file, indent=2)
                file.write("\n")
            updated += 1

    return updated


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Normalize harvested Aardvark metadata in place."
    )
    parser.add_argument(
        "rootdir",
        type=Path,
        nargs="?",
        default=Path(os.getenv("OGM_PATH", config["paths"]["ogm_path"])),
        help="Root directory of harvested JSON files"
    )
    parser.add_argument(
        "--schema_version",
        type=str,
        default=os.getenv("SCHEMA_VERSION", "Aardvark"),
        help="Only normalize records matching this schema version"
    )

    logfile = config["logging"]["logfile"]
    level = getattr(logging, config["logging"]["level"].upper(), logging.ERROR)
    os.makedirs(os.path.dirname(logfile), exist_ok=True)
    logging.basicConfig(
        filename=logfile,
        level=level,
        format="%(asctime)s:%(levelname)s:%(message)s",
    )

    args = parser.parse_args()
    updated = normalize_directory(args.rootdir, args.schema_version)
    print(f"Normalized {updated} files.")
