#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCENE_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(git -C "$SCENE_DIR" rev-parse --show-toplevel)"
ASSETS_ROOT="$REPO_ROOT/app/game/assets"
SOURCE_PXO="$SCENE_DIR/exports/mob-bat-sprite-sheet.pxo"
OUTPUT_PNG="$SCENE_DIR/exports/mob-bat-sprite-sheet.png"
GODOT_PNG="$REPO_ROOT/app/game/engines/godot/assets/mobs/mob-bat-sprite-sheet.png"
PIXELORAMA_CONFIG="$ASSETS_ROOT/.mise/conf.d/pixelorama/config.toml"

export MISE_CACHE_DIR="${MISE_CACHE_DIR:-$REPO_ROOT/.local/mise/cache}"
export MISE_STATE_DIR="${MISE_STATE_DIR:-$REPO_ROOT/.local/mise/state}"
export MISE_DATA_DIR="${MISE_DATA_DIR:-$REPO_ROOT/.local/mise/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$REPO_ROOT/.local/pixelorama/config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$REPO_ROOT/.local/pixelorama/data}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$REPO_ROOT/.local/pixelorama/cache}"

version="$(sed -n 's/^version = "\([^"]*\)"/\1/p' "$PIXELORAMA_CONFIG" | head -n 1)"
PIXELORAMA_BIN="${PIXELORAMA_BIN:-$MISE_DATA_DIR/installs/github-orama-interactive-pixelorama/$version/Pixelorama.x86_64}"

if [[ ! -f "$SOURCE_PXO" ]]; then
	printf 'File Pixelorama non trovato: %s\n' "$SOURCE_PXO" >&2
	exit 1
fi
if [[ ! -x "$PIXELORAMA_BIN" ]]; then
	printf 'Eseguibile Pixelorama non trovato: %s\n' "$PIXELORAMA_BIN" >&2
	exit 1
fi

mkdir -p "$(dirname -- "$OUTPUT_PNG")" "$(dirname -- "$GODOT_PNG")" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
temporary_dir="$(mktemp -d "${TMPDIR:-/tmp}/mob-bat-pixelorama-export.XXXXXX")"
trap 'rm -rf "$temporary_dir"' EXIT
temporary_pxo="$temporary_dir/mob-bat-sprite-sheet.pxo"

# Aggiorna solo il profilo di export nella copia temporanea, lasciando intatto il PXO editabile.
/usr/bin/python3 - "$SOURCE_PXO" "$temporary_pxo" "$(dirname -- "$OUTPUT_PNG")" <<'PY'
import json
import sys
import zipfile

source, destination, output_dir = sys.argv[1:]
with zipfile.ZipFile(source, 'r') as original:
    project = json.loads(original.read('data.json'))
    if (project.get('size_x'), project.get('size_y')) != (32, 32):
        raise SystemExit('Il canvas PXO del pipistrello deve essere 32x32')
    if len(project.get('frames', [])) != 2 or len(project.get('layers', [])) != 1:
        raise SystemExit('Il PXO del pipistrello deve contenere 2 frame su un livello')
    project['export_profile'].update({
        'directory_path': json.dumps(output_dir),
        'file_name': json.dumps('mob-bat-sprite-sheet'),
        'current_tab': '1',
        'orientation': '0',
        'lines_count': '1',
        'number_of_frames': '2',
        'frame_current_tag': '0',
        'export_layers': '0',
        'resize': '100',
        'split_layers': 'false',
        'sheet_layers_as_separate_files': 'false',
    })
    with zipfile.ZipFile(destination, 'w', compression=zipfile.ZIP_DEFLATED) as configured:
        for entry in original.infolist():
            data = original.read(entry.filename)
            if entry.filename == 'data.json':
                data = json.dumps(project, separators=(',', ':')).encode('utf-8')
            configured.writestr(entry, data)
PY

"$PIXELORAMA_BIN" --headless --quit-after 60 -- --export --spritesheet "$temporary_pxo"

/usr/bin/python3 - "$OUTPUT_PNG" <<'PY'
import struct
import sys

path = sys.argv[1]
with open(path, 'rb') as image:
    header = image.read(24)
if header[:8] != b'\x89PNG\r\n\x1a\n':
    raise SystemExit(f'Export non valido: {path} non è una PNG')
size = struct.unpack('>II', header[16:24])
if size != (64, 32):
    raise SystemExit(f'Dimensioni inattese per la sprite sheet: {size[0]}x{size[1]} (atteso 64x32)')
PY

cp "$OUTPUT_PNG" "$GODOT_PNG"
printf 'Esportata %s (64x32, 2 frame FLAP 32x32)\n' "$OUTPUT_PNG"
printf 'Aggiornata copia Godot: %s\n' "$GODOT_PNG"
