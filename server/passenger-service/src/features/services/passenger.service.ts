/**
 * Service layer orchestrating domain logic for passenger profiles, ride requests, ride history, and notifications.
 */
import { HTTPException } from 'hono/http-exception';
import { Passenger, PassengerRepository, SafePassenger } from '../entities/passenger.types.ts';
import { CreateRideRequest } from '../schemas/passenger.schema.ts';

function restrictionMutationHash(payload: Record<string, unknown>): string {
  return new Bun.CryptoHasher('sha256')
    .update(JSON.stringify(payload))
    .digest('hex');
}

function rethrowRestrictionMutation(error: unknown): never {
  if (
    error instanceof Error
    && ['IDEMPOTENCY_KEY_REUSED', 'RESTRICTION_ALREADY_LIFTED'].includes(error.message)
  ) {
    throw new HTTPException(409, { message: error.message });
  }
  throw error;
}

export class PassengerService {
  private repository: PassengerRepository;

  constructor(repository: PassengerRepository) {
    this.repository = repository;
  }

  private sanitizePassenger(passenger: Passenger): SafePassenger {
    const { password_hash: _, ...safePassenger } = passenger;
    return safePassenger;
  }

  async getPassengerProfile(passengerId: string): Promise<SafePassenger> {
    const passengerProfile = await this.repository.retrievePassengerProfile(passengerId);
    if (!passengerProfile) {
      throw new HTTPException(404, { message: `Passenger not found: ${passengerId}` });
    }
    return this.sanitizePassenger(passengerProfile);
  }

  async getPassengersBatch(passengerIds: string[]): Promise<Record<string, SafePassenger>> {
    const passengerMap = await this.repository.retrievePassengersByIds(passengerIds);
    return Object.fromEntries(
      Object.entries(passengerMap).map(([id, passenger]) => [id, this.sanitizePassenger(passenger)])
    );
  }

  async updatePassengerProfile(id: string, payload: { name: string; phone: string; email: string }): Promise<SafePassenger> {
    const updated = await this.repository.updatePassengerProfile({ id, ...payload });
    return this.sanitizePassenger(updated);
  }

  async createRideRequest(payload: CreateRideRequest) {
    const restriction = await this.repository.findActiveRestriction(payload.passenger_id);
    if (restriction) {
      throw new HTTPException(403, { message: 'ACCOUNT_RESTRICTED' });
    }
    return await this.repository.registerRideRequest(payload);
  }

  async getPassengerRideHistory(passengerId: string) {
    return await this.repository.retrievePassengerRideHistory(passengerId);
  }

  async getPassengerNotifications(passengerId: string) {
    return await this.repository.retrievePassengerNotifications(passengerId);
  }

  async getRideAccess(passengerId: string) {
    const passenger = await this.repository.retrievePassengerProfile(passengerId);
    if (!passenger) {
      throw new HTTPException(404, { message: 'Passenger not found' });
    }
    const restriction = await this.repository.findActiveRestriction(passengerId);
    return {
      allowed: !restriction,
      code: restriction ? 'ACCOUNT_RESTRICTED' : null,
      reason: restriction?.reason ?? null,
      ends_at: restriction?.endsAt?.toISOString() ?? null,
    };
  }

  async restrictPassenger(input: {
    passengerId: string;
    caseId?: string | null;
    reason: string;
    endsAt?: Date | null;
    createdBy: string;
    idempotencyKey: string;
  }) {
    const passenger = await this.repository.retrievePassengerProfile(input.passengerId);
    if (!passenger) {
      throw new HTTPException(404, { message: 'Passenger not found' });
    }
    try {
      return await this.repository.createRestriction({
        ...input,
        requestHash: restrictionMutationHash({
          operation: 'create_restriction',
          passengerId: input.passengerId,
          caseId: input.caseId ?? null,
          reason: input.reason,
          endsAt: input.endsAt?.toISOString() ?? null,
          createdBy: input.createdBy,
        }),
      });
    } catch (error) {
      rethrowRestrictionMutation(error);
    }
  }

  async listPassengerRestrictions(passengerId: string) {
    return await this.repository.listRestrictions(passengerId);
  }

  async liftPassengerRestriction(input: {
    restrictionId: string;
    reason: string;
    adminId: string;
    idempotencyKey: string;
  }) {
    let restriction;
    try {
      restriction = await this.repository.revokeRestriction({
        restrictionId: input.restrictionId,
        reason: input.reason,
        liftedBy: input.adminId,
        idempotencyKey: input.idempotencyKey,
        requestHash: restrictionMutationHash({
          operation: 'lift_restriction',
          restrictionId: input.restrictionId,
          reason: input.reason,
          adminId: input.adminId,
        }),
      });
    } catch (error) {
      rethrowRestrictionMutation(error);
    }
    if (!restriction) {
      throw new HTTPException(404, { message: 'Restriction not found' });
    }
    return {
      ...restriction,
      liftedBy: input.adminId,
      liftReason: input.reason,
      requestId: input.idempotencyKey,
    };
  }
}
