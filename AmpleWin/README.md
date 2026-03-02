# AmpleWin - Windows Port (Legacy Apple Emulator Frontend)

[English](README.md) | [繁體中文](README_tw.md)

This is a precision port of the macOS native [Ample](https://github.com/ksherlock/ample) project to the Windows platform.

> [!TIP]
> **Linux User?** Check out the [AmpleLinux](../AmpleLinux/) Port.


![](screenshot.png)

> [!IMPORTANT]
> **Current Version Support**: Updated to stay in sync with the latest version of Ample (macOS) resources and also MAME latest binary.

## 🍎 Ample (macOS) vs. AmpleWin (Windows) Comparison

| Feature | Ample (macOS Native) | AmpleWin (Windows Optimized) | Optimization & Notes |
| :--- | :--- | :--- | :--- |
| **Language** | Objective-C (Cocoa) | **Python 3.11 + PySide6 (Qt)** | Independent development, **zero changes to Mac source code** |
| **Installation** | .dmg Image / Homebrew | **Portable (+ .bat Auto-Config)** | One-click setup for Python and dependencies via `AmpleWin.bat` |
| **UI** | Native macOS Components | **1:1 Pixel-Perfect QSS Replica** | Replicates Mac aesthetic, with **Adaptive Light/Dark Theme** support |
| **MAME Integration** | Built-in Custom Core or Self-selected | **Official Core Download or Self-selected** | Users can update MAME independently or download via app |
| **Machine Selection** | Supports Default Bookmark | **Full Session Persistence (Auto-Load)** | Auto-loads last used machine state without manual bookmarking |
| **Software List Perf** | Synchronous Loading (Full XML) | **Deferred Loading** | **Major Optimization**: Instant machine switching, loads on search |
| **Software Search UI** | Standard Pop-up List | **Smart Overlay Search** | Supports real-time search and full descriptive names without UI shifts |
| **ROM Download** | Supports Auto-Download | **High-Speed Failover Engine** | **Major Optimization**: Multi-server failover (callapple + mdk.cab) |
| **Validation** | Relies on Static .plist | **Live Parameter Validation** | **Major Optimization**: Validates against MAME to prevent launch crashes |
| **Video Support** | Metal / OpenGL / BGFX | **BGFX / OpenGL / Vulkan / D3D11 / D3D12** | Optimized for Windows with multi-generational DirectX support |
| **Networking** | Apple VMNet Framework | **Npcap (WinPcap) / PCAP** | Standard networking via Npcap (no root fix needed) |
| **Operating Logic** | Sticky Software Selection | **Sticky Software Selection** | Preserves compatible software selection when switching machines |

## 🌟 Key Features

### 🍏 Faithful Mac Experience (Feature Parity)
*   **Visual Precision**: 
    *   **Resolution Scaling**: Precision support for **Window 1x-4x** modes with machine-specific aspect ratio heuristics (e.g., Apple II 4:3 correction).
    *   **Square Pixels**: Specialized integer-scaling mode (e.g., 1120x768) to eliminate pixel shimmering.
*   **Software Library**:
    *   **Smart Filtering**: Automatically identifies supported media types (flop1, flop2, cass...) to match machine capabilities.
    *   **Search Overlay**: Integrated Mac-style search with auto-completion and full descriptive names.
    *   **Compatibility Check**: Options marked as `disabled` in property lists (e.g. incompatible SCSI cards) are now correctly grayed out and unselectable, matching Mac behavior.
*   **Advanced Slot Emulation**: Full support for nested sub-slots (e.g. SCSI cards). Automatically initializes default devices (CD-ROM/Hard Disk) upon card selection.
*   **ROM Management**:
    *   **Search Filter**: Real-time searching in the ROM manager window to quickly find system firmwares.
    *   **Download Failover**: Automatic multi-server acquisition (callapple + mdk.cab) with transparent failover for maximum stability.
    *   **Extended Library**: Expanded support for PowerBook Duo 280, Pravetz 8C, TK3000, and more.
*   **Shared Directory**: Full parity with the Mac version, allowing direct host-to-emulator file sharing via the `-share_directory` argument. (Includes click-to-browse support).
*   **VGM Support (Advanced)**: Since modern MAME removed VGM support, AmpleWin implements a robust background workflow to download and configure the **MAME-VGM Mod (v0.280)**. It uses a non-destructive extraction process (`mame-vgm.exe`) to preserve your main MAME core while restoring high-fidelity music recording.

### 🪟 Windows-Specific Optimizations
*   **Performance**:
    *   **Concurrent Downloading**: Multi-threaded system for high-speed ROM acquisition.
    *   **Clean Workspace**: All MAME side-car files (nvram, cfg, sta) are strictly isolated within the `mame` directory.
    *   **Deferred XML Loading**: Major optimization for instant machine switching and search response.
*   **UI Enhancements**:
    *   **Adaptive Theme**: Real-time synchronization with Windows Light/Dark system theme.
    *   **Command Preview**: Real-time 4-line console preview to monitor exactly what parameters are being passed to MAME.
    *   **Smart Path Handling**: Native file/folder selectors for A/V output and Shared Directories, with automatic path normalization (converting `/` to `\`) for maximum Windows compatibility.
*   **Flexible Backend**: Full support for BGFX, OpenGL, Vulkan, and **DirectX 11/12** out of the box.

## 🛠️ Quick Start

1.  **Launch Ample**:
    Enter the **`AmpleWin`** folder and run **`AmpleWin.bat`**.
    *   The script will check the Python environment, install dependencies, and start the app.
2.  **Fast Deployment**:
    *   Go to **⚙️ Settings** -> Click **Download MAME** to auto-configure the emulator.
    *   Click **🎮 ROMs** to download system firmware.
    *   Click **📂 Ample Dir** to quickly open the local application folder.
3.  **Start playing**:
    *   Select a machine from the left panel.
    *   **Double-click** the machine name or click **Launch MAME** to start.

## 🌐 Networking (Advanced)

To simulate networking hardware like **Uthernet II**, Windows requires [Npcap](https://nmap.org/npcap/) (install in "WinPcap compatible mode"). Unlike the macOS version, no "Fix Permissions" is required as Windows handles hardware access via drivers.

## 📂 Project Structure

| File/Directory | Description |
| :--- | :--- |
| **`AmpleWin.bat`** | **Start Here**. Auto-setup script (installs Python deps & runs app). |
| `build_exe.bat` | **Packaging**. Creates a `dist` portable EXE folder using PyInstaller. |
| `main.py` | Application entry point, UI rendering, and event loop. |
| `data_manager.py` | Parser for `.plist` machine definitions and MAME `.xml` software lists. |
| `mame_launcher.py` | Command-line builder and process manager. |
| `rom_manager.py` | Management and multi-threaded downloading of system ROMs. |
| `mame_downloader.py` | Automated MAME / VGM Mod downloader and extractor. |
| `mame/` | Isolated directory for MAME executable, ROMs, and config files. |
| `Agent.md` | Development log and session history. |

## 📦 Building from Source (Portable EXE)

If you want to create a standalone executable for distribution:

1.  Run `build_exe.bat` in the `AmpleWin` directory.
2.  The script will automatically install PyInstaller, package the application, and copy necessary resources.
3.  The output will be in `AmpleWin\dist\AmpleWin`.
4.  Copy the entire `AmpleWin` folder to any location. It is fully **portable** and does not require Python to run.

## 📝 Acknowledgments

*   Original macOS version developer: [Kelvin Sherlock](https://github.com/ksherlock)
*   **Windows Port Developers: anomixer + Antigravity**: Dedicated to providing the ultimate Apple II / Macintosh emulation experience on Windows.
