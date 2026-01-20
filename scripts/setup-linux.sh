#!/bin/bash

# ============================================================
# Setup build environment for Linux
# Installs all required dependencies for building OpenVINO
# ============================================================

set -e

echo ""
echo "=========================================="
echo "  OpenVINO Build Tools - Linux Setup"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "ERROR: Please run as normal user (not root)"
    echo "The script will use sudo when needed"
    exit 1
fi

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION=$VERSION_ID
else
    echo "ERROR: Cannot detect Linux distribution"
    exit 1
fi

echo "Detected: $PRETTY_NAME"
echo ""

# Install basic build dependencies
case $DISTRO in
    ubuntu|debian)
        echo "=========================================="
        echo "  Installing build dependencies..."
        echo "=========================================="
        sudo apt-get update
        sudo apt-get install -y \
            build-essential \
            cmake \
            ninja-build \
            git \
            wget \
            curl \
            ca-certificates \
            pkg-config \
            python3 \
            python3-pip \
            python3-venv \
            python3-dev \
            libpython3-dev \
            ccache
        ;;
    
    fedora|rhel|centos|rocky|almalinux)
        echo "=========================================="
        echo "  Installing build dependencies..."
        echo "=========================================="
        sudo dnf install -y \
            gcc \
            gcc-c++ \
            cmake \
            ninja-build \
            git \
            wget \
            curl \
            ca-certificates \
            pkgconfig \
            python3 \
            python3-pip \
            python3-devel \
            ccache
        ;;
    
    opensuse*|sles)
        echo "=========================================="
        echo "  Installing build dependencies..."
        echo "=========================================="
        sudo zypper install -y \
            gcc \
            gcc-c++ \
            cmake \
            ninja \
            git \
            wget \
            curl \
            ca-certificates \
            pkg-config \
            python3 \
            python3-pip \
            python3-devel \
            ccache
        ;;
    
    arch|manjaro)
        echo "=========================================="
        echo "  Installing build dependencies..."
        echo "=========================================="
        sudo pacman -Sy --noconfirm \
            base-devel \
            cmake \
            ninja \
            git \
            wget \
            curl \
            ca-certificates \
            pkg-config \
            python \
            python-pip \
            ccache
        ;;
    
    *)
        echo "WARNING: Unsupported distribution: $DISTRO"
        echo "Please install manually:"
        echo "  - build-essential / gcc/g++"
        echo "  - cmake (3.13+)"
        echo "  - ninja-build"
        echo "  - git"
        echo "  - python3 (3.9-3.12)"
        echo "  - python3-pip"
        echo "  - ccache (optional)"
        exit 1
        ;;
esac

# Verify installations
echo ""
echo "=========================================="
echo "  Verifying installations..."
echo "=========================================="

command -v cmake >/dev/null 2>&1 && echo "✓ cmake: $(cmake --version | head -n1)" || echo "✗ cmake not found"
command -v ninja >/dev/null 2>&1 && echo "✓ ninja: $(ninja --version)" || echo "✗ ninja not found"
command -v git >/dev/null 2>&1 && echo "✓ git: $(git --version)" || echo "✗ git not found"
command -v gcc >/dev/null 2>&1 && echo "✓ gcc: $(gcc --version | head -n1)" || echo "✗ gcc not found"
command -v g++ >/dev/null 2>&1 && echo "✓ g++: $(g++ --version | head -n1)" || echo "✗ g++ not found"
command -v python3 >/dev/null 2>&1 && echo "✓ python3: $(python3 --version)" || echo "✗ python3 not found"
command -v ccache >/dev/null 2>&1 && echo "✓ ccache: $(ccache --version | head -n1)" || echo "  ccache not found (optional)"

echo ""
echo "=========================================="
echo "  Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Clone repositories:  ./scripts/clone-all.sh"
echo "  2. Install OpenVINO-specific deps (after cloning):"
echo "     cd openvino && sudo ./install_build_dependencies.sh && cd .."
echo "  3. Build:  ./scripts/ninja-build.sh"
echo ""

exit 0
