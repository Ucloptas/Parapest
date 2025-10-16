import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import axios from 'axios';
import './Dashboard.css';

function ParentDashboard() {
  const { user, logout, token } = useAuth();
  const [chores, setChores] = useState([]);
  const [rewards, setRewards] = useState([]);
  const [familyMembers, setFamilyMembers] = useState([]);
  const [completedChores, setCompletedChores] = useState([]);
  const [redeemedRewards, setRedeemedRewards] = useState([]);
  const [activeTab, setActiveTab] = useState('chores');
  const [showChoreModal, setShowChoreModal] = useState(false);
  const [showRewardModal, setShowRewardModal] = useState(false);
  const [editingChore, setEditingChore] = useState(null);
  const [editingReward, setEditingReward] = useState(null);
  const [loading, setLoading] = useState(true);

  const [choreForm, setChoreForm] = useState({ title: '', description: '', points: '' });
  const [rewardForm, setRewardForm] = useState({ title: '', description: '', cost: '' });

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const [choresRes, rewardsRes, familyRes, completedRes, redeemedRes] = await Promise.all([
        axios.get('/api/chores', { headers: { Authorization: `Bearer ${token}` } }),
        axios.get('/api/rewards', { headers: { Authorization: `Bearer ${token}` } }),
        axios.get('/api/family', { headers: { Authorization: `Bearer ${token}` } }),
        axios.get('/api/completed-chores', { headers: { Authorization: `Bearer ${token}` } }),
        axios.get('/api/redeemed-rewards', { headers: { Authorization: `Bearer ${token}` } })
      ]);
      setChores(choresRes.data);
      setRewards(rewardsRes.data);
      setFamilyMembers(familyRes.data);
      setCompletedChores(completedRes.data);
      setRedeemedRewards(redeemedRes.data);
    } catch (error) {
      console.error('Failed to fetch data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAddChore = () => {
    setEditingChore(null);
    setChoreForm({ title: '', description: '', points: '' });
    setShowChoreModal(true);
  };

  const handleEditChore = (chore) => {
    setEditingChore(chore);
    setChoreForm({ title: chore.title, description: chore.description, points: chore.points });
    setShowChoreModal(true);
  };

  const handleSaveChore = async (e) => {
    e.preventDefault();
    try {
      if (editingChore) {
        await axios.put(`/api/chores/${editingChore.id}`, choreForm, {
          headers: { Authorization: `Bearer ${token}` }
        });
      } else {
        await axios.post('/api/chores', choreForm, {
          headers: { Authorization: `Bearer ${token}` }
        });
      }
      setShowChoreModal(false);
      fetchData();
    } catch (error) {
      alert(error.response?.data?.error || 'Failed to save chore');
    }
  };

  const handleDeleteChore = async (choreId) => {
    if (!confirm('Are you sure you want to delete this chore?')) return;
    try {
      await axios.delete(`/api/chores/${choreId}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      fetchData();
    } catch (error) {
      alert(error.response?.data?.error || 'Failed to delete chore');
    }
  };

  const handleAddReward = () => {
    setEditingReward(null);
    setRewardForm({ title: '', description: '', cost: '' });
    setShowRewardModal(true);
  };

  const handleEditReward = (reward) => {
    setEditingReward(reward);
    setRewardForm({ title: reward.title, description: reward.description, cost: reward.cost });
    setShowRewardModal(true);
  };

  const handleSaveReward = async (e) => {
    e.preventDefault();
    try {
      if (editingReward) {
        await axios.put(`/api/rewards/${editingReward.id}`, rewardForm, {
          headers: { Authorization: `Bearer ${token}` }
        });
      } else {
        await axios.post('/api/rewards', rewardForm, {
          headers: { Authorization: `Bearer ${token}` }
        });
      }
      setShowRewardModal(false);
      fetchData();
    } catch (error) {
      alert(error.response?.data?.error || 'Failed to save reward');
    }
  };

  const handleDeleteReward = async (rewardId) => {
    if (!confirm('Are you sure you want to delete this reward?')) return;
    try {
      await axios.delete(`/api/rewards/${rewardId}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      fetchData();
    } catch (error) {
      alert(error.response?.data?.error || 'Failed to delete reward');
    }
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Loading...</p>
      </div>
    );
  }

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <div className="header-content">
          <h1>👨‍👩‍👧‍👦 Parent Dashboard</h1>
          <div className="header-info">
            <span className="user-name">Welcome, {user.username}!</span>
            <span className="family-id">Family ID: <strong>{user.familyId}</strong></span>
            <button onClick={logout} className="btn btn-secondary">Logout</button>
          </div>
        </div>
      </header>

      <div className="dashboard-content">
        <div className="tabs">
          <button
            className={`tab ${activeTab === 'chores' ? 'active' : ''}`}
            onClick={() => setActiveTab('chores')}
          >
            📋 Chores
          </button>
          <button
            className={`tab ${activeTab === 'rewards' ? 'active' : ''}`}
            onClick={() => setActiveTab('rewards')}
          >
            🎁 Rewards
          </button>
          <button
            className={`tab ${activeTab === 'family' ? 'active' : ''}`}
            onClick={() => setActiveTab('family')}
          >
            👨‍👩‍👧‍👦 Family
          </button>
          <button
            className={`tab ${activeTab === 'history' ? 'active' : ''}`}
            onClick={() => setActiveTab('history')}
          >
            📊 History
          </button>
        </div>

        {activeTab === 'chores' && (
          <div className="tab-content">
            <div className="content-header">
              <h2>Manage Chores</h2>
              <button onClick={handleAddChore} className="btn btn-success">+ Add Chore</button>
            </div>
            <div className="items-grid">
              {chores.length === 0 ? (
                <p className="empty-state">No chores yet. Add one to get started!</p>
              ) : (
                chores.map(chore => (
                  <div key={chore.id} className="item-card chore-card">
                    <h3>{chore.title}</h3>
                    {chore.description && <p className="description">{chore.description}</p>}
                    <div className="points">⭐ {chore.points} points</div>
                    <div className="card-actions">
                      <button onClick={() => handleEditChore(chore)} className="btn btn-primary">Edit</button>
                      <button onClick={() => handleDeleteChore(chore.id)} className="btn btn-danger">Delete</button>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}

        {activeTab === 'rewards' && (
          <div className="tab-content">
            <div className="content-header">
              <h2>Manage Rewards</h2>
              <button onClick={handleAddReward} className="btn btn-success">+ Add Reward</button>
            </div>
            <div className="items-grid">
              {rewards.length === 0 ? (
                <p className="empty-state">No rewards yet. Add one to get started!</p>
              ) : (
                rewards.map(reward => (
                  <div key={reward.id} className="item-card reward-card">
                    <h3>{reward.title}</h3>
                    {reward.description && <p className="description">{reward.description}</p>}
                    <div className="cost">💎 {reward.cost} points</div>
                    <div className="card-actions">
                      <button onClick={() => handleEditReward(reward)} className="btn btn-primary">Edit</button>
                      <button onClick={() => handleDeleteReward(reward.id)} className="btn btn-danger">Delete</button>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}

        {activeTab === 'family' && (
          <div className="tab-content">
            <div className="content-header">
              <h2>Family Members</h2>
            </div>
            <div className="family-list">
              {familyMembers.map(member => (
                <div key={member.id} className="family-member-card">
                  <div className="member-info">
                    <span className="member-icon">{member.role === 'parent' ? '👨‍👩‍👧‍👦' : '👶'}</span>
                    <div>
                      <h3>{member.username}</h3>
                      <span className="member-role">{member.role}</span>
                    </div>
                  </div>
                  <div className="member-points">
                    ⭐ {member.points} points
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {activeTab === 'history' && (
          <div className="tab-content">
            <div className="content-header">
              <h2>Activity History</h2>
            </div>
            
            <h3 className="section-title">✅ Completed Chores</h3>
            <div className="history-list">
              {completedChores.length === 0 ? (
                <p className="empty-state">No completed chores yet.</p>
              ) : (
                completedChores.map(item => (
                  <div key={item.id} className="history-item">
                    <div>
                      <strong>{item.username}</strong> completed <strong>{item.choreTitle}</strong>
                      <div className="history-date">{new Date(item.completedAt).toLocaleString()}</div>
                    </div>
                    <div className="history-points positive">+{item.points} points</div>
                  </div>
                ))
              )}
            </div>

            <h3 className="section-title">🎁 Redeemed Rewards</h3>
            <div className="history-list">
              {redeemedRewards.length === 0 ? (
                <p className="empty-state">No redeemed rewards yet.</p>
              ) : (
                redeemedRewards.map(item => (
                  <div key={item.id} className="history-item">
                    <div>
                      <strong>{item.username}</strong> redeemed <strong>{item.rewardTitle}</strong>
                      <div className="history-date">{new Date(item.redeemedAt).toLocaleString()}</div>
                    </div>
                    <div className="history-points negative">-{item.cost} points</div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}
      </div>

      {showChoreModal && (
        <div className="modal-overlay" onClick={() => setShowChoreModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>{editingChore ? 'Edit Chore' : 'Add New Chore'}</h2>
              <button className="close-btn" onClick={() => setShowChoreModal(false)}>&times;</button>
            </div>
            <form onSubmit={handleSaveChore}>
              <div className="form-group">
                <label>Chore Title *</label>
                <input
                  type="text"
                  value={choreForm.title}
                  onChange={(e) => setChoreForm({ ...choreForm, title: e.target.value })}
                  required
                  placeholder="e.g., Clean your room"
                />
              </div>
              <div className="form-group">
                <label>Description</label>
                <textarea
                  value={choreForm.description}
                  onChange={(e) => setChoreForm({ ...choreForm, description: e.target.value })}
                  placeholder="Optional: Add details about the chore"
                />
              </div>
              <div className="form-group">
                <label>Points Reward *</label>
                <input
                  type="number"
                  value={choreForm.points}
                  onChange={(e) => setChoreForm({ ...choreForm, points: e.target.value })}
                  required
                  min="1"
                  placeholder="e.g., 10"
                />
              </div>
              <div className="modal-actions">
                <button type="button" onClick={() => setShowChoreModal(false)} className="btn btn-secondary">Cancel</button>
                <button type="submit" className="btn btn-success">Save Chore</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {showRewardModal && (
        <div className="modal-overlay" onClick={() => setShowRewardModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>{editingReward ? 'Edit Reward' : 'Add New Reward'}</h2>
              <button className="close-btn" onClick={() => setShowRewardModal(false)}>&times;</button>
            </div>
            <form onSubmit={handleSaveReward}>
              <div className="form-group">
                <label>Reward Title *</label>
                <input
                  type="text"
                  value={rewardForm.title}
                  onChange={(e) => setRewardForm({ ...rewardForm, title: e.target.value })}
                  required
                  placeholder="e.g., Extra screen time"
                />
              </div>
              <div className="form-group">
                <label>Description</label>
                <textarea
                  value={rewardForm.description}
                  onChange={(e) => setRewardForm({ ...rewardForm, description: e.target.value })}
                  placeholder="Optional: Add details about the reward"
                />
              </div>
              <div className="form-group">
                <label>Points Cost *</label>
                <input
                  type="number"
                  value={rewardForm.cost}
                  onChange={(e) => setRewardForm({ ...rewardForm, cost: e.target.value })}
                  required
                  min="1"
                  placeholder="e.g., 50"
                />
              </div>
              <div className="modal-actions">
                <button type="button" onClick={() => setShowRewardModal(false)} className="btn btn-secondary">Cancel</button>
                <button type="submit" className="btn btn-success">Save Reward</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default ParentDashboard;

