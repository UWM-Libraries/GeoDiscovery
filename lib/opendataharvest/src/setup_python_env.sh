#!/bin/bash

set -euo pipefail

cd lib/opendataharvest

echo "Ensuring opendataharvest Python environment is ready..."
python3 -m venv venv
. venv/bin/activate
pip install --quiet --disable-pip-version-check -r src/requirements.txt
echo "opendataharvest Python environment ready."
