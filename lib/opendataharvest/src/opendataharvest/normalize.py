import argparse
import json
import logging
import os
from pathlib import Path
import subprocess
from typing import Dict, List, Optional

import yaml
from classify import ResourceClassifier

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


class OpenIndexMapsNormalizer:
    @staticmethod
    def normalize(data_dict: Dict) -> None:
        """Restore OpenIndexMaps class/type logic for harvested Aardvark records."""
        dct_references_s = str(data_dict.get("dct_references_s", ""))
        identifier = str(data_dict.get("id", ""))
        dct_source_sm = str(data_dict.get("dct_source_sm", ""))
        dct_description_sm = str(data_dict.get("dct_description_sm", ""))

        if (
            ("openindexmaps" not in dct_references_s.lower())
            and (identifier != "stanford-ch237ht4777")
            and ("ch237ht4777" not in dct_source_sm.lower())
        ):
            return

        logging.debug("OpenIndexMap detected, setting resource class and type.")
        data_dict["gbl_resourceClass_sm"] = ["Maps"]
        data_dict["gbl_resourceType_sm"] = ["Index maps"]

        if "aerial" in dct_description_sm.lower():
            data_dict["gbl_resourceClass_sm"] = ["Imagery"]


class WiscoProviderNormalizer:
    @staticmethod
    def normalize(data_dict: Dict) -> None:
        """Normalize select Wisconsin provider names and prepend provenance text."""
        provider = data_dict.get("schema_provider_s", "")
        if provider not in config["wisco_providers"]:
            return

        logging.debug(f"Wisco provider identified: {provider}")
        source = data_dict.get("dct_source_sm", [])
        if not isinstance(source, list):
            source = [source] if source else []

        if provider not in source:
            source.append(provider)

        data_dict["dct_source_sm"] = source
        data_dict["schema_provider_s"] = ["University of Wisconsin-Madison"]

        description = data_dict.get("dct_description_sm", [])
        if not isinstance(description, list):
            description = [description] if description else []

        provenance_note = f"Resource provided by {provider}."
        if provenance_note not in description:
            description.insert(0, provenance_note)

        data_dict["dct_description_sm"] = description
        logging.debug(f"Wisco Description now reads: {description}")


class RestrictedNoteNormalizer:
    @staticmethod
    def normalize(data_dict: Dict) -> None:
        """Add a warning note for restricted records."""
        if data_dict.get("dct_accessRights_s") != "Restricted":
            return

        note = (
            "Warning: This dataset is restricted and you may not be able to access "
            "the resource. Contact the dataset provider or the AGSL for assistance."
        )
        display_notes = data_dict.get("gbl_displayNote_sm")

        if display_notes is None:
            data_dict["gbl_displayNote_sm"] = [note]
        elif isinstance(display_notes, list):
            if note not in display_notes:
                display_notes.append(note)
        else:
            data_dict["gbl_displayNote_sm"] = [display_notes, note]


class ResourceClassificationNormalizer:
    @staticmethod
    def normalize(data_dict: Dict) -> None:
        """Fill missing resource class/type using shared classification rules."""
        if data_dict.get("gbl_resourceClass_sm") and data_dict.get("gbl_resourceType_sm"):
            return

        (
            data_dict["gbl_resourceClass_sm"],
            data_dict["gbl_resourceType_sm"],
        ) = ResourceClassifier.determine_resource_class_and_type(data_dict)


class TitleTransliterationNormalizer:
    FIELD = "agsl_title_transliterated_s"
    ICU_TRANSFORM = "Any-Latin; Latin-ASCII"

    _cache = {}
    _process = None
    _disabled = False

    @classmethod
    def normalize(cls, data_dict: Dict) -> None:
        title = str(data_dict.get("dct_title_s", ""))
        transliterated = cls.transliterate(title)

        if transliterated:
            data_dict[cls.FIELD] = transliterated
        else:
            data_dict.pop(cls.FIELD, None)

    @classmethod
    def transliterate(cls, title: str) -> Optional[str]:
        if not title or not cls.needs_transliteration(title):
            return None
        if title in cls._cache:
            return cls._cache[title]
        if cls._disabled:
            return None

        process = cls.process()
        if process is None:
            return None

        try:
            process.stdin.write(title.replace("\n", " ") + "\n")
            process.stdin.flush()
            stdout = process.stdout.readline()
        except (BrokenPipeError, OSError) as exc:
            logging.warning(f"uconv transliteration failed: {exc}")
            cls.disable()
            return None

        transliterated = " ".join(stdout.split())
        if not transliterated or transliterated == title:
            cls._cache[title] = None
            return None

        cls._cache[title] = transliterated
        return transliterated

    @classmethod
    def process(cls):
        if cls._disabled:
            return None
        if cls._process is not None and cls._process.poll() is None:
            return cls._process

        try:
            cls._process = subprocess.Popen(
                ["uconv", "-x", cls.ICU_TRANSFORM],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                universal_newlines=True,
                encoding="utf-8",
                bufsize=1,
            )
        except FileNotFoundError:
            logging.warning(
                "Title transliteration requires the ICU 'uconv' binary to be installed and on PATH."
            )
            cls.disable()
            return None

        return cls._process

    @classmethod
    def disable(cls) -> None:
        cls._disabled = True
        if cls._process is not None:
            try:
                cls._process.terminate()
            except OSError:
                pass
        cls._process = None

    @staticmethod
    def needs_transliteration(title: str) -> bool:
        normalized = title.lstrip()
        if not normalized:
            return False
        return ord(normalized[0]) > 127


class MetadataNormalizer:
    @staticmethod
    def normalize_document(data_dict: Dict) -> None:
        StanfordSpatialNormalizer.normalize(data_dict)
        OpenIndexMapsNormalizer.normalize(data_dict)
        WiscoProviderNormalizer.normalize(data_dict)
        RestrictedNoteNormalizer.normalize(data_dict)
        ResourceClassificationNormalizer.normalize(data_dict)
        TitleTransliterationNormalizer.normalize(data_dict)


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
