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
  } = await import('../../src/db/schema/index.ts');
  const { AuthService } = await import('../../src/modules/auth/auth.service.ts');
  const {
    closeAdminDatabase,
    getAdminDatabase,
  } = await import('../../src/config/database.ts');
  const db = getAdminDatabase();

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
      await closeAdminDatabase();
    });

    test('provisions the owner, signs in, and reaches a protected route', async () => {
      const password = 'a secure integration passphrase';
      const passwordHash = await Bun.password.hash(password, 'argon2id');
      await new AuthService().provisionOwner('owner@example.test', passwordHash);

      const loginResponse = await app.request('/admin/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'owner@example.test', password }),
      });
      expect(loginResponse.status).toBe(200);
      const session = await loginResponse.json() as { accessToken: string };

      const overviewResponse = await app.request('/admin/overview', {
        headers: { Authorization: `Bearer ${session.accessToken}` },
      });
      expect(overviewResponse.status).toBe(200);
      expect(await overviewResponse.json()).toMatchObject({
        scope: { passengerDriverIntegration: 'deferred' },
      });
    });
  });
}
