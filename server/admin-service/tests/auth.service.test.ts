import { describe, expect, test } from 'bun:test';

process.env.DATABASE_URL ??= 'postgresql://admin:password@localhost:5432/admin';
process.env.ADMIN_JWT_SECRET ??= 'admin-service-test-secret-value-32';

const { AuthService } = await import('../src/features/services/auth.service.ts');
const { AuthRepository } = await import('../src/features/repositories/auth.repository.ts');

type Owner = {
  id: string;
  email: string;
  passwordHash: string;
  failedAttempts: number;
  lockedUntil: Date | null;
};

class MemoryAuthRepository {
  owner: Owner | null = null;

  async withOwnerLock<T>(
    _email: string,
    operation: (executor: never) => Promise<T>,
  ): Promise<T> {
    return await operation({} as never);
  }

  async findByEmail(email: string) {
    return this.owner?.email === email ? this.owner : null;
  }

  async countOwners() {
    return this.owner ? 1 : 0;
  }

  async createOwner(input: { email: string; passwordHash: string }) {
    this.owner = {
      id: 'owner-1',
      ...input,
      failedAttempts: 0,
      lockedUntil: null,
    };
    return this.owner;
  }

  async rotatePassword(_ownerId: string, passwordHash: string) {
    if (!this.owner) return;
    this.owner.passwordHash = passwordHash;
    this.owner.failedAttempts = 0;
    this.owner.lockedUntil = null;
  }

  async recordFailedAttempt(
    _ownerId: string,
    failedAttempts: number,
    lockedUntil: Date | null,
  ) {
    if (!this.owner) return;
    this.owner.failedAttempts = failedAttempts;
    this.owner.lockedUntil = lockedUntil;
  }

  async clearLoginLock() {
    if (!this.owner) return;
    this.owner.failedAttempts = 0;
    this.owner.lockedUntil = null;
  }
}

function createService() {
  const repository = new MemoryAuthRepository();
  const service = new AuthService(repository as unknown as InstanceType<typeof AuthRepository>);
  return { repository, service };
}

describe('single Admin owner authentication', () => {
  test('creates one owner, rotates the same owner, and refuses a second email', async () => {
    const { service } = createService();
    const firstHash = await Bun.password.hash('a secure first passphrase', 'argon2id');
    const rotatedHash = await Bun.password.hash('a secure rotated passphrase', 'argon2id');

    await expect(service.provisionOwner('owner@example.test', firstHash))
      .resolves.toBe('created');
    await expect(service.provisionOwner('owner@example.test', rotatedHash))
      .resolves.toBe('rotated');
    await expect(service.provisionOwner('other@example.test', firstHash))
      .rejects.toThrow('An owner already exists');
  });

  test('locks login after five failed passwords', async () => {
    const { service } = createService();
    const passwordHash = await Bun.password.hash('a secure owner passphrase', 'argon2id');
    await service.provisionOwner('owner@example.test', passwordHash);

    for (let attempt = 0; attempt < 5; attempt += 1) {
      await expect(service.login('owner@example.test', 'the wrong passphrase'))
        .rejects.toMatchObject({ status: 401 });
    }
    await expect(service.login('owner@example.test', 'a secure owner passphrase'))
      .rejects.toMatchObject({ status: 429, message: 'ADMIN_LOGIN_LOCKED' });
  });

  test('issues an Admin token for the correct owner password', async () => {
    const { service } = createService();
    const passwordHash = await Bun.password.hash('a secure owner passphrase', 'argon2id');
    await service.provisionOwner('owner@example.test', passwordHash);

    const session = await service.login('owner@example.test', 'a secure owner passphrase');

    expect(session.accessToken.split('.')).toHaveLength(3);
  });
});
