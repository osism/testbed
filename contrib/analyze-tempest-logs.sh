#!/bin/bash

if [ -z "$1" ] || [ ! -f "$1" ]; then
    echo "Usage: $0 <tempest-logfile>"
    exit 1
fi

awk '
/^\{[0-9]+\}/ && /(ok$|FAILED|SKIPPED|ERROR)/ { print }
/^=+$/ { if (!sep) { print ""; sep=1 } }
/^=+$/,0 { print }
' "$1"
