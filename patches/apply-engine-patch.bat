@echo off
chcp 936 >nul
setlocal

rem ============================================================
rem  在新电脑上应用引擎补丁
rem  用法一：把 .patch 文件拖到本脚本上
rem  用法二：直接双击，按提示输入补丁路径
rem  前提    ：目标机器已有同版本（UE 5.8.4）官方引擎源码
rem ============================================================

set "PATCH=%~1"
if "%PATCH%"=="" goto askpatch

:havepatch
if not exist "%PATCH%" goto nopatch

set "ENGDIR=%~2"
if "%ENGDIR%"=="" set /p ENGDIR=请输入引擎根目录（直接回车用 F:\KCKRoot\Engine）：
if "%ENGDIR%"=="" set "ENGDIR=F:\KCKRoot\Engine"

if not exist "%ENGDIR%\GenerateProjectFiles.bat" goto notue

echo.
echo   补丁  ：%PATCH%
echo   引擎  ：%ENGDIR%
echo.
cd /d "%ENGDIR%"
if errorlevel 1 goto notue

echo [1/3] 校验补丁能否直接应用 ...
git apply --check --whitespace=nowarn "%PATCH%" >nul 2>nul
if errorlevel 1 goto try3way
echo       校验通过。
echo [2/3] 应用补丁 ...
git apply --whitespace=nowarn "%PATCH%"
if errorlevel 1 goto applyfail
goto done

:try3way
echo       直接应用有冲突，改用三方合并重试 ...
git apply --3way "%PATCH%"
if errorlevel 1 goto checkfail
goto done

:done
echo [3/3] 完成，补丁已应用。
echo.
echo   下一步：
echo     1. 运行 GenerateProjectFiles.bat 重新生成工程文件
echo     2. 用 VS 打开 UE5.sln 编译
echo.
pause
exit /b 0

:askpatch
echo.
set /p PATCH=请把 .patch 文件拖到这里再回车：
if "%PATCH%"=="" goto nopatch
goto havepatch

:checkfail
echo.
echo [失败] 补丁无法应用，常见原因：
echo        1) 目标引擎不是 5.8.4，或源码与基线不一致
echo        2) 这个补丁已经打过了
echo        3) 目标文件被改动过（先 git status 看看）
echo        4) 换行符被改过：可尝试 git apply --ignore-whitespace
echo.
pause
exit /b 1

:applyfail
echo.
echo [失败] 写入文件时出错，请先关掉 UE 编辑器和 Visual Studio 再试。
echo.
pause
exit /b 1

:nopatch
echo.
echo [错误] 没找到补丁文件。
echo.
pause
exit /b 1

:notue
echo.
echo [错误] 该目录不像 UE 引擎根目录（缺少 GenerateProjectFiles.bat）。
echo.
pause
exit /b 1
