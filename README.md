# 🏠 Prapest - Chore & Reward Manager

A modern web application for organizing household chores and rewards. Parents can create chores and rewards, while children can complete chores to earn points and redeem them for rewards. Built with React and Node.js.

## ✨ Features

### For Parents 👨‍👩‍👧‍👦
- **F1: Add Rewards** - Create rewards that children can redeem for a set number of points
- **F2: Add Chores** - Create chores/tasks with point rewards
- **View Family** - See all family members and their point balances
- **Activity History** - Track completed chores and redeemed rewards
- **Manage Everything** - Edit or delete chores and rewards as needed

### For Children 👶
- **F3: Complete Chores** - Mark chores as complete to earn points
- **F4: Redeem Rewards** - Spend earned points on available rewards
- **View Progress** - See current point balance
- **Browse Options** - Explore available chores and rewards

## 🛠️ Technology Stack

- **Frontend**: React 18, React Router, Axios, Vite
- **Backend**: Node.js, Express
- **Authentication**: JWT (JSON Web Tokens), bcryptjs
- **Database**: JSON file-based storage (simple and portable)
- **Styling**: Modern CSS with gradients and animations

## 📋 Requirements Met

### Functional Requirements ✅
- ✅ R1: Parents can add rewards into the system for a cost of x points
- ✅ R2: Parents can add chores/tasks into the system with reward of x points
- ✅ R3: Children can complete chores/tasks to earn points
- ✅ R4: Children can redeem points to earn real life rewards
- ✅ R5: Children and parents can log in and view chores/rewards
- ✅ R6: Children can grab completed chores and take it to the reward area for point redemption
- ✅ R7: Children can choose chores to start

### Non-Functional Requirements ✅

**Security:**
- ✅ Role-based access control (parents vs children)
- ✅ JWT-based authentication
- ✅ Password hashing with bcrypt
- ✅ Separate login for each user

**Reliability:**
- ✅ Persistent data storage
- ✅ Error handling throughout the application
- ✅ Real-time points updates

**Usability:**
- ✅ Intuitive interface for children and parents
- ✅ Simple navigation with clear tabs
- ✅ Immediate feedback on actions
- ✅ Child-friendly design with emojis and colors

**Maintainability:**
- ✅ Modular component structure
- ✅ Clean separation of concerns (frontend/backend)
- ✅ RESTful API design
- ✅ Well-organized code structure

## 🚀 Getting Started

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn

### Installation

1. **Clone the repository**
   ```bash
   cd Prapest
   ```

2. **Install all dependencies**
   ```bash
   npm run install-all
   ```
   This will install dependencies for the root, backend, and frontend.

3. **Set up environment variables**
   
   Create a `.env` file in the `backend` directory (copy from `.env.example`):
   ```bash
   cd backend
   cp .env.example .env
   ```
   
   Edit the `.env` file and set your JWT secret:
   ```
   PORT=5000
   JWT_SECRET=your-secret-key-change-this-in-production
   NODE_ENV=development
   ```

### Running the Application

**Development Mode (Recommended)**

Run both frontend and backend simultaneously:
```bash
npm run dev
```

This will start:
- Backend server on `http://localhost:5000`
- Frontend development server on `http://localhost:3000`

**Or run separately:**

Terminal 1 - Backend:
```bash
npm run server
```

Terminal 2 - Frontend:
```bash
npm run client
```

### First Time Setup

1. **Open your browser** and go to `http://localhost:3000`

2. **Create a Parent Account**
   - Click "Register here"
   - Choose "Parent" as your role
   - A Family ID will be generated for you
   - **Save this Family ID** - you'll need it for child accounts

3. **Create a Child Account**
   - Logout and click "Register here" again
   - Choose "Child" as your role
   - Enter the Family ID from step 2
   - Now both accounts are in the same family!

4. **Start Using the App**
   - Login as parent to add chores and rewards
   - Login as child to complete chores and redeem rewards

## 📖 User Guide

### Parent Workflow

1. **Login** with your parent account
2. **Add Chores**:
   - Go to the "Chores" tab
   - Click "+ Add Chore"
   - Enter title, description, and points reward
   - Click "Save Chore"
3. **Add Rewards**:
   - Go to the "Rewards" tab
   - Click "+ Add Reward"
   - Enter title, description, and points cost
   - Click "Save Reward"
4. **Monitor Activity**:
   - View "Family" tab to see everyone's points
   - Check "History" tab to see completed chores and redeemed rewards

### Child Workflow

1. **Login** with your child account
2. **Complete Chores**:
   - View available chores in the "Available Chores" tab
   - Click "✅ I Completed This!" when you finish a chore
   - Watch your points increase!
3. **Redeem Rewards**:
   - Browse rewards in the "Rewards Shop" tab
   - Click "🎁 Redeem Now!" when you have enough points
   - Ask your parent to give you your reward!

## 📁 Project Structure

```
Prapest/
├── backend/
│   ├── server.js          # Express server and API routes
│   ├── database.json      # Data storage (auto-generated)
│   ├── package.json       # Backend dependencies
│   └── .env.example       # Environment variables template
├── frontend/
│   ├── src/
│   │   ├── components/    # React components
│   │   │   ├── Login.jsx
│   │   │   ├── Register.jsx
│   │   │   ├── ParentDashboard.jsx
│   │   │   ├── ChildDashboard.jsx
│   │   │   ├── Auth.css
│   │   │   └── Dashboard.css
│   │   ├── context/       # React context
│   │   │   └── AuthContext.jsx
│   │   ├── App.jsx        # Main app component
│   │   ├── App.css
│   │   ├── main.jsx       # Entry point
│   │   └── index.css      # Global styles
│   ├── index.html
│   ├── vite.config.js     # Vite configuration
│   └── package.json       # Frontend dependencies
├── package.json           # Root package.json
└── README.md              # This file
```

## 🔒 Security Notes

- The `.env` file contains sensitive information and should never be committed to version control
- Change the `JWT_SECRET` in production
- The `database.json` file stores all data - back it up regularly
- In production, consider using a proper database (PostgreSQL, MongoDB, etc.)

## 🎨 Features in Detail

### Points System
- Children earn points by completing chores
- Points are tracked in real-time
- Points can be redeemed for rewards
- All transactions are logged in the history

### Family System
- Each family has a unique Family ID
- Multiple children can join a family using the Family ID
- All family members share the same pool of chores and rewards

### User Roles
- **Parent**: Can create, edit, and delete chores and rewards
- **Child**: Can complete chores and redeem rewards (but cannot modify them)

## 🐛 Troubleshooting

**Problem: Port already in use**
- Solution: Change the port in `backend/.env` (backend) or `frontend/vite.config.js` (frontend)

**Problem: Cannot connect to backend**
- Solution: Make sure the backend server is running on port 5000
- Check the proxy configuration in `frontend/vite.config.js`

**Problem: Login not working**
- Solution: Make sure you've created an account first via the Register page
- Check that the backend server is running

**Problem: Data lost after restart**
- Solution: The `database.json` file stores all data. Make sure it's not being deleted
- Check file permissions

## 🔮 Future Enhancements

Ideas for future development:
- [ ] Add profile pictures for users
- [ ] Implement chore assignments (parent assigns specific chores to specific children)
- [ ] Add recurring chores (daily, weekly, etc.)
- [ ] Notification system
- [ ] Mobile app version
- [ ] Integration with the 2D platformer game
- [ ] Statistics and charts for tracking progress
- [ ] Photo verification for completed chores
- [ ] Custom themes and avatars

## 📝 License

MIT License - Feel free to use and modify as needed.

## 🤝 Contributing

This is a personal project, but suggestions and improvements are welcome!

## 📧 Support

If you encounter any issues, please check the Troubleshooting section or create an issue in the repository.

---

**Enjoy organizing your household chores! 🏠✨**

