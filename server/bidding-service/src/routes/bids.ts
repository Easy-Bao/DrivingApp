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

bidsRouter.post('/fare', async (c) => {
  try {
    const { ride_type, distance_km, duration_minutes } = await c.req.json();
    if (distance_km == null || duration_minutes == null) {
      return c.json({ error: 'distance_km and duration_minutes are required' }, 400);
    }
    const breakdown = computeFare(
      ride_type ?? 'Solo Ride',
      parseFloat(distance_km),
      parseFloat(duration_minutes),
    );
    return c.json(breakdown);
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

bidsRouter.post('/', async (c) => {
  try {
    const body = await c.req.json();
    const {
      passenger_id,
      ride_type,
      pickup_latitude,
      pickup_longitude,
    } = body;

    if (!passenger_id || !ride_type || pickup_latitude == null || pickup_longitude == null) {
      return c.json({ error: 'passenger_id, ride_type, pickup, and dropoff are required' }, 400);
    }

    const session = await createBidSession(body);
    return c.json(mapSession(session), 201);
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

bidsRouter.get('/active', async (c) => {
  try {
    const driverId = c.req.query('driver_id');
    const sessions = await getActiveBidSessions(driverId);
    const mapped = sessions.map((s: any) => ({
      ...mapSession(s),
      passenger_name: s.passengerName,
      passenger_rating: s.passengerRating,
    }));
    return c.json(mapped);
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

bidsRouter.get('/:id/offers', async (c) => {
  const id = c.req.param('id');
  try {
    const offers = await getOffers(id);
    return c.json(offers.map(mapOffer));
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

bidsRouter.post('/:id/offer', async (c) => {
  const id = c.req.param('id');
  try {
    const body = await c.req.json();
    const { driver_id, driver_name, plate_number, vehicle_type } = body;

    if (!driver_id || !driver_name || !plate_number || !vehicle_type) {
      return c.json({ error: 'driver_id, driver_name, plate_number, and vehicle_type are required' }, 400);
    }

    try {
      const offer = await placeOffer(id, body);
      return c.json(mapOffer(offer), 201);
    } catch (err: any) {
      const msg = err.message;
      if (msg === 'Bid session not found') {
        return c.json({ error: msg }, 404);
      }
      if (msg.startsWith('Session is')) {
        return c.json({ error: msg }, 409);
      }
      if (msg === 'Session has expired') {
        return c.json({ error: msg }, 410);
      }
      if (msg === 'Offer already placed') {
        return c.json({ error: msg }, 409);
      }
      if (msg.includes('maximum cap') || msg.includes('Priority Ride')) {
        return c.json({ error: msg }, 400);
      }
      return c.json({ error: msg }, 400);
    }
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

bidsRouter.post('/:id/accept', async (c) => {
  const id = c.req.param('id');
  try {
    const { offer_id } = await c.req.json();
    if (!offer_id) {
      return c.json({ error: 'offer_id is required' }, 400);
    }

    try {
      const result = await acceptOffer(id, offer_id);
      return c.json({
        session: mapSession(result.session),
        offer: mapOffer(result.offer),
        ride_id: result.rideId,
      });
    } catch (err: any) {
      const msg = err.message;
      if (msg === 'Bid session not found') {
        return c.json({ error: msg }, 404);
      }
      if (msg.startsWith('Session is already')) {
        return c.json({ error: msg }, 409);
      }
      if (msg.startsWith('Offer not found')) {
        return c.json({ error: msg }, 404);
      }
      if (msg.startsWith('Failed to create trip')) {
        try {
          const detailStr = msg.replace('Failed to create trip: ', '');
          const details = JSON.parse(detailStr);
          return c.json({ error: 'Failed to create trip', details }, 502);
        } catch (_) {
          return c.json({ error: msg }, 502);
        }
      }
      return c.json({ error: msg }, 400);
    }
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

bidsRouter.delete('/:id', async (c) => {
  const id = c.req.param('id');
  try {
    try {
      const updated = await cancelBidSession(id);
      return c.json(mapSession(updated));
    } catch (err: any) {
      const msg = err.message;
      if (msg === 'Bid session not found') {
        return c.json({ error: msg }, 404);
      }
      if (msg === 'Cannot cancel an accepted session') {
        return c.json({ error: msg }, 409);
      }
      return c.json({ error: msg }, 400);
    }
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

bidsRouter.post('/:id/cancel-offer', async (c) => {
  const id = c.req.param('id');
  try {
    const { driver_id } = await c.req.json();
    if (!driver_id) {
      return c.json({ error: 'driver_id is required' }, 400);
    }
    try {
      const updated = await cancelOffer(id, driver_id);
      return c.json(mapOffer(updated));
    } catch (err: any) {
      const msg = err.message;
      if (msg === 'No pending offer found for this driver') {
        return c.json({ error: msg }, 404);
      }
      return c.json({ error: msg }, 400);
    }
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

bidsRouter.get('/:id', async (c) => {
  const id = c.req.param('id');
  try {
    try {
      const session = await getBidSession(id);
      return c.json({
        ...mapSession(session),
        offers: session.offers.map(mapOffer),
      });
    } catch (err: any) {
      const msg = err.message;
      if (msg === 'Bid session not found') {
        return c.json({ error: msg }, 404);
      }
      return c.json({ error: msg }, 400);
    }
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});
