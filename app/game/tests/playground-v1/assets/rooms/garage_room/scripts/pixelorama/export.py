#!/usr/bin/env python3
"""Export the garage room's simple Pixelorama PXO sources as PNG files.

The source files are Pixelorama v7 projects with one RGBA raster layer. Static
projects export one PNG. Animated projects export the first frame to the
asset's default PNG path and each tagged frame to a named PNG as well.
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


def read_source(path: Path) -> tuple[int, int, list[bytes], list[dict]]:
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
            if len(layers) != 1 or not frames:
                raise ValueError("expected exactly one layer and at least one frame")

            layer = layers[0]
            if (
                layer.get("type") != 0
                or not layer.get("visible", False)
                or layer.get("opacity", 1.0) != 1.0
                or layer.get("blend_mode", 0) != 0
                or layer.get("effects", [])
            ):
                raise ValueError(
                    "expected one visible, full-opacity raster layer without effects"
                )

            width = int(metadata["size_x"])
            height = int(metadata["size_y"])
            frame_pixels: list[bytes] = []
            for frame_index, frame in enumerate(frames, start=1):
                cel_list = frame.get("cels", [])
                if len(cel_list) != 1 or cel_list[0].get("opacity", 1.0) != 1.0:
                    raise ValueError(
                        "expected one full-opacity raster cel in every frame"
                    )
                frame_pixels.append(
                    project.read(f"image_data/frames/{frame_index}/layer_1")
                )
            tags = metadata.get("tags", [])
    except (BadZipFile, KeyError, json.JSONDecodeError) as error:
        raise ValueError(f"invalid or unsupported Pixelorama project: {error}") from error

    expected_size = width * height * 4
    if (
        width <= 0
        or height <= 0
        or any(len(pixels) != expected_size for pixels in frame_pixels)
    ):
        raise ValueError("expected full-canvas RGBA8 pixel layers")

    for tag in tags:
        if (
            not isinstance(tag, dict)
            or not isinstance(tag.get("name"), str)
            or not tag["name"].strip()
            or not isinstance(tag.get("from"), int)
            or not isinstance(tag.get("to"), int)
            or tag["from"] < 1
            or tag["to"] < tag["from"]
            or tag["to"] > len(frame_pixels)
        ):
            raise ValueError("expected valid frame tags within the project timeline")
    return width, height, frame_pixels, tags


def tagged_frame_name(source: Path, frame_number: int, tags: list[dict]) -> str:
    for tag in tags:
        if tag["from"] <= frame_number <= tag["to"]:
            name = "".join(
                character if character.isalnum() or character in "-_" else "_"
                for character in tag["name"].strip()
            )
            suffix = f"-{name}"
            if tag["from"] != tag["to"]:
                suffix += f"-{frame_number:02d}"
            return f"{source.stem}{suffix}.png"
    return f"{source.stem}-frame-{frame_number:02d}.png"


def main() -> int:
    sources = sorted(SOURCE_DIR.glob("*.pxo"))
    if not sources:
        print(f"Nessun file .pxo trovato in {SOURCE_DIR}", file=sys.stderr)
        return 1

    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    for source in sources:
        try:
            width, height, frames, tags = read_source(source)
            destination = EXPORT_DIR / f"{source.stem}.png"
            write_png(destination, width, height, frames[0])
            print(f"Esportato {source.name} -> {destination.name} ({width}x{height})")

            if len(frames) > 1:
                for frame_number, pixels in enumerate(frames, start=1):
                    tagged_destination = EXPORT_DIR / tagged_frame_name(
                        source, frame_number, tags
                    )
                    write_png(tagged_destination, width, height, pixels)
                    print(
                        f"Esportato frame {frame_number} -> "
                        f"{tagged_destination.name} ({width}x{height})"
                    )
        except (OSError, ValueError) as error:
            print(f"Errore nell'export di {source.name}: {error}", file=sys.stderr)
            return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
