/**
 * Driver compliance and service-credit orchestration.
 * Money changes remain repository transactions; this layer owns validation and safe responses.
 */
import { Driver, SafeDriver } from '../entities/driver.types.ts';
import {
  DriverDomainError,
  DriverEligibility,
  MAXIMUM_CREDIT_BALANCE_CENTAVOS,
  MINIMUM_TOPUP_CENTAVOS,
  calculateCommissionCentavos,
  getEffectiveDocumentStatus,
  hashIdempotencyPayload,
  isDocumentRequirementSatisfied,
  normalizePaymentReference,
  validateDocumentReviewExpiry,
} from '../entities/driver_operations.types.ts';
import { DriverRepositoryImpl } from '../repositories/driver.repository.ts';
import { DriverOperationsRepository } from '../repositories/driver_operations.repository.ts';
import {
  ApprovalUpdateRequest,
  CreateDocumentRequirementRequest,
  CreateRestrictionRequest,
  CreateTopupChannelRequest,
  CreateTopupRequest,
  CreditAdjustmentRequest,
  ReserveCreditRequest,
  ReviewDriverDocumentRequest,
  UpdateDocumentRequirementRequest,
  UpdateTopupChannelRequest,
} from '../schemas/driver_operations.schema.ts';
import { UpdateOnlineStatusRequest } from '../schemas/driver.schema.ts';

export class DriverOperationsService {
  constructor(
    private readonly repository: DriverOperationsRepository,
    private readonly driverRepository: DriverRepositoryImpl,
  ) {}

  private sanitizeDriver(driver: Driver): SafeDriver {
    const { passwordHash: _, ...safeDriver } = driver;
    return safeDriver;
  }

  private parseExpiry(value: string | null | undefined): Date | null {
    return value ? new Date(value) : null;
  }

  private ensureFutureExpiry(expiresAt: Date | null) {
    if (expiresAt && expiresAt <= new Date()) {
      throw new DriverDomainError(
        422,
        'INVALID_EXPIRY',
        'Expiry must be in the future',
      );
    }
  }

  private eligibilityFromData(
    data: Awaited<ReturnType<DriverOperationsRepository['getEligibilityData']>>,
    requiredCommissionCentavos: number,
  ): DriverEligibility {
    const availableBalanceCentavos = data.wallet.availableBalanceCentavos;
    const result = (
      eligible: boolean,
      code: DriverEligibility['code'],
      message: string | null,
    ): DriverEligibility => ({
      eligible,
      code,
      message,
      availableBalanceCentavos,
      requiredCommissionCentavos,
    });

    if (data.driver.approvalStatus !== 'approved') {
      return result(false, 'DRIVER_NOT_APPROVED', 'Driver is not approved');
    }
    if (data.restriction) {
      return result(false, 'ACCOUNT_RESTRICTED', data.restriction.reason);
    }
    const invalidDocument = data.documents.some(
      ({ requirement, check }: any) => !isDocumentRequirementSatisfied(
        requirement,
        check,
        data.now,
      ),
    );
    if (invalidDocument) {
      return result(
        false,
        'DRIVER_DOCUMENTS_INCOMPLETE',
        'Required documents are incomplete or expired',
      );
    }
    if (availableBalanceCentavos < requiredCommissionCentavos) {
      return result(
        false,
        'INSUFFICIENT_CREDIT',
        'Available service credits cannot cover the required commission',
      );
    }
    return result(true, null, null);
  }

  async getOperatingStatus(driverId: string) {
    const data = await this.repository.getEligibilityData(driverId);
    const eligibility = this.eligibilityFromData(data, 0);
    return {
      driver: this.sanitizeDriver(data.driver as Driver),
      approvalStatus: data.driver.approvalStatus,
      approvalReason: data.driver.approvalReason,
      canGoOnline: eligibility.eligible,
      blockingCode: eligibility.code,
      blockingMessage: eligibility.message,
      activeRestriction: data.restriction,
      documents: data.documents.map(({ requirement, check }: any) => ({
        requirement,
        check,
        effectiveStatus: getEffectiveDocumentStatus(requirement, check, data.now),
      })),
      wallet: data.wallet,
    };
  }

  async updateOnlineStatus(
    driverId: string,
    payload: UpdateOnlineStatusRequest,
  ) {
    const updated = await this.repository.updateOnlineStatus(
      driverId,
      payload.isOnline,
      payload.lat ?? undefined,
      payload.lng ?? undefined,
    );
    return this.sanitizeDriver(updated);
  }

  async getOnlineDrivers() {
    const onlineDrivers = await this.driverRepository.findOnlineDrivers();
    // ponytail: the pilot fleet is small; batch SQL is warranted when this becomes a hot path.
    const eligibleDrivers = await Promise.all(onlineDrivers.map(async (driver) => ({
      driver,
      eligibility: await this.checkEligibility(driver.id, 0),
    })));
    return eligibleDrivers
      .filter(({ eligibility }) => eligibility.eligible)
      .map(({ driver }) => this.sanitizeDriver(driver));
  }

  async checkEligibility(driverId: string, requiredCommissionCentavos: number) {
    const data = await this.repository.getEligibilityData(driverId);
    return this.eligibilityFromData(data, requiredCommissionCentavos);
  }

  async getInternalDriverProfile(driverId: string) {
    const driver = await this.repository.getDriver(driverId);
    if (!driver) {
      throw new DriverDomainError(404, 'DRIVER_NOT_FOUND', 'Driver not found');
    }
    return {
      id: driver.id,
      name: driver.name,
      rating: driver.rating,
      vehicleType: driver.vehicleType,
      plateNumber: driver.plateNumber,
    };
  }

  async listDrivers(
    page: number,
    limit: number,
    approvalStatus?: any,
    from?: Date,
    to?: Date,
  ) {
    const result = await this.repository.listDrivers(
      page,
      limit,
      approvalStatus,
      from,
      to,
    );
    const summaries = await this.repository.getDriverComplianceSummaries(
      result.items.map((driver) => driver.id),
    );
    return {
      ...result,
      items: result.items.map((driver) => {
        const summary = summaries.get(driver.id)!;
        const statuses = summary.documents.map(({ requirement, check }: any) => (
          getEffectiveDocumentStatus(requirement, check, summary.now)
        ));
        const hasExpiredDocument = statuses.includes('expired');
        const hasIncompleteDocument = statuses.some(
          (status: string) => status !== 'verified',
        );
        return {
          ...this.sanitizeDriver(driver as Driver),
          restrictionStatus: summary.restriction ? 'active' : 'none',
          documentStatus: hasExpiredDocument
            ? 'expired'
            : hasIncompleteDocument
              ? 'incomplete'
              : summary.documents.length === 0
                ? 'not_required'
                : 'verified',
          documents: summary.documents.map(({ requirement, check }: any) => ({
            requirementId: requirement.id,
            name: requirement.name,
            isActive: requirement.isActive,
            requiresExpiry: requirement.requiresExpiry,
            status: getEffectiveDocumentStatus(requirement, check, summary.now),
            expiresAt: check?.expiresAt || null,
          })),
        };
      }),
    };
  }

  async updateApproval(
    driverId: string,
    payload: ApprovalUpdateRequest,
    actorId: string,
    idempotencyKey: string,
  ) {
    const requestHash = await hashIdempotencyPayload({ driverId, ...payload });
    const driver = await this.repository.setApproval(
      driverId,
      payload.status,
      payload.reason,
      actorId,
      idempotencyKey,
      requestHash,
    );
    return this.sanitizeDriver(driver as Driver);
  }

  async listDocumentRequirements(includeInactive = true) {
    return (await this.repository.listDocumentRequirements(includeInactive))
      .map((requirement) => ({
        ...requirement,
        status: requirement.isActive ? 'active' : 'inactive',
      }));
  }

  async createDocumentRequirement(
    payload: CreateDocumentRequirementRequest,
    actorId: string,
    idempotencyKey: string,
  ) {
    const normalizedName = payload.name.toLowerCase().replace(/\s+/g, ' ');
    const requiresExpiry = payload.requiresExpiry ?? false;
    const isActive = payload.isActive ?? true;
    const requestHash = await hashIdempotencyPayload({ ...payload, normalizedName });
    return this.repository.createDocumentRequirement(
      payload.name,
      normalizedName,
      requiresExpiry,
      isActive,
      actorId,
      idempotencyKey,
      requestHash,
    );
  }

  async updateDocumentRequirement(
    requirementId: string,
    payload: UpdateDocumentRequirementRequest,
    idempotencyKey: string,
  ) {
    const changes = {
      ...payload,
      normalizedName: payload.name
        ? payload.name.toLowerCase().replace(/\s+/g, ' ')
        : undefined,
    };
    const requestHash = await hashIdempotencyPayload({ requirementId, ...changes });
    return this.repository.updateDocumentRequirement(
      requirementId,
      changes,
      idempotencyKey,
      requestHash,
    );
  }

  async getDriverDocuments(driverId: string) {
    const now = new Date();
    const documents = await this.repository.getDriverDocuments(driverId);
    return documents.map(({ requirement, check }: any) => ({
      requirement,
      check,
      effectiveStatus: getEffectiveDocumentStatus(requirement, check, now),
    }));
  }

  async reviewDriverDocument(
    driverId: string,
    requirementId: string,
    payload: ReviewDriverDocumentRequest,
    actorId: string,
    idempotencyKey: string,
  ) {
    const expiresAt = this.parseExpiry(payload.expiresAt);
    const requirement = await this.repository.getDocumentRequirement(requirementId);
    if (!requirement) {
      throw new DriverDomainError(
        404,
        'DOCUMENT_REQUIREMENT_NOT_FOUND',
        'Document requirement not found',
      );
    }
    validateDocumentReviewExpiry(requirement, payload.status, expiresAt);
    const requestHash = await hashIdempotencyPayload({
      driverId,
      requirementId,
      ...payload,
    });
    return this.repository.reviewDriverDocument(
      driverId,
      requirementId,
      payload.status,
      expiresAt,
      payload.notes ?? null,
      actorId,
      idempotencyKey,
      requestHash,
    );
  }

  async createRestriction(
    driverId: string,
    payload: CreateRestrictionRequest,
    actorId: string,
    idempotencyKey: string,
  ) {
    const expiresAt = this.parseExpiry(payload.expiresAt);
    this.ensureFutureExpiry(expiresAt);
    const requestHash = await hashIdempotencyPayload({ driverId, ...payload });
    return this.repository.createRestriction(
      driverId,
      payload.reason,
      expiresAt,
      actorId,
      idempotencyKey,
      requestHash,
    );
  }

  async listRestrictions(driverId: string) {
    const now = new Date();
    return (await this.repository.listRestrictions(driverId)).map((restriction) => ({
      ...restriction,
      effectiveStatus:
        restriction.status === 'active'
        && restriction.expiresAt
        && restriction.expiresAt <= now
          ? 'expired'
          : restriction.status,
    }));
  }

  async liftRestriction(
    restrictionId: string,
    reason: string,
    actorId: string,
    idempotencyKey: string,
  ) {
    const requestHash = await hashIdempotencyPayload({ restrictionId, reason });
    return this.repository.liftRestriction(
      restrictionId,
      reason,
      actorId,
      idempotencyKey,
      requestHash,
    );
  }

  async getWallet(driverId: string) {
    return this.repository.getWallet(driverId);
  }

  async listLedger(driverId: string, page: number, limit: number) {
    return this.repository.listLedger(driverId, page, limit);
  }

  async listTopupChannels(includeInactive = false) {
    return this.repository.listTopupChannels(includeInactive);
  }

  async createTopupChannel(
    payload: CreateTopupChannelRequest,
    actorId: string,
    idempotencyKey: string,
  ) {
    const requestHash = await hashIdempotencyPayload(payload);
    return this.repository.createTopupChannel(
      {
        ...payload,
        instructions: payload.instructions ?? null,
      },
      actorId,
      idempotencyKey,
      requestHash,
    );
  }

  async updateTopupChannel(
    channelId: string,
    payload: UpdateTopupChannelRequest,
    idempotencyKey: string,
  ) {
    const requestHash = await hashIdempotencyPayload({ channelId, ...payload });
    return this.repository.updateTopupChannel(
      channelId,
      payload,
      idempotencyKey,
      requestHash,
    );
  }

  async submitTopup(
    driverId: string,
    payload: CreateTopupRequest,
    idempotencyKey: string,
  ) {
    if (
      payload.amountCentavos < MINIMUM_TOPUP_CENTAVOS
      || payload.amountCentavos > MAXIMUM_CREDIT_BALANCE_CENTAVOS
    ) {
      throw new DriverDomainError(
        422,
        'INVALID_CREDIT_AMOUNT',
        'Top-up must be between ₱100 and ₱1,000',
      );
    }
    const normalizedTransactionReference = normalizePaymentReference(
      payload.transactionReference,
    );
    const values = { ...payload, normalizedTransactionReference };
    const requestHash = await hashIdempotencyPayload({ driverId, ...values });
    return this.repository.createTopupRequest(
      driverId,
      values,
      idempotencyKey,
      requestHash,
    );
  }

  async listDriverTopups(driverId: string, page: number, limit: number) {
    return this.repository.listDriverTopups(driverId, page, limit);
  }

  async listTopups(
    page: number,
    limit: number,
    status?: any,
    from?: Date,
    to?: Date,
  ) {
    return this.repository.listTopups(page, limit, status, from, to);
  }

  async reviewTopup(
    requestId: string,
    decision: 'approved' | 'rejected',
    reason: string,
    actorId: string,
    idempotencyKey: string,
  ) {
    const requestHash = await hashIdempotencyPayload({
      requestId,
      decision,
      reason,
    });
    return this.repository.reviewTopup(
      requestId,
      decision,
      reason,
      actorId,
      idempotencyKey,
      requestHash,
    );
  }

  async adjustCredits(
    driverId: string,
    payload: CreditAdjustmentRequest,
    actorId: string,
    idempotencyKey: string,
  ) {
    const requestHash = await hashIdempotencyPayload({ driverId, ...payload });
    return this.repository.changeBalance(
      driverId,
      payload.amountCentavos,
      'adjustment',
      payload.reason,
      actorId,
      idempotencyKey,
      requestHash,
    );
  }

  async refundCredits(
    driverId: string,
    amountCentavos: number,
    reason: string,
    actorId: string,
    idempotencyKey: string,
  ) {
    const requestHash = await hashIdempotencyPayload({
      driverId,
      amountCentavos,
      reason,
    });
    return this.repository.changeBalance(
      driverId,
      amountCentavos,
      'refund',
      reason,
      actorId,
      idempotencyKey,
      requestHash,
    );
  }

  /**
   * Creates the one credit hold for a ride. Replays with the same ride and key are safe.
   */
  async reserveCredits(
    payload: ReserveCreditRequest,
    actorId: string,
    idempotencyKey: string,
  ) {
    const commissionCentavos = calculateCommissionCentavos(
      payload.fareCentavos,
      payload.commissionBasisPoints,
    );
    const requestHash = await hashIdempotencyPayload(payload);
    const reservation = await this.repository.reserveCredit(
      payload,
      actorId,
      idempotencyKey,
      requestHash,
    );
    return { reservation, commissionCentavos };
  }

  async transitionReservation(
    rideId: string,
    targetStatus: 'settled' | 'released' | 'disputed',
    reason: string,
    actorId: string,
    idempotencyKey: string,
  ) {
    const requestHash = await hashIdempotencyPayload({
      rideId,
      targetStatus,
      reason,
    });
    return this.repository.transitionReservation(
      rideId,
      targetStatus,
      reason,
      actorId,
      idempotencyKey,
      requestHash,
    );
  }
}
