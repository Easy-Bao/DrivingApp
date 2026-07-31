import {
  and,
  asc,
  desc,
  eq,
  gte,
  gt,
  inArray,
  isNull,
  lte,
  or,
  sql,
} from 'drizzle-orm';
import {
  driverAccountRestrictions,
  driverCreditLedger,
  driverCreditReservations,
  driverCreditWallets,
  driverDocumentChecks,
  driverDocumentRequirements,
  driverIdempotencyRecords,
  drivers,
  driverTopupChannels,
  driverTopupRequests,
  DriverApprovalStatus,
  DocumentCheckStatus,
  TopupRequestStatus,
} from '../../db/schema.ts';
import { db } from '../../shared/drizzle.ts';
import {
  DriverDomainError,
  LOW_BALANCE_WARNING_CENTAVOS,
  MAXIMUM_CREDIT_BALANCE_CENTAVOS,
  Page,
  calculateCommissionCentavos,
  isDocumentRequirementSatisfied,
} from '../entities/driver_operations.types.ts';

type Executor = any;
type IdempotentAction<T> = (transaction: Executor) => Promise<T>;

export class DriverOperationsRepository {
  private async runIdempotently<T>(
    operation: string,
    idempotencyKey: string,
    requestHash: string,
    action: IdempotentAction<T>,
  ): Promise<T> {
    return db.transaction(async (transaction) => {
      const lockName = `${operation}:${idempotencyKey}`;
      await transaction.execute(
        sql`select pg_advisory_xact_lock(hashtext(${lockName}))`,
      );

      const [existing] = await transaction.select()
        .from(driverIdempotencyRecords)
        .where(
          and(
            eq(driverIdempotencyRecords.operation, operation),
            eq(driverIdempotencyRecords.idempotencyKey, idempotencyKey),
          ),
        );

      if (existing) {
        if (existing.requestHash !== requestHash) {
          throw new DriverDomainError(
            409,
            'IDEMPOTENCY_KEY_REUSED',
            'This idempotency key was already used with a different request',
          );
        }
        return existing.responseJson as T;
      }

      const response = await action(transaction);
      const serializableResponse = JSON.parse(JSON.stringify(response)) as unknown;
      await transaction.insert(driverIdempotencyRecords).values({
        operation,
        idempotencyKey,
        requestHash,
        responseJson: serializableResponse,
      });
      return response;
    });
  }

  private async findDriver(executor: Executor, driverId: string) {
    const [driver] = await executor.select()
      .from(drivers)
      .where(eq(drivers.id, driverId));
    return driver || null;
  }

  private async lockDriver(executor: Executor, driverId: string) {
    await executor.execute(
      sql`select "id" from "drivers" where "id" = ${driverId} for update`,
    );
    const driver = await this.findDriver(executor, driverId);
    if (!driver) {
      throw new DriverDomainError(404, 'DRIVER_NOT_FOUND', 'Driver not found');
    }
    return driver;
  }

  private async lockWallet(executor: Executor, driverId: string) {
    await executor.insert(driverCreditWallets)
      .values({ driverId })
      .onConflictDoNothing();
    await executor.execute(
      sql`select "driver_id" from "driver_credit_wallets"
          where "driver_id" = ${driverId} for update`,
    );
    const [wallet] = await executor.select()
      .from(driverCreditWallets)
      .where(eq(driverCreditWallets.driverId, driverId));
    return wallet;
  }

  private walletView(wallet: typeof driverCreditWallets.$inferSelect) {
    const availableBalanceCentavos =
      wallet.balanceCentavos - wallet.reservedCentavos;
    return {
      ...wallet,
      availableBalanceCentavos,
      lowBalance: availableBalanceCentavos <= LOW_BALANCE_WARNING_CENTAVOS,
    };
  }

  private async complianceData(executor: Executor, driverId: string) {
    const driver = await this.findDriver(executor, driverId);
    if (!driver) {
      throw new DriverDomainError(404, 'DRIVER_NOT_FOUND', 'Driver not found');
    }

    const now = new Date();
    const [restriction] = await executor.select()
      .from(driverAccountRestrictions)
      .where(
        and(
          eq(driverAccountRestrictions.driverId, driverId),
          eq(driverAccountRestrictions.status, 'active'),
          or(
            isNull(driverAccountRestrictions.expiresAt),
            gt(driverAccountRestrictions.expiresAt, now),
          ),
        ),
      );

    const documents = await executor.select({
      requirement: driverDocumentRequirements,
      check: driverDocumentChecks,
    })
      .from(driverDocumentRequirements)
      .leftJoin(
        driverDocumentChecks,
        and(
          eq(driverDocumentChecks.requirementId, driverDocumentRequirements.id),
          eq(driverDocumentChecks.driverId, driverId),
        ),
      )
      .where(eq(driverDocumentRequirements.isActive, true))
      .orderBy(asc(driverDocumentRequirements.name));

    return { driver, restriction: restriction || null, documents, now };
  }

  async getDriver(driverId: string) {
    return this.findDriver(db, driverId);
  }

  async updateOnlineStatus(
    driverId: string,
    isOnline: boolean,
    lat?: number,
    lng?: number,
  ) {
    const result = await db.transaction(async (transaction) => {
      await this.lockDriver(transaction, driverId);
      if (isOnline) {
        const compliance = await this.complianceData(transaction, driverId);
        if (compliance.driver.approvalStatus !== 'approved') {
          return {
            error: {
              code: 'DRIVER_NOT_APPROVED' as const,
              message: 'Driver is not approved to go online',
            },
          };
        }
        if (compliance.restriction) {
          return {
            error: {
              code: 'ACCOUNT_RESTRICTED' as const,
              message: 'Driver account is restricted',
            },
          };
        }
        const hasInvalidDocument = compliance.documents.some(
          ({ requirement, check }: any) => !isDocumentRequirementSatisfied(
            requirement,
            check,
            compliance.now,
          ),
        );
        if (hasInvalidDocument) {
          return {
            error: {
              code: 'DRIVER_DOCUMENTS_INCOMPLETE' as const,
              message: 'Driver documents are incomplete or expired',
            },
          };
        }
      }

      const changes: {
        isOnline: boolean;
        lat?: number;
        lng?: number;
      } = { isOnline };
      if (lat !== undefined) changes.lat = lat;
      if (lng !== undefined) changes.lng = lng;
      const [updated] = await transaction.update(drivers)
        .set(changes)
        .where(eq(drivers.id, driverId))
        .returning();
      return { driver: updated };
    });

    if ('error' in result && result.error) {
      throw new DriverDomainError(409, result.error.code, result.error.message);
    }
    return result.driver!;
  }

  async listDrivers(
    page: number,
    limit: number,
    approvalStatus?: DriverApprovalStatus,
    from?: Date,
    to?: Date,
  ): Promise<Page<typeof drivers.$inferSelect>> {
    const offset = (page - 1) * limit;
    const conditions = [
      approvalStatus ? eq(drivers.approvalStatus, approvalStatus) : undefined,
      from ? gte(drivers.createdAt, from) : undefined,
      to ? lte(drivers.createdAt, to) : undefined,
    ].filter(Boolean);
    const condition = conditions.length > 0
      ? and(...conditions as any[])
      : undefined;
    const [countRow] = await db.select({ count: sql<number>`count(*)::int` })
      .from(drivers)
      .where(condition);
    const items = await db.select()
      .from(drivers)
      .where(condition)
      .orderBy(desc(drivers.createdAt))
      .limit(limit)
      .offset(offset);
    return { items, page, limit, total: countRow?.count || 0 };
  }

  async getDriverComplianceSummaries(driverIds: string[]) {
    if (driverIds.length === 0) return new Map();
    const now = new Date();
    const requirements = await db.select()
      .from(driverDocumentRequirements)
      .where(eq(driverDocumentRequirements.isActive, true))
      .orderBy(asc(driverDocumentRequirements.name));
    const checks = requirements.length === 0
      ? []
      : await db.select()
        .from(driverDocumentChecks)
        .where(
          and(
            inArray(driverDocumentChecks.driverId, driverIds),
            inArray(
              driverDocumentChecks.requirementId,
              requirements.map((requirement) => requirement.id),
            ),
          ),
        );
    const restrictions = await db.select()
      .from(driverAccountRestrictions)
      .where(
        and(
          inArray(driverAccountRestrictions.driverId, driverIds),
          eq(driverAccountRestrictions.status, 'active'),
          or(
            isNull(driverAccountRestrictions.expiresAt),
            gt(driverAccountRestrictions.expiresAt, now),
          ),
        ),
      );
    const checkByDriverRequirement = new Map(
      checks.map((check) => [`${check.driverId}:${check.requirementId}`, check]),
    );
    const restrictionByDriver = new Map(
      restrictions.map((restriction) => [restriction.driverId, restriction]),
    );
    return new Map(driverIds.map((driverId) => [
      driverId,
      {
        restriction: restrictionByDriver.get(driverId) || null,
        documents: requirements.map((requirement) => ({
          requirement,
          check: checkByDriverRequirement.get(`${driverId}:${requirement.id}`) || null,
        })),
        now,
      },
    ]));
  }

  async setApproval(
    driverId: string,
    status: DriverApprovalStatus,
    reason: string,
    actorId: string,
    idempotencyKey: string,
    requestHash: string,
  ) {
    return this.runIdempotently(
      'driver.approval',
      idempotencyKey,
      requestHash,
      async (transaction) => {
        await this.lockDriver(transaction, driverId);
        const [updated] = await transaction.update(drivers)
          .set({
            approvalStatus: status,
            approvalReason: reason,
            approvalReviewedBy: actorId,
            approvalReviewedAt: new Date(),
            isOnline: status === 'approved' ? undefined : false,
          })
          .where(eq(drivers.id, driverId))
          .returning();
        const { passwordHash: _, ...safeDriver } = updated;
        return safeDriver;
      },
    );
  }

  async listDocumentRequirements(includeInactive = true) {
    return db.select()
      .from(driverDocumentRequirements)
      .where(
        includeInactive
          ? undefined
          : eq(driverDocumentRequirements.isActive, true),
      )
      .orderBy(asc(driverDocumentRequirements.name));
  }

  async getDocumentRequirement(requirementId: string) {
    const [requirement] = await db.select()
      .from(driverDocumentRequirements)
      .where(eq(driverDocumentRequirements.id, requirementId));
    return requirement || null;
  }

  async createDocumentRequirement(
    name: string,
    normalizedName: string,
    requiresExpiry: boolean,
    isActive: boolean,
    actorId: string,
    idempotencyKey: string,
    requestHash: string,
  ) {
    return this.runIdempotently(
      'document-requirement.create',
      idempotencyKey,
      requestHash,
      async (transaction) => {
        const requirementLock = `document-requirement:${normalizedName}`;
        await transaction.execute(
          sql`select pg_advisory_xact_lock(hashtext(${requirementLock}))`,
        );
        const [existing] = await transaction.select()
          .from(driverDocumentRequirements)
          .where(eq(driverDocumentRequirements.normalizedName, normalizedName));
        if (existing) {
          throw new DriverDomainError(
            409,
            'DOCUMENT_REQUIREMENT_EXISTS',
            'A document requirement with this name already exists',
          );
        }
        const [created] = await transaction.insert(driverDocumentRequirements)
          .values({
            id: crypto.randomUUID(),
            name,
            normalizedName,
            requiresExpiry,
            isActive,
            createdBy: actorId,
          })
          .returning();
        if (isActive) {
          await transaction.update(drivers).set({ isOnline: false });
        }
        return created;
      },
    );
  }

  async updateDocumentRequirement(
    requirementId: string,
    changes: {
      name?: string;
      normalizedName?: string;
      isActive?: boolean;
      requiresExpiry?: boolean;
    },
    idempotencyKey: string,
    requestHash: string,
  ) {
    return this.runIdempotently(
      'document-requirement.update',
      idempotencyKey,
      requestHash,
      async (transaction) => {
        const [existing] = await transaction.select()
          .from(driverDocumentRequirements)
          .where(eq(driverDocumentRequirements.id, requirementId));
        if (!existing) {
          throw new DriverDomainError(
            404,
            'DOCUMENT_REQUIREMENT_NOT_FOUND',
            'Document requirement not found',
          );
        }

        if (changes.normalizedName) {
          const requirementLock = `document-requirement:${changes.normalizedName}`;
          await transaction.execute(
            sql`select pg_advisory_xact_lock(hashtext(${requirementLock}))`,
          );
          const [duplicate] = await transaction.select()
            .from(driverDocumentRequirements)
            .where(eq(
              driverDocumentRequirements.normalizedName,
              changes.normalizedName,
            ));
          if (duplicate && duplicate.id !== requirementId) {
            throw new DriverDomainError(
              409,
              'DOCUMENT_REQUIREMENT_EXISTS',
              'A document requirement with this name already exists',
            );
          }
        }

        const [updated] = await transaction.update(driverDocumentRequirements)
          .set({ ...changes, updatedAt: new Date() })
          .where(eq(driverDocumentRequirements.id, requirementId))
          .returning();
        const willBeActive = changes.isActive ?? existing.isActive;
        const becomesActive = changes.isActive === true && existing.isActive === false;
        const startsRequiringExpiry = (
          changes.requiresExpiry === true
          && existing.requiresExpiry === false
        );
        if (willBeActive && (becomesActive || startsRequiringExpiry)) {
          await transaction.update(drivers).set({ isOnline: false });
        }
        return updated;
      },
    );
  }

  async getDriverDocuments(driverId: string) {
    if (!await this.findDriver(db, driverId)) {
      throw new DriverDomainError(404, 'DRIVER_NOT_FOUND', 'Driver not found');
    }
    return db.select({
      requirement: driverDocumentRequirements,
      check: driverDocumentChecks,
    })
      .from(driverDocumentRequirements)
      .leftJoin(
        driverDocumentChecks,
        and(
          eq(driverDocumentChecks.requirementId, driverDocumentRequirements.id),
          eq(driverDocumentChecks.driverId, driverId),
        ),
      )
      .orderBy(asc(driverDocumentRequirements.name));
  }

  async reviewDriverDocument(
    driverId: string,
    requirementId: string,
    status: DocumentCheckStatus,
    expiresAt: Date | null,
    notes: string | null,
    actorId: string,
    idempotencyKey: string,
    requestHash: string,
  ) {
    return this.runIdempotently(
      'driver-document.review',
      idempotencyKey,
      requestHash,
      async (transaction) => {
        await this.lockDriver(transaction, driverId);
        const [requirement] = await transaction.select()
          .from(driverDocumentRequirements)
          .where(eq(driverDocumentRequirements.id, requirementId));
        if (!requirement) {
          throw new DriverDomainError(
            404,
            'DOCUMENT_REQUIREMENT_NOT_FOUND',
            'Document requirement not found',
          );
        }

        const now = new Date();
        const [reviewed] = await transaction.insert(driverDocumentChecks)
          .values({
            id: crypto.randomUUID(),
            driverId,
            requirementId,
            status,
            expiresAt,
            notes,
            reviewedBy: actorId,
            reviewedAt: now,
            updatedAt: now,
          })
          .onConflictDoUpdate({
            target: [
              driverDocumentChecks.driverId,
              driverDocumentChecks.requirementId,
            ],
            set: {
              status,
              expiresAt,
              notes,
              reviewedBy: actorId,
              reviewedAt: now,
              updatedAt: now,
            },
          })
          .returning();
        if (!isDocumentRequirementSatisfied(
          requirement,
          { status, expiresAt },
          now,
        )) {
          await transaction.update(drivers)
            .set({ isOnline: false })
            .where(eq(drivers.id, driverId));
        }
        return reviewed;
      },
    );
  }

  async getActiveRestriction(driverId: string) {
    const now = new Date();
    const [restriction] = await db.select()
      .from(driverAccountRestrictions)
      .where(
        and(
          eq(driverAccountRestrictions.driverId, driverId),
          eq(driverAccountRestrictions.status, 'active'),
          or(
            isNull(driverAccountRestrictions.expiresAt),
            gt(driverAccountRestrictions.expiresAt, now),
          ),
        ),
      );
    return restriction || null;
  }

  async listRestrictions(driverId: string) {
    if (!await this.findDriver(db, driverId)) {
      throw new DriverDomainError(404, 'DRIVER_NOT_FOUND', 'Driver not found');
    }
    return db.select()
      .from(driverAccountRestrictions)
      .where(eq(driverAccountRestrictions.driverId, driverId))
      .orderBy(desc(driverAccountRestrictions.createdAt));
  }

  async createRestriction(
    driverId: string,
    reason: string,
    expiresAt: Date | null,
    actorId: string,
    idempotencyKey: string,
    requestHash: string,
  ) {
    return this.runIdempotently(
      'driver-restriction.create',
      idempotencyKey,
      requestHash,
      async (transaction) => {
        await this.lockDriver(transaction, driverId);
        const now = new Date();
        await transaction.update(driverAccountRestrictions)
          .set({
            status: 'lifted',
            liftedBy: 'system',
            liftedReason: 'Restriction expired',
            liftedAt: now,
          })
          .where(
            and(
              eq(driverAccountRestrictions.driverId, driverId),
              eq(driverAccountRestrictions.status, 'active'),
              lte(driverAccountRestrictions.expiresAt, now),
            ),
          );

        const [existing] = await transaction.select()
          .from(driverAccountRestrictions)
          .where(
            and(
              eq(driverAccountRestrictions.driverId, driverId),
              eq(driverAccountRestrictions.status, 'active'),
            ),
          );
        if (existing) {
          throw new DriverDomainError(
            409,
            'ACCOUNT_RESTRICTED',
            'Driver already has an active restriction',
          );
        }

        const [created] = await transaction.insert(driverAccountRestrictions)
          .values({
            id: crypto.randomUUID(),
            driverId,
            reason,
            expiresAt,
            createdBy: actorId,
          })
          .returning();
        await transaction.update(drivers)
          .set({ isOnline: false })
          .where(eq(drivers.id, driverId));
        return created;
      },
    );
  }

  async liftRestriction(
    restrictionId: string,
    reason: string,
    actorId: string,
    idempotencyKey: string,
    requestHash: string,
  ) {
    return this.runIdempotently(
      'driver-restriction.lift',
      idempotencyKey,
      requestHash,
      async (transaction) => {
        const [restriction] = await transaction.select()
          .from(driverAccountRestrictions)
          .where(eq(driverAccountRestrictions.id, restrictionId));
        if (!restriction) {
          throw new DriverDomainError(
            404,
            'RESTRICTION_NOT_FOUND',
            'Restriction not found',
          );
        }
        if (restriction.status === 'lifted') return restriction;

        const [lifted] = await transaction.update(driverAccountRestrictions)
          .set({
            status: 'lifted',
            liftedBy: actorId,
            liftedReason: reason,
            liftedAt: new Date(),
          })
          .where(eq(driverAccountRestrictions.id, restrictionId))
          .returning();
        return lifted;
      },
    );
  }

  async getWallet(driverId: string) {
    if (!await this.findDriver(db, driverId)) {
      throw new DriverDomainError(404, 'DRIVER_NOT_FOUND', 'Driver not found');
    }
    await db.insert(driverCreditWallets)
      .values({ driverId })
      .onConflictDoNothing();
    const [wallet] = await db.select()
      .from(driverCreditWallets)
      .where(eq(driverCreditWallets.driverId, driverId));
    return this.walletView(wallet);
  }

  async listLedger(driverId: string, page: number, limit: number) {
    await this.getWallet(driverId);
    const offset = (page - 1) * limit;
    const [countRow] = await db.select({ count: sql<number>`count(*)::int` })
      .from(driverCreditLedger)
      .where(eq(driverCreditLedger.driverId, driverId));
    const items = await db.select()
      .from(driverCreditLedger)
      .where(eq(driverCreditLedger.driverId, driverId))
      .orderBy(desc(driverCreditLedger.createdAt))
      .limit(limit)
      .offset(offset);
    return { items, page, limit, total: countRow?.count || 0 };
  }

  async listTopupChannels(includeInactive = false) {
    return db.select()
      .from(driverTopupChannels)
      .where(includeInactive ? undefined : eq(driverTopupChannels.isActive, true))
      .orderBy(asc(driverTopupChannels.name));
  }

  async createTopupChannel(
    values: {
      name: string;
      accountName: string;
      accountReference: string;
      instructions: string | null;
    },
    actorId: string,
    idempotencyKey: string,
    requestHash: string,
  ) {
    return this.runIdempotently(
      'topup-channel.create',
      idempotencyKey,
      requestHash,
      async (transaction) => {
        const [created] = await transaction.insert(driverTopupChannels)
          .values({
            id: crypto.randomUUID(),
            ...values,
            createdBy: actorId,
          })
          .returning();
        return created;
      },
    );
  }

  async updateTopupChannel(
    channelId: string,
    changes: {
      name?: string;
      accountName?: string;
      accountReference?: string;
      instructions?: string | null;
      isActive?: boolean;
    },
    idempotencyKey: string,
    requestHash: string,
  ) {
    return this.runIdempotently(
      'topup-channel.update',
      idempotencyKey,
      requestHash,
      async (transaction) => {
        const [existing] = await transaction.select()
          .from(driverTopupChannels)
          .where(eq(driverTopupChannels.id, channelId));
        if (!existing) {
          throw new DriverDomainError(
            404,
            'TOPUP_CHANNEL_NOT_FOUND',
            'Top-up channel not found',
          );
        }
        const [updated] = await transaction.update(driverTopupChannels)
          .set({ ...changes, updatedAt: new Date() })
          .where(eq(driverTopupChannels.id, channelId))
          .returning();
        return updated;
      },
    );
  }

  async createTopupRequest(
    driverId: string,
    values: {
      channelId: string;
      amountCentavos: number;
      senderName: string;
      transactionReference: string;
      normalizedTransactionReference: string;
    },
    idempotencyKey: string,
    requestHash: string,
  ) {
    return this.runIdempotently(
      `topup-request.create:${driverId}`,
      idempotencyKey,
      requestHash,
      async (transaction) => {
        await this.lockDriver(transaction, driverId);
        const [channel] = await transaction.select()
          .from(driverTopupChannels)
          .where(
            and(
              eq(driverTopupChannels.id, values.channelId),
              eq(driverTopupChannels.isActive, true),
            ),
          );
        if (!channel) {
          throw new DriverDomainError(
            404,
            'TOPUP_CHANNEL_NOT_FOUND',
            'Active top-up channel not found',
          );
        }

        const referenceLock =
          `topup-reference:${values.channelId}:${values.normalizedTransactionReference}`;
        await transaction.execute(
          sql`select pg_advisory_xact_lock(hashtext(${referenceLock}))`,
        );
        const [duplicate] = await transaction.select()
          .from(driverTopupRequests)
          .where(
            and(
              eq(driverTopupRequests.channelId, values.channelId),
              eq(
                driverTopupRequests.normalizedTransactionReference,
                values.normalizedTransactionReference,
              ),
            ),
          );
        if (duplicate) {
          throw new DriverDomainError(
            409,
            'DUPLICATE_TOPUP_REFERENCE',
            'This payment reference has already been submitted',
          );
        }

        const [created] = await transaction.insert(driverTopupRequests)
          .values({
            id: crypto.randomUUID(),
            driverId,
            ...values,
          })
          .returning();
        return created;
      },
    );
  }

  async listDriverTopups(driverId: string, page: number, limit: number) {
    if (!await this.findDriver(db, driverId)) {
      throw new DriverDomainError(404, 'DRIVER_NOT_FOUND', 'Driver not found');
    }
    const offset = (page - 1) * limit;
    const [countRow] = await db.select({ count: sql<number>`count(*)::int` })
      .from(driverTopupRequests)
      .where(eq(driverTopupRequests.driverId, driverId));
    const items = await db.select({
      id: driverTopupRequests.id,
      driverId: driverTopupRequests.driverId,
      channelId: driverTopupRequests.channelId,
      channelName: driverTopupChannels.name,
      amountCentavos: driverTopupRequests.amountCentavos,
      senderName: driverTopupRequests.senderName,
      transactionReference: driverTopupRequests.transactionReference,
      status: driverTopupRequests.status,
      submittedAt: driverTopupRequests.submittedAt,
      reviewedBy: driverTopupRequests.reviewedBy,
      reviewedAt: driverTopupRequests.reviewedAt,
      reviewReason: driverTopupRequests.reviewReason,
    })
      .from(driverTopupRequests)
      .innerJoin(
        driverTopupChannels,
        eq(driverTopupChannels.id, driverTopupRequests.channelId),
      )
      .where(eq(driverTopupRequests.driverId, driverId))
      .orderBy(desc(driverTopupRequests.submittedAt))
      .limit(limit)
      .offset(offset);
    return { items, page, limit, total: countRow?.count || 0 };
  }

  async listTopups(
    page: number,
    limit: number,
    status?: TopupRequestStatus,
    from?: Date,
    to?: Date,
  ) {
    const offset = (page - 1) * limit;
    const conditions = [
      status ? eq(driverTopupRequests.status, status) : undefined,
      from ? gte(driverTopupRequests.submittedAt, from) : undefined,
      to ? lte(driverTopupRequests.submittedAt, to) : undefined,
    ].filter(Boolean);
    const condition = conditions.length > 0
      ? and(...conditions as any[])
      : undefined;
    const [countRow] = await db.select({ count: sql<number>`count(*)::int` })
      .from(driverTopupRequests)
      .where(condition);
    const items = await db.select({
      id: driverTopupRequests.id,
      driverId: driverTopupRequests.driverId,
      driverName: drivers.name,
      driverEmail: drivers.email,
      channelId: driverTopupRequests.channelId,
      channelName: driverTopupChannels.name,
      amountCentavos: driverTopupRequests.amountCentavos,
      senderName: driverTopupRequests.senderName,
      transactionReference: driverTopupRequests.transactionReference,
      status: driverTopupRequests.status,
      submittedAt: driverTopupRequests.submittedAt,
      reviewedBy: driverTopupRequests.reviewedBy,
      reviewedAt: driverTopupRequests.reviewedAt,
      reviewReason: driverTopupRequests.reviewReason,
    })
      .from(driverTopupRequests)
      .innerJoin(
        driverTopupChannels,
        eq(driverTopupChannels.id, driverTopupRequests.channelId),
      )
      .innerJoin(drivers, eq(drivers.id, driverTopupRequests.driverId))
      .where(condition)
      .orderBy(asc(driverTopupRequests.submittedAt))
      .limit(limit)
      .offset(offset);
    return { items, page, limit, total: countRow?.count || 0 };
  }

  async reviewTopup(
    requestId: string,
    decision: 'approved' | 'rejected',
    reason: string,
    actorId: string,
    idempotencyKey: string,
    requestHash: string,
  ) {
    return this.runIdempotently(
      `topup-request.${decision}`,
      idempotencyKey,
      requestHash,
      async (transaction) => {
        await transaction.execute(
          sql`select "id" from "driver_topup_requests"
              where "id" = ${requestId} for update`,
        );
        const [request] = await transaction.select()
          .from(driverTopupRequests)
          .where(eq(driverTopupRequests.id, requestId));
        if (!request) {
          throw new DriverDomainError(
            404,
            'TOPUP_REQUEST_NOT_FOUND',
            'Top-up request not found',
          );
        }
        if (request.status !== 'pending') {
          throw new DriverDomainError(
            409,
            'TOPUP_ALREADY_REVIEWED',
            'Top-up request has already been reviewed',
          );
        }

        let wallet = await this.lockWallet(transaction, request.driverId);
        if (decision === 'approved') {
          const balanceAfter = wallet.balanceCentavos + request.amountCentavos;
          if (balanceAfter > MAXIMUM_CREDIT_BALANCE_CENTAVOS) {
            throw new DriverDomainError(
              409,
              'MAX_CREDIT_BALANCE',
              'Approval would exceed the ₱1,000 service-credit balance limit',
            );
          }
          [wallet] = await transaction.update(driverCreditWallets)
            .set({ balanceCentavos: balanceAfter, updatedAt: new Date() })
            .where(eq(driverCreditWallets.driverId, request.driverId))
            .returning();
          await transaction.insert(driverCreditLedger).values({
            id: crypto.randomUUID(),
            driverId: request.driverId,
            type: 'topup',
            balanceDeltaCentavos: request.amountCentavos,
            reservedDeltaCentavos: 0,
            balanceAfterCentavos: wallet.balanceCentavos,
            reservedAfterCentavos: wallet.reservedCentavos,
            topupRequestId: request.id,
            actorId,
            reason,
          });
        }

        const [reviewed] = await transaction.update(driverTopupRequests)
          .set({
            status: decision,
            reviewedBy: actorId,
            reviewedAt: new Date(),
            reviewReason: reason,
          })
          .where(eq(driverTopupRequests.id, requestId))
          .returning();
        return { request: reviewed, wallet: this.walletView(wallet) };
      },
    );
  }

  async changeBalance(
    driverId: string,
    amountCentavos: number,
    type: 'adjustment' | 'refund',
    reason: string,
    actorId: string,
    idempotencyKey: string,
    requestHash: string,
  ) {
    return this.runIdempotently(
      `driver-credit.${type}`,
      idempotencyKey,
      requestHash,
      async (transaction) => {
        await this.lockDriver(transaction, driverId);
        const wallet = await this.lockWallet(transaction, driverId);
        const signedAmount = type === 'refund'
          ? -Math.abs(amountCentavos)
          : amountCentavos;
        const balanceAfter = wallet.balanceCentavos + signedAmount;
        if (balanceAfter < wallet.reservedCentavos) {
          throw new DriverDomainError(
            409,
            'INSUFFICIENT_CREDIT',
            'Available credits cannot cover this operation',
          );
        }
        if (balanceAfter > MAXIMUM_CREDIT_BALANCE_CENTAVOS) {
          throw new DriverDomainError(
            409,
            'MAX_CREDIT_BALANCE',
            'Operation would exceed the ₱1,000 service-credit balance limit',
          );
        }

        const [updatedWallet] = await transaction.update(driverCreditWallets)
          .set({ balanceCentavos: balanceAfter, updatedAt: new Date() })
          .where(eq(driverCreditWallets.driverId, driverId))
          .returning();
        const [entry] = await transaction.insert(driverCreditLedger)
          .values({
            id: crypto.randomUUID(),
            driverId,
            type,
            balanceDeltaCentavos: signedAmount,
            reservedDeltaCentavos: 0,
            balanceAfterCentavos: updatedWallet.balanceCentavos,
            reservedAfterCentavos: updatedWallet.reservedCentavos,
            actorId,
            reason,
          })
          .returning();
        return { wallet: this.walletView(updatedWallet), ledgerEntry: entry };
      },
    );
  }

  async getEligibilityData(driverId: string) {
    const compliance = await this.complianceData(db, driverId);
    const wallet = await this.getWallet(driverId);
    return { ...compliance, wallet };
  }

  async reserveCredit(
    values: {
      driverId: string;
      rideId: string;
      fareCentavos: number;
      commissionBasisPoints: number;
    },
    actorId: string,
    idempotencyKey: string,
    requestHash: string,
  ) {
    return this.runIdempotently(
      'driver-credit.reserve',
      idempotencyKey,
      requestHash,
      async (transaction) => {
        const rideLock = `credit-reservation:${values.rideId}`;
        await transaction.execute(
          sql`select pg_advisory_xact_lock(hashtext(${rideLock}))`,
        );
        const [existing] = await transaction.select()
          .from(driverCreditReservations)
          .where(eq(driverCreditReservations.rideId, values.rideId));
        const commissionCentavos = calculateCommissionCentavos(
          values.fareCentavos,
          values.commissionBasisPoints,
        );
        if (existing) {
          if (
            existing.driverId !== values.driverId
            || existing.fareCentavos !== values.fareCentavos
            || existing.commissionBasisPoints !== values.commissionBasisPoints
          ) {
            throw new DriverDomainError(
              409,
              'RESERVATION_STATE_CONFLICT',
              'Ride already has a different credit reservation',
            );
          }
          return existing;
        }

        await this.lockDriver(transaction, values.driverId);
        const compliance = await this.complianceData(transaction, values.driverId);
        if (compliance.driver.approvalStatus !== 'approved') {
          throw new DriverDomainError(
            409,
            'DRIVER_NOT_APPROVED',
            'Driver is not approved to accept rides',
          );
        }
        if (compliance.restriction) {
          throw new DriverDomainError(
            409,
            'ACCOUNT_RESTRICTED',
            'Driver account is restricted',
          );
        }
        const hasInvalidDocument = compliance.documents.some(
          ({ requirement, check }: any) => !isDocumentRequirementSatisfied(
            requirement,
            check,
            compliance.now,
          ),
        );
        if (hasInvalidDocument) {
          throw new DriverDomainError(
            409,
            'DRIVER_DOCUMENTS_INCOMPLETE',
            'Driver documents are incomplete or expired',
          );
        }

        const wallet = await this.lockWallet(transaction, values.driverId);
        const available = wallet.balanceCentavos - wallet.reservedCentavos;
        if (available < commissionCentavos) {
          throw new DriverDomainError(
            409,
            'INSUFFICIENT_CREDIT',
            'Driver has insufficient service credits for this ride',
          );
        }

        const reservedAfter = wallet.reservedCentavos + commissionCentavos;
        const [updatedWallet] = await transaction.update(driverCreditWallets)
          .set({ reservedCentavos: reservedAfter, updatedAt: new Date() })
          .where(eq(driverCreditWallets.driverId, values.driverId))
          .returning();
        const [reservation] = await transaction.insert(driverCreditReservations)
          .values({
            id: crypto.randomUUID(),
            ...values,
            commissionCentavos,
          })
          .returning();
        await transaction.insert(driverCreditLedger).values({
          id: crypto.randomUUID(),
          driverId: values.driverId,
          type: 'reserve',
          balanceDeltaCentavos: 0,
          reservedDeltaCentavos: commissionCentavos,
          balanceAfterCentavos: updatedWallet.balanceCentavos,
          reservedAfterCentavos: updatedWallet.reservedCentavos,
          rideId: values.rideId,
          actorId,
          reason: 'Ride commission reserved',
        });
        return reservation;
      },
    );
  }

  async transitionReservation(
    rideId: string,
    targetStatus: 'settled' | 'released' | 'disputed',
    reason: string,
    actorId: string,
    idempotencyKey: string,
    requestHash: string,
  ) {
    return this.runIdempotently(
      `driver-credit.${targetStatus}`,
      idempotencyKey,
      requestHash,
      async (transaction) => {
        await transaction.execute(
          sql`select "id" from "driver_credit_reservations"
              where "ride_id" = ${rideId} for update`,
        );
        const [reservation] = await transaction.select()
          .from(driverCreditReservations)
          .where(eq(driverCreditReservations.rideId, rideId));
        if (!reservation) {
          throw new DriverDomainError(
            404,
            'RESERVATION_STATE_CONFLICT',
            'Ride credit reservation not found',
          );
        }
        if (reservation.status === targetStatus) return reservation;
        if (reservation.status === 'settled' || reservation.status === 'released') {
          throw new DriverDomainError(
            409,
            'RESERVATION_STATE_CONFLICT',
            `Reservation is already ${reservation.status}`,
          );
        }

        const wallet = await this.lockWallet(transaction, reservation.driverId);
        let balanceDelta = 0;
        let reservedDelta = 0;
        if (targetStatus === 'settled') {
          balanceDelta = -reservation.commissionCentavos;
          reservedDelta = -reservation.commissionCentavos;
        } else if (targetStatus === 'released') {
          reservedDelta = -reservation.commissionCentavos;
        }

        const balanceAfter = wallet.balanceCentavos + balanceDelta;
        const reservedAfter = wallet.reservedCentavos + reservedDelta;
        if (balanceAfter < 0 || reservedAfter < 0 || balanceAfter < reservedAfter) {
          throw new DriverDomainError(
            409,
            'RESERVATION_STATE_CONFLICT',
            'Wallet and reservation balances do not reconcile',
          );
        }

        const [updatedWallet] = await transaction.update(driverCreditWallets)
          .set({
            balanceCentavos: balanceAfter,
            reservedCentavos: reservedAfter,
            updatedAt: new Date(),
          })
          .where(eq(driverCreditWallets.driverId, reservation.driverId))
          .returning();
        const [updatedReservation] = await transaction.update(driverCreditReservations)
          .set({
            status: targetStatus,
            disputeReason: targetStatus === 'disputed' ? reason : reservation.disputeReason,
            updatedAt: new Date(),
          })
          .where(eq(driverCreditReservations.id, reservation.id))
          .returning();
        await transaction.insert(driverCreditLedger).values({
          id: crypto.randomUUID(),
          driverId: reservation.driverId,
          type: targetStatus === 'settled'
            ? 'settle'
            : targetStatus === 'released'
              ? 'release'
              : 'dispute',
          balanceDeltaCentavos: balanceDelta,
          reservedDeltaCentavos: reservedDelta,
          balanceAfterCentavos: updatedWallet.balanceCentavos,
          reservedAfterCentavos: updatedWallet.reservedCentavos,
          rideId,
          actorId,
          reason,
        });
        return updatedReservation;
      },
    );
  }
}
