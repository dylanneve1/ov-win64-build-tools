# OpenVINO Build Tools

Cross-platform build scripts for OpenVINO and OpenVINO GenAI using Ninja.

Supports both **Windows** and **Linux**.

## Quick Start

### Linux - Complete Automated Setup

On a vanilla Linux installation, just run:

```bash
# Run automated setup (does everything!)
./linux/setup-linux.sh
```

This single command will:
1. Install all build dependencies (cmake, ninja, gcc, python, etc.)
2. Clone OpenVINO and OpenVINO GenAI repositories
3. Install OpenVINO-specific dependencies
4. Prepare your system for building

Then build:
```bash
./linux/ninja-build.sh
```

### Windows First-Time Setup

On Windows, ensure you have Visual Studio installed, then:

```batch
REM Clone repositories
windows\clone-all.bat

REM Build
windows\ninja-build.bat
```

## Manual Steps (Advanced Users)

### 1. Clone Repositories

**Windows:**
```batch
windows\clone-all.bat
```

**Linux:**
```bash
./linux/clone-all.sh
```

Or clone individually:

**Windows:**
```batch
windows\clone-openvino.bat
windows\clone-openvino-genai.bat
```

**Linux:**
```bash
./linux/clone-openvino.sh
./linux/clone-openvino-genai.sh
```

### 2. Build

**Windows:**
```batch
windows\ninja-build.bat
```

Build with custom tag for packaging:
```batch
windows\ninja-build.bat -Tag my-custom-tag
```

**Linux:**
```bash
./linux/ninja-build.sh
```

Build with specific number of parallel jobs:
```bash
./linux/ninja-build.sh --jobs 8
```

**Cross-compile for Windows on Linux:**
```bash
# Install MinGW-w64 first (if not already installed)
sudo apt-get install mingw-w64

# Cross-compile
./linux/ninja-build-windows.sh
```

### 3. Update

Pull latest changes from both repositories:

**Windows:**
```batch
windows\update-all.bat
```

**Linux:**
```bash
./linux/update-all.sh
```

## Scripts Overview

Scripts are organized by platform in separate folders:

### Linux Scripts (`linux/`)

| Script | Description |
|--------|-------------|
| `setup-linux.sh` | **ONE-COMMAND SETUP**: Installs dependencies, clones repos, prepares everything |
| `clone-all.sh` | Clone both OpenVINO and OpenVINO GenAI repositories |
| `clone-openvino.sh` | Clone OpenVINO repository only |
| `clone-openvino-genai.sh` | Clone OpenVINO GenAI repository only |
| `ninja-build.sh` | Build OpenVINO + GenAI for Linux and create tar.gz package |
| `ninja-build-windows.sh` | **Cross-compile** for Windows on Linux (using MinGW-w64) |
| `update-all.sh` | Update both repositories (git pull) |

### Windows Scripts (`windows/`)

| Script | Description |
|--------|-------------|
| `clone-all.bat` | Clone both OpenVINO and OpenVINO GenAI repositories |
| `clone-openvino.bat` | Clone OpenVINO repository only |
| `clone-openvino-genai.bat` | Clone OpenVINO GenAI repository only |
| `ninja-build.bat` | Build OpenVINO + GenAI using Ninja and create ZIP package |
| `ninja-pack.ps1` | PowerShell script for packaging builds |
| `update-all.bat` | Update both repositories (git pull) |

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

**Automated installation (RECOMMENDED):**
```bash
./linux/setup-linux.sh
```

This script automatically:
- Detects your Linux distribution
- Installs all required dependencies
- Clones both repositories
- Runs OpenVINO's `install_build_dependencies.sh`
- Prepares everything for building

**Supported distributions:**
- Ubuntu/Debian
- Fedora/RHEL/CentOS/Rocky/AlmaLinux
- openSUSE/SLES
- Arch/Manjaro

## Directory Structure

```
ov-build-tools/
├── linux/                 # Linux build scripts (.sh)
│   ├── setup-linux.sh     # Automated setup (ONE COMMAND!)
│   ├── clone-all.sh
│   ├── clone-openvino.sh
│   ├── clone-openvino-genai.sh
│   ├── ninja-build.sh
│   └── update-all.sh
├── windows/               # Windows build scripts (.bat, .ps1)
│   ├── clone-all.bat
│   ├── clone-openvino.bat
│   ├── clone-openvino-genai.bat
│   ├── ninja-build.bat
│   ├── ninja-pack.ps1
│   └── update-all.bat
├── openvino/              # OpenVINO source (after cloning)
└── openvino.genai/        # OpenVINO GenAI source (after cloning)
```

## Platform-Specific Notes

### Windows
- Uses Visual Studio compiler (vcvars64.bat)
- Supports ccache for faster rebuilds (configure path in ninja-build.bat)
- **Cross-compilation**: Can build Windows binaries using MinGW-w64 (`ninja-build-windows.sh`)
- Packages builds as ZIP archives
- Optional: Python virtual environment at `build-env\Scripts\activate.bat`

### Linux
- Uses GCC compiler
- Packages builds as tar.gz archives
- Optional: Python virtual environment at `build-env/bin/activate`
- **Automated setup available**: Run `./linux/setup-linux.sh` for complete one-command setup
- Supports Ubuntu, Debian, Fedora, RHEL, CentOS, Rocky, AlmaLinux, openSUSE, SLES, Arch, and Manjaro
