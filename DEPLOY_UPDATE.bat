@echo off
setlocal enabledelayedexpansion
title ULTIMATE.cc - FINAL REDEMPTION v13.6
color 0b

echo ========================================================
echo         ULTIMATE.cc - DISPATCHER v13.6
echo ========================================================
echo.
echo [1] PRIVATE BUILD (Local Only)
echo [2] LIVE DEPLOY    (GitHub Global)
echo.
choice /c 12 /n /m "SELECT UPDATE TYPE (1 or 2): "
set DEPLOY_TYPE=%ERRORLEVEL%
cls

echo ========================================================
echo         ULTIMATE.cc - PRO AUTO-DEPLOYMENT
echo ========================================================
echo.

:: [1/3] Finding MSBuild
set "VSW=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq tokens=*" %%i in (`"!VSW!" -latest -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
    set "MSB=%%i\MSBuild\Current\Bin\MSBuild.exe"
)

:: CLEAN OLD FILES
echo [STEP 1] Cleaning old binaries...
if exist Loader.exe del /f /q Loader.exe
if exist x64\Release\Loader.exe del /f /q x64\Release\Loader.exe
if exist build_log.txt del /f /q build_log.txt

:: [2/3] THE SYNCHRONOUS BUILD
echo [STEP 2] Building Project (Release x64)...
echo Building... (Sync Mode)

:: Synchronous Rebuild
"!MSB!" "Internal Base.sln" /t:Rebuild /p:Configuration=Release /p:Platform=x64 /v:m /m /p:BuildInParallel=true /p:CL_MPCount=12 /nodeReuse:false /clp:NoSummary > build_log.txt 2>&1

:: Check if build actually succeeded
if not exist "x64\Release\Loader.exe" (
    echo.
    powershell -Command "Write-Host '--------------------------------------------------------' -ForegroundColor Red; Write-Host '[CRITICAL ERROR] BUILD FAILED!' -ForegroundColor Red -Bold; Write-Host '--------------------------------------------------------' -ForegroundColor Red; Get-Content build_log.txt | ForEach-Object { if ($_ -match 'error') { Write-Host $_ -ForegroundColor Red } };"
    pause
    exit /b
)

echo [DONE] Build Successful.

:: [3/3] POST-BUILD VERSIONING & SYNC
echo [STEP 3] Finalizing Global Release...
set "V_FILE=version.txt"
if not exist %V_FILE% echo 4.1 > %V_FILE%
powershell -Command "$v = [float](Get-Content %V_FILE%); $v += 0.1; \"{0:N1}\" -f $v | Set-Content 'version.tmp'"
move /y "version.tmp" "%V_FILE%" >nul
for /f "tokens=*" %%a in (%V_FILE%) do set NEW_V=%%a

:: Force version and UI Sync
powershell -Command "(Get-Content 'Loader\main.cpp') -replace '#define LOADER_VERSION \".*\"', '#define LOADER_VERSION \"%NEW_V%\"' | Set-Content 'Loader\main.cpp'"

echo Copying v%NEW_V% to Root...
copy /y "x64\Release\Loader.exe" "Loader.exe" >nul

:: Global Sync (FIXED)
if %DEPLOY_TYPE% EQU 2 (
    echo Global Syncing to GitHub Global...
    git add . >nul
    git commit -m "Auto-Deploy v%NEW_V% - Global Sync Complete" >nul 2>&1
    git push origin main > github_log.txt 2>&1
    echo [OK] Global Sync Complete.
)

echo.
echo ========================================================
echo   ULTIMATE.cc - v%NEW_V% IS OFFICIALLY LIVE!🥇🦅💎
echo ========================================================
echo.
echo Launching v%NEW_V% Loader...
start "" "Loader.exe"
timeout /t 3 >nul
exit
