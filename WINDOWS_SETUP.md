# 🪟 Windows Setup Guide

## Common Windows Issues & Solutions

### Issue: "cannot be loaded" or "execution policy" error

**Error Message:**
```
npm : File C:\Program Files\nodejs\npm.ps1 cannot be loaded. 
The file is not digitally signed.
```

**This happens because:** Windows PowerShell blocks unsigned scripts by default.

## ✅ Solutions (Pick One)

### Solution 1: Use Command Prompt (Recommended for Beginners)

**Why:** Doesn't require admin rights, always works.

**Steps:**
1. Press `Win + R` to open Run dialog
2. Type `cmd` and press Enter
3. Navigate to project folder:
   ```cmd
   cd C:\Users\sinan\Documents\GitHub\Prapest
   ```
4. Run setup:
   ```cmd
   setup.bat
   ```
5. Start app:
   ```cmd
   npm run dev
   ```

### Solution 2: Fix PowerShell Execution Policy (Permanent Fix)

**Why:** Allows PowerShell to run npm and other development tools.

**Steps:**
1. **Close all PowerShell windows**
2. Right-click **Windows PowerShell** in Start Menu
3. Choose **"Run as Administrator"**
4. Run this command:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
5. Type `Y` and press Enter to confirm
6. Close admin PowerShell
7. Open regular PowerShell and navigate to project
8. Now `npm run dev` will work!

### Solution 3: Bypass for Current Session Only

**Why:** Quick temporary fix without admin rights.

**Steps:**
In your current PowerShell window:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
npm run dev
```

**Note:** You'll need to run the first command each time you open PowerShell.

### Solution 4: Use Windows Terminal with Command Prompt

**Why:** Modern terminal with better features.

**Steps:**
1. Install Windows Terminal from Microsoft Store (if not already installed)
2. Open Windows Terminal
3. Click the ▼ dropdown next to the + button
4. Select **"Command Prompt"** (not PowerShell)
5. Navigate to project and run commands normally

## 📝 Full Setup Steps for Windows

### Using Command Prompt (Recommended):

```cmd
# 1. Navigate to project
cd C:\Users\sinan\Documents\GitHub\Prapest

# 2. Install dependencies
npm run install-all

# 3. Create .env file
cd backend
copy .env.example .env
cd ..

# 4. Start the app
npm run dev
```

### Using PowerShell (After fixing execution policy):

```powershell
# 1. Fix execution policy (run as admin, one time only)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 2. Navigate to project
cd C:\Users\sinan\Documents\GitHub\Prapest

# 3. Install dependencies
npm run install-all

# 4. Create .env file
cd backend
Copy-Item .env.example .env
cd ..

# 5. Start the app
npm run dev
```

## 🎯 After Running `npm run dev`

You should see:
```
> concurrently "npm run server" "npm run client"

[0] Server running on port 5000
[1] 
[1]   VITE v5.0.8  ready in 523 ms
[1] 
[1]   ➜  Local:   http://localhost:3000/
```

**Then open your browser to:** `http://localhost:3000`

## 🐛 Other Windows-Specific Issues

### "Port already in use" on Windows

**Check what's using the port:**
```cmd
netstat -ano | findstr :5000
netstat -ano | findstr :3000
```

**Kill the process:**
```cmd
taskkill /PID <PID_NUMBER> /F
```
Replace `<PID_NUMBER>` with the actual PID from the netstat command.

### "ENOENT: no such file or directory"

**Fix:** Make sure you're in the correct directory
```cmd
cd C:\Users\sinan\Documents\GitHub\Prapest
dir
```
You should see `package.json`, `backend`, and `frontend` folders.

### "node: command not found"

**Fix:** Node.js is not installed or not in PATH

1. Download Node.js from: https://nodejs.org/
2. Run the installer
3. **Important:** Check "Add to PATH" during installation
4. Restart Command Prompt/PowerShell
5. Verify: `node --version`

### "npm: command not found"

npm comes with Node.js. If it's not working:

1. Reinstall Node.js from https://nodejs.org/
2. Use the LTS (Long Term Support) version
3. During installation, ensure "npm package manager" is checked
4. Restart your terminal
5. Verify: `npm --version`

### Firewall Blocking

If Windows Firewall asks about Node.js:
- ✅ **Allow** on Private networks
- ✅ Click "Allow access"

### Antivirus Blocking

Some antivirus software blocks Node.js:
- Add Node.js to exceptions
- Add your project folder to exceptions
- Temporarily disable antivirus during development (not recommended for production)

## 💡 Windows Development Tips

### Use a Better Terminal

Consider installing:
- **Windows Terminal** (Microsoft Store) - Modern, tabs, better colors
- **Git Bash** (comes with Git for Windows) - Unix-like commands
- **cmder** - Portable console emulator

### Path Issues

Windows uses backslashes (`\`) but many tools expect forward slashes (`/`).
The app handles this automatically, but if you see path errors:
- Use forward slashes: `C:/Users/...`
- Or escape backslashes: `C:\\Users\\...`

### Line Endings

Windows uses CRLF (`\r\n`), Unix uses LF (`\n`).
Git usually handles this automatically, but if you have issues:

```cmd
git config --global core.autocrlf true
```

### Environment Variables

If you need to check your environment:
```cmd
echo %PATH%
echo %NODE_ENV%
```

PowerShell uses different syntax:
```powershell
$env:PATH
$env:NODE_ENV
```

## 🚀 Quick Reference

| Action | Command Prompt | PowerShell |
|--------|---------------|------------|
| List files | `dir` | `dir` or `ls` |
| Change directory | `cd folder` | `cd folder` |
| Go up one level | `cd..` | `cd..` |
| Clear screen | `cls` | `cls` or `clear` |
| Copy file | `copy source dest` | `Copy-Item source dest` |
| Delete file | `del file` | `Remove-Item file` |
| Show path | `cd` | `pwd` |

## ✅ Checklist

Before asking for help, verify:
- [ ] Node.js is installed: `node --version`
- [ ] npm is installed: `npm --version`
- [ ] You're in the correct directory: `cd` (shows current path)
- [ ] You can see package.json: `dir package.json`
- [ ] Dependencies are installed: Check if `node_modules` folder exists
- [ ] Using Command Prompt OR fixed PowerShell execution policy
- [ ] No other app is using port 3000 or 5000
- [ ] Windows Firewall allowed Node.js

## 🎓 Why This Happens

PowerShell's execution policy is a security feature that:
- Prevents running unsigned/untrusted scripts
- Protects against malicious code
- Is enabled by default on Windows

npm is installed as a PowerShell script (npm.ps1), which triggers this protection.

**Command Prompt (cmd.exe)** doesn't have this restriction, which is why it's often easier for development on Windows.

## 📞 Still Stuck?

If none of these solutions work:

1. **Try running everything in Command Prompt** - This works 99% of the time
2. **Restart your computer** - Refreshes PATH and system state
3. **Reinstall Node.js** - Use the LTS version from nodejs.org
4. **Check antivirus logs** - Your antivirus might be blocking Node.js
5. **Run as Administrator** - Right-click Command Prompt/PowerShell → "Run as administrator"

## 🎉 Success!

Once `npm run dev` runs successfully, you'll see both servers start.

Open your browser to **http://localhost:3000** and enjoy your app!

---

**Windows development can be tricky, but once set up, it works great! 💪**

