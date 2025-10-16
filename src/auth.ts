import bcrypt from 'bcryptjs';
import { nanoid as _nid } from 'nanoid';
import type { AuthFile, AuthRecord, Role, User } from './models.js';
import { AuthStore, JsonStore } from './store.js';


export class AuthService {
constructor(private authStore: AuthStore, private dataStore: JsonStore) {}


async register(username: string, password: string, role: Role): Promise<User> {
const auth = await this.authStore.load();
if (auth.users.find(u => u.username.toLowerCase() === username.toLowerCase())) {
throw new Error('Username already exists');
}


const hash = await bcrypt.hash(password, 10);
const userId = _nid(12);


const rec: AuthRecord = { userId, username, passwordHash: hash };
auth.users.push(rec);
await this.authStore.save(auth);


const data = await this.dataStore.load();
const user: User = {
id: userId,
username,
role,
points: 0,
assignedChoreIds: [],
completedChoreIds: [],
redeemedRewardIds: [],
};
data.users.push(user);
await this.dataStore.save(data);
return user;
}


async authenticate(username: string, password: string): Promise<User> {
const auth = await this.authStore.load();
const rec = auth.users.find(u => u.username.toLowerCase() === username.toLowerCase());
if (!rec) throw new Error('Invalid credentials');
const ok = await bcrypt.compare(password, rec.passwordHash);
if (!ok) throw new Error('Invalid credentials');


const data = await this.dataStore.load();
const user = data.users.find(u => u.id === rec.userId);
if (!user) throw new Error('User profile missing');
return user;
}
}