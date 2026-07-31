import { HTTPException } from 'hono/http-exception';
import { AdminClients, ServiceName } from '../clients/admin.clients.ts';
import { AdminRepository } from '../repositories/admin.repository.ts';
import { isPointInZone, ZoneGeometry } from './zone.service.ts';

type MutationContext = {
  adminId: string;
  requestId: string;
  action: string;
  targetType: string;
  targetId?: string | null;
  reason?: string | null;
};

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

  private async mutate<T>(
    context: MutationContext,
    operation: () => Promise<T>,
    loadBeforeState?: () => Promise<unknown>,
  ): Promise<T> {
    if (!context.requestId) {
      throw new HTTPException(400, { message: 'Idempotency-Key header is required.' });
    }
    const existing = await this.repository.findMutationResult(context.requestId);
    if (existing) {
      if (existing.action !== context.action) {
        throw new HTTPException(409, {
          message: 'Idempotency-Key was already used for another operation.',
        });
      }
      return existing.response as T;
    }

    let beforeState: unknown = null;
    try {
      beforeState = loadBeforeState ? await loadBeforeState() : null;
      const result = await operation();
      const stored = await this.repository.saveMutationResult({
        requestId: context.requestId,
        action: context.action,
        response: result,
      });
      const response = stored?.response as T ?? result;
      await this.repository.appendAudit({
        actorAdminId: context.adminId,
        action: context.action,
        targetType: context.targetType,
        targetId: context.targetId,
        reason: context.reason,
        beforeState,
        afterState: response,
        outcome: 'succeeded',
        requestId: context.requestId,
      });
      return response;
    } catch (error) {
      await this.repository.appendAudit({
        actorAdminId: context.adminId,
        action: context.action,
        targetType: context.targetType,
        targetId: context.targetId,
        reason: context.reason,
        beforeState,
        afterState: {
          error: error instanceof Error ? error.message : 'Unknown error',
        },
        outcome: 'failed',
        requestId: context.requestId,
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
        drivers: drivers.ok ? listFromResponse(drivers.data).length : null,
        active_rides: rides.ok ? listFromResponse(rides.data).length : null,
        open_requests: sessions.ok ? listFromResponse(sessions.data).length : null,
        pending_topups: topups.ok ? listFromResponse(topups.data).length : null,
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
    }, () => this.clients.request('driver', '/drivers/admin/document-requirements', {
      method: 'POST',
      headers: {
        'Idempotency-Key': input.requestId,
        'X-Admin-Id': input.adminId,
      },
      body: JSON.stringify({ name: input.payload.name }),
    }));
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
    return await this.mutate({
      adminId: input.adminId,
      requestId: input.requestId,
      action: 'pricing.commission.scheduled',
      targetType: 'commission_policy',
      reason: input.reason,
    }, () => this.repository.createCommissionPolicy({
      rateBasisPoints: input.rateBasisPoints,
      effectiveAt: input.effectiveAt,
      createdBy: input.adminId,
      reason: input.reason,
    }), () => this.repository.getCurrentCommission());
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
    }, async () => {
      const current = await this.repository.findZone(input.psgcCode);
      if (!current) throw new HTTPException(404, { message: 'Service zone not found.' });
      if (input.isActive && !current.geometry) {
        throw new HTTPException(409, {
          message: 'This barangay has no verified or interim geometry and cannot be activated.',
        });
      }
      return await this.repository.setZoneActive(input.psgcCode, input.isActive);
    }, () => this.repository.findZone(input.psgcCode));
  }

  async listCases(status: string | undefined, limit: number, offset: number) {
    return await this.repository.listCases({ status, limit, offset });
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
    }, () => this.repository.createCase({
      targetType: input.payload.target_type,
      targetId: input.payload.target_id,
      rideId: input.payload.ride_id,
      category: input.payload.category,
      notes: input.payload.notes,
      createdBy: input.adminId,
    }));
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
    }, async () => {
      const updated = await this.repository.updateCase(input.caseId, {
        status: input.status,
        resolution: input.resolution,
      });
      if (!updated) throw new HTTPException(404, { message: 'Complaint case not found.' });
      return updated;
    }, () => this.repository.findCase(input.caseId));
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
    }, async () => {
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
        await this.repository.updateCase(input.caseId, {
          status: 'under_review',
          restrictionId: String(restriction.id ?? ''),
        });
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

  async audits(limit: number, offset: number) {
    return await this.repository.listAudits(limit, offset);
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
    let rows: unknown[];
    if (type === 'cases') {
      rows = await this.repository.listCases({
        status: search.get('status') ?? undefined,
        limit: 10_000,
        offset: 0,
      });
    } else {
      const sources: Record<string, [ServiceName, string]> = {
        trips: ['trip', `/rides/admin/report?${search}`],
        commissions: ['fare', `/fares/admin/transactions?${search}`],
        topups: ['driver', `/drivers/admin/topups?${search}`],
        compliance: ['driver', `/drivers/admin/drivers?${search}`],
      };
      const source = sources[type];
      if (!source) throw new HTTPException(404, { message: 'Report type not found.' });
      rows = listFromResponse(await this.clients.request(source[0], source[1]));
    }
    return rowsToCsv(rows as Array<Record<string, unknown>>);
  }
}
