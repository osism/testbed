#!/bin/bash

source /opt/venv/bin/activate
python3 set-versions.py
rm set-versions.py
deactivate
