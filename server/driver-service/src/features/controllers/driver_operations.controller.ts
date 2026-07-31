import { Context } from 'hono';
import { DriverAuthEnvironment } from '../../shared/middleware/auth.ts';
import { DriverDomainError } from '../entities/driver_operations.types.ts';
import { driverOperationsService } from '../driver.dependencies.ts';

function requireIdempotencyKey(context: Context): string {
  const key = context.req.header('Idempotency-Key')?.trim();
  if (!key || key.length > 200) {
    throw new DriverDomainError(
      422,
      'INVALID_ACTOR',
      'A valid Idempotency-Key header is required',
    );
  }
  return key;
}

function requireAdminActor(context: Context): string {
  const actorId = context.req.header('x-admin-id')?.trim();
  if (!actorId || actorId.length > 128) {
    throw new DriverDomainError(
      422,
      'INVALID_IDEMPOTENCY_KEY',
      'A valid x-admin-id header is required',
    );
  }
  return actorId;
}

function internalActor(context: Context): string {
  return context.req.header('x-service-name')?.trim().slice(0, 128)
    || 'internal-service';
}

function validatedJson<T = any>(context: Context): T {
  return context.req.valid('json' as never) as T;
}

function validatedQuery<T = any>(context: Context): T {
  return context.req.valid('query' as never) as T;
}

function pagination(context: Context) {
  const query = validatedQuery<{ page: number; limit: number }>(context);
  return {
    page: query.page,
    limit: query.limit,
  };
}

export async function handleGetOwnOperatingStatus(
  context: Context<DriverAuthEnvironment>,
) {
  return context.json(
    await driverOperationsService.getOperatingStatus(context.get('driverId')),
    200,
  );
}

export async function handleUpdateOwnOnlineStatus(
  context: Context<DriverAuthEnvironment>,
) {
  const payload = validatedJson(context);
  return context.json(
    await driverOperationsService.updateOnlineStatus(
      context.get('driverId'),
      payload,
    ),
    200,
  );
}

export async function handleGetOwnWallet(context: Context<DriverAuthEnvironment>) {
  return context.json(
    await driverOperationsService.getWallet(context.get('driverId')),
    200,
  );
}

export async function handleGetOwnLedger(context: Context<DriverAuthEnvironment>) {
  const { page, limit } = pagination(context);
  return context.json(
    await driverOperationsService.listLedger(
      context.get('driverId'),
      page,
      limit,
    ),
    200,
  );
}

export async function handleGetOwnTopupChannels(context: Context) {
  return context.json(await driverOperationsService.listTopupChannels(false), 200);
}

export async function handleSubmitOwnTopup(
  context: Context<DriverAuthEnvironment>,
) {
  const payload = validatedJson(context);
  const result = await driverOperationsService.submitTopup(
    context.get('driverId'),
    payload,
    requireIdempotencyKey(context),
  );
  return context.json(result, 201);
}

export async function handleListOwnTopups(
  context: Context<DriverAuthEnvironment>,
) {
  const { page, limit } = pagination(context);
  return context.json(
    await driverOperationsService.listDriverTopups(
      context.get('driverId'),
      page,
      limit,
    ),
    200,
  );
}

export async function handleListAdminDrivers(context: Context) {
  const { page, limit } = pagination(context);
  const query = validatedQuery<{ approvalStatus?: string }>(context);
  return context.json(
    await driverOperationsService.listDrivers(
      page,
      limit,
      query.approvalStatus,
    ),
    200,
  );
}

export async function handleGetAdminDriverStatus(context: Context) {
  return context.json(
    await driverOperationsService.getOperatingStatus(context.req.param('id')!),
    200,
  );
}

export async function handleUpdateAdminDriverApproval(context: Context) {
  const result = await driverOperationsService.updateApproval(
    context.req.param('id')!,
    validatedJson(context),
    requireAdminActor(context),
    requireIdempotencyKey(context),
  );
  return context.json(result, 200);
}

export async function handleListDocumentRequirements(context: Context) {
  const includeInactive = context.req.query('includeInactive') !== 'false';
  return context.json(
    await driverOperationsService.listDocumentRequirements(includeInactive),
    200,
  );
}

export async function handleCreateDocumentRequirement(context: Context) {
  const result = await driverOperationsService.createDocumentRequirement(
    validatedJson(context),
    requireAdminActor(context),
    requireIdempotencyKey(context),
  );
  return context.json(result, 201);
}

export async function handleUpdateDocumentRequirement(context: Context) {
  requireAdminActor(context);
  return context.json(
    await driverOperationsService.updateDocumentRequirement(
      context.req.param('requirementId')!,
      validatedJson(context),
      requireIdempotencyKey(context),
    ),
    200,
  );
}

export async function handleGetAdminDriverDocuments(context: Context) {
  return context.json(
    await driverOperationsService.getDriverDocuments(context.req.param('id')!),
    200,
  );
}

export async function handleReviewAdminDriverDocument(context: Context) {
  return context.json(
    await driverOperationsService.reviewDriverDocument(
      context.req.param('id')!,
      context.req.param('requirementId')!,
      validatedJson(context),
      requireAdminActor(context),
      requireIdempotencyKey(context),
    ),
    200,
  );
}

export async function handleCreateAdminRestriction(context: Context) {
  const result = await driverOperationsService.createRestriction(
    context.req.param('id')!,
    validatedJson(context),
    requireAdminActor(context),
    requireIdempotencyKey(context),
  );
  return context.json(result, 201);
}

export async function handleListAdminRestrictions(context: Context) {
  return context.json(
    await driverOperationsService.listRestrictions(context.req.param('id')!),
    200,
  );
}

export async function handleLiftAdminRestriction(context: Context) {
  const { reason } = validatedJson(context);
  return context.json(
    await driverOperationsService.liftRestriction(
      context.req.param('restrictionId')!,
      reason,
      requireAdminActor(context),
      requireIdempotencyKey(context),
    ),
    200,
  );
}

export async function handleGetAdminWallet(context: Context) {
  return context.json(
    await driverOperationsService.getWallet(context.req.param('id')!),
    200,
  );
}

export async function handleGetAdminLedger(context: Context) {
  const { page, limit } = pagination(context);
  return context.json(
    await driverOperationsService.listLedger(
      context.req.param('id')!,
      page,
      limit,
    ),
    200,
  );
}

export async function handleCreateCreditAdjustment(context: Context) {
  return context.json(
    await driverOperationsService.adjustCredits(
      context.req.param('id')!,
      validatedJson(context),
      requireAdminActor(context),
      requireIdempotencyKey(context),
    ),
    201,
  );
}

export async function handleCreateCreditRefund(context: Context) {
  const { amountCentavos, reason } = validatedJson(context);
  return context.json(
    await driverOperationsService.refundCredits(
      context.req.param('id')!,
      amountCentavos,
      reason,
      requireAdminActor(context),
      requireIdempotencyKey(context),
    ),
    201,
  );
}

export async function handleListAdminTopupChannels(context: Context) {
  return context.json(await driverOperationsService.listTopupChannels(true), 200);
}

export async function handleCreateAdminTopupChannel(context: Context) {
  const result = await driverOperationsService.createTopupChannel(
    validatedJson(context),
    requireAdminActor(context),
    requireIdempotencyKey(context),
  );
  return context.json(result, 201);
}

export async function handleUpdateAdminTopupChannel(context: Context) {
  requireAdminActor(context);
  return context.json(
    await driverOperationsService.updateTopupChannel(
      context.req.param('channelId')!,
      validatedJson(context),
      requireIdempotencyKey(context),
    ),
    200,
  );
}

export async function handleListAdminTopups(context: Context) {
  const { page, limit } = pagination(context);
  const query = validatedQuery<{ status?: string }>(context);
  return context.json(
    await driverOperationsService.listTopups(
      page,
      limit,
      query.status,
    ),
    200,
  );
}

export async function handleApproveAdminTopup(context: Context) {
  const { reason } = validatedJson(context);
  return context.json(
    await driverOperationsService.reviewTopup(
      context.req.param('requestId')!,
      'approved',
      reason,
      requireAdminActor(context),
      requireIdempotencyKey(context),
    ),
    200,
  );
}

export async function handleRejectAdminTopup(context: Context) {
  const { reason } = validatedJson(context);
  return context.json(
    await driverOperationsService.reviewTopup(
      context.req.param('requestId')!,
      'rejected',
      reason,
      requireAdminActor(context),
      requireIdempotencyKey(context),
    ),
    200,
  );
}

export async function handleCheckInternalEligibility(context: Context) {
  const { driverId, requiredCommissionCentavos = 0 } = validatedJson(context);
  return context.json(
    await driverOperationsService.checkEligibility(
      driverId,
      requiredCommissionCentavos,
    ),
    200,
  );
}

export async function handleGetInternalDriverProfile(context: Context) {
  return context.json(
    await driverOperationsService.getInternalDriverProfile(context.req.param('id')!),
    200,
  );
}

export async function handleReserveInternalCredits(context: Context) {
  return context.json(
    await driverOperationsService.reserveCredits(
      validatedJson(context),
      internalActor(context),
      requireIdempotencyKey(context),
    ),
    201,
  );
}

export async function handleSettleInternalReservation(context: Context) {
  const { reason = 'Ride completed and commission settled' } =
    validatedJson(context);
  return context.json(
    await driverOperationsService.transitionReservation(
      context.req.param('rideId')!,
      'settled',
      reason,
      internalActor(context),
      requireIdempotencyKey(context),
    ),
    200,
  );
}

export async function handleReleaseInternalReservation(context: Context) {
  const { reason = 'Ride cancelled and commission released' } =
    validatedJson(context);
  return context.json(
    await driverOperationsService.transitionReservation(
      context.req.param('rideId')!,
      'released',
      reason,
      internalActor(context),
      requireIdempotencyKey(context),
    ),
    200,
  );
}

export async function handleDisputeInternalReservation(context: Context) {
  const { reason } = validatedJson(context);
  return context.json(
    await driverOperationsService.transitionReservation(
      context.req.param('rideId')!,
      'disputed',
      reason,
      internalActor(context),
      requireIdempotencyKey(context),
    ),
    200,
  );
}
