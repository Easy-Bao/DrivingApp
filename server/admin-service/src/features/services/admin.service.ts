import { HTTPException } from 'hono/http-exception';
import { AdminClients, ServiceName } from '../clients/admin.clients.ts';
import {
  AdminExecutor,
  AdminRepository,
} from '../repositories/admin.repository.ts';
import {
  fingerprintMutationPayload,
  sanitizeAuditError,
  sanitizeAuditReason,
  sanitizeAuditValue,
} from './mutation.service.ts';
import { isPointInZone, ZoneGeometry } from './zone.service.ts';

type MutationContext = {
  adminId: string;
  requestId: string;
  action: string;
  targetType: string;
  targetId?: string | null;
  reason?: string | null;
  payload: unknown;
};

const caseTransitions: Record<string, ReadonlySet<string>> = {
  open: new Set(['open', 'under_review', 'resolved', 'dismissed']),
  under_review: new Set(['under_review', 'resolved', 'dismissed']),
  resolved: new Set(['resolved']),
  dismissed: new Set(['dismissed']),
};

function validateCaseTransition(
  currentStatus: string,
  nextStatus: string,
  resolution?: string | null,
) {
  if (!caseTransitions[currentStatus]?.has(nextStatus)) {
    throw new HTTPException(409, { message: 'INVALID_CASE_TRANSITION' });
  }
  if (
    (nextStatus === 'resolved' || nextStatus === 'dismissed')
    && !resolution?.trim()
  ) {
    throw new HTTPException(422, { message: 'CASE_RESOLUTION_REQUIRED' });
  }
}

function listFromResponse(value: unknown): unknown[] {
  if (Array.isArray(value)) return value;
  if (value && typeof value === 'object') {
    const record = value as Record<string, unknown>;
    for (const key of ['items', 'data', 'drivers', 'topups', 'rides', 'sessions']) {
      if (Array.isArray(record[key])) return record[key] as unknown[];
    }
  }
  return [];
}

function totalFromResponse(value: unknown): number | null {
  if (Array.isArray(value)) return value.length;
  if (!value || typeof value !== 'object') return null;
  const total = (value as Record<string, unknown>).total;
  return typeof total === 'number' && Number.isSafeInteger(total) && total >= 0
    ? total
    : null;
}

function reportDate(value: string | null, endOfDay = false): Date | undefined {
  if (!value) return undefined;
  const parsed = /^\d{4}-\d{2}-\d{2}$/.test(value)
    ? new Date(`${value}T${endOfDay ? '23:59:59.999' : '00:00:00'}+08:00`)
    : new Date(value);
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
  return `\uFEFF${headers.map(csvCell).join(',')}\r\n${
    rows.map((row) => headers.map((header) => csvCell(row[header])).join(',')).join('\r\n')
  }\r\n`;
}

export class AdminService {
  constructor(
    private readonly repository: AdminRepository,
    private readonly clients: AdminClients,
  ) {}

  private async reportRows(
    service: ServiceName,
    path: string,
    search: URLSearchParams,
  ): Promise<unknown[]> {
    const pageSize = 100;
    const query = new URLSearchParams(search);
    query.set('page', '1');
    query.set('limit', String(pageSize));
    const first = await this.clients.request<unknown>(
      service,
      `${path}?${query}`,
    );
    const rows = listFromResponse(first);
    const total = totalFromResponse(first);
    if (total === null || rows.length >= total) return rows;

    for (let page = 2; rows.length < total; page += 1) {
      query.set('page', String(page));
      const items = listFromResponse(await this.clients.request<unknown>(
        service,
        `${path}?${query}`,
      ));
      if (items.length === 0) break;
      rows.push(...items);
    }
    return rows;
  }

  private async mutate<T>(
    context: MutationContext,
    operation: (transaction: AdminExecutor) => Promise<T>,
    loadBeforeState?: (transaction: AdminExecutor) => Promise<unknown>,
  ): Promise<T> {
    const requestId = context.requestId.trim();
    if (!requestId) {
      throw new HTTPException(400, { message: 'Idempotency-Key header is required.' });
    }
    if (requestId !== context.requestId || requestId.length > 200) {
      throw new HTTPException(400, { message: 'INVALID_IDEMPOTENCY_KEY' });
    }

    let beforeState: unknown = null;
    const requestHash = await fingerprintMutationPayload(context.payload);
    try {
      return await this.repository.withMutationLock(requestId, async (transaction) => {
        const existing = await this.repository.findMutationResult(
          requestId,
          transaction,
        );
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
        const response = stored?.response as T ?? result;
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
    const [drivers, rides, sessions, topups, local] = await Promise.all([
      this.clients.safeRequest<unknown>('driver', '/drivers/admin/drivers?limit=100'),
      this.clients.safeRequest<unknown>('trip', '/rides/active'),
      this.clients.safeRequest<unknown>('bidding', '/bids/active'),
      this.clients.safeRequest<unknown>('driver', '/drivers/admin/topups?status=pending'),
      this.repository.localCounts(),
    ]);

    return {
      counts: {
        drivers: drivers.ok
          ? totalFromResponse(drivers.data) ?? listFromResponse(drivers.data).length
          : null,
        active_rides: rides.ok ? listFromResponse(rides.data).length : null,
        open_requests: sessions.ok ? listFromResponse(sessions.data).length : null,
        pending_topups: topups.ok
          ? totalFromResponse(topups.data) ?? listFromResponse(topups.data).length
          : null,
        open_cases: local.openCases,
        active_zones: local.activeZones,
      },
      service_health: {
        driver: drivers.ok ? 'ok' : drivers.error,
        trip: rides.ok ? 'ok' : rides.error,
        bidding: sessions.ok ? 'ok' : sessions.error,
      },
      refreshed_at: new Date().toISOString(),
    };
  }

  async listDrivers(search: URLSearchParams) {
    const query = new URLSearchParams(search);
    if (query.has('status') && !query.has('approvalStatus')) {
      query.set('approvalStatus', query.get('status')!);
      query.delete('status');
    }
    return await this.clients.request<unknown>('driver', `/drivers/admin/drivers?${query}`);
  }

  async getDriver(driverId: string) {
    const [status, documents, credits, restrictions] = await Promise.all([
      this.clients.request<unknown>(
        'driver',
        `/drivers/admin/drivers/${driverId}/operating-status`,
      ),
      this.clients.request<unknown>(
        'driver',
        `/drivers/admin/drivers/${driverId}/documents`,
      ),
      this.clients.request<unknown>(
        'driver',
        `/drivers/admin/drivers/${driverId}/credits`,
      ),
      this.clients.request<unknown>(
        'driver',
        `/drivers/admin/drivers/${driverId}/restrictions`,
      ),
    ]);
    return { status, documents, credits, restrictions };
  }

  async updateDriverApproval(input: {
    driverId: string;
    status: string;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'driver.approval.updated',
      targetType: 'driver',
      targetId: input.driverId,
      reason: input.reason,
      payload: { status: input.status, reason: input.reason },
    }, () => this.clients.request(
      'driver',
      `/drivers/admin/drivers/${input.driverId}/approval`,
      {
        method: 'PATCH',
        headers: {
          'Idempotency-Key': input.requestId,
          'X-Admin-Id': input.adminId,
        },
        body: JSON.stringify({ status: input.status, reason: input.reason }),
      },
    ), () => this.getDriver(input.driverId));
  }

  async listDocumentRequirements() {
    return await this.clients.request<unknown>('driver', '/drivers/admin/document-requirements');
  }

  async createDocumentRequirement(input: {
    payload: Record<string, unknown>;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'driver.document_requirement.created',
      targetType: 'document_requirement',
      reason: input.reason,
      payload: { ...input.payload, reason: input.reason },
    }, () => this.clients.request('driver', '/drivers/admin/document-requirements', {
      method: 'POST',
      headers: {
        'Idempotency-Key': input.requestId,
        'X-Admin-Id': input.adminId,
      },
      body: JSON.stringify({
        name: input.payload.name,
        requiresExpiry: input.payload.requires_expiry,
        isActive: input.payload.is_active,
      }),
    }));
  }

  async updateDocumentRequirement(input: {
    requirementId: string;
    payload: Record<string, unknown>;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'driver.document_requirement.updated',
      targetType: 'document_requirement',
      targetId: input.requirementId,
      reason: input.reason,
      payload: { ...input.payload, reason: input.reason },
    }, () => this.clients.request(
      'driver',
      `/drivers/admin/document-requirements/${input.requirementId}`,
      {
        method: 'PATCH',
        headers: {
          'Idempotency-Key': input.requestId,
          'X-Admin-Id': input.adminId,
        },
        body: JSON.stringify({
          name: input.payload.name,
          requiresExpiry: input.payload.requires_expiry,
          isActive: input.payload.is_active,
        }),
      },
    ), async () => {
      const requirements = listFromResponse(await this.listDocumentRequirements());
      return requirements.find((requirement) => (
        typeof requirement === 'object'
        && requirement !== null
        && (requirement as Record<string, unknown>).id === input.requirementId
      )) ?? null;
    });
  }

  async reviewDriverDocument(input: {
    driverId: string;
    requirementId: string;
    payload: Record<string, unknown>;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'driver.document.reviewed',
      targetType: 'driver',
      targetId: input.driverId,
      reason: input.reason,
      payload: {
        requirementId: input.requirementId,
        ...input.payload,
        reason: input.reason,
      },
    }, () => this.clients.request(
      'driver',
      `/drivers/admin/drivers/${input.driverId}/documents/${input.requirementId}`,
      {
        method: 'PUT',
        headers: {
          'Idempotency-Key': input.requestId,
          'X-Admin-Id': input.adminId,
        },
        body: JSON.stringify({
          status: input.payload.status,
          expiresAt: input.payload.expires_at,
          notes: input.payload.notes,
        }),
      },
    ), () => this.getDriver(input.driverId));
  }

  async adjustDriverCredits(input: {
    driverId: string;
    amountCentavos: number;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'credit.adjusted',
      targetType: 'driver_wallet',
      targetId: input.driverId,
      reason: input.reason,
      payload: {
        amountCentavos: input.amountCentavos,
        reason: input.reason,
      },
    }, () => this.clients.request(
      'driver',
      `/drivers/admin/drivers/${input.driverId}/credits/adjustments`,
      {
        method: 'POST',
        headers: {
          'Idempotency-Key': input.requestId,
          'X-Admin-Id': input.adminId,
        },
        body: JSON.stringify({
          amountCentavos: input.amountCentavos,
          reason: input.reason,
        }),
      },
    ), () => this.clients.request(
      'driver',
      `/drivers/admin/drivers/${input.driverId}/credits`,
    ));
  }

  async refundDriverCredits(input: {
    driverId: string;
    amountCentavos: number;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'credit.refunded',
      targetType: 'driver_wallet',
      targetId: input.driverId,
      reason: input.reason,
      payload: {
        amountCentavos: input.amountCentavos,
        reason: input.reason,
      },
    }, () => this.clients.request(
      'driver',
      `/drivers/admin/drivers/${input.driverId}/credits/refunds`,
      {
        method: 'POST',
        headers: {
          'Idempotency-Key': input.requestId,
          'X-Admin-Id': input.adminId,
        },
        body: JSON.stringify({
          amountCentavos: input.amountCentavos,
          reason: input.reason,
        }),
      },
    ), () => this.clients.request(
      'driver',
      `/drivers/admin/drivers/${input.driverId}/credits`,
    ));
  }

  async listTopUps(search: URLSearchParams) {
    return await this.clients.request<unknown>('driver', `/drivers/admin/topups?${search}`);
  }

  async reviewTopUp(input: {
    topUpId: string;
    status: string;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: `topup.${input.status}`,
      targetType: 'topup',
      targetId: input.topUpId,
      reason: input.reason,
      payload: { status: input.status, reason: input.reason },
    }, () => this.clients.request(
      'driver',
      `/drivers/admin/topups/${input.topUpId}/${input.status === 'approved' ? 'approve' : 'reject'}`,
      {
      method: 'POST',
        headers: {
          'Idempotency-Key': input.requestId,
          'X-Admin-Id': input.adminId,
        },
        body: JSON.stringify({ reason: input.reason }),
      },
    ));
  }

  async listTopUpChannels() {
    return await this.clients.request<unknown>('driver', '/drivers/admin/topup-channels');
  }

  async createTopUpChannel(input: {
    payload: Record<string, unknown>;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'topup_channel.created',
      targetType: 'topup_channel',
      reason: input.reason,
      payload: { ...input.payload, reason: input.reason },
    }, () => this.clients.request('driver', '/drivers/admin/topup-channels', {
      method: 'POST',
      headers: {
        'Idempotency-Key': input.requestId,
        'X-Admin-Id': input.adminId,
      },
      body: JSON.stringify({
        name: input.payload.name,
        accountName: input.payload.account_name,
        accountReference: input.payload.account_reference,
        instructions: input.payload.instructions,
      }),
    }));
  }

  async updateTopUpChannel(input: {
    channelId: string;
    payload: Record<string, unknown>;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'topup_channel.updated',
      targetType: 'topup_channel',
      targetId: input.channelId,
      reason: input.reason,
      payload: { ...input.payload, reason: input.reason },
    }, () => this.clients.request(
      'driver',
      `/drivers/admin/topup-channels/${input.channelId}`,
      {
        method: 'PATCH',
        headers: {
          'Idempotency-Key': input.requestId,
          'X-Admin-Id': input.adminId,
        },
        body: JSON.stringify({
          name: input.payload.name,
          accountName: input.payload.account_name,
          accountReference: input.payload.account_reference,
          instructions: input.payload.instructions,
          isActive: input.payload.is_active,
        }),
      },
    ), async () => {
      const channels = listFromResponse(await this.listTopUpChannels());
      return channels.find((channel) => (
        typeof channel === 'object'
        && channel !== null
        && (channel as Record<string, unknown>).id === input.channelId
      )) ?? null;
    });
  }

  async dispatch() {
    const [sessions, rides, drivers] = await Promise.all([
      this.clients.safeRequest<unknown>('bidding', '/bids/active'),
      this.clients.safeRequest<unknown>('trip', '/rides/active'),
      this.clients.safeRequest<unknown>('driver', '/drivers/online'),
    ]);
    return {
      sessions: sessions.ok ? listFromResponse(sessions.data) : [],
      rides: rides.ok ? listFromResponse(rides.data) : [],
      drivers: drivers.ok ? listFromResponse(drivers.data) : [],
      service_health: {
        bidding: sessions.ok ? 'ok' : sessions.error,
        trip: rides.ok ? 'ok' : rides.error,
        driver: drivers.ok ? 'ok' : drivers.error,
      },
      refreshed_at: new Date().toISOString(),
    };
  }

  async manualAssignment(input: {
    sessionId: string;
    driverId: string;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'dispatch.manual_assignment',
      targetType: 'bid_session',
      targetId: input.sessionId,
      reason: input.reason,
      payload: { driverId: input.driverId, reason: input.reason },
    }, () => this.clients.request(
      'bidding',
      `/bids/internal/${input.sessionId}/assign`,
      {
        method: 'POST',
        headers: { 'Idempotency-Key': input.requestId },
        body: JSON.stringify({
          driver_id: input.driverId,
          admin_id: input.adminId,
          reason: input.reason,
        }),
      },
    ));
  }

  async pricing() {
    const [commission, policies, fare] = await Promise.all([
      this.repository.getCurrentCommission(),
      this.repository.listCommissionPolicies(),
      this.clients.safeRequest<unknown>('fare', '/fares/admin/pricing'),
    ]);
    return {
      commission,
      commission_history: policies,
      fare_rules: fare.ok ? fare.data : [],
      fare_service: fare.ok ? 'ok' : fare.error,
    };
  }

  async scheduleCommission(input: {
    rateBasisPoints: number;
    effectiveAt: Date;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'pricing.commission.scheduled',
      targetType: 'commission_policy',
      reason: input.reason,
      payload: {
        rateBasisPoints: input.rateBasisPoints,
        effectiveAt: input.effectiveAt,
        reason: input.reason,
      },
    }, async (transaction) => {
      const completedRides = listFromResponse(await this.clients.request(
        'trip',
        '/rides/admin/report?status=completed',
      ));
      const earliest = Date.now() + 30 * 24 * 60 * 60 * 1000;
      if (completedRides.length > 0 && input.effectiveAt.getTime() < earliest) {
        throw new HTTPException(400, {
          message: 'Commission changes require at least 30 days notice.',
        });
      }
      return await this.repository.createCommissionPolicy({
        rateBasisPoints: input.rateBasisPoints,
        effectiveAt: input.effectiveAt,
        createdBy: input.adminId,
        reason: input.reason,
      }, transaction);
    }, (transaction) => this.repository.getCurrentCommission(
      new Date(),
      transaction,
    ));
  }

  async updateFareRule(input: {
    serviceType: string;
    payload: Record<string, unknown>;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'pricing.fare_rule.updated',
      targetType: 'fare_rule',
      targetId: input.serviceType,
      reason: input.reason,
      payload: { ...input.payload, reason: input.reason },
    }, () => this.clients.request('fare', `/fares/admin/pricing/${input.serviceType}`, {
      method: 'PUT',
      headers: { 'Idempotency-Key': input.requestId },
      body: JSON.stringify({
        ...input.payload,
        admin_id: input.adminId,
      }),
    }), async () => {
      const rules = listFromResponse(await this.clients.request('fare', '/fares/admin/pricing'));
      return rules.find((rule) => (
        typeof rule === 'object'
        && rule !== null
        && (rule as Record<string, unknown>).serviceType === input.serviceType
      )) ?? null;
    });
  }

  async zones() {
    return await this.repository.listZones();
  }

  async updateZone(input: {
    psgcCode: string;
    isActive: boolean;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: input.isActive ? 'zone.activated' : 'zone.deactivated',
      targetType: 'service_zone',
      targetId: input.psgcCode,
      reason: input.reason,
      payload: { isActive: input.isActive, reason: input.reason },
    }, async (transaction) => {
      const current = await this.repository.findZone(input.psgcCode, transaction);
      if (!current) throw new HTTPException(404, { message: 'Service zone not found.' });
      if (input.isActive && !current.geometry) {
        throw new HTTPException(409, {
          message: 'This barangay has no verified or interim geometry and cannot be activated.',
        });
      }
      return await this.repository.setZoneActive(
        input.psgcCode,
        input.isActive,
        transaction,
      );
    }, (transaction) => this.repository.findZone(input.psgcCode, transaction));
  }

  async listCases(
    status: string | undefined,
    limit: number,
    offset: number,
    fromValue?: string,
    toValue?: string,
  ) {
    const from = reportDate(fromValue ?? null);
    const to = reportDate(toValue ?? null, true);
    const input = { status, from, to };
    const [items, total] = await Promise.all([
      this.repository.listCases({ ...input, limit, offset }),
      this.repository.countCases(input),
    ]);
    return {
      items,
      page: Math.floor(offset / limit) + 1,
      limit,
      total,
    };
  }

  async createCase(input: {
    payload: {
      target_type: string;
      target_id: string;
      ride_id?: string | null;
      category: string;
      notes: string;
    };
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'case.created',
      targetType: input.payload.target_type,
      targetId: input.payload.target_id,
      reason: input.reason,
      payload: { ...input.payload, reason: input.reason },
    }, (transaction) => this.repository.createCase({
      targetType: input.payload.target_type,
      targetId: input.payload.target_id,
      rideId: input.payload.ride_id,
      category: input.payload.category,
      notes: input.payload.notes,
      createdBy: input.adminId,
    }, transaction));
  }

  async updateCase(input: {
    caseId: string;
    status: string;
    resolution?: string | null;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'case.updated',
      targetType: 'case',
      targetId: input.caseId,
      reason: input.reason,
      payload: {
        status: input.status,
        resolution: input.resolution,
        reason: input.reason,
      },
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
      if (!updated) throw new HTTPException(404, { message: 'CASE_NOT_FOUND' });
      return updated;
    }, (transaction) => this.repository.findCase(input.caseId, transaction));
  }

  async restrictAccount(input: {
    targetType: 'driver' | 'passenger';
    targetId: string;
    caseId?: string | null;
    endsAt?: string | null;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    const endsAt = input.endsAt ? new Date(input.endsAt) : null;
    const service = input.targetType as ServiceName;
    const path = input.targetType === 'driver'
      ? `/drivers/admin/drivers/${input.targetId}/restrictions`
      : `/passengers/admin/${input.targetId}/restrictions`;
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'account.restricted',
      targetType: input.targetType,
      targetId: input.targetId,
      reason: input.reason,
      payload: {
        caseId: input.caseId,
        endsAt: input.endsAt,
        reason: input.reason,
      },
    }, async (transaction) => {
      if (
        endsAt
        && (!Number.isFinite(endsAt.getTime()) || endsAt <= new Date())
      ) {
        throw new HTTPException(422, { message: 'INVALID_EXPIRY' });
      }
      const linkedCase = input.caseId
        ? await this.repository.findCase(input.caseId, transaction)
        : null;
      if (input.caseId && !linkedCase) {
        throw new HTTPException(404, { message: 'CASE_NOT_FOUND' });
      }
      if (linkedCase) {
        validateCaseTransition(
          linkedCase.status,
          'under_review',
          linkedCase.resolution,
        );
        if (linkedCase.targetType === 'ride') {
          const ride = await this.clients.request<Record<string, unknown>>(
            'trip',
            `/rides/${encodeURIComponent(linkedCase.targetId)}`,
          );
          const linkedAccountId = input.targetType === 'driver'
            ? ride.driver_id ?? ride.driverId
            : ride.passenger_id ?? ride.passengerId;
          if (linkedAccountId !== input.targetId) {
            throw new HTTPException(409, { message: 'CASE_TARGET_MISMATCH' });
          }
        } else if (
          linkedCase.targetType !== input.targetType
          || linkedCase.targetId !== input.targetId
        ) {
          throw new HTTPException(409, { message: 'CASE_TARGET_MISMATCH' });
        }
      }
      const restriction = await this.clients.request<Record<string, unknown>>(
        service,
        path,
        {
          method: 'POST',
          headers: {
            'Idempotency-Key': input.requestId,
            'X-Admin-Id': input.adminId,
          },
          body: JSON.stringify({
            caseId: input.caseId,
            expiresAt: input.endsAt,
            case_id: input.caseId,
            ends_at: input.endsAt,
            reason: input.reason,
            admin_id: input.adminId,
          }),
        },
      );
      if (input.caseId) {
        const restrictionId = restriction.id;
        if (typeof restrictionId !== 'string' || !restrictionId.trim()) {
          throw new HTTPException(502, {
            message: 'INVALID_RESTRICTION_RESPONSE',
          });
        }
        const updatedCase = await this.repository.updateCase(input.caseId, {
          status: 'under_review',
          restrictionId,
        }, transaction);
        if (!updatedCase) {
          throw new HTTPException(404, { message: 'CASE_NOT_FOUND' });
        }
      }
      return restriction;
    });
  }

  async liftRestriction(input: {
    targetType: 'driver' | 'passenger';
    restrictionId: string;
    reason: string;
    adminId: string;
    requestId: string;
  }) {
    const service = input.targetType as ServiceName;
    const path = input.targetType === 'driver'
      ? `/drivers/admin/restrictions/${input.restrictionId}/lift`
      : `/passengers/admin/restrictions/${input.restrictionId}/lift`;
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'account.restriction_lifted',
      targetType: input.targetType,
      targetId: input.restrictionId,
      reason: input.reason,
      payload: { reason: input.reason },
    }, () => this.clients.request(service, path, {
      method: 'POST',
      headers: {
        'Idempotency-Key': input.requestId,
        'X-Admin-Id': input.adminId,
      },
      body: JSON.stringify({
        reason: input.reason,
        admin_id: input.adminId,
      }),
    }));
  }

  async audits(
    limit: number,
    offset: number,
    outcome?: string,
    fromValue?: string,
    toValue?: string,
  ) {
    const from = reportDate(fromValue ?? null);
    const to = reportDate(toValue ?? null, true);
    const input = { outcome, from, to };
    const [items, total] = await Promise.all([
      this.repository.listAudits({ ...input, limit, offset }),
      this.repository.countAudits(input),
    ]);
    return {
      items,
      page: Math.floor(offset / limit) + 1,
      limit,
      total,
    };
  }

  async checkZones(input: {
    pickupLatitude: number;
    pickupLongitude: number;
    dropoffLatitude: number;
    dropoffLongitude: number;
  }) {
    const activeZones = await this.repository.listActiveZones();
    if (activeZones.length === 0) {
      return {
        allowed: false,
        code: 'SERVICE_ZONE_NOT_CONFIGURED',
        message: 'No Pagadian pilot barangays are active.',
      };
    }
    const pickupZone = activeZones.find((zone) => zone.geometry && isPointInZone(
      [input.pickupLongitude, input.pickupLatitude],
      zone.geometry as ZoneGeometry,
    ));
    const dropoffZone = activeZones.find((zone) => zone.geometry && isPointInZone(
      [input.dropoffLongitude, input.dropoffLatitude],
      zone.geometry as ZoneGeometry,
    ));
    return {
      allowed: Boolean(pickupZone && dropoffZone),
      code: pickupZone && dropoffZone ? 'ALLOWED' : 'OUTSIDE_SERVICE_ZONE',
      pickup_zone: pickupZone
        ? { psgc_code: pickupZone.psgcCode, name: pickupZone.name }
        : null,
      dropoff_zone: dropoffZone
        ? { psgc_code: dropoffZone.psgcCode, name: dropoffZone.name }
        : null,
    };
  }

  async currentCommission(at?: Date) {
    const policy = await this.repository.getCurrentCommission(at);
    return {
      rate_basis_points: policy?.rateBasisPoints ?? 1000,
      effective_at: policy?.effectiveAt?.toISOString() ?? new Date(0).toISOString(),
      policy_id: policy?.id ?? null,
    };
  }

  async report(type: string, search: URLSearchParams): Promise<string> {
    const reportStatuses: Record<string, string[]> = {
      trips: ['requested', 'accepted', 'arrived', 'in_transit', 'completed', 'canceled'],
      commissions: ['cash_pending', 'cash_received', 'cash_disputed', 'canceled'],
      topups: ['pending', 'approved', 'rejected'],
      compliance: ['pending', 'approved', 'rejected'],
      cases: ['open', 'under_review', 'resolved', 'dismissed'],
    };
    const allowedStatuses = reportStatuses[type];
    if (!allowedStatuses) {
      throw new HTTPException(404, { message: 'Report type not found.' });
    }
    const status = search.get('status');
    if (status && !allowedStatuses.includes(status)) {
      throw new HTTPException(400, { message: 'INVALID_REPORT_STATUS' });
    }
    const from = reportDate(search.get('from'));
    const to = reportDate(search.get('to'), true);
    if (from && to && from > to) {
      throw new HTTPException(400, { message: 'INVALID_DATE_RANGE' });
    }
    let rows: unknown[];
    if (type === 'cases') {
      rows = [];
      const limit = 1_000;
      for (let offset = 0; ; offset += limit) {
        const batch = await this.repository.listCases({
          status: search.get('status') ?? undefined,
          from,
          to,
          limit,
          offset,
        });
        rows.push(...batch);
        if (batch.length < limit) break;
      }
    } else {
      const sources: Record<string, [ServiceName, string]> = {
        trips: ['trip', '/rides/admin/report'],
        commissions: ['fare', '/fares/admin/transactions'],
        topups: ['driver', '/drivers/admin/topups'],
        compliance: ['driver', '/drivers/admin/drivers'],
      };
      const source = sources[type];
      const sourceSearch = new URLSearchParams(search);
      if (from) sourceSearch.set('from', from.toISOString());
      if (to) sourceSearch.set('to', to.toISOString());
      if (type === 'compliance' && status) {
        sourceSearch.delete('status');
        sourceSearch.set('approvalStatus', status);
      }
      rows = await this.reportRows(source[0], source[1], sourceSearch);
    }
    return rowsToCsv(rows as Array<Record<string, unknown>>);
  }
}
