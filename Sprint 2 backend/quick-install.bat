@echo off
echo ========================================
echo Backend Quick Install for Windows
echo ========================================
echo.

echo Step 1: Installing dependencies...
call npm install --build-from-source=false

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Installation failed. Trying to rebuild...
    call npm rebuild better-sqlite3
)

echo.
echo Step 2: Testing SQLite module...
node -e "try { const Database = require('better-sqlite3'); console.log('SUCCESS: SQLite is working!'); } catch(e) { console.log('FAILED: ' + e.message); process.exit(1); }"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo INSTALLATION FAILED
    echo ========================================
    echo.
    echo You need to install Visual Studio Build Tools:
    echo.
    echo 1. Download from: https://visualstudio.microsoft.com/downloads/
    echo 2. Install "Build Tools for Visual Studio 2022"
    echo 3. Select "Desktop development with C++" workload
    echo 4. After installation, restart this terminal and run:
    echo    npm rebuild better-sqlite3
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo INSTALLATION SUCCESSFUL!
echo ========================================
echo.
echo You can now start the server with:
echo   npm start
echo.
pause


