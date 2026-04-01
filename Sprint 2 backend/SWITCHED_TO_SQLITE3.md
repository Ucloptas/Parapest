# Switched from better-sqlite3 to sqlite3

## What Changed

I've switched the backend from `better-sqlite3` to `sqlite3` to avoid Windows SDK compilation issues.

### Changes Made:

1. **package.json**: Changed dependency from `better-sqlite3` to `sqlite3`
2. **server.js**: 
   - Updated database initialization to use `sqlite3` instead of `better-sqlite3`
   - Converted all synchronous database calls to async/await
   - Added promise wrappers for easier async usage

### Key Differences:

- **better-sqlite3**: Synchronous API (faster, but requires native compilation)
- **sqlite3**: Asynchronous API (works on Windows without build tools, uses pre-built binaries)

## Installation

The package has been installed. You can now start the server:

```powershell
cd "Sprint 2 backend"
npm start
```

## Testing

The server should now start without any Windows SDK errors. You should see:

```
Database initialized
Server running on port 5000
Using SQLite database: [path]\database.db
```

## Benefits

✅ No Windows SDK required  
✅ No build tools needed  
✅ Pre-built binaries work out of the box  
✅ Same functionality, just async instead of sync  

## Note

All database operations are now asynchronous. The code has been updated to use `async/await` throughout, so the API behavior remains the same from the client's perspective.

