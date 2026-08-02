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
                
                # Special patch for dragon32 to merge MDK split files if missing
                if self.value == 'dragon32':
                    self.patch_dragon32()
                
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

    def patch_dragon32(self):
        try:
            mdk_url = "https://mdk.cab/download/split/dragon32.zip"
            resp = requests.get(mdk_url, headers=self.headers, timeout=20)
            if resp.status_code == 200 and len(resp.content) > 100:
                import zipfile, io
                existing_data = open(self.dest_path, 'rb').read()
                z_existing = zipfile.ZipFile(io.BytesIO(existing_data))
                z_mdk = zipfile.ZipFile(io.BytesIO(resp.content))
                
                existing_names = set(z_existing.namelist())
                mdk_names = set(z_mdk.namelist())
                
                missing = mdk_names - existing_names
                if missing:
                    out_buf = io.BytesIO()
                    with zipfile.ZipFile(out_buf, 'w', zipfile.ZIP_DEFLATED) as zout:
                        for item in z_existing.infolist():
                            zout.writestr(item, z_existing.read(item.filename))
                        for item in z_mdk.infolist():
                            if item.filename in missing:
                                zout.writestr(item, z_mdk.read(item.filename))
                    with open(self.dest_path, 'wb') as f:
                        f.write(out_buf.getvalue())
        except Exception as e:
            print(f"Warning: dragon32 patch failed: {e}")

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
            {'value': 'prav8d', 'description': 'Pravetz 8D'},
            {'value': 'las128ex', 'description': 'Laser 128EX'},
            {'value': 'las128e2', 'description': 'Laser 128EX/2'},
            {'value': 'laser128', 'description': 'Laser 128'},
            {'value': 'laser128o', 'description': 'Laser 128 (Original)'},
            {'value': 'laser2c', 'description': 'Laser 2c'}
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
