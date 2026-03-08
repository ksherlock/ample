# Pull Request: Fix missing ROM definitions and suggest updated download URL

## 🔍 Symptom
When selecting certain machines in Ample—specifically the **Macintosh PowerBook Duo 280**, **PowerBook Duo 280c**, **Pravetz 8C/82/8M**, and **TK3000 //e**—the application reports missing firmwares. However, these ROMs cannot be found or downloaded through the built-in firmware manager because they are missing from the `roms.plist` definitions, despite being correctly referenced in `models.plist`.

## 🎯 Objective
This PR fixes this discrepancy by adding the missing ROM entries to `Ample/Resources/roms.plist`. It ensures that all machines currently supported by the model definitions can actually be used by allowing the UI to identify and acquire their necessary firmwares. Additionally, we include a suggestion for the download source to improve overall reliability.

---

## 🛠️ Changes in `Ample/Resources/roms.plist`

The following system ROMs were defined in `models.plist` but missing from the firmware management list, preventing users from identifying or downloading required files via the UI.

### 1. Macintosh Additions
*   **Target**: After `macpd270c` (around line 1636).
*   **Added**: `macpd280` (Macintosh PowerBook Duo 280).
*   **Reason**: Consistency with the already present `macpd280c`.

### 2. Apple II Clone & Sub-system Additions
*   **Target**: After `ym2608` (around line 2488).
*   **Added**: 
    *   `prav8c` (Pravetz 8C)
    *   `prav82` (Pravetz 82)
    *   `prav8m` (Pravetz 8M)
    *   `tk3000` (TK3000 //e)
    *   `prav8ckb` (Pravetz 8C Keyboard)
*   **Reason**: These machines are functional in the core but currently report firmwares as "Not Specified" or "Download Failed" due to missing plist descriptors.

---

## 📝 Proposed XML Snippets

### Location 1: PowerBook Duo Series
```xml
    <dict>
      <key>value</key>
      <string>macpd280</string>
      <key>description</key>
      <string>Macintosh PowerBook Duo 280</string>
    </dict>
```

### Location 2: Apple II Clones & Peripherals
```xml
    <dict>
      <key>value</key>
      <string>prav8c</string>
      <key>description</key>
      <string>Pravetz 8C</string>
    </dict>
    <dict>
      <key>value</key>
      <string>tk3000</string>
      <key>description</key>
      <string>TK3000 //e</string>
    </dict>
    <dict>
      <key>value</key>
      <string>prav82</string>
      <key>description</key>
      <string>Pravetz 82</string>
    </dict>
    <dict>
      <key>value</key>
      <string>prav8m</string>
      <key>description</key>
      <string>Pravetz 8M</string>
    </dict>
    <dict>
      <key>value</key>
      <string>prav8ckb</string>
      <key>description</key>
      <string>Pravetz 8C Keyboard</string>
    </dict>
```

---

## 🌐 Download URL Suggestion
Currently, Ample relies on `callapple.org`. During testing for the Windows port, we observed that:
*   `callapple.org` successfully covers the **PowerBook Duo 280/280c** ROMs.
*   However, it **lacks coverage** for some Apple II clones such as the **Pravetz** series and **TK3000 //e**.

Therefore, we suggest adding:
**`https://mdk.cab/download/split/`**
as a secondary/fallback URL. It provides complete coverage for these clones and more modern MAME split sets, ensuring a 100% success rate for the systems that are missing on the primary server.

You might also consider implementing a selectable URL list (similar to the **AmpleWin** port) that allows users to pick their preferred source (e.g., mdk.cab or callapple) or automatically failover between them for maximum reliability.

---

## 🎨 About the AmpleWin Port
This PR is submitted in conjunction with the development of **AmpleWin**, a precision Windows port of your project. You can explore the project and its detailed documentation here:
*   Project Home: **[https://github.com/anomixer/ample](https://github.com/anomixer/ample)**
*   Windows Subdirectory & README: **[https://github.com/anomixer/ample/tree/master/AmpleWin](https://github.com/anomixer/ample/tree/master/AmpleWin)**

Our goal is to achieve **near 100% UI fidelity** and feature parity for Windows users. To maintain a clean integration, all Windows-specific logic, scripts, and binaries are strictly isolated within the `AmpleWin/` subdirectory. We strive to keep the upstream root directory and resources untouched. We are only proposing these changes to `Ample/Resources/roms.plist` because they are functionally essential to allow all machines in the library to be fully "bootable" via the UI for all users.

Thanks for your consideration.

---
*Note: This PR content was prepared by Antigravity AI as part of the AmpleWin Windows port project.*
