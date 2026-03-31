import os
import subprocess
import logging
import yaml
from pathlib import Path

# Load configuration from YAML file
with open("config/opendataharvest.yaml", "r") as file:
    config = yaml.safe_load(file)

# Get the OGM_PATH environment variable or from config
env_ogm_path = os.getenv("OGM_PATH")
if os.getenv("RAILS_ENV") == "production" and not env_ogm_path:
    raise ValueError("OGM_PATH must be set in production")
ogm_path = env_ogm_path or config["paths"]["ogm_path"]

# Set up logging to a file
logfile = config["logging"]["logfile"]
level = getattr(logging, config["logging"]["level"].upper(), logging.ERROR)
logging.basicConfig(
    filename=logfile,
    level=level,
    format="%(asctime)s:%(levelname)s:%(message)s",
)

REPOS = [
    # {"name": "edu.berkeley"},
    {"name": "edu.princeton.arks"},
    {"name": "edu.stanford.purl"},
    {"name": "edu.cornell"},
    {"name": "edu.columbia"},
    {"name": "edu.wisc", "extra_args": ["--place_default", "Wisconsin"]},
]


def has_aardvark_metadata(repo_path: Path) -> bool:
    aardvark_dirs = [repo_path / "metadata-aardvark", repo_path / "aardvark"]
    for aardvark_dir in aardvark_dirs:
        if not aardvark_dir.is_dir():
            continue
        if any(aardvark_dir.rglob("geoblacklight.json")):
            return True
    return False


def legacy_source_dir(repo_path: Path) -> Path:
    metadata_1 = repo_path / "metadata-1.0"
    return metadata_1 if metadata_1.is_dir() else repo_path


def has_legacy_metadata(repo_path: Path) -> bool:
    return any(repo_path.rglob("geoblacklight.json"))


for repo in REPOS:
    repo_path = Path(ogm_path) / repo["name"]

    if not repo_path.is_dir():
        logging.info(
            f"Skipping conversion for {repo['name']}: local repository path does not exist."
        )
        continue

    if has_aardvark_metadata(repo_path):
        logging.info(
            f"Skipping conversion for {repo['name']}: populated Aardvark metadata already exists."
        )
        continue

    source_dir = legacy_source_dir(repo_path)
    if not has_legacy_metadata(source_dir):
        logging.warning(
            f"Skipping conversion for {repo['name']}: no legacy geoblacklight.json files were found."
        )
        continue

    target_dir = repo_path / "aardvark"
    command = [
        "lib/opendataharvest/venv/bin/python3",
        "lib/opendataharvest/src/opendataharvest/convert.py",
        str(source_dir),
        str(target_dir),
    ] + repo.get("extra_args", [])

    try:
        subprocess.run(command, check=True) #, capture_output=True, text=True) (This fails in production)
        logging.info(f"Command {' '.join(command)} executed successfully.")
    except subprocess.CalledProcessError as e:
        logging.error(
            f"Command {' '.join(command)} failed with return code {e.returncode}."
        )
        if e.stderr:
            logging.error(f"Error message: {e.stderr}")
