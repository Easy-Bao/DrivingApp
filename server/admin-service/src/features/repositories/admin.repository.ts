import { and, desc, eq, gte, lte, SQL, sql } from 'drizzle-orm';
import {
  AuditOutcome,
  adminAuditEvents,
  adminMutationResults,
  CaseStatus,
  CaseTargetType,
  complaintCases,
} from '../../db/schema.ts';
import { db } from '../../shared/drizzle.ts';

export type AdminExecutor = Pick<typeof db, 'select' | 'insert' | 'update'>;

export type AuditInput = {
  actorAdminId: string;
  action: string;
  targetType: string;
  targetId?: string | null;
  reason?: string | null;
  beforeState?: unknown;
  afterState?: unknown;
  outcome: AuditOutcome;
  requestId: string;
};

function auditConditions(input: {
  outcome?: AuditOutcome;
  from?: Date;
  to?: Date;
}): SQL[] {
  return [
    input.outcome ? eq(adminAuditEvents.outcome, input.outcome) : undefined,
    input.from ? gte(adminAuditEvents.createdAt, input.from) : undefined,
    input.to ? lte(adminAuditEvents.createdAt, input.to) : undefined,
  ].filter((condition): condition is SQL => Boolean(condition));
}

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

export class AdminRepository {
  /** Serializes retries for one key and supplies one transaction to every local write. */
  async withMutationLock<T>(
    requestId: string,
    operation: (transaction: AdminExecutor) => Promise<T>,
  ): Promise<T> {
    return await db.transaction(async (transaction) => {
      await transaction.execute(
        sql`select pg_advisory_xact_lock(hashtext(${`admin-mutation:${requestId}`}))`,
      );
      return await operation(transaction);
    });
  }

  async findMutationResult(requestId: string, executor: AdminExecutor = db) {
    const [result] = await executor.select()
      .from(adminMutationResults)
      .where(eq(adminMutationResults.requestId, requestId))
      .limit(1);
    return result ?? null;
  }

  async saveMutationResult(input: {
    requestId: string;
    action: string;
    targetType: string;
    targetId?: string | null;
    requestHash: string;
    response: unknown;
  }, executor: AdminExecutor = db) {
    const [result] = await executor.insert(adminMutationResults)
      .values(input)
      .onConflictDoNothing()
      .returning();
    return result ?? await this.findMutationResult(input.requestId, executor);
  }

  async appendAudit(input: AuditInput, executor: AdminExecutor = db) {
    const [event] = await executor.insert(adminAuditEvents).values(input).returning();
    return event;
  }

  async listAudits(input: {
    outcome?: AuditOutcome;
    from?: Date;
    to?: Date;
    limit: number;
    offset: number;
  }) {
    const conditions = auditConditions(input);
    return await db.select()
      .from(adminAuditEvents)
      .where(conditions.length > 0 ? and(...conditions) : undefined)
      .orderBy(desc(adminAuditEvents.createdAt))
      .limit(input.limit)
      .offset(input.offset);
  }

  async countAudits(input: { outcome?: AuditOutcome; from?: Date; to?: Date }) {
    const conditions = auditConditions(input);
    const [row] = await db.select({ count: sql<number>`count(*)::int` })
      .from(adminAuditEvents)
      .where(conditions.length > 0 ? and(...conditions) : undefined);
    return row?.count ?? 0;
  }

  async listCases(input: {
    status?: CaseStatus;
    from?: Date;
    to?: Date;
    limit: number;
    offset: number;
  }) {
    const conditions = caseConditions(input);
    return await db.select()
      .from(complaintCases)
      .where(conditions.length > 0 ? and(...conditions) : undefined)
      .orderBy(desc(complaintCases.createdAt))
      .limit(input.limit)
      .offset(input.offset);
  }

  async countCases(input: { status?: CaseStatus; from?: Date; to?: Date }) {
    const conditions = caseConditions(input);
    const [row] = await db.select({ count: sql<number>`count(*)::int` })
      .from(complaintCases)
      .where(conditions.length > 0 ? and(...conditions) : undefined);
    return row?.count ?? 0;
  }

  async findCase(id: string, executor: AdminExecutor = db) {
    const [caseRecord] = await executor.select()
      .from(complaintCases)
      .where(eq(complaintCases.id, id))
      .limit(1);
    return caseRecord ?? null;
  }

  async createCase(input: {
    targetType: CaseTargetType;
    targetId: string;
    rideId?: string | null;
    category: string;
    notes: string;
    createdBy: string;
  }, executor: AdminExecutor = db) {
    const [caseRecord] = await executor.insert(complaintCases).values(input).returning();
    return caseRecord;
  }

  async updateCase(
    id: string,
    input: { status: CaseStatus; resolution?: string | null },
    executor: AdminExecutor = db,
  ) {
    const [caseRecord] = await executor.update(complaintCases)
      .set({
        ...input,
        resolvedAt: input.status === 'resolved' || input.status === 'dismissed'
          ? new Date()
          : null,
        updatedAt: new Date(),
      })
      .where(eq(complaintCases.id, id))
      .returning();
    return caseRecord ?? null;
  }

  async overviewCounts() {
    const [openCases] = await db.select({ count: sql<number>`count(*)::int` })
      .from(complaintCases)
      .where(eq(complaintCases.status, 'open'));
    const [underReviewCases] = await db.select({ count: sql<number>`count(*)::int` })
      .from(complaintCases)
      .where(eq(complaintCases.status, 'under_review'));
    const [auditEvents] = await db.select({ count: sql<number>`count(*)::int` })
      .from(adminAuditEvents);
    return {
      openCases: openCases?.count ?? 0,
      underReviewCases: underReviewCases?.count ?? 0,
      auditEvents: auditEvents?.count ?? 0,
    };
  }
}
