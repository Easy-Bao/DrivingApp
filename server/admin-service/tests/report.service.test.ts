import { describe, expect, test } from 'bun:test';
import { AdminClients, ServiceName } from '../src/features/clients/admin.clients.ts';
import { AdminRepository } from '../src/features/repositories/admin.repository.ts';
import {
  AuditListQuerySchema,
  CaseListQuerySchema,
} from '../src/features/schemas/admin.schema.ts';
import { AdminService } from '../src/features/services/admin.service.ts';

class ReportClients {
  readonly pages: number[] = [];
  readonly paths: string[] = [];
  readonly records = Array.from({ length: 205 }, (_, index) => ({
    id: `record-${index + 1}`,
  }));

  async request<T>(_service: ServiceName, path: string): Promise<T> {
    this.paths.push(path);
    const url = new URL(path, 'http://service.test');
    const page = Number(url.searchParams.get('page') ?? 1);
    const limit = Number(url.searchParams.get('limit') ?? 100);
    this.pages.push(page);
    return {
      items: this.records.slice((page - 1) * limit, page * limit),
      page,
      limit,
      total: this.records.length,
    } as T;
  }

  async safeRequest<T>(_service: ServiceName, path: string) {
    if (path.includes('/drivers/admin/drivers')) {
      return { ok: true as const, data: { items: this.records.slice(0, 100), total: 205 } as T };
    }
    if (path.includes('/drivers/admin/topups')) {
      return { ok: true as const, data: { items: this.records.slice(0, 100), total: 150 } as T };
    }
    return { ok: true as const, data: [] as T };
  }
}

function service(repository: Partial<AdminRepository>, clients = new ReportClients()) {
  return {
    clients,
    service: new AdminService(
      repository as AdminRepository,
      clients as unknown as AdminClients,
    ),
  };
}

describe('Admin reports', () => {
  test('validates and returns paginated case and audit lists', async () => {
    expect(CaseListQuerySchema.safeParse({
      page: '2',
      status: 'open',
      from: '2026-07-01',
      to: '2026-07-31',
    }).success).toBe(true);
    expect(AuditListQuerySchema.safeParse({ status: 'failed' }).success).toBe(true);
    expect(AuditListQuerySchema.safeParse({ status: 'open' }).success).toBe(false);

    const { service: admin } = service({
      listCases: async () => [{ id: 'case-1' }] as never[],
      countCases: async () => 51,
      listAudits: async () => [{ id: 'audit-1' }] as never[],
      countAudits: async () => 101,
    });

    await expect(admin.listCases('open', 50, 50)).resolves.toMatchObject({
      page: 2,
      limit: 50,
      total: 51,
      items: [{ id: 'case-1' }],
    });
    await expect(admin.audits(100, 100, 'failed')).resolves.toMatchObject({
      page: 2,
      limit: 100,
      total: 101,
      items: [{ id: 'audit-1' }],
    });
  });

  test('uses source totals for overview cards', async () => {
    const { service: admin } = service({
      localCounts: async () => ({ openCases: 2, activeZones: 3 }),
    });

    const overview = await admin.overview();

    expect(overview.counts).toMatchObject({
      drivers: 205,
      pending_topups: 150,
      open_cases: 2,
      active_zones: 3,
    });
  });

  test('exports every page from a paginated service', async () => {
    const { clients, service: admin } = service({});

    const csv = await admin.report('commissions', new URLSearchParams());

    expect(csv.trim().split('\r\n')).toHaveLength(206);
    expect(clients.pages).toEqual([1, 2, 3]);
  });

  test('maps compliance status and Manila calendar dates to source filters', async () => {
    const { clients, service: admin } = service({});

    await admin.report('compliance', new URLSearchParams({
      status: 'approved',
      from: '2026-07-01',
      to: '2026-07-31',
    }));

    const query = new URL(clients.paths[0]!, 'http://service.test').searchParams;
    expect(query.get('status')).toBeNull();
    expect(query.get('approvalStatus')).toBe('approved');
    expect(query.get('from')).toBe('2026-06-30T16:00:00.000Z');
    expect(query.get('to')).toBe('2026-07-31T15:59:59.999Z');
  });

  test('exports every case batch and applies date filters', async () => {
    const records = Array.from({ length: 1_005 }, (_, index) => ({
      id: `case-${index + 1}`,
    }));
    const calls: Array<Record<string, unknown>> = [];
    const { service: admin } = service({
      listCases: async (input) => {
        calls.push(input);
        return records.slice(input.offset, input.offset + input.limit) as never[];
      },
    });

    const csv = await admin.report('cases', new URLSearchParams({
      status: 'resolved',
      from: '2026-07-01T00:00:00.000Z',
      to: '2026-07-31T23:59:59.999Z',
    }));

    expect(csv.trim().split('\r\n')).toHaveLength(1_006);
    expect(calls.map(({ offset }) => offset)).toEqual([0, 1_000]);
    expect(calls[0]).toMatchObject({ status: 'resolved' });
    expect(calls[0]?.from).toBeInstanceOf(Date);
    expect(calls[0]?.to).toBeInstanceOf(Date);
  });

  test('rejects invalid or reversed date ranges', async () => {
    const { service: admin } = service({});

    await expect(admin.report('trips', new URLSearchParams({
      from: 'not-a-date',
    }))).rejects.toMatchObject({ status: 400, message: 'INVALID_DATE_FILTER' });
    await expect(admin.report('trips', new URLSearchParams({
      from: '2026-08-01T00:00:00.000Z',
      to: '2026-07-01T00:00:00.000Z',
    }))).rejects.toMatchObject({ status: 400, message: 'INVALID_DATE_RANGE' });
    await expect(admin.report('topups', new URLSearchParams({
      status: 'completed',
    }))).rejects.toMatchObject({ status: 400, message: 'INVALID_REPORT_STATUS' });
  });
});
