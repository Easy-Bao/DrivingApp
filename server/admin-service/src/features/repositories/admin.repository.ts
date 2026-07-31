import { and, desc, eq, lte, sql } from 'drizzle-orm';
import { db } from '../../shared/drizzle.ts';
import {
  adminAuditEvents,
  adminMutationResults,
  commissionPolicies,
  complaintCases,
  serviceZones,
} from '../../db/schema.ts';

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
  async findMutationResult(requestId: string) {
    const [result] = await db.select()
      .from(adminMutationResults)
      .where(eq(adminMutationResults.requestId, requestId))
      .limit(1);
    return result ?? null;
  }

  async saveMutationResult(input: {
    requestId: string;
    action: string;
    response: unknown;
  }) {
    const [result] = await db.insert(adminMutationResults)
      .values(input)
      .onConflictDoNothing()
      .returning();
    if (result) return result;
    return await this.findMutationResult(input.requestId);
  }

  async appendAudit(input: AuditInput) {
    const [event] = await db.insert(adminAuditEvents)
      .values(input)
      .returning();
    return event;
  }

  async listAudits(limit: number, offset: number) {
    return await db.select()
      .from(adminAuditEvents)
      .orderBy(desc(adminAuditEvents.createdAt))
      .limit(limit)
      .offset(offset);
  }

  async listZones() {
    return await db.select()
      .from(serviceZones)
      .orderBy(serviceZones.name);
  }

  async findZone(psgcCode: string) {
    const [zone] = await db.select()
      .from(serviceZones)
      .where(eq(serviceZones.psgcCode, psgcCode))
      .limit(1);
    return zone ?? null;
  }

  async setZoneActive(psgcCode: string, isActive: boolean) {
    const [zone] = await db.update(serviceZones)
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

  async getCurrentCommission(at: Date = new Date()) {
    const [policy] = await db.select()
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
  }) {
    const [policy] = await db.insert(commissionPolicies)
      .values(input)
      .returning();
    return policy;
  }

  async listCases(input: {
    status?: string;
    limit: number;
    offset: number;
  }) {
    return await db.select()
      .from(complaintCases)
      .where(input.status ? eq(complaintCases.status, input.status) : undefined)
      .orderBy(desc(complaintCases.createdAt))
      .limit(input.limit)
      .offset(input.offset);
  }

  async findCase(id: string) {
    const [caseRecord] = await db.select()
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
  }) {
    const [caseRecord] = await db.insert(complaintCases)
      .values(input)
      .returning();
    return caseRecord;
  }

  async updateCase(id: string, input: {
    status: string;
    resolution?: string | null;
    restrictionId?: string | null;
  }) {
    const [caseRecord] = await db.update(complaintCases)
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
