import argparse
import json
import logging
import os
from pathlib import Path
import subprocess
from typing import Dict, Iterable, Optional

import yaml
from classify import ResourceClassifier

# Load configuration from YAML file
with open("config/opendataharvest.yaml", "r") as file:
    config = yaml.safe_load(file)


class StanfordSpatialNormalizer:
    @staticmethod
    def normalize(data_dict: Dict) -> bool:
        """Collapse a known bad Stanford place combination to a broader place."""
        spatial = data_dict.get("dct_spatial_sm", [])
        if "Wisconsin" in spatial and "New Mexico" in spatial:
            data_dict["dct_spatial_sm"] = ["United States"]
            return True
        return False


class OpenIndexMapsNormalizer:
    @staticmethod
    def normalize(data_dict: Dict) -> bool:
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
            return False

        logging.debug("OpenIndexMap detected, setting resource class and type.")
        changed = False

        if data_dict.get("gbl_resourceClass_sm") != ["Maps"]:
            data_dict["gbl_resourceClass_sm"] = ["Maps"]
            changed = True
        if data_dict.get("gbl_resourceType_sm") != ["Index maps"]:
            data_dict["gbl_resourceType_sm"] = ["Index maps"]
            changed = True

        if "aerial" in dct_description_sm.lower():
            if data_dict.get("gbl_resourceClass_sm") != ["Imagery"]:
                data_dict["gbl_resourceClass_sm"] = ["Imagery"]
                changed = True

        return changed


class WiscoProviderNormalizer:
    @staticmethod
    def normalize(data_dict: Dict) -> bool:
        """Normalize select Wisconsin provider names and prepend provenance text."""
        provider = data_dict.get("schema_provider_s", "")
        if provider not in config["wisco_providers"]:
            return False

        logging.debug(f"Wisco provider identified: {provider}")
        changed = False
        source = data_dict.get("dct_source_sm", [])
        if not isinstance(source, list):
            source = [source] if source else []

        if provider not in source:
            source.append(provider)
            changed = True

        if data_dict.get("dct_source_sm") != source:
            data_dict["dct_source_sm"] = source
            changed = True

        if data_dict.get("schema_provider_s") != ["University of Wisconsin-Madison"]:
            data_dict["schema_provider_s"] = ["University of Wisconsin-Madison"]
            changed = True

        description = data_dict.get("dct_description_sm", [])
        if not isinstance(description, list):
            description = [description] if description else []

        provenance_note = f"Resource provided by {provider}."
        if provenance_note not in description:
            description.insert(0, provenance_note)
            changed = True

        if data_dict.get("dct_description_sm") != description:
            data_dict["dct_description_sm"] = description
            changed = True
        logging.debug(f"Wisco Description now reads: {description}")
        return changed


class RestrictedNoteNormalizer:
    @staticmethod
    def normalize(data_dict: Dict) -> bool:
        """Add a warning note for restricted records."""
        if data_dict.get("dct_accessRights_s") != "Restricted":
            return False

        note = (
            "Warning: This dataset is restricted and you may not be able to access "
            "the resource. Contact the dataset provider or the AGSL for assistance."
        )
        display_notes = data_dict.get("gbl_displayNote_sm")

        if display_notes is None:
            data_dict["gbl_displayNote_sm"] = [note]
            return True
        elif isinstance(display_notes, list):
            if note not in display_notes:
                display_notes.append(note)
                return True
        else:
            data_dict["gbl_displayNote_sm"] = [display_notes, note]
            return True

        return False


class ResourceClassificationNormalizer:
    @staticmethod
    def normalize(data_dict: Dict) -> bool:
        """Fill missing resource class/type using shared classification rules."""
        if data_dict.get("gbl_resourceClass_sm") and data_dict.get("gbl_resourceType_sm"):
            return False

        resource_class, resource_type = ResourceClassifier.determine_resource_class_and_type(
            data_dict
        )
        changed = False

        if data_dict.get("gbl_resourceClass_sm") != resource_class:
            data_dict["gbl_resourceClass_sm"] = resource_class
            changed = True
        if data_dict.get("gbl_resourceType_sm") != resource_type:
            data_dict["gbl_resourceType_sm"] = resource_type
            changed = True

        return changed


class TitleTransliterationNormalizer:
    FIELD = "agsl_title_transliterated_s"
    ICU_TRANSFORM = "Any-Latin; Latin-ASCII"

    _cache = {}
    _process = None
    _disabled = False

    @classmethod
    def normalize(cls, data_dict: Dict) -> bool:
        title = str(data_dict.get("dct_title_s", ""))
        transliterated = cls.transliterate(title)
        current = data_dict.get(cls.FIELD)

        if transliterated:
            if current != transliterated:
                data_dict[cls.FIELD] = transliterated
                return True
        else:
            if cls.FIELD in data_dict:
                data_dict.pop(cls.FIELD, None)
                return True

        return False

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
    def normalize_document(data_dict: Dict) -> bool:
        changed = False
        changed = StanfordSpatialNormalizer.normalize(data_dict) or changed
        changed = OpenIndexMapsNormalizer.normalize(data_dict) or changed
        changed = WiscoProviderNormalizer.normalize(data_dict) or changed
        changed = RestrictedNoteNormalizer.normalize(data_dict) or changed
        changed = ResourceClassificationNormalizer.normalize(data_dict) or changed
        changed = TitleTransliterationNormalizer.normalize(data_dict) or changed
        return changed


def iter_json_files(rootdir: Path) -> Iterable[Path]:
    for path in rootdir.rglob("*.json"):
        if path.name != "layers.json":
            yield path


def normalize_directory(rootdir: Path, schema_version: str = "Aardvark") -> int:
    updated = 0
    scanned = 0

    logging.info(f"Starting normalization in {rootdir} for schema version {schema_version}.")

    for path in iter_json_files(rootdir):
        scanned += 1
        if scanned % 1000 == 0:
            logging.info(f"Scanned {scanned} files; updated {updated} so far.")
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

            changed = MetadataNormalizer.normalize_document(record) or changed

        if changed:
            with open(path, "w", encoding="utf8") as file:
                json.dump(data, file, indent=2)
                file.write("\n")
            updated += 1
            if updated <= 10 or updated % 100 == 0:
                logging.info(f"Updated {path}")

    logging.info(f"Finished scanning {scanned} files; updated {updated}.")
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
