#!/bin/sh
set -eu

engine_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
project_root=$(CDPATH= cd -- "$engine_dir/../../../.." && pwd)
runtime_dir="$project_root/.local/gamebook/ink-cli"

if [ ! -d "$runtime_dir/node_modules/inkjs" ] || ! cmp -s "$engine_dir/package-lock.json" "$runtime_dir/package-lock.json"; then
  mkdir -p "$runtime_dir"
  cp "$engine_dir/package.json" "$engine_dir/package-lock.json" "$runtime_dir/"
  npm_config_cache="$project_root/.local/npm/cache" npm ci --prefix "$runtime_dir" --ignore-scripts --no-audit --no-fund
fi

inklecate -o "$runtime_dir/story.json" "$engine_dir/story.ink"
FORCE_COLOR=1 node "$engine_dir/scripts/play-color.cjs" "$runtime_dir/story.json" "$runtime_dir/node_modules/inkjs"
