# Quick Fix: Missing Windows SDK

## The Error
```
error MSB8036: The Windows SDK version 10.0.22621.0 was not found
```

## Solution (5 minutes)

### Step 1: Open Visual Studio Installer
- Press `Windows Key` and type "Visual Studio Installer"
- Click to open it

### Step 2: Modify Visual Studio 2022
- Find "Visual Studio 2022 Community" in the list
- Click the **"Modify"** button

### Step 3: Install Windows SDK
1. Click the **"Individual components"** tab at the top
2. In the search box, type: **"Windows SDK"**
3. Look for **"Windows 11 SDK (10.0.22621.0)"**
   - If that exact version isn't there, check **any "Windows 11 SDK"** version
   - Or check **"Windows 10 SDK (10.0.19041.0)"** or later
4. Check the box next to it
5. Click **"Modify"** at the bottom right
6. Wait for installation (5-10 minutes)

### Step 4: Restart Terminal
- **Close** your PowerShell/Command Prompt
- **Open a new one**

### Step 5: Rebuild and Start
```powershell
cd "Sprint 2 backend"
npm rebuild better-sqlite3
npm start
```

## That's It!

You should now see:
```
Server running on port 5000
Using SQLite database: [path]\database.db
Database initialized
```

## Alternative: If You Can't Install SDK

If you can't install the SDK right now, you can use an alternative SQLite package that doesn't require compilation. Let me know and I can help switch the code to use a different package.


