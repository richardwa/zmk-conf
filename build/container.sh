#!/usr/bin/env bash
# Runs inside the zmkfirmware/zmk-build-arm:stable container.
# Local equivalent of zmkfirmware/zmk's build-user-config.yml@v0.3 job.
#
# Usage: bash build/container.sh [board] [shield]   (no args = full build.yaml matrix)
set -euo pipefail

repo=/workspaces/zmk-config
config_path=config
# CI uses a temp dir for the west workspace when zephyr/module.yml exists;
# we use the persistent cache dir so module downloads survive between runs.
base_dir="$repo/build/cache"
output_dir="$repo/build/output"

mkdir -p "$base_dir/$config_path"
cp -R "$repo/$config_path/." "$base_dir/$config_path/"

if [ ! -e "$base_dir/.west" ]; then
  west init -l "$base_dir/$config_path"
fi
west update --fetch-opt=--filter=tree:0
west zephyr-export

build_one() {
  local board="$1"
  local shield="${2:-}"
  local build_dir="$base_dir/build/$board${shield:+-$shield}"
  local display_name="${shield:+"$shield - "}$board"
  local artifact_name="${shield:+$shield-}${board}-zmk"

  # -DZMK_EXTRA_MODULES points at the repo root, which contains zephyr/module.yml
  local extra_cmake_args="-DZMK_CONFIG=$base_dir/$config_path -DZMK_EXTRA_MODULES=$repo"
  if [ -n "$shield" ]; then
    extra_cmake_args="-DSHIELD=$shield $extra_cmake_args"
  fi

  echo "==> Building $display_name"
  west build -s zmk/app -d "$build_dir" -b "$board" -- $extra_cmake_args

  for ext in uf2 bin; do
    if [ -f "$build_dir/zephyr/zmk.$ext" ]; then
      cp "$build_dir/zephyr/zmk.$ext" "$output_dir/$artifact_name.$ext"
      echo "==> Artifact: build/output/$artifact_name.$ext"
    fi
  done
}

cd "$base_dir"

if [ $# -ge 1 ]; then
  build_one "$1" "${2:-}"
else
  # No args: mirror build.yaml (keep in sync with it)
  build_one nice_nano_v2 lily58_left
  build_one nice_nano_v2 lily58_right
fi

echo "==> Done. Firmware is in build/output/"
