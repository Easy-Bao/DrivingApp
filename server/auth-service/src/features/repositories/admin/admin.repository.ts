import { eq, sql } from 'drizzle-orm';
import { adminAuthAccounts } from '../../../db/schemas/admin_accounts.schema.ts';
import { authDb } from '../../../shared/admin.drizzle.ts';

export interface AdminAccountRecord {
  id: string;
  email: string;
  passwordHash: string;
  failedLoginAttempts: number;
  lockedUntil: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface AdminAccountRepository {
  findOwnerByEmail(email: string): Promise<AdminAccountRecord | undefined>;
  recordFailedLogin(
    id: string,
    maximumAttempts: number,
    lockSeconds: number,
  ): Promise<{ attempts: number; lockedUntil: Date | null }>;
  clearFailedLogins(id: string): Promise<void>;
}

export interface AdminOwnerProvisioningRepository {
  createOwnerIfAbsent(email: string, passwordHash: string): Promise<boolean>;
  findOwner(): Promise<AdminAccountRecord | undefined>;
  rotateOwnerPassword(id: string, passwordHash: string): Promise<void>;
}

export class DrizzleAdminAccountRepository
  implements AdminAccountRepository, AdminOwnerProvisioningRepository {
  async findOwnerByEmail(email: string): Promise<AdminAccountRecord | undefined> {
    const [owner] = await authDb.select()
      .from(adminAuthAccounts)
      .where(eq(adminAuthAccounts.email, email))
      .limit(1);
    return owner;
  }

  async recordFailedLogin(
    id: string,
    maximumAttempts: number,
    lockSeconds: number,
  ): Promise<{ attempts: number; lockedUntil: Date | null }> {
    const nextAttempts = sql<number>`
      CASE
        WHEN ${adminAuthAccounts.lockedUntil} IS NOT NULL
          AND ${adminAuthAccounts.lockedUntil} <= NOW()
          THEN 1
        ELSE ${adminAuthAccounts.failedLoginAttempts} + 1
      END
    `;
    const [updated] = await authDb.update(adminAuthAccounts)
      .set({
        failedLoginAttempts: nextAttempts,
        lockedUntil: sql<Date | null>`
          CASE
            WHEN ${nextAttempts} >= ${maximumAttempts}
              THEN NOW() + (${lockSeconds} * INTERVAL '1 second')
            ELSE NULL
          END
        `,
        updatedAt: new Date(),
      })
      .where(eq(adminAuthAccounts.id, id))
      .returning({
        attempts: adminAuthAccounts.failedLoginAttempts,
        lockedUntil: adminAuthAccounts.lockedUntil,
      });

    if (!updated) {
      throw new Error('Owner account no longer exists.');
    }
    return updated;
  }

  async clearFailedLogins(id: string): Promise<void> {
    await authDb.update(adminAuthAccounts)
      .set({
        failedLoginAttempts: 0,
        lockedUntil: null,
        updatedAt: new Date(),
      })
      .where(eq(adminAuthAccounts.id, id));
  }

  async createOwnerIfAbsent(email: string, passwordHash: string): Promise<boolean> {
    const [created] = await authDb.insert(adminAuthAccounts)
      .values({
        singletonKey: true,
        id: `adm_${crypto.randomUUID()}`,
        email,
        passwordHash,
      })
      .onConflictDoNothing()
      .returning();

    return Boolean(created);
  }

  async findOwner(): Promise<AdminAccountRecord | undefined> {
    const [owner] = await authDb.select()
      .from(adminAuthAccounts)
      .limit(1);
    return owner;
  }

  async rotateOwnerPassword(id: string, passwordHash: string): Promise<void> {
    const [updated] = await authDb.update(adminAuthAccounts)
      .set({
        passwordHash,
        failedLoginAttempts: 0,
        lockedUntil: null,
        updatedAt: new Date(),
      })
      .where(eq(adminAuthAccounts.id, id))
      .returning({ id: adminAuthAccounts.id });

    if (!updated) {
      throw new Error('Owner account no longer exists.');
    }
  }
}
