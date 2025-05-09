#!/usr/bin/env bash

set -euo pipefail

# Very simple installation script that doesn't depend on dependencies being installed

echo "Running simplified installation process..."

# Check if clean was requested
if [ "${1:-}" = "clean" ]; then
  echo "Cleaning previous installation..."
  rm -rf node_modules
  rm -rf .yarn/cache
  rm -rf .yarn/install-state.gz
  rm -rf build/relsize/mvp
  rm -rf build/relsize/eh
  rm -rf build/relsize/coi
  exit 0
fi

# First check if emscripten is installed
if ! command -v emcc &> /dev/null; then
    echo "Error: Emscripten not found. Please install Emscripten first."
    echo "Visit https://emscripten.org/docs/getting_started/downloads.html for instructions."
    exit 1
fi

# Create necessary build directories
mkdir -p packages/duckdb-wasm/src/bindings
mkdir -p build/relsize/mvp
mkdir -p build/relsize/eh
mkdir -p build/relsize/coi

echo "Building all required WASM variants..."

# Build the different WASM variants directly
echo "Building MVP variant..."
./scripts/wasm_build_lib.sh relsize mvp

echo "Building EH variant..."
./scripts/wasm_build_lib.sh relsize eh

echo "Building COI variant..."
./scripts/wasm_build_lib.sh relsize coi

# Install TypeScript globally
echo "Installing TypeScript globally..."
npm install -g typescript

# Install remaining JS dependencies with increased memory
echo "Installing remaining dependencies with basic yarn install..."
NODE_OPTIONS="--max-old-space-size=8192" yarn install || echo "Yarn install had issues, but we will continue since we built the WASM files directly"

echo "All required WASM variants have been built."
echo "You can now proceed with make serve_local or another make target" 
