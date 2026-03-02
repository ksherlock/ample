# Agent Task Audit Log - Ample Windows Port


## 📅 Session: 2026-03-02 (Session 13)

### 🎯 Objective: Upstream Version Bump & Documentation Maintenance
Focused on updating the project to track MAME 0.286 and simplifying documentation maintainability.

### ✅ Key Achievements:
1.  **Version Bump**: Updated `mame_downloader.py` to point to the latest **MAME 0.286** x64 Windows binary.
2.  **Documentation Refactoring**: 
    *   Renamed version-specific screenshot files (e.g. `screenshot-v0.28x.png` to `screenshot.png`) across all platforms.
    *   Updated `README.md` and `README_tw.md` to use generic "latest version" terminology to prevent the need for manual text updates upon future MAME releases.

### 🚀 Current Project Status
The Windows Port is functionally tracking MAME 0.286 and documentation is now future-proofed against minor version increments.

---

## 📅 Session: 2026-02-16 (Session 12)

### 🎯 Objective: Linux Port Spinoff
AmpleWin has successfully served as the foundation for a new Linux port. 

### ✅ Key Achievements:
1.  **Port Creation**:
    *   **AmpleLinux**: Created `AmpleLinux/` directory based on the AmpleWin codebase.
    *   **Shared DNA**: `data_manager.py` and `rom_manager.py` remain identical, while `main.py` was adapted for Linux (xdg-open, paths, dependencies).
    *   **Cross-Reference**: Added links to AmpleLinux in the README.

### 🚀 Current Project Status
The project now supports both Windows (AmpleWin) and Linux (AmpleLinux) natively.

---

## 📅 Session: 2026-02-09 (Session 11)


### 🎯 Objective: Upstream Synchronization & Codebase Hygiene
Focused on synchronizing the project with the latest upstream changes from `ksherlock/ample`, ensuring the `roms.plist` database is compliant with the official repository, and cleaning up diverging local branches.

### ✅ Key Achievements:

1.  **Full Upstream Sync**:
    *   **Repository Alignment**: Merged latest `upstream/master` changes (4 new commits), bringing in the official fix for **PowerBook Duo 280 (`macpd280`)** and new definitions like **Epson RX-80 (`epson_rx80`)**.
    *   **Deforking roms.plist**: Discarded local custom modifications to `Ample/Resources/roms.plist`. The file is now byte-for-byte identical to the upstream version, ensuring long-term maintainability.
    *   **Branch Cleanup**: Removed the stale `fix-missing-roms` branch and closed the associated PR #44, as the upstream author has implemented the necessary fixes natively.

2.  **AmpleWin Verification**:
    *   **Compatibility Verified**: Confirmed that `AmpleWin` correctly parses the new upstream `roms.plist` without errors.
    *   **ROM Status**: Validated that `macpd280` is now natively supported for auto-download via the new upstream definitions. Note: Custom definitions for *Pravetz* and *TK3000* are no longer in `roms.plist` but remain playable if ROMs are manually provided.
3.  **Deployment & Distribution**:
    *   **Refactor**: Renamed `mame_bin` to `mame` across the codebase for better standards compliance.
    *   **Portable EXE**: Created `build_exe.bat` using **PyInstaller (OneDir)** to package the application into a standalone executable.
    *   **Path Logic**: Updated `main.py` with robust `sys.frozen` detection to ensure resources and downloads work correctly in both Dev and Frozen environments.
    *   **Documentation**: Added build instructions to READMEs.

### 🚀 Current Project Status
The codebase is now in a "Clean Slate" state. `master` is fully synced with upstream, with `AmpleWin` serving as a strictly additive extension.

## 📅 Session: 2026-02-02 (Session 10)

### 🎯 Objective: ROM Library Expansion & Advanced Slot Emulation
Focused on expanding the supported ROM library, implementing a robust failover download mechanism, and perfecting nested slot configuration logic for SCSI peripherals.

### ✅ Key Achievements:

1.  **ROM Library & Search Expansion**:
    *   **New System Support**: Added missing ROM definitions for **Macintosh PowerBook Duo 280/280c**, **Pravetz 8C**, and **TK3000 //e**.
    *   **Search Parity**: Fully synchronized hardware definitions with the latest macOS release, including secondary Pravetz models (`82`, `8M`).

2.  **Robust ROM Download Failover**:
    *   **Prioritized Multi-Server Support**: Implemented a transparent failover mechanism in `rom_manager.py`. The downloader now prioritizes **callapple.org** for maximum stability and automatically falls back to **mdk.cab** for Apple II clones and split sets unreachable on the primary server.
    *   **Status Integrity**: Fixed a bug in the download progress counter to ensure accurate success/failure reporting in the UI.

3.  **Advanced Slot & Media Emulation**:
    *   **SCSI Sub-Peripheral Detection**: Rewrote `aggregate_media` to recursively detect devices attached to slot cards (e.g., finding the CD-ROM and Hard Disk on an Apple IIgs SCSI card).
    *   **Nested Slot Defaults**: Implemented automatic initialization for sub-slots. Plugging in a SCSI card now automatically populates its sub-slots with default devices (CD-ROM at ID 1, Hard Disk at ID 6), matching Mac parity.
    *   **Sub-Slot UI Parity**: Updated the "Hamburger" popup to show all configurable sub-slots, not just those with media, giving users full control over complex hardware chains.
    *   **Aggregator Optimization**: Refined the media scanner to ignore the global "device library" at the root level, preventing UI clutter and double-counting of unmapped drives.

### 🚀 Current Project Status
The Windows Port now offers superior hardware configuration capabilities. Complex SCSI and SmartPort chains are handled automatically, and the ROM acquisition system is more reliable than ever.

## 📅 Session: 2026-02-02 (Session 9)

### 🎯 Objective: Upstream Synchronization & Feature Parity (MAME 0.286)
Focused on synchronizing with the upstream Ample (macOS) v0.286 release, updating the core emulator backend, and implementing new UI search capabilities.

### ✅ Key Achievements:

1.  **Upstream Repository Synchronization**:
    *   **Merge & Push**: Successfully merged latest commits from `upstream/master` (ksherlock/ample).
    *   **Resource Alignment**: Synchronized latest hardware definitions and slot configurations from original project.
    *   **A2retroNET Integration**: Inherited support for a2retronet hardware, enabling up to 8 SmartPort disk images.

2.  **MAME Core Update**:
    *   **Version Upgrade**: Updated `mame_downloader.py` to point to the official **MAME 0.286** Windows x64 binary.
    *   **Download Engine Parity**: Users can now auto-download the latest MAME core directly from the Settings menu.

3.  **ROM Manager Enhancements**:
    *   **Search Filter**: Implemented a real-time search field in the `RomManagerDialog` header (matching macOS feature parity).
    *   **Filtering Logic**: Updated `refresh_list` to filter ROMs by description or shortcode, allowing users to quickly find specific system firmwares.

### 🚀 Current Project Status
The Windows Port is now fully synchronized with Ample (macOS) v0.286 resources. It supports the latest MAME core and offers improved ROM management tools.

---


## 📅 Session: 2026-01-24 (Session 8)

### 🎯 Objective: Path robustness & UI Interactivity
Focused on fixing "No such file" errors when launching custom ROM paths and improving the user experience for file selection in secondary tabs.

### ✅ Key Achievements:

1.  **Command Line Robustness**:
    *   **Quote Handling**: Patched the `shlex` logic in `main.py` to handle Windows paths correctly. Manually stripping outer quotes ensures `subprocess` doesn't double-escape them, fixing the critical "No such file or directory" error when launching files with spaces in their path.

2.  **File Selection UX**:
    *   **A/V Path Selectors**: Implemented `mousePressEvent` on the A/V tab input fields (AVI, WAV, VGM). Clicking these text boxes now opens a native `QFileDialog` ("Save As") with appropriate extension filters, saving users from manual typing.
    *   **Path Normalization**: Updated the "Shared Directory" directory selector to automatically normalize paths (e.g., converting `/` to `\`), ensuring visual consistency and compatibility with Windows command line expectations.

### 🚀 Current Project Status
The application is now highly resilient to typical Windows path complexities. Users can easily select output destinations and shared folders without worrying about path syntax errors.

---

## 📅 Session: 2026-01-22 (Session 7)

### 🎯 Objective: User Freedom & flexible Command Control
Focused on giving the user complete control over the MAME launch command and ensuring a cleaner default state for machine slots.

### ✅ Key Achievements:

1.  **Editable Command Console**:
    *   **Unlocked Preview**: The "Command Preview" text box is no longer read-only.
    *   **Source of Truth**: The Launch button now executes *exactly* what is typed in this box. Users can manually add, remove, or edit arguments (e.g., adding `-verbose` or removing unwanted flags) before launching.

2.  **Launch Engine Integrity**:
    *   **Absolute Path Resolution**: Implemented `shlex` parsing to read the user's manual command string. It automatically detects the command (`mame` or `mame-vgm`) and resolves it to the absolute system path to fix `[WinError 2]` on Windows.
    *   **VGM Pathing**: Logic retains awareness of VGM Mod capabilities even when launching from a custom text string.

3.  **Cleaner Default State**:
    *   **Slot Neutrality**: Removed the aggressive fallback logic that forced the first available option for slots without a default value.
    *   **Phantom Args Clarified**: This eliminates confusing arguments like `-fdc:0 525` appearing automatically, ensuring MAME starts with its internal defaults unless the local configuration explicitly overrides them.

### 🚀 Current Project Status
The app now respects "Power User" workflows. You can use the UI for quick setup, then fine-tune the command line manually. The codebase structure is being finalized.

---

## 📅 Session: 2026-01-21 (Session 6)

### 🎯 Objective: VGM Mod Stability & Extraction Safety
Focused on fixing critical bugs in the VGM recording workflow, ensuring extraction safety, and improving UI feedback for the modded binary.

### ✅ Key Achievements:

1.  **VGM Mod Extraction Safety**:
    *   **Anti-Overwrite Workflow**: Implemented a temporary directory strategy (`_vgm_temp`) during VGM Mod extraction. This ensures that the mod's `mame.exe` (v0.280) never accidentally overwrites the main official `mame.exe` (v0.284).
    *   **Atomic Renaming**: The modded binary is now safely extracted, renamed to `mame-vgm.exe`, and moved to the destination in a single, non-destructive step.

2.  **Command Line & UI Parity**:
    *   **Explicit Recording Toggle**: Fixed a bug where `-vgmwrite 1` was missing from the console launch command. Recording is now correctly activated when using the modded binary.
    *   **Dynamic UI Preview**: The 4-line console preview now correctly displays `mame-vgm` as the target executable when VGM recording is enabled and the mod is detected, matching actual runtime behavior.

3.  **Thread & Lifecycle Stability**:
    *   **Remove Safety**: Fixed a `ValueError: list.remove(x): x not in list` in the worker cleanup logic, ensuring the thread-safe management of background tasks even if signals fire twice.
    *   **Worker Refactoring**: Rewrote the `VgmModDownloadWorker` and `VgmPostProcessWorker` logic to handle edge cases in file movement and process termination more gracefully.

4.  **Shared Directory & UI Refinement**:
    *   **Logic Completion**: Fixed a missing link in the launch engine where the "Shared Directory" path from the UI wasn't being passed to the actual MAME process.
    *   **Standardized Argument**: Updated from `-share` to the official `-share_directory` for maximum compatibility.
    *   **UI Bugfix**: Removed duplicate "Paths" tab initialization in the main window.
    *   **Click-to-Browse**: Implemented a pop-up directory selector when clicking the Shared Directory path box, replacing manual entry.

5.  **Smart Slot Validation (Mac Parity)**:
    *   **Disabled State Support**: Ported the `disabled` logic from the Mac version. Slot options that are technically defined but marked as unsupported in the plist (e.g., specific SCSI cards on Apple IIgs) are now visually grayed out and unselectable in the dropdown menu.
    *   **Prevention**: Prevents users from accidentally selecting incompatible hardware configurations that would cause MAME to crash or behave unexpectedly.

### 🚀 Current Project Status
The VGM and Shared Directory workflows are now "Production Ready." The UI has reached a high level of fidelity with the Mac original, including subtle behaviors like smart slot validation and intuitive path selection.

---

## 📅 Session: 2026-01-21 (Session 5)

### 🎯 Objective: MAME Core Logic & Command Line Robustness
Focused on improving the reliability of the MAME launch engine, specifically regarding dynamic slot media (CFFA2), multi-drive support, and shell-safe command construction.

### ✅ Key Achievements:

1.  **Relaxed Parameter Validation**:
    *   **Dynamic Media Parity**: Removed strict `listmedia` validation in `MameLauncher` to allow secondary media types (like `hard1`, `hard2`) that only appear when a specific card (e.g., CFFA2) is plugged in.
    *   **Internal Filter**: Implemented logic to automatically skip internal MAME node names starting with a colon (e.g., `-:prn`) to prevent "unknown option" errors.

2.  **Multi-Drive & Storage Support**:
    *   **Capping Removal**: Fixed a self-imposed limitation in `main.py` that forced `hard`, `cdrom`, and `cassette` counts to 1. 
    *   **CFFA2 Ready**: AmpleWin now correctly supports machines/cards with multiple hard drives (`-hard1`, `-hard2`).

3.  **Shell Integrity & Quoting**:
    *   **Robust Quoting**: Integrated `subprocess.list2cmdline` for both the UI Command Preview and the actual process execution.
    *   **Space Handling**: Guaranteed that file paths containing spaces are automatically wrapped in quotes (`""`), preventing launch failures on Windows.
    *   **Path Normalization**: Implemented `os.path.normpath` for all MAME arguments (`-hard`, `-rompath`, etc.), ensuring consistent Windows-style backslashes (`\`).
    *   **Command Line Streamlining**: Automated `mame.ini` generation via `mame -cc` upon MAME detection. This allows removing redundant path arguments (`-hashpath`, `-artpath`, etc.) from the command line, resulting in a much cleaner and more readable preview.
    *   **VGM Support (Advanced)**: Since modern MAME removed VGM support, AmpleWin implements a robust background workflow to download and configure the **MAME-VGM Mod (v0.280)**. It uses a non-destructive extraction process (`mame-vgm.exe`) to preserve your main MAME core while restoring high-fidelity music recording, and automatically moves the resulting `.vgm` files to the user's desired path upon MAME exit.

4.  **Resolution Scaling & Visual Parity**:
    *   **Window Mode Scaling**: Implemented `-resolution` generation for scaling modes (2x, 3x, 4x) and **`-nomax`** for **Window 1x** mode to ensure consistent default sizing.
    *   **Aspect Ratio Heuristic**: Integrated a 4:3 correction heuristic for non-square pixel machines (e.g., Apple II: 560x192 -> 1120x840 at 2x) to match macOS Ample behavior.
    *   **Square Pixel Mode**: Implemented integer scaling for Apple II machines (e.g., **1120x768** at 2x) while adding **`-nounevenstretch`** to prevent pixel shimmering and maintain clarity.
    *   **UI Expansion**: Added "Window 4x" option to the Video settings tab.
    *   **Disk Sound Effects Integration**: Linked the "Disk Sound Effects" checkbox to the `-nosamples` argument, allowing MAME samples to load when sound effects are enabled.
    *   **CPU Speed & Throttle UI Alignment**: Merged the Throttle checkbox into the CPU Speed dropdown as a "No Throttle" option, perfectly matching the original macOS Ample interface and logic.

5.  **BGFX Effect Synchronization**:
    *   **Enhanced Effects List**: Updated the video effects selection to support a standardized set of BGFX screen chains: **Unfiltered, HLSL, CRT Geometry, CRT Geometry Deluxe, LCD Grid, and Fighters**.
    *   **Chain Mapping**: Implemented precise mapping between UI selection and MAME's `-bgfx_screen_chains` internal identifiers.

### 🚀 Current Project Status
The MAME launch engine is now significantly more robust and "intelligent." It handles complex slot configurations and multi-disk setups like CFFA2 without manual parameter tweaking, while maintaining a clean, error-free command line preview.

---

## 📅 Session: 2026-01-19 (Session 4)

### 🎯 Objective: Real-time Adaptive Theming & UI Resilience
Focused on implementing a native Windows theme detection engine and ensuring 100% visibility/aesthetic parity across both Light and Dark modes without requiring application restarts. Refined the command console for long parameter strings.

### ✅ Key Achievements:

1.  **Adaptive Theme Engine**:
    *   **Registry-Level Detection**: Implemented `winreg` polling to detect `AppsUseLightTheme` changes in real-time.
    *   **Live Synchronization**: Added a 2-second polling timer (`QTimer`) that triggers a global UI restyle, allowing the app to switch between Light and Dark modes on-the-fly.
    *   **Cross-Window Propagation**: Ensured theme changes flow correctly into child dialogs (ROM Manager) and dynamic overlays (Software Search, Sub-slot popups).

2.  **UI Polish & Visibility Fixes**:
    *   **Light Mode "Ghosting" Elimination**: Fixed unreadable text by moving critical UI colors (Slot Labels, Media Headers) from hardcoded Python strings to the global adaptive stylesheet.
    *   **Themed Popups**: Rewrote `SoftwarePopup` and sub-slot bubble painting to dynamically adjust background colors and "triangle" indicators based on the system theme.
    *   **ROM Manager Parity**: Fully themed the ROM download dialog, ensuring status labels (found/missing) maintain high contrast in both modes.

3.  **Command Console Expansion**:
    *   **Multi-line Preview**: Replaced the single-line `QLineEdit` with a 4-line `QTextEdit` console footer.
    *   **Parameter Visibility**: This allows users to review the entire MAME command line, including long software list paths and slot configurations, without horizontal scrolling.

4.  **Stability & Bug Squashing**:
    *   **ROM Manager Reliability**: Corrected `@Slot` decorators and converted the dialog to `.exec()` (Modal) to prevent interaction conflicts.
    *   **Logic Errors**: Fixed several `NameError` bugs in the rendering engine and addressed stylesheet inheritance issues that caused transparent list views.
5.  **Visual Documentation & Networking Guide**:
    *   **README Screenshots**: Embedded `screenshot-v0.284.png` in READMEs to match original aesthetics.
    *   **Networking Parity Section**: Added a specialized section in READMEs explaining **Npcap** requirements for Uthernet II simulation, clarifying that the macOS "Fix Permissions" is unnecessary on Windows.

### 🚀 Current Project Status
The Windows Port is now a "State-of-the-Art" adaptive application. It feels native on both Light and Dark Windows setups, offers robust command line verification, and maintains the premium "Apple-inspired" aesthetic consistently.

---

## 📅 Session: 2026-01-19 (Session 3)

### 🎯 Objective: Documentation Standardization & UI Finalization
This session focused on finalizing the project's documentation (internationalization), organizing the file structure to stay clean relative to the upstream repository, and refining the primary toolbar functions.

### ✅ Key Achievements:

1.  **Documentation Internationalization**:
    *   **Dual-Language Support**: Created `README.md` (English) and `README_tw.md` (Traditional Chinese) in the `AmpleWin` directory.
    *   **Mutual Linking**: Implemented language-switching headers in both README files for a professional GitHub experience.
    *   **Parity Verification**: Deep-dived into original macOS Objective-C source code to ensure the comparison table is 100% accurate regarding ROM downloading, bookmarked machine persistence, and technical differences.

2.  **UI Finalization & Utility Tools**:
    *   **Ample Dir Integration**: Renamed "Disk Images" to "📂 Ample Dir". It now acts as a shortcut to open the application directory in Windows Explorer.
    *   **Redirected Help**: Linked the "📖 Help" button directly to the official project GitHub sub-folder for instant user support.

3.  **Project Structure Hygiene**:
    *   **Namespace Isolation**: Relocated all Windows-specific overhead files (`README_tw.md`, `AmpleWin.bat`, `requirements.txt`, `Agent.md`) into the `AmpleWin` subdirectory.
    *   **Upstream Integrity**: Restored the root directory to its original state, ensuring a clean "1 commit ahead" status for easy upstream maintenance.
    *   **Script Resilience**: Updated `AmpleWin.bat` to handle the new directory structure, allowing execution directly from within the `AmpleWin` folder.

### 🚀 Current Project Status
The Windows Port is now a "ready-to-ship" localized product. The documentation is verified against the original Mac source code, the UI buttons serve practical Windows-specific needs, and the project stays respectful to the original repository's file structure.

---

## 📅 Session: 2026-01-18 (Session 2)

### 🎯 Objective: Deployment, Performance & Path Robustness
This session focused on making the application portable, optimizing the download engine for "instant" ROM acquisition, and improving the first-run user experience with guided setup.

### ✅ Key Achievements:

1.  **Deployment & Portability**:
    *   **Auto-Launcher**: Created `ample_win.bat` to automate dependency installation and app execution.
    *   **Dynamic Paths**: Replaced hardcoded absolute paths with a robust search algorithm that detects the `Ample/Resources` folder relative to the script location.
    *   **Environment Isolation**: Forced MAME working directory to `mame_bin`, ensuring `nvram`, `cfg`, and `diff` folders stay within the emulator directory and out of the project root.

2.  **Explosive Download Engine**:
    *   **Threading Mastery**: Transitioned to `QThreadPool` for manageable concurrency.
    *   **Performance Leap**: Increased parallel download threads from 1 to **50**.
    *   **Small File Optimization**: For ROM files (<64KB), switched from streaming to direct `requests.content` I/O, resulting in near-instant mass downloads.
    *   **Anti-Throttling**: Added browser-masking `User-Agent` headers.

3.  **User Experience (UX)**:
    *   **Startup Wizard**: Implemented sequential logic: Check MAME -> Guided Download -> Check ROMs -> Guided Download.
    *   **Sticky Software (Smart Carry-over)**: 
        *   Selections and filters now persist across compatible machines.
        *   **Compatibility Logic**: Automatically clears selection if the new machine doesn't support the current software list.
        *   **Full Name Display**: The search box now displays the full, descriptive software name instead of the short MAME ID.
        *   **UI Cleanliness**: Software lists stay collapsed during machine switches for a sleeker look.
    *   **Windows 10 Fixes**: Applied global CSS overrides for `QMessageBox` and `QDialog` to fix unreadable grey-on-white text issues on Windows 10.

4.  **Project Hygiene**:
    *   Updated `.gitignore` to exclude MAME runtime artifacts (`nvram/`, `cfg/`, `sta/`, etc.).
    *   Updated `README_win.md` with the new one-click launch instructions.

### 🚀 Current Project Status
Ample Windows is now highly portable and user-friendly. The download system is exceptionally fast, and the environment stays clean during emulation sessions.

## 📅 Session: 2026-01-18 (Session 1)

### 🎯 Objective: Software List Integration & Final UI Polish
This session focused on implementing the MAME Software List feature and refining the UI to achieve 100% aesthetic parity with the macOS version, including functional improvements to the MAME launch engine for Windows.

### ✅ Key Achievements:

1.  **Software List Feature**:
    *   **XML Parsing**: Enhanced `DataManager` to parse MAME's `hash/*.xml` files.
    *   **Intelligent Discovery**: Implemented a search-based software browser with autocomplete-style show/hide logic.
    *   **Auto-Detection**: Integrated software list selection into the MAME launch command with optimized argument ordering.

2.  **MAME Launch Engine**:
    *   **Argument Ordering**: Fixed Windows-specific software list resolution issues by placing software list items immediately after the machine name.
    *   **Path Isolation**: Standardized `-hashpath`, `-bgfx_path`, and `-rompath` to be relative to the application's `mame_bin` directory.
    *   **Resource Management**: Centralized ROM storage to `mame_bin\roms`.

3.  **UI Aesthetic Refinement**:
    *   **Apple Launch Button**: Replicated the Mac-style 🍎 icon inside the Launch button with left-aligned icon and right-aligned text.
    *   **Full-Width Console**: Moved the Command Preview to a full-width footer with a console-style (black background, monospace) styling.
    *   **Clean Mode**: Removed "Use Samples" checkbox and hardcoded `-nosamples` for authenticity.
    *   **Proportional Layout**: Expanded the options area to comfortably display long software names (60+ characters).

4.  **Stability & Initialization**:
    *   **Graceful Shutdown**: Improved thread termination logic in `closeEvent`.
    *   **Safe Initialization**: Fixed attribute and name errors in `DataManager` and `AmpleMainWindow` during early startup phases.

### 🚀 Current Project Status
The Windows Port is now functionally on par with the original Mac version, including the Software List feature. The UI is pixel-perfect and the launch engine is robust against common Windows path and argument pitfalls.

---

##  Handover Notes for Future Agents

### 1. UI Implementation Strategy (CRITICAL)
*   **Custom Combo Boxes**: Do NOT attempt to use native `QComboBox::down-arrow` CSS for the blue ↕ icon. Windows Qt has rendering issues (white dots/flicker). We use a **stacked overlay** strategy:
    *   A `QWidget` container holds the `QComboBox`.
    *   A `QLabel` with `Qt.WA_TransparentForMouseEvents` is positioned on top of the combo's right edge.
    *   This label has an opaque background (#3b7ee1) to mask the native Windows combo indicator dots.
*   **Alignment**: The global fixed width for slot combos is **160px**. The arrow overlay is **20px** wide.

### 2. Adaptive Theming
*   **Real-time Detection**: The app polls the Windows Registry every 2 seconds for theme changes.
*   **Centralized CSS**: Most UI colors are defined in `apply_premium_theme` using Python f-strings, allowing instant restyling of all common widgets.
*   **Persistent IDs**: Labels and special widgets use `setObjectName` to inherit styles from the global stylesheet, avoiding contrast issues during theme transitions.

### 3. State Management
*   **Sub-Slot Popups**: Tracked via `self.active_popup` in `AmpleMainWindow`. 
*   **Toggle Logic**: Uses `time.time()` threshold (0.3s) and `id(data)` check in `show_sub_slots()` to prevent the "immediate reopening" bug when clicking the hamburger button to close the popup.

### 4. Data Processing
*   `data_manager.py` handles the heavy lifting of parsing original Ample `.plist` files.
*   Slot changes trigger `self.refresh_ui()`, which rebuilds the dynamic slots layout from scratch to handle nested slot dependencies.

### 5. Known Mantras
*   **Visual Parity is King**: Every margin, font size (mostly 11px/12px), and color was cross-referenced with macOS high-res screenshots.
*   **Authorship**: This Windows Port is a collaboration between **anomixer** and **Antigravity**.
