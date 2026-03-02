import os
import requests
import subprocess
from PySide6.QtCore import QThread, Signal

class MameDownloadWorker(QThread):
    progress = Signal(int, int)
    finished = Signal(bool, str)
    status = Signal(str)

    def __init__(self, dest_dir):
        super().__init__()
        self.dest_dir = dest_dir
        # MAME official self-extracting EXE - Updated to 0.286
        self.url = "https://github.com/mamedev/mame/releases/download/mame0286/mame0286b_x64.exe"

    def run(self):
        try:
            self.status.emit("Downloading MAME installer...")
            response = requests.get(self.url, stream=True, timeout=60, allow_redirects=True)
            response.raise_for_status()
            total_size = int(response.headers.get('content-length', 0))
            
            # Use official filename from URL
            filename = self.url.split('/')[-1]
            exe_path = os.path.join(self.dest_dir, filename)
            os.makedirs(self.dest_dir, exist_ok=True)
            
            downloaded = 0
            with open(exe_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=65536):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        self.progress.emit(downloaded, total_size)
            
            self.status.emit("Opening installer...")
            # Use os.startfile to run the self-extractor on Windows
            os.startfile(exe_path)
            self.finished.emit(True, exe_path)
                
        except Exception as e:
            self.status.emit(f"Error: {str(e)}")
            self.finished.emit(False, str(e))

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
            
            # Create a temporary directory for extraction to avoid overwriting existing mame.exe
            temp_extract_dir = os.path.join(self.dest_dir, "_vgm_temp")
            os.makedirs(temp_extract_dir, exist_ok=True)
            
            # Extract mame.exe to the temporary directory
            extract_cmd = ["7z", "e", archive_path, "mame.exe", "-o" + temp_extract_dir, "-y"]
            
            try:
                subprocess.run(extract_cmd, check=True, capture_output=True)
            except (subprocess.CalledProcessError, FileNotFoundError):
                # Fallback to common Program Files path if 7z not in PATH
                pf_7z = r"C:\Program Files\7-Zip\7z.exe"
                if os.path.exists(pf_7z):
                    extract_cmd[0] = pf_7z
                    subprocess.run(extract_cmd, check=True, capture_output=True)
                else:
                    raise Exception("7-Zip (7z.exe) not found. Please install it to extract the VGM Mod.")

            # Move and rename extracted mame.exe to mame-vgm.exe in the main dest_dir
            extracted_mame = os.path.join(temp_extract_dir, "mame.exe")
            target_vgm_exe = os.path.join(self.dest_dir, "mame-vgm.exe")
            
            if os.path.exists(extracted_mame):
                if os.path.exists(target_vgm_exe):
                    os.remove(target_vgm_exe)
                os.rename(extracted_mame, target_vgm_exe)
            
            # Clean up temporary directory and archive
            try:
                if os.path.exists(temp_extract_dir):
                    import shutil
                    shutil.rmtree(temp_extract_dir)
            except Exception:
                pass
            
            if os.path.exists(archive_path):
                os.remove(archive_path)

            self.finished.emit(True, target_vgm_exe)
                
        except Exception as e:
            self.status.emit(f"Error: {str(e)}")
            self.finished.emit(False, str(e))
