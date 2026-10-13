#!/bin/sh
set -eu

engine_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
project_root=$(CDPATH= cd -- "$engine_dir/../../../.." && pwd)
runtime_dir="$project_root/.local/gamebook/ink-cli"
output_dir="$engine_dir/dist"

if [ ! -d "$runtime_dir/node_modules/inkjs" ] || ! cmp -s "$engine_dir/package-lock.json" "$runtime_dir/package-lock.json"; then
  mkdir -p "$runtime_dir"
  cp "$engine_dir/package.json" "$engine_dir/package-lock.json" "$runtime_dir/"
  npm_config_cache="$project_root/.local/npm/cache" npm ci --prefix "$runtime_dir" --ignore-scripts --no-audit --no-fund
fi

mkdir -p "$output_dir"
inklecate -o "$output_dir/story.json" "$engine_dir/story.ink"
node "$engine_dir/scripts/story-to-js.cjs" "$output_dir/story.json" "$output_dir/story.js"
rm "$output_dir/story.json"
cp "$runtime_dir/node_modules/inkjs/dist/ink.js" "$output_dir/ink.js"
cp "$engine_dir/web/index.html" "$output_dir/index.html"
cp "$engine_dir/scripts/checkpoints.js" "$output_dir/checkpoints.js"

node -e 'const path = require("node:path"); const { pathToFileURL } = require("node:url"); console.log("Storia web:", pathToFileURL(path.join(process.argv[1], "index.html")).href);' "$output_dir"
