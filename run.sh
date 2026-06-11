#!/bin/bash

set -e

echo "[*] Initializing Automation Environment..."

if ! command -v python3 &> /dev/null; then
    echo "[!] FATAL ERROR: python3 is not found on this system."
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
if (( $(echo "$PYTHON_VERSION < 3.10" | bc -l) )); then
    echo "[!] Warning: Python version ($PYTHON_VERSION) detected. mitmproxy highly recommends Python >= 3.10."
fi

if [ ! -d "venv" ]; then
    echo "[*] Virtual environment not found. Creating a new 'venv'..."
    python3 -m venv venv || { echo "[!] Failed to create venv. Ensure the python3-venv package is installed."; exit 1; }
fi

echo "[*] Activating virtual environment..."

source venv/bin/activate

echo "[*] Verifying Python dependencies..."

if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt -q
    
    echo "[*] Verifying Chromium engine..."
    playwright install chromium
else
    echo "[!] Warning: requirements.txt not found. Skipping dependency installation."
fi

trap 'echo -e "\n[*] Cleaning up background processes..."; kill $MITMDUMP_PID 2>/dev/null; exit 0' EXIT INT TERM

echo "[*] Launching Mitmproxy Engine (autodrop.py) in the background..."

mitmdump -s autodrop.py > mitm_output.log 2>&1 &
MITMDUMP_PID=$!

sleep 2

if ! ps -p $MITMDUMP_PID > /dev/null; then
    echo "[!] ERROR: mitmdump failed to start. Check mitm_output.log for details."
    cat mitm_output.log
    exit 1
fi

echo "[*] Launching Playwright Browser (chromium.py)..."

python3 chromium.py

echo "[*] Session complete."