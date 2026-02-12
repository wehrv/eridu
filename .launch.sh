#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

export COMPOSE_BAKE=false

# Git operations (commit, push, first-run repo setup)
~/apps/.launch.sh --git-only "${1:-}"

# Fetch latest stable versions
GO_VERSION=$(curl -fsSL 'https://go.dev/dl/?mode=json' | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['version'])")

PYTHON_VERSION=$(curl -fsSL 'https://endoflife.date/api/python.json' | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['latest'])")

RUST_VERSION=$(curl -fsSL 'https://static.rust-lang.org/dist/channel-rust-stable.toml' | python3 -c "
import sys, re
m = re.search(r'\[pkg\.rust\]\nversion = \"([^ \"]+)', sys.stdin.read())
print(m.group(1))
")

NODE_VERSION=$(curl -fsSL 'https://nodejs.org/dist/index.json' | python3 -c "
import sys, json
for r in json.load(sys.stdin):
    if r.get('lts'):
        print(r['version'])
        break
")

echo "Go:     $GO_VERSION"
echo "Python: $PYTHON_VERSION"
echo "Rust:   $RUST_VERSION"
echo "Node:   $NODE_VERSION (LTS)"

# Build the image
GO_VERSION="$GO_VERSION" \
PYTHON_VERSION="$PYTHON_VERSION" \
RUST_VERSION="$RUST_VERSION" \
NODE_VERSION="$NODE_VERSION" \
docker-compose build

echo "Built infra-eridu:latest"
