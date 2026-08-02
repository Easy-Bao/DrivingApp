import { and, desc, eq, gte, lte, SQL, sql } from 'drizzle-orm';
import { HTTPException } from 'hono/http-exception';
import { AdminExecutor, getAdminDatabase } from '../../config/database.ts';
import {
  CaseStatus,
  CaseTargetType,
  complaintCases,
} from '../../db/schema/index.ts';
import { AuditService } from '../audit-log/audit.service.ts';

const caseTransitions: Record<CaseStatus, ReadonlySet<CaseStatus>> = {
  open: new Set(['open', 'under_review', 'resolved', 'dismissed']),
  under_review: new Set(['under_review', 'resolved', 'dismissed']),
  resolved: new Set(['resolved']),
  dismissed: new Set(['dismissed']),
};

export type CaseStore = {
  listCases(input: {
    status?: CaseStatus;
    from?: Date;
    to?: Date;
    limit: number;
    offset: number;
  }): Promise<Array<typeof complaintCases.$inferSelect>>;
  countCases(input: { status?: CaseStatus; from?: Date; to?: Date }): Promise<number>;
  findCase(id: string, executor?: AdminExecutor): Promise<
    typeof complaintCases.$inferSelect | null
  >;
  createCase(input: {
    targetType: CaseTargetType;
    targetId: string;
    rideId?: string | null;
    category: string;
    notes: string;
    createdBy: string;
  }, executor?: AdminExecutor): Promise<typeof complaintCases.$inferSelect | undefined>;
  updateCase(
    id: string,
    input: { status: CaseStatus; resolution?: string | null },
    executor?: AdminExecutor,
  ): Promise<typeof complaintCases.$inferSelect | null>;
};

function caseConditions(input: {
  status?: CaseStatus;
  from?: Date;
  to?: Date;
}): SQL[] {
  return [
    input.status ? eq(complaintCases.status, input.status) : undefined,
    input.from ? gte(complaintCases.createdAt, input.from) : undefined,
    input.to ? lte(complaintCases.createdAt, input.to) : undefined,
  ].filter((condition): condition is SQL => Boolean(condition));
}

export const postgresCaseStore: CaseStore = {
  async listCases(input) {
    const conditions = caseConditions(input);
    return await getAdminDatabase().select()
      .from(complaintCases)
      .where(conditions.length > 0 ? and(...conditions) : undefined)
      .orderBy(desc(complaintCases.createdAt))
      .limit(input.limit)
      .offset(input.offset);
  },

  async countCases(input) {
    const conditions = caseConditions(input);
    const [row] = await getAdminDatabase().select({ count: sql<number>`count(*)::int` })
      .from(complaintCases)
      .where(conditions.length > 0 ? and(...conditions) : undefined);
    return row?.count ?? 0;
  },

  async findCase(id, executor = getAdminDatabase()) {
    const [record] = await executor.select()
      .from(complaintCases)
      .where(eq(complaintCases.id, id))
      .limit(1);
    return record ?? null;
  },

  async createCase(input, executor = getAdminDatabase()) {
    const [record] = await executor.insert(complaintCases).values(input).returning();
    return record;
  },

  async updateCase(id, input, executor = getAdminDatabase()) {
    const [record] = await executor.update(complaintCases)
      .set({
        ...input,
        resolvedAt: input.status === 'resolved' || input.status === 'dismissed'
          ? new Date()
          : null,
        updatedAt: new Date(),
      })
      .where(eq(complaintCases.id, id))
      .returning();
    return record ?? null;
  },
};

function dateFilter(value?: string): Date | undefined {
  if (!value) return undefined;
  const parsed = new Date(value);
  if (!Number.isFinite(parsed.getTime())) {
    throw new HTTPException(400, { message: 'INVALID_DATE_FILTER' });
  }
  return parsed;
}

function validateTransition(
  currentStatus: CaseStatus,
  nextStatus: CaseStatus,
  resolution?: string | null,
) {
  if (!caseTransitions[currentStatus].has(nextStatus)) {
    throw new HTTPException(409, { message: 'INVALID_CASE_TRANSITION' });
  }
  if (
    (nextStatus === 'resolved' || nextStatus === 'dismissed')
    && !resolution?.trim()
  ) {
    throw new HTTPException(422, { message: 'CASE_RESOLUTION_REQUIRED' });
  }
}

export class CaseService {
  constructor(
    private readonly store: CaseStore = postgresCaseStore,
    private readonly auditService: AuditService = new AuditService(),
  ) {}

  async overview() {
    const [openCases, underReviewCases, auditEvents] = await Promise.all([
      this.store.countCases({ status: 'open' }),
      this.store.countCases({ status: 'under_review' }),
      this.auditService.count(),
    ]);
    return {
      counts: { openCases, underReviewCases, auditEvents },
      scope: {
        cases: 'available',
        audit: 'available',
        reports: 'available',
        passengerDriverIntegration: 'deferred',
      },
    };
  }

  async list(
    status: CaseStatus | undefined,
    limit: number,
    offset: number,
    from?: string,
    to?: string,
  ) {
    const filters = { status, from: dateFilter(from), to: dateFilter(to) };
    const [items, total] = await Promise.all([
      this.store.listCases({ ...filters, limit, offset }),
      this.store.countCases(filters),
    ]);
    return { items, total, limit, offset };
  }

  async create(input: {
    adminId: string;
    requestId: string;
    payload: {
      target_type: CaseTargetType;
      target_id: string;
      ride_id?: string | null;
      category: string;
      notes: string;
    };
    reason: string;
  }) {
    return await this.auditService.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'case.create',
      targetType: 'case',
      reason: input.reason,
      payload: input.payload,
    }, async (transaction) => {
      const created = await this.store.createCase({
        targetType: input.payload.target_type,
        targetId: input.payload.target_id,
        rideId: input.payload.ride_id,
        category: input.payload.category,
        notes: input.payload.notes,
        createdBy: input.adminId,
      }, transaction);
      if (!created) {
        throw new HTTPException(500, { message: 'CASE_CREATE_FAILED' });
      }
      return created;
    });
  }

  async update(input: {
    adminId: string;
    requestId: string;
    caseId: string;
    status: CaseStatus;
    resolution?: string | null;
    reason: string;
  }) {
    return await this.auditService.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'case.update',
      targetType: 'case',
      targetId: input.caseId,
      reason: input.reason,
      payload: { status: input.status, resolution: input.resolution },
    }, async (transaction) => {
      const current = await this.store.findCase(input.caseId, transaction);
      if (!current) {
        throw new HTTPException(404, { message: 'CASE_NOT_FOUND' });
      }
      validateTransition(current.status, input.status, input.resolution);
      const updated = await this.store.updateCase(input.caseId, {
        status: input.status,
        resolution: input.resolution,
      }, transaction);
      if (!updated) {
        throw new HTTPException(404, { message: 'CASE_NOT_FOUND' });
      }
      return updated;
    }, (transaction) => this.store.findCase(input.caseId, transaction));
  }
}
