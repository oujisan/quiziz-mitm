@echo off
setlocal enabledelayedexpansion

echo [*] Initializing Automation Environment for Windows...

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] FATAL ERROR: Python is not found on this system or not in PATH.
    exit /b 1
)

if not exist "venv\" (
    echo [*] Virtual environment not found. Creating a new 'venv'...
    python -m venv venv
    if !errorlevel! neq 0 (
        echo [!] ERROR: Failed to create venv. Check your Python installation.
        exit /b 1
    )
)

echo [*] Activating virtual environment...
call venv\Scripts\activate.bat

echo [*] Verifying Python dependencies...
if exist "requirements.txt" (
    pip install -r requirements.txt -q
    echo [*] Verifying Chromium engine...
    playwright install chromium
) else (
    echo [!] Warning: requirements.txt not found. Skipping dependency installation.
)

echo [*] Launching Mitmproxy Engine (drop.py) in the background...
start /B cmd /c "mitmdump -s autodrop.py > mitm_output.log 2>&1"

timeout /t 2 /nobreak >nul

echo [*] Launching Playwright Browser (chromium.py)...
python chromium.py


echo.
echo [*] Cleaning up background processes...

taskkill /F /IM mitmdump.exe >nul 2>&1

echo [*] Session complete.