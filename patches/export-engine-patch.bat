@echo off
chcp 936 >nul
setlocal

rem ============================================================
rem  导出 UE 引擎改动（相对官方 5.8.4 的累计差异）
rem
rem  仓库：F:\KCKRoot\Engine（历史已挂在 Epic 官方 5.8.4 提交上）
rem  基线：git config kck.baseline，默认 f45729c0b（Epic 官方 5.8.4）
rem        在仓库里正常 commit 不会影响比对，基线永远是官方提交
rem  输出：同目录 engine-latest.patch（每次覆盖，含全部改动）
rem        换机器时只需应用最新这一份，不要叠加旧补丁
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
if "%BASE%"=="" goto nobase

echo.
echo [1/5] 基线提交：%BASE%
for /f %%i in ('git rev-parse --short HEAD') do set "HEADS=%%i"
echo       当前 HEAD：%HEADS%
for /f "tokens=*" %%l in ('git log --oneline %BASE%..HEAD') do echo       本地提交：%%l

set "TRACKED=0"
for /f %%i in ('git -c diff.renames=false diff --name-only %BASE% -- . ^| find /c /v ""') do set "TRACKED=%%i"
set "NEW=0"
for /f %%i in ('git status --porcelain ^| findstr /b /c:"?? " ^| find /c /v ""') do set "NEW=%%i"
set /a TOTAL=%TRACKED%+%NEW%
echo [2/5] 修改或删除 %TRACKED% 个，新增 %NEW% 个
if "%TOTAL%"=="0" goto nochange

set "PATCH=%OUTDIR%\engine-latest.patch"
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
echo 这份补丁是相对官方 5.8.4 的全量差异。
echo 换机器时只应用最新一份，旧的可以删掉，不要叠加。
echo.
pause
exit /b 0

:nochange
echo.
echo       引擎没有检测到改动，无需导出。
echo.
pause
exit /b 0

:nobase
echo.
echo [错误] 未设置基线提交（git config kck.baseline 为空）。
echo        请先执行：git -C %ENGINE% config kck.baseline f45729c0b
echo.
pause
exit /b 1

:nogit
echo.
echo [错误] 没找到 git 命令，请先安装 Git 并加入 PATH。
echo.
pause
exit /b 1

:noeng
echo.
echo [错误] 没找到引擎仓库：%ENGINE%\.git
echo        如果已经删掉 .git，需要重新初始化仓库。
echo.
pause
exit /b 1
