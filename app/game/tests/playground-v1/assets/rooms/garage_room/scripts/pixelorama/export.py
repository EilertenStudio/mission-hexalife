#!/usr/bin/env python3
"""Export the garage room's simple Pixelorama PXO sources as PNG files.

The source files are Pixelorama v7 projects with one RGBA raster layer and one
frame. The exporter deliberately rejects other project layouts rather than
silently producing an image that differs from what Pixelorama would render.
"""

from __future__ import annotations

import json
import struct
import sys
import zlib
from pathlib import Path
from zipfile import BadZipFile, ZipFile


SOURCE_DIR = Path(__file__).resolve().parent
EXPORT_DIR = SOURCE_DIR.parent.parent / "exports"


def png_chunk(kind: bytes, data: bytes) -> bytes:
    content = kind + data
    return (
        struct.pack(">I", len(data))
        + content
        + struct.pack(">I", zlib.crc32(content) & 0xFFFFFFFF)
    )


def write_png(path: Path, width: int, height: int, rgba: bytes) -> None:
    if len(rgba) != width * height * 4:
        raise ValueError(
            f"pixel data has {len(rgba)} bytes; expected {width * height * 4}"
        )

    scanlines = b"".join(
        b"\x00" + rgba[row * width * 4 : (row + 1) * width * 4]
        for row in range(height)
    )
    png = (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + png_chunk(b"IDAT", zlib.compress(scanlines, level=9))
        + png_chunk(b"IEND", b"")
    )
    temporary_path = path.with_suffix(path.suffix + ".tmp")
    temporary_path.write_bytes(png)
    temporary_path.replace(path)


def read_source(path: Path) -> tuple[int, int, bytes]:
    try:
        with ZipFile(path) as project:
            metadata = json.loads(project.read("data.json"))
            if metadata.get("pxo_version") != 7:
                raise ValueError(
                    f"unsupported PXO version {metadata.get('pxo_version')!r}; "
                    "this exporter supports version 7"
                )

            layers = metadata.get("layers", [])
            frames = metadata.get("frames", [])
            if len(layers) != 1 or len(frames) != 1:
                raise ValueError("expected exactly one layer and one frame")

            layer = layers[0]
            cel_list = frames[0].get("cels", [])
            if (
                layer.get("type") != 0
                or not layer.get("visible", False)
                or layer.get("opacity", 1.0) != 1.0
                or layer.get("blend_mode", 0) != 0
                or layer.get("effects", [])
                or len(cel_list) != 1
                or cel_list[0].get("opacity", 1.0) != 1.0
            ):
                raise ValueError(
                    "expected one visible, full-opacity raster layer without effects"
                )

            width = int(metadata["size_x"])
            height = int(metadata["size_y"])
            pixels = project.read("image_data/frames/1/layer_1")
    except (BadZipFile, KeyError, json.JSONDecodeError) as error:
        raise ValueError(f"invalid or unsupported Pixelorama project: {error}") from error

    if width <= 0 or height <= 0 or len(pixels) != width * height * 4:
        raise ValueError("expected a full-canvas RGBA8 pixel layer")
    return width, height, pixels


def main() -> int:
    sources = sorted(SOURCE_DIR.glob("*.pxo"))
    if not sources:
        print(f"Nessun file .pxo trovato in {SOURCE_DIR}", file=sys.stderr)
        return 1

    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    for source in sources:
        try:
            width, height, pixels = read_source(source)
            destination = EXPORT_DIR / f"{source.stem}.png"
            write_png(destination, width, height, pixels)
        except (OSError, ValueError) as error:
            print(f"Errore nell'export di {source.name}: {error}", file=sys.stderr)
            return 1
        print(f"Esportato {source.name} -> {destination.name} ({width}x{height})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
