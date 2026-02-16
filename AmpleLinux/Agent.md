# Agent Task Audit Log - Ample Linux Port


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

### 2. Known Mantras (inherited from AmpleWin)
*   **Visual Parity is King**: Every margin, font size, and color was cross-referenced with macOS.
*   **Authorship**: This Linux Port is based on the AmpleWin collaboration between **anomixer** and **Antigravity**.
