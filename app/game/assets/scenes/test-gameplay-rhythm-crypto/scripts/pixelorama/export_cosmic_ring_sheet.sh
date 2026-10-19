#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCENE_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(git -C "$SCENE_DIR" rev-parse --show-toplevel)"
ASSETS_ROOT="$REPO_ROOT/app/game/assets"
SOURCE_PXO="$SCENE_DIR/exports/prop-weapon-cosmic_ring-sheet.pxo"
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

output_dir="$SCENE_DIR/exports"
godot_vfx_dir="$REPO_ROOT/app/game/engines/godot/assets/vfx"
mkdir -p "$output_dir" "$godot_vfx_dir" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
temporary_root="/tmp/els-gmx"
mkdir -p "$temporary_root"
temporary_dir="$(mktemp -d "$temporary_root/cosmic-ring-export.XXXXXX")"
trap 'rm -rf "$temporary_dir"' EXIT

# Pixelorama 1.2.3 non applica sempre --output al profilo della spritesheet.
# Creo copie temporanee con il solo layer selezionato; l'export resta gestito da Pixelorama.
/usr/bin/python3 - "$SOURCE_PXO" "$temporary_dir" "$output_dir" <<'PY'
import copy
import json
import sys
import zipfile
from pathlib import Path

source, temporary_dir, output_dir = sys.argv[1:]
temporary_dir = Path(temporary_dir)
with zipfile.ZipFile(source, "r") as original:
    source_project = json.loads(original.read("data.json"))
    layer_names = [layer["name"].strip().upper() for layer in source_project.get("layers", [])]
    expected_layers = ["BLACK HOLE", "WHITE HOLE"]
    if (source_project.get("size_x"), source_project.get("size_y")) != (32, 32):
        raise SystemExit("Il canvas PXO deve essere 32x32")
    if len(source_project.get("frames", [])) != 8:
        raise SystemExit("Il PXO deve contenere quattro frame cast e quattro frame loop")
    if layer_names != expected_layers:
        raise SystemExit("Il PXO deve separare i layer BLACK HOLE e WHITE HOLE")

    for layer_index, (layer_name, file_stem) in enumerate([
        ("BLACK HOLE", "prop-weapon-cosmic_ring-black-hole"),
        ("WHITE HOLE", "prop-weapon-cosmic_ring-white-hole"),
    ]):
        project = copy.deepcopy(source_project)
        selected_layer = copy.deepcopy(project["layers"][layer_index])
        selected_layer["visible"] = True
        project["layers"] = [selected_layer]
        for frame in project["frames"]:
            frame["cels"] = [copy.deepcopy(frame["cels"][layer_index])]
        project["current_layer"] = 0
        profile = project["export_profile"]
        profile.update({
            "directory_path": json.dumps(output_dir),
            "file_name": json.dumps(file_stem),
            "file_format": "0",
            "current_tab": "1",
            "orientation": "0",
            "lines_count": "1",
            "number_of_frames": "8",
            "frame_current_tag": "0",
            "export_layers": "0",
            "resize": "100",
            "split_layers": "false",
            "sheet_layers_as_separate_files": "false",
        })
        destination = temporary_dir / f"{file_stem}.pxo"
        with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as configured:
            for entry in original.infolist():
                if entry.filename.startswith("image_data/frames/"):
                    continue
                data = original.read(entry.filename)
                if entry.filename == "data.json":
                    data = json.dumps(project, separators=(",", ":")).encode("utf-8")
                configured.writestr(entry.filename, data, compress_type=zipfile.ZIP_DEFLATED)
            for frame_number in range(1, 9):
                source_prefix = f"image_data/frames/{frame_number}"
                output_prefix = source_prefix
                configured.writestr(output_prefix + "/", b"")
                configured.writestr(
                    output_prefix + "/layer_1",
                    original.read(f"{source_prefix}/layer_{layer_index + 1}"),
                )
                configured.writestr(
                    output_prefix + "/indices_layer_1",
                    original.read(f"{source_prefix}/indices_layer_{layer_index + 1}"),
                )
PY

for color in black-hole white-hole; do
	file_stem="prop-weapon-cosmic_ring-$color"
	"$PIXELORAMA_BIN" --headless --quit-after 60 -- --export --spritesheet "$temporary_dir/$file_stem.pxo"
	/usr/bin/python3 - "$output_dir/$file_stem.png" <<'PY'
import struct
import sys

path = sys.argv[1]
with open(path, "rb") as image:
	header = image.read(24)
if header[:8] != b"\x89PNG\r\n\x1a\n":
	raise SystemExit(f"Export non valido: {path} non è una PNG")
size = struct.unpack(">II", header[16:24])
if size != (256, 32):
	raise SystemExit(f"Dimensioni inattese: {size[0]}x{size[1]} (atteso 256x32)")
PY
	cp "$output_dir/$file_stem.png" "$godot_vfx_dir/$file_stem.png"
done

rm -f "$output_dir/prop-weapon-cosmic_ring-sheet.png"
rm -f "$godot_vfx_dir/prop-weapon-cosmic_ring-sheet.png" "$godot_vfx_dir/prop-weapon-cosmic_ring-sheet.png.import"

printf 'Esportate le sheet VFX separate (8 frame 32x32 ciascuna): %s\n' "$output_dir"
printf 'Aggiornate le copie Godot: %s\n' "$godot_vfx_dir"
