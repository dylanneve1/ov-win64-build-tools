#!/bin/bash

# ============================================================
# Clone both OpenVINO and OpenVINO GenAI repositories
# ============================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "=========================================="
echo "  Cloning all repositories"
echo "=========================================="
echo ""

"$SCRIPT_DIR/clone-openvino.sh"
if [ $? -ne 0 ]; then
    echo ""
    echo "=========================================="
    echo "  ERROR: Failed to clone OpenVINO"
    echo "=========================================="
    exit 1
fi

echo ""

"$SCRIPT_DIR/clone-openvino-genai.sh"
if [ $? -ne 0 ]; then
    echo ""
    echo "=========================================="
    echo "  ERROR: Failed to clone OpenVINO GenAI"
    echo "=========================================="
    exit 1
fi

echo ""
echo "=========================================="
echo "  All repositories cloned successfully  ✓"
echo "=========================================="
echo ""
echo "Next step: Install OpenVINO-specific dependencies"
echo ""
echo "Run:"
echo "  cd openvino"
echo "  sudo ./install_build_dependencies.sh"
echo "  touch .deps_installed"
echo "  cd .."
echo ""

exit 0
