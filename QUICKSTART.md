# 🚀 Quick Start Guide

Get up and running with Prapest in 3 minutes!

## Step 1: Install Dependencies (1 minute)

```bash
npm run install-all
```

## Step 2: Set Up Environment (30 seconds)

Create a `.env` file in the `backend` folder:

**Windows (PowerShell):**
```powershell
cd backend
Copy-Item .env.example .env
cd ..
```

**Mac/Linux:**
```bash
cd backend
cp .env.example .env
cd ..
```

The default settings work fine for development!

## Step 3: Start the App (30 seconds)

```bash
npm run dev
```

Wait for both servers to start, then open your browser to:
```
http://localhost:3000
```

## Step 4: Create Your First Accounts (1 minute)

### Create Parent Account:
1. Click "Register here"
2. Choose username and password
3. Select "👨‍👩‍👧‍👦 Parent"
4. Click "Register"
5. **IMPORTANT:** Copy your Family ID (shown in the dashboard)

### Create Child Account:
1. Logout (top right)
2. Click "Register here"
3. Choose username and password
4. Select "👶 Child"
5. Enter the Family ID from parent account
6. Click "Register"

## Step 5: Start Using! (30 seconds)

### As Parent:
1. Go to "📋 Chores" tab
2. Click "+ Add Chore"
3. Add a chore (e.g., "Clean room" for 10 points)
4. Go to "🎁 Rewards" tab
5. Click "+ Add Reward"
6. Add a reward (e.g., "Extra screen time" for 50 points)

### As Child:
1. Login with child account
2. See available chores
3. Complete a chore to earn points!
4. Browse rewards and redeem when you have enough points

## 🎉 That's it!

You're now ready to organize household chores and rewards!

## 📝 Quick Tips

- **Share Family ID**: Give the Family ID to all children in your household
- **Point Values**: Start with small rewards (5-20 points) and bigger rewards (50-100 points)
- **Real Rewards**: Make sure to actually give the rewards when children redeem them!
- **Backup Data**: The `backend/database.json` file contains all your data - back it up!

## ⚡ Commands Cheat Sheet

| Command | What it does |
|---------|-------------|
| `npm run dev` | Start both frontend and backend |
| `npm run server` | Start only backend |
| `npm run client` | Start only frontend |
| `npm run install-all` | Install all dependencies |

## 🆘 Having Issues?

**Can't login?**
- Make sure you registered first
- Check that backend server is running (you'll see "Server running on port 5000")

**Port already in use?**
- Close any other programs using port 3000 or 5000
- Or change the port in `backend/.env` (for backend) or `frontend/vite.config.js` (for frontend)

**Lost Family ID?**
- Login as parent and check the dashboard header
- It's the long number displayed in the header

Need more help? Check the full `README.md` file!

