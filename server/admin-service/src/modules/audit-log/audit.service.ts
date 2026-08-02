import { and, desc, eq, gte, lte, SQL, sql } from 'drizzle-orm';
import { HTTPException } from 'hono/http-exception';
import { AdminExecutor, getAdminDatabase } from '../../config/database.ts';
import {
  AdminAction,
  AdminTargetType,
  adminAuditEvents,
  adminMutationResults,
  AuditOutcome,
} from '../../db/schema/index.ts';

const sensitiveAuditKey = /password|token|secret|authorization|cookie|otp|pin/i;
const sensitiveAuditText = /\bbearer\s+\S+|(?:password|token|secret|authorization|otp|pin)\s*[:=]\s*\S+/i;

export type AuditInput = {
  actorAdminId: string;
  action: AdminAction;
  targetType: AdminTargetType;
  targetId?: string | null;
  reason?: string | null;
  beforeState?: unknown;
  afterState?: unknown;
  outcome: AuditOutcome;
  requestId: string;
};

type MutationContext = {
  adminId: string;
  requestId: string;
  action: AdminAction;
  targetType: AdminTargetType;
  targetId?: string | null;
  reason?: string | null;
  payload: unknown;
};

export type AuditStore = {
  withMutationLock<T>(
    requestId: string,
    operation: (transaction: AdminExecutor) => Promise<T>,
  ): Promise<T>;
  findMutationResult(requestId: string, executor?: AdminExecutor): Promise<
    typeof adminMutationResults.$inferSelect | null
  >;
  saveMutationResult(input: {
    requestId: string;
    action: AdminAction;
    targetType: AdminTargetType;
    targetId?: string | null;
    requestHash: string;
    response: unknown;
  }, executor?: AdminExecutor): Promise<typeof adminMutationResults.$inferSelect | null>;
  appendAudit(input: AuditInput, executor?: AdminExecutor): Promise<unknown>;
  listAudits(input: {
    outcome?: AuditOutcome;
    from?: Date;
    to?: Date;
    limit: number;
    offset: number;
  }): Promise<Array<typeof adminAuditEvents.$inferSelect>>;
  countAudits(input: { outcome?: AuditOutcome; from?: Date; to?: Date }): Promise<number>;
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

export const postgresAuditStore: AuditStore = {
  async withMutationLock<T>(
    requestId: string,
    operation: (transaction: AdminExecutor) => Promise<T>,
  ) {
    return await getAdminDatabase().transaction(async (transaction) => {
      await transaction.execute(
        sql`select pg_advisory_xact_lock(hashtext(${`admin-mutation:${requestId}`}))`,
      );
      return await operation(transaction);
    });
  },

  async findMutationResult(requestId, executor = getAdminDatabase()) {
    const [result] = await executor.select()
      .from(adminMutationResults)
      .where(eq(adminMutationResults.requestId, requestId))
      .limit(1);
    return result ?? null;
  },

  async saveMutationResult(input, executor = getAdminDatabase()) {
    const [result] = await executor.insert(adminMutationResults)
      .values(input)
      .onConflictDoNothing()
      .returning();
    return result ?? await this.findMutationResult(input.requestId, executor);
  },

  async appendAudit(input, executor = getAdminDatabase()) {
    const [event] = await executor.insert(adminAuditEvents).values(input).returning();
    return event;
  },

  async listAudits(input) {
    const conditions = auditConditions(input);
    return await getAdminDatabase().select()
      .from(adminAuditEvents)
      .where(conditions.length > 0 ? and(...conditions) : undefined)
      .orderBy(desc(adminAuditEvents.createdAt))
      .limit(input.limit)
      .offset(input.offset);
  },

  async countAudits(input) {
    const conditions = auditConditions(input);
    const [row] = await getAdminDatabase().select({ count: sql<number>`count(*)::int` })
      .from(adminAuditEvents)
      .where(conditions.length > 0 ? and(...conditions) : undefined);
    return row?.count ?? 0;
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

function normalize(value: unknown): unknown {
  if (value instanceof Date) return value.toISOString();
  if (Array.isArray(value)) return value.map(normalize);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>)
        .filter(([, entry]) => entry !== undefined)
        .sort(([left], [right]) => left.localeCompare(right))
        .map(([key, entry]) => [key, normalize(entry)]),
    );
  }
  return value;
}

async function fingerprint(payload: unknown): Promise<string> {
  const bytes = new TextEncoder().encode(JSON.stringify(normalize(payload)));
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

function sanitizeValue(value: unknown): unknown {
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'string' && sensitiveAuditText.test(value)) return '[REDACTED]';
  if (Array.isArray(value)) return value.map(sanitizeValue);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([key, entry]) => [
        key,
        sensitiveAuditKey.test(key) ? '[REDACTED]' : sanitizeValue(entry),
      ]),
    );
  }
  return value;
}

function sanitizeReason(reason?: string | null): string | null {
  if (!reason) return null;
  return sensitiveAuditText.test(reason) ? '[REDACTED]' : reason;
}

function sanitizeError(error: unknown): Record<string, unknown> {
  if (error instanceof HTTPException) {
    return {
      code: /^[A-Z][A-Z0-9_]+$/.test(error.message)
        ? error.message
        : 'REQUEST_FAILED',
      status: error.status,
    };
  }
  return { code: 'INTERNAL_ERROR' };
}

export class AuditService {
  constructor(private readonly store: AuditStore = postgresAuditStore) {}

  /** Executes and audits one Admin mutation exactly once per idempotency key. */
  async mutate<T>(
    context: MutationContext,
    operation: (transaction: AdminExecutor) => Promise<T>,
    loadBeforeState?: (transaction: AdminExecutor) => Promise<unknown>,
  ): Promise<T> {
    const requestId = context.requestId.trim();
    if (!requestId || requestId !== context.requestId || requestId.length > 200) {
      throw new HTTPException(400, { message: 'INVALID_IDEMPOTENCY_KEY' });
    }

    let beforeState: unknown = null;
    const requestHash = await fingerprint(context.payload);
    try {
      return await this.store.withMutationLock(requestId, async (transaction) => {
        const existing = await this.store.findMutationResult(requestId, transaction);
        if (existing) {
          const sameRequest = existing.action === context.action
            && existing.targetType === context.targetType
            && (existing.targetId ?? null) === (context.targetId ?? null)
            && existing.requestHash === requestHash;
          if (!sameRequest) {
            throw new HTTPException(409, { message: 'IDEMPOTENCY_KEY_REUSED' });
          }
          return existing.response as T;
        }

        beforeState = loadBeforeState ? await loadBeforeState(transaction) : null;
        const result = await operation(transaction);
        const stored = await this.store.saveMutationResult({
          requestId,
          action: context.action,
          targetType: context.targetType,
          targetId: context.targetId,
          requestHash,
          response: result,
        }, transaction);
        const response = (stored?.response as T | undefined) ?? result;
        await this.store.appendAudit({
          actorAdminId: context.adminId,
          action: context.action,
          targetType: context.targetType,
          targetId: context.targetId,
          reason: sanitizeReason(context.reason),
          beforeState: sanitizeValue(beforeState),
          afterState: sanitizeValue(response),
          outcome: 'succeeded',
          requestId,
        }, transaction);
        return response;
      });
    } catch (error) {
      await this.store.appendAudit({
        actorAdminId: context.adminId,
        action: context.action,
        targetType: context.targetType,
        targetId: context.targetId,
        reason: sanitizeReason(context.reason),
        beforeState: sanitizeValue(beforeState),
        afterState: { error: sanitizeError(error) },
        outcome: 'failed',
        requestId,
      });
      throw error;
    }
  }

  async list(
    limit: number,
    offset: number,
    outcome?: AuditOutcome,
    from?: string,
    to?: string,
  ) {
    const filters = { outcome, from: dateFilter(from), to: dateFilter(to) };
    const [items, total] = await Promise.all([
      this.store.listAudits({ ...filters, limit, offset }),
      this.store.countAudits(filters),
    ]);
    return { items, total, limit, offset };
  }

  async count(): Promise<number> {
    return await this.store.countAudits({});
  }
}
