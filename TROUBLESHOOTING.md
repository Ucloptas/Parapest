# 🔧 Troubleshooting Guide

## Common Issues and Solutions

### Installation Issues

#### ❌ "npm: command not found"
**Problem:** Node.js is not installed or not in PATH

**Solution:**
1. Download and install Node.js from https://nodejs.org/
2. Restart your terminal
3. Verify installation: `node --version`

#### ❌ "Cannot find module" errors during install
**Problem:** Dependencies not properly installed

**Solution:**
```bash
# Delete node_modules and reinstall
rm -rf node_modules frontend/node_modules backend/node_modules
npm run install-all
```

#### ❌ "Permission denied" on Mac/Linux
**Problem:** Insufficient permissions

**Solution:**
```bash
# Make setup script executable
chmod +x setup.sh

# Or use sudo for npm (not recommended)
# Better: Fix npm permissions
# https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally
```

### Server Issues

#### ❌ "Port 5000 already in use"
**Problem:** Another application is using port 5000

**Solution 1 - Kill the process (Windows):**
```powershell
netstat -ano | findstr :5000
taskkill /PID <PID_NUMBER> /F
```

**Solution 2 - Kill the process (Mac/Linux):**
```bash
lsof -ti:5000 | xargs kill -9
```

**Solution 3 - Change the port:**
Edit `backend/.env`:
```
PORT=5001
```

#### ❌ "Port 3000 already in use"
**Problem:** Another application is using port 3000

**Solution 1 - Change the port:**
Edit `frontend/vite.config.js`:
```javascript
server: {
  port: 3001,  // Change this
  // ...
}
```

#### ❌ "Cannot connect to backend"
**Problem:** Backend server not running or wrong URL

**Solution:**
1. Make sure backend is running: `npm run server`
2. Check backend console for errors
3. Verify proxy in `frontend/vite.config.js`
4. Try accessing directly: http://localhost:5000/api/user

### Authentication Issues

#### ❌ "Invalid credentials" when logging in
**Problem:** Wrong username/password or user doesn't exist

**Solution:**
1. Make sure you registered first
2. Check username spelling (case-sensitive)
3. Try registering a new account
4. Check backend console for error messages

#### ❌ "Access token required" error
**Problem:** Token expired or missing

**Solution:**
1. Logout and login again
2. Clear browser localStorage:
   - Open browser DevTools (F12)
   - Go to Application > Storage > Local Storage
   - Delete all items
   - Refresh page and login again

#### ❌ "Family ID required for child accounts"
**Problem:** Trying to register child without Family ID

**Solution:**
1. Login as parent first
2. Copy the Family ID from parent dashboard header
3. Use that Family ID when registering child account

### Data Issues

#### ❌ "Data disappeared after restart"
**Problem:** database.json was deleted or corrupted

**Solution:**
1. Check if `backend/database.json` exists
2. If corrupted, delete it and restart server (will create new one)
3. **Prevention:** Backup database.json regularly
4. **Recovery:** Restore from backup if available

#### ❌ "Points not updating"
**Problem:** State not refreshing or API error

**Solution:**
1. Refresh the page
2. Logout and login again
3. Check browser console for errors (F12)
4. Check backend console for errors

#### ❌ "Chores/Rewards from other families showing"
**Problem:** Bug in family filtering (shouldn't happen)

**Solution:**
1. Check your Family ID in the header
2. Logout and login again
3. If persists, check backend logs
4. Last resort: Delete database.json and start fresh

### UI Issues

#### ❌ "Buttons not clickable"
**Problem:** CSS or JavaScript error

**Solution:**
1. Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
2. Clear browser cache
3. Try different browser
4. Check browser console for errors (F12)

#### ❌ "Modal won't close"
**Problem:** JavaScript event handler issue

**Solution:**
1. Press ESC key
2. Refresh page
3. Check browser console for errors

#### ❌ "Styles look broken"
**Problem:** CSS not loading

**Solution:**
1. Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
2. Check if frontend dev server is running
3. Check browser console for 404 errors
4. Clear browser cache

### Development Issues

#### ❌ "Hot reload not working"
**Problem:** Vite not detecting changes

**Solution:**
1. Save the file again
2. Check file is in `frontend/src/` directory
3. Restart frontend dev server
4. Check for syntax errors in the file

#### ❌ "CORS errors in browser console"
**Problem:** Frontend can't access backend

**Solution:**
1. Make sure backend is running
2. Check proxy configuration in `frontend/vite.config.js`
3. Verify backend has CORS enabled (it should by default)
4. Try accessing backend directly: http://localhost:5000/api/user

#### ❌ "ESLint errors"
**Problem:** Code style issues

**Solution:**
These are just warnings. The app will still work. To fix:
1. Review the specific error message
2. Fix the code according to the suggestion
3. Or disable ESLint temporarily if needed

### Build/Production Issues

#### ❌ "Build fails"
**Problem:** Error during `npm run build`

**Solution:**
1. Check for syntax errors in code
2. Make sure all dependencies are installed
3. Check Node.js version (should be v16+)
4. Look at specific error message for clues

#### ❌ "Production build not working"
**Problem:** Built files not serving correctly

**Solution:**
This project is designed for development. For production:
1. Build frontend: `cd frontend && npm run build`
2. Serve static files from backend
3. Configure environment variables properly
4. Use a proper database (not JSON file)

## Browser-Specific Issues

### Chrome/Edge
- **Issue:** Console warnings about React keys
- **Solution:** These are harmless warnings, can be ignored

### Firefox
- **Issue:** Slower performance
- **Solution:** Firefox is generally slower for React apps, this is normal

### Safari
- **Issue:** Some CSS features not working
- **Solution:** Safari has limited support for some modern CSS, consider using Chrome

## Still Having Issues?

### Debug Checklist:
1. ✅ Node.js installed? (`node --version`)
2. ✅ Dependencies installed? (`npm run install-all`)
3. ✅ Backend running? (Should see "Server running on port 5000")
4. ✅ Frontend running? (Should see "Local: http://localhost:3000")
5. ✅ Browser console clear? (F12 to check)
6. ✅ Backend console clear? (Check terminal)
7. ✅ .env file exists in backend?
8. ✅ Correct URL in browser? (http://localhost:3000)

### Get More Information:

**Backend Logs:**
Check the terminal where you ran `npm run server`

**Frontend Logs:**
Open browser DevTools (F12) and check Console tab

**Network Errors:**
Open browser DevTools (F12) > Network tab > Look for failed requests

### Common Error Messages:

| Error | Likely Cause | Fix |
|-------|-------------|-----|
| "Failed to fetch" | Backend not running | Start backend |
| "Network Error" | Wrong URL or CORS | Check backend URL |
| "Invalid token" | Expired session | Login again |
| "Not enough points" | Expected behavior | Earn more points |
| "Chore not found" | Deleted chore | Refresh page |
| "User not found" | Database issue | Check database.json |

## Nuclear Option 🔴

If nothing else works, start completely fresh:

```bash
# 1. Stop all servers (Ctrl+C)

# 2. Delete everything generated
rm -rf node_modules
rm -rf frontend/node_modules
rm -rf backend/node_modules
rm -rf backend/database.json
rm -rf frontend/dist

# 3. Reinstall
npm run install-all

# 4. Recreate .env
cd backend
cp .env.example .env
cd ..

# 5. Start fresh
npm run dev
```

## Getting Help

If you're still stuck:
1. Check the main README.md for setup instructions
2. Review QUICKSTART.md for basic setup
3. Check PROJECT_SUMMARY.md for architecture details
4. Look at the specific error message and search online
5. Check browser and backend console logs
6. Try in a different browser
7. Restart your computer (seriously, sometimes it helps!)

## Prevention Tips

To avoid issues:
- ✅ Backup `backend/database.json` regularly
- ✅ Keep Node.js updated
- ✅ Don't edit files while server is running
- ✅ Use the provided npm scripts
- ✅ Check for errors before moving on
- ✅ Read error messages carefully
- ✅ Test in a clean browser profile if issues persist

---

**Remember:** Most issues are caused by:
1. Forgetting to start the server
2. Wrong port numbers
3. Not installing dependencies
4. Cached data in browser

Happy troubleshooting! 🔧

