import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { BiddingRepositoryImpl } from '../repositories/bidding.repository.ts';
import { BiddingService } from '../services/bidding.service.ts';
import { AuthVariables } from '../../shared/middleware/auth.ts';

const biddingRepository = new BiddingRepositoryImpl();
const biddingService = new BiddingService(biddingRepository);

type AuthContext = Context<{ Variables: AuthVariables }>;

export async function handleComputeFare(context: Context) {
  const { ride_type, distance_km, duration_minutes } =
    context.req.valid('json' as never) as {
      ride_type: string;
      distance_km: number;
      duration_minutes: number;
    };
  const fareResult = await biddingService.computeFare(
    ride_type ?? 'Solo Ride',
    Number(distance_km),
    Number(duration_minutes),
  );
  return context.json(fareResult, 200);
}

export async function handleCreateSession(context: AuthContext) {
  const body = context.req.valid('json' as never);
  const session = await biddingService.createSession(body, context.get('userId'));

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
    offered_fare: session.offeredFareCentavos / 100,
    offered_fare_centavos: session.offeredFareCentavos,
    status: session.status,
    target_driver_id: session.targetDriverId,
    expires_at: session.expiresAt.toISOString(),
    created_at: session.createdAt.toISOString(),
  }, 201);
}

export async function handleGetActiveSessions(context: AuthContext) {
  const role = context.get('role');
  const driverId = role === 'driver' ? context.get('userId') : undefined;
  const list = await biddingService.getActiveSessions(driverId, role === 'internal');
  return context.json(list, 200);
}

export async function handleGetOffers(context: AuthContext) {
  const sessionId = context.req.param('sessionId')!;
  const list = await biddingService.getOffers(
    sessionId,
    context.get('userId'),
    context.get('role'),
  );
  return context.json(list, 200);
}

export async function handlePlaceOffer(context: AuthContext) {
  const sessionId = context.req.param('sessionId')!;
  const body = context.req.valid('json' as never);
  const offer = await biddingService.placeOffer(
    sessionId,
    context.get('userId'),
    body,
  );
  return context.json(offer, 201);
}

export async function handleAcceptOffer(context: AuthContext) {
  const sessionId = context.req.param('sessionId')!;
  const offerId = context.req.param('offerId')!;
  const result = await biddingService.acceptOffer(
    sessionId,
    offerId,
    context.get('userId'),
  );
  return context.json(result, 200);
}

export async function handleAcceptOfferBody(context: AuthContext) {
  const body = context.req.valid('json' as never) as { offer_id: string };
  const result = await biddingService.acceptOffer(
    context.req.param('sessionId')!,
    body.offer_id,
    context.get('userId'),
  );
  return context.json(result, 200);
}

export async function handleCancelSession(context: AuthContext) {
  const sessionId = context.req.param('sessionId')!;
  const result = await biddingService.cancelSession(
    sessionId,
    context.get('userId'),
  );
  return context.json(result, 200);
}

export async function handleCancelOffer(context: AuthContext) {
  const sessionId = context.req.param('sessionId')!;
  const result = await biddingService.cancelOffer(
    sessionId,
    context.get('userId'),
  );
  return context.json(result, 200);
}

export async function handleGetSessionDetails(context: AuthContext) {
  const sessionId = context.req.param('sessionId')!;
  const details = await biddingService.getSessionDetails(
    sessionId,
    context.get('userId'),
    context.get('role'),
  );
  return context.json(details, 200);
}

export async function handleManualAssignment(context: Context) {
  const idempotencyKey = context.req.header('Idempotency-Key')?.trim();
  if (!idempotencyKey || idempotencyKey.length > 200) {
    throw new HTTPException(400, { message: 'Idempotency-Key header is required' });
  }
  const body = context.req.valid('json' as never) as {
    driver_id: string;
    admin_id: string;
  };
  const result = await biddingService.manualAssign(
    context.req.param('sessionId')!,
    body.driver_id,
    body.admin_id,
    idempotencyKey,
  );
  return context.json(result, 200);
}
