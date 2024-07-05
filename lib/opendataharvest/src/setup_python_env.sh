#!/bin/bash

cd lib/opendataharvest
python3 -m venv venv
. venv/bin/activate
pip install -r src/requirements.txt
