@echo off
chcp 936 >nul
setlocal

rem ============================================================
rem  一键导出 UE 引擎改动补丁
rem  引擎仓库：F:\KCKRoot\Engine
rem  基线    ：仓库初始快照（HEAD）
rem  产物    ：同目录下 engine-<时间戳>.patch
rem  说明    ：新增文件会被 git add -N 后一并写入补丁
rem ============================================================

set "ENGINE=F:\KCKRoot\Engine"
set "OUTDIR=%~dp0"
if "%OUTDIR:~-1%"=="\" set "OUTDIR=%OUTDIR:~0,-1%"

where git >nul 2>nul
if errorlevel 1 goto nogit

if not exist "%ENGINE%\.git" goto noeng

cd /d "%ENGINE%"

echo.
echo [1/4] 检查引擎改动 ...
set "CHANGED=0"
for /f %%i in ('git status --porcelain ^| find /c /v ""') do set "CHANGED=%%i"
echo       共 %CHANGED% 处改动
if "%CHANGED%"=="0" goto nochange

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmm"') do set "STAMP=%%i"
set "PATCH=%OUTDIR%\engine-%STAMP%.patch"
set "TMP=%OUTDIR%\_status.tmp"

echo [2/4] 把新增文件纳入补丁 ...
set "NEWCOUNT=0"
for /f %%i in ('git status --porcelain ^| findstr /b /c:"?? " ^| find /c /v ""') do set "NEWCOUNT=%%i"
if "%NEWCOUNT%"=="0" echo       没有新增文件
if not "%NEWCOUNT%"=="0" echo       发现 %NEWCOUNT% 个新增文件，正在登记 ...
for /f "tokens=1*" %%a in ('git status --porcelain ^| findstr /b /c:"?? "') do git add -N "%%b" >nul 2>nul

echo [3/4] 生成补丁 ...
git status --porcelain > "%TMP%"
git diff --binary HEAD > "%PATCH%"
git reset -q >nul 2>nul

echo [4/4] 完成
echo.
echo       改动清单：
type "%TMP%"
echo.
for %%A in ("%PATCH%") do echo       补丁文件：%%~fA
for %%A in ("%PATCH%") do echo       补丁大小：%%~zA 字节
if not "%NEWCOUNT%"=="0" echo       已包含 %NEWCOUNT% 个新增文件
del "%TMP%" >nul 2>nul

echo.
echo 下一步：把 patch 提交到 KCKProject 仓库的 patches 目录。
echo.
pause
exit /b 0

:nochange
echo.
echo       引擎没有检测到改动，无需导出。
echo.
pause
exit /b 0

:nogit
echo.
echo [错误] 没找到 git 命令，请先安装 Git 并加入 PATH。
echo.
pause
exit /b 1

:noeng
echo.
echo [错误] 没找到引擎仓库：%ENGINE%\.git
echo        如果已经删掉 .git，需要先重新初始化仓库。
echo.
pause
exit /b 1
