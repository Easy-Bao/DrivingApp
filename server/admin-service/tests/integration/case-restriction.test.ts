import {
  afterAll,
  beforeEach,
  describe,
  expect,
  test,
} from 'bun:test';
import { eq } from 'drizzle-orm';
import {
  adminAuditEvents,
  adminMutationResults,
  complaintCases,
} from '../../src/db/schema.ts';
import type { AdminClients } from '../../src/features/clients/admin.clients.ts';

class SupportClients {
  restrictionCalls = 0;

  async request<T>(
    service: string,
    path: string,
  ): Promise<T> {
    if (
      service === 'driver'
      && path.endsWith('/restrictions')
    ) {
      this.restrictionCalls += 1;
      return { id: 'restriction-1' } as T;
    }
    throw new Error(`Unexpected support test request: ${service} ${path}`);
  }
}

async function loadIntegrationHarness() {
  const [repositoryModule, serviceModule, databaseModule] = await Promise.all([
    import('../../src/features/repositories/admin.repository.ts'),
    import('../../src/features/services/admin.service.ts'),
    import('../../src/shared/drizzle.ts'),
  ]);
  const repository = new repositoryModule.AdminRepository();
  const clients = new SupportClients();
  return {
    repository,
    clients,
    service: new serviceModule.AdminService(
      repository,
      clients as unknown as AdminClients,
    ),
    db: databaseModule.db,
    postgresClient: databaseModule.postgresClient,
  };
}

const runDatabaseIntegration = process.env.RUN_ADMIN_SUPPORT_INTEGRATION === '1';
const integration = runDatabaseIntegration ? await loadIntegrationHarness() : null;
const databaseDescribe = runDatabaseIntegration
  ? describe
  : describe.skip;

function integrationHarness() {
  if (!integration) throw new Error('Admin support integration is not enabled.');
  return integration;
}

databaseDescribe('Admin complaint and restriction transactions', () => {
  beforeEach(async () => {
    const { clients, db } = integrationHarness();
    clients.restrictionCalls = 0;
    await db.delete(adminAuditEvents);
    await db.delete(adminMutationResults);
    await db.delete(complaintCases);
  });

  afterAll(async () => {
    await integration?.postgresClient.end();
  });

  test('links a restriction and audits case closure', async () => {
    const { clients, db, repository, service } = integrationHarness();
    const created = await service.createCase({
      payload: {
        target_type: 'driver',
        target_id: 'driver-1',
        category: 'Pilot support concern',
        notes: 'Controlled integration record',
      },
      reason: 'Create controlled support case',
      adminId: 'owner-1',
      requestId: 'support-case-create-1',
    }) as typeof complaintCases.$inferSelect;

    const restrictionInput = {
      targetType: 'driver' as const,
      targetId: 'driver-1',
      caseId: created.id,
      endsAt: new Date(Date.now() + 86_400_000).toISOString(),
      reason: 'Controlled temporary restriction',
      adminId: 'owner-1',
      requestId: 'support-restriction-create-1',
    };
    const restriction = await service.restrictAccount(restrictionInput);

    expect(restriction).toEqual({ id: 'restriction-1' });
    expect(clients.restrictionCalls).toBe(1);
    expect(await repository.findCase(created.id)).toMatchObject({
      status: 'under_review',
      restrictionId: 'restriction-1',
    });

    await service.updateCase({
      caseId: created.id,
      status: 'resolved',
      resolution: 'Controlled review completed',
      reason: 'Resolve controlled case',
      adminId: 'owner-1',
      requestId: 'support-case-resolve-1',
    });

    const mutations = await db.select()
      .from(adminMutationResults);
    const audits = await db.select()
      .from(adminAuditEvents);
    const restrictionMutations = mutations.filter(
      ({ action }) => action === 'account.restricted',
    );
    expect(restrictionMutations).toHaveLength(1);
    expect(audits.filter(
      ({ requestId }) => requestId === 'support-restriction-create-1',
    )).toHaveLength(1);

    const [storedCase] = await db.select()
      .from(complaintCases)
      .where(eq(complaintCases.id, created.id));
    expect(storedCase).toMatchObject({
      status: 'resolved',
      resolution: 'Controlled review completed',
      restrictionId: 'restriction-1',
    });
  });

  test('paginates and filters case and audit records with complete totals', async () => {
    const { service } = integrationHarness();
    const created = await service.createCase({
      payload: {
        target_type: 'passenger',
        target_id: 'passenger-1',
        category: 'Report filter check',
        notes: 'Controlled report record',
      },
      reason: 'Create report test case',
      adminId: 'owner-1',
      requestId: 'report-case-create-1',
    }) as typeof complaintCases.$inferSelect;
    await service.updateCase({
      caseId: created.id,
      status: 'resolved',
      resolution: 'Report check completed',
      reason: 'Resolve report test case',
      adminId: 'owner-1',
      requestId: 'report-case-resolve-1',
    });

    const resolvedCases = await service.listCases(
      'resolved',
      1,
      0,
      '2000-01-01',
      '2100-01-01',
    );
    expect(resolvedCases).toMatchObject({ page: 1, limit: 1, total: 1 });
    const futureCases = await service.listCases(
      'resolved',
      1,
      0,
      '2100-01-01',
    );
    expect(futureCases).toMatchObject({ total: 0, items: [] });

    const audits = await service.audits(
      1,
      0,
      'succeeded',
      '2000-01-01',
      '2100-01-01',
    );
    expect(audits.items).toHaveLength(1);
    expect(audits.total).toBe(2);
  });
});
