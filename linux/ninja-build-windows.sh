#!/bin/bash

# ============================================================
# Cross-compile OpenVINO + OpenVINO.GenAI for Windows on Linux
# Uses MinGW-w64 toolchain
# ============================================================

set -e

# --- Help handling ---
if [[ "$*" == *"--help"* ]] || [[ "$*" == *"-h"* ]]; then
    cat << EOF

============================================================
ninja-build-windows.sh - Cross-compile for Windows on Linux
============================================================

This script cross-compiles OpenVINO for Windows using MinGW-w64.

Requirements:
  - MinGW-w64 toolchain
  - wine (optional, for testing)

Install on Ubuntu/Debian:
  sudo apt-get install mingw-w64 cmake ninja-build

Usage:
  ./ninja-build-windows.sh [--help]
  ./ninja-build-windows.sh [--jobs N]

Options:
  --jobs N    Number of parallel jobs (default: number of CPU cores)
  --help      Show this help message

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

# --- Root directory (parent of linux folder) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Repo locations ---
OV_SRC="$ROOT/openvino"
GENAI_SRC="$ROOT/openvino.genai"

# --- Build directories ---
OV_BUILD="$OV_SRC/build-windows"
GENAI_BUILD="$GENAI_SRC/build-windows"

# --- Install directory ---
OV_INSTALL="$OV_BUILD/install"

# --- OpenVINO Developer Package directory ---
OV_DEVPKG_DIR="$OV_BUILD"

# --- Artifacts Directory ---
ARTIFACTS_DIR="$ROOT/artifacts"

echo ""
echo "============================================================"
echo "Cross-compiling OpenVINO for Windows on Linux"
echo "============================================================"
echo ""

# Check for MinGW-w64
if ! command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
    echo "ERROR: MinGW-w64 not found"
    echo ""
    echo "Install it with:"
    echo "  Ubuntu/Debian: sudo apt-get install mingw-w64 cmake ninja-build"
    echo "  Fedora/RHEL:   sudo dnf install mingw64-gcc mingw64-gcc-c++ cmake ninja-build"
    echo "  Arch:          sudo pacman -S mingw-w64-gcc cmake ninja"
    exit 1
fi

# --- Sanity checks ---
if [ ! -f "$OV_SRC/CMakeLists.txt" ]; then
    echo "ERROR: OpenVINO repo not found at $OV_SRC"
    echo "Please run: ./linux/clone-all.sh first"
    exit 1
fi

if [ ! -f "$GENAI_SRC/CMakeLists.txt" ]; then
    echo "ERROR: openvino.genai repo not found at $GENAI_SRC"
    echo "Please run: ./linux/clone-all.sh first"
    exit 1
fi

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
echo "TOOLCHAIN     = MinGW-w64 (x86_64-w64-mingw32)"
echo "============================================================"

echo ""
echo "============================================================"
echo "1) Configure + build OpenVINO for Windows..."
echo "============================================================"

mkdir -p "$OV_BUILD"
cd "$OV_BUILD"

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$OV_INSTALL" \
  -DCMAKE_TOOLCHAIN_FILE="$OV_SRC/cmake/toolchains/mingw64.toolchain.cmake" \
  -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
  -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
  -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DENABLE_PLUGINS_XML=ON \
  ..

cmake --build . --target install --parallel "$PARALLEL_JOBS"

echo ""
echo "============================================================"
echo "2) Configure + build OpenVINO.GenAI for Windows..."
echo "============================================================"

mkdir -p "$GENAI_BUILD"
cd "$GENAI_BUILD"

cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$OV_INSTALL" \
  -DCMAKE_TOOLCHAIN_FILE="$OV_SRC/cmake/toolchains/mingw64.toolchain.cmake" \
  -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
  -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
  -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DOpenVINODeveloperPackage_DIR="$OV_DEVPKG_DIR" \
  ..

cmake --build . --target install --parallel "$PARALLEL_JOBS"

echo ""
echo "============================================================"
echo "3) Creating ZIP archive..."
echo "============================================================"

mkdir -p "$ARTIFACTS_DIR"

# Get version info
cd "$OV_SRC"
OV_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
BUILD_DATE=$(date +%Y%m%d)

ZIP_NAME="openvino-genai-windows-${OV_VERSION}-${BUILD_DATE}-mingw64.zip"
ZIP_PATH="$ARTIFACTS_DIR/$ZIP_NAME"

echo "Creating ZIP: $ZIP_NAME"
cd "$OV_INSTALL"
zip -r "$ZIP_PATH" . -q

echo ""
echo "============================================================"
echo "DONE: Cross-compile complete!"
echo "Install path: $OV_INSTALL"
echo "ZIP archive:  $ZIP_PATH"
echo "============================================================"
echo ""
echo "NOTE: Built with MinGW-w64 toolchain"
echo "To test on Linux, you can use Wine:"
echo "  wine $OV_INSTALL/bin/hello_query_device.exe"
echo ""

exit 0
