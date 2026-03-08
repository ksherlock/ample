import os
import requests
import plistlib
from PySide6.QtCore import QObject, Signal, QRunnable, QThreadPool

class DownloadSignals(QObject):
    progress = Signal(int, int) # current, total
    finished = Signal(str, bool) # value, success
    status = Signal(str)

class DownloadWorker(QRunnable):
    def __init__(self, urls, dest_path, value):
        super().__init__()
        self.urls = urls if isinstance(urls, list) else [urls]
        self.dest_path = dest_path
        self.value = value
        self.signals = DownloadSignals()
        self._is_cancelled = False
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }

    def cancel(self):
        self._is_cancelled = True

    def run(self):
        last_error = "No URLs provided"
        for url in self.urls:
            try:
                if self._is_cancelled: return
                
                # For small files (ROMs), direct download is much faster than streaming
                response = requests.get(url, headers=self.headers, timeout=20)
                response.raise_for_status()
                
                os.makedirs(os.path.dirname(self.dest_path), exist_ok=True)
                
                if self._is_cancelled: return
                
                with open(self.dest_path, 'wb') as f:
                    f.write(response.content)
                
                self.signals.finished.emit(self.value, True)
                return # Success!
            except Exception as e:
                last_error = str(e)
                continue # Try next URL
        
        # If we get here, all URLs failed
        if os.path.exists(self.dest_path):
            try: os.remove(self.dest_path)
            except: pass
        self.signals.status.emit(f"Error: {last_error}")
        self.signals.finished.emit(self.value, False)

class RomManager(QObject):
    def __init__(self, resources_path, roms_dir):
        super().__init__()
        self.resources_path = resources_path
        self.roms_dir = roms_dir
        self.base_urls = [
            "https://www.callapple.org/roms/",
            "https://mdk.cab/download/split/"
        ]
        self.rom_list = self.load_rom_list()

    def load_rom_list(self):
        path = os.path.join(self.resources_path, "roms.plist")
        if not os.path.exists(path):
            return []
        with open(path, 'rb') as f:
            return plistlib.load(f)

    def get_rom_status(self):
        status_list = []
        for rom in self.rom_list:
            value = rom['value']
            # Check for zip, 7z or folder
            found = False
            for ext in ['zip', '7z']:
                path = os.path.join(self.roms_dir, f"{value}.{ext}")
                if os.path.exists(path):
                    found = True
                    break
            
            if not found:
                # Check for unzipped folder
                path = os.path.join(self.roms_dir, value)
                if os.path.isdir(path):
                    found = True
            
            status_list.append({
                'value': value,
                'description': rom['description'],
                'exists': found
            })
        return status_list

    def get_download_url(self, value, ext='zip'):
        return f"{self.base_url}{value}.{ext}"
