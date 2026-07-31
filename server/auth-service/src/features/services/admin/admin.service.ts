import { JsonWebTokenService } from '../common/jwt.service.ts';
import type {
  AdminAccountRepository,
  AdminAccountRecord,
} from '../../repositories/admin/admin.repository.ts';
import type { LoginAdminInput } from '../../schemas/admin/admin.zod.ts';

const MAX_FAILED_LOGIN_ATTEMPTS = 5;
const LOGIN_LOCK_SECONDS = 15 * 60;

export interface AdminSessionResult {
  token: string;
  expiresAt: string;
  user: {
    id: string;
    email: string;
    name: string;
    role: 'admin';
  };
}

export class AdminAuthenticationError extends Error {
  constructor(
    public readonly code: 'INVALID_ADMIN_CREDENTIALS' | 'ADMIN_LOGIN_LOCKED',
    public readonly status: 401 | 429,
    message: string,
  ) {
    super(message);
  }
}

export class AdminAuthenticationService {
  constructor(private readonly repository: AdminAccountRepository) {}

  /**
   * Authenticates the private owner and applies a persistent five-attempt lock.
   */
  async authenticateOwner(loginInput: LoginAdminInput): Promise<AdminSessionResult> {
    const normalizedEmail = loginInput.email.toLowerCase().trim();
    const owner = await this.repository.findOwnerByEmail(normalizedEmail);

    if (!owner) {
      throw new AdminAuthenticationError(
        'INVALID_ADMIN_CREDENTIALS',
        401,
        'Invalid email or password',
      );
    }

    this.assertOwnerIsNotLocked(owner);

    if (!await Bun.password.verify(loginInput.password, owner.passwordHash)) {
      const failure = await this.repository.recordFailedLogin(
        owner.id,
        MAX_FAILED_LOGIN_ATTEMPTS,
        LOGIN_LOCK_SECONDS,
      );

      if (failure.lockedUntil) {
        throw new AdminAuthenticationError(
          'ADMIN_LOGIN_LOCKED',
          429,
          'Too many failed login attempts. Try again in 15 minutes.',
        );
      }

      throw new AdminAuthenticationError(
        'INVALID_ADMIN_CREDENTIALS',
        401,
        'Invalid email or password',
      );
    }

    if (owner.failedLoginAttempts > 0 || owner.lockedUntil) {
      await this.repository.clearFailedLogins(owner.id);
    }

    return {
      token: JsonWebTokenService.generateAdminJsonWebToken(owner.id, owner.email),
      expiresAt: new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString(),
      user: {
        id: owner.id,
        email: owner.email,
        name: 'Owner',
        role: 'admin',
      },
    };
  }

  private assertOwnerIsNotLocked(owner: AdminAccountRecord): void {
    if (owner.lockedUntil && owner.lockedUntil.getTime() > Date.now()) {
      throw new AdminAuthenticationError(
        'ADMIN_LOGIN_LOCKED',
        429,
        'Too many failed login attempts. Try again later.',
      );
    }
  }
}
