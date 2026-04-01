# Windows Setup Guide for Backend

## SQLite Database Setup

Good news! This project uses **SQLite**, which is a file-based database. You don't need to install a separate SQL server like MySQL or PostgreSQL.

However, the `better-sqlite3` package requires native compilation on Windows, which means you need build tools.

## Option 1: Install Visual Studio Build Tools (Recommended)

1. **Download Visual Studio Build Tools:**
   - Go to: https://visualstudio.microsoft.com/downloads/
   - Scroll down to "Tools for Visual Studio"
   - Download "Build Tools for Visual Studio 2022"

2. **Install with C++ workload:**
   - Run the installer
   - Select "Desktop development with C++" workload
   - Click "Install"
   - This will take 10-20 minutes

3. **Restart your terminal/PowerShell** after installation

4. **Install dependencies:**
   ```powershell
   cd "Sprint 2 backend"
   npm install
   ```

5. **Start the server:**
   ```powershell
   npm start
   ```

## Option 2: Use Pre-built Binary (Easier, but may not work on all systems)

Try installing with the pre-built binary first:

```powershell
cd "Sprint 2 backend"
npm install --build-from-source=false
```

If this works, you're done! If you get errors, use Option 1.

## Option 3: Use Alternative SQLite Package (If build tools don't work)

If you continue having issues, we can switch to `sqlite3` package instead, which has better Windows support:

```powershell
cd "Sprint 2 backend"
npm uninstall better-sqlite3
npm install sqlite3
```

Then we'll need to update `server.js` to use the different API.

## Quick Test

After installation, test if SQLite works:

```powershell
cd "Sprint 2 backend"
node -e "const Database = require('better-sqlite3'); const db = new Database('test.db'); console.log('SQLite works!'); db.close();"
```

If you see "SQLite works!", you're ready to go!

## Starting the Server

Once everything is installed:

```powershell
cd "Sprint 2 backend"
npm start
```

You should see:
```
Server running on port 5000
Using SQLite database: [path to database.db]
```

## Troubleshooting

**Error: "node-gyp rebuild failed"**
- Install Visual Studio Build Tools (Option 1)

**Error: "Cannot find module 'better-sqlite3'"**
- Run `npm install` in the backend directory

**Error: "Port 5000 already in use"**
- Close other programs using port 5000
- Or change PORT in a `.env` file

**Still having issues?**
- Make sure you have Node.js v16 or higher: `node --version`
- Make sure npm is installed: `npm --version`
- Try deleting `node_modules` and `package-lock.json`, then run `npm install` again


