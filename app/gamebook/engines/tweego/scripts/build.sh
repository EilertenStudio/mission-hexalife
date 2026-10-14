#!/bin/sh
set -eu

engine_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
repo_dir=$(CDPATH= cd -- "$engine_dir/../../../.." && pwd)
output_dir="$repo_dir/.local/gamebook/tweego"

mkdir -p "$output_dir"
tweego -f sugarcube-2 -o "$output_dir/story.html" "$engine_dir/story.twee"
printf 'Creato: %s\n' "$output_dir/story.html"
