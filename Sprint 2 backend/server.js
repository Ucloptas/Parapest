const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs').promises;
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const DB_FILE = path.join(__dirname, 'database.json');

// Middleware
app.use(cors());
app.use(express.json());

// Initialize database
async function initDatabase() {
  try {
    await fs.access(DB_FILE);
  } catch {
    const initialData = {
      users: [],
      chores: [],
      rewards: [],
      completedChores: [],
      redeemedRewards: []
    };
    await fs.writeFile(DB_FILE, JSON.stringify(initialData, null, 2));
  }
}

// Database operations
async function readDB() {
  const data = await fs.readFile(DB_FILE, 'utf8');
  return JSON.parse(data);
}

async function writeDB(data) {
  await fs.writeFile(DB_FILE, JSON.stringify(data, null, 2));
}

// Auth middleware
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
}

// Parent-only middleware
function requireParent(req, res, next) {
  if (req.user.role !== 'parent') {
    return res.status(403).json({ error: 'Parent access required' });
  }
  next();
}

// Routes

// Register
app.post('/api/register', async (req, res) => {
  try {
    const { username, password, role, familyId } = req.body;

    if (!username || !password || !role) {
      return res.status(400).json({ error: 'Username, password, and role are required' });
    }

    if (!['parent', 'child'].includes(role)) {
      return res.status(400).json({ error: 'Role must be parent or child' });
    }

    const db = await readDB();
    
    // Check if username exists
    if (db.users.find(u => u.username === username)) {
      return res.status(400).json({ error: 'Username already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Generate familyId if parent, or use provided familyId
    const userFamilyId = role === 'parent' ? Date.now().toString() : familyId;

    if (role === 'child' && !familyId) {
      return res.status(400).json({ error: 'Family ID required for child accounts' });
    }

    const user = {
      id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
      username,
      password: hashedPassword,
      role,
      familyId: userFamilyId,
      points: 0,
      createdAt: new Date().toISOString()
    };

    db.users.push(user);
    await writeDB(db);

    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role, familyId: user.familyId },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        role: user.role,
        familyId: user.familyId,
        points: user.points
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Login
app.post('/api/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password are required' });
    }

    const db = await readDB();
    const user = db.users.find(u => u.username === username);

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role, familyId: user.familyId },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        role: user.role,
        familyId: user.familyId,
        points: user.points
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Logout endpoint (for consistency, JWT is stateless so just returns success)
app.post('/api/logout', (req, res) => {
  res.json({ message: 'Logged out successfully' });
});

// Get current user
app.get('/api/user', authenticateToken, async (req, res) => {
  try {
    const db = await readDB();
    const user = db.users.find(u => u.id === req.user.id);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      id: user.id,
      username: user.username,
      role: user.role,
      familyId: user.familyId,
      points: user.points
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get family members
app.get('/api/family', authenticateToken, async (req, res) => {
  try {
    const db = await readDB();
    const familyMembers = db.users
      .filter(u => u.familyId === req.user.familyId)
      .map(u => ({
        id: u.id,
        username: u.username,
        role: u.role,
        points: u.points
      }));

    res.json({ users: familyMembers });
  } catch (error) {
    console.error('Get family error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Chores routes

// Get all chores for family
app.get('/api/chores', authenticateToken, async (req, res) => {
  try {
    const db = await readDB();
    const chores = db.chores.filter(c => c.familyId === req.user.familyId);
    res.json({ chores });
  } catch (error) {
    console.error('Get chores error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Create chore (parent only)
app.post('/api/chores', authenticateToken, requireParent, async (req, res) => {
  try {
    const { title, description, points } = req.body;

    if (!title || !points) {
      return res.status(400).json({ error: 'Title and points are required' });
    }

    const db = await readDB();
    const chore = {
      id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
      title,
      description: description || '',
      points: parseInt(points),
      familyId: req.user.familyId,
      createdBy: req.user.id,
      createdAt: new Date().toISOString()
    };

    db.chores.push(chore);
    await writeDB(db);

    res.json(chore);
  } catch (error) {
    console.error('Create chore error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update chore (parent only)
app.put('/api/chores/:id', authenticateToken, requireParent, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, points, status } = req.body;

    const db = await readDB();
    const choreIndex = db.chores.findIndex(c => c.id === id && c.familyId === req.user.familyId);

    if (choreIndex === -1) {
      return res.status(404).json({ error: 'Chore not found' });
    }

    db.chores[choreIndex] = {
      ...db.chores[choreIndex],
      title: title || db.chores[choreIndex].title,
      description: description !== undefined ? description : db.chores[choreIndex].description,
      points: points !== undefined ? parseInt(points) : db.chores[choreIndex].points,
      status: status || db.chores[choreIndex].status,
      updatedAt: new Date().toISOString()
    };

    await writeDB(db);
    res.json(db.chores[choreIndex]);
  } catch (error) {
    console.error('Update chore error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete chore (parent only)
app.delete('/api/chores/:id', authenticateToken, requireParent, async (req, res) => {
  try {
    const { id } = req.params;
    const db = await readDB();
    
    const choreIndex = db.chores.findIndex(c => c.id === id && c.familyId === req.user.familyId);
    if (choreIndex === -1) {
      return res.status(404).json({ error: 'Chore not found' });
    }

    db.chores.splice(choreIndex, 1);
    await writeDB(db);

    res.json({ message: 'Chore deleted successfully' });
  } catch (error) {
    console.error('Delete chore error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Complete chore (child only)
app.post('/api/chores/:id/complete', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'child') {
      return res.status(403).json({ error: 'Only children can complete chores' });
    }

    const { id } = req.params;
    const db = await readDB();

    const chore = db.chores.find(c => c.id === id && c.familyId === req.user.familyId);
    if (!chore) {
      return res.status(404).json({ error: 'Chore not found' });
    }

    // Add points to user
    const userIndex = db.users.findIndex(u => u.id === req.user.id);
    if (userIndex === -1) {
      return res.status(404).json({ error: 'User not found' });
    }

    db.users[userIndex].points += chore.points;

    // Record completed chore
    const completedChore = {
      id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
      choreId: chore.id,
      choreTitle: chore.title,
      userId: req.user.id,
      username: req.user.username,
      points: chore.points,
      completedAt: new Date().toISOString()
    };

    db.completedChores.push(completedChore);
    await writeDB(db);

    res.json({
      message: 'Chore completed successfully',
      points: chore.points,
      totalPoints: db.users[userIndex].points
    });
  } catch (error) {
    console.error('Complete chore error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get completed chores
app.get('/api/completed-chores', authenticateToken, async (req, res) => {
  try {
    const db = await readDB();
    const user = db.users.find(u => u.id === req.user.id);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Get all completed chores for the family
    const familyUserIds = db.users
      .filter(u => u.familyId === req.user.familyId)
      .map(u => u.id);

    const completedChores = db.completedChores
      .filter(c => familyUserIds.includes(c.userId))
      .sort((a, b) => new Date(b.completedAt) - new Date(a.completedAt));

    res.json(completedChores);
  } catch (error) {
    console.error('Get completed chores error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Rewards routes

// Get all rewards for family
app.get('/api/rewards', authenticateToken, async (req, res) => {
  try {
    const db = await readDB();
    const rewards = db.rewards.filter(r => r.familyId === req.user.familyId);
    res.json({ rewards });
  } catch (error) {
    console.error('Get rewards error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Create reward (parent only)
app.post('/api/rewards', authenticateToken, requireParent, async (req, res) => {
  try {
    const { title, description, cost } = req.body;

    if (!title || !cost) {
      return res.status(400).json({ error: 'Title and cost are required' });
    }

    const db = await readDB();
    const reward = {
      id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
      title,
      description: description || '',
      cost: parseInt(cost),
      familyId: req.user.familyId,
      createdBy: req.user.id,
      createdAt: new Date().toISOString()
    };

    db.rewards.push(reward);
    await writeDB(db);

    res.json(reward);
  } catch (error) {
    console.error('Create reward error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update reward (parent only)
app.put('/api/rewards/:id', authenticateToken, requireParent, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, cost, status, stock } = req.body;

    const db = await readDB();
    const rewardIndex = db.rewards.findIndex(r => r.id === id && r.familyId === req.user.familyId);

    if (rewardIndex === -1) {
      return res.status(404).json({ error: 'Reward not found' });
    }

    db.rewards[rewardIndex] = {
      ...db.rewards[rewardIndex],
      title: title || db.rewards[rewardIndex].title,
      description: description !== undefined ? description : db.rewards[rewardIndex].description,
      cost: cost !== undefined ? parseInt(cost) : db.rewards[rewardIndex].cost,
      status: status || db.rewards[rewardIndex].status,
      stock: stock !== undefined ? (stock === null ? null : parseInt(stock)) : db.rewards[rewardIndex].stock,
      updatedAt: new Date().toISOString()
    };

    await writeDB(db);
    res.json(db.rewards[rewardIndex]);
  } catch (error) {
    console.error('Update reward error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete reward (parent only)
app.delete('/api/rewards/:id', authenticateToken, requireParent, async (req, res) => {
  try {
    const { id } = req.params;
    const db = await readDB();
    
    const rewardIndex = db.rewards.findIndex(r => r.id === id && r.familyId === req.user.familyId);
    if (rewardIndex === -1) {
      return res.status(404).json({ error: 'Reward not found' });
    }

    db.rewards.splice(rewardIndex, 1);
    await writeDB(db);

    res.json({ message: 'Reward deleted successfully' });
  } catch (error) {
    console.error('Delete reward error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Redeem reward (child only)
app.post('/api/rewards/:id/redeem', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'child') {
      return res.status(403).json({ error: 'Only children can redeem rewards' });
    }

    const { id } = req.params;
    const db = await readDB();

    const reward = db.rewards.find(r => r.id === id && r.familyId === req.user.familyId);
    if (!reward) {
      return res.status(404).json({ error: 'Reward not found' });
    }

    // Check if user has enough points
    const userIndex = db.users.findIndex(u => u.id === req.user.id);
    if (userIndex === -1) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (db.users[userIndex].points < reward.cost) {
      return res.status(400).json({ error: 'Not enough points' });
    }

    // Deduct points from user
    db.users[userIndex].points -= reward.cost;

    // Record redeemed reward
    const redeemedReward = {
      id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
      rewardId: reward.id,
      rewardTitle: reward.title,
      userId: req.user.id,
      username: req.user.username,
      cost: reward.cost,
      redeemedAt: new Date().toISOString()
    };

    db.redeemedRewards.push(redeemedReward);
    await writeDB(db);

    res.json({
      message: 'Reward redeemed successfully',
      cost: reward.cost,
      remainingPoints: db.users[userIndex].points
    });
  } catch (error) {
    console.error('Redeem reward error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get redeemed rewards
app.get('/api/redeemed-rewards', authenticateToken, async (req, res) => {
  try {
    const db = await readDB();
    const user = db.users.find(u => u.id === req.user.id);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Get all redeemed rewards for the family
    const familyUserIds = db.users
      .filter(u => u.familyId === req.user.familyId)
      .map(u => u.id);

    const redeemedRewards = db.redeemedRewards
      .filter(r => familyUserIds.includes(r.userId))
      .sort((a, b) => new Date(b.redeemedAt) - new Date(a.redeemedAt));

    res.json(redeemedRewards);
  } catch (error) {
    console.error('Get redeemed rewards error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Start server
initDatabase().then(() => {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
});

