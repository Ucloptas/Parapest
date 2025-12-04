# Installation script for Windows
Write-Host "=== Installing Backend Dependencies ===" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "package.json")) {
    Write-Host "Error: package.json not found. Please run this script from the 'Sprint 2 backend' directory." -ForegroundColor Red
    exit 1
}

# Step 1: Try installing with pre-built binaries first
Write-Host "Step 1: Attempting to install with pre-built binaries..." -ForegroundColor Yellow
npm install --build-from-source=false

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Installation successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Testing SQLite module..." -ForegroundColor Yellow
    
    # Test if better-sqlite3 works
    $testResult = node -e "try { const Database = require('better-sqlite3'); console.log('SUCCESS'); } catch(e) { console.log('FAILED: ' + e.message); }" 2>&1
    
    if ($testResult -match "SUCCESS") {
        Write-Host "✓ SQLite module is working!" -ForegroundColor Green
        Write-Host ""
        Write-Host "=== Setup Complete ===" -ForegroundColor Green
        Write-Host "You can now start the server with: npm start" -ForegroundColor Cyan
        exit 0
    } else {
        Write-Host "✗ SQLite module failed to load" -ForegroundColor Red
        Write-Host ""
    }
} else {
    Write-Host "✗ Installation with pre-built binaries failed" -ForegroundColor Red
    Write-Host ""
}

# Step 2: If pre-built failed, try rebuilding
Write-Host "Step 2: Attempting to rebuild native modules..." -ForegroundColor Yellow
npm rebuild better-sqlite3

if ($LASTEXITCODE -eq 0) {
    $testResult = node -e "try { const Database = require('better-sqlite3'); console.log('SUCCESS'); } catch(e) { console.log('FAILED'); }" 2>&1
    
    if ($testResult -match "SUCCESS") {
        Write-Host "✓ Rebuild successful! SQLite is working!" -ForegroundColor Green
        Write-Host ""
        Write-Host "=== Setup Complete ===" -ForegroundColor Green
        Write-Host "You can now start the server with: npm start" -ForegroundColor Cyan
        exit 0
    }
}

# Step 3: If still failing, provide instructions
Write-Host ""
Write-Host "=== Installation Failed ===" -ForegroundColor Red
Write-Host ""
Write-Host "The better-sqlite3 package requires native compilation tools." -ForegroundColor Yellow
Write-Host ""
Write-Host "Please install Visual Studio Build Tools:" -ForegroundColor White
Write-Host ""
Write-Host "1. Download from: https://visualstudio.microsoft.com/downloads/" -ForegroundColor Cyan
Write-Host "   (Look for 'Build Tools for Visual Studio 2022')" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Run the installer and select:" -ForegroundColor White
Write-Host "   ✓ Desktop development with C++" -ForegroundColor Green
Write-Host ""
Write-Host "3. After installation, restart PowerShell and run:" -ForegroundColor White
Write-Host "   npm rebuild better-sqlite3" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Then test with:" -ForegroundColor White
Write-Host "   npm start" -ForegroundColor Cyan
Write-Host ""
Write-Host "Alternatively, you can use Chocolatey to install build tools:" -ForegroundColor Yellow
Write-Host "   choco install visualstudio2022buildtools --package-parameters `"--add Microsoft.VisualStudio.Workload.VCTools`"" -ForegroundColor Cyan
Write-Host ""

exit 1


