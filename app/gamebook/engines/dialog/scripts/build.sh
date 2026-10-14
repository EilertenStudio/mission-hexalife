#!/bin/sh
set -eu

engine_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
project_root=$(CDPATH= cd -- "$engine_dir/../../../.." && pwd)
dialog_root=$(mise where github:Dialog-IF/dialog)
output_dir="$project_root/.local/gamebook/dialog"

mkdir -p "$output_dir"
dialogc --no-warn-not-topic -t aa -o "$output_dir/story.aastory" \
  "$engine_dir/story.dg" "$dialog_root/stdlib.dg"
printf 'Creato %s\n' "$output_dir/story.aastory"
