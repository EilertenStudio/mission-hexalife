#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "$script_dir/.." && pwd)"
repo_root="$(cd -- "$project_dir/../.." && pwd)"
output_dir="$project_dir/dist/web"
port="${WEB_PORT:-8060}"
bind_address="${WEB_BIND:-0.0.0.0}"

export MISE_CACHE_DIR="$repo_root/.local/mise/cache"
export MISE_STATE_DIR="$repo_root/.local/mise/state"
export MISE_DATA_DIR="$repo_root/.local/mise/data"

if ! command -v mise >/dev/null 2>&1; then
	echo "Errore: mise non è installato o non è nel PATH." >&2
	exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
	echo "Errore: Python 3 è necessario per servire l'export Web." >&2
	exit 1
fi

echo "Compilo la storia Ink..."
mise -C "$repo_root/app/gamebook" run compile-godot

mkdir -p "$output_dir"
echo "Esporto il progetto Godot per Web..."
if ! mise -C "$project_dir" exec -- godot --headless --path "$project_dir" \
	--export-release Web "$output_dir/index.html"; then
	cat >&2 <<'EOF'
Export non riuscito. Controlla che i template di export Web di Godot 4.7.2
siano installati (Editor > Manage Export Templates) e che l'errore non segnali
risorse o script incompatibili con il target Web.
EOF
	exit 1
fi

lan_address="$(python3 -c 'import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.connect(("192.0.2.1", 1)); print(s.getsockname()[0]); s.close()' 2>/dev/null || true)"
if [[ -z "$lan_address" ]]; then
	lan_address="<IP-LAN-del-computer>"
fi

echo
echo "Export pronto. Apri sul computer di questa rete:"
echo "  http://$lan_address:$port/"
echo "Il server ascolta su $bind_address:$port. Premi Ctrl+C per fermarlo."
echo
cd "$output_dir"
exec python3 -m http.server "$port" --bind "$bind_address" --directory "$output_dir"
