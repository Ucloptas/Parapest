# Fix: Missing Windows SDK

## The Problem
The error shows: `The Windows SDK version 10.0.22621.0 was not found`

Visual Studio 2022 is installed, but it's missing the specific Windows SDK version needed.

## Solution: Install Windows SDK

### Method 1: Through Visual Studio Installer (Recommended)

1. **Open Visual Studio Installer**
   - Press `Windows Key` and search for "Visual Studio Installer"
   - Or go to: `C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe`

2. **Modify Visual Studio 2022 Community**
   - Click "Modify" next to Visual Studio 2022 Community

3. **Install Windows SDK**
   - Go to the "Individual components" tab
   - Search for "Windows SDK"
   - Check the box for **"Windows 11 SDK (10.0.22621.0)"** or any **Windows 11 SDK (10.0.22621.x)**
   - If that exact version isn't available, check **"Windows 11 SDK (10.0.22000.0)"** or any Windows 11 SDK
   - Click "Modify" to install

4. **After installation, restart PowerShell** and try again:
   ```powershell
   cd "Sprint 2 backend"
   npm rebuild better-sqlite3
   npm start
   ```

### Method 2: Install Windows SDK Standalone

1. **Download Windows SDK**
   - Go to: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/
   - Download "Windows SDK for Windows 11" (version 22621 or latest)

2. **Install the SDK**

3. **Restart PowerShell** and rebuild:
   ```powershell
   cd "Sprint 2 backend"
   npm rebuild better-sqlite3
   npm start
   ```

### Method 3: Use a Different SDK Version (Quick Fix)

If you have a different Windows SDK version installed, we can configure node-gyp to use it:

1. **Check what SDKs you have:**
   ```powershell
   dir "C:\Program Files (x86)\Windows Kits\10\Include"
   ```

2. **Set the SDK version** (replace with your version):
   ```powershell
   $env:npm_config_msvs_version = "2022"
   $env:npm_config_windows_sdk_version = "10.0.22000.0"  # Use your installed version
   npm rebuild better-sqlite3
   ```

## After Installing SDK

Once the SDK is installed:

```powershell
cd "Sprint 2 backend"
npm rebuild better-sqlite3
npm start
```

You should see:
```
Server running on port 5000
Using SQLite database: [path]\database.db
Database initialized
```


