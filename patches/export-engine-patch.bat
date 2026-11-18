@echo off
chcp 936 >nul
setlocal

rem ============================================================
rem  一键导出 UE 引擎改动补丁
rem  引擎仓库：F:\KCKRoot\Engine
rem  基线    ：首次运行时记录的提交（git config kck.baseline）
rem             即使你中途在 UGit 里提交过，对比基线依然成立
rem  产物    ：同目录下 engine-<时间戳>.patch
rem ============================================================

set "ENGINE=F:\KCKRoot\Engine"
set "OUTDIR=%~dp0"
if "%OUTDIR:~-1%"=="\" set "OUTDIR=%OUTDIR:~0,-1%"

where git >nul 2>nul
if errorlevel 1 goto nogit
if not exist "%ENGINE%\.git" goto noeng
cd /d "%ENGINE%"
if errorlevel 1 goto noeng

set "BASE="
for /f %%i in ('git config kck.baseline') do set "BASE=%%i"
if "%BASE%"=="" (
    for /f %%i in ('git rev-parse HEAD') do set "BASE=%%i"
    git config kck.baseline %BASE%
)

echo.
echo [1/5] 基线提交：%BASE%
for /f %%i in ('git rev-parse HEAD') do set "HEADNOW=%%i"
if /i not "%HEADNOW%"=="%BASE%" echo       提示：HEAD 已前移（可能已在 UGit 里提交过），仍按初始基线比对，结果不受影响。

set "TRACKED=0"
for /f %%i in ('git -c diff.renames=false diff --name-only %BASE% -- . ^| find /c /v ""') do set "TRACKED=%%i"
set "NEW=0"
for /f %%i in ('git status --porcelain ^| findstr /b /c:"?? " ^| find /c /v ""') do set "NEW=%%i"
set /a TOTAL=%TRACKED%+%NEW%
echo [2/5] 修改或删除 %TRACKED% 个，新增 %NEW% 个
if "%TOTAL%"=="0" goto nochange

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmm"') do set "STAMP=%%i"
set "PATCH=%OUTDIR%\engine-%STAMP%.patch"
set "TMP=%OUTDIR%\_status.tmp"

echo [3/5] 登记新增文件 ...
if not "%NEW%"=="0" for /f "tokens=1*" %%a in ('git status --porcelain ^| findstr /b /c:"?? "') do git add -N "%%b" >nul 2>nul

echo [4/5] 生成补丁 ...
git status --porcelain > "%TMP%"
git -c diff.renames=false diff --binary %BASE% > "%PATCH%"
git reset -q >nul 2>nul

echo [5/5] 完成
echo.
echo       改动清单：
type "%TMP%"
echo.
for %%A in ("%PATCH%") do echo       补丁文件：%%~fA
for %%A in ("%PATCH%") do echo       补丁大小：%%~zA 字节
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
