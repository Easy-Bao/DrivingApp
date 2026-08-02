import { afterAll, beforeEach, describe, expect, test } from 'bun:test';

if (process.env.RUN_DB_INTEGRATION_TESTS !== '1') {
  describe.skip('Admin HTTP authentication with migrated PostgreSQL', () => {
    test('requires RUN_DB_INTEGRATION_TESTS=1', () => undefined);
  });
} else {
  const { app } = await import('../../src/index.ts');
  const {
    adminAuditEvents,
    adminMutationResults,
    adminOwners,
    complaintCases,
  } = await import('../../src/db/schema.ts');
  const { AuthRepository } = await import('../../src/features/repositories/auth.repository.ts');
  const { AuthService } = await import('../../src/features/services/auth.service.ts');
  const { db, postgresClient } = await import('../../src/shared/drizzle.ts');

  async function clearAdminTables() {
    await db.delete(adminAuditEvents);
    await db.delete(adminMutationResults);
    await db.delete(complaintCases);
    await db.delete(adminOwners);
  }

  describe('Admin HTTP authentication with migrated PostgreSQL', () => {
    beforeEach(clearAdminTables);
    afterAll(async () => {
      await clearAdminTables();
      await postgresClient.end();
    });

    test('provisions the owner, signs in, and reaches a protected route', async () => {
      const password = 'a secure integration passphrase';
      const passwordHash = await Bun.password.hash(password, 'argon2id');
      await new AuthService(new AuthRepository())
        .provisionOwner('owner@example.test', passwordHash);

      const loginResponse = await app.request('/admin/v1/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'owner@example.test', password }),
      });
      expect(loginResponse.status).toBe(200);
      const session = await loginResponse.json() as { accessToken: string };

      const overviewResponse = await app.request('/admin/v1/overview', {
        headers: { Authorization: `Bearer ${session.accessToken}` },
      });
      expect(overviewResponse.status).toBe(200);
      expect(await overviewResponse.json()).toMatchObject({
        scope: { passengerDriverIntegration: 'deferred' },
      });
    });
  });
}
