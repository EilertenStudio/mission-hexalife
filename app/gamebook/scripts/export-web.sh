#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
gamebook_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
repo_root=$(CDPATH= cd -- "$gamebook_dir/../.." && pwd)
runtime_dir="$repo_root/.local/gamebook/ink-cli"
output_dir="$gamebook_dir/dist"

if [ ! -d "$runtime_dir/node_modules/inkjs" ] || ! cmp -s "$gamebook_dir/package-lock.json" "$runtime_dir/package-lock.json"; then
  mkdir -p "$runtime_dir"
  cp "$gamebook_dir/package.json" "$gamebook_dir/package-lock.json" "$runtime_dir/"
  npm_config_cache="$repo_root/.local/npm/cache" npm ci --prefix "$runtime_dir" --ignore-scripts --no-audit --no-fund
fi

mkdir -p "$output_dir"
inklecate -o "$output_dir/story.json" "$gamebook_dir/story.ink"
node "$script_dir/story-to-js.cjs" "$output_dir/story.json" "$output_dir/story.js"
rm "$output_dir/story.json"
cp "$runtime_dir/node_modules/inkjs/dist/ink.js" "$output_dir/ink.js"
cp "$gamebook_dir/web/index.html" "$output_dir/index.html"
cp "$script_dir/checkpoints.js" "$output_dir/checkpoints.js"

node -e 'const path = require("node:path"); const { pathToFileURL } = require("node:url"); console.log("Storia web:", pathToFileURL(path.join(process.argv[1], "index.html")).href);' "$output_dir"
