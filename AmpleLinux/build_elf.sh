#!/bin/bash
# build_elf.sh — Build standalone Linux binary for AmpleLinux using PyInstaller
set -e

cd "$(dirname "${BASH_SOURCE[0]}")"
echo "[AmpleLinux] Building standalone Linux binary..."

# --- Step 0: Ensure python3-venv is available ---
if ! python3 -m venv --help &> /dev/null; then
    echo "[INFO] python3-venv is required but not installed."
    if command -v apt &> /dev/null; then
        PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        echo "[INFO] Installing python3.${PY_VER}-venv ..."
        sudo apt install -y "python3.${PY_VER}-venv" python3-full
        if [ $? -ne 0 ]; then
            echo "[ERROR] Failed to install python3-venv. Please run manually:"
            echo "  sudo apt install python3-venv python3-full"
            exit 1
        fi
    else
        echo "[ERROR] Please install python3-venv for your distro and try again."
        exit 1
    fi
fi

# --- Step 1: Create/Activate virtual environment ---
VENV_DIR=".build_venv"
# Recreate if venv is broken (missing activate script)
if [ -d "$VENV_DIR" ] && [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "[WARN] Build venv is broken, recreating..."
    rm -rf "$VENV_DIR"
fi
if [ ! -d "$VENV_DIR" ]; then
    echo "[INFO] Creating build virtual environment..."
    python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"
echo "[INFO] Using Python: $(which python3)"

# --- Step 2: Install build dependencies + app dependencies in venv ---
echo "[INFO] Installing build dependencies..."
pip install --quiet pyinstaller Pillow
pip install --quiet -r requirements.txt

# --- Step 3: Generate Application Icons ---
echo ""
echo "[0/2] Generating Application Icons..."
python3 make_icon.py

# --- Step 4: Build with PyInstaller ---
echo ""
echo "[1/2] Converting main.py to Linux binary..."

ICON_PATH="ample.png"
ICON_ARG=""
if [ -f "$ICON_PATH" ]; then
    ICON_ARG="--icon $ICON_PATH"
fi

pyinstaller --noconfirm --onedir --clean --name "AmpleLinux" $ICON_ARG main.py

if [ $? -ne 0 ]; then
    echo "[ERROR] Build failed!"
    deactivate
    exit 1
fi

# --- Step 5: Copy necessary assets ---
echo ""
echo "[2/2] Copying necessary assets..."

DIST_RESOURCES="dist/AmpleLinux/Ample/Resources"
mkdir -p "$DIST_RESOURCES"
echo "Copying Resources..."
cp -r ../Ample/Resources/* "$DIST_RESOURCES/"

DIST_MAME="dist/AmpleLinux/mame"
mkdir -p "$DIST_MAME/roms"
mkdir -p "$DIST_MAME/cfg"
echo "Created mame directory structure."

cp requirements.txt dist/AmpleLinux/

echo ""
echo "[SUCCESS] Build complete!"
echo "The standalone application is located in: dist/AmpleLinux/AmpleLinux"
echo ""

# --- Cleanup ---
echo "Cleaning up build artifacts..."
rm -rf build
rm -f AmpleLinux.spec
deactivate

echo "Done!"
