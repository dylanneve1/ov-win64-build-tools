#!/bin/bash

# ============================================================
# Build OpenVINO + OpenVINO.GenAI (Ninja) and package
# Assumes this script is in scripts/ subfolder with:
#   ../openvino/
#   ../openvino.genai/
# Usage:
#   ninja-build.sh [--help]
#   ninja-build.sh [--jobs N]
# ============================================================

set -e  # Exit on error

# -------------------------------
# Help handling
# -------------------------------
if [[ "$*" == *"--help"* ]] || [[ "$*" == *"-h"* ]]; then
    cat << EOF

============================================================
ninja-build.sh - Build OpenVINO + OpenVINO.GenAI
============================================================

Location assumptions:
  - This script is in scripts/ subfolder with parent containing:
      ../openvino/
      ../openvino.genai/

Usage:
  ninja-build.sh [--help]
  ninja-build.sh [--jobs N]

Options:
  --jobs N    Number of parallel jobs (default: number of CPU cores)
  --help      Show this help message

Examples:
  ./ninja-build.sh
  ./ninja-build.sh --jobs 8

EOF
    exit 0
fi

# --- Parse arguments ---
PARALLEL_JOBS=$(nproc)
while [[ $# -gt 0 ]]; do
    case $1 in
        --jobs)
            PARALLEL_JOBS="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# --- Root directory (parent of scripts folder) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Repo locations ---
OV_SRC="$ROOT/openvino"
GENAI_SRC="$ROOT/openvino.genai"

# --- Build directories ---
OV_BUILD="$OV_SRC/build-ninja"
GENAI_BUILD="$GENAI_SRC/build-ninja"

# --- Install directory ---
OV_INSTALL="$OV_BUILD/install"

# --- OpenVINO Developer Package directory ---
OV_DEVPKG_DIR="$OV_BUILD"

# --- Artifacts Directory ---
ARTIFACTS_DIR="$ROOT/artifacts"

# --- Sanity checks ---
if [ ! -f "$OV_SRC/CMakeLists.txt" ]; then
    echo "ERROR: OpenVINO repo not found at $OV_SRC"
    echo "Please run: ./scripts/clone-all.sh first"
    exit 1
fi

if [ ! -f "$GENAI_SRC/CMakeLists.txt" ]; then
    echo "ERROR: openvino.genai repo not found at $GENAI_SRC"
    echo "Please run: ./scripts/clone-all.sh first"
    exit 1
fi

# Check if OpenVINO dependencies are installed
if [ ! -f "$OV_SRC/.deps_installed" ]; then
    echo ""
    echo "=========================================="
    echo "  WARNING: OpenVINO dependencies may not be installed"
    echo "=========================================="
    echo ""
    echo "For first-time setup, run:"
    echo "  cd $OV_SRC"
    echo "  sudo ./install_build_dependencies.sh"
    echo "  touch .deps_installed"
    echo "  cd -"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "============================================================"
echo "Paths"
echo "============================================================"
echo "ROOT          = $ROOT"
echo "OV_SRC        = $OV_SRC"
echo "OV_BUILD      = $OV_BUILD"
echo "OV_INSTALL    = $OV_INSTALL"
echo "OV_DEVPKG     = $OV_DEVPKG_DIR"
echo "GENAI_SRC     = $GENAI_SRC"
echo "GENAI_BUILD   = $GENAI_BUILD"
echo "ARTIFACTS_DIR = $ARTIFACTS_DIR"
echo "PARALLEL_JOBS = $PARALLEL_JOBS"
echo "============================================================"

# --- Optional python venv activation ---
if [ -f "$ROOT/build-env/bin/activate" ]; then
    echo ""
    echo "============================================================"
    echo "Activating Python venv..."
    echo "============================================================"
    source "$ROOT/build-env/bin/activate"
fi

echo ""
echo "============================================================"
echo "1) Configure + build OpenVINO..."
echo "============================================================"

mkdir -p "$OV_BUILD"
cd "$OV_BUILD"

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$OV_INSTALL" \
  -DENABLE_PLUGINS_XML=ON \
  -DENABLE_DEBUG_CAPS=ON \
  ..

cmake --build . --target install --parallel "$PARALLEL_JOBS"

echo ""
echo "============================================================"
echo "2) Configure + build OpenVINO.GenAI..."
echo "============================================================"

mkdir -p "$GENAI_BUILD"
cd "$GENAI_BUILD"

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$OV_INSTALL" \
  -DOpenVINODeveloperPackage_DIR="$OV_DEVPKG_DIR" \
  ..

cmake --build . --target install --parallel "$PARALLEL_JOBS"

echo ""
echo "============================================================"
echo "3) Creating tarball..."
echo "============================================================"

mkdir -p "$ARTIFACTS_DIR"

# Get version info
cd "$OV_SRC"
OV_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
BUILD_DATE=$(date +%Y%m%d)

TARBALL_NAME="openvino-genai-linux-${OV_VERSION}-${BUILD_DATE}.tar.gz"
TARBALL_PATH="$ARTIFACTS_DIR/$TARBALL_NAME"

echo "Creating tarball: $TARBALL_NAME"
cd "$OV_INSTALL"
tar -czf "$TARBALL_PATH" .

echo ""
echo "============================================================"
echo "DONE: Build + install + package complete"
echo "Install path: $OV_INSTALL"
echo "Tarball:      $TARBALL_PATH"
echo "============================================================"

exit 0
