#!/bin/sh
set -eu

engine_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
dialog_root=$(mise where github:Dialog-IF/dialog)

python3 "$engine_dir/scripts/play-ansi.py" \
  dgdebug --formatting ansi --no-warn-not-topic \
  "$engine_dir/story.dg" "$dialog_root/stdlib.dg"
