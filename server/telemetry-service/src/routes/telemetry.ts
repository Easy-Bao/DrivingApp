import { Hono } from 'hono';
import { updateLocation, getLocation } from '../services/telemetry.ts';

export const telemetryRouter = new Hono();

telemetryRouter.post('/location', async (context) => {
  try {
    const { driverId, lat, lng } = await context.req.json();
    updateLocation(driverId, lat, lng);
    return context.json({ success: true });
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

telemetryRouter.get('/location/:driverId', (context) => {
  const driverId = context.req.param('driverId');
  const loc = getLocation(driverId);
  if (!loc) return context.json({ error: 'No location telemetry found' }, 404);
  return context.json(loc);
});
