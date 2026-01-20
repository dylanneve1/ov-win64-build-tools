# OpenVINO Build Tools

Cross-platform build scripts for OpenVINO and OpenVINO GenAI using Ninja.

Supports both **Windows** and **Linux**.

## Quick Start

### Linux First-Time Setup

On a vanilla Linux installation, start here:

```bash
# 1. Make scripts executable
chmod +x scripts/*.sh

# 2. Install build dependencies (cmake, ninja, gcc, python, etc.)
./scripts/setup-linux.sh

# 3. Clone repositories
./scripts/clone-all.sh

# 4. Install OpenVINO-specific dependencies
cd openvino
sudo ./install_build_dependencies.sh
touch .deps_installed
cd ..

# 5. Build
./scripts/ninja-build.sh
```

### Windows First-Time Setup

On Windows, ensure you have Visual Studio installed, then:

```batch
REM 1. Clone repositories
scripts\clone-all.bat

REM 2. Build
scripts\ninja-build.bat
```

### 1. Clone Repositories

**Windows:**
```batch
scripts\clone-all.bat
```

**Linux:**
```bash
./scripts/clone-all.sh
```

Or clone individually:

**Windows:**
```batch
scripts\clone-openvino.bat
scripts\clone-openvino-genai.bat
```

**Linux:**
```bash
./scripts/clone-openvino.sh
./scripts/clone-openvino-genai.sh
```

### 2. Build

**Windows:**
```batch
scripts\ninja-build.bat
```

Build with custom tag for packaging:
```batch
scripts\ninja-build.bat -Tag my-custom-tag
```

**Linux:**
```bash
./scripts/ninja-build.sh
```

Build with specific number of parallel jobs:
```bash
./scripts/ninja-build.sh --jobs 8
```

### 3. Update

Pull latest changes from both repositories:

**Windows:**
```batch
scripts\update-all.bat
```

**Linux:**
```bash
./scripts/update-all.sh
```

## Scripts Overview

All scripts are located in the `scripts/` folder:

| Script | Platform | Description |
|--------|----------|-------------|
| `setup-linux.sh` | Linux | Install all build dependencies (run first on vanilla Linux) |
| `clone-all.bat/sh` | Win/Linux | Clone both OpenVINO and OpenVINO GenAI repositories |
| `clone-openvino.bat/sh` | Win/Linux | Clone OpenVINO repository only |
| `clone-openvino-genai.bat/sh` | Win/Linux | Clone OpenVINO GenAI repository only |
| `ninja-build.bat/sh` | Win/Linux | Build OpenVINO + GenAI using Ninja and package |
| `ninja-pack.ps1` | Windows | PowerShell script for packaging builds (Windows only) |
| `update-all.bat/sh` | Win/Linux | Update both repositories (git pull) |

## Requirements

### Windows
- Git
- CMake 3.13 or higher
- Ninja
- Visual Studio 2019 or later (with C++ tools)
- Python 3.9-3.12 (optional, for virtual environment)
- ccache (optional, for faster rebuilds)

### Linux
- Git
- CMake 3.13 or higher
- Ninja
- GCC 7.5 or higher
- Python 3.9-3.12 (optional, for virtual environment)
- ccache (optional, for faster rebuilds)

**Automated installation:**
```bash
./scripts/setup-linux.sh
```

This script automatically detects your Linux distribution and installs all required dependencies for:
- Ubuntu/Debian
- Fedora/RHEL/CentOS/Rocky/AlmaLinux
- openSUSE/SLES
- Arch/Manjaro

**Manual installation (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake ninja-build git python3 python3-pip ccache

# After cloning OpenVINO:
cd openvino
sudo ./install_build_dependencies.sh
```

## Directory Structure

After cloning:
```
ov-build-tools/
├── openvino/              # OpenVINO source
├── openvino.genai/        # OpenVINO GenAI source
└── scripts/               # All build scripts
    ├── clone-all.bat/sh
    ├── clone-openvino.bat/sh
    ├── clone-openvino-genai.bat/sh
    ├── ninja-build.bat/sh
    ├── ninja-pack.ps1     # Windows only
    └── update-all.bat/sh
```

## Platform-Specific Notes

### Windows
- Uses Visual Studio compiler (vcvars64.bat)
- Supports ccache for faster rebuilds (configure path in ninja-build.bat)
- Packages builds as ZIP archives
- Optional: Python virtual environment at `build-env\Scripts\activate.bat`

### Linux
- Uses GCC compiler
- Packages builds as tar.gz archives
- Optional: Python virtual environment at `build-env/bin/activate`
- Make scripts executable on first use: `chmod +x scripts/*.sh`
- Run `setup-linux.sh` first on vanilla installations to install all dependencies
- Supports Ubuntu, Debian, Fedora, RHEL, CentOS, Rocky, AlmaLinux, openSUSE, SLES, Arch, and Manjaro
