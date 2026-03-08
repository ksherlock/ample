@echo off
setlocal
title Ample Windows Launcher

echo ========================================
echo   Ample - Windows Port Auto Launcher
echo ========================================

:: Check for Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found! Please install Python 3.9 or newer.
    pause
    exit /b 1
)

:: Install/Update dependencies
echo [1/2] Checking dependencies...
pip install -r requirements.txt --quiet
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install requirements.
    pause
    exit /b 1
)

:: Run the application
echo [2/2] Launching Ample...
python main.py

if %errorlevel% neq 0 (
    echo.
    echo [INFO] Application exited with error code %errorlevel%.
    pause
)

endlocal
