@echo off
cd /d "%~dp0"
set "ROOT=%~dp0"
title 澳门码投注计算器

echo ========================================
echo  澳门码投注计算器
echo ========================================

:: 检测 Python
set PY=
where py >nul 2>&1 && set PY=py -3
if "%PY%"=="" (
    where python >nul 2>&1 && set PY=python
)
if "%PY%"=="" (
    echo [错误] 未找到 Python
    echo 请从 https://www.python.org/downloads/ 安装
    pause
    exit /b
)
echo [OK] Python: %PY%

:: 安装依赖
%PY% -c "import requests" >nul 2>&1
if errorlevel 1 (
    echo [..] 正在安装 requests...
    %PY% -m pip install requests
    if errorlevel 1 (
        echo [错误] pip install 失败
        pause
        exit /b
    )
)
echo [OK] requests 已安装

:: 清理旧代理
taskkill /F /IM python*.exe >nul 2>&1

:: 启动代理 (使用绝对路径)
echo [1/2] 启动数据代理 localhost:3002 ...
start /B %PY% "%ROOT%server\proxy.py" > "%ROOT%proxy.log" 2>&1
timeout /t 3 /nobreak >nul

:: 检测 Flutter
set "FLUTTER_BIN=F:\flutter\flutter\bin"
where flutter >nul 2>&1
if errorlevel 1 (
    set "PATH=%PATH%;%FLUTTER_BIN%"
    where flutter >nul 2>&1
    if errorlevel 1 (
        echo [错误] 未找到 Flutter
        pause
        exit /b
    )
)
echo [OK] Flutter: %FLUTTER_BIN%

:: 启动 Flutter
echo [2/2] 启动 Flutter 应用...
echo.
echo  首次获取数据可能需要等待 60 秒
echo  之后会被缓存，秒级响应
echo.
cd /d "%ROOT%app"
call flutter run -d chrome --web-port 5000
cd /d "%ROOT%"
echo 清理中...
taskkill /F /IM python*.exe >nul 2>&1
echo 已关闭。
pause
