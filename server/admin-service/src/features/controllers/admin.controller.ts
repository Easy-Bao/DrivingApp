import { Context } from 'hono';
import { AdminClients } from '../clients/admin.clients.ts';
import { AdminRepository } from '../repositories/admin.repository.ts';
import { AdminService } from '../services/admin.service.ts';
import { AdminVariables } from '../../shared/middleware/auth.ts';

const adminService = new AdminService(new AdminRepository(), new AdminClients());

type AdminContext = Context<{ Variables: AdminVariables }>;

function pagination(context: Context) {
  const page = Math.max(1, Number(context.req.query('page') ?? 1));
  const limit = Math.min(100, Math.max(1, Number(context.req.query('limit') ?? 25)));
  return { limit, offset: (page - 1) * limit };
}

function mutation(context: AdminContext) {
  return {
    adminId: context.get('adminId'),
    requestId: context.req.header('Idempotency-Key') ?? '',
  };
}

export async function handleOverview(context: AdminContext) {
  return context.json(await adminService.overview());
}

export async function handleListDrivers(context: AdminContext) {
  return context.json(await adminService.listDrivers(new URL(context.req.url).searchParams));
}

export async function handleGetDriver(context: AdminContext) {
  return context.json(await adminService.getDriver(context.req.param('driverId')!));
}

export async function handleUpdateDriverApproval(context: AdminContext) {
  const body = await context.req.json() as {
    status: 'pending' | 'approved' | 'rejected';
    reason: string;
  };
  return context.json(await adminService.updateDriverApproval({
    driverId: context.req.param('driverId')!,
    ...body,
    ...mutation(context),
  }));
}

export async function handleListDocumentRequirements(context: AdminContext) {
  return context.json(await adminService.listDocumentRequirements());
}

export async function handleCreateDocumentRequirement(context: AdminContext) {
  const body = await context.req.json() as {
    name: string;
    requires_expiry: boolean;
    is_active: boolean;
    reason: string;
  };
  return context.json(await adminService.createDocumentRequirement({
    payload: body,
    reason: body.reason,
    ...mutation(context),
  }), 201);
}

export async function handleReviewDriverDocument(context: AdminContext) {
  const body = await context.req.json() as {
    status: 'pending' | 'verified' | 'rejected' | 'expired';
    expires_at?: string | null;
    notes?: string | null;
    reason: string;
  };
  return context.json(await adminService.reviewDriverDocument({
    driverId: context.req.param('driverId')!,
    requirementId: context.req.param('requirementId')!,
    payload: body,
    reason: body.reason,
    ...mutation(context),
  }));
}

export async function handleCreateCreditAdjustment(context: AdminContext) {
  const body = await context.req.json() as {
    amount_centavos: number;
    reason: string;
  };
  return context.json(await adminService.adjustDriverCredits({
    driverId: context.req.param('driverId')!,
    amountCentavos: body.amount_centavos,
    reason: body.reason,
    ...mutation(context),
  }), 201);
}

export async function handleCreateCreditRefund(context: AdminContext) {
  const body = await context.req.json() as {
    amount_centavos: number;
    reason: string;
  };
  return context.json(await adminService.refundDriverCredits({
    driverId: context.req.param('driverId')!,
    amountCentavos: body.amount_centavos,
    reason: body.reason,
    ...mutation(context),
  }), 201);
}

export async function handleListTopUps(context: AdminContext) {
  return context.json(await adminService.listTopUps(new URL(context.req.url).searchParams));
}

export async function handleReviewTopUp(context: AdminContext) {
  const body = await context.req.json() as {
    status: 'approved' | 'rejected';
    reason: string;
  };
  return context.json(await adminService.reviewTopUp({
    topUpId: context.req.param('topUpId')!,
    ...body,
    ...mutation(context),
  }));
}

export async function handleListTopUpChannels(context: AdminContext) {
  return context.json(await adminService.listTopUpChannels());
}

export async function handleCreateTopUpChannel(context: AdminContext) {
  const body = await context.req.json() as {
    name: string;
    account_name: string;
    account_reference: string;
    instructions?: string | null;
    reason: string;
  };
  return context.json(await adminService.createTopUpChannel({
    payload: body,
    reason: body.reason,
    ...mutation(context),
  }), 201);
}

export async function handleUpdateTopUpChannel(context: AdminContext) {
  const body = await context.req.json() as Record<string, unknown> & { reason: string };
  return context.json(await adminService.updateTopUpChannel({
    channelId: context.req.param('channelId')!,
    payload: body,
    reason: body.reason,
    ...mutation(context),
  }));
}

export async function handleDispatch(context: AdminContext) {
  return context.json(await adminService.dispatch());
}

export async function handleManualAssignment(context: AdminContext) {
  const body = await context.req.json() as {
    session_id: string;
    driver_id: string;
    reason: string;
  };
  return context.json(await adminService.manualAssignment({
    sessionId: body.session_id,
    driverId: body.driver_id,
    reason: body.reason,
    ...mutation(context),
  }));
}

export async function handlePricing(context: AdminContext) {
  return context.json(await adminService.pricing());
}

export async function handleScheduleCommission(context: AdminContext) {
  const body = await context.req.json() as {
    rate_basis_points: number;
    effective_at: string;
    reason: string;
  };
  return context.json(await adminService.scheduleCommission({
    rateBasisPoints: body.rate_basis_points,
    effectiveAt: new Date(body.effective_at),
    reason: body.reason,
    ...mutation(context),
  }), 201);
}

export async function handleUpdateFareRule(context: AdminContext) {
  const body = await context.req.json() as {
    base_fare: number;
    per_km_rate: number;
    per_minute_rate: number;
    minimum_fare: number;
    surge_multiplier: number;
    is_active: boolean;
    reason: string;
  };
  return context.json(await adminService.updateFareRule({
    serviceType: context.req.param('serviceType')!,
    payload: body,
    reason: body.reason,
    ...mutation(context),
  }));
}

export async function handleListZones(context: AdminContext) {
  return context.json(await adminService.zones());
}

export async function handleUpdateZone(context: AdminContext) {
  const body = await context.req.json() as {
    is_active: boolean;
    reason: string;
  };
  return context.json(await adminService.updateZone({
    psgcCode: context.req.param('psgcCode')!,
    isActive: body.is_active,
    reason: body.reason,
    ...mutation(context),
  }));
}

export async function handleListCases(context: AdminContext) {
  const { limit, offset } = pagination(context);
  return context.json(await adminService.listCases(
    context.req.query('status'),
    limit,
    offset,
  ));
}

export async function handleCreateCase(context: AdminContext) {
  const body = await context.req.json() as {
    target_type: 'ride' | 'driver' | 'passenger';
    target_id: string;
    ride_id?: string | null;
    category: string;
    notes: string;
    reason: string;
  };
  return context.json(await adminService.createCase({
    payload: body,
    reason: body.reason,
    ...mutation(context),
  }), 201);
}

export async function handleUpdateCase(context: AdminContext) {
  const body = await context.req.json() as {
    status: 'open' | 'under_review' | 'resolved' | 'dismissed';
    resolution?: string | null;
    reason: string;
  };
  return context.json(await adminService.updateCase({
    caseId: context.req.param('caseId')!,
    status: body.status,
    resolution: body.resolution,
    reason: body.reason,
    ...mutation(context),
  }));
}

export async function handleRestrictAccount(context: AdminContext) {
  const body = await context.req.json() as {
    target_type: 'driver' | 'passenger';
    target_id: string;
    case_id?: string | null;
    ends_at?: string | null;
    reason: string;
  };
  return context.json(await adminService.restrictAccount({
    targetType: body.target_type,
    targetId: body.target_id,
    caseId: body.case_id,
    endsAt: body.ends_at,
    reason: body.reason,
    ...mutation(context),
  }), 201);
}

export async function handleLiftRestriction(context: AdminContext) {
  const targetType = context.req.param('targetType');
  if (targetType !== 'driver' && targetType !== 'passenger') {
    throw new Error('Restriction target must be driver or passenger.');
  }
  const { reason } = await context.req.json() as { reason: string };
  return context.json(await adminService.liftRestriction({
    targetType,
    restrictionId: context.req.param('restrictionId')!,
    reason,
    ...mutation(context),
  }));
}

export async function handleAudits(context: AdminContext) {
  const { limit, offset } = pagination(context);
  return context.json(await adminService.audits(limit, offset));
}

export async function handleReport(context: AdminContext) {
  const type = context.req.param('type')!;
  const csv = await adminService.report(type, new URL(context.req.url).searchParams);
  context.header('Content-Type', 'text/csv; charset=utf-8');
  context.header('Content-Disposition', `attachment; filename="baobao-${type}.csv"`);
  return context.body(csv);
}

export async function handleInternalZoneCheck(context: Context) {
  const body = await context.req.json() as {
    pickup_latitude: number;
    pickup_longitude: number;
    dropoff_latitude: number;
    dropoff_longitude: number;
  };
  return context.json(await adminService.checkZones({
    pickupLatitude: body.pickup_latitude,
    pickupLongitude: body.pickup_longitude,
    dropoffLatitude: body.dropoff_latitude,
    dropoffLongitude: body.dropoff_longitude,
  }));
}

export async function handleInternalCommission(context: Context) {
  const at = context.req.query('at');
  return context.json(await adminService.currentCommission(at ? new Date(at) : undefined));
}
