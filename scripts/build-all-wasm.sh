#!/usr/bin/env bash

set -euo pipefail

# Build script that ensures all necessary WASM variants are built
# particularly the COI variant which contains the worker.js files

echo "Building all WASM variants..."

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# First build the relsize variants which include optimizations for size
echo "Building relsize variants (MVP, EH, COI)..."
"${ROOT_DIR}/scripts/wasm_build_lib.sh" relsize mvp
"${ROOT_DIR}/scripts/wasm_build_lib.sh" relsize eh
"${ROOT_DIR}/scripts/wasm_build_lib.sh" relsize coi

echo "All WASM variants built successfully!"
echo "Verifying worker files exist..."

BINDINGS_DIR="${ROOT_DIR}/packages/duckdb-wasm/src/bindings"
COI_WORKER="${BINDINGS_DIR}/duckdb-coi.pthread.js"

if [ -f "$COI_WORKER" ]; then
  echo "✓ COI worker file exists at: ${COI_WORKER}"
else
  echo "❌ Error: COI worker file is missing at: ${COI_WORKER}"
  exit 1
fi

echo "All required files are present!"
echo "You can now proceed with 'yarn workspace @duckdb/duckdb-wasm build:debug' or 'yarn workspace @duckdb/duckdb-wasm build:release'" 
