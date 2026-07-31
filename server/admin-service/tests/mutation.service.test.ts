import { describe, expect, test } from 'bun:test';
import { AdminClients } from '../src/features/clients/admin.clients.ts';
import {
  AdminExecutor,
  AdminRepository,
  AuditInput,
} from '../src/features/repositories/admin.repository.ts';
import { AdminService } from '../src/features/services/admin.service.ts';
import { fingerprintMutationPayload } from '../src/features/services/mutation.service.ts';
import { DocumentRequirementUpdateSchema } from '../src/features/schemas/admin.schema.ts';

type StoredMutation = {
  requestId: string;
  action: string;
  targetType: string;
  targetId?: string | null;
  requestHash: string;
  response: unknown;
  createdAt: Date;
};

class MemoryRepository {
  readonly results = new Map<string, StoredMutation>();
  readonly audits: AuditInput[] = [];
  readonly transaction = {} as AdminExecutor;
  readonly executors: AdminExecutor[] = [];

  async withMutationLock<T>(
    _requestId: string,
    operation: (transaction: AdminExecutor) => Promise<T>,
  ) {
    return await operation(this.transaction);
  }

  async findMutationResult(requestId: string, executor?: AdminExecutor) {
    if (executor) this.executors.push(executor);
    return this.results.get(requestId) ?? null;
  }

  async saveMutationResult(
    input: Omit<StoredMutation, 'createdAt'>,
    executor?: AdminExecutor,
  ) {
    if (executor) this.executors.push(executor);
    const stored = { ...input, createdAt: new Date() };
    this.results.set(input.requestId, stored);
    return stored;
  }

  async appendAudit(input: AuditInput, executor?: AdminExecutor) {
    if (executor) this.executors.push(executor);
    this.audits.push(input);
    return input;
  }

  async findZone(_psgcCode: string, executor?: AdminExecutor) {
    if (executor) this.executors.push(executor);
    return {
      psgcCode: '097322009',
      isActive: false,
      geometry: { type: 'Polygon', coordinates: [] },
    };
  }

  async setZoneActive(
    psgcCode: string,
    isActive: boolean,
    executor?: AdminExecutor,
  ) {
    if (executor) this.executors.push(executor);
    return { psgcCode, isActive };
  }
}

class FakeClients {
  mutationCalls = 0;
  failMutation = false;
  readonly requests: Array<{ path: string; init: RequestInit }> = [];

  async request<T>(
    _service: string,
    path: string,
    init: RequestInit = {},
  ): Promise<T> {
    this.requests.push({ path, init });
    if (path.endsWith('/approval') && init.method === 'PATCH') {
      this.mutationCalls += 1;
      if (this.failMutation) {
        throw new Error('downstream leaked bearer secret-value');
      }
      const body = JSON.parse(String(init.body));
      return {
        status: body.status,
        accessToken: 'after-token',
        pin: '1234',
      } as T;
    }
    if (path === '/drivers/admin/document-requirements' && !init.method) {
      return [{
        id: 'requirement-1',
        name: 'Driver license',
        requiresExpiry: false,
        isActive: true,
      }] as T;
    }
    if (
      path.startsWith('/drivers/admin/document-requirements')
      && (init.method === 'POST' || init.method === 'PATCH')
    ) {
      return {
        id: 'requirement-1',
        ...JSON.parse(String(init.body)),
      } as T;
    }
    return { accessToken: 'before-token' } as T;
  }
}

function createService() {
  const repository = new MemoryRepository();
  const clients = new FakeClients();
  const service = new AdminService(
    repository as unknown as AdminRepository,
    clients as unknown as AdminClients,
  );
  return { repository, clients, service };
}

describe('Admin mutation idempotency', () => {
  test('normalizes payload object keys before hashing', async () => {
    expect(await fingerprintMutationPayload({ b: 2, a: 1 })).toBe(
      await fingerprintMutationPayload({ a: 1, b: 2 }),
    );
  });

  test('replays one completed mutation and sanitizes its audit state', async () => {
    const { repository, clients, service } = createService();
    const input = {
      driverId: 'driver-1',
      status: 'approved',
      reason: 'documents verified',
      adminId: 'owner-1',
      requestId: 'request-1',
    };

    const first = await service.updateDriverApproval(input);
    const replay = await service.updateDriverApproval(input);

    expect(replay).toEqual(first);
    expect(clients.mutationCalls).toBe(1);
    expect(repository.audits).toHaveLength(1);
    const audit = JSON.stringify(repository.audits[0]);
    expect(audit).not.toContain('before-token');
    expect(audit).not.toContain('after-token');
    expect(audit).not.toContain('1234');
  });

  test('rejects a key reused for a different payload, target, or action', async () => {
    const { clients, service } = createService();
    const input = {
      driverId: 'driver-1',
      status: 'approved',
      reason: 'documents verified',
      adminId: 'owner-1',
      requestId: 'request-2',
    };
    await service.updateDriverApproval(input);

    await expect(service.updateDriverApproval({
      ...input,
      status: 'rejected',
    })).rejects.toMatchObject({ status: 409, message: 'IDEMPOTENCY_KEY_REUSED' });
    await expect(service.updateDriverApproval({
      ...input,
      driverId: 'driver-2',
    })).rejects.toMatchObject({ status: 409, message: 'IDEMPOTENCY_KEY_REUSED' });
    await expect(service.reviewTopUp({
      topUpId: 'topup-1',
      status: 'approved',
      reason: input.reason,
      adminId: input.adminId,
      requestId: input.requestId,
    })).rejects.toMatchObject({ status: 409, message: 'IDEMPOTENCY_KEY_REUSED' });

    expect(clients.mutationCalls).toBe(1);
  });

  test('does not copy unexpected downstream errors into failed audit records', async () => {
    const { repository, clients, service } = createService();
    clients.failMutation = true;

    await expect(service.updateDriverApproval({
      driverId: 'driver-1',
      status: 'approved',
      reason: 'documents verified',
      adminId: 'owner-1',
      requestId: 'request-3',
    })).rejects.toThrow('downstream leaked bearer secret-value');

    expect(repository.audits).toHaveLength(1);
    expect(repository.audits[0]?.afterState).toEqual({
      error: { code: 'INTERNAL_ERROR' },
    });
    expect(JSON.stringify(repository.audits[0])).not.toContain('secret-value');
  });

  test('rejects invalid keys and redacts credential-like audit reasons', async () => {
    const { repository, clients, service } = createService();

    await expect(service.updateDriverApproval({
      driverId: 'driver-1',
      status: 'approved',
      reason: 'documents verified',
      adminId: 'owner-1',
      requestId: 'x'.repeat(201),
    })).rejects.toMatchObject({ status: 400, message: 'INVALID_IDEMPOTENCY_KEY' });
    expect(clients.mutationCalls).toBe(0);

    await service.updateDriverApproval({
      driverId: 'driver-1',
      status: 'approved',
      reason: 'token=must-not-enter-audit',
      adminId: 'owner-1',
      requestId: 'request-redacted',
    });
    expect(repository.audits[0]?.reason).toBe('[REDACTED]');
  });

  test('uses one transaction for an Admin-local write, result, and audit', async () => {
    const { repository, service } = createService();

    await service.updateZone({
      psgcCode: '097322009',
      isActive: true,
      reason: 'pilot launch',
      adminId: 'owner-1',
      requestId: 'request-4',
    });

    expect(repository.executors.length).toBeGreaterThanOrEqual(5);
    expect(repository.executors.every(
      (executor) => executor === repository.transaction,
    )).toBe(true);
  });

  test('maps document requirement creation to the Driver contract', async () => {
    const { repository, clients, service } = createService();

    await service.createDocumentRequirement({
      payload: {
        name: 'Driver license',
        requires_expiry: true,
        is_active: false,
        reason: 'pilot checklist',
      },
      reason: 'pilot checklist',
      adminId: 'owner-1',
      requestId: 'requirement-create-1',
    });

    const request = clients.requests.find(({ init }) => init.method === 'POST');
    expect(request?.path).toBe('/drivers/admin/document-requirements');
    expect(JSON.parse(String(request?.init.body))).toEqual({
      name: 'Driver license',
      requiresExpiry: true,
      isActive: false,
    });
    expect(new Headers(request?.init.headers).get('Idempotency-Key')).toBe(
      'requirement-create-1',
    );
    expect(new Headers(request?.init.headers).get('X-Admin-Id')).toBe('owner-1');
    expect(repository.audits[0]?.action).toBe('driver.document_requirement.created');
  });

  test('validates and maps document requirement updates through the audit seam', async () => {
    expect(DocumentRequirementUpdateSchema.safeParse({
      reason: 'no actual change',
    }).success).toBe(false);
    expect(DocumentRequirementUpdateSchema.safeParse({
      is_active: false,
      reason: 'pause this check',
    }).success).toBe(true);

    const { repository, clients, service } = createService();
    await service.updateDocumentRequirement({
      requirementId: 'requirement-1',
      payload: {
        requires_expiry: true,
        is_active: false,
        reason: 'policy changed',
      },
      reason: 'policy changed',
      adminId: 'owner-1',
      requestId: 'requirement-update-1',
    });

    const request = clients.requests.find(({ init }) => init.method === 'PATCH');
    expect(request?.path).toBe(
      '/drivers/admin/document-requirements/requirement-1',
    );
    expect(JSON.parse(String(request?.init.body))).toEqual({
      requiresExpiry: true,
      isActive: false,
    });
    expect(new Headers(request?.init.headers).get('Idempotency-Key')).toBe(
      'requirement-update-1',
    );
    expect(new Headers(request?.init.headers).get('X-Admin-Id')).toBe('owner-1');
    expect(repository.audits[0]).toMatchObject({
      action: 'driver.document_requirement.updated',
      targetType: 'document_requirement',
      targetId: 'requirement-1',
      outcome: 'succeeded',
    });
  });
});
