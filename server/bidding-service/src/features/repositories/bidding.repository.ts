import { db } from '../../shared/drizzle.ts';
import { bidSessions, driverOffers } from '../../db/schema.ts';
import { and, desc, eq, gte, isNull, lt, ne } from 'drizzle-orm';
import { BidSession, DriverOffer, BiddingRepository } from '../entities/bidding.types.ts';

export class BiddingRepositoryImpl implements BiddingRepository {
  async createSession(details: any): Promise<BidSession> {
    const [created] = await db.insert(bidSessions)
      .values({
        id: crypto.randomUUID(),
        passengerId: details.passengerId,
        rideType: details.rideType,
        pickupLatitude: details.pickupLatitude,
        pickupLongitude: details.pickupLongitude,
        pickupName: details.pickupName,
        dropoffLatitude: details.dropoffLatitude,
        dropoffLongitude: details.dropoffLongitude,
        dropoffName: details.dropoffName,
        distanceKm: details.distanceKm,
        durationMinutes: details.durationMinutes,
        offeredFare: details.offeredFare,
        offeredFareCentavos: details.offeredFareCentavos
          ?? Math.round(details.offeredFare * 100),
        targetDriverId: details.targetDriverId,
        status: 'open',
        expiresAt: details.expiresAt,
      })
      .returning();
    return created;
  }

  async findSessionById(id: string): Promise<BidSession | null> {
    const [matched] = await db.select().from(bidSessions).where(eq(bidSessions.id, id));
    return matched || null;
  }

  async findSessionWithOffers(id: string): Promise<BidSession & { offers: DriverOffer[] } | null> {
    const session = await this.findSessionById(id);
    if (!session) return null;
    const offersList = await db.select().from(driverOffers).where(eq(driverOffers.sessionId, id));
    return { ...session, offers: offersList };
  }

  async findActiveSessions(now: Date): Promise<(BidSession & { offers: DriverOffer[] })[]> {
    const active = await db.select()
      .from(bidSessions)
      .where(
        and(
          eq(bidSessions.status, 'open'),
          gte(bidSessions.expiresAt, now)
        )
      )
      .orderBy(desc(bidSessions.createdAt));

    const result: (BidSession & { offers: DriverOffer[] })[] = [];
    for (const s of active) {
      const offersList = await db.select().from(driverOffers).where(eq(driverOffers.sessionId, s.id));
      result.push({ ...s, offers: offersList });
    }
    return result;
  }

  async expireSessions(now: Date): Promise<void> {
    await db.update(bidSessions)
      .set({ status: 'canceled' })
      .where(
        and(
          eq(bidSessions.status, 'open'),
          lt(bidSessions.expiresAt, now)
        )
      );
  }

  async findPendingOffer(sessionId: string, driverId: string): Promise<DriverOffer | null> {
    const [matched] = await db.select()
      .from(driverOffers)
      .where(
        and(
          eq(driverOffers.sessionId, sessionId),
          eq(driverOffers.driverId, driverId),
          eq(driverOffers.status, 'pending')
        )
      );
    return matched || null;
  }

  async findOffersBySessionId(sessionId: string): Promise<DriverOffer[]> {
    return await db.select()
      .from(driverOffers)
      .where(
        and(
          eq(driverOffers.sessionId, sessionId),
          eq(driverOffers.status, 'pending')
        )
      )
      .orderBy(driverOffers.createdAt);
  }

  async createOffer(sessionId: string, offerDetails: any): Promise<DriverOffer> {
    const [created] = await db.insert(driverOffers)
      .values({
        id: crypto.randomUUID(),
        sessionId,
        driverId: offerDetails.driverId,
        driverName: offerDetails.driverName,
        plateNumber: offerDetails.plateNumber,
        vehicleType: offerDetails.vehicleType,
        proposedFare: offerDetails.proposedFare,
        proposedFareCentavos: offerDetails.proposedFareCentavos
          ?? Math.round(offerDetails.proposedFare * 100),
        status: 'pending',
      })
      .returning();
    return created;
  }

  async claimAssignment(input: {
    sessionId: string;
    offerId: string;
    driverId: string;
    idempotencyKey: string;
    assignmentSource: 'driver_offer' | 'admin';
    assignedByAdminId?: string | null;
  }): Promise<{
    state: 'claimed' | 'retry' | 'completed' | 'conflict';
    session: BidSession | null;
  }> {
    const [claimed] = await db.update(bidSessions)
      .set({
        status: 'assigning',
        acceptedDriverId: input.driverId,
        acceptedOfferId: input.offerId,
        acceptanceIdempotencyKey: input.idempotencyKey,
        assignmentSource: input.assignmentSource,
        assignedByAdminId: input.assignedByAdminId ?? null,
        updatedAt: new Date(),
      })
      .where(and(
        eq(bidSessions.id, input.sessionId),
        eq(bidSessions.status, 'open'),
      ))
      .returning();
    if (claimed) return { state: 'claimed', session: claimed };

    const existing = await this.findSessionById(input.sessionId);
    if (!existing) return { state: 'conflict', session: null };
    const sameAssignment = (
      existing.acceptanceIdempotencyKey === input.idempotencyKey
      && existing.acceptedDriverId === input.driverId
      && existing.acceptedOfferId === input.offerId
      && existing.assignmentSource === input.assignmentSource
      && existing.assignedByAdminId === (input.assignedByAdminId ?? null)
    );
    if (!sameAssignment) return { state: 'conflict', session: existing };
    if (existing.status === 'accepted') return { state: 'completed', session: existing };
    if (existing.status === 'assigning') return { state: 'retry', session: existing };
    return { state: 'conflict', session: existing };
  }

  async recordAssignmentTrip(
    sessionId: string,
    idempotencyKey: string,
    tripId: string,
  ): Promise<BidSession> {
    const [updated] = await db.update(bidSessions)
      .set({ acceptedTripId: tripId, updatedAt: new Date() })
      .where(and(
        eq(bidSessions.id, sessionId),
        eq(bidSessions.status, 'assigning'),
        eq(bidSessions.acceptanceIdempotencyKey, idempotencyKey),
        isNull(bidSessions.acceptedTripId),
      ))
      .returning();
    if (updated) return updated;

    const existing = await this.findSessionById(sessionId);
    if (
      existing
      && existing.acceptanceIdempotencyKey === idempotencyKey
      && existing.acceptedTripId === tripId
    ) {
      return existing;
    }
    throw new Error('Assignment state changed before the trip could be recorded');
  }

  async completeAssignment(
    sessionId: string,
    offerId: string,
    idempotencyKey: string,
    tripId: string,
  ): Promise<{ session: BidSession; offer: DriverOffer }> {
    return await db.transaction(async (tx) => {
      const [updatedSession] = await tx.update(bidSessions)
        .set({
          status: 'accepted',
          acceptedTripId: tripId,
          updatedAt: new Date(),
        })
        .where(and(
          eq(bidSessions.id, sessionId),
          eq(bidSessions.status, 'assigning'),
          eq(bidSessions.acceptanceIdempotencyKey, idempotencyKey),
          eq(bidSessions.acceptedOfferId, offerId),
        ))
        .returning();

      const [updatedOffer] = await tx.update(driverOffers)
        .set({ status: 'accepted' })
        .where(and(
          eq(driverOffers.id, offerId),
          eq(driverOffers.sessionId, sessionId),
          eq(driverOffers.status, 'pending'),
        ))
        .returning();

      if (!updatedSession || !updatedOffer) {
        throw new Error('Assignment state changed before it could be completed');
      }

      await tx.update(driverOffers)
        .set({ status: 'rejected' })
        .where(
          and(
            eq(driverOffers.sessionId, sessionId),
            ne(driverOffers.id, offerId),
            eq(driverOffers.status, 'pending')
          )
        );

      return { session: updatedSession, offer: updatedOffer };
    });
  }

  async releaseAssignment(
    sessionId: string,
    idempotencyKey: string,
    offerId?: string,
  ): Promise<void> {
    const released = await db.transaction(async (tx) => {
      const [released] = await tx.update(bidSessions)
        .set({
          status: 'open',
          acceptedDriverId: null,
          acceptedOfferId: null,
          acceptedTripId: null,
          acceptanceIdempotencyKey: null,
          assignmentSource: null,
          assignedByAdminId: null,
          updatedAt: new Date(),
        })
        .where(and(
          eq(bidSessions.id, sessionId),
          eq(bidSessions.status, 'assigning'),
          eq(bidSessions.acceptanceIdempotencyKey, idempotencyKey),
        ))
        .returning({ id: bidSessions.id });
      if (released && offerId) {
        await tx.update(driverOffers)
          .set({ status: 'rejected' })
          .where(and(
            eq(driverOffers.id, offerId),
            eq(driverOffers.sessionId, sessionId),
            eq(driverOffers.status, 'pending'),
          ));
      }
      return Boolean(released);
    });
    if (released) return;

    const existing = await this.findSessionById(sessionId);
    if (existing?.status === 'open' && !existing.acceptanceIdempotencyKey) return;
    throw new Error('Assignment state changed before its claim could be released');
  }

  async updateSessionStatus(id: string, status: string): Promise<BidSession> {
    const [updated] = await db.update(bidSessions)
      .set({ status, updatedAt: new Date() })
      .where(eq(bidSessions.id, id))
      .returning();
    if (!updated) throw new Error('Bid session not found');
    return updated;
  }

  async updateOfferStatus(id: string, status: string): Promise<DriverOffer> {
    const [updated] = await db.update(driverOffers)
      .set({ status })
      .where(eq(driverOffers.id, id))
      .returning();
    if (!updated) throw new Error('Offer not found');
    return updated;
  }
}
