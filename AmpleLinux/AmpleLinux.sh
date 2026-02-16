#!/bin/bash
echo "========================================"
echo "  Ample - Linux Port Auto Launcher"
echo "========================================"

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo "[ERROR] Python 3 not found! Please install Python 3.9 or newer."
    echo "  Ubuntu/Debian: sudo apt install python3 python3-pip python3-venv"
    echo "  Fedora: sudo dnf install python3 python3-pip"
    echo "  Arch: sudo pacman -S python python-pip"
    exit 1
fi

# Navigate to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Install/Update dependencies
echo "[1/2] Checking dependencies..."
pip3 install -r requirements.txt --quiet 2>/dev/null || pip install -r requirements.txt --quiet

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to install requirements."
    echo "  You may need to install pip first:"
    echo "    Ubuntu/Debian: sudo apt install python3-pip"
    echo "    Or use: python3 -m pip install -r requirements.txt"
    exit 1
fi

# Run the application
echo "[2/2] Launching Ample..."
python3 main.py

if [ $? -ne 0 ]; then
    echo ""
    echo "[INFO] Application exited with error code $?."
    read -p "Press Enter to continue..."
fi
