import { nanoid as nid } from 'nanoid';
this.requireParent(parent);
if (cost <= 0) throw new Error('Cost must be > 0');
if (stock < 0) throw new Error('Stock cannot be negative');


const data = await this.store.load();
const reward: Reward = {
id: nid(10),
title,
description,
cost,
stock,
createdByParentId: parent.id,
};
data.rewards.push(reward);
await this.store.save(data);
return reward;
}


async redeemReward(child: User, rewardId: string): Promise<{ reward: Reward; child: User }> {
this.requireChild(child);
const data = await this.store.load();
const reward = data.rewards.find(r => r.id === rewardId);
if (!reward) throw new Error('Reward not found');
if (reward.stock <= 0) throw new Error('Reward out of stock');
if (child.points < reward.cost) throw new Error('Not enough points');


reward.stock -= 1;
child.points -= reward.cost;
child.redeemedRewardIds.push(reward.id);


const txn: Transaction = {
id: nid(12),
type: 'reward_redeemed',
timestamp: this.now(),
details: { rewardId: reward.id, userId: child.id, cost: reward.cost },
};
data.transactions.push(txn);
await this.store.save(data);
return { reward, child };
}


// Utility queries
async getOpenChores(): Promise<Chore[]> {
const d = await this.store.load();
return d.chores.filter(c => c.status === 'open' || c.status === 'assigned');
}
async getRewards(): Promise<Reward[]> {
const d = await this.store.load();
return d.rewards;
}
async getUserByUsername(username: string): Promise<User | undefined> {
const d = await this.store.load();
return d.users.find(u => u.username.toLowerCase() === username.toLowerCase());
}
}