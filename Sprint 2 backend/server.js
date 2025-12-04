const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Database = require('better-sqlite3');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const DB_FILE = path.join(__dirname, 'database.db');

// Initialize SQLite database
const db = new Database(DB_FILE);
db.pragma('journal_mode = WAL'); // Better performance for concurrent reads

// Middleware
app.use(cors());
app.use(express.json());

// Initialize database tables
function initDatabase() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT NOT NULL CHECK(role IN ('parent', 'child')),
      familyId TEXT NOT NULL,
      points INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS chores (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT DEFAULT '',
      points INTEGER NOT NULL,
      familyId TEXT NOT NULL,
      createdBy TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT,
      status TEXT DEFAULT 'active'
    );

    CREATE TABLE IF NOT EXISTS rewards (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT DEFAULT '',
      cost INTEGER NOT NULL,
      familyId TEXT NOT NULL,
      createdBy TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT,
      status TEXT DEFAULT 'active',
      stock INTEGER
    );

    CREATE TABLE IF NOT EXISTS completedChores (
      id TEXT PRIMARY KEY,
      choreId TEXT NOT NULL,
      choreTitle TEXT NOT NULL,
      userId TEXT NOT NULL,
      username TEXT NOT NULL,
      points INTEGER NOT NULL,
      completedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS redeemedRewards (
      id TEXT PRIMARY KEY,
      rewardId TEXT NOT NULL,
      rewardTitle TEXT NOT NULL,
      userId TEXT NOT NULL,
      username TEXT NOT NULL,
      cost INTEGER NOT NULL,
      redeemedAt TEXT NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_users_familyId ON users(familyId);
    CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
    CREATE INDEX IF NOT EXISTS idx_chores_familyId ON chores(familyId);
    CREATE INDEX IF NOT EXISTS idx_rewards_familyId ON rewards(familyId);
    CREATE INDEX IF NOT EXISTS idx_completedChores_userId ON completedChores(userId);
    CREATE INDEX IF NOT EXISTS idx_redeemedRewards_userId ON redeemedRewards(userId);
  `);
  console.log('Database initialized');
}

// Generate unique ID
function generateId() {
  return Date.now().toString() + Math.random().toString(36).substr(2, 9);
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

    // Check if username exists
    const existingUser = db.prepare('SELECT id FROM users WHERE username = ?').get(username);
    if (existingUser) {
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
      id: generateId(),
      username,
      password: hashedPassword,
      role,
      familyId: userFamilyId,
      points: 0,
      createdAt: new Date().toISOString()
    };

    db.prepare(`
      INSERT INTO users (id, username, password, role, familyId, points, createdAt)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(user.id, user.username, user.password, user.role, user.familyId, user.points, user.createdAt);

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

    const user = db.prepare('SELECT * FROM users WHERE username = ?').get(username);

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
app.get('/api/user', authenticateToken, (req, res) => {
  try {
    const user = db.prepare('SELECT id, username, role, familyId, points FROM users WHERE id = ?').get(req.user.id);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get family members
app.get('/api/family', authenticateToken, (req, res) => {
  try {
    const familyMembers = db.prepare(`
      SELECT id, username, role, points FROM users WHERE familyId = ?
    `).all(req.user.familyId);

    res.json(familyMembers);
  } catch (error) {
    console.error('Get family error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Chores routes

// Get all chores for family
app.get('/api/chores', authenticateToken, (req, res) => {
  try {
    const chores = db.prepare('SELECT * FROM chores WHERE familyId = ?').all(req.user.familyId);
    res.json(chores);
  } catch (error) {
    console.error('Get chores error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Create chore (parent only)
app.post('/api/chores', authenticateToken, requireParent, (req, res) => {
  try {
    const { title, description, points } = req.body;

    if (!title || !points) {
      return res.status(400).json({ error: 'Title and points are required' });
    }

    const chore = {
      id: generateId(),
      title,
      description: description || '',
      points: parseInt(points),
      familyId: req.user.familyId,
      createdBy: req.user.id,
      createdAt: new Date().toISOString()
    };

    db.prepare(`
      INSERT INTO chores (id, title, description, points, familyId, createdBy, createdAt)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(chore.id, chore.title, chore.description, chore.points, chore.familyId, chore.createdBy, chore.createdAt);

    res.json(chore);
  } catch (error) {
    console.error('Create chore error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update chore (parent only)
app.put('/api/chores/:id', authenticateToken, requireParent, (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, points, status } = req.body;

    const chore = db.prepare('SELECT * FROM chores WHERE id = ? AND familyId = ?').get(id, req.user.familyId);

    if (!chore) {
      return res.status(404).json({ error: 'Chore not found' });
    }

    const updatedChore = {
      ...chore,
      title: title || chore.title,
      description: description !== undefined ? description : chore.description,
      points: points !== undefined ? parseInt(points) : chore.points,
      status: status || chore.status,
      updatedAt: new Date().toISOString()
    };

    db.prepare(`
      UPDATE chores SET title = ?, description = ?, points = ?, status = ?, updatedAt = ?
      WHERE id = ? AND familyId = ?
    `).run(updatedChore.title, updatedChore.description, updatedChore.points, updatedChore.status, updatedChore.updatedAt, id, req.user.familyId);

    res.json(updatedChore);
  } catch (error) {
    console.error('Update chore error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete chore (parent only)
app.delete('/api/chores/:id', authenticateToken, requireParent, (req, res) => {
  try {
    const { id } = req.params;
    
    const result = db.prepare('DELETE FROM chores WHERE id = ? AND familyId = ?').run(id, req.user.familyId);
    
    if (result.changes === 0) {
      return res.status(404).json({ error: 'Chore not found' });
    }

    res.json({ message: 'Chore deleted successfully' });
  } catch (error) {
    console.error('Delete chore error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Complete chore (child only)
app.post('/api/chores/:id/complete', authenticateToken, (req, res) => {
  try {
    if (req.user.role !== 'child') {
      return res.status(403).json({ error: 'Only children can complete chores' });
    }

    const { id } = req.params;

    const chore = db.prepare('SELECT * FROM chores WHERE id = ? AND familyId = ?').get(id, req.user.familyId);
    if (!chore) {
      return res.status(404).json({ error: 'Chore not found' });
    }

    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Update user points
    const newPoints = user.points + chore.points;
    db.prepare('UPDATE users SET points = ? WHERE id = ?').run(newPoints, req.user.id);

    // Record completed chore
    const completedChore = {
      id: generateId(),
      choreId: chore.id,
      choreTitle: chore.title,
      userId: req.user.id,
      username: req.user.username,
      points: chore.points,
      completedAt: new Date().toISOString()
    };

    db.prepare(`
      INSERT INTO completedChores (id, choreId, choreTitle, userId, username, points, completedAt)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(completedChore.id, completedChore.choreId, completedChore.choreTitle, completedChore.userId, completedChore.username, completedChore.points, completedChore.completedAt);

    res.json({
      message: 'Chore completed successfully',
      points: chore.points,
      totalPoints: newPoints
    });
  } catch (error) {
    console.error('Complete chore error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get completed chores
app.get('/api/completed-chores', authenticateToken, (req, res) => {
  try {
    // Get all completed chores for the family
    const completedChores = db.prepare(`
      SELECT cc.* FROM completedChores cc
      INNER JOIN users u ON cc.userId = u.id
      WHERE u.familyId = ?
      ORDER BY cc.completedAt DESC
    `).all(req.user.familyId);

    res.json(completedChores);
  } catch (error) {
    console.error('Get completed chores error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Rewards routes

// Get all rewards for family
app.get('/api/rewards', authenticateToken, (req, res) => {
  try {
    const rewards = db.prepare('SELECT * FROM rewards WHERE familyId = ?').all(req.user.familyId);
    res.json(rewards);
  } catch (error) {
    console.error('Get rewards error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Create reward (parent only)
app.post('/api/rewards', authenticateToken, requireParent, (req, res) => {
  try {
    const { title, description, cost } = req.body;

    if (!title || !cost) {
      return res.status(400).json({ error: 'Title and cost are required' });
    }

    const reward = {
      id: generateId(),
      title,
      description: description || '',
      cost: parseInt(cost),
      familyId: req.user.familyId,
      createdBy: req.user.id,
      createdAt: new Date().toISOString()
    };

    db.prepare(`
      INSERT INTO rewards (id, title, description, cost, familyId, createdBy, createdAt)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(reward.id, reward.title, reward.description, reward.cost, reward.familyId, reward.createdBy, reward.createdAt);

    res.json(reward);
  } catch (error) {
    console.error('Create reward error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update reward (parent only)
app.put('/api/rewards/:id', authenticateToken, requireParent, (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, cost, status, stock } = req.body;

    const reward = db.prepare('SELECT * FROM rewards WHERE id = ? AND familyId = ?').get(id, req.user.familyId);

    if (!reward) {
      return res.status(404).json({ error: 'Reward not found' });
    }

    const updatedReward = {
      ...reward,
      title: title || reward.title,
      description: description !== undefined ? description : reward.description,
      cost: cost !== undefined ? parseInt(cost) : reward.cost,
      status: status || reward.status,
      stock: stock !== undefined ? (stock === null ? null : parseInt(stock)) : reward.stock,
      updatedAt: new Date().toISOString()
    };

    db.prepare(`
      UPDATE rewards SET title = ?, description = ?, cost = ?, status = ?, stock = ?, updatedAt = ?
      WHERE id = ? AND familyId = ?
    `).run(updatedReward.title, updatedReward.description, updatedReward.cost, updatedReward.status, updatedReward.stock, updatedReward.updatedAt, id, req.user.familyId);

    res.json(updatedReward);
  } catch (error) {
    console.error('Update reward error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete reward (parent only)
app.delete('/api/rewards/:id', authenticateToken, requireParent, (req, res) => {
  try {
    const { id } = req.params;
    
    const result = db.prepare('DELETE FROM rewards WHERE id = ? AND familyId = ?').run(id, req.user.familyId);
    
    if (result.changes === 0) {
      return res.status(404).json({ error: 'Reward not found' });
    }

    res.json({ message: 'Reward deleted successfully' });
  } catch (error) {
    console.error('Delete reward error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Redeem reward (child only)
app.post('/api/rewards/:id/redeem', authenticateToken, (req, res) => {
  try {
    if (req.user.role !== 'child') {
      return res.status(403).json({ error: 'Only children can redeem rewards' });
    }

    const { id } = req.params;

    const reward = db.prepare('SELECT * FROM rewards WHERE id = ? AND familyId = ?').get(id, req.user.familyId);
    if (!reward) {
      return res.status(404).json({ error: 'Reward not found' });
    }

    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.points < reward.cost) {
      return res.status(400).json({ error: 'Not enough points' });
    }

    // Deduct points from user
    const remainingPoints = user.points - reward.cost;
    db.prepare('UPDATE users SET points = ? WHERE id = ?').run(remainingPoints, req.user.id);

    // Record redeemed reward
    const redeemedReward = {
      id: generateId(),
      rewardId: reward.id,
      rewardTitle: reward.title,
      userId: req.user.id,
      username: req.user.username,
      cost: reward.cost,
      redeemedAt: new Date().toISOString()
    };

    db.prepare(`
      INSERT INTO redeemedRewards (id, rewardId, rewardTitle, userId, username, cost, redeemedAt)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(redeemedReward.id, redeemedReward.rewardId, redeemedReward.rewardTitle, redeemedReward.userId, redeemedReward.username, redeemedReward.cost, redeemedReward.redeemedAt);

    res.json({
      message: 'Reward redeemed successfully',
      cost: reward.cost,
      remainingPoints
    });
  } catch (error) {
    console.error('Redeem reward error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get redeemed rewards
app.get('/api/redeemed-rewards', authenticateToken, (req, res) => {
  try {
    // Get all redeemed rewards for the family
    const redeemedRewards = db.prepare(`
      SELECT rr.* FROM redeemedRewards rr
      INNER JOIN users u ON rr.userId = u.id
      WHERE u.familyId = ?
      ORDER BY rr.redeemedAt DESC
    `).all(req.user.familyId);

    res.json(redeemedRewards);
  } catch (error) {
    console.error('Get redeemed rewards error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Graceful shutdown
process.on('SIGINT', () => {
  db.close();
  process.exit();
});

process.on('SIGTERM', () => {
  db.close();
  process.exit();
});

// Start server
initDatabase();
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Using SQLite database: ${DB_FILE}`);
});
