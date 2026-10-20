#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
gamebook_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
repo_root=$(CDPATH= cd -- "$gamebook_dir/../.." && pwd)
runtime_dir="$repo_root/.local/gamebook/ink-cli"

if [ ! -d "$runtime_dir/node_modules/inkjs" ] || ! cmp -s "$gamebook_dir/package-lock.json" "$runtime_dir/package-lock.json"; then
  mkdir -p "$runtime_dir"
  cp "$gamebook_dir/package.json" "$gamebook_dir/package-lock.json" "$runtime_dir/"
  npm_config_cache="$repo_root/.local/npm/cache" npm ci --prefix "$runtime_dir" --ignore-scripts --no-audit --no-fund
fi

inklecate -o "$runtime_dir/story.json" "$gamebook_dir/story.ink"
FORCE_COLOR=1 node "$script_dir/play-color.cjs" "$runtime_dir/story.json" "$runtime_dir/node_modules/inkjs"
