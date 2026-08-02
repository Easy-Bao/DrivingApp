import { sign } from 'hono/jwt';
import { HTTPException } from 'hono/http-exception';
import { loadAdminConfiguration } from '../../config.ts';
import { AuthRepository } from '../repositories/auth.repository.ts';

const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_MILLISECONDS = 15 * 60 * 1_000;
const SESSION_SECONDS = 8 * 60 * 60;

export class AuthService {
  constructor(private readonly repository: AuthRepository) {}

  /**
   * Authenticates the single owner inside the Admin service boundary. Failed
   * attempts are serialized before the counter changes, preventing concurrent
   * requests from bypassing the five-attempt lockout.
   */
  async login(email: string, password: string): Promise<{ accessToken: string }> {
    const normalizedEmail = email.trim().toLowerCase();
    const owner = await this.repository.withOwnerLock(normalizedEmail, async (executor) => {
      const record = await this.repository.findByEmail(normalizedEmail, executor);
      if (!record) {
        return null;
      }

      const now = new Date();
      if (record.lockedUntil && record.lockedUntil > now) {
        throw new HTTPException(429, { message: 'ADMIN_LOGIN_LOCKED' });
      }

      const passwordMatches = await Bun.password.verify(password, record.passwordHash);
      if (!passwordMatches) {
        const failedAttempts = record.failedAttempts + 1;
        const lockedUntil = failedAttempts >= MAX_FAILED_ATTEMPTS
          ? new Date(now.getTime() + LOCKOUT_MILLISECONDS)
          : null;
        await this.repository.recordFailedAttempt(
          record.id,
          failedAttempts >= MAX_FAILED_ATTEMPTS ? 0 : failedAttempts,
          lockedUntil,
          executor,
        );
        return null;
      }

      await this.repository.clearLoginLock(record.id, executor);
      return record;
    });

    if (!owner) {
      throw new HTTPException(401, { message: 'INVALID_ADMIN_CREDENTIALS' });
    }

    const now = Math.floor(Date.now() / 1_000);
    const { ADMIN_JWT_SECRET } = loadAdminConfiguration();
    const accessToken = await sign({
      sub: owner.id,
      email: owner.email,
      role: 'admin',
      iat: now,
      exp: now + SESSION_SECONDS,
    }, ADMIN_JWT_SECRET, 'HS256');

    return { accessToken };
  }

  /**
   * Creates the first owner or rotates that same owner's password. A different
   * second owner is refused so the MVP cannot silently grow a staff-role model.
   */
  async provisionOwner(
    email: string,
    passwordHash: string,
  ): Promise<'created' | 'rotated'> {
    const normalizedEmail = email.trim().toLowerCase();
    return await this.repository.withOwnerLock('single-owner-provisioning', async (executor) => {
      const existing = await this.repository.findByEmail(normalizedEmail, executor);
      if (existing) {
        await this.repository.rotatePassword(existing.id, passwordHash, executor);
        return 'rotated';
      }

      if (await this.repository.countOwners(executor) > 0) {
        throw new Error('An owner already exists. Use the existing owner email to rotate it.');
      }

      await this.repository.createOwner({ email: normalizedEmail, passwordHash }, executor);
      return 'created';
    });
  }
}
