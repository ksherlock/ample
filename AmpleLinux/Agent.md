# Agent Task Audit Log - Ample Linux Port


## 📅 Session: 2026-03-02 (Session 3)

### 🎯 Objective: Upstream Version Tracking & Documentation Maintenance
Focused on updating the Linux port documentation to track MAME 0.286 and simplifying maintainability.

### ✅ Key Achievements:
1.  **Documentation Refactoring**:
    *   Renamed version-specific screenshot files (e.g. `screenshot-v0.28x.png` to `screenshot.png`).
    *   Updated `README.md` and `README_tw.md` to use generic "latest version" terminology to prevent the need for manual text updates upon future Ample/MAME releases.

### 🚀 Current Project Status
The Linux Port documentation is updated for MAME 0.286 and future-proofed against minor version increments.

---

## 📅 Session: 2026-02-17 (Session 2)

### 🎯 Objective: Real-World Testing & Deployment Fix
Deployed the Linux Port to an actual Linux machine for testing. Identified and fixed a critical dependency installation issue.

### ✅ Key Achievements:

1.  **Launcher Script Fix (`AmpleLinux.sh`)**:
    *   **Bug**: Original script used `pip3` / `pip` commands directly, which don't exist on many modern Linux distros (Debian 12+, Ubuntu 23+, Fedora 38+ enforce PEP 668).
    *   **Fix v1**: Changed to `python3 -m pip` (the universally reliable pip invocation).
    *   **Fix v2**: Added automatic `--break-system-packages` fallback for PEP 668-compliant systems.
    *   **Error Messages**: Added distro-specific guidance (apt/dnf/pacman) and venv instructions in error output.

2.  **Git Workflow**:
    *   Created `linux` branch from `master`.
    *   Pushed to `origin/linux` for cross-machine testing.

### 🔍 Testing Observations (Real Linux Machine):
*   `pip3` command was not in PATH → first fallback triggered.
*   `python3 -m pip` also failed (PEP 668 system Python restriction) → second fallback triggered with `--break-system-packages`.
*   **Conclusion**: Many modern Linux distros require either system packages (`sudo apt install python3-pyside6 python3-requests`) or a venv approach. The launcher script now documents both paths clearly.

### ⚠️ Known Issue - Pending Resolution:
*   Systems without any pip module need manual package installation first. The script provides clear guidance but cannot auto-resolve this without `sudo`.
*   **Recommended solutions** (in priority order):
    1.  System packages: `sudo apt install python3-pyside6 python3-requests`
    2.  Install pip: `sudo apt install python3-pip`, then re-run script
    3.  Use venv: `python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && python3 main.py`

### 🚀 Current Project Status
Codebase is ported and pushed to `linux` branch. Launcher script has been hardened for modern Linux distros. Awaiting successful end-to-end test with dependencies installed.

---

## 📅 Session: 2026-02-16 (Session 1)

### 🎯 Objective: Linux Port Creation
Ported AmpleWin (Windows) to Linux, following the original author's suggestion (ksherlock/ample#45) that Linux support would be easy to add.

### ✅ Key Achievements:

1.  **Codebase Porting (from AmpleWin)**:
    *   **Zero-Modification Files**: `data_manager.py`, `rom_manager.py`, `mame_launcher.py`, `requirements.txt` — copied directly, no changes needed.
    *   **Simplified `mame_downloader.py`**: Removed `MameDownloadWorker` entirely (Linux users install MAME via their package manager). Kept `VgmModDownloadWorker` with Linux adaptations (7z via PATH, no `.exe` suffix, helpful `p7zip` install instructions).
    *   **`main.py` (~20 changes)**: Comprehensive platform adaptation:
        -   Replaced `winreg` theme detection with `gsettings` (GNOME 42+ `color-scheme`) and KDE (`kdeglobals`) dark mode detection.
        -   Replaced all `os.startfile()` calls with `xdg-open` via a helper function `_xdg_open()`.
        -   Removed all `.exe` suffixes from MAME binary references (`mame.exe` → `mame`, `mame-vgm.exe` → `mame-vgm`).
        -   Enhanced `check_for_mame()` to search system paths (`/usr/bin/mame`, `/usr/games/mame`, `/usr/local/bin/mame`) and use `which mame`.
        -   Replaced `Download MAME` button with package manager guidance text.
        -   Updated `shlex.split()` from `posix=False` (Windows) to `posix=True` (Linux).
        -   Updated file browser filter from `*.exe` to `All Files (*)`.
        -   Changed window title and help URL.

2.  **Launcher Script**:
    *   Created `AmpleLinux.sh` as equivalent of `AmpleWin.bat`.
    *   Includes Python 3 detection, pip dependency installation, and helpful error messages with distro-specific commands.

3.  **Documentation**:
    *   Created dual-language READMEs (`README.md` English, `README_tw.md` Traditional Chinese).
    *   Includes installation guide for all major distros (Ubuntu, Fedora, Arch, Flatpak).
    *   Troubleshooting section for PySide6, MAME detection, and theme issues.

### 🔍 Design Decisions:

1.  **Separate Directory (not shared codebase)**: Chose to create `AmpleLinux/` as a separate directory rather than refactoring `AmpleWin/` into a shared codebase. This maintains the project convention where each platform gets its own additive subdirectory, minimizing risk to the stable Windows port.

2.  **No MAME Auto-Download**: Following the original author's guidance ("let the user download it themselves"), Linux users install MAME via their system package manager. This is the Linux cultural norm and avoids complex binary distribution issues.

3.  **GNOME + KDE Theme Detection**: Implemented multi-strategy dark mode detection covering GNOME 42+ `color-scheme`, older GNOME `gtk-theme`, and KDE `kdeglobals`, with Qt palette as ultimate fallback.

### 🚀 Current Project Status
The Linux Port is functionally complete. All Windows-specific code has been adapted, and the application should work on major Linux distributions with GNOME or KDE desktops.

---

##  Handover Notes for Future Agents

### 1. Platform Differences from AmpleWin
*   **No `winreg`**: Theme detection uses `gsettings` and KDE config file parsing.
*   **No `os.startfile()`**: Uses `xdg-open` via the `_xdg_open()` helper function.
*   **No `.exe` suffixes**: All binary references use bare names (`mame`, `mame-vgm`).
*   **No MAME auto-download**: Users install via package manager. Settings dialog shows guidance.
*   **`shlex.split(posix=True)`**: Linux uses POSIX-mode shell parsing (no special Windows path handling).
*   **MAME detection**: Checks `PATH` via `which`, plus standard Linux paths (`/usr/bin`, `/usr/games`, `/usr/local/bin`).

### 2. Deployment (CRITICAL)
*   **PEP 668 Era**: Modern Linux distros (Debian 12+, Ubuntu 23.04+, Fedora 38+) block global pip installs. The launcher script handles this with `--break-system-packages` fallback.
*   **Recommended Install Methods** (in priority order):
    1.  System packages: `sudo apt install python3-pyside6 python3-requests mame`
    2.  venv: `python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt`
    3.  pip with override: `python3 -m pip install -r requirements.txt --break-system-packages`
*   **Never use `pip3` or `pip` directly** in scripts — always use `python3 -m pip` for reliability.

### 3. Known Mantras (inherited from AmpleWin)
*   **Visual Parity is King**: Every margin, font size, and color was cross-referenced with macOS.
*   **Authorship**: This Linux Port is based on the AmpleWin collaboration between **anomixer** and **Antigravity**.

---

## 📅 Session: 2026-02-17 (Session 2)

### 🎯 Objective: First-Run Experience, Build System & Polish

### ✅ Key Changes:

1.  **Launcher Architecture (`AmpleLinux.sh`)**:
    *   **Refactored to venv**: Switched from system-level `apt` dependencies to a strictly isolated `python3 -m venv` approach.
    *   **Automated Setup**: Script now auto-creates `.venv`, installs `python3-venv` (if missing), and pip installs `requirements.txt`.
    *   **Distro Agnostic**: Only depends on `python3-full` and `libxcb-cursor*` (apt) for the base interpreter; all libraries (PySide6) are pulled via pip.
    *   **ALSA Fix**: Added auto-detection of `/proc/asound` and `usermod -a -G audio` fix for permission issues.

2.  **User Experience Enhancements (`main.py`)**:
    *   **Ubuntu Snap Integration**: If MAME is missing on Ubuntu, offers `sudo snap install mame` with a non-blocking `QProgressDialog`.
    *   **Configuration Fix**: `ensure_mame_ini` now runs `mame -cc` inside `AmpleLinux/mame` to keep config portable.
    *   **Path Precision**: `update_command_line` now resolves absolute paths for `-inipath` and `-rompath` (e.g., `/home/user/...`).
    *   **BGFX Cleanup**: Removed Windows-only Direct3D options.
    *   **UI Polish**: "Generate VGM" now shows a "Feature not implemented" popup.

3.  **Build System (New)**:
    *   **`make_icon.py`**: Created Linux-specific icon generator (produces standard PNG sizes: 16x16 to 512x512).
    *   **`build_elf.sh`**: Created PyInstaller build script that uses a temporary venv to bypass PEP 668 restrictions and produce a standalone ELF binary in `dist/`.

### 🔍 Technical Decisions:
*   **PySide6 via pip**: Moved away from `python3-pyside2` (apt) because the codebase is written for PySide6. Using venv + pip ensures version consistency and avoids the "externally-managed-environment" error on modern distros.
*   **MAME Snap**: For Ubuntu users, Snap is the most reliable way to get a recent MAME version without PPA complexity.
