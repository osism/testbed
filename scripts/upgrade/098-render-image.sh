#!/bin/bash

source /opt/venv/bin/activate
python3 render-images.py
rm render-images.py
deactivate
