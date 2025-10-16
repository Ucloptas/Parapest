export type Role = 'parent' | 'child';


export interface User {
id: string;
username: string; // unique
role: Role;
points: number;
assignedChoreIds: string[]; // chores currently assigned to this child
completedChoreIds: string[]; // chores the child has completed (awaiting approval or approved)
redeemedRewardIds: string[]; // rewards the child redeemed
}


export type ChoreStatus = 'open' | 'assigned' | 'completed' | 'approved';


export interface Chore {
id: string;
title: string;
description?: string;
points: number; // points to award upon approval
createdByParentId: string;
assignedToUserId?: string; // child id
status: ChoreStatus;
}


export interface Reward {
id: string;
title: string;
description?: string;
cost: number; // points required to redeem
stock: number; // remaining quantity
createdByParentId: string;
}


export type TxnType = 'chore_completed' | 'chore_approved' | 'reward_redeemed' | 'points_adjusted';


export interface Transaction {
id: string;
type: TxnType;
timestamp: string; // ISO
details: Record<string, unknown>;
}


export interface RootData {
users: User[];
chores: Chore[];
rewards: Reward[];
transactions: Transaction[];
}


export interface AuthRecord {
userId: string;
username: string;
passwordHash: string;
}


export interface AuthFile {
users: AuthRecord[];
}