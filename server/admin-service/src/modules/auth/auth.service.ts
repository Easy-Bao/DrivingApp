import { eq, sql } from 'drizzle-orm';
import { sign } from 'hono/jwt';
import { HTTPException } from 'hono/http-exception';
import { AdminExecutor, getAdminDatabase } from '../../config/database.ts';
import { loadAdminConfiguration } from '../../config/env.ts';
import { adminOwners } from '../../db/schema/index.ts';

const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_MILLISECONDS = 15 * 60 * 1_000;
const SESSION_SECONDS = 8 * 60 * 60;

export type AuthStore = {
  withOwnerLock<T>(
    email: string,
    operation: (executor: AdminExecutor) => Promise<T>,
  ): Promise<T>;
  findByEmail(email: string, executor?: AdminExecutor): Promise<
    typeof adminOwners.$inferSelect | null
  >;
  countOwners(executor?: AdminExecutor): Promise<number>;
  createOwner(
    input: { email: string; passwordHash: string },
    executor?: AdminExecutor,
  ): Promise<typeof adminOwners.$inferSelect | undefined>;
  recordFailedAttempt(
    ownerId: string,
    failedAttempts: number,
    lockedUntil: Date | null,
    executor?: AdminExecutor,
  ): Promise<void>;
  clearLoginLock(ownerId: string, executor?: AdminExecutor): Promise<void>;
  rotatePassword(
    ownerId: string,
    passwordHash: string,
    executor?: AdminExecutor,
  ): Promise<void>;
};

export const postgresAuthStore: AuthStore = {
  async withOwnerLock<T>(email: string, operation: (executor: AdminExecutor) => Promise<T>) {
    return await getAdminDatabase().transaction(async (transaction) => {
      await transaction.execute(
        sql`select pg_advisory_xact_lock(hashtext(${`admin-owner:${email}`}))`,
      );
      return await operation(transaction);
    });
  },

  async findByEmail(email, executor = getAdminDatabase()) {
    const [owner] = await executor.select()
      .from(adminOwners)
      .where(eq(adminOwners.email, email))
      .limit(1);
    return owner ?? null;
  },

  async countOwners(executor = getAdminDatabase()) {
    const [row] = await executor.select({ count: sql<number>`count(*)::int` })
      .from(adminOwners);
    return row?.count ?? 0;
  },

  async createOwner(input, executor = getAdminDatabase()) {
    const [owner] = await executor.insert(adminOwners).values(input).returning();
    return owner;
  },

  async recordFailedAttempt(
    ownerId,
    failedAttempts,
    lockedUntil,
    executor = getAdminDatabase(),
  ) {
    await executor.update(adminOwners)
      .set({ failedAttempts, lockedUntil, updatedAt: new Date() })
      .where(eq(adminOwners.id, ownerId));
  },

  async clearLoginLock(ownerId, executor = getAdminDatabase()) {
    await executor.update(adminOwners)
      .set({ failedAttempts: 0, lockedUntil: null, updatedAt: new Date() })
      .where(eq(adminOwners.id, ownerId));
  },

  async rotatePassword(ownerId, passwordHash, executor = getAdminDatabase()) {
    await executor.update(adminOwners)
      .set({
        passwordHash,
        failedAttempts: 0,
        lockedUntil: null,
        updatedAt: new Date(),
      })
      .where(eq(adminOwners.id, ownerId));
  },
};

export class AuthService {
  constructor(
    private readonly store: AuthStore = postgresAuthStore,
    private readonly signingSecret?: string,
  ) {}

  /** Authenticates the single owner with a serialized five-attempt lockout. */
  async login(email: string, password: string): Promise<{ accessToken: string }> {
    const normalizedEmail = email.trim().toLowerCase();
    const owner = await this.store.withOwnerLock(normalizedEmail, async (executor) => {
      const record = await this.store.findByEmail(normalizedEmail, executor);
      if (!record) return null;

      const now = new Date();
      if (record.lockedUntil && record.lockedUntil > now) {
        throw new HTTPException(429, { message: 'ADMIN_LOGIN_LOCKED' });
      }

      if (!await Bun.password.verify(password, record.passwordHash)) {
        const failedAttempts = record.failedAttempts + 1;
        const shouldLock = failedAttempts >= MAX_FAILED_ATTEMPTS;
        await this.store.recordFailedAttempt(
          record.id,
          shouldLock ? 0 : failedAttempts,
          shouldLock ? new Date(now.getTime() + LOCKOUT_MILLISECONDS) : null,
          executor,
        );
        return null;
      }

      await this.store.clearLoginLock(record.id, executor);
      return record;
    });

    if (!owner) {
      throw new HTTPException(401, { message: 'INVALID_ADMIN_CREDENTIALS' });
    }

    const now = Math.floor(Date.now() / 1_000);
    const accessToken = await sign({
      sub: owner.id,
      email: owner.email,
      role: 'admin',
      iat: now,
      exp: now + SESSION_SECONDS,
    }, this.signingSecret ?? loadAdminConfiguration().ADMIN_JWT_SECRET, 'HS256');

    return { accessToken };
  }

  /** Creates the first owner or rotates that same owner's password. */
  async provisionOwner(
    email: string,
    passwordHash: string,
  ): Promise<'created' | 'rotated'> {
    const normalizedEmail = email.trim().toLowerCase();
    return await this.store.withOwnerLock('single-owner-provisioning', async (executor) => {
      const existing = await this.store.findByEmail(normalizedEmail, executor);
      if (existing) {
        await this.store.rotatePassword(existing.id, passwordHash, executor);
        return 'rotated';
      }

      if (await this.store.countOwners(executor) > 0) {
        throw new Error('An owner already exists. Use the existing owner email to rotate it.');
      }

      await this.store.createOwner({ email: normalizedEmail, passwordHash }, executor);
      return 'created';
    });
  }
}
