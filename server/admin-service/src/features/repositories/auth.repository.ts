import { eq, sql } from 'drizzle-orm';
import { adminOwners } from '../../db/schema.ts';
import { db } from '../../shared/drizzle.ts';

type AuthExecutor = Pick<typeof db, 'select' | 'insert' | 'update'>;

export class AuthRepository {
  /** Serializes owner login and provisioning changes for one normalized email. */
  async withOwnerLock<T>(
    email: string,
    operation: (executor: AuthExecutor) => Promise<T>,
  ): Promise<T> {
    return await db.transaction(async (transaction) => {
      await transaction.execute(
        sql`select pg_advisory_xact_lock(hashtext(${`admin-owner:${email}`}))`,
      );
      return await operation(transaction);
    });
  }

  async findByEmail(email: string, executor: AuthExecutor = db) {
    const [owner] = await executor.select()
      .from(adminOwners)
      .where(eq(adminOwners.email, email))
      .limit(1);
    return owner ?? null;
  }

  async countOwners(executor: AuthExecutor = db): Promise<number> {
    const [row] = await executor.select({ count: sql<number>`count(*)::int` })
      .from(adminOwners);
    return row?.count ?? 0;
  }

  async createOwner(
    input: { email: string; passwordHash: string },
    executor: AuthExecutor = db,
  ) {
    const [owner] = await executor.insert(adminOwners).values(input).returning();
    return owner;
  }

  async recordFailedAttempt(
    ownerId: string,
    failedAttempts: number,
    lockedUntil: Date | null,
    executor: AuthExecutor = db,
  ) {
    await executor.update(adminOwners)
      .set({ failedAttempts, lockedUntil, updatedAt: new Date() })
      .where(eq(adminOwners.id, ownerId));
  }

  async clearLoginLock(ownerId: string, executor: AuthExecutor = db) {
    await executor.update(adminOwners)
      .set({ failedAttempts: 0, lockedUntil: null, updatedAt: new Date() })
      .where(eq(adminOwners.id, ownerId));
  }

  async rotatePassword(
    ownerId: string,
    passwordHash: string,
    executor: AuthExecutor = db,
  ) {
    await executor.update(adminOwners)
      .set({
        passwordHash,
        failedAttempts: 0,
        lockedUntil: null,
        updatedAt: new Date(),
      })
      .where(eq(adminOwners.id, ownerId));
  }
}
