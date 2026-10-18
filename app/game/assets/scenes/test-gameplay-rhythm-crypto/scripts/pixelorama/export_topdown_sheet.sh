#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCENE_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(git -C "$SCENE_DIR" rev-parse --show-toplevel)"
ASSETS_ROOT="$REPO_ROOT/app/game/assets"
SOURCE_PXO="$SCENE_DIR/exports/jerv-tgrc-topdown-sheet.pxo"
OUTPUT_PNG="$SCENE_DIR/exports/jerv-tgrc-topdown-sheet.png"
GODOT_PNG="$REPO_ROOT/app/game/engines/godot/assets/characters/jerv/jerv-tgrc-topdown-sheet.png"
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
temporary_dir="$(mktemp -d "${TMPDIR:-/tmp}/jerv-pixelorama-export.XXXXXX")"
trap 'rm -rf "$temporary_dir"' EXIT
temporary_pxo="$temporary_dir/jerv-tgrc-topdown-sheet.pxo"

# Pixelorama 1.2.3 ha un problema nell'opzione CLI --output. Configuro una
# copia temporanea del progetto; il disegno e l'export restano gestiti da Pixelorama.
/usr/bin/python3 - "$SOURCE_PXO" "$temporary_pxo" "$(dirname -- "$OUTPUT_PNG")" <<'PY'
import json
import copy
import sys
import zipfile

source, destination, output_dir = sys.argv[1:]
directions = ["DOWN", "LEFT", "TOP", "RIGHT"]
# Pixelorama dispone i frame dall'alto in basso per colonna. Nella copia
# temporanea intercalo le direzioni per ottenere una riga per direzione.
column_major_order = [0, 2, 4, 6, 1, 3, 5, 7]
with zipfile.ZipFile(source, "r") as original:
	with zipfile.ZipFile(destination, "w") as configured:
		project = None
		for entry in original.infolist():
			if entry.filename == "data.json":
				project = json.loads(original.read(entry.filename))
				break
		if project is None:
			raise SystemExit("Il progetto Pixelorama non contiene data.json")
		if len(project["frames"]) != 2:
			raise SystemExit("Il PXO deve contenere due frame idle")
		layer_indices = {layer["name"].strip().upper(): index for index, layer in enumerate(project["layers"])}
		if set(layer_indices) != set(directions) or len(project["layers"]) != len(directions):
			raise SystemExit("Il PXO deve contenere i layer DOWN, LEFT, TOP e RIGHT")
		frame_sources = []
		frames = []
		for direction in directions:
			layer_index = layer_indices[direction]
			for source_frame_index, source_frame in enumerate(project["frames"], 1):
				frames.append(
					{
						"cels": [copy.deepcopy(source_frame["cels"][layer_index])],
						"duration": source_frame["duration"],
						"metadata": copy.deepcopy(source_frame.get("metadata", {})),
						"user_data": f"{direction}: {source_frame.get('user_data', '')}",
					}
				)
				frame_sources.append((source_frame_index, layer_index + 1))
		project["frames"] = [frames[index] for index in column_major_order]
		project["layers"] = [copy.deepcopy(project["layers"][layer_indices["DOWN"]])]
		project["layers"][0]["name"] = "Jerv - sprite sheet"
		project["current_frame"] = 0
		project["current_layer"] = 0
		project["tags"] = []
		profile = project["export_profile"]
		profile.update(
			{
				"directory_path": json.dumps(output_dir),
				"file_name": json.dumps("jerv-tgrc-topdown-sheet"),
				"file_format": "0",
				"current_tab": "1",
				"orientation": "0",
				"lines_count": "4",
				"number_of_frames": "8",
				"frame_current_tag": "0",
				"export_layers": "0",
				"resize": "100",
				"split_layers": "false",
				"sheet_layers_as_separate_files": "false",
			}
		)
		for entry in original.infolist():
			if entry.filename.startswith("image_data/frames/"):
				continue
			data = original.read(entry.filename)
			if entry.filename == "data.json":
				data = json.dumps(project, separators=(",", ":")).encode("utf-8")
			configured.writestr(entry, data)
		for output_frame, ordered_index in enumerate(column_major_order, 1):
			source_frame, source_layer = frame_sources[ordered_index]
			image_name = f"image_data/frames/{source_frame}/layer_{source_layer}"
			indices_name = f"image_data/frames/{source_frame}/indices_layer_{source_layer}"
			configured.writestr(f"image_data/frames/{output_frame}/layer_1", original.read(image_name))
			configured.writestr(
				f"image_data/frames/{output_frame}/indices_layer_1", original.read(indices_name)
			)
PY

"$PIXELORAMA_BIN" --headless --quit-after 60 -- --export --spritesheet "$temporary_pxo"

/usr/bin/python3 - "$OUTPUT_PNG" <<'PY'
import struct
import sys

path = sys.argv[1]
with open(path, "rb") as image:
	header = image.read(24)
if header[:8] != b"\x89PNG\r\n\x1a\n":
	raise SystemExit(f"Export non valido: {path} non è una PNG")
size = struct.unpack(">II", header[16:24])
if size != (64, 128):
	raise SystemExit(f"Dimensioni inattese per la sprite sheet: {size[0]}x{size[1]} (atteso 64x128)")
PY

cp "$OUTPUT_PNG" "$GODOT_PNG"
printf 'Esportata %s (64x128, 4 direzioni con due frame idle ciascuna)\n' "$OUTPUT_PNG"
printf 'Aggiornata copia Godot: %s\n' "$GODOT_PNG"
