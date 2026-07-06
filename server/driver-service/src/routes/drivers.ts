import { Hono } from 'hono';
import {
  signupDriver,
  loginDriver,
  getOnlineDrivers,
  updateDriverOnlineStatus,
  getDriverById,
  getDriverStats,
  getDriverTrips,
} from '../services/drivers.ts';

export const driversRouter = new Hono();

driversRouter.post('/signup', async (c) => {
  try {
    const body = await c.req.json();
    try {
      const driver = await signupDriver(body);
      return c.json(driver, 201);
    } catch (err: any) {
      if (err.message === 'A driver with this email already exists') {
        return c.json({ error: err.message }, 409);
      }
      return c.json({ error: err.message }, 400);
    }
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

driversRouter.post('/login', async (c) => {
  try {
    const body = await c.req.json();
    try {
      const driver = await loginDriver(body);
      return c.json({ driver }, 200);
    } catch (err: any) {
      if (err.message === 'Invalid email or password') {
        return c.json({ error: err.message }, 401);
      }
      return c.json({ error: err.message }, 400);
    }
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

driversRouter.get('/online', async (c) => {
  try {
    const list = await getOnlineDrivers();
    return c.json(list);
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

driversRouter.post('/:id/online', async (c) => {
  const id = c.req.param('id');
  try {
    const body = await c.req.json();
    const updated = await updateDriverOnlineStatus(id, body);
    return c.json(updated);
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

driversRouter.get('/:id', async (c) => {
  const id = c.req.param('id');
  try {
    try {
      const driver = await getDriverById(id);
      return c.json(driver);
    } catch (err: any) {
      if (err.message === 'Driver not found') {
        return c.json({ error: err.message }, 404);
      }
      return c.json({ error: err.message }, 400);
    }
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

driversRouter.get('/:id/stats', async (c) => {
  const id = c.req.param('id');
  try {
    try {
      const stats = await getDriverStats(id);
      return c.json(stats);
    } catch (err: any) {
      if (err.message === 'Driver not found') {
        return c.json({ error: err.message }, 404);
      }
      return c.json({ error: err.message }, 400);
    }
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

driversRouter.get('/:id/trips', async (c) => {
  const id = c.req.param('id');
  try {
    try {
      const trips = await getDriverTrips(id);
      return c.json(trips);
    } catch (err: any) {
      if (err.message.includes('Trip service failed')) {
        const parts = err.message.split(' ');
        const status = parseInt(parts[parts.length - 1]);
        return c.json({ error: 'Trip service failed' }, status as any);
      }
      return c.json({ error: err.message }, 400);
    }
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});
