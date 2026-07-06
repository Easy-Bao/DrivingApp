import { Hono } from 'hono';
import { updateLocation, getLocation } from '../services/telemetry.ts';

export const telemetryRouter = new Hono();

telemetryRouter.post('/location', async (c) => {
  try {
    const { driverId, lat, lng } = await c.req.json();
    updateLocation(driverId, lat, lng);
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

telemetryRouter.get('/location/:driverId', (c) => {
  const driverId = c.req.param('driverId');
  const loc = getLocation(driverId);
  if (!loc) return c.json({ error: 'No location telemetry found' }, 404);
  return c.json(loc);
});
