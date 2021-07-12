#!/usr/bin/env bash
set -euxo pipefail

# Pull often fails with "net/http: TLS handshake timeout" 
#docker-compose pull
docker-compose up --no-build --remove-orphans --exit-code-from test
docker-compose rm -f

ls -lah robot_results
