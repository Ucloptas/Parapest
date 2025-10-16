import { AuthService } from '../auth.js';
import { AuthStore, JsonStore } from '../store.js';
import { LobbyService } from '../services.js';
import path from 'path';


async function run() {
const DATA = new JsonStore(path.resolve('data/data.json'));
const AUTH = new AuthStore(path.resolve('data/auth.json'));
const auth = new AuthService(AUTH, DATA);
const lobby = new LobbyService(DATA);


// Create accounts
const parent = await auth.register('alice_parent', 'Password123!', 'parent');
const child = await auth.register('bobby_child', 'Password123!', 'child');


// Seed chores & rewards
await lobby.addChore(parent, 'Clean your room', 10, 'Pick up toys and make the bed');
await lobby.addChore(parent, 'Do homework', 15);
await lobby.addReward(parent, 'Ice cream trip', 25, 5);
await lobby.addReward(parent, 'Extra screen time (30m)', 20, 100);


console.log('Seed complete. Users:', { parent, child });
}


run().catch(err => {
console.error(err);
process.exit(1);
});