#!/usr/bin/env bash
#
# ruvector_server.sh — Start the RuVector HNSW vector database server
#
# RuVector (https://github.com/ruvnet/ruvector) is an open-source vector
# database written in Rust.  It provides HNSW (Hierarchical Navigable Small
# World) indexing with SIMD (Single Instruction, Multiple Data) acceleration
# and a self-learning GNN (Graph Neural Network) reranking layer.
#
# This script starts the RuVector server so the PrologAI bakeoff harness
# can use the 'ruvector' backend.
#
# After the server is running, open SWI-Prolog and run:
#   ?- use_module(library(bakeoff)).
#   ?- run_bakeoff([prolog, ruvector], [100, 1000]).
#
# Requirements:
#   - Rust toolchain (https://rustup.rs) must be installed
#   - This script will clone ruvector-server if not already present
#
# Usage:
#   bash packs/vector_backend/scripts/ruvector_server.sh [--port 8080]
#

set -euo pipefail

PORT="${1:-6333}"
RUVECTOR_DIR="${HOME}/.prologai/ruvector"
REPO_URL="https://github.com/ruvnet/ruvector"

echo "[ruvector] PrologAI RuVector Server Startup"
echo "[ruvector] Port: ${PORT}"
echo "[ruvector] Server directory: ${RUVECTOR_DIR}"
echo ""

# Create the ruvector directory if it does not exist.
if [ ! -d "${RUVECTOR_DIR}" ]; then
    echo "[ruvector] Cloning ruvector repository..."
    git clone "${REPO_URL}" "${RUVECTOR_DIR}"
else
    echo "[ruvector] Repository already present at ${RUVECTOR_DIR}"
fi

# Change into the ruvector-server crate directory.
cd "${RUVECTOR_DIR}/crates/ruvector-server" 2>/dev/null || cd "${RUVECTOR_DIR}"

echo "[ruvector] Building ruvector-server (this may take a few minutes on first run)..."
cargo build --release

# Locate the compiled binary.
BINARY=$(find "${RUVECTOR_DIR}/target/release" -maxdepth 1 -name "ruvector*" -type f 2>/dev/null | head -n1)

if [ -z "${BINARY}" ]; then
    echo "[ruvector] ERROR: Could not find compiled binary in ${RUVECTOR_DIR}/target/release"
    echo "[ruvector] Try: cd ${RUVECTOR_DIR} && cargo build --release"
    exit 1
fi

echo "[ruvector] Starting server: ${BINARY} --port ${PORT}"
echo "[ruvector] Press Ctrl+C to stop."
echo ""

# Start the RuVector server on the specified port.
exec "${BINARY}" --port "${PORT}"
