# Pull Request: Add native Windows (AmpleWin) and Linux (AmpleLinux) ports

This PR introduces full support for **Windows** and **Linux** platforms, expanding Ample from a macOS-exclusive tool to a cross-platform frontend.

To ensure stability and avoid conflicts with the existing macOS codebase, the new ports are contained in their own dedicated directories (`AmpleWin/` and `AmpleLinux/`) while keeping the root structure clean.

### � Isolation & Safety
**I have NOT touched any of your original macOS code.** The only file modified in the root directory is `README.md`, simply to add links to the new Windows/Linux ports.

You can freely modify these links to point to your own repository structure if you choose to merge this.

### �🚀 Key Features

#### 🪟 Windows Port (`AmpleWin/`)
*   **Launcher**: `AmpleWin.bat` script for easy startup.
*   **Portable**: Designed to work as a portable app without complex installation.
*   **Docs**: Includes detailed installation and usage instructions (English + Traditional Chinese).

#### 🐧 Linux Port (`AmpleLinux/`)
*   **One-Click Setup**: `AmpleLinux.sh` automatically creates a virtual environment (`venv`) and installs dependencies (`PySide6`, etc.) on the first run.
*   **Desktop Integration**: Includes a `build_elf.sh` script using PyInstaller to create a standalone binary. It also generates and installs a `.desktop` file for proper application menu integration.
*   **Smart Detection**:
    *   Auto-detects system dark/light mode (GNOME/KDE).
    *   Detects if MAME is missing and offers `snap install mame` on Ubuntu.
    *   Fixes common audio permission issues (ALSA group check).

### 📝 Documentation
*   Updated the root `README.md` to reference the new ports.
*   Added comprehensive `README.md` and `README_tw.md` inside each port directory.

### ✅ Verification
I have tested these changes on:
*   **Windows 10/11**: Confirmed launch and ROM management.
*   **Ubuntu 22.04 / 24.04**: Verified `AmpleLinux.sh` setup, `build_elf.sh` binary generation, and icon integration.

Hope this helps expand the user base for Ample! Thanks for the great original work.
