import { describe, expect, test } from 'bun:test';
import jwt from 'jsonwebtoken';
import {
  AdminAuthenticationError,
  AdminAuthenticationService,
} from '../src/features/services/admin/admin.service.ts';
import type {
  AdminAccountRecord,
  AdminAccountRepository,
} from '../src/features/repositories/admin/admin.repository.ts';

process.env.JWT_SECRET = 'test_environment_jwt_secret_key_12345';

class MemoryAdminAccountRepository implements AdminAccountRepository {
  constructor(public owner: AdminAccountRecord) {}

  async findOwnerByEmail(email: string): Promise<AdminAccountRecord | undefined> {
    return this.owner.email === email ? this.owner : undefined;
  }

  async recordFailedLogin(
    _id: string,
    maximumAttempts: number,
    lockSeconds: number,
  ): Promise<{ attempts: number; lockedUntil: Date | null }> {
    const lockExpired =
      this.owner.lockedUntil && this.owner.lockedUntil.getTime() <= Date.now();
    this.owner.failedLoginAttempts =
      lockExpired ? 1 : this.owner.failedLoginAttempts + 1;
    this.owner.lockedUntil =
      this.owner.failedLoginAttempts >= maximumAttempts
        ? new Date(Date.now() + lockSeconds * 1000)
        : null;
    return {
      attempts: this.owner.failedLoginAttempts,
      lockedUntil: this.owner.lockedUntil,
    };
  }

  async clearFailedLogins(): Promise<void> {
    this.owner.failedLoginAttempts = 0;
    this.owner.lockedUntil = null;
  }
}

async function createOwnerRepository(): Promise<MemoryAdminAccountRepository> {
  const now = new Date();
  return new MemoryAdminAccountRepository({
    id: 'adm_test',
    email: 'owner@example.com',
    passwordHash: await Bun.password.hash('a-secure-owner-password'),
    failedLoginAttempts: 0,
    lockedUntil: null,
    createdAt: now,
    updatedAt: now,
  });
}

describe('Admin authentication', () => {
  test('issues an eight-hour admin token for the owner', async () => {
    const repository = await createOwnerRepository();
    const result = await new AdminAuthenticationService(repository).authenticateOwner({
      email: 'OWNER@example.com',
      password: 'a-secure-owner-password',
    });
    const payload = jwt.decode(result.token) as jwt.JwtPayload;

    expect(result.user.role).toBe('admin');
    expect(payload.role).toBe('admin');
    expect(payload.exp! - payload.iat!).toBe(8 * 60 * 60);
  });

  test('locks the owner after five failed attempts', async () => {
    const repository = await createOwnerRepository();
    const service = new AdminAuthenticationService(repository);

    for (let attempt = 1; attempt <= 5; attempt += 1) {
      try {
        await service.authenticateOwner({
          email: 'owner@example.com',
          password: 'incorrect-password',
        });
      } catch (error: unknown) {
        expect(error).toBeInstanceOf(AdminAuthenticationError);
        expect((error as AdminAuthenticationError).status)
          .toBe(attempt === 5 ? 429 : 401);
      }
    }

    expect(repository.owner.failedLoginAttempts).toBe(5);
    expect(repository.owner.lockedUntil!.getTime()).toBeGreaterThan(Date.now());
  });

  test('starts a fresh attempt window after a lock expires', async () => {
    const repository = await createOwnerRepository();
    repository.owner.failedLoginAttempts = 5;
    repository.owner.lockedUntil = new Date(Date.now() - 1000);

    try {
      await new AdminAuthenticationService(repository).authenticateOwner({
        email: 'owner@example.com',
        password: 'incorrect-password',
      });
    } catch (error: unknown) {
      expect((error as AdminAuthenticationError).status).toBe(401);
    }

    expect(repository.owner.failedLoginAttempts).toBe(1);
    expect(repository.owner.lockedUntil).toBeNull();
  });
});
