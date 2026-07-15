/**
 * Repository layer executing Drizzle queries and transaction locks for bidding sessions.
 */
import { db } from '../../../shared/drizzle.ts';
import { bidSessions, driverOffers } from '../../../db/schema.ts';
import { eq, desc, and, lt, gte, ne } from 'drizzle-orm';
import { BidSession, DriverOffer, BiddingRepository } from '../entities/bidding.types.ts';

export class DrizzleBiddingRepository implements BiddingRepository {
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
        status: 'pending',
      })
      .returning();
    return created;
  }

  async acceptOfferTransaction(
    sessionId: string,
    offerId: string,
    acceptedDriverId: string
  ): Promise<{ session: BidSession; offer: DriverOffer }> {
    return await db.transaction(async (tx) => {
      const [updatedSession] = await tx.update(bidSessions)
        .set({ status: 'accepted', acceptedDriverId })
        .where(eq(bidSessions.id, sessionId))
        .returning();

      const [updatedOffer] = await tx.update(driverOffers)
        .set({ status: 'accepted' })
        .where(eq(driverOffers.id, offerId))
        .returning();

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

  async updateSessionStatus(id: string, status: string): Promise<BidSession> {
    const [updated] = await db.update(bidSessions)
      .set({ status })
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
