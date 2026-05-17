@echo off
cd /d "%~dp0"
title Macau Calculator
echo ===== Macau Lottery Calculator =====

:: Python detection
set PY=
py --version >_ 2>&1
if not errorlevel 1 set PY=py -3
if "%PY%"=="" (
    python --version >_ 2>&1
    if not errorlevel 1 set PY=python
)
del _ 2>_

if "%PY%"=="" (
    echo [FAIL] Python not found - install from python.org
    pause
    exit /b
)
echo [OK] Python: %PY%

:: requests
%PY% -c "import requests" >_ 2>&1
if errorlevel 1 (
    echo [..] pip install requests...
    %PY% -m pip install requests
    if errorlevel 1 (
        echo [FAIL] pip install failed
        pause
        exit /b
    )
)

:: Cleanup old proxy
taskkill /F /IM python*.exe >_ 2>&1

:: Start proxy
echo [1/2] Starting proxy on localhost:3002...
start /B %PY% server\proxy.py > proxy.log 2>&1
timeout /t 3 /nobreak >_

:: Flutter
where flutter >_ 2>&1
if errorlevel 1 (
    set "PATH=%PATH%;F:\flutter\flutter\bin"
    where flutter >_ 2>&1
    if errorlevel 1 (
        echo [FAIL] Flutter not found
        pause
        exit /b
    )
)
echo [OK] Flutter ready

:: Launch Flutter
echo [2/2] Launching Flutter app...
cd /d "%~dp0app"
call flutter run -d chrome --web-port 5000
cd /d "%~dp0"
echo Cleanup...
taskkill /F /IM python*.exe >_ 2>&1
del _ 2>_
echo Done.
pause
