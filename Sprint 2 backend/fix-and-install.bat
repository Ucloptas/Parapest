@echo off
echo ========================================
echo Fixing better-sqlite3 Installation
echo ========================================
echo.

echo The issue: Missing Windows SDK 10.0.22621.0
echo.
echo SOLUTION: Install Windows SDK through Visual Studio Installer
echo.
echo Steps:
echo 1. Open Visual Studio Installer (search in Windows Start menu)
echo 2. Click "Modify" on Visual Studio 2022 Community
echo 3. Go to "Individual components" tab
echo 4. Search for "Windows SDK"
echo 5. Check "Windows 11 SDK (10.0.22621.0)" or any Windows 11 SDK
echo 6. Click "Modify" to install (takes 5-10 minutes)
echo 7. After installation, restart this terminal
echo 8. Then run: npm rebuild better-sqlite3
echo.
echo ========================================
echo.
echo Trying alternative: Using any available Windows SDK...
echo.

REM Try to set SDK version to use any available one
set npm_config_msvs_version=2022
set npm_config_windows_sdk_version=10.0.22000.0

echo Attempting rebuild with SDK 10.0.22000.0...
call npm rebuild better-sqlite3

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS! Rebuild completed!
    echo ========================================
    echo.
    echo You can now start the server with:
    echo   npm start
    echo.
    pause
    exit /b 0
) else (
    echo.
    echo ========================================
    echo Rebuild failed
    echo ========================================
    echo.
    echo Please install Windows SDK through Visual Studio Installer:
    echo (See instructions above)
    echo.
    pause
    exit /b 1
)


