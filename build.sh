#!/usr/bin/env bash
# Builds both Lily58 halves (nice_nano_v2 + lily58_left/right) in podman,
# mirroring the GitHub CI job (zmk build-user-config.yml@v0.3).
#
# Outputs:
#   build/output/  - firmware files
#   build/build.log - full build log
#   build/cache/   - west workspace cache (kept between runs)
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p build/output
log=build/build.log

echo "==> Building ZMK firmware (log: $log)"
podman run --rm \
  -v "$PWD":/workspaces/zmk-config:Z \
  zmkfirmware/zmk-build-arm:stable \
  bash /workspaces/zmk-config/build/container.sh "$@" 2>&1 | tee "$log"

echo "==> Firmware:"
ls -l build/output/
