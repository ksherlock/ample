@echo off
setlocal

cd /d "%~dp0"
echo [AmpleWin] Building standalone EXE...

:AskPyInstaller
where pyinstaller >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo [INFO] PyInstaller not found. Installing...
    pip install pyinstaller
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install PyInstaller.
        pause
        exit /b 1
    )
)

echo.
echo [0/2] Generating Application Icon...
python make_icon.py

echo.
echo [1/2] Converting main.py to EXE...
rem --noconfirm: overwrite output directory without asking
rem --onedir: create a directory with exe and dependencies (easier for debugging)
rem --windowed: no console window (for final release)
rem --name: name of the executable
rem --clean: clean cache

pyinstaller --noconfirm --onedir --windowed --clean --name "AmpleWin" --icon "app_icon.ico" main.py

if %errorlevel% neq 0 (
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

echo.
echo [2/2] Copying necessary assets...

rem Copy Resource directory from ..\Ample\Resources
rem We need to copy ..\Ample\Resources to dist\AmpleWin\Ample\Resources
if not exist "dist\AmpleWin\Ample\Resources" mkdir "dist\AmpleWin\Ample\Resources"

echo Copying Resources...
xcopy /E /I /Y "..\Ample\Resources\*.*" "dist\AmpleWin\Ample\Resources\" >nul

echo.
echo [SUCCESS] Build complete!
echo The standalone application is located in: AmpleWin\dist\AmpleWin\AmpleWin.exe
echo.

echo Cleaning up build artifacts...
if exist "build" rmdir /s /q "build"
if exist "AmpleWin.spec" del "AmpleWin.spec"

pause
