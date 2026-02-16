# AmpleLinux - Linux Port (Legacy Apple Emulator Frontend)

[English](README.md) | [繁體中文](README_tw.md)

This is a port of the macOS native [Ample](https://github.com/ksherlock/ample) project to the Linux platform, based on the [AmpleWin](../AmpleWin/) Windows Port.

> [!IMPORTANT]
> **Current Version Support**: Updated to stay in sync with Ample (macOS) **v0.285** resources and **MAME 0.285**.

## 🍎 Ample (macOS) vs. AmpleLinux (Linux) Comparison

| Feature | Ample (macOS Native) | AmpleLinux (Linux) | Notes |
| :--- | :--- | :--- | :--- |
| **Language** | Objective-C (Cocoa) | **Python 3.11 + PySide6 (Qt)** | Independent development, **zero changes to Mac source code** |
| **Installation** | .dmg Image / Homebrew | **Portable (+ .sh Auto-Config)** | One-click setup via `AmpleLinux.sh` |
| **MAME Integration** | Built-in Custom Core | **System-installed MAME** | Uses `mame` from your package manager (apt, dnf, pacman, etc.) |
| **UI** | Native macOS Components | **1:1 Pixel-Perfect QSS Replica** | With **Adaptive Light/Dark Theme** support (GNOME/KDE) |
| **Machine Selection** | Supports Default Bookmark | **Full Session Persistence (Auto-Load)** | Auto-loads last used machine state |
| **Software List Perf** | Synchronous Loading | **Deferred Loading** | Instant machine switching |
| **ROM Download** | Supports Auto-Download | **High-Speed Failover Engine** | Multi-server failover (callapple + mdk.cab) |
| **Video Support** | Metal / OpenGL / BGFX | **BGFX / OpenGL / Vulkan** | Leveraging MAME's cross-platform rendering |

## 🌟 Key Features

### 🍏 Faithful Mac Experience (Feature Parity)
*   **Visual Precision**: Precision support for **Window 1x-4x** modes with machine-specific aspect ratio heuristics.
*   **Software Library**: Smart filtering, search overlay, and compatibility checking.
*   **Advanced Slot Emulation**: Full support for nested sub-slots (e.g. SCSI cards).
*   **ROM Management**: Real-time search, multi-server failover download, extended library.
*   **Shared Directory**: Full parity with `-share_directory` argument.

### 🐧 Linux-Specific Features
*   **System MAME Integration**: Auto-detects MAME from `PATH`, `/usr/bin/mame`, `/usr/games/mame`, etc.
*   **Adaptive Theme**: Detects GNOME (`gsettings`) and KDE dark/light mode in real-time.
*   **Native File Management**: Uses `xdg-open` for file/folder/URL opening.
*   **No External Dependencies**: MAME is installed via your distribution's package manager.

## 🛠️ Quick Start

### Prerequisites
-   **Python 3.9+** with pip
-   **MAME** installed via your package manager
-   **PySide6** (installed automatically)

### Installation

1.  **Install MAME** (if not already installed):
    ```bash
    # Ubuntu / Debian
    sudo apt install mame

    # Fedora
    sudo dnf install mame

    # Arch Linux
    sudo pacman -S mame

    # Flatpak (any distro)
    flatpak install flathub org.mamedev.MAME
    ```

2.  **Launch Ample**:
    ```bash
    cd AmpleLinux
    chmod +x AmpleLinux.sh
    ./AmpleLinux.sh
    ```
    The script will check Python, install dependencies, and start the app.

3.  **Fast Deployment**:
    *   Click **🎮 ROMs** to download system firmware.
    *   Go to **⚙️ Settings** to verify MAME is detected.
    *   Select a machine and **Launch MAME**!

## 📂 Project Structure

| File/Directory | Description |
| :--- | :--- |
| **`AmpleLinux.sh`** | **Start Here**. Auto-setup script (installs Python deps & runs app). |
| `main.py` | Application entry point, UI rendering, and event loop. |
| `data_manager.py` | Parser for `.plist` machine definitions and MAME `.xml` software lists. |
| `mame_launcher.py` | Command-line builder and process manager. |
| `rom_manager.py` | Management and multi-threaded downloading of system ROMs. |
| `mame_downloader.py` | VGM Mod downloader and extractor. |

## 🔧 Troubleshooting

### PySide6 Installation Issues
If `pip install PySide6` fails, try:
```bash
# Ubuntu/Debian: install system Qt dependencies first
sudo apt install python3-pyside6 
# Or install from pip with --break-system-packages (if using system python)
pip3 install PySide6 --break-system-packages
```

### MAME Not Detected
If the app can't find MAME:
1.  Go to **⚙️ Settings** and click **Select MAME...** to manually browse to the binary.
2.  Or verify MAME is in your PATH: `which mame`

### Theme Detection
The app auto-detects GNOME and KDE dark/light themes. If your desktop environment isn't supported, the app defaults to the Qt palette for theme detection.

## 📝 Acknowledgments

*   Original macOS version developer: [Kelvin Sherlock](https://github.com/ksherlock)
*   **Windows Port Developers: anomixer + Antigravity**
*   **Linux Port**: Adapted from AmpleWin by anomixer + Antigravity
