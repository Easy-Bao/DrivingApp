import { describe, expect, test } from 'bun:test';
import { AdminClients } from '../src/features/clients/admin.clients.ts';
import {
  AdminExecutor,
  AdminRepository,
  AuditInput,
} from '../src/features/repositories/admin.repository.ts';
import { ComplaintUpdateSchema } from '../src/features/schemas/admin.schema.ts';
import { AdminService } from '../src/features/services/admin.service.ts';

type SupportCase = {
  id: string;
  targetType: 'ride' | 'driver' | 'passenger';
  targetId: string;
  status: string;
  resolution: string | null;
  restrictionId: string | null;
};

type StoredMutation = {
  requestId: string;
  action: string;
  targetType: string;
  targetId?: string | null;
  requestHash: string;
  response: unknown;
  createdAt: Date;
};

class SupportRepository {
  readonly audits: AuditInput[] = [];
  readonly cases = new Map<string, SupportCase>();
  readonly results = new Map<string, StoredMutation>();
  readonly transaction = {} as AdminExecutor;

  async withMutationLock<T>(
    _requestId: string,
    operation: (transaction: AdminExecutor) => Promise<T>,
  ) {
    return await operation(this.transaction);
  }

  async findMutationResult(requestId: string) {
    return this.results.get(requestId) ?? null;
  }

  async saveMutationResult(input: Omit<StoredMutation, 'createdAt'>) {
    const stored = { ...input, createdAt: new Date() };
    this.results.set(input.requestId, stored);
    return stored;
  }

  async appendAudit(input: AuditInput) {
    this.audits.push(input);
    return input;
  }

  async findCase(id: string) {
    return this.cases.get(id) ?? null;
  }

  async updateCase(
    id: string,
    input: {
      status: string;
      resolution?: string | null;
      restrictionId?: string | null;
    },
  ) {
    const current = this.cases.get(id);
    if (!current) return null;
    const updated = {
      ...current,
      ...input,
      resolution: input.resolution === undefined
        ? current.resolution
        : input.resolution,
      restrictionId: input.restrictionId === undefined
        ? current.restrictionId
        : input.restrictionId,
    };
    this.cases.set(id, updated);
    return updated;
  }
}

class SupportClients {
  readonly requests: Array<{
    service: string;
    path: string;
    init: RequestInit;
  }> = [];

  async request<T>(
    service: string,
    path: string,
    init: RequestInit = {},
  ): Promise<T> {
    this.requests.push({ service, path, init });
    if (service === 'trip') {
      return {
        id: 'ride-1',
        passenger_id: 'passenger-1',
        driver_id: 'driver-1',
      } as T;
    }
    return { id: 'restriction-1' } as T;
  }
}

function createService(caseRecord?: SupportCase) {
  const repository = new SupportRepository();
  if (caseRecord) repository.cases.set(caseRecord.id, caseRecord);
  const clients = new SupportClients();
  const service = new AdminService(
    repository as unknown as AdminRepository,
    clients as unknown as AdminClients,
  );
  return { clients, repository, service };
}

const openDriverCase: SupportCase = {
  id: 'fbc5f0f8-4805-4b2a-a337-65bf30ac7692',
  targetType: 'driver',
  targetId: 'driver-1',
  status: 'open',
  resolution: null,
  restrictionId: null,
};

describe('Admin complaint workflow', () => {
  test('requires a resolution only when a case is closed', () => {
    expect(ComplaintUpdateSchema.safeParse({
      status: 'under_review',
      resolution: null,
      reason: 'Owner began review',
    }).success).toBe(true);
    expect(ComplaintUpdateSchema.safeParse({
      status: 'resolved',
      resolution: null,
      reason: 'Owner closed case',
    }).success).toBe(false);
    expect(ComplaintUpdateSchema.safeParse({
      status: 'dismissed',
      resolution: 'No policy violation found',
      reason: 'Owner closed case',
    }).success).toBe(true);
  });

  test('allows forward transitions, audits them, and keeps closed cases closed', async () => {
    const { repository, service } = createService({ ...openDriverCase });

    await service.updateCase({
      caseId: openDriverCase.id,
      status: 'under_review',
      reason: 'Review started',
      adminId: 'owner-1',
      requestId: 'case-review-1',
    });
    await service.updateCase({
      caseId: openDriverCase.id,
      status: 'resolved',
      resolution: 'Driver and passenger were contacted',
      reason: 'Review completed',
      adminId: 'owner-1',
      requestId: 'case-resolve-1',
    });

    expect(repository.cases.get(openDriverCase.id)).toMatchObject({
      status: 'resolved',
      resolution: 'Driver and passenger were contacted',
    });
    expect(repository.audits.map(({ outcome }) => outcome)).toEqual([
      'succeeded',
      'succeeded',
    ]);

    await expect(service.updateCase({
      caseId: openDriverCase.id,
      status: 'open',
      reason: 'Attempt to reopen',
      adminId: 'owner-1',
      requestId: 'case-reopen-1',
    })).rejects.toMatchObject({
      status: 409,
      message: 'INVALID_CASE_TRANSITION',
    });
    expect(repository.audits.at(-1)).toMatchObject({
      action: 'case.updated',
      outcome: 'failed',
    });
  });
});

describe('Admin restriction workflow', () => {
  test('links a matching open case and replays the downstream mutation once', async () => {
    const { clients, repository, service } = createService({ ...openDriverCase });
    const input = {
      targetType: 'driver' as const,
      targetId: 'driver-1',
      caseId: openDriverCase.id,
      endsAt: new Date(Date.now() + 86_400_000).toISOString(),
      reason: 'Temporary safety review',
      adminId: 'owner-1',
      requestId: 'restrict-driver-1',
    };

    const first = await service.restrictAccount(input);
    const replay = await service.restrictAccount(input);

    expect(replay).toEqual(first);
    expect(clients.requests).toHaveLength(1);
    expect(clients.requests[0]).toMatchObject({
      service: 'driver',
      path: '/drivers/admin/drivers/driver-1/restrictions',
    });
    expect(new Headers(clients.requests[0]?.init.headers).get(
      'Idempotency-Key',
    )).toBe('restrict-driver-1');
    expect(repository.cases.get(openDriverCase.id)).toMatchObject({
      status: 'under_review',
      restrictionId: 'restriction-1',
    });
    expect(repository.audits).toHaveLength(1);
    expect(repository.audits[0]).toMatchObject({
      action: 'account.restricted',
      outcome: 'succeeded',
    });
  });

  test('rejects mismatched, closed-case, and expired restriction requests before dispatch', async () => {
    const mismatched = createService({
      ...openDriverCase,
      targetType: 'passenger',
      targetId: 'passenger-1',
    });
    await expect(mismatched.service.restrictAccount({
      targetType: 'driver',
      targetId: 'driver-1',
      caseId: openDriverCase.id,
      reason: 'Wrong account link',
      adminId: 'owner-1',
      requestId: 'restriction-mismatch-1',
    })).rejects.toMatchObject({
      status: 409,
      message: 'CASE_TARGET_MISMATCH',
    });

    const closed = createService({
      ...openDriverCase,
      status: 'resolved',
      resolution: 'Already completed',
    });
    await expect(closed.service.restrictAccount({
      targetType: 'driver',
      targetId: 'driver-1',
      caseId: openDriverCase.id,
      reason: 'Closed case link',
      adminId: 'owner-1',
      requestId: 'restriction-closed-1',
    })).rejects.toMatchObject({
      status: 409,
      message: 'INVALID_CASE_TRANSITION',
    });

    const expired = createService();
    await expect(expired.service.restrictAccount({
      targetType: 'passenger',
      targetId: 'passenger-1',
      endsAt: '2020-01-01T00:00:00.000Z',
      reason: 'Already expired',
      adminId: 'owner-1',
      requestId: 'restriction-expired-1',
    })).rejects.toMatchObject({
      status: 422,
      message: 'INVALID_EXPIRY',
    });

    expect(mismatched.clients.requests).toHaveLength(0);
    expect(closed.clients.requests).toHaveLength(0);
    expect(expired.clients.requests).toHaveLength(0);
    expect(mismatched.repository.audits[0]?.outcome).toBe('failed');
    expect(closed.repository.audits[0]?.outcome).toBe('failed');
    expect(expired.repository.audits[0]?.outcome).toBe('failed');
  });

  test('only links a ride case to a passenger or driver on that ride', async () => {
    const { clients, service } = createService({
      ...openDriverCase,
      targetType: 'ride',
      targetId: 'ride-1',
    });

    await expect(service.restrictAccount({
      targetType: 'driver',
      targetId: 'driver-2',
      caseId: openDriverCase.id,
      reason: 'Driver is not on this ride',
      adminId: 'owner-1',
      requestId: 'restriction-ride-mismatch-1',
    })).rejects.toMatchObject({
      status: 409,
      message: 'CASE_TARGET_MISMATCH',
    });

    expect(clients.requests).toHaveLength(1);
    expect(clients.requests[0]).toMatchObject({
      service: 'trip',
      path: '/rides/ride-1',
    });
  });
});
