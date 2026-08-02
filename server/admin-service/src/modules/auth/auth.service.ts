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

  /**
   * Owner login lifecycle: normalizes the submitted email, serializes attempts
   * for that identity with a PostgreSQL advisory transaction lock, and loads the
   * single Admin record before performing the Argon2id password check.
   *
   * A failed password increments the persisted counter; the fifth failure resets
   * that counter and stores a fifteen-minute lock timestamp. Because lookup and
   * counter update occur under the same lock, concurrent requests cannot race
   * past the threshold. A successful password clears prior failures and only
   * then signs an eight-hour JWT with the Admin-only secret.
   *
   * The input contract is normalized `email` plus plaintext `password`; the
   * password is never stored or returned. The output contains only
   * `{ accessToken }`, which the SvelteKit server places in an HttpOnly cookie.
   */
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

  /**
   * Owner provisioning lifecycle: gives an interactive setup command one safe
   * path for initial creation and later password rotation without introducing a
   * public registration endpoint or a staff-role model.
   *
   * Provisioning first normalizes the email and acquires one global advisory
   * lock. If that owner exists, the supplied Argon2id hash replaces the previous
   * hash and clears the login lock; otherwise the service counts owners and
   * refuses creation when any different owner already exists. Concurrent setup
   * commands therefore cannot create a second account between count and insert.
   *
   * The service receives an email and an already-produced password hash, then
   * returns either `created` or `rotated`; it never receives or records the
   * interactive plaintext password.
   */
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
