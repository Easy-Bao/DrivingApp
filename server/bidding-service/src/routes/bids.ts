import { Hono } from 'hono';
import {
  computeFare,
  createBidSession,
  getActiveBidSessions,
  getOffers,
  placeOffer,
  acceptOffer,
  cancelBidSession,
  cancelOffer,
  getBidSession,
} from '../services/bids.ts';
import { mapSession, mapOffer } from '../utils/mappers.ts';

export const bidsRouter = new Hono();

bidsRouter.post('/fare', async (context) => {
  try {
    const { ride_type, distance_km, duration_minutes } = await context.req.json();
    if (distance_km == null || duration_minutes == null) {
      return context.json({ error: 'distance_km and duration_minutes are required' }, 400);
    }
    const breakdown = computeFare(
      ride_type ?? 'Solo Ride',
      parseFloat(distance_km),
      parseFloat(duration_minutes),
    );
    return context.json(breakdown);
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

bidsRouter.post('/', async (context) => {
  try {
    const body = await context.req.json();
    const {
      passenger_id,
      ride_type,
      pickup_latitude,
      pickup_longitude,
    } = body;

    if (!passenger_id || !ride_type || pickup_latitude == null || pickup_longitude == null) {
      return context.json({ error: 'passenger_id, ride_type, pickup, and dropoff are required' }, 400);
    }

    const session = await createBidSession(body);
    return context.json(mapSession(session), 201);
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

bidsRouter.get('/active', async (context) => {
  try {
    const driverId = context.req.query('driver_id');
    const sessions = await getActiveBidSessions(driverId);
    const mapped = sessions.map((s: any) => ({
      ...mapSession(s),
      passenger_name: s.passengerName,
      passenger_rating: s.passengerRating,
    }));
    return context.json(mapped);
  } catch (error: any) {
    return context.json({ error: error.message }, 500);
  }
});

bidsRouter.get('/:id/offers', async (context) => {
  const id = context.req.param('id');
  try {
    const offers = await getOffers(id);
    return context.json(offers.map(mapOffer));
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

bidsRouter.post('/:id/offer', async (context) => {
  const id = context.req.param('id');
  try {
    const body = await context.req.json();
    const { driver_id, driver_name, plate_number, vehicle_type } = body;

    if (!driver_id || !driver_name || !plate_number || !vehicle_type) {
      return context.json({ error: 'driver_id, driver_name, plate_number, and vehicle_type are required' }, 400);
    }

    try {
      const offer = await placeOffer(id, body);
      return context.json(mapOffer(offer), 201);
    } catch (error: any) {
      const msg = error.message;
      if (msg === 'Bid session not found') {
        return context.json({ error: msg }, 404);
      }
      if (msg.startsWith('Session is')) {
        return context.json({ error: msg }, 409);
      }
      if (msg === 'Session has expired') {
        return context.json({ error: msg }, 410);
      }
      if (msg === 'Offer already placed') {
        return context.json({ error: msg }, 409);
      }
      if (msg.includes('maximum cap') || msg.includes('Priority Ride')) {
        return context.json({ error: msg }, 400);
      }
      return context.json({ error: msg }, 400);
    }
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

bidsRouter.post('/:id/accept', async (context) => {
  const id = context.req.param('id');
  try {
    const { offer_id } = await context.req.json();
    if (!offer_id) {
      return context.json({ error: 'offer_id is required' }, 400);
    }

    try {
      const result = await acceptOffer(id, offer_id);
      return context.json({
        session: mapSession(result.session),
        offer: mapOffer(result.offer),
        ride_id: result.rideId,
      });
    } catch (error: any) {
      const msg = error.message;
      if (msg === 'Bid session not found') {
        return context.json({ error: msg }, 404);
      }
      if (msg.startsWith('Session is already')) {
        return context.json({ error: msg }, 409);
      }
      if (msg.startsWith('Offer not found')) {
        return context.json({ error: msg }, 404);
      }
      if (msg.startsWith('Failed to create trip')) {
        try {
          const detailStr = msg.replace('Failed to create trip: ', '');
          const details = JSON.parse(detailStr);
          return context.json({ error: 'Failed to create trip', details }, 502);
        } catch (_) {
          return context.json({ error: msg }, 502);
        }
      }
      return context.json({ error: msg }, 400);
    }
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

bidsRouter.delete('/:id', async (context) => {
  const id = context.req.param('id');
  try {
    try {
      const updated = await cancelBidSession(id);
      return context.json(mapSession(updated));
    } catch (error: any) {
      const msg = error.message;
      if (msg === 'Bid session not found') {
        return context.json({ error: msg }, 404);
      }
      if (msg === 'Cannot cancel an accepted session') {
        return context.json({ error: msg }, 409);
      }
      return context.json({ error: msg }, 400);
    }
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

bidsRouter.post('/:id/cancel-offer', async (context) => {
  const id = context.req.param('id');
  try {
    const { driver_id } = await context.req.json();
    if (!driver_id) {
      return context.json({ error: 'driver_id is required' }, 400);
    }
    try {
      const updated = await cancelOffer(id, driver_id);
      return context.json(mapOffer(updated));
    } catch (error: any) {
      const msg = error.message;
      if (msg === 'No pending offer found for this driver') {
        return context.json({ error: msg }, 404);
      }
      return context.json({ error: msg }, 400);
    }
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

bidsRouter.get('/:id', async (context) => {
  const id = context.req.param('id');
  try {
    try {
      const session = await getBidSession(id);
      return context.json({
        ...mapSession(session),
        offers: session.offers.map(mapOffer),
      });
    } catch (error: any) {
      const msg = error.message;
      if (msg === 'Bid session not found') {
        return context.json({ error: msg }, 404);
      }
      return context.json({ error: msg }, 400);
    }
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});
