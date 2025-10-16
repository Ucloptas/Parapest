@echo off
echo ========================================
echo  Prapest - Chore and Reward Manager
echo  Windows Setup Script
echo ========================================
echo.

echo [1/3] Installing dependencies...
echo.
call npm run install-all

echo.
echo [2/3] Setting up backend environment...
echo.
cd backend
if not exist .env (
    copy .env.example .env
    echo Created .env file from template
) else (
    echo .env file already exists
)
cd ..

echo.
echo [3/3] Setup complete!
echo.
echo ========================================
echo  Next Steps:
echo ========================================
echo.
echo 1. Start the application:
echo    npm run dev
echo.
echo 2. Open your browser to:
echo    http://localhost:3000
echo.
echo 3. Create a parent account first
echo.
echo 4. Note your Family ID and share with children
echo.
echo For more help, see QUICKSTART.md
echo.
pause

