import { Hono } from 'hono';
import { getActiveRides } from '../services/drivers.ts';

export const ridesRouter = new Hono();

ridesRouter.get('/active', async (c) => {
  try {
    const data = await getActiveRides();
    return c.json(data);
  } catch (e: any) {
    const msg = e.message;
    return c.json({ error: 'Trip service unavailable', details: msg }, 502);
  }
});
