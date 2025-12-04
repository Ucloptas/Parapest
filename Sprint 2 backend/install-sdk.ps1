# Script to help install Windows SDK for better-sqlite3
Write-Host "=== Windows SDK Checker ===" -ForegroundColor Cyan
Write-Host ""

# Check for installed SDKs
$sdkPaths = @(
    "C:\Program Files (x86)\Windows Kits\10\Include",
    "C:\Program Files\Windows Kits\10\Include"
)

$foundSdks = @()
foreach ($path in $sdkPaths) {
    if (Test-Path $path) {
        Write-Host "Found Windows Kits at: $path" -ForegroundColor Green
        $sdks = Get-ChildItem $path -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^10\.0\." }
        if ($sdks) {
            Write-Host "Installed SDK versions:" -ForegroundColor Yellow
            foreach ($sdk in $sdks) {
                Write-Host "  - $($sdk.Name)" -ForegroundColor White
                $foundSdks += $sdk.Name
            }
        }
    }
}

Write-Host ""

if ($foundSdks.Count -eq 0) {
    Write-Host "✗ No Windows SDK found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "You need to install Windows SDK:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1: Through Visual Studio Installer (Easiest)" -ForegroundColor Cyan
    Write-Host "  1. Open Visual Studio Installer" -ForegroundColor White
    Write-Host "  2. Click 'Modify' on Visual Studio 2022 Community" -ForegroundColor White
    Write-Host "  3. Go to 'Individual components' tab" -ForegroundColor White
    Write-Host "  4. Search for 'Windows SDK'" -ForegroundColor White
    Write-Host "  5. Check 'Windows 11 SDK (10.0.22621.0)' or any Windows 11 SDK" -ForegroundColor White
    Write-Host "  6. Click 'Modify' to install" -ForegroundColor White
    Write-Host ""
    Write-Host "Option 2: Download Standalone SDK" -ForegroundColor Cyan
    Write-Host "  Download from: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "✓ Found $($foundSdks.Count) SDK version(s)" -ForegroundColor Green
    Write-Host ""
    
    # Check if the required version is installed
    $requiredVersion = "10.0.22621.0"
    if ($foundSdks -contains $requiredVersion) {
        Write-Host "✓ Required SDK version ($requiredVersion) is installed!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Try rebuilding:" -ForegroundColor Yellow
        Write-Host "  npm rebuild better-sqlite3" -ForegroundColor Cyan
    } else {
        Write-Host "⚠ Required version ($requiredVersion) not found" -ForegroundColor Yellow
        Write-Host "  You have: $($foundSdks -join ', ')" -ForegroundColor White
        Write-Host ""
        Write-Host "Trying to use available SDK version..." -ForegroundColor Yellow
        
        # Try to use the latest available SDK
        $latestSdk = ($foundSdks | Sort-Object -Descending)[0]
        Write-Host "Using SDK: $latestSdk" -ForegroundColor Cyan
        
        # Set environment variables
        $env:npm_config_msvs_version = "2022"
        $env:npm_config_windows_sdk_version = $latestSdk
        
        Write-Host ""
        Write-Host "Rebuilding better-sqlite3 with SDK $latestSdk..." -ForegroundColor Yellow
        npm rebuild better-sqlite3
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✓ Rebuild successful!" -ForegroundColor Green
            Write-Host "You can now run: npm start" -ForegroundColor Cyan
        } else {
            Write-Host ""
            Write-Host "✗ Rebuild failed. You may need to install SDK version $requiredVersion" -ForegroundColor Red
        }
    }
}

Write-Host ""


