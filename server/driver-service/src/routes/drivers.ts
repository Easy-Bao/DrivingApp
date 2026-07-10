import { Hono } from 'hono';
import {
  registerDriver,
  authenticateDriver,
  retrieveOnlineDrivers,
  updateDriverOnlineStatus,
  retrieveDriverProfile,
  retrieveDriverStats,
  retrieveDriverTripHistory,
  retrieveDriverReviews,
} from '../services/drivers.ts';

export const driversRouter = new Hono();

driversRouter.post('/signup', async (context) => {
  try {
    const body = await context.req.json();
    try {
      const driver = await registerDriver(body);
      return context.json(driver, 201);
    } catch (error: any) {
      if (error.message === 'A driver with this email already exists') {
        return context.json({ error: error.message }, 409);
      }
      return context.json({ error: error.message }, 400);
    }
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

driversRouter.post('/login', async (context) => {
  try {
    const body = await context.req.json();
    try {
      const driver = await authenticateDriver(body);
      return context.json({ driver }, 200);
    } catch (error: any) {
      if (error.message === 'Invalid email or password') {
        return context.json({ error: error.message }, 401);
      }
      return context.json({ error: error.message }, 400);
    }
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

driversRouter.get('/online', async (context) => {
  try {
    const list = await retrieveOnlineDrivers();
    return context.json(list);
  } catch (error: any) {
    return context.json({ error: error.message }, 500);
  }
});

driversRouter.post('/:id/online', async (context) => {
  const id = context.req.param('id');
  try {
    const body = await context.req.json();
    const updated = await updateDriverOnlineStatus(id, body);
    return context.json(updated);
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

driversRouter.get('/:id', async (context) => {
  const id = context.req.param('id');
  try {
    try {
      const driver = await retrieveDriverProfile(id);
      return context.json(driver);
    } catch (error: any) {
      if (error.message === 'Driver not found') {
        return context.json({ error: error.message }, 404);
      }
      return context.json({ error: error.message }, 400);
    }
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

driversRouter.get('/:id/stats', async (context) => {
  const id = context.req.param('id');
  try {
    try {
      const stats = await retrieveDriverStats(id);
      return context.json(stats);
    } catch (error: any) {
      if (error.message === 'Driver not found') {
        return context.json({ error: error.message }, 404);
      }
      return context.json({ error: error.message }, 400);
    }
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

driversRouter.get('/:id/trips', async (context) => {
  const id = context.req.param('id');
  try {
    try {
      const trips = await retrieveDriverTripHistory(id);
      return context.json(trips);
    } catch (error: any) {
      if (error.message.includes('Trip service failed')) {
        const parts = error.message.split(' ');
        const status = parseInt(parts[parts.length - 1]);
        return context.json({ error: 'Trip service failed' }, status as any);
      }
      return context.json({ error: error.message }, 400);
    }
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

driversRouter.get('/:id/reviews', async (context) => {
  const id = context.req.param('id');
  try {
    const reviews = await retrieveDriverReviews(id);
    return context.json(reviews);
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});
