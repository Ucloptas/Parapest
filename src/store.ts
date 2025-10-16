import { promises as fs } from 'fs';
import path from 'path';
import type { RootData, AuthFile } from './models.js';


const DEFAULT_DATA: RootData = {
users: [],
chores: [],
rewards: [],
transactions: [],
};


export class JsonStore {
constructor(private dataPath: string) {}


private async ensureFile(): Promise<void> {
try {
await fs.access(this.dataPath);
} catch {
await fs.mkdir(path.dirname(this.dataPath), { recursive: true });
await fs.writeFile(this.dataPath, JSON.stringify(DEFAULT_DATA, null, 2));
}
}


async load(): Promise<RootData> {
await this.ensureFile();
const raw = await fs.readFile(this.dataPath, 'utf8');
return JSON.parse(raw) as RootData;
}


// Atomic write: write to temp file, then rename.
async save(data: RootData): Promise<void> {
await this.ensureFile();
const tmpPath = this.dataPath + '.tmp-' + nanoid(6);
const payload = JSON.stringify(data, null, 2);
await fs.writeFile(tmpPath, payload, 'utf8');
await fs.rename(tmpPath, this.dataPath);
}
}


export class AuthStore {
constructor(private authPath: string) {}


private async ensureFile(): Promise<void> {
try {
await fs.access(this.authPath);
} catch {
await fs.mkdir(path.dirname(this.authPath), { recursive: true });
const empty: AuthFile = { users: [] };
await fs.writeFile(this.authPath, JSON.stringify(empty, null, 2));
}
}


async load(): Promise<AuthFile> {
await this.ensureFile();
const raw = await fs.readFile(this.authPath, 'utf8');
return JSON.parse(raw) as AuthFile;
}


async save(auth: AuthFile): Promise<void> {
await this.ensureFile();
const tmpPath = this.authPath + '.tmp-' + nanoid(6);
const payload = JSON.stringify(auth, null, 2);
await fs.writeFile(tmpPath, payload, 'utf8');
await fs.rename(tmpPath, this.authPath);
}
}