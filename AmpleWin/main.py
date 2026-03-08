import sys
import os
import subprocess
import time
from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QListWidget, QListWidgetItem, QLabel, 
                             QLineEdit, QPushButton, QFrame, QSplitter, QScrollArea,
                             QComboBox, QCheckBox, QGroupBox, QFileDialog, QDialog,
                             QProgressBar, QMessageBox, QTabWidget, QTreeWidget, 
                             QTreeWidgetItem, QTextEdit, QGridLayout, QButtonGroup,
                             QSizePolicy, QMenu)
from PySide6.QtCore import Qt, QSize, Signal, Slot, QSettings, QPoint, QRect, QTimer, QThreadPool, QRunnable, QEvent, QThread
from PySide6.QtGui import QFont, QIcon, QPalette, QColor, QCloseEvent, QPainter, QPainterPath

import shutil
from data_manager import DataManager
from mame_launcher import MameLauncher
from rom_manager import RomManager, DownloadWorker
from mame_downloader import MameDownloadWorker, VgmModDownloadWorker

try:
    import winreg
except ImportError:
    winreg = None

class VgmPostProcessWorker(QThread):
    finished = Signal()

    def __init__(self, process, src_dir, rom_name, dest_path):
        super().__init__()
        self.process = process
        self.src_dir = src_dir
        self.rom_name = rom_name
        self.dest_path = dest_path

    def run(self):
        # Wait for MAME to exit
        self.process.wait()
        
        # MAME-VGM mod saves as <romname>_0.vgm in the working directory (mame)
        # Note: sometimes it might be <machine>_0.vgm
        src_file = os.path.join(self.src_dir, f"{self.rom_name}_0.vgm")
        if os.path.exists(src_file) and self.dest_path:
            try:
                dest_dir = os.path.dirname(self.dest_path)
                if dest_dir: os.makedirs(dest_dir, exist_ok=True)
                if os.path.exists(self.dest_path):
                    os.remove(self.dest_path)
                shutil.move(src_file, self.dest_path)
                print(f"VGM captured and moved to: {self.dest_path}")
            except Exception as e:
                print(f"Failed to move VGM file: {e}")
        self.finished.emit()

class RomItemWidget(QWidget):
    def __init__(self, description, value, exists, parent=None):
        super().__init__(parent)
        self.exists = exists
        layout = QVBoxLayout(self)
        layout.setContentsMargins(10, 5, 10, 5)
        layout.setSpacing(2)
        
        self.title_label = QLabel(description)
        self.status_label = QLabel("ROM found" if exists else "ROM missing")
        
        layout.addWidget(self.title_label)
        layout.addWidget(self.status_label)
        self.apply_theme()

    def apply_theme(self):
        is_dark = self.window().is_dark_mode() if hasattr(self.window(), 'is_dark_mode') else True
        if not hasattr(self.window(), 'is_dark_mode'):
            # Fallback if window not yet active
            main_win = next((w for w in QApplication.topLevelWidgets() if isinstance(w, QMainWindow)), None)
            if main_win and hasattr(main_win, 'is_dark_mode'):
                is_dark = main_win.is_dark_mode()

        title_color = ("#ffffff" if self.exists else "#ff4d4d") if is_dark else ("#1a1a1a" if self.exists else "#d32f2f")
        self.title_label.setStyleSheet(f"font-weight: bold; font-size: 13px; color: {title_color};")
        self.status_label.setStyleSheet(f"font-size: 11px; color: #888888;")

class RomManagerDialog(QDialog):
    def __init__(self, rom_manager, parent=None):
        super().__init__(parent)
        self.rom_manager = rom_manager
        self.setWindowTitle("ROMs")
        self.setMinimumSize(650, 550)
        self.filter_mode = "all" # "all" or "missing"
        self.init_ui()
        self.apply_dialog_theme()
        self.refresh_list()

    def init_ui(self):
        self.setObjectName("RomDialog")
        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # 1. Header with Segmented Control
        header = QWidget()
        header.setFixedHeight(50)
        header_layout = QHBoxLayout(header)
        
        self.seg_all = QPushButton("All")
        self.seg_all.setCheckable(True)
        self.seg_all.setChecked(True)
        self.seg_missing = QPushButton("Missing")
        self.seg_missing.setCheckable(True)
        
        self.seg_group = QButtonGroup(self)
        self.seg_group.addButton(self.seg_all)
        self.seg_group.addButton(self.seg_missing)
        self.seg_group.buttonClicked.connect(self.on_filter_changed)

        self.rom_search = QLineEdit()
        self.rom_search.setPlaceholderText("Search ROMs...")
        self.rom_search.setFixedWidth(200)
        self.rom_search.textChanged.connect(self.refresh_list)
        
        header_layout.addWidget(self.rom_search)
        header_layout.addSpacing(20)
        header_layout.addWidget(self.seg_all)
        header_layout.addWidget(self.seg_missing)
        header_layout.addStretch()
        main_layout.addWidget(header)

        # 2. ROM List
        self.rom_list = QListWidget()
        self.rom_list.setObjectName("RomList")
        main_layout.addWidget(self.rom_list)

        # 3. Progress Area (Hidden by default)
        self.progress_area = QWidget()
        self.progress_area.setVisible(False)
        p_layout = QVBoxLayout(self.progress_area)
        self.progress_bar = QProgressBar()
        self.status_label = QLabel("")
        p_layout.addWidget(self.status_label)
        p_layout.addWidget(self.progress_bar)
        main_layout.addWidget(self.progress_area)

        # 4. Settings Footer
        footer = QWidget()
        footer.setObjectName("RomFooter")
        footer_layout = QVBoxLayout(footer)
        footer_layout.setContentsMargins(15, 15, 15, 15)
        
        url_layout = QHBoxLayout()
        url_layout.addWidget(QLabel("URL"))
        self.url_combo = QComboBox()
        self.url_combo.setEditable(True)
        self.url_combo.addItems(self.rom_manager.base_urls)
        url_layout.addWidget(self.url_combo)
        footer_layout.addLayout(url_layout)
        
        type_layout = QHBoxLayout()
        type_layout.addWidget(QLabel("Type"))
        self.type_combo = QComboBox()
        self.type_combo.addItems(["zip", "7z"])
        type_layout.addWidget(self.type_combo)
        type_layout.addStretch()
        footer_layout.addLayout(type_layout)
        
        # 5. Buttons Footer
        btns_layout = QHBoxLayout()
        self.refresh_btn = QPushButton("Refresh")
        self.refresh_btn.clicked.connect(self.refresh_list)
        
        self.open_roms_btn = QPushButton("📁 ROMs")
        self.open_roms_btn.clicked.connect(self.open_roms_folder)
        
        self.download_btn = QPushButton("Download Missing")
        self.download_btn.setObjectName("PrimaryButton")
        self.download_btn.clicked.connect(self.download_missing)
        
        self.cancel_btn = QPushButton("Cancel")
        self.cancel_btn.clicked.connect(self.reject)
        
        btns_layout.addWidget(self.refresh_btn)
        btns_layout.addWidget(self.open_roms_btn)
        btns_layout.addStretch()
        btns_layout.addWidget(self.download_btn)
        btns_layout.addWidget(self.cancel_btn)
        footer_layout.addLayout(btns_layout)
        
        main_layout.addWidget(footer)
        
        self.apply_dialog_theme()

    def on_filter_changed(self, btn):
        self.filter_mode = "all" if btn == self.seg_all else "missing"
        self.refresh_list()

    def refresh_list(self):
        self.rom_list.clear()
        statuses = self.rom_manager.get_rom_status()
        query = self.rom_search.text().lower()
        
        for s in statuses:
            if self.filter_mode == "missing" and s['exists']:
                continue
                
            if query and query not in s['description'].lower() and query not in s['value'].lower():
                continue

            item = QListWidgetItem(self.rom_list)
            widget = RomItemWidget(s['description'], s['value'], s['exists'])
            item.setSizeHint(widget.sizeHint())
            self.rom_list.addItem(item)
            self.rom_list.setItemWidget(item, widget)

    def open_roms_folder(self):
        os.startfile(self.rom_manager.roms_dir)

    def download_missing(self):
        primary_url = self.url_combo.currentText()
        if not primary_url.endswith("/"):
            primary_url += "/"
            
        statuses = self.rom_manager.get_rom_status()
        self.to_download = [s for s in statuses if not s['exists']]
        if not self.to_download:
            QMessageBox.information(self, "Done", "All ROMs are already present!")
            return
        
        self.progress_area.setVisible(True)
        self.download_total = len(self.to_download)
        self.download_finished_count = 0
        self.download_failed_count = 0  # Reset failed count
        self.progress_bar.setMaximum(self.download_total)
        self.progress_bar.setValue(0)
        
        # Ultra-fast Concurrent Execution using QThreadPool
        pool = QThreadPool.globalInstance()
        # Set to 50 to allow explosive downloading of many small files
        if pool.maxThreadCount() < 50:
            pool.setMaxThreadCount(50)
            
        for current in self.to_download:
            value = current['value']
            ext = self.type_combo.currentText()
            
            # Prepare all possible URLs: Primary (UI) + others from the list
            urls = []
            primary_url = self.url_combo.currentText()
            if not primary_url.endswith("/"): primary_url += "/"
            urls.append(f"{primary_url}{value}.{ext}")
            
            for base in self.rom_manager.base_urls:
                if base.strip("/") != primary_url.strip("/"):
                    if not base.endswith("/"): base += "/"
                    urls.append(f"{base}{value}.{ext}")
            
            dest = os.path.join(self.rom_manager.roms_dir, f"{value}.{ext}")
            
            worker = DownloadWorker(urls, dest, value)
            # Signal handling for QRunnable via proxy object
            worker.signals.finished.connect(lambda v, s, w=worker: self.on_concurrent_download_finished(w, v, s))
            pool.start(worker)

    def on_concurrent_download_finished(self, worker, value, success):
        self.download_finished_count += 1
        if not success:
            self.download_failed_count = getattr(self, "download_failed_count", 0) + 1
            
        self.progress_bar.setValue(self.download_finished_count)
        self.status_label.setText(f"Finished {self.download_finished_count}/{self.download_total}: {value}")
        
        if self.download_finished_count == self.download_total:
            self.progress_area.setVisible(False)
            failed = getattr(self, "download_failed_count", 0)
            if failed > 0:
                QMessageBox.warning(self, "Finished", f"Downloaded {self.download_total - failed} ROMs, but {failed} failed.\nSome files might not exist on the server.")
            else:
                QMessageBox.information(self, "Finished", f"Successfully downloaded all {self.download_total} ROMs!")
            self.refresh_list()

    def apply_dialog_theme(self):
        main_win = next((w for w in QApplication.topLevelWidgets() if isinstance(w, QMainWindow)), None)
        is_dark = main_win.is_dark_mode() if main_win else True
        
        bg_main = "#1e1e1e" if is_dark else "#f5f5f7"
        bg_list = "#1a1a1a" if is_dark else "#ffffff"
        border = "#3d3d3d" if is_dark else "#d1d1d1"
        text = "#eeeeee" if is_dark else "#1a1a1a"
        btn_bg = "#3d3d3d" if is_dark else "#e0e0e0"

        self.setStyleSheet(f"""
            QDialog#RomDialog {{ background-color: {bg_main}; color: {text}; }}
            #RomList {{ 
                background-color: {bg_list}; 
                border-top: 1px solid {border};
                border-bottom: 1px solid {border};
            }}
            #RomFooter {{ background-color: {bg_main}; }}
            
            QPushButton {{
                background-color: {btn_bg};
                border: 1px solid {border};
                color: {text};
                padding: 6px 12px;
                border-radius: 4px;
            }}
            QPushButton:hover {{ background-color: {"#4d4d4d" if is_dark else "#d0d0d0"}; }}
            
            #PrimaryButton {{ background-color: #0078d4; border: none; font-weight: bold; color: white; }}
            #PrimaryButton:hover {{ background-color: #1a8ad4; }}
            
            QLineEdit, QComboBox {{
                background-color: {bg_list};
                border: 1px solid {border};
                border-radius: 4px;
                padding: 4px;
                color: {text};
            }}
            
            QLabel {{ color: {text}; font-size: 12px; }}
            
            QProgressBar {{
                border: 1px solid {border};
                border-radius: 4px;
                text-align: center;
                height: 15px;
            }}
            QProgressBar::chunk {{ background-color: #0078d4; }}
        """)

# --- Sub-Slot Popup (The popover from Mac version) ---
class SubSlotPopup(QDialog):
    def __init__(self, parent, data, current_slots, on_change_callback):
        super().__init__(parent)
        self.setWindowFlags(Qt.Popup | Qt.FramelessWindowHint)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.data = data
        self.current_slots = current_slots
        self.on_change_callback = on_change_callback
        self.init_ui()

    def closeEvent(self, event):
        if hasattr(self.parent(), 'active_popup') and self.parent().active_popup == self:
            self.parent().last_popup_close_time = time.time()
            self.parent().last_popup_id = id(self.data)
            self.parent().active_popup = None
        super().closeEvent(event)

    def init_ui(self):
        # Overall container to allow for the pointer arrow on top
        self.main_layout = QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 10, 0, 0) # Top margin for arrow
        
        self.container = QWidget()
        self.container.setObjectName("BubbleContainer")
        self.container.setStyleSheet("""
            QWidget#BubbleContainer {
                background-color: #262626;
                border: 1px solid #3d3d3d;
                border-radius: 12px;
            }
        """)
        
        self.content_layout = QVBoxLayout(self.container)
        self.content_layout.setContentsMargins(15, 20, 15, 15)
        self.content_layout.setSpacing(8)

        # Close button
        self.close_btn = QPushButton("×", self.container)
        self.close_btn.setFixedSize(20, 20)
        self.close_btn.setStyleSheet("color: #aaa; background: #444; border-radius: 10px; border:none; font-weight:bold;")
        self.close_btn.move(250, 8)
        self.close_btn.clicked.connect(self.close)

        if 'slots' in self.data:
            for slot in self.data['slots']:
                options = slot.get('options', [])
                combo = QComboBox()
                combo.setFixedWidth(180)
                combo.setFixedHeight(22)
                combo.setProperty("appleStyle", "slot")
                
                slot_name = slot['name']
                combo.setObjectName(slot_name)
                for opt in options:
                    combo.addItem(opt.get('description') or opt['value'] or "—None—", opt['value'])

                combo.blockSignals(True)
                val = self.current_slots.get(slot_name)
                idx = combo.findData(str(val))
                if idx < 0: idx = combo.findData(val)
                if idx >= 0: combo.setCurrentIndex(idx)
                combo.blockSignals(False)
                
                combo.currentIndexChanged.connect(self.on_changed)
                
                # Create container with combo and arrow overlay (matching main window)
                combo_widget = QWidget()
                combo_widget.setFixedSize(180, 22)
                combo.setParent(combo_widget)
                combo.move(0, 0)
                
                # Arrow label overlay - narrow blue like Mac
                arrow_label = QLabel("↕", combo_widget)
                arrow_label.setFixedSize(20, 20)
                arrow_label.move(160, 1)  # 160 + 20 = 180
                arrow_label.setAlignment(Qt.AlignCenter)
                arrow_label.setStyleSheet("""
                    background-color: #3b7ee1;
                    color: white;
                    font-size: 12px;
                    font-weight: bold;
                    padding-bottom: 3px;
                    border: none;
                    border-top-right-radius: 3px;
                    border-bottom-right-radius: 3px;
                """)
                arrow_label.setAttribute(Qt.WA_TransparentForMouseEvents)
                
                self.content_layout.addWidget(combo_widget, 0, Qt.AlignCenter)

        self.main_layout.addWidget(self.container)
        self.apply_theme()
        self.setFixedWidth(280)

    def paintEvent(self, event):
        painter = QPainter(self)
        try:
            main_win = next((w for w in QApplication.topLevelWidgets() if isinstance(w, QMainWindow)), None)
            is_dark = main_win.is_dark_mode() if main_win else True
            
            painter.setRenderHint(QPainter.Antialiasing)
            painter.setBrush(QColor("#262626" if is_dark else "#f5f5f7"))
            painter.setPen(Qt.NoPen)
            
            # Draw a triangle pointing up at the middle
            path = QPainterPath()
            mw = self.width() / 2
            path.moveTo(mw - 10, 11)
            path.lineTo(mw, 0)
            path.lineTo(mw + 10, 11)
            painter.drawPath(path)
        finally:
            painter.end()

    def apply_theme(self):
        main_win = next((w for w in QApplication.topLevelWidgets() if isinstance(w, QMainWindow)), None)
        is_dark = main_win.is_dark_mode() if main_win else True
        
        bg = "#262626" if is_dark else "#f5f5f7"
        border = "#3d3d3d" if is_dark else "#d1d1d1"
        combo_bg = "#3d3d3d" if is_dark else "#ffffff"
        text = "#eeeeee" if is_dark else "#1a1a1a"

        self.setStyleSheet(f"""
            QWidget#BubbleContainer {{
                background-color: {bg};
                border: 1px solid {border};
                border-radius: 12px;
            }}
            QComboBox {{
                background-color: {combo_bg};
                border: 1px solid {border};
                border-radius: 4px;
                padding: 2px 20px 2px 8px;
                color: {text};
                font-size: 11px;
                min-height: 18px;
            }}
            QComboBox::drop-down {{
                width: 0px;
                border: none;
            }}
            QComboBox::down-arrow {{
                image: none;
                width: 0px;
                height: 0px;
            }}
            QComboBox:hover {{
                border-color: {"#777" if is_dark else "#999"};
            }}
        """)

    def on_changed(self):
        combo = self.sender()
        self.current_slots[combo.objectName()] = combo.currentData()
        self.on_change_callback()

# --- Software List Popup (Overlay) ---
class SoftwarePopup(QDialog):
    def __init__(self, parent):
        super().__init__(parent)
        # 使用 Qt.Tool 確保它附屬於主視窗，且不會永遠置頂（Always on Top）
        self.setWindowFlags(Qt.Tool | Qt.FramelessWindowHint | Qt.NoFocus)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setAttribute(Qt.WA_ShowWithoutActivating)
        
        self.main_layout = QVBoxLayout(self)
        self.main_layout.setContentsMargins(0, 10, 0, 0) # Top margin for arrow
        
        self.container = QFrame()
        self.container.setObjectName("BubbleContainer")
        
        self.layout = QVBoxLayout(self.container)
        self.layout.setContentsMargins(2, 2, 2, 2)
        
        self.list_widget = QListWidget()
        self.list_widget.setObjectName("SoftwareListPopup")
        self.layout.addWidget(self.list_widget)
        self.main_layout.addWidget(self.container)
        self.apply_theme()
        self.setFixedHeight(300)

    def paintEvent(self, event):
        painter = QPainter(self)
        try:
            main_win = next((w for w in QApplication.topLevelWidgets() if isinstance(w, QMainWindow)), None)
            is_dark = main_win.is_dark_mode() if main_win else True
            
            painter.setRenderHint(QPainter.Antialiasing)
            painter.setBrush(QColor("#262626" if is_dark else "#f5f5f7"))
            painter.setPen(Qt.NoPen)
            path = QPainterPath()
            # Arrow pointing up
            mw = 40 
            path.moveTo(mw - 10, 11)
            path.lineTo(mw, 0)
            path.lineTo(mw + 10, 11)
            painter.drawPath(path)
        finally:
            painter.end()

    def apply_theme(self):
        main_win = next((w for w in QApplication.topLevelWidgets() if isinstance(w, QMainWindow)), None)
        is_dark = main_win.is_dark_mode() if main_win else True
        
        bg = "#262626" if is_dark else "#f5f5f7"
        border = "#3d3d3d" if is_dark else "#d1d1d1"
        text = "#cccccc" if is_dark else "#1a1a1a"
        item_border = "#333" if is_dark else "#e0e0e0"
        sel_bg = "#3b7ee1"
        
        self.container.setStyleSheet(f"""
            QFrame#BubbleContainer {{
                background-color: {bg};
                border: 1px solid {border};
                border-radius: 8px;
            }}
        """)
        
        self.list_widget.setStyleSheet(f"""
            QListWidget {{
                background: transparent;
                border: none;
                color: {text};
                font-size: 11px;
            }}
            QListWidget::item {{
                padding: 6px 12px;
                border-bottom: 1px solid {item_border};
            }}
            QListWidget::item:selected {{
                background-color: {sel_bg};
                color: white;
                border-radius: 4px;
            }}
            QListWidget::item:disabled {{
                color: {"#555" if is_dark else "#999"};
                font-weight: bold;
                background-color: {"#222" if is_dark else "#eee"};
            }}
            QScrollBar:vertical {{
                background: {"#1a1a1a" if is_dark else "#f0f0f0"};
                width: 10px;
                margin: 0;
            }}
            QScrollBar::handle:vertical {{
                background: {"#444" if is_dark else "#ccc"};
                min-height: 20px;
                border-radius: 5px;
                margin: 2px;
            }}
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {{
                height: 0;
            }}
        """)

    def show_at(self, widget):
        if self.list_widget.count() == 0:
            self.hide()
            return
        
        # 僅在尚未顯示或位置需要更新時處理，避免重複抓取導致卡頓
        self.setFixedWidth(widget.width())
        pos = widget.mapToGlobal(QPoint(0, widget.height() - 5))
        self.move(pos)
        if not self.isVisible():
            self.show()
        self.raise_()

class AmpleMainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Ample - Windows Port")
        self.setMinimumSize(1000, 750)
        
        # Paths
        if getattr(sys, 'frozen', False):
            # If running as PyInstaller OneDir/OneFile bundle
            self.app_dir = os.path.dirname(os.path.abspath(sys.executable))
        else:
            # If running from source (development)
            self.app_dir = os.path.dirname(os.path.abspath(__file__))
        
        # Robustly find Resources path
        self.resources_path = None
        curr = self.app_dir
        for _ in range(3): # Look up to 3 levels up
            candidate = os.path.join(curr, "Ample", "Resources")
            if os.path.exists(os.path.join(candidate, "models.plist")):
                self.resources_path = candidate
                break
            curr = os.path.dirname(curr)
            
        if not self.resources_path:
            # Fallback to current working directory
            candidate = os.path.join(os.getcwd(), "Ample", "Resources")
            if os.path.exists(os.path.join(candidate, "models.plist")):
                self.resources_path = candidate
        
        print(f"DEBUG: app_dir: {self.app_dir}")
        print(f"DEBUG: resolved resources_path: {self.resources_path}")
        
        mame_bin_dir = os.path.abspath(os.path.join(self.app_dir, "mame"))
        self.roms_dir = os.path.join(mame_bin_dir, "roms")
        mame_exe = os.path.join(mame_bin_dir, "mame.exe")
        hash_path = os.path.join(mame_bin_dir, "hash")
        
        self.data_manager = DataManager(self.resources_path, hash_path)
        self.rom_manager = RomManager(self.resources_path, self.roms_dir)
        self.launcher = MameLauncher()
        self.launcher.mame_path = mame_exe
        self.launcher.working_dir = mame_bin_dir
        
        self.selected_software = None # Storage for listname:itemname
        self.selected_software_desc = "" # Storage for full display name
        self.active_popup = None  # Track current open sub-slot popup
        self.last_popup_close_time = 0
        self.last_popup_id = None
        self.sw_search = None
        
        # Global stylesheet for combos with appleStyle="slot"
        self.setStyleSheet("""
            QComboBox[appleStyle="slot"] {
                background-color: #3d3d3d;
                border: 1px solid #555;
                border-radius: 4px;
                padding: 2px 20px 2px 8px;
                color: #eee;
                font-size: 11px;
                min-height: 18px;
            }
            QComboBox[appleStyle="slot"]::drop-down {
                width: 0px;
                border: none;
            }
            QComboBox[appleStyle="slot"]::down-arrow {
                image: none;
                width: 0px;
                height: 0px;
            }
        """)
        
        # Thread management
        self.active_workers = []
        
        # Settings Persistence
        self.settings = QSettings(os.path.join(self.roms_dir, "settings.ini"), QSettings.IniFormat)
        
        self.selected_machine = None
        self.current_slots = {}
        self.current_media = {}
        self.launcher.working_dir = mame_bin_dir
        
        self.init_ui()
        self.apply_premium_theme()
        self.load_persistent_settings()
        
        # 安裝全域事件過濾器以偵測點擊外部
        qApp.installEventFilter(self)
        
        # Theme polling
        self.last_theme_is_dark = self.is_dark_mode()
        self.theme_timer = QTimer(self)
        self.theme_timer.timeout.connect(self.check_theme_change)
        self.theme_timer.start(2000)

        # Sequentially check for MAME and then ROMs
        QTimer.singleShot(500, self.run_startup_checks)

    def is_dark_mode(self):
        if winreg:
            try:
                key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize")
                value, _ = winreg.QueryValueEx(key, "AppsUseLightTheme")
                return value == 0
            except:
                pass
        return self.palette().color(QPalette.Window).value() < 128

    def check_theme_change(self):
        current_is_dark = self.is_dark_mode()
        if current_is_dark != self.last_theme_is_dark:
            self.last_theme_is_dark = current_is_dark
            self.apply_premium_theme()
            
            # Refresh child dialogs and popups
            if hasattr(self, 'rom_manager_dialog') and self.rom_manager_dialog and self.rom_manager_dialog.isVisible():
                self.rom_manager_dialog.apply_dialog_theme()
                # Also need to refresh top-level widgets that might be using custom items
                for i in range(self.rom_manager_dialog.rom_list.count()):
                    item = self.rom_manager_dialog.rom_list.item(i)
                    if self.rom_manager_dialog.rom_list.itemWidget(item):
                        self.rom_manager_dialog.rom_list.itemWidget(item).apply_theme()

            if hasattr(self, 'sw_popup') and self.sw_popup:
                self.sw_popup.apply_theme()
            
            if self.active_popup and self.active_popup.isVisible():
                self.active_popup.apply_theme()
                self.active_popup.update() # Force repaint for triangle

    def run_startup_checks(self):
        """Sequential startup validation: MAME first, then ROMs."""
        if not self.check_for_mame():
            # If MAME is missing, focus on that first
            from PySide6.QtWidgets import QMessageBox
            reply = QMessageBox.question(self, "MAME Not Found", 
                                      "MAME executable was not found.\n\nWould you like to open settings to set MAME path or download it?",
                                      QMessageBox.Yes | QMessageBox.No)
            if reply == QMessageBox.Yes:
                self.show_settings()
            return

        # Only if MAME is found, we check for ROMs
        self.check_and_auto_roms()

    def check_and_auto_roms(self):
        statuses = self.rom_manager.get_rom_status()
        missing = [s for s in statuses if not s['exists']]
        if missing:
            # Short timer to show dialog after window is visible
            # QTimer already imported at top
            QTimer.singleShot(500, self.show_rom_manager)

    def open_ample_dir(self):
        os.startfile(self.app_dir)

    def open_help_url(self):
        os.startfile("https://github.com/anomixer/ample/tree/master/AmpleWin")

    def init_ui(self):
        container = QWidget()
        self.setCentralWidget(container)
        main_vbox = QVBoxLayout(container)
        main_vbox.setContentsMargins(0, 0, 0, 0)
        main_vbox.setSpacing(0)

        # 1. Toolbar (macOS Style)
        toolbar = QWidget()
        toolbar.setObjectName("Toolbar")
        toolbar.setFixedHeight(60)
        toolbar_layout = QHBoxLayout(toolbar)
        toolbar_layout.setContentsMargins(15, 0, 15, 0)
        
        tools = [
            ("📂 Ample Dir", self.open_ample_dir),
            ("🎮 ROMs", self.show_rom_manager),
            ("⚙️ Settings", self.show_settings),
            ("📖 Help", self.open_help_url)
        ]
        for name, slot in tools:
            btn = QPushButton(name)
            btn.setObjectName("ToolbarButton")
            if slot: btn.clicked.connect(slot)
            toolbar_layout.addWidget(btn)
        toolbar_layout.addStretch()
        main_vbox.addWidget(toolbar)

        # 2. Splitter for Tree and Main Area
        self.splitter = QSplitter(Qt.Horizontal)
        self.splitter.setHandleWidth(1)
        self.splitter.setObjectName("MainSplitter")
        
        # Left Panel: Machine Tree
        left_panel = QWidget()
        left_panel.setObjectName("LeftPanel")
        left_layout = QVBoxLayout(left_panel)
        left_layout.setContentsMargins(10, 10, 10, 10)
        
        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText("Find Machine...")
        self.search_input.setObjectName("SearchInput")
        self.search_input.textChanged.connect(self.filter_machines)
        
        self.machine_tree = QTreeWidget()
        self.machine_tree.setHeaderHidden(True)
        self.machine_tree.setObjectName("MachineTree")
        self.machine_tree.itemClicked.connect(self.on_machine_selected)
        self.machine_tree.itemDoubleClicked.connect(self.on_tree_double_clicked)
        self.populate_machine_tree(self.data_manager.models, self.machine_tree.invisibleRootItem())
        
        left_layout.addWidget(self.search_input)
        left_layout.addWidget(self.machine_tree)
        self.splitter.addWidget(left_panel)
        
        # Right Panel: Compact Configuration Area
        right_panel = QWidget()
        right_panel.setObjectName("RightPanel")
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(15, 10, 15, 10)
        right_layout.setSpacing(5)
        
        # Tabs (Centered and Compact)
        tab_container = QHBoxLayout()
        self.tabs = QTabWidget()
        self.tabs.setObjectName("MainTabs")
        self.tabs.setFixedHeight(120) # Compact height for video/cpu settings
        self.init_tabs()
        tab_container.addStretch()
        tab_container.addWidget(self.tabs)
        tab_container.addStretch()
        right_layout.addLayout(tab_container)

        # Body: Grid for Slots and Media
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet("background: transparent; border: none;")
        self.options_container = QWidget()
        self.options_grid = QGridLayout(self.options_container)
        self.options_grid.setContentsMargins(10, 10, 20, 10)
        self.options_grid.setSpacing(20)
        self.options_grid.setColumnStretch(0, 1)
        self.options_grid.setColumnStretch(1, 1)
        
        # Fixed containers to avoid grid stacking issues
        self.slots_frame = QWidget()
        self.slots_layout = QVBoxLayout(self.slots_frame)
        self.slots_layout.setContentsMargins(0, 0, 0, 0)
        self.slots_layout.setSpacing(10)
        self.options_grid.addWidget(self.slots_frame, 0, 0)
        
        self.media_frame = QWidget()
        self.media_layout = QVBoxLayout(self.media_frame)
        self.media_layout.setContentsMargins(0, 0, 0, 0)
        self.media_layout.setSpacing(10)
        self.options_grid.addWidget(self.media_frame, 0, 1)

        # Proportions: tree (managed by splitter), slots(1), media/software(2)
        self.options_grid.setColumnStretch(0, 1)
        self.options_grid.setColumnStretch(1, 2)
        
        scroll.setWidget(self.options_container)
        right_layout.addWidget(scroll)
        
        # Launch Area (Button only, right-aligned)
        launch_row = QHBoxLayout()
        self.launch_btn = QPushButton()
        self.launch_btn.setObjectName("LaunchButton")
        self.launch_btn.setFixedSize(110, 32)
        self.launch_btn.clicked.connect(self.launch_mame)
        
        # Internal layout to align icon left and text right
        btn_layout = QHBoxLayout(self.launch_btn)
        btn_layout.setContentsMargins(10, 0, 15, 0)
        
        icon_lbl = QLabel("🍎")
        icon_lbl.setAttribute(Qt.WA_TransparentForMouseEvents)
        icon_lbl.setStyleSheet("background: transparent; border: none; font-size: 14px;")
        
        text_lbl = QLabel("Launch")
        text_lbl.setAttribute(Qt.WA_TransparentForMouseEvents)
        text_lbl.setStyleSheet("background: transparent; border: none; font-weight: bold; color: white; font-size: 13px;")
        
        btn_layout.addWidget(icon_lbl)
        btn_layout.addStretch()
        btn_layout.addWidget(text_lbl)
        
        launch_row.addStretch()
        launch_row.addWidget(self.launch_btn)
        right_layout.addLayout(launch_row)
        
        self.splitter.addWidget(right_panel)
        self.splitter.setStretchFactor(1, 1) # Balanced ratio
        main_vbox.addWidget(self.splitter)

        # 4. Command Preview (Full Width Bottom - Mac Style)
        self.cmd_preview = QTextEdit()
        self.cmd_preview.setReadOnly(False)
        self.cmd_preview.setObjectName("CommandPreview")
        self.cmd_preview.setFixedHeight(65)  # Approx 4 lines
        self.cmd_preview.setAcceptRichText(False)
        self.cmd_preview.setVerticalScrollBarPolicy(Qt.ScrollBarAlwaysOff) # Keep it clean like Mac
        main_vbox.addWidget(self.cmd_preview)



    def populate_machine_tree(self, models, parent_item):
        if not models:
            print("DEBUG: No models found to populate machine tree.")
            return
        for model in models:
            item = QTreeWidgetItem(parent_item)
            item.setText(0, model.get('description', 'Unknown'))
            if 'value' in model:
                item.setData(0, Qt.UserRole, model['value'])
            if 'children' in model:
                self.populate_machine_tree(model['children'], item)

    def init_tabs(self):
        # --- Video Tab ---
        video_tab = QWidget()
        v_layout = QVBoxLayout(video_tab)
        v_layout.setContentsMargins(15, 10, 15, 10)
        v_layout.setSpacing(6)
        
        row1 = QHBoxLayout()
        row1.setSpacing(10)
        self.use_bgfx = QCheckBox("BGFX")
        self.use_bgfx.setChecked(True)
        self.bgfx_backend = QComboBox()
        self.bgfx_backend.addItems(["Default", "OpenGL", "Vulkan", "Direct3D 11", "Direct3D 12"])
        
        row1.addWidget(self.use_bgfx)
        row1.addWidget(QLabel("Backend:"))
        row1.addWidget(self.bgfx_backend)
        
        row1.addSpacing(15)
        row1.addWidget(QLabel("Effects:"))
        self.video_effect = QComboBox()
        self.video_effect.addItems(["Default", "Unfiltered", "HLSL", "CRT Geometry", "CRT Geometry Deluxe", "LCD Grid", "Fighters"])
        row1.addWidget(self.video_effect)
        row1.addStretch()
        v_layout.addLayout(row1)
        
        row2 = QHBoxLayout()
        row2.setSpacing(10)
        row2.addWidget(QLabel("Window Mode:"))
        self.win_mode = QComboBox()
        self.win_mode.addItems(["Window 1x", "Window 2x", "Window 3x", "Window 4x", "Full Screen"])
        self.win_mode.setCurrentIndex(1)
        row2.addWidget(self.win_mode)
        
        self.square_pixels = QCheckBox("Square Pixels")
        row2.addSpacing(15)
        row2.addWidget(self.square_pixels)
        row2.addStretch()
        v_layout.addLayout(row2)

        row3 = QHBoxLayout()
        row3.setSpacing(15)
        self.capture_mouse = QCheckBox("Capture Mouse")
        self.disk_sounds = QCheckBox("Disk Sound Effects")
        row3.addWidget(self.capture_mouse)
        row3.addWidget(self.disk_sounds)
        row3.addStretch()
        v_layout.addLayout(row3)

        # Connect all
        for w in [self.use_bgfx, self.bgfx_backend, self.video_effect, self.win_mode, 
                  self.square_pixels, self.capture_mouse, self.disk_sounds]:
            if isinstance(w, QCheckBox): w.stateChanged.connect(lambda: self.update_and_preview())
            else: w.currentIndexChanged.connect(lambda: self.update_and_preview())

        self.tabs.addTab(video_tab, "Video")

        # --- CPU Tab ---
        cpu_tab = QWidget()
        c_layout = QVBoxLayout(cpu_tab)
        row_c1 = QHBoxLayout()
        row_c1.addWidget(QLabel("Speed:"))
        self.cpu_speed = QComboBox()
        self.cpu_speed.addItems(["100%", "200%", "300%", "400%", "500%", "No Throttle"])
        self.cpu_speed.currentIndexChanged.connect(lambda: self.update_and_preview())
        row_c1.addWidget(self.cpu_speed)
        
        row_c1.addStretch()
        c_layout.addLayout(row_c1)

        row_c2 = QHBoxLayout()
        self.debugger = QCheckBox("Debug")
        self.debugger.stateChanged.connect(lambda: self.update_and_preview())
        self.rewind = QCheckBox("Rewind")
        self.rewind.stateChanged.connect(lambda: self.update_and_preview())
        row_c2.addWidget(self.debugger)
        row_c2.addWidget(self.rewind)
        row_c2.addStretch()
        c_layout.addLayout(row_c2)
        self.tabs.addTab(cpu_tab, "CPU")

        # --- A/V Tab ---
        av_tab = QWidget()
        av_layout = QVBoxLayout(av_tab)
        av_layout.setContentsMargins(15, 10, 15, 10)
        av_layout.setSpacing(6)

        def add_av_row(label, attr_prefix):
            row = QHBoxLayout()
            cb = QCheckBox(label)
            edit = QLineEdit()
            ext = label.split()[-1].lower()
            edit.setPlaceholderText(f"/path/to/file.{ext}")
            setattr(self, f"{attr_prefix}_check", cb)
            setattr(self, f"{attr_prefix}_path", edit)
            cb.stateChanged.connect(lambda: self.update_and_preview())
            edit.textChanged.connect(lambda: self.update_and_preview())

            # Make the line edit clickable to open save file dialog
            def on_click(event):
                # Use current text directory if valid, else CWD
                current_path = edit.text()
                start_dir = current_path if current_path and os.path.dirname(current_path) else os.getcwd()
                
                file_path, _ = QFileDialog.getSaveFileName(
                    self, 
                    f"Select Output File ({label})", 
                    start_dir, 
                    f"{ext.upper()} Files (*.{ext});;All Files (*.*)"
                )
                if file_path:
                    # Convert to native separators for Windows consistency
                    file_path = os.path.normpath(file_path)
                    edit.setText(file_path)
                QLineEdit.mousePressEvent(edit, event)

            edit.mousePressEvent = on_click

            row.addWidget(cb)
            row.addWidget(edit, 1) # Give path field more space
            av_layout.addLayout(row)

        add_av_row("Generate AVI", "avi")
        add_av_row("Generate WAV", "wav")
        add_av_row("Generate VGM", "vgm")
        # Override connection for VGM to handle Mod check
        self.vgm_check.stateChanged.disconnect()
        self.vgm_check.stateChanged.connect(self.on_vgm_check_changed)
        
        av_layout.addStretch()
        self.tabs.addTab(av_tab, "A/V")

        # --- Paths Tab ---
        paths_tab = QWidget()
        p_layout = QVBoxLayout(paths_tab)
        p_layout.setContentsMargins(15, 10, 15, 10)
        p_layout.setSpacing(6)
        
        row_p1 = QHBoxLayout()
        self.share_dir_check = QCheckBox("Share Directory")
        self.share_dir_path = QLineEdit()
        self.share_dir_path.setPlaceholderText("/path/to/directory/")
        # Make the line edit clickable to open directory selector
        def share_dir_mouse_press(event):
            dir_path = QFileDialog.getExistingDirectory(self, "Select Shared Directory", self.share_dir_path.text() or os.getcwd())
            if dir_path:
                self.share_dir_path.setText(os.path.normpath(dir_path))
            QLineEdit.mousePressEvent(self.share_dir_path, event)
            
        self.share_dir_path.mousePressEvent = share_dir_mouse_press
        
        self.share_dir_check.stateChanged.connect(lambda: self.update_and_preview())
        self.share_dir_path.textChanged.connect(lambda: self.update_and_preview())
        
        row_p1.addWidget(self.share_dir_check)
        row_p1.addWidget(self.share_dir_path, 1)
        p_layout.addLayout(row_p1)
        p_layout.addStretch()
        self.tabs.addTab(paths_tab, "Paths")

    def update_and_preview(self):
        self.update_command_line()

    def filter_machines(self, text):
        query = text.lower()
        self.filter_tree_item(self.machine_tree.invisibleRootItem(), query)

    def filter_tree_item(self, item, query):
        item_text = item.text(0).lower()
        is_match = query in item_text
        any_child_match = False
        for i in range(item.childCount()):
            if self.filter_tree_item(item.child(i), query):
                any_child_match = True
        visible = is_match or any_child_match
        item.setHidden(not visible)
        if visible and query: item.setExpanded(True)
        return visible

    def on_machine_selected(self, item):
        # 切換機器時立刻隱藏軟體下拉清單
        if hasattr(self, 'sw_popup') and self.sw_popup:
            self.sw_popup.hide()

        machine_name = item.data(0, Qt.UserRole)
        if not machine_name: return
        self.selected_machine = machine_name
        self.current_slots = {} # Reset slots for the new machine
        self.machine_title_bar = item.text(0)
        self.setWindowTitle(f"Ample - {self.machine_title_bar}")
        
        # Sticky Settings: Only keep software selection if the new machine supports the same list
        if self.selected_software:
            current_list = self.selected_software.split(':')[0]
            new_sw_lists = self.data_manager.get_software_lists(machine_name)
            supported_lists = [sl['name'] for sl in new_sw_lists]
            if current_list not in supported_lists:
                self.clear_software_selection()
        
        data = self.data_manager.get_machine_description(machine_name)
        if data:
            self.current_machine_data = data
            self.initialize_default_slots(data)
            self.refresh_ui()
            # 不再於切換時立即填充軟體清單 (延遲加載以優化效能)
            if hasattr(self, 'sw_list'): self.sw_list.clear()

    def initialize_default_slots(self, data, depth=0):
        if depth > 20: return
        
        # Helper to find a shared definition
        def find_global_def(name):
            if not self.current_machine_data: return None
            # 1. Search 'devices'
            for d in self.current_machine_data.get('devices', []):
                if d.get('name') == name: return d
            # 2. Search 'slots'
            for s in self.current_machine_data.get('slots', []):
                if s.get('name') == name: return s
            return None

        # 1. Process 'slots'
        if 'slots' in data:
            for slot in data['slots']:
                slot_name = slot.get('name')
                if not slot_name: continue
                
                # Default selection
                if not self.current_slots.get(slot_name):
                    best_val = None
                    for opt in slot.get('options', []):
                        if opt.get('default'):
                            best_val = opt.get('value')
                            break
                    if best_val is not None:
                        self.current_slots[slot_name] = best_val

                # Recursion into selected option
                cur_val = self.current_slots.get(slot_name)
                for opt in slot.get('options', []):
                    if str(opt.get('value')) == str(cur_val):
                        # A. Recurse into inline slots
                        self.initialize_default_slots(opt, depth + 1)
                        # B. Recurse into devname definition
                        if 'devname' in opt:
                            m_dev = find_global_def(opt['devname'])
                            if m_dev: self.initialize_default_slots(m_dev, depth + 1)
                        break

        # 2. Process 'devices' - ONLY if not the root machine level
        # At the root, 'devices' is a catalog of all possible device types.
        if depth > 0 and 'devices' in data:
            for dev in data['devices']:
                self.initialize_default_slots(dev, depth + 1)

    def on_tree_double_clicked(self, item, column):
        if item.childCount() == 0:
            machine_name = item.data(0, Qt.UserRole)
            if machine_name:
                self.launch_mame()

    def update_options_ui(self, data):
        self.current_machine_data = data
        self.refresh_ui()

    def refresh_ui(self):
        # 0. Re-initialize defaults for any newly appeared slots/devices
        if self.current_machine_data:
            self.initialize_default_slots(self.current_machine_data)

        # 1. Clean the fixed layouts without destroying the frames themselves
        self.clear_grid(self.slots_layout)
        self.clear_grid(self.media_layout)
        
        # 2. Re-render
        self.render_slots_ui()
        self.render_media_ui()
        self.update_command_line()

    def render_slots_ui(self):
        # We now add directly to self.slots_layout
        self.slots_layout.setContentsMargins(10, 10, 10, 10)
        self.slots_layout.setSpacing(6)
        
        if 'slots' in self.current_machine_data:
            # 1. RAM Group
            ram_slot = next((s for s in self.current_machine_data['slots'] if s['name'] == 'ramsize'), None)
            if ram_slot:
                self.add_slot_row(self.slots_layout, ram_slot)
                self.slots_layout.addSpacing(5)

            # 2. Disk Drives - EXACTLY same structure as add_slot_row
            # Mac hides popup button but it still takes up space. Hamburger at far right.
            dd_slot = next((s for s in self.current_machine_data['slots'] if s.get('description') == 'Disk Drives'), None)
            if dd_slot:
                row = QHBoxLayout()
                row.setContentsMargins(0, 0, 0, 0)
                row.setSpacing(5)
                
                # Label - IDENTICAL to add_slot_row
                lbl = QLabel("Disk Drives:")
                lbl.setFixedWidth(100)
                lbl.setAlignment(Qt.AlignRight | Qt.AlignVCenter)
                lbl.setObjectName("SlotLabel")
                row.addWidget(lbl)
                
                # Invisible container - same size as add_slot_row combo (160px)
                invisible_container = QLabel("")
                invisible_container.setFixedWidth(160)
                invisible_container.setFixedHeight(22)
                row.addWidget(invisible_container)
                
                # Hamburger at FAR RIGHT - SAME position as other rows
                cur_val = self.current_slots.get(dd_slot['name'])
                selected_opt = next((o for o in dd_slot['options'] if str(o.get('value')) == str(cur_val)), dd_slot['options'][0])
                target_data = selected_opt
                if 'devname' in selected_opt:
                    devname = selected_opt['devname']
                    m_dev = next((d for d in self.current_machine_data.get('devices', []) if d.get('name') == devname), None)
                    if m_dev: target_data = m_dev
                
                h_btn = self.create_hamburger(target_data)
                row.addWidget(h_btn)
                
                # Insert stretch at index 0 - IDENTICAL to add_slot_row
                row.insertStretch(0)
                
                self.slots_layout.addLayout(row)











            # 3. All other slots
            for slot in self.current_machine_data['slots']:
                if slot['name'] != 'ramsize' and slot.get('description') != 'Disk Drives':
                    self.add_slot_row(self.slots_layout, slot)
            
        self.slots_layout.addStretch()

    def add_slot_row(self, parent_layout, slot):
        slot_name = slot['name']
        desc = slot.get('description')
        if not desc: return

        row = QHBoxLayout()
        row.setContentsMargins(0, 0, 0, 0) # Explicitly zero margins to match Disk Drives
        row.setSpacing(5)
        lbl = QLabel(f"{desc}:")
        lbl.setFixedWidth(100)
        lbl.setAlignment(Qt.AlignRight | Qt.AlignVCenter)
        lbl.setObjectName("SlotLabel")
        
        combo = QComboBox()
        from PySide6.QtWidgets import QListView
        lv = QListView()
        combo.setView(lv)
        # MacOS list is wide, field is narrow
        lv.setMinimumWidth(350) 
        
        is_dark = self.is_dark_mode()
        lv_bg = "#1a1a1a" if is_dark else "#ffffff"
        lv_text = "#dddddd" if is_dark else "#1a1a1a"
        lv_border = "#444444" if is_dark else "#d1d1d1"
        lv.setStyleSheet(f"background-color: {lv_bg}; color: {lv_text}; border: 1px solid {lv_border}; outline: none;")
        
        combo.setObjectName(slot_name)
        combo.setProperty("appleStyle", "slot")
        combo.setFixedWidth(160)  # Match Mac popup width
        combo.setFixedHeight(22)

        
        if slot.get('default') == "true" or slot.get('default') is True:
            # Default logic handled via current_slots, but could be reinforced here
            pass
        
        # Use QStandardItemModel for advanced item control (disabling items)
        from PySide6.QtGui import QStandardItemModel, QStandardItem
        model = QStandardItemModel()
        combo.setModel(model)

        for opt in slot['options']:
            opt_desc = opt.get('description') or opt['value'] or "—None—"
            item = QStandardItem(opt_desc)
            item.setData(opt['value'], Qt.UserRole)
            
            # Check for disabled status in plist
            # XML plist boolean is usually True/False in Python after loading
            is_disabled = opt.get('disabled', False)
            if is_disabled:
                item.setEnabled(False)
                # Optional: Add visual cue like "(Unsupported)" or color change if style sheet overrides gray
                item.setForeground(QColor("#888888")) 
            
            model.appendRow(item)
        
        combo.blockSignals(True)
        val = self.current_slots.get(slot_name)
        idx = combo.findData(str(val))
        if idx < 0: idx = combo.findData(val)
        if idx >= 0: combo.setCurrentIndex(idx)
        combo.blockSignals(False)
        
        combo.currentIndexChanged.connect(self.on_slot_changed)
        
        # Create container with combo and arrow overlay
        combo_widget = QWidget()
        combo_widget.setFixedSize(160, 22)
        combo.setParent(combo_widget)
        combo.move(0, 0)
        
        # Arrow label overlay - narrow blue like Mac
        arrow_label = QLabel("↕", combo_widget)
        arrow_label.setFixedSize(20, 20)
        arrow_label.move(140, 1)  # 140 + 20 = 160, narrow and covers right edge
        arrow_label.setAlignment(Qt.AlignCenter)
        arrow_label.setStyleSheet("""
            background-color: #3b7ee1;
            color: white;
            font-size: 12px;
            font-weight: bold;
            padding-bottom: 3px;
            border: none;
            border-top-right-radius: 3px;
            border-bottom-right-radius: 3px;
        """)
        arrow_label.setAttribute(Qt.WA_TransparentForMouseEvents)  # Click through to combo
        
        # Order: Label -> ComboWidget -> Hamburger (then addStretch at 0)
        row.addWidget(lbl)
        row.addWidget(combo_widget)

        # Subtle Hamburger - Unified with create_hamburger size
        selected_opt = next((o for o in slot['options'] if str(o.get('value')) == str(val)), None)
        
        has_sub = False
        target_data = selected_opt
        if selected_opt:
            if 'slots' in selected_opt or 'devices' in selected_opt:
                has_sub = True
            elif 'devname' in selected_opt:
                devname = selected_opt['devname']
                m_dev = next((d for d in self.current_machine_data.get('devices', []) if d.get('name') == devname), None)
                if m_dev and ('slots' in m_dev or 'devices' in m_dev):
                    has_sub = True
                    target_data = m_dev

        if has_sub:
            sub_btn = self.create_hamburger(target_data)
            row.addWidget(sub_btn)
        else:
            # Invisible placeholder - same size as hamburger for alignment
            invisible_hamburger = QLabel("")
            invisible_hamburger.setFixedSize(22, 22)
            row.addWidget(invisible_hamburger)

        # KEY FIX: Insert stretch at index 0 to force right-alignment
        row.insertStretch(0)

        parent_layout.addLayout(row)

    def create_hamburger(self, data):
        btn = QPushButton("≡")
        btn.setFixedSize(22, 22)
        btn.setFlat(True)
        btn.setStyleSheet("color: #999; font-size: 18px; border: none; background: transparent;")
        btn.clicked.connect(lambda _, d=data: self.show_sub_slots(d, btn))
        return btn

    def gather_active_slots(self, data, depth=0):
        if depth > 10: return []
        slots = []
        
        # Check standard slots
        if 'slots' in data:
            for slot in data['slots']:
                slots.append(slot)
                selected_val = self.current_slots.get(slot['name'])
                for opt in slot['options']:
                    if opt['value'] == selected_val:
                        slots.extend(self.gather_active_slots(opt, depth + 1))
                        break

        # Check devices
        if 'devices' in data:
            for dev in data['devices']:
                slots.extend(self.gather_active_slots(dev, depth + 1))
                
        return slots

    def show_sub_slots(self, data, button):
        # Prevent immediate reopening when clicking the same button to close (race condition)
        # Windows Qt: Popup auto-hides on mouse press OUTSIDE, then button-click fires.
        now = time.time()
        if (now - self.last_popup_close_time < 0.3) and (self.last_popup_id == id(data)):
            return

        # If there's an active popup, close it first
        if self.active_popup is not None:
            self.active_popup.close()
            # Note: closeEvent will set self.active_popup = None
            
        # Create and show the popup relative to the button
        popup = SubSlotPopup(self, data, self.current_slots, self.refresh_ui)
        self.active_popup = popup
        
        pos = button.mapToGlobal(QPoint(button.width(), 0))
        # Shift a bit to the left to align with Mac bubble
        popup.move(pos.x() - 100, pos.y() + button.height() + 5)
        popup.show()

    def get_total_media(self):
        total_media = {}
        
        def find_global_def(name):
            if not self.current_machine_data: return None
            for d in self.current_machine_data.get('devices', []):
                if d.get('name') == name: return d
            for s in self.current_machine_data.get('slots', []):
                if s.get('name') == name: return s
            return None

        def aggregate_media(data, depth=0):
            if depth > 15: return
            
            # 1. Media defined here
            if 'media' in data:
                for k, v in data['media'].items():
                    key = k
                    if k == 'cass': key = 'cassette'
                    total_media[key] = total_media.get(key, 0) + v
            
            # 2. Recurse into slots
            if 'slots' in data:
                for slot in data['slots']:
                    cur_val = self.current_slots.get(slot['name'])
                    for opt in slot.get('options', []):
                        if str(opt.get('value')) == str(cur_val):
                            # A. Inline
                            aggregate_media(opt, depth + 1)
                            # B. Via devname
                            if 'devname' in opt:
                                m_dev = find_global_def(opt['devname'])
                                if m_dev: aggregate_media(m_dev, depth + 1)
                            break
            
            # 3. Recurse into devices - ONLY if not the root machine level
            if depth > 0 and 'devices' in data:
                for dev in data['devices']:
                    aggregate_media(dev, depth + 1)
                            
        if self.current_machine_data:
            aggregate_media(self.current_machine_data, depth=0)

        # UI FIX: Cleanup empty entries
        for k in ['hard', 'cdrom', 'cassette']:
            if k in total_media and total_media[k] <= 0:
                total_media.pop(k, None)
        return total_media

    def get_filtered_media(self):
        total_media = self.get_total_media()
        PREFIX_MAP = {
            'floppy_5_25': 'flop',
            'floppy_3_5': 'flop',
            'hard': 'hard',
            'cdrom': 'cdrom',
            'cassette': 'cass',
            'cass': 'cass'
        }
        counters = {"flop": 0, "hard": 0, "cdrom": 0, "cass": 0}
        active_keys = set()
        
        # We must iterate in a consistent order if we want flop1, flop2 etc to be stable
        # Using the same order as in add_media_group calls
        media_order = ["floppy_5_25", "floppy_3_5", "hard", "cdrom", "cassette"]
        for m_type_key in media_order:
            if m_type_key in total_media:
                m_prefix = PREFIX_MAP.get(m_type_key, m_type_key)
                count = total_media[m_type_key]
                for i in range(count):
                    counters[m_prefix] += 1
                    idx = counters[m_prefix]
                    key = f"{m_prefix}{idx}"
                    if m_prefix == "cass" and idx == 1 and count == 1:
                        key = "cass"
                    active_keys.add(key)
        
        return {k: v for k, v in self.current_media.items() if k in active_keys}

    def render_media_ui(self):
        # 1. Clear media layout EXCEPT for Software List at the top (if we want to keep it)
        # Actually, let's keep it simple: rebuild everything.
        while self.media_layout.count():
            item = self.media_layout.takeAt(0)
            if item.widget():
                item.widget().setParent(None)
                item.widget().deleteLater()
            elif item.layout():
                self.clear_grid(item.layout())

        # 2. Add Software List Search Box (Mac Style)
        # Software list is now an overlay popup, it won't push down other media.
        if not hasattr(self, 'sw_popup') or self.sw_popup is None:
            self.sw_popup = SoftwarePopup(self)
            self.sw_list = self.sw_popup.list_widget
            self.sw_list.itemClicked.connect(self.on_software_selected)

        sw_row = QHBoxLayout()
        self.sw_search = QLineEdit()
        self.sw_search.setPlaceholderText("Search Software List...")
        self.sw_search.setObjectName("SoftwareSearch")
        self.sw_search.setFixedHeight(24)
        if self.selected_software:
            self.sw_search.setText(self.selected_software_desc)
            self.sw_search.setProperty("hasValue", True)
        else:
            self.sw_search.setProperty("hasValue", False)
        
        # Clear button within the search box
        btn_clear = QPushButton("✕")
        btn_clear.setFixedSize(20, 20)
        btn_clear.setStyleSheet("background: transparent; border: none; color: #666; font-size: 10px;")
        btn_clear.clicked.connect(self.clear_software_selection)
        
        sw_row.addWidget(self.sw_search)
        sw_row.addWidget(btn_clear)
        self.media_layout.addLayout(sw_row)

        # Behavior: 延遲加載 - 只有在使用者點擊搜尋框時，才真正去抓軟體清單
        def on_search_focused(event, original_fn=self.sw_search.focusInEvent):
            # 如果清單是空的，才需要抓取 (或根據需要重新抓取)
            if self.sw_list.count() == 0:
                self.render_software_ui()
            
            if self.sw_list.count() > 0:
                self.sw_popup.show_at(self.sw_search)
            original_fn(event)
        
        self.sw_search.focusInEvent = on_search_focused
        self.sw_search.textChanged.connect(self.filter_software)
        
        # Add small vertical space before drive list
        self.media_layout.addSpacing(10)

        total_media = self.get_total_media()
        # ... (rest of the media rendering)
        
        # MAME Prefix Mapping and Index Counters
        PREFIX_MAP = {
            'floppy_5_25': 'flop',
            'floppy_3_5': 'flop',
            'hard': 'hard',
            'cdrom': 'cdrom',
            'cassette': 'cass',
            'cass': 'cass'
        }
        counters = {"flop": 0, "hard": 0, "cdrom": 0, "cass": 0}

        def add_media_group(target_layout, title, m_type_key):
            if m_type_key in total_media:
                m_prefix = PREFIX_MAP.get(m_type_key, m_type_key)
                is_dark = self.is_dark_mode()
                row_h = QHBoxLayout()
                handle = QLabel("⠇")
                handle.setObjectName("MediaHandle")
                handle.setFixedWidth(10)
                row_h.addWidget(handle)
                lbl = QLabel(f"<b>{title}</b>")
                lbl.setObjectName("MediaHeader")
                row_h.addWidget(lbl)
                row_h.addStretch()
                target_layout.addLayout(row_h)
                count = total_media[m_type_key]
                for i in range(count):
                    counters[m_prefix] += 1
                    idx = counters[m_prefix]
                    # MAME: cass is just -cass if single, or -cass1. Floppies are -flop1, -flop2...
                    key = f"{m_prefix}{idx}"
                    if m_prefix == "cass" and idx == 1 and count == 1:
                        key = "cass"

                    row = QHBoxLayout()
                    row.setContentsMargins(15, 0, 0, 0) # Indent rows like Mac
                    row.setSpacing(5)
                    
                    lbl_choose = QLabel("Choose...")
                    lbl_choose.setObjectName("SmallDimLabel")
                    lbl_choose.setFixedWidth(65)
                    lbl_choose.setAlignment(Qt.AlignRight | Qt.AlignVCenter)
                    edit = QLineEdit()
                    edit.setPlaceholderText("None")
                    edit.setText(self.current_media.get(key, ""))
                    edit.setFixedHeight(18)
                    edit.setObjectName("MediaEdit")
                    
                    # Blue Double Arrow Button (Select)
                    btn_sel = QPushButton("↕")
                    btn_sel.setFixedSize(20, 18)
                    btn_sel.setStyleSheet("""
                        QPushButton { 
                            background-color: #3b7ee1; 
                            color: white; 
                            border: none; 
                            border-radius: 2px; 
                            font-weight: bold; 
                            font-size: 12px;
                            padding-bottom: 3px;
                        }
                        QPushButton:hover { background-color: #4a8df0; }
                    """)
                    btn_sel.clicked.connect(lambda _, k=key, e=edit: self.browse_media(k, e))
                    
                    # Eject Button
                    btn_eject = QPushButton("⏏")
                    btn_eject.setFixedSize(20, 18)
                    btn_eject.setObjectName("EjectButton")
                    btn_eject.clicked.connect(lambda _, k=key, e=edit: self.eject_media(k, e))
                    
                    row.addWidget(lbl_choose)
                    row.addWidget(edit)
                    row.addWidget(btn_sel)
                    row.addWidget(btn_eject)
                    target_layout.addLayout(row)

        add_media_group(self.media_layout, "5.25\" Floppies", "floppy_5_25")
        add_media_group(self.media_layout, "3.5\" Floppies", "floppy_3_5")
        add_media_group(self.media_layout, "Hard Drives", "hard")
        add_media_group(self.media_layout, "CD-ROMs", "cdrom")
        add_media_group(self.media_layout, "Cassettes", "cassette")

        self.media_layout.addStretch()

    def clear_software_selection(self):
        self.selected_software = None
        self.selected_software_desc = ""
        if self.sw_search:
            self.sw_search.clear()
            self.sw_search.setProperty("hasValue", False)
            self.sw_search.style().unpolish(self.sw_search)
            self.sw_search.style().polish(self.sw_search)
        if hasattr(self, 'sw_popup') and self.sw_popup:
            self.sw_popup.hide()
        self.update_command_line()

    def render_software_ui(self):
        # Re-populate list and check if we should show it
        if not hasattr(self, 'sw_list'): return
        self.sw_list.clear()
        
        # 如果沒有選定機器，確保隱藏彈出視窗
        if not self.selected_machine:
            if hasattr(self, 'sw_popup'): self.sw_popup.hide()
            return
        
        # Ensure hash path is set
        mame_bin_dir = os.path.dirname(self.launcher.mame_path)
        if mame_bin_dir and mame_bin_dir != ".":
             self.data_manager.hash_path = os.path.join(mame_bin_dir, "hash")
             
        sw_lists = self.data_manager.get_software_lists(self.selected_machine)
        for sl in sw_lists:
            header = QListWidgetItem(f"--- {sl['description']} ---")
            header.setFlags(Qt.NoItemFlags)
            header.setBackground(QColor("#222"))
            header.setForeground(QColor("#777"))
            self.sw_list.addItem(header)
            
            for item in sl['items']:
                li = QListWidgetItem(item['description'])
                li.setData(Qt.UserRole, f"{sl['name']}:{item['name']}")
                self.sw_list.addItem(li)

        # Re-apply filter if text exists (sticky search)
        if hasattr(self, 'sw_search') and self.sw_search and self.sw_search.text():
            self.filter_software(self.sw_search.text())

    def filter_software(self, text):
        query = text.lower()
        
        # 先進行過濾計算
        visible_count = 0
        for i in range(self.sw_list.count()):
            item = self.sw_list.item(i)
            data = item.data(Qt.UserRole)
            if not data: # Header items
                item.setHidden(True) # 搜尋時隱藏分類標題以簡化
                continue
            visible = query in item.text().lower() or query in data.lower()
            item.setHidden(not visible)
            if visible: visible_count += 1
            
        # 根據結果決定是否顯示視窗
        if visible_count > 0 and self.sw_search.hasFocus():
            if hasattr(self, 'sw_popup'): self.sw_popup.show_at(self.sw_search)
        else:
            if hasattr(self, 'sw_popup'): self.sw_popup.hide()

    def on_software_selected(self, item):
        data = item.data(Qt.UserRole)
        if data:
            self.selected_software = data
            self.selected_software_desc = item.text()
            self.sw_search.setText(self.selected_software_desc)
            # 設置高亮度屬性
            self.sw_search.setProperty("hasValue", True)
            self.sw_search.style().unpolish(self.sw_search)
            self.sw_search.style().polish(self.sw_search)
            
            # 確保選中後隱藏清單
            if hasattr(self, 'sw_popup'):
                self.sw_popup.hide()
            self.update_command_line()
        # 清除焦點以確保下次點擊搜尋框能正確觸發 focusInEvent
        self.sw_search.clearFocus()
        if hasattr(self, 'sw_popup'): self.sw_popup.hide()

    def on_slot_changed(self):
        combo = self.sender()
        self.current_slots[combo.objectName()] = combo.currentData()
        # Full refresh because changing a slot might add more slots OR change media
        self.refresh_ui()

    def eject_media(self, key, edit):
        if key in self.current_media:
            del self.current_media[key]
            edit.clear()
            self.update_command_line()

    def browse_media(self, key, edit):
        path, _ = QFileDialog.getOpenFileName(self, f"Select file for {key}")
        if path:
            edit.setText(path)
            self.current_media[key] = path
            self.update_command_line()

    def update_command_line(self):
        if not self.selected_machine: return
        
        # Filter sticky media to only what's supported by current machine/slots
        filtered_media = {k: os.path.normpath(v) for k, v in self.get_filtered_media().items()}
        
        # Softlist selection
        soft_list_args = []
        if self.selected_software:
            # IMPORTANT: Do NOT use -flop1 for software list items on Windows.
            # Positional arguments allow MAME's Software List manager to resolve them.
            soft_list_args.append(self.selected_software)
            
        # Build base args
        args = self.launcher.build_args(self.selected_machine, self.current_slots, filtered_media, soft_list_args)
        
        # Add UI Video options for preview
        win_mode = self.win_mode.currentText()
        if "Window" in win_mode:
            args.append("-window")
            # Handle scaling (2x, 3x, 4x)
            try:
                # Extract multiplier from "Window 2x" -> 2
                multiplier_str = win_mode.split("x")[0].split()[-1]
                multiplier = int(multiplier_str)
            except (IndexError, ValueError):
                multiplier = 1

            if multiplier > 1:
                res = self.current_machine_data.get('resolution')
                if res and len(res) >= 2:
                    base_w = res[0]
                    base_h = res[1]
                    
                    if self.square_pixels.isChecked():
                        if base_w / base_h > 2.0:
                            # Apple II heuristic for Square Pixels (integer scale)
                            # Base Square (1x) is 560x384 (1x width, 2x height)
                            # User wants Window 2x -> 1120x768
                            target_w = base_w * multiplier
                            target_h = base_h * 2 * multiplier
                        else:
                            # Standard square pixel machine
                            target_w = base_w * multiplier
                            target_h = base_h * multiplier
                    else:
                        # 4:3 Heuristic for non-square pixel machines like Apple II
                        if base_w / base_h > 2.0:
                            eff_h = base_w * 3 // 4
                        else:
                            eff_h = base_h
                        target_w = base_w * multiplier
                        target_h = eff_h * multiplier
                    
                    args.extend(["-resolution", f"{target_w}x{target_h}"])
            else:
                args.append("-nomax")
        else:
            args.extend(["-nowindow", "-maximize"])

        if self.square_pixels.isChecked():
            args.extend(["-nounevenstretch"])

        if self.use_bgfx.isChecked():
            args.extend(["-video", "bgfx"])
            backend = self.bgfx_backend.currentText().lower().replace(" ", "")
            if backend != "default":
                args.extend(["-bgfx_backend", backend])
            
            effect = self.video_effect.currentText()
            effect_map = {
                "Unfiltered": "unfiltered",
                "HLSL": "hlsl",
                "CRT Geometry": "crt-geom",
                "CRT Geometry Deluxe": "crt-geom-deluxe",
                "LCD Grid": "lcd-grid",
                "Fighters": "fighters"
            }
            if effect in effect_map:
                args.extend(["-bgfx_screen_chains", effect_map[effect]])
        
        # CPU settings
        speed_text = self.cpu_speed.currentText()
        if speed_text == "No Throttle":
            args.append("-nothrottle")
        elif speed_text != "100%":
            try:
                speed_val = float(speed_text.replace("%", "")) / 100.0
                args.extend(["-speed", str(speed_val)])
            except ValueError:
                pass
            
        if self.rewind.isChecked():
            args.append("-rewind")
        if self.debugger.isChecked():
            args.append("-debug")
            
        # Default MAME behaviors to match Mac Ample: use samples only if disk sounds enabled
        if not self.disk_sounds.isChecked():
            args.append("-nosamples")
            
        # A/V settings
        if self.avi_check.isChecked() and self.avi_path.text():
            args.extend(["-aviwrite", self.avi_path.text()])
        if hasattr(self, 'wav_check') and self.wav_check.isChecked() and self.wav_path.text():
            args.extend(["-wavwrite", self.wav_path.text()])
        if hasattr(self, 'vgm_check') and self.vgm_check.isChecked() and self.vgm_path.text():
            # VGM Mod version only supports -vgmwrite 1
            args.extend(["-vgmwrite", "1"])
        
        if self.capture_mouse.isChecked():
            args.append("-mouse")
        
        if hasattr(self, 'share_dir_check') and self.share_dir_check.isChecked() and self.share_dir_path.text():
            args.extend(["-share_directory", os.path.normpath(self.share_dir_path.text())])

        # Path Setup (Minimalist: redundant paths are now in mame.ini)
        # Determine display executable
        exe_display = "mame"
        if hasattr(self, 'vgm_check') and self.vgm_check.isChecked():
            mame_bin_dir = os.path.dirname(self.launcher.mame_path)
            if os.path.exists(os.path.join(mame_bin_dir, "mame-vgm.exe")):
                exe_display = "mame-vgm"
        
        import subprocess # Safety import for robust runtime
        self.cmd_preview.setText(subprocess.list2cmdline([exe_display] + args))

    def clear_grid_column(self, col):
        # Extremely aggressive clearing to prevent widget ghosting
        item = self.options_grid.itemAtPosition(0, col)
        if item:
            w = item.widget()
            if w:
                w.setParent(None)
                w.deleteLater()
            self.options_grid.removeItem(item)

    def clear_grid(self, layout):
        if not layout: return
        while layout.count():
            item = layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()
            elif item.layout():
                self.clear_grid(item.layout())
            # Layout items that are not widgets or layouts are rare but handled by takeAt

    @Slot()
    def show_rom_manager(self):
        self.rom_manager_dialog = RomManagerDialog(self.rom_manager, self)
        # apply_dialog_theme is already called in RomManagerDialog.__init__
        self.rom_manager_dialog.exec()

    @Slot()
    def show_settings(self):
        dialog = QDialog(self)
        dialog.setWindowTitle("Settings")
        layout = QVBoxLayout(dialog)

        path_label = QLabel(f"MAME: {self.launcher.mame_path}")
        layout.addWidget(path_label)
        
        # Bottom status and progress
        self.settings_status = QLabel("")
        layout.addWidget(self.settings_status)

        self.settings_progress = QProgressBar()
        self.settings_progress.setVisible(False)
        layout.addWidget(self.settings_progress)

        # Buttons
        btn1 = QPushButton("Select MAME...")
        btn1.clicked.connect(lambda: self.select_mame(dialog, path_label))
        layout.addWidget(btn1)
        
        btn2 = QPushButton("Download MAME")
        btn2.clicked.connect(lambda: self.download_mame(dialog, path_label))
        layout.addWidget(btn2)
        
        # Auto-run check immediately
        self.check_for_mame(path_label)
        
        dialog.exec()
        
        # After closing settings, if MAME is now valid, check for ROMs
        if self.check_for_mame():
            self.check_and_auto_roms()

    def select_mame(self, dialog, label):
        path, _ = QFileDialog.getOpenFileName(dialog, "Select MAME", "", "*.exe")
        if path:
            self.launcher.mame_path = path
            self.check_for_mame(label)

    def download_mame(self, dialog, label):
        target_dir = os.path.join(self.app_dir, "mame")
        self.settings_progress.setVisible(True)
        worker = MameDownloadWorker(target_dir)
        self.active_workers.append(worker)
        worker.progress.connect(self.settings_progress.setValue)
        worker.progress.connect(lambda v, t: self.settings_progress.setMaximum(t))
        worker.status.connect(self.settings_status.setText)
        worker.finished.connect(lambda s, p: self.on_mame_dl_finished(worker, s, p, label))
        worker.start()

    def on_mame_dl_finished(self, worker, success, path, label):
        if worker in self.active_workers: self.active_workers.remove(worker)
        self.settings_progress.setVisible(False)
        self.settings_status.setText("Installer opened. Please complete extraction.")
        
        if success:
            QMessageBox.information(self, "Download Complete", 
                f"MAME installer has been opened.\n\n"
                f"1. In the installer, extract to: {self.app_dir}\\mame\n"
                f"2. Once extraction is done, click 'Select MAME' to confirm.")
            
            # Immediate check in case it's already there
            self.check_for_mame(label)
        else:
            QMessageBox.critical(self, "Error", path)
            self.settings_status.setText("Download failed.")

    def check_for_mame(self, label=None):
        """Helper to check standard paths and update UI."""
        potential_paths = [
            os.path.join(self.app_dir, "mame", "mame.exe"),
            os.path.join(self.app_dir, "mame.exe"),
        ]
        
        # Also check current path if it's already set and valid
        if hasattr(self, 'launcher') and self.launcher.mame_path and os.path.exists(self.launcher.mame_path) and self.launcher.mame_path != "mame":
            if self.launcher.mame_path not in potential_paths:
                potential_paths.insert(0, self.launcher.mame_path)

        for p in potential_paths:
            if os.path.exists(p) and os.path.isfile(p):
                self.launcher.mame_path = p
                self.ensure_mame_ini(p)
                if label:
                    label.setText(f"MAME: {p} <span style='color: #2ecc71;'>✅</span>")
                    label.setTextFormat(Qt.RichText)
                if hasattr(self, 'settings_status'):
                    self.settings_status.setText("MAME detected and configured!")
                return True
        
        if label:
            label.setText(f"MAME: Not found <span style='color: #e74c3c;'>❌</span>")
            label.setTextFormat(Qt.RichText)
        return False

    def ensure_mame_ini(self, mame_path):
        """Generate mame.ini in the background if it doesn't exist."""
        mame_dir = os.path.dirname(mame_path)
        ini_path = os.path.join(mame_dir, "mame.ini")
        if not os.path.exists(ini_path):
            print(f"Generating mame.ini in {mame_dir}...")
            try:
                # Run mame -cc in the mame directory
                subprocess.run([mame_path, "-cc"], cwd=mame_dir, check=True, capture_output=True)
            except Exception as e:
                print(f"Failed to generate mame.ini: {e}")

    def launch_mame(self):
        if hasattr(self, 'sw_popup') and self.sw_popup:
            self.sw_popup.hide()
        
        # Get command from preview console (User Input is Source of Truth)
        cmd_str = self.cmd_preview.toPlainText().strip()
        if not cmd_str: return
        
        print(f"Launching custom command: {cmd_str}")
        
        # Determine the MAME binary directory
        mame_bin_dir = os.path.dirname(self.launcher.mame_path)

        # Parse command string into arguments list safely
        import shlex
        try:
            # posix=False is important for Windows paths (keeps backslashes)
            # However, it preserves quotes in tokens, so we safely strip matching outer quotes.
            raw_args = shlex.split(cmd_str, posix=False)
            args = []
            for arg in raw_args:
                # Strip outer quotes if they match and are length >= 2
                if len(arg) >= 2 and ((arg.startswith('"') and arg.endswith('"')) or (arg.startswith("'") and arg.endswith("'"))):
                    args.append(arg[1:-1])
                else:
                    args.append(arg)
        except ValueError:
            # Fallback for unbalanced quotes
            args = cmd_str.split()
            
        if not args: return

        try:
            # Resolve executable path from bare filename to absolute path
            # This fixes [WinError 2] where Popen(cwd=...) fails to find bare 'mame'
            exe_cmd = args[0].lower()
            vgm_exe = None
            
            # Start with whatever the user provided
            target_exe_path = args[0]
            
            if exe_cmd in ["mame", "mame.exe"]:
                target_exe_path = self.launcher.mame_path
            elif exe_cmd in ["mame-vgm", "mame-vgm.exe"]:
                 path_vgm = os.path.join(mame_bin_dir, "mame-vgm.exe")
                 if os.path.exists(path_vgm):
                     target_exe_path = path_vgm
                     vgm_exe = path_vgm
            
            # Update the binary path in the args list
            args[0] = target_exe_path

            # Pass the LIST of args to Popen. 
            # subprocess will handle quoting for Windows automatically.
            proc = subprocess.Popen(args, cwd=mame_bin_dir)
            
            if proc and vgm_exe:
                # If using VGM Mod, we need to move the file after exit
                worker = VgmPostProcessWorker(proc, mame_bin_dir, self.selected_machine, self.vgm_path.text())
                worker.finished.connect(lambda: self.active_workers.remove(worker) if worker in self.active_workers else None)
                self.active_workers.append(worker)
                worker.start()

        except Exception as e:
            print(f"Error launching MAME: {e}")
            QMessageBox.critical(self, "Launch Error", f"Failed to launch command:\n{e}")

    def on_vgm_check_changed(self, state):
        if state == Qt.Checked.value:
            mame_bin_dir = os.path.dirname(self.launcher.mame_path)
            vgm_exe = os.path.join(mame_bin_dir, "mame-vgm.exe")
            
            if not os.path.exists(vgm_exe):
                # Request download
                res = QMessageBox.question(self, "VGM Support Required",
                    "VGM (Video Game Music) support was removed from MAME after v0.163.\n\n"
                    "The community-supported VGM Mod is available up to v0.280.\n"
                    "Would you like to download and use this version for VGM recording?",
                    QMessageBox.Yes | QMessageBox.No)
                
                if res == QMessageBox.Yes:
                    self.download_vgm_mod(mame_bin_dir)
                else:
                    # Uncheck if user said no
                    self.vgm_check.setChecked(False)
        
        self.update_and_preview()

    def download_vgm_mod(self, dest_dir):
        # reuse existing progress dialog or create new
        dialog = QDialog(self)
        dialog.setWindowTitle("Downloading VGM Mod")
        dialog.setFixedSize(400, 150)
        self.apply_premium_theme() # refresh styles
        
        layout = QVBoxLayout(dialog)
        label = QLabel("Initializing download...")
        layout.addWidget(label)
        
        pbar = QProgressBar()
        layout.addWidget(pbar)
        
        status = QLabel("")
        layout.addWidget(status)

        worker = VgmModDownloadWorker(dest_dir)
        worker.progress.connect(lambda d, t: pbar.setValue(int(d*100/t)) if t>0 else None)
        worker.status.connect(label.setText)
        worker.finished.connect(lambda s, p: self.on_vgm_dl_finished(worker, s, p, label, dialog))
        
        self.active_workers.append(worker)
        worker.start()
        dialog.exec()

    def on_vgm_dl_finished(self, worker, success, path, label, dialog):
        if worker in self.active_workers:
            self.active_workers.remove(worker)
        
        if success:
            QMessageBox.information(self, "Success", "MAME VGM Mod has been installed as mame-vgm.exe")
            dialog.accept()
        else:
            QMessageBox.critical(self, "Error", f"Failed to download VGM Mod: {path}")
            self.vgm_check.setChecked(False)
            dialog.reject()

    def load_persistent_settings(self):
        """Restore window geometry and splitter state."""
        geom = self.settings.value("geometry")
        if geom:
            self.restoreGeometry(geom)
        else:
            self.resize(1100, 800)
            
        splitter_state = self.settings.value("splitterState")
        if splitter_state:
            self.splitter.restoreState(splitter_state)

        # Restore last selected machine
        last_machine = self.settings.value("lastMachine")
        if last_machine:
            item = self.find_item_by_value(self.machine_tree.invisibleRootItem(), last_machine)
            if item:
                self.machine_tree.setCurrentItem(item)
                self.on_machine_selected(item)
                # Expand to show the selection
                parent = item.parent()
                while parent:
                    parent.setExpanded(True)
                    parent = parent.parent()

    def find_item_by_value(self, parent_item, value):
        for i in range(parent_item.childCount()):
            child = parent_item.child(i)
            if child.data(0, Qt.UserRole) == value:
                return child
            res = self.find_item_by_value(child, value)
            if res: return res
        return None

    def moveEvent(self, event):
        if hasattr(self, 'sw_popup'): self.sw_popup.hide()
        super().moveEvent(event)

    def eventFilter(self, obj, event):
        # 1. 偵測滑鼠點擊主視窗其他地方或外部時，關閉軟體清單
        if event.type() == QEvent.MouseButtonPress:
            if hasattr(self, 'sw_popup') and self.sw_popup.isVisible():
                # 取得全域點擊位置
                gp = event.globalPos()
                # 判斷點擊是否在搜尋框或彈出視窗之外
                if not self.sw_search.rect().contains(self.sw_search.mapFromGlobal(gp)) and \
                   not self.sw_popup.rect().contains(self.sw_popup.mapFromGlobal(gp)):
                    self.sw_popup.hide()
        
        # 2. 當主視窗失去焦點（例如 Alt-Tab 切換到其他 App）時，隱藏軟體清單
        elif event.type() == QEvent.WindowDeactivate:
            if hasattr(self, 'sw_popup') and self.sw_popup:
                self.sw_popup.hide()

        return super().eventFilter(obj, event)

    def resizeEvent(self, event):
        if hasattr(self, 'sw_popup'): self.sw_popup.hide()
        super().resizeEvent(event)

    def closeEvent(self, event: QCloseEvent):
        """Save settings before exiting."""
        if hasattr(self, 'sw_popup'): self.sw_popup.close()
        self.settings.setValue("geometry", self.saveGeometry())
        self.settings.setValue("splitterState", self.splitter.saveState())
        if self.selected_machine:
            self.settings.setValue("lastMachine", self.selected_machine)
        
        # Clean up threads gracefully
        for worker in self.active_workers[:]:
            worker.requestInterruption()
            if not worker.wait(500): # Don't block forever if download is stuck
                worker.terminate()
                worker.wait()
        event.accept()

    def apply_premium_theme(self):
        is_dark = self.is_dark_mode()
        
        # Color Palette
        bg_main = "#1e1e1e" if is_dark else "#f5f5f7"
        bg_panel = "#1a1a1a" if is_dark else "#ffffff"
        bg_right = "#2b2b2b" if is_dark else "#f0f0f2"
        bg_toolbar = "#2d2d2d" if is_dark else "#e5e5e7"
        bg_tab_pane = "#222" if is_dark else "#ffffff"
        bg_tab_unselected = "#333" if is_dark else "#e0e0e0"
        
        text_primary = "#eeeeee" if is_dark else "#1a1a1a"
        text_secondary = "#bbbbbb" if is_dark else "#444444"
        text_dim = "#888888" if is_dark else "#777777"
        text_tree = "#cccccc" if is_dark else "#222222"
        
        border_color = "#3d3d3d" if is_dark else "#d1d1d1"
        input_bg = "#2d2d2d" if is_dark else "#ffffff"
        
        accent = "#0078d4"
        hover_bg = "#3d3d3d" if is_dark else "#e0e0e0"

        self.setStyleSheet(f"""
            * {{
                font-family: 'Inter', 'Inter Display', 'Segoe UI Variable Display', 'Segoe UI', 'Microsoft JhengHei', sans-serif;
            }}
            QMainWindow {{ background-color: {bg_main}; }}
            
            #Toolbar {{ 
                background-color: {bg_toolbar}; 
                border-bottom: 1px solid {border_color};
            }}
            
            #ToolbarButton {{
                background-color: transparent;
                border: none;
                color: {text_secondary};
                padding: 8px 15px;
                font-size: 13px;
                font-weight: bold;
                border-radius: 4px;
            }}
            #ToolbarButton:hover {{ background-color: {hover_bg}; color: {"white" if is_dark else "#000"}; }}

            #LeftPanel {{ 
                background-color: {bg_panel}; 
                border-right: 1px solid {border_color};
            }}
            
            #SearchInput {{
                background-color: {input_bg};
                border: 1px solid {border_color};
                border-radius: 5px;
                padding: 6px 10px;
                color: {text_primary};
                margin-bottom: 5px;
            }}

            #CommandPreview {{
                background-color: {"#000" if is_dark else "#eee"};
                border: none;
                border-top: 1px solid {border_color};
                color: {text_primary if is_dark else "#333"};
                font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
                font-size: 11px;
                padding: 2px 10px;
            }}

            #MachineTree {{
                background-color: transparent;
                border: none;
                color: {text_tree};
                font-size: 13px;
                show-decoration-selected: 1;
            }}
            #MachineTree::item {{ padding: 5px; }}
            #MachineTree::item:selected {{
                background-color: {accent};
                color: white;
                border-radius: 4px;
            }}
            #MachineTree::item:hover:!selected {{
                background-color: {hover_bg};
            }}

            #RightPanel {{ background-color: {bg_right}; }}

            #SmallLabel {{
                color: {text_dim};
                font-size: 10px;
                font-weight: bold;
                margin-top: 5px;
            }}
            
            #SmallDimLabel {{
                color: {text_dim};
                font-size: 10px;
            }}

            #SlotLabel {{
                color: {text_secondary};
                font-size: 11px;
            }}

            #MediaHeader {{
                color: {text_primary};
                font-size: 11px;
                font-weight: bold;
            }}
            
            #MediaHandle {{
                color: {text_dim};
                font-size: 14px;
            }}

            #MediaEdit {{
                background-color: transparent;
                border: 1px solid {border_color};
                color: {text_secondary};
                font-size: 10px;
            }}

            #EjectButton {{
                background-color: transparent;
                color: {text_dim};
                border: none;
                font-size: 12px;
            }}
            #EjectButton:hover {{
                color: {text_primary};
            }}

            QTabWidget {{ background-color: transparent; }}
            QTabWidget::pane {{ border: 1px solid {border_color}; background-color: {bg_tab_pane}; border-radius: 4px; }}
            QTabBar::tab {{
                background-color: {bg_tab_unselected};
                color: {text_dim};
                padding: 4px 12px;
                font-size: 11px;
                border: 1px solid {border_color};
                margin-right: 1px;
            }}
            QTabBar::tab:selected {{
                background-color: {accent};
                color: white;
            }}
            QTabBar::tab:hover:!selected {{
                background-color: {hover_bg};
            }}

            QDialog, QMessageBox {{ 
                background-color: {bg_main}; 
                color: {text_secondary}; 
            }}
            QMessageBox QLabel {{ color: {text_secondary}; }}
            QMessageBox QPushButton {{ 
                background-color: {hover_bg}; 
                color: {text_primary}; 
                padding: 5px 15px; 
                border-radius: 3px; 
                min-width: 70px;
            }}
            QMessageBox QPushButton:hover {{ background-color: {accent}; color: white; }}

            QLabel {{ 
                color: {text_secondary}; 
                font-size: 11px;
                letter-spacing: 0.2px;
            }}

            QCheckBox, QRadioButton {{
                color: {text_secondary};
                font-size: 11px;
                spacing: 5px;
            }}
            QCheckBox::indicator, QRadioButton::indicator {{
                width: 14px;
                height: 14px;
                background-color: {input_bg};
                border: 1px solid {border_color};
                border-radius: 3px;
            }}
            QCheckBox::indicator:checked {{
                background-color: {accent};
                border-color: {accent};
            }}
            QRadioButton::indicator {{ border-radius: 7px; }}
            QRadioButton::indicator:checked {{
                background-color: {accent};
                border-color: {accent};
            }}

            QComboBox {{
                background-color: {input_bg};
                border: 1px solid {border_color};
                border-radius: 4px;
                padding: 2px 8px;
                color: {text_primary};
                font-size: 11px;
            }}
            QComboBox QAbstractItemView {{
                background-color: {bg_panel};
                color: {text_tree};
                selection-background-color: {accent};
                selection-color: white;
                border: 1px solid {border_color};
                outline: none;
            }}

            QComboBox[appleStyle="slot"] {{
                background-color: {input_bg if is_dark else "#fff"};
                border: 1px solid {border_color};
                border-radius: 4px;
                padding: 1px 4px;
                color: {text_primary};
                font-size: 11px;
            }}
            QComboBox[appleStyle="slot"]::drop-down {{
                border: none;
                background-color: #3b7ee1;
                width: 16px;
                border-top-right-radius: 3px;
                border-bottom-right-radius: 3px;
            }}
            QComboBox[appleStyle="slot"]::down-arrow {{
                image: none;
                border-left: 4px solid transparent;
                border-right: 4px solid transparent;
                border-top: 5px solid white;
                margin-top: 2px;
            }}

            QPushButton#LaunchButton {{
                background-color: #f39c12;
                color: white;
                border: none;
                border-radius: 4px;
                padding: 0;
            }}
            QPushButton#LaunchButton:hover {{ background-color: #f79c2a; }}

            #SoftwareSearch {{
                background-color: {input_bg};
                border: 1px solid {border_color};
                color: {text_primary};
                padding-left: 8px;
                border-radius: 4px;
            }}

            QScrollBar:vertical {{
                background: {bg_panel};
                width: 10px;
                margin: 0px;
            }}
            QScrollBar::handle:vertical {{
                background: {hover_bg};
                min-height: 20px;
                border-radius: 5px;
                margin: 2px;
            }}
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {{
                height: 0px;
            }}
        """)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = AmpleMainWindow()
    window.show()
    sys.exit(app.exec())
