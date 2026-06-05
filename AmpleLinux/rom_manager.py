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
            "https://mdk.cab/download/split/",
            "https://www.callapple.org/roms/"
        ]
        self.rom_list = self.load_rom_list()

    def load_rom_list(self):
        path = os.path.join(self.resources_path, "roms.plist")
        if not os.path.exists(path):
            roms = []
        else:
            with open(path, 'rb') as f:
                roms = plistlib.load(f)

        # Compatibility fallback: Add back ROMs removed by upstream but still supported by mdk.cab
        custom_roms = [
            {'value': 'tk3000', 'description': 'TK3000 //e'},
            {'value': 'prav8c', 'description': 'Pravetz 8C'},
            {'value': 'prav82', 'description': 'Pravetz 82'},
            {'value': 'prav8m', 'description': 'Pravetz 8M'},
            {'value': 'prav8d', 'description': 'Pravetz 8D'}
        ]
        existing_values = {r.get('value') for r in roms if 'value' in r}
        for cr in custom_roms:
            if cr['value'] not in existing_values:
                roms.append(cr)
        return roms

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
