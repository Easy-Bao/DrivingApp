import { describe, expect, test } from 'bun:test';
import {
  AdminExecutor,
  AdminRepository,
  AuditInput,
} from '../src/features/repositories/admin.repository.ts';
import {
  AdminService,
  rowsToCsv,
} from '../src/features/services/admin.service.ts';

class MemoryRepository {
  readonly transaction = {} as AdminExecutor;
  readonly audits: AuditInput[] = [];
  readonly results = new Map<string, {
    requestId: string;
    action: string;
    targetType: string;
    targetId: string | null;
    requestHash: string;
    response: unknown;
  }>();
  readonly cases = new Map<string, {
    id: string;
    targetType: 'ride' | 'driver' | 'passenger';
    targetId: string;
    rideId: string | null;
    category: string;
    notes: string;
    status: 'open' | 'under_review' | 'resolved' | 'dismissed';
    resolution: string | null;
    createdBy: string;
  }>();

  async withMutationLock<T>(
    _requestId: string,
    operation: (transaction: AdminExecutor) => Promise<T>,
  ) {
    return await operation(this.transaction);
  }

  async findMutationResult(requestId: string) {
    return this.results.get(requestId) ?? null;
  }

  async saveMutationResult(input: {
    requestId: string;
    action: string;
    targetType: string;
    targetId?: string | null;
    requestHash: string;
    response: unknown;
  }) {
    const stored = { ...input, targetId: input.targetId ?? null };
    this.results.set(input.requestId, stored);
    return stored;
  }

  async appendAudit(input: AuditInput) {
    this.audits.push(input);
    return input;
  }

  async createCase(input: {
    targetType: 'ride' | 'driver' | 'passenger';
    targetId: string;
    rideId?: string | null;
    category: string;
    notes: string;
    createdBy: string;
  }) {
    const record = {
      id: `case-${this.cases.size + 1}`,
      ...input,
      rideId: input.rideId ?? null,
      status: 'open' as const,
      resolution: null,
    };
    this.cases.set(record.id, record);
    return record;
  }

  async findCase(id: string) {
    return this.cases.get(id) ?? null;
  }

  async updateCase(
    id: string,
    input: {
      status: 'open' | 'under_review' | 'resolved' | 'dismissed';
      resolution?: string | null;
    },
  ) {
    const current = this.cases.get(id);
    if (!current) return null;
    const updated = { ...current, ...input, resolution: input.resolution ?? null };
    this.cases.set(id, updated);
    return updated;
  }
}

function createService() {
  const repository = new MemoryRepository();
  const service = new AdminService(repository as unknown as AdminRepository);
  return { repository, service };
}

describe('Admin-local case workflow', () => {
  test('replays a case creation only once for the same idempotency key', async () => {
    const { repository, service } = createService();
    const input = {
      adminId: 'owner-1',
      requestId: 'case-create-1',
      reason: 'support request received',
      payload: {
        target_type: 'ride' as const,
        target_id: 'ride-1',
        category: 'safety',
        notes: 'manual review required',
      },
    };

    const first = await service.createCase(input);
    const replay = await service.createCase(input);

    expect(replay).toEqual(first);
    expect(repository.cases).toHaveLength(1);
    expect(repository.audits).toHaveLength(1);
  });

  test('requires a resolution before a case can close', async () => {
    const { service } = createService();
    const created = await service.createCase({
      adminId: 'owner-1',
      requestId: 'case-create-2',
      reason: 'support request received',
      payload: {
        target_type: 'driver',
        target_id: 'driver-1',
        category: 'conduct',
        notes: 'manual review required',
      },
    });

    await expect(service.updateCase({
      adminId: 'owner-1',
      requestId: 'case-close-1',
      caseId: created.id,
      status: 'resolved',
      reason: 'review completed',
    })).rejects.toMatchObject({ status: 422, message: 'CASE_RESOLUTION_REQUIRED' });
  });

  test('escapes report values as CSV', () => {
    expect(rowsToCsv([{ notes: 'hello, "driver"' }])).toBe(
      '\uFEFF"notes"\r\n"hello, ""driver"""\r\n',
    );
  });
});
