import { AuthService as _Auth } from '../auth.js';
import { AuthStore as _AS, JsonStore as _JS } from '../store.js';
import { LobbyService as _Lobby } from '../services.js';
import path from 'path';


async function demo() {
const DATA = new _JS(path.resolve('data/data.json'));
const AUTH = new _AS(path.resolve('data/auth.json'));
const auth = new _Auth(AUTH, DATA);
const lobby = new _Lobby(DATA);


// Login
const parent = await auth.authenticate('alice_parent', 'Password123!');
const child = await auth.authenticate('bobby_child', 'Password123!');


// Assign + complete + approve + redeem
const chores = await lobby.getOpenChores();
const toAssign = chores[0];
if (toAssign) {
await lobby.assignChore(parent, toAssign.id, child.id);
await lobby.completeChore(child, toAssign.id);
await lobby.approveChore(parent, toAssign.id);
}


const rewards = await lobby.getRewards();
const firstReward = rewards[0];
if (firstReward) {
const res = await lobby.redeemReward(child, firstReward.id);
console.log('Redeemed reward:', res.reward.title, 'Remaining points:', res.child.points);
}


console.log('Demo complete.');
}


demo().catch(e => { console.error(e); process.exit(1); });