import { and, desc, eq, gte, lte, sql } from 'drizzle-orm';
import { db } from '../../shared/drizzle.ts';
import {
  adminAuditEvents,
  adminMutationResults,
  commissionPolicies,
  complaintCases,
  serviceZones,
} from '../../db/schema.ts';

export type AdminExecutor = Pick<typeof db, 'select' | 'insert' | 'update'>;

export type AuditInput = {
  actorAdminId: string;
  action: string;
  targetType: string;
  targetId?: string | null;
  reason?: string | null;
  beforeState?: unknown;
  afterState?: unknown;
  outcome: 'succeeded' | 'failed';
  requestId: string;
};

export class AdminRepository {
  /** Serializes retries for one key and supplies one transaction to Admin-local writes. */
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
    if (result) return result;
    return await this.findMutationResult(input.requestId, executor);
  }

  async appendAudit(input: AuditInput, executor: AdminExecutor = db) {
    const [event] = await executor.insert(adminAuditEvents)
      .values(input)
      .returning();
    return event;
  }

  async listAudits(input: {
    outcome?: string;
    from?: Date;
    to?: Date;
    limit: number;
    offset: number;
  }) {
    const conditions = [
      input.outcome ? eq(adminAuditEvents.outcome, input.outcome) : undefined,
      input.from ? gte(adminAuditEvents.createdAt, input.from) : undefined,
      input.to ? lte(adminAuditEvents.createdAt, input.to) : undefined,
    ].filter(Boolean);
    return await db.select()
      .from(adminAuditEvents)
      .where(conditions.length > 0 ? and(...conditions as any[]) : undefined)
      .orderBy(desc(adminAuditEvents.createdAt))
      .limit(input.limit)
      .offset(input.offset);
  }

  async countAudits(input: {
    outcome?: string;
    from?: Date;
    to?: Date;
  }) {
    const conditions = [
      input.outcome ? eq(adminAuditEvents.outcome, input.outcome) : undefined,
      input.from ? gte(adminAuditEvents.createdAt, input.from) : undefined,
      input.to ? lte(adminAuditEvents.createdAt, input.to) : undefined,
    ].filter(Boolean);
    const [row] = await db.select({ count: sql<number>`count(*)::int` })
      .from(adminAuditEvents)
      .where(conditions.length > 0 ? and(...conditions as any[]) : undefined);
    return row?.count ?? 0;
  }

  async listZones() {
    return await db.select()
      .from(serviceZones)
      .orderBy(serviceZones.name);
  }

  async findZone(psgcCode: string, executor: AdminExecutor = db) {
    const [zone] = await executor.select()
      .from(serviceZones)
      .where(eq(serviceZones.psgcCode, psgcCode))
      .limit(1);
    return zone ?? null;
  }

  async setZoneActive(
    psgcCode: string,
    isActive: boolean,
    executor: AdminExecutor = db,
  ) {
    const [zone] = await executor.update(serviceZones)
      .set({ isActive, updatedAt: new Date() })
      .where(eq(serviceZones.psgcCode, psgcCode))
      .returning();
    return zone ?? null;
  }

  async listActiveZones() {
    return await db.select()
      .from(serviceZones)
      .where(eq(serviceZones.isActive, true))
      .orderBy(serviceZones.name);
  }

  async getCurrentCommission(at: Date = new Date(), executor: AdminExecutor = db) {
    const [policy] = await executor.select()
      .from(commissionPolicies)
      .where(lte(commissionPolicies.effectiveAt, at))
      .orderBy(desc(commissionPolicies.effectiveAt))
      .limit(1);
    return policy ?? null;
  }

  async listCommissionPolicies() {
    return await db.select()
      .from(commissionPolicies)
      .orderBy(desc(commissionPolicies.effectiveAt));
  }

  async createCommissionPolicy(input: {
    rateBasisPoints: number;
    effectiveAt: Date;
    createdBy: string;
    reason: string;
  }, executor: AdminExecutor = db) {
    const [policy] = await executor.insert(commissionPolicies)
      .values(input)
      .returning();
    return policy;
  }

  async listCases(input: {
    status?: string;
    from?: Date;
    to?: Date;
    limit: number;
    offset: number;
  }) {
    const conditions = [
      input.status ? eq(complaintCases.status, input.status) : undefined,
      input.from ? gte(complaintCases.createdAt, input.from) : undefined,
      input.to ? lte(complaintCases.createdAt, input.to) : undefined,
    ].filter(Boolean);
    return await db.select()
      .from(complaintCases)
      .where(conditions.length > 0 ? and(...conditions as any[]) : undefined)
      .orderBy(desc(complaintCases.createdAt))
      .limit(input.limit)
      .offset(input.offset);
  }

  async countCases(input: {
    status?: string;
    from?: Date;
    to?: Date;
  }) {
    const conditions = [
      input.status ? eq(complaintCases.status, input.status) : undefined,
      input.from ? gte(complaintCases.createdAt, input.from) : undefined,
      input.to ? lte(complaintCases.createdAt, input.to) : undefined,
    ].filter(Boolean);
    const [row] = await db.select({ count: sql<number>`count(*)::int` })
      .from(complaintCases)
      .where(conditions.length > 0 ? and(...conditions as any[]) : undefined);
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
    targetType: string;
    targetId: string;
    rideId?: string | null;
    category: string;
    notes: string;
    createdBy: string;
  }, executor: AdminExecutor = db) {
    const [caseRecord] = await executor.insert(complaintCases)
      .values(input)
      .returning();
    return caseRecord;
  }

  async updateCase(id: string, input: {
    status: string;
    resolution?: string | null;
    restrictionId?: string | null;
  }, executor: AdminExecutor = db) {
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

  async localCounts() {
    const [cases] = await db.select({ count: sql<number>`count(*)::int` })
      .from(complaintCases)
      .where(and(
        eq(complaintCases.status, 'open'),
      ));
    const [zones] = await db.select({ count: sql<number>`count(*)::int` })
      .from(serviceZones)
      .where(eq(serviceZones.isActive, true));
    return {
      openCases: cases?.count ?? 0,
      activeZones: zones?.count ?? 0,
    };
  }
}
