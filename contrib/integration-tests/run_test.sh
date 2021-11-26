#!/usr/bin/env bash
set -euxo pipefail

# Pull often fails with "net/http: TLS handshake timeout"
until docker compose pull; do
    echo "Failed to pull images, retrying"
done

docker compose up --no-build --remove-orphans --exit-code-from test
docker compose rm -f

ls -lah robot_results
