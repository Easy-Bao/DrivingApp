import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { BiddingRepositoryImpl } from '../repositories/bidding.repository.ts';
import { BiddingService } from '../services/bidding.service.ts';

const biddingRepository = new BiddingRepositoryImpl();
const biddingService = new BiddingService(biddingRepository);

export async function handleComputeFare(context: Context) {
  const { ride_type, distance_km, duration_minutes } = await context.req.json();
  if (distance_km == null || duration_minutes == null) {
    throw new HTTPException(400, { message: 'distance_km and duration_minutes are required' });
  }

  const fareResult = biddingService.computeFare(
    ride_type ?? 'Solo Ride',
    parseFloat(distance_km),
    parseFloat(duration_minutes)
  );
  return context.json(fareResult, 200);
}

export async function handleCreateSession(context: Context) {
  const body = await context.req.json();
  const session = await biddingService.createSession(body);

  return context.json({
    id: session.id,
    passenger_id: session.passengerId,
    ride_type: session.rideType,
    pickup_latitude: session.pickupLatitude,
    pickup_longitude: session.pickupLongitude,
    pickup_name: session.pickupName,
    dropoff_latitude: session.dropoffLatitude,
    dropoff_longitude: session.dropoffLongitude,
    dropoff_name: session.dropoffName,
    distance_km: session.distanceKm,
    duration_minutes: session.durationMinutes,
    offered_fare: session.offeredFare,
    status: session.status,
    target_driver_id: session.targetDriverId,
    expires_at: session.expiresAt.toISOString(),
    created_at: session.createdAt.toISOString(),
  }, 201);
}

export async function handleGetActiveSessions(context: Context) {
  const driverId = context.req.query('driver_id');
  const list = await biddingService.getActiveSessions(driverId);
  return context.json(list, 200);
}

export async function handleGetOffers(context: Context) {
  const sessionId = context.req.param('sessionId');
  const list = await biddingService.getOffers(sessionId);
  return context.json(list, 200);
}

export async function handlePlaceOffer(context: Context) {
  const sessionId = context.req.param('sessionId');
  const body = await context.req.json();
  const offer = await biddingService.placeOffer(sessionId, body);
  return context.json(offer, 201);
}

export async function handleAcceptOffer(context: Context) {
  const sessionId = context.req.param('sessionId');
  const offerId = context.req.param('offerId');
  const result = await biddingService.acceptOffer(sessionId, offerId);
  return context.json(result, 200);
}

export async function handleCancelSession(context: Context) {
  const sessionId = context.req.param('sessionId');
  const result = await biddingService.cancelSession(sessionId);
  return context.json(result, 200);
}

export async function handleCancelOffer(context: Context) {
  const sessionId = context.req.param('sessionId');
  const { driver_id } = await context.req.json();
  if (!driver_id) {
    throw new HTTPException(400, { message: 'driver_id is required' });
  }
  const result = await biddingService.cancelOffer(sessionId, driver_id);
  return context.json(result, 200);
}

export async function handleGetSessionDetails(context: Context) {
  const sessionId = context.req.param('sessionId');
  const details = await biddingService.getSessionDetails(sessionId);
  return context.json(details, 200);
}
