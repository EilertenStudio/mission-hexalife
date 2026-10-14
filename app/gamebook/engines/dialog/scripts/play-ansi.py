#!/usr/bin/env python3
"""Run Dialog and remap its ANSI palette to Missione Hexalife's Ink palette."""

import re
import subprocess
import sys


BASE_NARRATIVE = b"\x1b[38;5;110m"
INPUT_COMMAND = b"\x1b[38;5;220m"
COLOR_MAP = {
    b"\x1b[38;2;181;169;38m": b"\x1b[38;5;208m",  # Capitano
    b"\x1b[38;2;191;28;191m": b"\x1b[38;5;212m",  # Primo Ufficiale
    b"\x1b[38;2;24;170;73m": b"\x1b[38;5;79m",  # Medico
    b"\x1b[38;2;99;97;234m": b"\x1b[38;5;141m",  # Scienziato
    b"\x1b[38;2;242;242;242m": b"\x1b[38;5;230m",  # Ingegnere
    b"\x1b[38;2;33;186;186m": b"\x1b[38;5;51m",  # QC
    b"\x1b[38;2;223;32;80m": b"\x1b[38;5;196m",  # Allarme
    b"\x1b[38;2;38;38;38m": b"\x1b[38;5;245m",  # Stato attenuato
}
SGR = re.compile(rb"\x1b\[[0-9;]*m")
RESET = b"\x1b[0m"
DEFAULT_FG = b"\x1b[39m"


def remap(data: bytes) -> bytes:
    def replace(match: re.Match[bytes]) -> bytes:
        sequence = match.group(0)
        if sequence in COLOR_MAP:
            return COLOR_MAP[sequence]
        if sequence in (RESET, DEFAULT_FG):
            return (RESET if sequence == RESET else b"") + BASE_NARRATIVE
        return sequence

    remapped = SGR.sub(replace, data)
    # Bold green marks available actions; plain green remains the Doctor's color.
    remapped = remapped.replace(
        b"\x1b[1m\x1b[38;5;79m", b"\x1b[1m\x1b[38;5;82m"
    )
    return remapped


def write_game_output(data: bytes) -> None:
    """Write output and color the prompt so the terminal echoes input in amber."""
    prompt = b"> "
    at = data.rfind(prompt)
    if at >= 0 and at + len(prompt) == len(data):
        sys.stdout.buffer.write(remap(data[: at + len(prompt)]) + INPUT_COMMAND)
    else:
        sys.stdout.buffer.write(remap(data))
    sys.stdout.buffer.flush()


def main() -> int:
    if len(sys.argv) < 2:
        print("Uso: play-ansi.py <comando> [argomenti...]", file=sys.stderr)
        return 2

    process = subprocess.Popen(
        sys.argv[1:], stdin=None, stdout=subprocess.PIPE, stderr=None, bufsize=0
    )
    pending = b""
    assert process.stdout is not None

    while chunk := process.stdout.read(4096):
        pending += chunk
        last_escape = pending.rfind(b"\x1b[")
        if last_escape >= 0 and b"m" not in pending[last_escape:]:
            ready, pending = pending[:last_escape], pending[last_escape:]
        else:
            ready, pending = pending, b""
        write_game_output(ready)

    if pending:
        write_game_output(pending)
    return_code = process.wait()
    sys.stdout.buffer.write(RESET)
    sys.stdout.buffer.flush()
    return return_code


if __name__ == "__main__":
    raise SystemExit(main())
