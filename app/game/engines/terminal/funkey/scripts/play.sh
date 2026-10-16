#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$script_dir/prepare-source.sh"
cd "$FUNKEY_SOURCE_ROOT/funkey"
cargo run --release --locked --example hexalife_cryogenic_awakening
