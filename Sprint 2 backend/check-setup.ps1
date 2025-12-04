# PowerShell script to check backend setup
Write-Host "=== Backend Setup Checker ===" -ForegroundColor Cyan
Write-Host ""

# Check Node.js
Write-Host "Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js not found! Please install Node.js from https://nodejs.org/" -ForegroundColor Red
    exit 1
}

# Check npm
Write-Host "Checking npm..." -ForegroundColor Yellow
try {
    $npmVersion = npm --version
    Write-Host "✓ npm installed: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ npm not found!" -ForegroundColor Red
    exit 1
}

# Check if node_modules exists
Write-Host "Checking dependencies..." -ForegroundColor Yellow
if (Test-Path "node_modules") {
    Write-Host "✓ node_modules folder exists" -ForegroundColor Green
} else {
    Write-Host "✗ Dependencies not installed. Run: npm install" -ForegroundColor Red
    exit 1
}

# Check better-sqlite3
Write-Host "Checking better-sqlite3 module..." -ForegroundColor Yellow
try {
    $test = node -e "const Database = require('better-sqlite3'); console.log('OK');"
    if ($test -eq "OK") {
        Write-Host "✓ better-sqlite3 module works!" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ better-sqlite3 failed to load" -ForegroundColor Red
    Write-Host ""
    Write-Host "This usually means you need to install build tools:" -ForegroundColor Yellow
    Write-Host "1. Download Visual Studio Build Tools from:" -ForegroundColor White
    Write-Host "   https://visualstudio.microsoft.com/downloads/" -ForegroundColor Cyan
    Write-Host "2. Install 'Desktop development with C++' workload" -ForegroundColor White
    Write-Host "3. Restart PowerShell and run: npm rebuild better-sqlite3" -ForegroundColor White
    exit 1
}

# Check database file
Write-Host "Checking database..." -ForegroundColor Yellow
if (Test-Path "database.db") {
    Write-Host "✓ Database file exists" -ForegroundColor Green
} else {
    Write-Host "ℹ Database will be created on first run" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=== All checks passed! ===" -ForegroundColor Green
Write-Host "You can start the server with: npm start" -ForegroundColor Cyan


