#!/bin/bash
echo "========================================"
echo "  Ample - Linux Port Auto Launcher"
echo "========================================"

# --- First-Time Setup: Install system-level dependencies ---
if command -v apt &> /dev/null; then
    # libxcb-cursor0 is required by Qt/PySide6 on X11
    NEED_INSTALL=0
    for pkg in python3-full libxcb-cursor0; do
        if ! dpkg -s "$pkg" &> /dev/null 2>&1; then
            NEED_INSTALL=1
            break
        fi
    done

    if [ $NEED_INSTALL -eq 1 ]; then
        echo "[SETUP] Installing required system packages..."
        echo "  sudo apt install python3-full libxcb-cursor*"
        sudo apt install -y python3-full libxcb-cursor*
        if [ $? -ne 0 ]; then
            echo "[WARN] Some packages may have failed to install. Continuing anyway..."
        else
            echo "[SETUP] System packages installed successfully."
        fi
    fi
fi

# --- ALSA Audio Permission Fix ---
if [ -d /proc/asound ]; then
    if ! id -nG "$(whoami)" | grep -qw "audio"; then
        echo "[SETUP] ALSA audio system detected. Adding user to 'audio' group..."
        sudo usermod -a -G audio "$(whoami)"
        if [ $? -eq 0 ]; then
            echo "[SETUP] Added $(whoami) to 'audio' group. Please log out and back in for this to take effect."
        else
            echo "[WARN] Failed to add user to 'audio' group. Sound may not work properly."
        fi
    fi
fi

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo "[ERROR] Python 3 not found! Please install Python 3.9 or newer."
    echo "  Ubuntu/Debian: sudo apt install python3 python3-full"
    echo "  Fedora: sudo dnf install python3 python3-pip"
    echo "  Arch: sudo pacman -S python python-pip"
    exit 1
fi

# Navigate to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- Virtual Environment Setup ---
VENV_DIR=".venv"

# Ensure python3-venv is available
if ! python3 -m venv --help &> /dev/null; then
    echo "[INFO] python3-venv is required but not installed."
    if command -v apt &> /dev/null; then
        PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        echo "[INFO] Installing python3.${PY_VER}-venv ..."
        sudo apt install -y "python3.${PY_VER}-venv" python3-full
    else
        echo "[ERROR] Please install python3-venv for your distro and try again."
        exit 1
    fi
fi

# Recreate if venv is broken
if [ -d "$VENV_DIR" ] && [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "[WARN] Virtual environment is broken, recreating..."
    rm -rf "$VENV_DIR"
fi

# Create venv if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "[1/3] Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
else
    echo "[1/3] Virtual environment found."
fi

# Activate venv
source "$VENV_DIR/bin/activate"

# Install/Update dependencies
echo "[2/3] Checking dependencies..."
pip install -r requirements.txt --quiet 2>/dev/null

if [ $? -ne 0 ]; then
    echo "[WARN] pip install failed, retrying with upgrade..."
    pip install --upgrade pip --quiet 2>/dev/null
    pip install -r requirements.txt --quiet
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to install requirements."
        deactivate
        exit 1
    fi
fi

# Run the application
echo "[3/3] Launching Ample..."
python3 main.py

if [ $? -ne 0 ]; then
    echo ""
    echo "[INFO] Application exited with error."
    read -p "Press Enter to continue..."
fi

deactivate
