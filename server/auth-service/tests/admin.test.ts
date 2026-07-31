import { describe, expect, test } from 'bun:test';
import jwt from 'jsonwebtoken';
import {
  AdminAuthenticationError,
  AdminAuthenticationService,
  AdminOwnerProvisioningService,
} from '../src/features/services/admin/admin.service.ts';
import type {
  AdminAccountRecord,
  AdminAccountRepository,
  AdminOwnerProvisioningRepository,
} from '../src/features/repositories/admin/admin.repository.ts';
import { JsonWebTokenService } from '../src/features/services/common/jwt.service.ts';

const JWT_SECRET = 'test_environment_jwt_secret_key_12345';
process.env.JWT_SECRET = JWT_SECRET;

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

class MemoryAdminOwnerProvisioningRepository
  implements AdminOwnerProvisioningRepository {
  constructor(public owner?: AdminAccountRecord) {}

  async createOwnerIfAbsent(email: string, passwordHash: string): Promise<boolean> {
    if (this.owner) {
      return false;
    }

    const now = new Date();
    this.owner = {
      id: 'adm_test',
      email,
      passwordHash,
      failedLoginAttempts: 0,
      lockedUntil: null,
      createdAt: now,
      updatedAt: now,
    };
    return true;
  }

  async findOwner(): Promise<AdminAccountRecord | undefined> {
    return this.owner;
  }

  async rotateOwnerPassword(id: string, passwordHash: string): Promise<void> {
    if (!this.owner || this.owner.id !== id) {
      throw new Error('Owner account no longer exists.');
    }
    this.owner.passwordHash = passwordHash;
    this.owner.failedLoginAttempts = 0;
    this.owner.lockedUntil = null;
    this.owner.updatedAt = new Date();
  }
}

async function createOwnerRecord(): Promise<AdminAccountRecord> {
  const now = new Date();
  return {
    id: 'adm_test',
    email: 'owner@example.com',
    passwordHash: await Bun.password.hash('a-secure-owner-password'),
    failedLoginAttempts: 0,
    lockedUntil: null,
    createdAt: now,
    updatedAt: now,
  };
}

async function createOwnerRepository(): Promise<MemoryAdminAccountRepository> {
  return new MemoryAdminAccountRepository(await createOwnerRecord());
}

describe('Admin owner provisioning', () => {
  test('creates the first owner with a normalized email and password hash', async () => {
    const repository = new MemoryAdminOwnerProvisioningRepository();
    const passwordHash = await Bun.password.hash('first-secure-owner-password');

    const result = await new AdminOwnerProvisioningService(repository).provisionOwner(
      ' OWNER@example.com ',
      passwordHash,
    );

    expect(result).toBe('created');
    expect(repository.owner?.email).toBe('owner@example.com');
    expect(await Bun.password.verify(
      'first-secure-owner-password',
      repository.owner!.passwordHash,
    )).toBe(true);
  });

  test('rotates only the same owner password and clears its login lock', async () => {
    const owner = await createOwnerRecord();
    owner.failedLoginAttempts = 5;
    owner.lockedUntil = new Date(Date.now() + 60_000);
    const previousPasswordHash = owner.passwordHash;
    const repository = new MemoryAdminOwnerProvisioningRepository(owner);
    const nextPasswordHash = await Bun.password.hash('rotated-secure-owner-password');

    const result = await new AdminOwnerProvisioningService(repository).provisionOwner(
      'OWNER@example.com',
      nextPasswordHash,
    );

    expect(result).toBe('rotated');
    expect(repository.owner?.passwordHash).not.toBe(previousPasswordHash);
    expect(repository.owner?.failedLoginAttempts).toBe(0);
    expect(repository.owner?.lockedUntil).toBeNull();
    expect(await Bun.password.verify(
      'rotated-secure-owner-password',
      repository.owner!.passwordHash,
    )).toBe(true);
  });

  test('refuses to replace the owner with a different email', async () => {
    const owner = await createOwnerRecord();
    const previousPasswordHash = owner.passwordHash;
    const repository = new MemoryAdminOwnerProvisioningRepository(owner);

    await expect(
      new AdminOwnerProvisioningService(repository).provisionOwner(
        'second-owner@example.com',
        await Bun.password.hash('second-secure-owner-password'),
      ),
    ).rejects.toThrow('different email address');

    expect(repository.owner?.email).toBe('owner@example.com');
    expect(repository.owner?.passwordHash).toBe(previousPasswordHash);
  });
});

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
    expect(JsonWebTokenService.verifyAdminJsonWebToken(result.token).role).toBe('admin');
  });

  test('rejects invalid owner credentials', async () => {
    const repository = await createOwnerRepository();

    await expect(
      new AdminAuthenticationService(repository).authenticateOwner({
        email: 'not-the-owner@example.com',
        password: 'a-secure-owner-password',
      }),
    ).rejects.toMatchObject({
      code: 'INVALID_ADMIN_CREDENTIALS',
      status: 401,
    });
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

    await expect(
      service.authenticateOwner({
        email: 'owner@example.com',
        password: 'a-secure-owner-password',
      }),
    ).rejects.toMatchObject({
      code: 'ADMIN_LOGIN_LOCKED',
      status: 429,
    });
    expect(repository.owner.failedLoginAttempts).toBe(5);
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

  test('clears prior failed attempts after a correct login', async () => {
    const repository = await createOwnerRepository();
    repository.owner.failedLoginAttempts = 2;

    await new AdminAuthenticationService(repository).authenticateOwner({
      email: 'owner@example.com',
      password: 'a-secure-owner-password',
    });

    expect(repository.owner.failedLoginAttempts).toBe(0);
    expect(repository.owner.lockedUntil).toBeNull();
  });
});

describe('Admin session verification', () => {
  test('rejects an expired admin token', () => {
    const expiredToken = jwt.sign(
      { sub: 'adm_test', email: 'owner@example.com', role: 'admin' },
      JWT_SECRET,
      { expiresIn: -1 },
    );

    expect(() => JsonWebTokenService.verifyAdminJsonWebToken(expiredToken))
      .toThrow('Invalid or expired authentication token');
  });

  test('rejects a signed non-Admin token', () => {
    const passengerToken = JsonWebTokenService.generateJsonWebToken(
      'passenger_test',
      'passenger@example.com',
      'passenger',
    );

    expect(() => JsonWebTokenService.verifyAdminJsonWebToken(passengerToken))
      .toThrow('Admin access is required');
  });
});
