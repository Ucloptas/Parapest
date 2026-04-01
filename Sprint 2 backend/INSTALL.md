# Backend Installation Guide for Windows

## Quick Answer

**You don't need to install SQL Server!** This project uses **SQLite**, which is a file-based database. However, the `better-sqlite3` package needs to be compiled, which requires build tools on Windows.

## Step-by-Step Installation

### Method 1: Try Pre-built Binary (Easiest - Try This First!)

1. Open PowerShell in the `Sprint 2 backend` folder
2. Run:
   ```powershell
   npm install --build-from-source=false
   ```
3. Test if it works:
   ```powershell
   npm start
   ```
4. If you see "Server running on port 5000", you're done! ✅

### Method 2: Install Build Tools (If Method 1 Fails)

If you get errors about "node-gyp" or "build tools", you need to install Visual Studio Build Tools:

#### Option A: Download and Install Manually

1. **Download Visual Studio Build Tools:**
   - Go to: https://visualstudio.microsoft.com/downloads/
   - Scroll to "Tools for Visual Studio" section
   - Click "Build Tools for Visual Studio 2022"

2. **Install:**
   - Run the downloaded installer
   - Check the box: **"Desktop development with C++"**
   - Click "Install" (this takes 10-20 minutes)
   - Wait for installation to complete

3. **Restart PowerShell** (close and reopen)

4. **Rebuild the module:**
   ```powershell
   cd "Sprint 2 backend"
   npm rebuild better-sqlite3
   ```

5. **Start the server:**
   ```powershell
   npm start
   ```

#### Option B: Use Chocolatey (If you have it installed)

```powershell
choco install visualstudio2022buildtools --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools"
```

Then restart PowerShell and run:
```powershell
cd "Sprint 2 backend"
npm rebuild better-sqlite3
npm start
```

## Verify Installation

After installation, test if SQLite works:

```powershell
node -e "const Database = require('better-sqlite3'); console.log('SQLite works!');"
```

If you see "SQLite works!", you're ready!

## Starting the Server

Once everything is installed:

```powershell
cd "Sprint 2 backend"
npm start
```

You should see:
```
Server running on port 5000
Using SQLite database: [path]\database.db
Database initialized
```

## Troubleshooting

### Error: "Cannot find module 'better-sqlite3'"
**Solution:** Run `npm install` in the backend directory

### Error: "node-gyp rebuild failed"
**Solution:** Install Visual Studio Build Tools (Method 2 above)

### Error: "Port 5000 already in use"
**Solution:** 
- Close other programs using port 5000
- Or create a `.env` file with: `PORT=5001`

### Error: "Access denied" or permission errors
**Solution:** Run PowerShell as Administrator

## What is SQLite?

SQLite is a **file-based database** - it stores all data in a single file (`database.db`). You don't need to:
- Install a database server
- Configure database connections
- Set up database users

The database file is created automatically when you first run the server!

## Need Help?

If you're still having issues:
1. Make sure Node.js is installed: `node --version` (should be v16+)
2. Make sure npm is installed: `npm --version`
3. Try deleting `node_modules` folder and `package-lock.json`, then run `npm install` again
4. Check the error message carefully - it usually tells you what's missing


