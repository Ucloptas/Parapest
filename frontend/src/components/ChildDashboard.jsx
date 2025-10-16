import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import axios from 'axios';
import './Dashboard.css';

function ChildDashboard() {
  const { user, logout, token, updateUserPoints } = useAuth();
  const [chores, setChores] = useState([]);
  const [rewards, setRewards] = useState([]);
  const [activeTab, setActiveTab] = useState('chores');
  const [loading, setLoading] = useState(true);
  const [actionMessage, setActionMessage] = useState('');

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const [choresRes, rewardsRes, userRes] = await Promise.all([
        axios.get('/api/chores', { headers: { Authorization: `Bearer ${token}` } }),
        axios.get('/api/rewards', { headers: { Authorization: `Bearer ${token}` } }),
        axios.get('/api/user', { headers: { Authorization: `Bearer ${token}` } })
      ]);
      setChores(choresRes.data);
      setRewards(rewardsRes.data);
      updateUserPoints(userRes.data.points);
    } catch (error) {
      console.error('Failed to fetch data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCompleteChore = async (choreId, choreTitle) => {
    if (!confirm(`Are you sure you completed "${choreTitle}"?`)) return;
    
    try {
      const response = await axios.post(`/api/chores/${choreId}/complete`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      });
      updateUserPoints(response.data.totalPoints);
      setActionMessage(`🎉 Great job! You earned ${response.data.points} points!`);
      setTimeout(() => setActionMessage(''), 5000);
    } catch (error) {
      alert(error.response?.data?.error || 'Failed to complete chore');
    }
  };

  const handleRedeemReward = async (rewardId, rewardTitle, cost) => {
    if (user.points < cost) {
      alert(`You need ${cost - user.points} more points to redeem this reward!`);
      return;
    }

    if (!confirm(`Redeem "${rewardTitle}" for ${cost} points?`)) return;
    
    try {
      const response = await axios.post(`/api/rewards/${rewardId}/redeem`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      });
      updateUserPoints(response.data.remainingPoints);
      setActionMessage(`🎁 Awesome! You redeemed "${rewardTitle}"! Ask your parent to give it to you!`);
      setTimeout(() => setActionMessage(''), 5000);
    } catch (error) {
      alert(error.response?.data?.error || 'Failed to redeem reward');
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
    <div className="dashboard child-dashboard">
      <header className="dashboard-header">
        <div className="header-content">
          <h1>👶 My Chores & Rewards</h1>
          <div className="header-info">
            <span className="user-name">Hi, {user.username}! 👋</span>
            <div className="points-display">
              <span className="points-label">Your Points:</span>
              <span className="points-value">⭐ {user.points}</span>
            </div>
            <button onClick={logout} className="btn btn-secondary">Logout</button>
          </div>
        </div>
      </header>

      {actionMessage && (
        <div className="action-message">
          {actionMessage}
        </div>
      )}

      <div className="dashboard-content">
        <div className="tabs">
          <button
            className={`tab ${activeTab === 'chores' ? 'active' : ''}`}
            onClick={() => setActiveTab('chores')}
          >
            📋 Available Chores
          </button>
          <button
            className={`tab ${activeTab === 'rewards' ? 'active' : ''}`}
            onClick={() => setActiveTab('rewards')}
          >
            🎁 Rewards Shop
          </button>
        </div>

        {activeTab === 'chores' && (
          <div className="tab-content">
            <div className="content-header">
              <h2>Chores You Can Do</h2>
              <p className="tab-description">Complete chores to earn points! 🌟</p>
            </div>
            <div className="items-grid">
              {chores.length === 0 ? (
                <div className="empty-state-large">
                  <div className="empty-icon">📋</div>
                  <p>No chores available right now.</p>
                  <p className="empty-subtitle">Ask your parent to add some chores!</p>
                </div>
              ) : (
                chores.map(chore => (
                  <div key={chore.id} className="item-card chore-card child-card">
                    <h3>{chore.title}</h3>
                    {chore.description && <p className="description">{chore.description}</p>}
                    <div className="points-badge">⭐ Earn {chore.points} points</div>
                    <button 
                      onClick={() => handleCompleteChore(chore.id, chore.title)} 
                      className="btn btn-success btn-block"
                    >
                      ✅ I Completed This!
                    </button>
                  </div>
                ))
              )}
            </div>
          </div>
        )}

        {activeTab === 'rewards' && (
          <div className="tab-content">
            <div className="content-header">
              <h2>Rewards You Can Get</h2>
              <p className="tab-description">Spend your points on awesome rewards! 🎁</p>
            </div>
            <div className="items-grid">
              {rewards.length === 0 ? (
                <div className="empty-state-large">
                  <div className="empty-icon">🎁</div>
                  <p>No rewards available yet.</p>
                  <p className="empty-subtitle">Ask your parent to add some rewards!</p>
                </div>
              ) : (
                rewards.map(reward => {
                  const canAfford = user.points >= reward.cost;
                  return (
                    <div key={reward.id} className={`item-card reward-card child-card ${!canAfford ? 'disabled' : ''}`}>
                      <h3>{reward.title}</h3>
                      {reward.description && <p className="description">{reward.description}</p>}
                      <div className="cost-badge">💎 Costs {reward.cost} points</div>
                      {!canAfford && (
                        <div className="insufficient-points">
                          Need {reward.cost - user.points} more points
                        </div>
                      )}
                      <button 
                        onClick={() => handleRedeemReward(reward.id, reward.title, reward.cost)} 
                        className="btn btn-warning btn-block"
                        disabled={!canAfford}
                      >
                        {canAfford ? '🎁 Redeem Now!' : '🔒 Not Enough Points'}
                      </button>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default ChildDashboard;

