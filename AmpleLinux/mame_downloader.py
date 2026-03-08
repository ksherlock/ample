import os
import requests
import subprocess
import shutil
from PySide6.QtCore import QThread, Signal


class VgmModDownloadWorker(QThread):
    progress = Signal(int, int)
    finished = Signal(bool, str)
    status = Signal(str)

    def __init__(self, dest_dir):
        super().__init__()
        self.dest_dir = dest_dir

    def run(self):
        # Try multiple URLs for VGM support
        urls = [
            "https://vgmrips.net/programs/creators/MAME0280_bin64_2025-11-16.7z",
            "https://github.com/anomixer/ample/raw/mame-vgm/MAME0280_bin64_2025-11-16.7z",
            "https://github.com/anomixer/ample/blob/mame-vgm/MAME0280_bin64_2025-11-16.7z?raw=true"
        ]
        
        last_error = ""
        success = False
        archive_path = ""
        
        try:
            for url in urls:
                try:
                    self.status.emit(f"Downloading MAME VGM Mod...")
                    response = requests.get(url, stream=True, timeout=60, allow_redirects=True)
                    response.raise_for_status()
                    total_size = int(response.headers.get('content-length', 0))
                    
                    filename = "mame_vgm_mod.7z"
                    archive_path = os.path.join(self.dest_dir, filename)
                    os.makedirs(self.dest_dir, exist_ok=True)
                    
                    downloaded = 0
                    with open(archive_path, 'wb') as f:
                        for chunk in response.iter_content(chunk_size=65536):
                            if chunk:
                                f.write(chunk)
                                downloaded += len(chunk)
                                self.progress.emit(downloaded, total_size)
                    success = True
                    break
                except Exception as e:
                    last_error = str(e)
                    continue
            
            if not success:
                self.finished.emit(False, f"Failed to download from all mirrors. Last error: {last_error}")
                return

            self.status.emit("Extracting VGM Mod...")
            
            # Create a temporary directory for extraction to avoid overwriting existing mame
            temp_extract_dir = os.path.join(self.dest_dir, "_vgm_temp")
            os.makedirs(temp_extract_dir, exist_ok=True)
            
            # Extract mame.exe (the Windows binary inside the archive) to the temp directory
            # On Linux we use 7z from PATH (p7zip-full package)
            extract_cmd = ["7z", "e", archive_path, "mame.exe", "-o" + temp_extract_dir, "-y"]
            
            try:
                subprocess.run(extract_cmd, check=True, capture_output=True)
            except (subprocess.CalledProcessError, FileNotFoundError) as e:
                raise Exception(
                    "7z not found. Please install p7zip-full:\n"
                    "  Ubuntu/Debian: sudo apt install p7zip-full\n"
                    "  Fedora: sudo dnf install p7zip-plugins\n"
                    "  Arch: sudo pacman -S p7zip"
                )

            # Note: VGM Mod is Windows-only (mame.exe). On Linux, this would need
            # Wine to run. We still extract and rename it for users who may use Wine.
            extracted_mame = os.path.join(temp_extract_dir, "mame.exe")
            target_vgm = os.path.join(self.dest_dir, "mame-vgm")
            
            if os.path.exists(extracted_mame):
                if os.path.exists(target_vgm):
                    os.remove(target_vgm)
                os.rename(extracted_mame, target_vgm)
            
            # Clean up temporary directory and archive
            try:
                if os.path.exists(temp_extract_dir):
                    shutil.rmtree(temp_extract_dir)
            except Exception:
                pass
            
            if os.path.exists(archive_path):
                os.remove(archive_path)

            self.finished.emit(True, target_vgm)
                
        except Exception as e:
            self.status.emit(f"Error: {str(e)}")
            self.finished.emit(False, str(e))
