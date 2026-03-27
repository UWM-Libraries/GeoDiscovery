#!/bin/bash

set -euo pipefail

cd lib/opendataharvest

echo "Ensuring opendataharvest Python environment is ready..."
PYTHON_BIN="${PYTHON_BIN:-}"

if [ -z "$PYTHON_BIN" ]; then
    for candidate in python3.11 python3.10 python3.9 python3; do
        if command -v "$candidate" >/dev/null 2>&1; then
            PYTHON_BIN="$candidate"
            break
        fi
    done
fi

if [ -z "$PYTHON_BIN" ]; then
    echo "No suitable Python interpreter found for opendataharvest venv setup." >&2
    exit 1
fi

echo "Using Python interpreter: $PYTHON_BIN"
"$PYTHON_BIN" -m venv venv
. venv/bin/activate
pip install --quiet --disable-pip-version-check -r src/requirements.txt
echo "opendataharvest Python environment ready."
