#!/usr/bin/env bash
# Export PINGUDOT for the web into build/web (gitignored).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/web
# Keep Godot from importing the exported artifacts.
touch build/.gdignore
godot --headless --path . --export-release "Web" build/web/index.html
echo
echo "Web build ready: $(pwd)/build/web/index.html"
echo "Serve it with:  cd build/web && python3 -m http.server 8000"
echo "Then open:      http://localhost:8000"
