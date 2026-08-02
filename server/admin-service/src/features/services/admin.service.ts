import { HTTPException } from 'hono/http-exception';
import { AuditOutcome, CaseStatus, CaseTargetType } from '../../db/schema.ts';
import { AdminExecutor, AdminRepository } from '../repositories/admin.repository.ts';
import {
  fingerprintMutationPayload,
  sanitizeAuditError,
  sanitizeAuditReason,
  sanitizeAuditValue,
} from './mutation.service.ts';

type MutationContext = {
  adminId: string;
  requestId: string;
  action: string;
  targetType: string;
  targetId?: string | null;
  reason?: string | null;
  payload: unknown;
};

const caseTransitions: Record<CaseStatus, ReadonlySet<CaseStatus>> = {
  open: new Set(['open', 'under_review', 'resolved', 'dismissed']),
  under_review: new Set(['under_review', 'resolved', 'dismissed']),
  resolved: new Set(['resolved']),
  dismissed: new Set(['dismissed']),
};

function validateCaseTransition(
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

function dateFilter(value?: string): Date | undefined {
  if (!value) return undefined;
  const parsed = new Date(value);
  if (!Number.isFinite(parsed.getTime())) {
    throw new HTTPException(400, { message: 'INVALID_DATE_FILTER' });
  }
  return parsed;
}

function csvCell(value: unknown): string {
  if (value == null) return '';
  const text = typeof value === 'object' ? JSON.stringify(value) : String(value);
  return `"${text.replaceAll('"', '""')}"`;
}

export function rowsToCsv(rows: Array<Record<string, unknown>>): string {
  if (rows.length === 0) return '\uFEFF';
  const headers = [...new Set(rows.flatMap((row) => Object.keys(row)))];
  const records = rows.map((row) => (
    headers.map((header) => csvCell(row[header])).join(',')
  ));
  return `\uFEFF${headers.map(csvCell).join(',')}\r\n${records.join('\r\n')}\r\n`;
}

export class AdminService {
  constructor(private readonly repository: AdminRepository) {}

  /**
   * Runs an Admin-local mutation exactly once for each idempotency key. The
   * result and its audit event share one transaction, so a retry returns the
   * original response instead of repeating the case transition.
   */
  private async mutate<T>(
    context: MutationContext,
    operation: (transaction: AdminExecutor) => Promise<T>,
    loadBeforeState?: (transaction: AdminExecutor) => Promise<unknown>,
  ): Promise<T> {
    const requestId = context.requestId.trim();
    if (!requestId || requestId !== context.requestId || requestId.length > 200) {
      throw new HTTPException(400, { message: 'INVALID_IDEMPOTENCY_KEY' });
    }

    let beforeState: unknown = null;
    const requestHash = await fingerprintMutationPayload(context.payload);
    try {
      return await this.repository.withMutationLock(requestId, async (transaction) => {
        const existing = await this.repository.findMutationResult(requestId, transaction);
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
        const stored = await this.repository.saveMutationResult({
          requestId,
          action: context.action,
          targetType: context.targetType,
          targetId: context.targetId,
          requestHash,
          response: result,
        }, transaction);
        const response = (stored?.response as T | undefined) ?? result;
        await this.repository.appendAudit({
          actorAdminId: context.adminId,
          action: context.action,
          targetType: context.targetType,
          targetId: context.targetId,
          reason: sanitizeAuditReason(context.reason),
          beforeState: sanitizeAuditValue(beforeState),
          afterState: sanitizeAuditValue(response),
          outcome: 'succeeded',
          requestId,
        }, transaction);
        return response;
      });
    } catch (error) {
      await this.repository.appendAudit({
        actorAdminId: context.adminId,
        action: context.action,
        targetType: context.targetType,
        targetId: context.targetId,
        reason: sanitizeAuditReason(context.reason),
        beforeState: sanitizeAuditValue(beforeState),
        afterState: { error: sanitizeAuditError(error) },
        outcome: 'failed',
        requestId,
      });
      throw error;
    }
  }

  async overview() {
    return {
      counts: await this.repository.overviewCounts(),
      scope: {
        cases: 'available',
        audit: 'available',
        reports: 'available',
        passengerDriverIntegration: 'deferred',
      },
    };
  }

  async listCases(
    status: CaseStatus | undefined,
    limit: number,
    offset: number,
    from?: string,
    to?: string,
  ) {
    const filters = { status, from: dateFilter(from), to: dateFilter(to) };
    const [items, total] = await Promise.all([
      this.repository.listCases({ ...filters, limit, offset }),
      this.repository.countCases(filters),
    ]);
    return { items, total, limit, offset };
  }

  async createCase(input: {
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
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'case.create',
      targetType: 'case',
      reason: input.reason,
      payload: input.payload,
    }, async (transaction) => {
      const created = await this.repository.createCase({
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

  async updateCase(input: {
    adminId: string;
    requestId: string;
    caseId: string;
    status: CaseStatus;
    resolution?: string | null;
    reason: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'case.update',
      targetType: 'case',
      targetId: input.caseId,
      reason: input.reason,
      payload: { status: input.status, resolution: input.resolution },
    }, async (transaction) => {
      const current = await this.repository.findCase(input.caseId, transaction);
      if (!current) {
        throw new HTTPException(404, { message: 'CASE_NOT_FOUND' });
      }
      validateCaseTransition(current.status, input.status, input.resolution);
      const updated = await this.repository.updateCase(input.caseId, {
        status: input.status,
        resolution: input.resolution,
      }, transaction);
      if (!updated) {
        throw new HTTPException(404, { message: 'CASE_NOT_FOUND' });
      }
      return updated;
    }, (transaction) => this.repository.findCase(input.caseId, transaction));
  }

  async audits(
    limit: number,
    offset: number,
    outcome?: AuditOutcome,
    from?: string,
    to?: string,
  ) {
    const filters = { outcome, from: dateFilter(from), to: dateFilter(to) };
    const [items, total] = await Promise.all([
      this.repository.listAudits({ ...filters, limit, offset }),
      this.repository.countAudits(filters),
    ]);
    return { items, total, limit, offset };
  }

  async report(type: string, search: URLSearchParams): Promise<string> {
    const from = search.get('from') ?? undefined;
    const to = search.get('to') ?? undefined;
    if (type === 'cases') {
      const statusValue = search.get('status');
      const status = statusValue as CaseStatus | null;
      if (status && !Object.hasOwn(caseTransitions, status)) {
        throw new HTTPException(400, { message: 'INVALID_CASE_STATUS' });
      }
      const rows = await this.repository.listCases({
        status: status ?? undefined,
        from: dateFilter(from),
        to: dateFilter(to),
        limit: 10_000,
        offset: 0,
      });
      return rowsToCsv(rows as Array<Record<string, unknown>>);
    }
    if (type === 'audits') {
      const outcomeValue = search.get('status');
      const outcome = outcomeValue === 'succeeded' || outcomeValue === 'failed'
        ? outcomeValue
        : undefined;
      const rows = await this.repository.listAudits({
        outcome,
        from: dateFilter(from),
        to: dateFilter(to),
        limit: 10_000,
        offset: 0,
      });
      return rowsToCsv(rows as Array<Record<string, unknown>>);
    }
    throw new HTTPException(404, { message: 'REPORT_NOT_FOUND' });
  }
}
